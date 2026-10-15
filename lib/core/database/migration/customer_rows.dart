import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../modules/customers/models/customer.dart';
import '../../identifiers/uuid_generator.dart';
import '../axpert_database.dart';
import 'fnv1a.dart';

/// A legacy id that was already taken and got a `~dupN` suffix (KG-132).
class RenamedCustomerId {
  const RenamedCustomerId({
    required this.from,
    required this.to,
    required this.name,
  });

  final String from;
  final String to;
  final String name;

  Map<String, String> toJson() => {'from': from, 'to': to, 'name': name};
}

/// The list after the duplicate-id rule, plus what was renamed.
class NormalizedCustomers {
  const NormalizedCustomers(this.customers, this.renamed);

  final List<Customer> customers;
  final List<RenamedCustomerId> renamed;
}

/// Customer list <-> `customers` table mapping shared by the one-way copy and
/// every save (DEC-126). Callers wrap [apply] in `durableTransaction`.
abstract final class CustomerRows {
  /// Duplicate legacy ids are never dropped: the first keeps its id, later
  /// ones become `<id>~dup2`, `~dup3`, ... (smallest id used by nobody in the
  /// list). Re-applying an already normalized list changes nothing.
  static NormalizedCustomers normalize(List<Customer> list) {
    final original = {for (final c in list) c.id};
    final used = <String>{};
    final renamed = <RenamedCustomerId>[];
    final out = <Customer>[];
    for (final c in list) {
      if (used.add(c.id)) {
        out.add(c);
        continue;
      }
      var n = 2;
      while (used.contains('${c.id}~dup$n') ||
          original.contains('${c.id}~dup$n')) {
        n++;
      }
      final id = '${c.id}~dup$n';
      used.add(id);
      renamed.add(RenamedCustomerId(from: c.id, to: id, name: c.name));
      out.add(
        Customer(
          id: id,
          name: c.name,
          phone: c.phone,
          email: c.email,
          member: c.member,
          points: c.points,
        ),
      );
    }
    return NormalizedCustomers(out, renamed);
  }

  /// Makes the table equal [list] (already normalized): match by legacy id,
  /// keep the UUID and `created_at` of known rows, insert new ones with a new
  /// UUID, tombstone (never delete) active rows that left the list, and set
  /// `position` to the list index.
  static Future<void> apply(
    AxpertDatabase db,
    List<Customer> list, {
    required int now,
    required UuidGenerator uuid,
  }) async {
    final existing = {
      for (final row in await db.select(db.customerEntries).get())
        row.legacyId: row,
    };
    final inList = <String>{};
    for (var i = 0; i < list.length; i++) {
      final c = list[i];
      inList.add(c.id);
      final row = existing[c.id];
      if (row == null) {
        await db
            .into(db.customerEntries)
            .insert(
              CustomerEntriesCompanion.insert(
                id: uuid.generate(),
                legacyId: c.id,
                position: i,
                name: c.name,
                phone: c.phone,
                email: c.email,
                memberNo: c.member,
                points: c.points,
                createdAt: now,
                updatedAt: now,
              ),
            );
        continue;
      }
      final same =
          row.deletedAt == null &&
          row.position == i &&
          row.name == c.name &&
          row.phone == c.phone &&
          row.email == c.email &&
          row.memberNo == c.member &&
          row.points == c.points;
      if (same) continue;
      await (db.update(
        db.customerEntries,
      )..where((t) => t.id.equals(row.id))).write(
        CustomerEntriesCompanion(
          position: Value(i),
          name: Value(c.name),
          phone: Value(c.phone),
          email: Value(c.email),
          memberNo: Value(c.member),
          points: Value(c.points),
          updatedAt: Value(now),
          deletedAt: const Value(null),
        ),
      );
    }
    for (final row in existing.values) {
      if (row.deletedAt == null && !inList.contains(row.legacyId)) {
        await (db.update(
          db.customerEntries,
        )..where((t) => t.id.equals(row.id))).write(
          CustomerEntriesCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }
    }
  }

  /// Active rows in list order.
  static Future<List<Customer>> readList(AxpertDatabase db) async {
    final rows =
        await (db.select(db.customerEntries)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return [
      for (final r in rows)
        Customer(
          id: r.legacyId,
          name: r.name,
          phone: r.phone,
          email: r.email,
          member: r.memberNo,
          points: r.points,
        ),
    ];
  }

  /// FNV-1a over the canonical JSON lines of [list], in order.
  static String checksum(List<Customer> list) =>
      fnv1a32Hex(list.map((c) => jsonEncode(c.toJson())).join('\n'));
}
