// TEMPORARY (DEC-065): debug-only token swatch for checking that Roboto
// Condensed and the tokens render on macOS and Chrome. Delete in step 1.4c,
// together with its use in main.dart and the specimen golden. Its labels are
// not in AppStrings on purpose.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app_theme.dart';
import '../theme_x.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class ThemeSwatchPage extends StatefulWidget {
  const ThemeSwatchPage({super.key, this.initialDark = false});

  final bool initialDark;

  @override
  State<ThemeSwatchPage> createState() => _ThemeSwatchPageState();
}

class _ThemeSwatchPageState extends State<ThemeSwatchPage> {
  late bool _dark = widget.initialDark;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _dark ? AppTheme.dark : AppTheme.light,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: context.colors.card,
            title: Text(
              'TEMPORARY token swatch (debug only)',
              style: context.text.of(
                AppFontSize.s18,
                weight: AppFontWeight.bold,
              ),
            ),
            actions: [
              Switch(value: _dark, onChanged: (v) => setState(() => _dark = v)),
              Center(
                child: Text(
                  _dark ? 'dark (unverified)' : 'light',
                  style: context.text.of(AppFontSize.s12),
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
            ],
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.panelPad),
            child: _SwatchBody(),
          ),
        ),
      ),
    );
  }
}

class _SwatchBody extends StatelessWidget {
  const _SwatchBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Heading(
          'Screenshot probes (same text as the reference screenshots)',
        ),
        const _Probes(),
        const _Heading('Typography: Roboto Condensed 400 / 500 / 600 / 700'),
        for (final weight in AppFontWeight.values)
          Text(
            'Aa Bb 0123456789 Rs.1,25,000.00 Quick brown fox  (${weight.name})',
            style: context.text.of(AppFontSize.s20, weight: weight),
          ),
        Text(
          'Axpert POS',
          style: context.text.of(
            AppFontSize.s26,
            weight: AppFontWeight.bold,
            letterSpacing: AppTracking.brand,
          ),
        ),
        for (final size in AppFontSize.values)
          Text(
            '${size.px.toInt()}px  The quick brown fox jumps over the lazy dog',
            style: context.text.of(size),
          ),
        const _Heading('Lucide icons (package lucide_icons_flutter)'),
        Wrap(
          spacing: AppSpacing.s16,
          children: [
            for (final icon in const <IconData>[
              LucideIcons.shoppingCart,
              LucideIcons.package,
              LucideIcons.users,
              LucideIcons.fileText,
              LucideIcons.undo2,
              LucideIcons.trash2,
              LucideIcons.search,
              LucideIcons.star,
              LucideIcons.banknote,
              LucideIcons.creditCard,
            ])
              Icon(icon, size: AppSizes.paymentIcon, color: colors.blue),
          ],
        ),
        const _Heading('Colors'),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final e in colors.toMap().entries)
              _Swatch(name: e.key, color: e.value),
          ],
        ),
        const _Heading('Shadows'),
        Wrap(
          spacing: AppSpacing.s24,
          runSpacing: AppSpacing.s24,
          children: [
            for (final e in AppShadows.all.entries)
              Container(
                width: 120,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(AppRadii.r10),
                  boxShadow: AppShadows.boxShadows(e.value),
                ),
                child: Text(e.key, style: context.text.of(AppFontSize.s11)),
              ),
          ],
        ),
        const _Heading('Radii'),
        Wrap(
          spacing: AppSpacing.s12,
          children: [
            for (final e in AppRadii.all.entries)
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.actionBlueBg,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(e.value.toDouble()),
                ),
                child: Text(e.key, style: context.text.of(AppFontSize.s10)),
              ),
          ],
        ),
      ],
    );
  }
}

/// Text and fills copied from the POS screenshot (brand, Bill Summary rows,
/// invoice) so the golden can be compared with the screenshot crops.
class _Probes extends StatelessWidget {
  const _Probes();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Wrap(
      spacing: AppSpacing.s24,
      runSpacing: AppSpacing.s16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Axpert POS',
          style: text.of(
            AppFontSize.s26,
            weight: AppFontWeight.bold,
            letterSpacing: AppTracking.brand,
          ),
        ),
        Text(
          'Bill Summary',
          style: text.of(AppFontSize.s22, weight: AppFontWeight.bold),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Subtotal',
              style: text
                  .of(AppFontSize.s13)
                  .copyWith(color: colors.summaryRowText),
            ),
            const SizedBox(width: AppSpacing.s24),
            Text(
              '\u20b90.00',
              style: text.of(AppFontSize.s16, weight: AppFontWeight.bold),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s8),
          decoration: BoxDecoration(
            color: colors.invoiceBg,
            borderRadius: BorderRadius.circular(AppRadii.r10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Invoice Total',
                style: text
                    .of(AppFontSize.s17, weight: AppFontWeight.bold)
                    .copyWith(color: colors.invoiceFg),
              ),
              const SizedBox(width: AppSpacing.s24),
              Text(
                '\u20b90.00',
                style: text
                    .of(
                      AppFontSize.s26,
                      weight: AppFontWeight.bold,
                      letterSpacing: AppTracking.invoiceTotal,
                    )
                    .copyWith(color: colors.invoiceFg),
              ),
            ],
          ),
        ),
        Text(
          'POS',
          style: text.of(AppFontSize.s12).copyWith(color: colors.blue),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.s24,
        bottom: AppSpacing.s8,
      ),
      child: Text(
        label,
        style: context.text.of(AppFontSize.s16, weight: AppFontWeight.bold),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadii.r6),
              border: Border.all(color: context.colors.border),
            ),
          ),
          Text(name, style: context.text.of(AppFontSize.s10)),
          Text(
            '#$hex',
            style: context.text
                .of(AppFontSize.s9)
                .copyWith(color: context.colors.muted),
          ),
        ],
      ),
    );
  }
}
