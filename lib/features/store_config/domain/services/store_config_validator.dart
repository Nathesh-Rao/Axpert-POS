import '../../../session/domain/entities/session_entities.dart';
import '../entities/store_config.dart';

enum ConfigIssueKind {
  nameRequired,
  slabNameRequired,
  slabNeedsComponent,
  labelRequired,
  duplicateLabel,
  rateOutOfRange,
  slabTotalTooHigh,
  duplicateTotal,
  noDefaultSlab,
  forexRateInvalid,
  forexDuplicate,
}

/// One validation problem; [subject] names the slab, component or currency.
class ConfigIssue {
  const ConfigIssue(this.kind, [this.subject = '']);

  final ConfigIssueKind kind;
  final String subject;

  @override
  bool operator ==(Object other) =>
      other is ConfigIssue && other.kind == kind && other.subject == subject;

  @override
  int get hashCode => Object.hash(kind, subject);
}

/// Validation of a [StoreConfig] before it is saved (plain Dart).
abstract final class StoreConfigValidator {
  static const int maxRateBp = 10000;

  static List<ConfigIssue> validate(StoreConfig config) {
    final issues = <ConfigIssue>[];
    if (config.name.trim().isEmpty) {
      issues.add(const ConfigIssue(ConfigIssueKind.nameRequired));
    }
    final totals = <String, Set<int>>{};
    var hasDefault = false;
    for (final slab in config.slabs) {
      final name = slab.label.trim();
      if (name.isEmpty) {
        issues.add(const ConfigIssue(ConfigIssueKind.slabNameRequired));
      }
      if (slab.components.isEmpty) {
        issues.add(ConfigIssue(ConfigIssueKind.slabNeedsComponent, name));
      }
      final seen = <String>{};
      for (final c in slab.components) {
        final label = c.label.trim();
        if (label.isEmpty) {
          issues.add(ConfigIssue(ConfigIssueKind.labelRequired, name));
        } else if (!seen.add(label.toLowerCase())) {
          issues.add(ConfigIssue(ConfigIssueKind.duplicateLabel, label));
        }
        if (c.rateBp < 0 || c.rateBp > maxRateBp) {
          issues.add(ConfigIssue(ConfigIssueKind.rateOutOfRange, label));
        }
      }
      if (TaxSlabInfo.totalOf(slab.components) > maxRateBp) {
        issues.add(ConfigIssue(ConfigIssueKind.slabTotalTooHigh, name));
      }
      if (slab.enabled) {
        final set = totals.putIfAbsent(slab.scheme, () => <int>{});
        if (!set.add(slab.rateBp)) {
          issues.add(ConfigIssue(ConfigIssueKind.duplicateTotal, name));
        }
        if (slab.isDefault && slab.scheme == TaxScheme.standard) {
          hasDefault = true;
        }
      }
    }
    if (config.slabs.isNotEmpty && !hasDefault) {
      issues.add(const ConfigIssue(ConfigIssueKind.noDefaultSlab));
    }
    final codes = <String>{};
    for (final f in config.forex) {
      if (f.rateMicro <= 0) {
        issues.add(ConfigIssue(ConfigIssueKind.forexRateInvalid, f.code));
      }
      if (!codes.add(f.code)) {
        issues.add(ConfigIssue(ConfigIssueKind.forexDuplicate, f.code));
      }
    }
    return issues;
  }
}
