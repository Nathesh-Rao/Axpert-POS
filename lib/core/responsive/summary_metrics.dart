import 'clamp_rule.dart';

/// Bill Summary density: normal, compact (height <= 960), tight (<= 820).
enum SummaryDensity { normal, compact, tight }

/// Bill Summary sizes for one density (`css_metrics.md` section 13). Normal is
/// the base block with its `clamp(vh/vw)` rules; compact (height <= 960) and
/// tight (height <= 820) are the later media blocks, cascade-resolved in file
/// order. Pure Dart: the panel arrives in S4.a and only reads these values.
class SummaryMetrics {
  const SummaryMetrics({
    required this.density,
    required this.panelPad,
    required this.gap,
    required this.titleHeight,
    required this.titleFont,
    required this.cardPad,
    required this.rowHeight,
    required this.rowFont,
    required this.rowValueFont,
    required this.invoiceHeight,
    required this.invoicePad,
    required this.invoiceLabelFont,
    required this.invoiceTotalFont,
    required this.currencyRowHeight,
    required this.currencyRowFont,
    required this.rateLabelHeight,
    required this.membershipGap,
    required this.membershipLabelGap,
    required this.membershipInputHeight,
    required this.membershipFont,
    required this.applyDiscountHeight,
    required this.applyDiscountMarginBottom,
    required this.applyDiscountFont,
    required this.checkoutPad,
    required this.checkoutGap,
    required this.paymentButtonHeight,
    required this.paymentButtonFont,
    required this.inlineGap,
    required this.inlineAmountHeight,
    required this.tenderedHeight,
    required this.tenderedPadY,
    required this.tenderedFont,
    required this.rateFont,
    required this.quickAmountHeight,
    required this.quickAmountFont,
    required this.completeHeight,
    required this.completeFont,
    required this.terminalHeight,
    required this.declineHeight,
    required this.quickActionsGap,
    required this.quickActionSize,
  });

  /// `clamp(18px,1.25vw,22px)` capped to what fits in the input: the inner
  /// height (field height minus the 2 px border and both paddings) over the
  /// input line height.
  /// Line height factor of the tendered and rate texts.
  static const double inputLineHeight = 1.15;

  static double _tenderedFont(double height, double padY, ClampRule c) {
    final fits = (height - 2 - 2 * padY) / inputLineHeight;
    final wanted = c.vw(18, 1.25, 22);
    return wanted < fits ? wanted : fits;
  }

  /// Height of the rate row text box: the label height, or the font's line
  /// (1.2) when that is taller, so the text is never cut.
  double get rateRowHeight {
    final line = (rateFont * inputLineHeight).ceilToDouble();
    return line > rateLabelHeight ? line : rateLabelHeight;
  }

  /// Smallest padding between a card's border and its content, the smallest
  /// gap between a label and its input, the smallest gap between two rows
  /// inside a card and the smallest clearance between an input's text and its
  /// focus ring (user-approved deviations from the tight and compact media
  /// rules, DEC-100).
  static const double minCardInset = 8;
  static const double minLabelGap = 4;
  static const double minRowGap = 4;
  static const double minRingClearance = 4;

  static double _atLeast(double value, double min) => value < min ? min : value;

  /// Smallest gap between two cards (and the quick actions) and the largest
  /// one free height is spread to before it collects between the member card
  /// and the checkout section (user-approved deviation from the media rules,
  /// DEC-099).
  static const double minCardGap = 8;
  static const double maxCardGap = 16;

  /// The gap this density starts from: the CSS gap, never below [minCardGap].
  double get baseGap => gap < minCardGap ? minCardGap : gap;

  /// Values for [density] in a window of [c]'s size.
  factory SummaryMetrics.of(SummaryDensity density, ClampRule c) {
    switch (density) {
      case SummaryDensity.normal:
        return SummaryMetrics(
          density: density,
          panelPad: c.vh(14, 1.6, 20),
          gap: c.vh(8, .75, 12),
          titleHeight: 24,
          titleFont: c.vw(18, 1.25, 22),
          cardPad: _atLeast(c.vh(6, .8, 10), minCardInset),
          rowHeight: c.vh(28, 3.2, 34),
          rowFont: 13,
          rowValueFont: c.vw(13, .95, 16),
          invoiceHeight: c.vh(52, 5.6, 68),
          invoicePad: 8,
          invoiceLabelFont: c.vw(14, .9, 17),
          invoiceTotalFont: c.vh(25, 2.5, 32),
          currencyRowHeight: 40,
          currencyRowFont: 13,
          rateLabelHeight: 14,
          membershipGap: 10,
          membershipLabelGap: 4,
          membershipInputHeight: 38,
          membershipFont: 13,
          applyDiscountHeight: 32,
          applyDiscountMarginBottom: 12,
          applyDiscountFont: c.vw(11, .8, 14),
          checkoutPad: c.vh(10, 1.3, 16),
          checkoutGap: 10,
          paymentButtonHeight: c.vh(46, 6.5, 56),
          paymentButtonFont: c.vw(16, 1.1, 20),
          inlineGap: c.vh(8, .75, 12),
          inlineAmountHeight: 24,
          tenderedHeight: 44,
          tenderedPadY: 8,
          tenderedFont: _tenderedFont(44, 8, c),
          rateFont: 12,
          quickAmountHeight: 36,
          quickAmountFont: 13,
          completeHeight: 48,
          completeFont: 15,
          terminalHeight: 90,
          declineHeight: 54,
          quickActionsGap: 10,
          quickActionSize: c.vh(44, 5.2, 52),
        );
      case SummaryDensity.compact:
        return SummaryMetrics(
          density: density,
          panelPad: 14,
          gap: 4,
          titleHeight: 22,
          titleFont: 18,
          cardPad: minCardInset,
          rowHeight: c.vh(24, 3.1, 28),
          rowFont: 13,
          rowValueFont: c.vw(13, .95, 16),
          invoiceHeight: c.vh(44, 5.5, 52),
          invoicePad: 6,
          invoiceLabelFont: c.vw(14, .9, 17),
          invoiceTotalFont: 25,
          currencyRowHeight: 32,
          currencyRowFont: 13,
          rateLabelHeight: 12,
          membershipGap: 6,
          membershipLabelGap: minLabelGap,
          membershipInputHeight: 28,
          membershipFont: 12,
          applyDiscountHeight: 32,
          applyDiscountMarginBottom: 12,
          applyDiscountFont: c.vw(11, .8, 14),
          checkoutPad: 8,
          checkoutGap: 8,
          paymentButtonHeight: 40,
          paymentButtonFont: c.vw(16, 1.1, 20),
          inlineGap: 4,
          inlineAmountHeight: 22,
          tenderedHeight: 34,
          tenderedPadY: 4,
          tenderedFont: _tenderedFont(34, 4, c),
          rateFont: 12,
          quickAmountHeight: 28,
          quickAmountFont: 13,
          completeHeight: 34,
          completeFont: 14,
          terminalHeight: 68,
          declineHeight: 46,
          quickActionsGap: 10,
          quickActionSize: 40,
        );
      case SummaryDensity.tight:
        return SummaryMetrics(
          density: density,
          panelPad: 14,
          gap: 3,
          titleHeight: 20,
          titleFont: 17,
          cardPad: minCardInset,
          rowHeight: 21,
          rowFont: 12,
          rowValueFont: 13,
          invoiceHeight: 42,
          invoicePad: 5,
          invoiceLabelFont: 13,
          invoiceTotalFont: 24,
          currencyRowHeight: 28,
          currencyRowFont: 12,
          rateLabelHeight: 12,
          membershipGap: minRowGap,
          membershipLabelGap: minLabelGap,
          membershipInputHeight: 22,
          membershipFont: 12,
          applyDiscountHeight: 27,
          applyDiscountMarginBottom: 4,
          applyDiscountFont: 11,
          checkoutPad: minCardInset,
          checkoutGap: 6,
          paymentButtonHeight: 30,
          paymentButtonFont: c.vw(16, 1.1, 20),
          inlineGap: minRowGap,
          inlineAmountHeight: 20,
          tenderedHeight: 30,
          tenderedPadY: 4,
          tenderedFont: _tenderedFont(30, 4, c),
          rateFont: 10,
          quickAmountHeight: 24,
          quickAmountFont: 12,
          completeHeight: 28,
          completeFont: 13,
          terminalHeight: 64,
          declineHeight: 40,
          quickActionsGap: minRowGap,
          quickActionSize: 30,
        );
    }
  }

  final SummaryDensity density;
  final double panelPad;
  final double gap;
  final double titleHeight;
  final double titleFont;
  final double cardPad;
  final double rowHeight;
  final double rowFont;
  final double rowValueFont;
  final double invoiceHeight;
  final double invoicePad;
  final double invoiceLabelFont;
  final double invoiceTotalFont;
  final double currencyRowHeight;
  final double currencyRowFont;
  final double rateLabelHeight;
  final double membershipGap;
  final double membershipLabelGap;
  final double membershipInputHeight;
  final double membershipFont;
  final double applyDiscountHeight;
  final double applyDiscountMarginBottom;
  final double applyDiscountFont;
  final double checkoutPad;
  final double checkoutGap;
  final double paymentButtonHeight;
  final double paymentButtonFont;
  final double inlineGap;
  final double inlineAmountHeight;
  final double tenderedHeight;

  /// Vertical padding and font of the tendered input. The CSS keeps the
  /// clamp font and 8 px padding at every density, which clips the value in a
  /// 32 to 34 px field; here the padding shrinks and the font is capped so the
  /// text always fits (user-approved, DEC-099).
  final double tenderedPadY;
  final double tenderedFont;

  /// `.rate-label input` font (10 when tight).
  final double rateFont;
  final double quickAmountHeight;
  final double quickAmountFont;
  final double completeHeight;
  final double completeFont;
  final double terminalHeight;
  final double declineHeight;
  final double quickActionsGap;
  final double quickActionSize;
}

/// Height <= 719: the member card collapses to a one-line header and the form
/// floats (`.member-compact`, `.member-card.member-open .membership`).
class MemberCardMetrics {
  const MemberCardMetrics._();

  static const double compactMinHeight = 34;
  static const double compactPadY = SummaryMetrics.minCardInset;
  static const double compactPadX = SummaryMetrics.minCardInset;
  static const double compactGap = 6;
  static const double compactFont = 12;
  static const double floatingPad = 16;
  static const double floatingInputHeight = 38;
  static const double floatingRight = 24;

  /// `top: clamp(100px, 22vh, 180px)`.
  static double floatingTop(ClampRule c) => c.vh(100, 22, 180);

  /// `width: calc(var(--summary-width) - 36px)`.
  static double floatingWidth(double summaryWidth) => summaryWidth - 36;
}
