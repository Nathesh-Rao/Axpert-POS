import 'package:flutter/widgets.dart';

import '../../../../core/services/pricing/decimal_parser.dart';
import '../../../../core/services/pricing/tax_components.dart';
import '../../../../core/utils/decimal_text.dart';
import '../../../session/domain/entities/session_entities.dart';
import '../../domain/entities/store_config.dart';

/// Text of a rate field that cannot be read (never a valid rate).
const int invalidRate = -1;

int _parse(String text, int scale) {
  try {
    return DecimalParser.parseScaled(text, scale);
  } on FormatException {
    return invalidRate;
  }
}

/// The editable state of one tax component of a slab.
class ComponentDraft {
  ComponentDraft({
    String label = '',
    int rateBp = 0,
    this.enabled = true,
    this.custom = false,
  }) : label = TextEditingController(text: label),
       rate = TextEditingController(text: DecimalText.scaled(rateBp, 2));

  final TextEditingController label;

  /// Percent text (`9`, `12.5`).
  final TextEditingController rate;
  bool enabled;

  /// The label was typed (the picker shows "Custom").
  bool custom;

  TaxComponent toComponent() => TaxComponent(
    label: label.text.trim(),
    rateBp: _parse(rate.text, 2),
    enabled: enabled,
  );

  void dispose() {
    label.dispose();
    rate.dispose();
  }
}

/// The editable state of one tax slab.
class SlabDraft {
  SlabDraft({
    this.id = '',
    String name = '',
    this.scheme = TaxScheme.standard,
    this.enabled = true,
    this.isDefault = false,
    List<ComponentDraft>? components,
  }) : name = TextEditingController(text: name),
       components = components ?? <ComponentDraft>[];

  final String id;
  final TextEditingController name;
  final String scheme;
  bool enabled;
  bool isDefault;
  final List<ComponentDraft> components;

  TaxSlabInfo toSlab() => TaxSlabInfo.of(
    id: id,
    name: name.text.trim(),
    scheme: scheme,
    enabled: enabled,
    isDefault: isDefault,
    components: [for (final c in components) c.toComponent()],
  );

  void dispose() {
    name.dispose();
    for (final c in components) {
      c.dispose();
    }
  }
}

/// The editable state of one exchange rate row.
class ForexDraft {
  ForexDraft({
    required this.code,
    int rateMicro = 0,
    this.active = true,
    this.updatedAtMs = 0,
  }) : rate = TextEditingController(
         text: rateMicro == 0 ? '' : DecimalText.scaled(rateMicro, 6),
       );

  String code;
  final TextEditingController rate;
  bool active;
  final int updatedAtMs;

  ForexRow toRow() => ForexRow(
    code: code,
    rateMicro: _parse(rate.text, 6),
    active: active,
    updatedAtMs: updatedAtMs,
  );

  void dispose() => rate.dispose();
}
