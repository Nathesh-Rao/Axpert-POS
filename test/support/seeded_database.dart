import 'dart:io';

import 'package:drift/native.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/seed/demo_seeder.dart';

/// A [DatabaseProvider] around an already open (in-memory) database.
class FixedDatabaseProvider implements DatabaseProvider {
  FixedDatabaseProvider(this.db);

  final AxpertDatabase db;

  @override
  Future<AxpertDatabase> open() async => db;

  @override
  Future<void> close() async {}
}

/// Reads the real seed assets from the project folder (tests run there).
Future<String> readSeedFile(String name) =>
    File('assets/seed/$name').readAsString();

/// An in-memory database with the demo seed loaded once.
Future<AxpertDatabase> seededDatabase({DateTime? now}) async {
  final db = AxpertDatabase(NativeDatabase.memory());
  await DemoSeeder(
    db: db,
    loadAsset: readSeedFile,
    uuid: UuidV4Generator(),
    now: now == null ? null : () => now,
  ).run();
  return db;
}

DemoSeeder seederFor(AxpertDatabase db, {DateTime? now}) => DemoSeeder(
  db: db,
  loadAsset: readSeedFile,
  uuid: UuidV4Generator(),
  now: now == null ? null : () => now,
);
