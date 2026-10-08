// GENERATED once from the css_metrics.md color tables (see docs/css_metrics.md);
// maintained by hand from here on. Every value traces to a CSS rule listed in
// that document, and test/core/theme/css_metrics_test.dart asserts they match.
//
// Color literals: CSS `#rrggbb` -> `0xFFRRGGBB`; CSS `#rrggbbaa` -> `0xAARRGGBB`.
// Dark mode replicates the 13 `.dark` rules of the prototype only. Every other
// value is identical in both modes (known_gaps.md section C), UNVERIFIED VISUALLY.
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.card,
    required this.secondary,
    required this.text,
    required this.muted,
    required this.border,
    required this.blue,
    required this.white,
    required this.summaryRowText,
    required this.labelText,
    required this.placeholder,
    required this.globalSearchFg,
    required this.fieldIcon,
    required this.searchFieldFg,
    required this.focusRing,
    required this.primary,
    required this.primaryGreen,
    required this.actionBlueBg,
    required this.actionBlueFg,
    required this.actionBlueHover,
    required this.actionRedBg,
    required this.actionRedFg,
    required this.actionRedHover,
    required this.actionPurpleBg,
    required this.actionPurpleFg,
    required this.actionPurpleHover,
    required this.actionOrangeBg,
    required this.actionOrangeFg,
    required this.actionOrangeHover,
    required this.actionNeutralBg,
    required this.actionNeutralFg,
    required this.actionNeutralHover,
    required this.actionHoverRing,
    required this.smallBadge,
    required this.discountDot,
    required this.clearHoldClock,
    required this.invoiceBg,
    required this.invoiceFg,
    required this.applyDiscountBg,
    required this.payCashTop,
    required this.payCashBottom,
    required this.payCashIdleFg,
    required this.payCashIdleBorder,
    required this.payCardTop,
    required this.payCardBottom,
    required this.payCardIdleFg,
    required this.payCardIdleBorder,
    required this.completeDisabledBg,
    required this.completeDisabledFg,
    required this.completeDisabledBorder,
    required this.quickAmountBg,
    required this.quickAmountHover,
    required this.changeDueGreen,
    required this.shortChangeRed,
    required this.terminalApproved,
    required this.terminalDeclined,
    required this.terminalDeclinedModal,
    required this.terminalApprovedModal,
    required this.selectedLineBg,
    required this.selectedLineBorder,
    required this.qtyButtonBg,
    required this.qtyButtonFg,
    required this.qtyButtonHoverBg,
    required this.qtyButtonHoverFg,
    required this.qtyRemoveBg,
    required this.qtyRemoveFg,
    required this.qtyRing,
    required this.trashFg,
    required this.trashBg,
    required this.trashHoverBg,
    required this.lineEditBorder,
    required this.qtyBadgeBg,
    required this.qtyBadgeFg,
    required this.highlightBg,
    required this.highlightBorder,
    required this.sidebarActiveTop,
    required this.sidebarActiveBottom,
    required this.sidebarHover,
    required this.onlineDot,
    required this.offlineDot,
    required this.notificationDot,
    required this.avatarBg,
    required this.avatarBorder,
    required this.brandMark,
    required this.brandMarkShadow,
    required this.offlineBannerBg,
    required this.offlineBannerFg,
    required this.categoryStar,
    required this.categoryIcon3,
    required this.categoryIcon4,
    required this.categoryIcon5,
    required this.categorySelectedTop,
    required this.categorySelectedBottom,
    required this.selectedTabBg,
    required this.viewToggleFg,
    required this.productHoverBorder,
    required this.productInCartBorder,
    required this.productStepperBg,
    required this.favouriteFg,
    required this.favouriteActive,
    required this.favouriteFill,
    required this.scrollThumb,
    required this.scrollThumbCart,
    required this.stockOkBg,
    required this.stockOkFg,
    required this.stockLowBg,
    required this.stockLowFg,
    required this.greenIcon,
    required this.saleToggleIdleFg,
    required this.radioBorder,
    required this.cashChosenFg,
    required this.cashChosenBg,
    required this.creditChosenFg,
    required this.creditChosenBg,
    required this.validation,
    required this.toastSuccess,
    required this.toastSuccessIcon,
    required this.toastError,
    required this.toastWarning,
    required this.toastInfo,
    required this.tooltipBg,
    required this.modalOverlay,
    required this.modalSymbolBg,
    required this.modalSymbolGreenBg,
    required this.modalSymbolGreenFg,
    required this.spinnerTrack,
    required this.chartTop,
    required this.chartBottom,
    required this.productImageMultiply,
    required this.productImageRadius,
    required this.quickActionHoverBrightness,
  });

  // Core
  final Color background;
  final Color card;
  final Color secondary;
  final Color text;
  final Color muted;
  final Color border;
  final Color blue;
  final Color white;
  final Color summaryRowText;
  final Color labelText;
  final Color placeholder;
  final Color globalSearchFg;
  final Color fieldIcon;
  final Color searchFieldFg;
  final Color focusRing;
  // Buttons and actions
  final Color primary;
  final Color primaryGreen;
  final Color actionBlueBg;
  final Color actionBlueFg;
  final Color actionBlueHover;
  final Color actionRedBg;
  final Color actionRedFg;
  final Color actionRedHover;
  final Color actionPurpleBg;
  final Color actionPurpleFg;
  final Color actionPurpleHover;
  final Color actionOrangeBg;
  final Color actionOrangeFg;
  final Color actionOrangeHover;
  final Color actionNeutralBg;
  final Color actionNeutralFg;
  final Color actionNeutralHover;
  final Color actionHoverRing;
  final Color smallBadge;
  final Color discountDot;
  final Color clearHoldClock;
  final Color invoiceBg;
  final Color invoiceFg;
  final Color applyDiscountBg;
  // Payment
  final Color payCashTop;
  final Color payCashBottom;
  final Color payCashIdleFg;
  final Color payCashIdleBorder;
  final Color payCardTop;
  final Color payCardBottom;
  final Color payCardIdleFg;
  final Color payCardIdleBorder;
  final Color completeDisabledBg;
  final Color completeDisabledFg;
  final Color completeDisabledBorder;
  final Color quickAmountBg;
  final Color quickAmountHover;
  final Color changeDueGreen;
  final Color shortChangeRed;
  final Color terminalApproved;
  final Color terminalDeclined;
  final Color terminalDeclinedModal;
  final Color terminalApprovedModal;
  // Cart and lines
  final Color selectedLineBg;
  final Color selectedLineBorder;
  final Color qtyButtonBg;
  final Color qtyButtonFg;
  final Color qtyButtonHoverBg;
  final Color qtyButtonHoverFg;
  final Color qtyRemoveBg;
  final Color qtyRemoveFg;
  final Color qtyRing;
  final Color trashFg;
  final Color trashBg;
  final Color trashHoverBg;
  final Color lineEditBorder;
  final Color qtyBadgeBg;
  final Color qtyBadgeFg;
  final Color highlightBg;
  final Color highlightBorder;
  // Navigation and topbar
  final Color sidebarActiveTop;
  final Color sidebarActiveBottom;
  final Color sidebarHover;
  final Color onlineDot;
  final Color offlineDot;
  final Color notificationDot;
  final Color avatarBg;
  final Color avatarBorder;
  final Color brandMark;
  final Color brandMarkShadow;
  final Color offlineBannerBg;
  final Color offlineBannerFg;
  // Catalog
  final Color categoryStar;
  final Color categoryIcon3;
  final Color categoryIcon4;
  final Color categoryIcon5;
  final Color categorySelectedTop;
  final Color categorySelectedBottom;
  final Color selectedTabBg;
  final Color viewToggleFg;
  final Color productHoverBorder;
  final Color productInCartBorder;
  final Color productStepperBg;
  final Color favouriteFg;
  final Color favouriteActive;
  final Color favouriteFill;
  final Color scrollThumb;
  final Color scrollThumbCart;
  final Color stockOkBg;
  final Color stockOkFg;
  final Color stockLowBg;
  final Color stockLowFg;
  // Sale type and status
  final Color greenIcon;
  final Color saleToggleIdleFg;
  final Color radioBorder;
  final Color cashChosenFg;
  final Color cashChosenBg;
  final Color creditChosenFg;
  final Color creditChosenBg;
  final Color validation;
  // Overlays and feedback
  final Color toastSuccess;
  final Color toastSuccessIcon;
  final Color toastError;
  final Color toastWarning;
  final Color toastInfo;
  final Color tooltipBg;
  final Color modalOverlay;
  final Color modalSymbolBg;
  final Color modalSymbolGreenBg;
  final Color modalSymbolGreenFg;
  final Color spinnerTrack;
  final Color chartTop;
  final Color chartBottom;

  // Mode behaviours (not colors) that the prototype switches under `.dark`.

  /// `.product-image img { mix-blend-mode }`: multiply in light, normal in dark.
  final bool productImageMultiply;

  /// `.dark .product-image img { border-radius: 4px }` (0 = no rule in light).
  final double productImageRadius;

  /// `.quick-actions .action:hover` filter: none in light, brightness(1.2) in dark.
  final double quickActionHoverBrightness;

  /// Light palette (the prototype's `:root`).
  static const AppColors light = AppColors(
    background: Color(0xFFEFF4F9), // #eff4f9
    card: Color(0xFFFFFFFF), // #ffffff
    secondary: Color(0xFFF3F6FA), // #f3f6fa
    text: Color(0xFF102047), // #102047
    muted: Color(0xFF7585A4), // #7585a4
    border: Color(0xFFE4EBF4), // #e4ebf4
    blue: Color(0xFF0061FF), // #0061ff
    white: Color(0xFFFFFFFF), // #ffffff
    summaryRowText: Color(0xFF526584), // #526584
    labelText: Color(0xFF526584), // #526584
    placeholder: Color(0xFF8A99B4), // #8a99b4
    globalSearchFg: Color(0xFF536584), // #536584
    fieldIcon: Color(0xFF506483), // #506483
    searchFieldFg: Color(0xFF526581), // #526581
    focusRing: Color(0xFF78AAFF), // #78aaff
    primary: Color(0xFF0968EE), // #0968ee
    primaryGreen: Color(0xFF049667), // #049667
    actionBlueBg: Color(0xFFEDF5FF), // #edf5ff
    actionBlueFg: Color(0xFF0060FF), // #0060ff
    actionBlueHover: Color(0xFFDBEAFF), // #dbeaff
    actionRedBg: Color(0xFFFFF0F3), // #fff0f3
    actionRedFg: Color(0xFFFF2036), // #ff2036
    actionRedHover: Color(0xFFFFE1E8), // #ffe1e8
    actionPurpleBg: Color(0xFFF1EDFF), // #f1edff
    actionPurpleFg: Color(0xFF7A20FF), // #7a20ff
    actionPurpleHover: Color(0xFFE6DCFF), // #e6dcff
    actionOrangeBg: Color(0xFFFFF6EB), // #fff6eb
    actionOrangeFg: Color(0xFFDB7900), // #db7900
    actionOrangeHover: Color(0xFFFFECD1), // #ffecd1
    actionNeutralBg: Color(0xFFEFF0F3), // #eff0f3
    actionNeutralFg: Color(0xFF14203B), // #14203b
    actionNeutralHover: Color(0xFFDFE4ED), // #dfe4ed
    actionHoverRing: Color(0x33729BD4), // #729bd433
    smallBadge: Color(0xFF743DF2), // #743df2
    discountDot: Color(0xFFF02B4A), // #f02b4a
    clearHoldClock: Color(0xFFFFF0F3), // #fff0f3
    invoiceBg: Color(0xFFEDF5FF), // #edf5ff
    invoiceFg: Color(0xFF005CFF), // #005cff
    applyDiscountBg: Color(0xFFEDF5FF), // #edf5ff
    payCashTop: Color(0xFF2CAA78), // #2caa78
    payCashBottom: Color(0xFF05945D), // #05945d
    payCashIdleFg: Color(0xFF078B5C), // #078b5c
    payCashIdleBorder: Color(0xFFACD9C7), // #acd9c7
    payCardTop: Color(0xFF4796FF), // #4796ff
    payCardBottom: Color(0xFF0860EF), // #0860ef
    payCardIdleFg: Color(0xFF166EE3), // #166ee3
    payCardIdleBorder: Color(0xFFB1CDF4), // #b1cdf4
    completeDisabledBg: Color(0xFFDBE7E3), // #dbe7e3
    completeDisabledFg: Color(0xFF71847D), // #71847d
    completeDisabledBorder: Color(0xFFCCDBD5), // #ccdbd5
    quickAmountBg: Color(0xFFF0F6FF), // #f0f6ff
    quickAmountHover: Color(0xFFD9EAFF), // #d9eaff
    changeDueGreen: Color(0xFF03965D), // #03965d
    shortChangeRed: Color(0xFFD92F4A), // #d92f4a
    terminalApproved: Color(0xFF079567), // #079567
    terminalDeclined: Color(0xFFDF354D), // #df354d
    terminalDeclinedModal: Color(0xFFEC354D), // #ec354d
    terminalApprovedModal: Color(0xFF079567), // #079567
    selectedLineBg: Color(0xFFF0F6FF), // #f0f6ff
    selectedLineBorder: Color(0xFFADCBF5), // #adcbf5
    qtyButtonBg: Color(0xFFEDF2F8), // #edf2f8
    qtyButtonFg: Color(0xFF38567F), // #38567f
    qtyButtonHoverBg: Color(0xFFDBEAFF), // #dbeaff
    qtyButtonHoverFg: Color(0xFF0061EE), // #0061ee
    qtyRemoveBg: Color(0xFFFFEDF1), // #ffedf1
    qtyRemoveFg: Color(0xFFE62D49), // #e62d49
    qtyRing: Color(0xFFDBE5F3), // #dbe5f3
    trashFg: Color(0xFFFF263C), // #ff263c
    trashBg: Color(0xFFFFF0F3), // #fff0f3
    trashHoverBg: Color(0xFFFFE0E8), // #ffe0e8
    lineEditBorder: Color(0xFFDCE5F2), // #dce5f2
    qtyBadgeBg: Color(0xFFE8F2FF), // #e8f2ff
    qtyBadgeFg: Color(0xFF0063FF), // #0063ff
    highlightBg: Color(0xFFDCF0FF), // #dcf0ff
    highlightBorder: Color(0xFF69B1FF), // #69b1ff
    sidebarActiveTop: Color(0xFFDFEAFF), // #dfeaff
    sidebarActiveBottom: Color(0xFFE8F3FF), // #e8f3ff
    sidebarHover: Color(0x77DFEAFF), // #dfeaff77
    onlineDot: Color(0xFF05A76C), // #05a76c
    offlineDot: Color(0xFFEDAB24), // #edab24
    notificationDot: Color(0xFFFF293E), // #ff293e
    avatarBg: Color(0xFF657793), // #657793
    avatarBorder: Color(0xFFEDF4FF), // #edf4ff
    brandMark: Color(0xFF0D63BB), // #0d63bb
    brandMarkShadow: Color(0xFFB6D6FF), // #b6d6ff
    offlineBannerBg: Color(0xFFFFF1C8), // #fff1c8
    offlineBannerFg: Color(0xFF8D5C00), // #8d5c00
    categoryStar: Color(0xFFF3A400), // #f3a400
    categoryIcon3: Color(0xFF502299), // #502299
    categoryIcon4: Color(0xFFB87516), // #b87516
    categoryIcon5: Color(0xFF673BC7), // #673bc7
    categorySelectedTop: Color(0xFF4B98FF), // #4b98ff
    categorySelectedBottom: Color(0xFF2E7CF7), // #2e7cf7
    selectedTabBg: Color(0xFFE4EFFF), // #e4efff
    viewToggleFg: Color(0xFF45658F), // #45658f
    productHoverBorder: Color(0xFF95BAFF), // #95baff
    productInCartBorder: Color(0xFFABCAFF), // #abcaff
    productStepperBg: Color(0xFFEAF3FF), // #eaf3ff
    favouriteFg: Color(0xFF92A3BF), // #92a3bf
    favouriteActive: Color(0xFFE5AE24), // #e5ae24
    favouriteFill: Color(0xFFF9CB45), // #f9cb45
    scrollThumb: Color(0xFFDBE4F1), // #dbe4f1
    scrollThumbCart: Color(0xFFC5D5EC), // #c5d5ec
    stockOkBg: Color(0xFFE2F6ED), // #e2f6ed
    stockOkFg: Color(0xFF078255), // #078255
    stockLowBg: Color(0xFFFFF0D8), // #fff0d8
    stockLowFg: Color(0xFFB76B02), // #b76b02
    greenIcon: Color(0xFF019354), // #019354
    saleToggleIdleFg: Color(0xFF647694), // #647694
    radioBorder: Color(0xFF94A4BE), // #94a4be
    cashChosenFg: Color(0xFF00824C), // #00824c
    cashChosenBg: Color(0xFFE2F5ED), // #e2f5ed
    creditChosenFg: Color(0xFF1665DB), // #1665db
    creditChosenBg: Color(0xFFE4EFFF), // #e4efff
    validation: Color(0xFFCE6D09), // #ce6d09
    toastSuccess: Color(0xFF13A274), // #13a274
    toastSuccessIcon: Color(0xFF08A575), // #08a575
    toastError: Color(0xFFEF3548), // #ef3548
    toastWarning: Color(0xFFEDAB24), // #edab24
    toastInfo: Color(0xFF3C8CFF), // #3c8cff
    tooltipBg: Color(0xFF142746), // #142746
    modalOverlay: Color(0x5510213B), // #10213b55
    modalSymbolBg: Color(0xFFE8F2FF), // #e8f2ff
    modalSymbolGreenBg: Color(0xFFE5F7EE), // #e5f7ee
    modalSymbolGreenFg: Color(0xFF06986A), // #06986a
    spinnerTrack: Color(0xFFDEEBFF), // #deebff
    chartTop: Color(0xFF479BFF), // #479bff
    chartBottom: Color(0xFF0870ED), // #0870ed
    productImageMultiply: true,
    productImageRadius: 0,
    quickActionHoverBrightness: 1,
  );

  /// Dark palette: light plus the prototype's 13 `.dark` rules, nothing else.
  static const AppColors dark = AppColors(
    background: Color(0xFF162134), // #162134
    card: Color(0xFF1D2B41), // #1d2b41
    secondary: Color(0xFF26344A), // #26344a
    text: Color(0xFFE4ECFA), // #e4ecfa
    muted: Color(0xFFA4B4CE), // #a4b4ce
    border: Color(0xFF35445E), // #35445e
    blue: Color(0xFF0061FF), // #0061ff
    white: Color(0xFFFFFFFF), // #ffffff
    summaryRowText: Color(0xFFA4B4CE), // #a4b4ce
    labelText: Color(0xFF526584), // #526584
    placeholder: Color(0xFF8A99B4), // #8a99b4
    globalSearchFg: Color(0xFF536584), // #536584
    fieldIcon: Color(0xFF506483), // #506483
    searchFieldFg: Color(0xFF526581), // #526581
    focusRing: Color(0xFF78AAFF), // #78aaff
    primary: Color(0xFF0968EE), // #0968ee
    primaryGreen: Color(0xFF049667), // #049667
    actionBlueBg: Color(0xFF233B60), // #233b60
    actionBlueFg: Color(0xFF0060FF), // #0060ff
    actionBlueHover: Color(0xFFDBEAFF), // #dbeaff
    actionRedBg: Color(0xFF492838), // #492838
    actionRedFg: Color(0xFFFF2036), // #ff2036
    actionRedHover: Color(0xFFFFE1E8), // #ffe1e8
    actionPurpleBg: Color(0xFF362C59), // #362c59
    actionPurpleFg: Color(0xFF7A20FF), // #7a20ff
    actionPurpleHover: Color(0xFFE6DCFF), // #e6dcff
    actionOrangeBg: Color(0xFF493822), // #493822
    actionOrangeFg: Color(0xFFDB7900), // #db7900
    actionOrangeHover: Color(0xFFFFECD1), // #ffecd1
    actionNeutralBg: Color(0xFF303B4E), // #303b4e
    actionNeutralFg: Color(0xFFE4ECFA), // #e4ecfa
    actionNeutralHover: Color(0xFFDFE4ED), // #dfe4ed
    actionHoverRing: Color(0x33729BD4), // #729bd433
    smallBadge: Color(0xFF743DF2), // #743df2
    discountDot: Color(0xFFF02B4A), // #f02b4a
    clearHoldClock: Color(0xFFFFF0F3), // #fff0f3
    invoiceBg: Color(0xFF233B60), // #233b60
    invoiceFg: Color(0xFF005CFF), // #005cff
    applyDiscountBg: Color(0xFF233B60), // #233b60
    payCashTop: Color(0xFF2CAA78), // #2caa78
    payCashBottom: Color(0xFF05945D), // #05945d
    payCashIdleFg: Color(0xFF078B5C), // #078b5c
    payCashIdleBorder: Color(0xFFACD9C7), // #acd9c7
    payCardTop: Color(0xFF4796FF), // #4796ff
    payCardBottom: Color(0xFF0860EF), // #0860ef
    payCardIdleFg: Color(0xFF166EE3), // #166ee3
    payCardIdleBorder: Color(0xFFB1CDF4), // #b1cdf4
    completeDisabledBg: Color(0xFFDBE7E3), // #dbe7e3
    completeDisabledFg: Color(0xFF71847D), // #71847d
    completeDisabledBorder: Color(0xFFCCDBD5), // #ccdbd5
    quickAmountBg: Color(0xFF2D4260), // #2d4260
    quickAmountHover: Color(0xFF2D4260), // #2d4260
    changeDueGreen: Color(0xFF03965D), // #03965d
    shortChangeRed: Color(0xFFD92F4A), // #d92f4a
    terminalApproved: Color(0xFF079567), // #079567
    terminalDeclined: Color(0xFFDF354D), // #df354d
    terminalDeclinedModal: Color(0xFFEC354D), // #ec354d
    terminalApprovedModal: Color(0xFF079567), // #079567
    selectedLineBg: Color(0xFF273C58), // #273c58
    selectedLineBorder: Color(0xFFADCBF5), // #adcbf5
    qtyButtonBg: Color(0xFF2D4260), // #2d4260
    qtyButtonFg: Color(0xFF38567F), // #38567f
    qtyButtonHoverBg: Color(0xFF2D4260), // #2d4260
    qtyButtonHoverFg: Color(0xFF0061EE), // #0061ee
    qtyRemoveBg: Color(0xFFFFEDF1), // #ffedf1
    qtyRemoveFg: Color(0xFFE62D49), // #e62d49
    qtyRing: Color(0xFFDBE5F3), // #dbe5f3
    trashFg: Color(0xFFFF263C), // #ff263c
    trashBg: Color(0xFFFFF0F3), // #fff0f3
    trashHoverBg: Color(0xFFFFE0E8), // #ffe0e8
    lineEditBorder: Color(0xFF35445E), // #35445e
    qtyBadgeBg: Color(0xFFE8F2FF), // #e8f2ff
    qtyBadgeFg: Color(0xFF0063FF), // #0063ff
    highlightBg: Color(0xFFDCF0FF), // #dcf0ff
    highlightBorder: Color(0xFF69B1FF), // #69b1ff
    sidebarActiveTop: Color(0xFFDFEAFF), // #dfeaff
    sidebarActiveBottom: Color(0xFFE8F3FF), // #e8f3ff
    sidebarHover: Color(0x77DFEAFF), // #dfeaff77
    onlineDot: Color(0xFF05A76C), // #05a76c
    offlineDot: Color(0xFFEDAB24), // #edab24
    notificationDot: Color(0xFFFF293E), // #ff293e
    avatarBg: Color(0xFF657793), // #657793
    avatarBorder: Color(0xFFEDF4FF), // #edf4ff
    brandMark: Color(0xFF0D63BB), // #0d63bb
    brandMarkShadow: Color(0xFFB6D6FF), // #b6d6ff
    offlineBannerBg: Color(0xFFFFF1C8), // #fff1c8
    offlineBannerFg: Color(0xFF8D5C00), // #8d5c00
    categoryStar: Color(0xFFF3A400), // #f3a400
    categoryIcon3: Color(0xFF502299), // #502299
    categoryIcon4: Color(0xFFB87516), // #b87516
    categoryIcon5: Color(0xFF673BC7), // #673bc7
    categorySelectedTop: Color(0xFF4B98FF), // #4b98ff
    categorySelectedBottom: Color(0xFF2E7CF7), // #2e7cf7
    selectedTabBg: Color(0xFFE4EFFF), // #e4efff
    viewToggleFg: Color(0xFF45658F), // #45658f
    productHoverBorder: Color(0xFF95BAFF), // #95baff
    productInCartBorder: Color(0xFFABCAFF), // #abcaff
    productStepperBg: Color(0xFFEAF3FF), // #eaf3ff
    favouriteFg: Color(0xFF92A3BF), // #92a3bf
    favouriteActive: Color(0xFFE5AE24), // #e5ae24
    favouriteFill: Color(0xFFF9CB45), // #f9cb45
    scrollThumb: Color(0xFFDBE4F1), // #dbe4f1
    scrollThumbCart: Color(0xFFC5D5EC), // #c5d5ec
    stockOkBg: Color(0xFFE2F6ED), // #e2f6ed
    stockOkFg: Color(0xFF078255), // #078255
    stockLowBg: Color(0xFFFFF0D8), // #fff0d8
    stockLowFg: Color(0xFFB76B02), // #b76b02
    greenIcon: Color(0xFF019354), // #019354
    saleToggleIdleFg: Color(0xFF647694), // #647694
    radioBorder: Color(0xFF94A4BE), // #94a4be
    cashChosenFg: Color(0xFF00824C), // #00824c
    cashChosenBg: Color(0xFFE2F5ED), // #e2f5ed
    creditChosenFg: Color(0xFF1665DB), // #1665db
    creditChosenBg: Color(0xFFE4EFFF), // #e4efff
    validation: Color(0xFFCE6D09), // #ce6d09
    toastSuccess: Color(0xFF13A274), // #13a274
    toastSuccessIcon: Color(0xFF08A575), // #08a575
    toastError: Color(0xFFEF3548), // #ef3548
    toastWarning: Color(0xFFEDAB24), // #edab24
    toastInfo: Color(0xFF3C8CFF), // #3c8cff
    tooltipBg: Color(0xFF142746), // #142746
    modalOverlay: Color(0x5510213B), // #10213b55
    modalSymbolBg: Color(0xFFE8F2FF), // #e8f2ff
    modalSymbolGreenBg: Color(0xFFE5F7EE), // #e5f7ee
    modalSymbolGreenFg: Color(0xFF06986A), // #06986a
    spinnerTrack: Color(0xFFDEEBFF), // #deebff
    chartTop: Color(0xFF479BFF), // #479bff
    chartBottom: Color(0xFF0870ED), // #0870ed
    productImageMultiply: false,
    productImageRadius: 4,
    quickActionHoverBrightness: 1.2,
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? card,
    Color? secondary,
    Color? text,
    Color? muted,
    Color? border,
    Color? blue,
    Color? white,
    Color? summaryRowText,
    Color? labelText,
    Color? placeholder,
    Color? globalSearchFg,
    Color? fieldIcon,
    Color? searchFieldFg,
    Color? focusRing,
    Color? primary,
    Color? primaryGreen,
    Color? actionBlueBg,
    Color? actionBlueFg,
    Color? actionBlueHover,
    Color? actionRedBg,
    Color? actionRedFg,
    Color? actionRedHover,
    Color? actionPurpleBg,
    Color? actionPurpleFg,
    Color? actionPurpleHover,
    Color? actionOrangeBg,
    Color? actionOrangeFg,
    Color? actionOrangeHover,
    Color? actionNeutralBg,
    Color? actionNeutralFg,
    Color? actionNeutralHover,
    Color? actionHoverRing,
    Color? smallBadge,
    Color? discountDot,
    Color? clearHoldClock,
    Color? invoiceBg,
    Color? invoiceFg,
    Color? applyDiscountBg,
    Color? payCashTop,
    Color? payCashBottom,
    Color? payCashIdleFg,
    Color? payCashIdleBorder,
    Color? payCardTop,
    Color? payCardBottom,
    Color? payCardIdleFg,
    Color? payCardIdleBorder,
    Color? completeDisabledBg,
    Color? completeDisabledFg,
    Color? completeDisabledBorder,
    Color? quickAmountBg,
    Color? quickAmountHover,
    Color? changeDueGreen,
    Color? shortChangeRed,
    Color? terminalApproved,
    Color? terminalDeclined,
    Color? terminalDeclinedModal,
    Color? terminalApprovedModal,
    Color? selectedLineBg,
    Color? selectedLineBorder,
    Color? qtyButtonBg,
    Color? qtyButtonFg,
    Color? qtyButtonHoverBg,
    Color? qtyButtonHoverFg,
    Color? qtyRemoveBg,
    Color? qtyRemoveFg,
    Color? qtyRing,
    Color? trashFg,
    Color? trashBg,
    Color? trashHoverBg,
    Color? lineEditBorder,
    Color? qtyBadgeBg,
    Color? qtyBadgeFg,
    Color? highlightBg,
    Color? highlightBorder,
    Color? sidebarActiveTop,
    Color? sidebarActiveBottom,
    Color? sidebarHover,
    Color? onlineDot,
    Color? offlineDot,
    Color? notificationDot,
    Color? avatarBg,
    Color? avatarBorder,
    Color? brandMark,
    Color? brandMarkShadow,
    Color? offlineBannerBg,
    Color? offlineBannerFg,
    Color? categoryStar,
    Color? categoryIcon3,
    Color? categoryIcon4,
    Color? categoryIcon5,
    Color? categorySelectedTop,
    Color? categorySelectedBottom,
    Color? selectedTabBg,
    Color? viewToggleFg,
    Color? productHoverBorder,
    Color? productInCartBorder,
    Color? productStepperBg,
    Color? favouriteFg,
    Color? favouriteActive,
    Color? favouriteFill,
    Color? scrollThumb,
    Color? scrollThumbCart,
    Color? stockOkBg,
    Color? stockOkFg,
    Color? stockLowBg,
    Color? stockLowFg,
    Color? greenIcon,
    Color? saleToggleIdleFg,
    Color? radioBorder,
    Color? cashChosenFg,
    Color? cashChosenBg,
    Color? creditChosenFg,
    Color? creditChosenBg,
    Color? validation,
    Color? toastSuccess,
    Color? toastSuccessIcon,
    Color? toastError,
    Color? toastWarning,
    Color? toastInfo,
    Color? tooltipBg,
    Color? modalOverlay,
    Color? modalSymbolBg,
    Color? modalSymbolGreenBg,
    Color? modalSymbolGreenFg,
    Color? spinnerTrack,
    Color? chartTop,
    Color? chartBottom,
    bool? productImageMultiply,
    double? productImageRadius,
    double? quickActionHoverBrightness,
  }) {
    return AppColors(
      background: background ?? this.background,
      card: card ?? this.card,
      secondary: secondary ?? this.secondary,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      blue: blue ?? this.blue,
      white: white ?? this.white,
      summaryRowText: summaryRowText ?? this.summaryRowText,
      labelText: labelText ?? this.labelText,
      placeholder: placeholder ?? this.placeholder,
      globalSearchFg: globalSearchFg ?? this.globalSearchFg,
      fieldIcon: fieldIcon ?? this.fieldIcon,
      searchFieldFg: searchFieldFg ?? this.searchFieldFg,
      focusRing: focusRing ?? this.focusRing,
      primary: primary ?? this.primary,
      primaryGreen: primaryGreen ?? this.primaryGreen,
      actionBlueBg: actionBlueBg ?? this.actionBlueBg,
      actionBlueFg: actionBlueFg ?? this.actionBlueFg,
      actionBlueHover: actionBlueHover ?? this.actionBlueHover,
      actionRedBg: actionRedBg ?? this.actionRedBg,
      actionRedFg: actionRedFg ?? this.actionRedFg,
      actionRedHover: actionRedHover ?? this.actionRedHover,
      actionPurpleBg: actionPurpleBg ?? this.actionPurpleBg,
      actionPurpleFg: actionPurpleFg ?? this.actionPurpleFg,
      actionPurpleHover: actionPurpleHover ?? this.actionPurpleHover,
      actionOrangeBg: actionOrangeBg ?? this.actionOrangeBg,
      actionOrangeFg: actionOrangeFg ?? this.actionOrangeFg,
      actionOrangeHover: actionOrangeHover ?? this.actionOrangeHover,
      actionNeutralBg: actionNeutralBg ?? this.actionNeutralBg,
      actionNeutralFg: actionNeutralFg ?? this.actionNeutralFg,
      actionNeutralHover: actionNeutralHover ?? this.actionNeutralHover,
      actionHoverRing: actionHoverRing ?? this.actionHoverRing,
      smallBadge: smallBadge ?? this.smallBadge,
      discountDot: discountDot ?? this.discountDot,
      clearHoldClock: clearHoldClock ?? this.clearHoldClock,
      invoiceBg: invoiceBg ?? this.invoiceBg,
      invoiceFg: invoiceFg ?? this.invoiceFg,
      applyDiscountBg: applyDiscountBg ?? this.applyDiscountBg,
      payCashTop: payCashTop ?? this.payCashTop,
      payCashBottom: payCashBottom ?? this.payCashBottom,
      payCashIdleFg: payCashIdleFg ?? this.payCashIdleFg,
      payCashIdleBorder: payCashIdleBorder ?? this.payCashIdleBorder,
      payCardTop: payCardTop ?? this.payCardTop,
      payCardBottom: payCardBottom ?? this.payCardBottom,
      payCardIdleFg: payCardIdleFg ?? this.payCardIdleFg,
      payCardIdleBorder: payCardIdleBorder ?? this.payCardIdleBorder,
      completeDisabledBg: completeDisabledBg ?? this.completeDisabledBg,
      completeDisabledFg: completeDisabledFg ?? this.completeDisabledFg,
      completeDisabledBorder:
          completeDisabledBorder ?? this.completeDisabledBorder,
      quickAmountBg: quickAmountBg ?? this.quickAmountBg,
      quickAmountHover: quickAmountHover ?? this.quickAmountHover,
      changeDueGreen: changeDueGreen ?? this.changeDueGreen,
      shortChangeRed: shortChangeRed ?? this.shortChangeRed,
      terminalApproved: terminalApproved ?? this.terminalApproved,
      terminalDeclined: terminalDeclined ?? this.terminalDeclined,
      terminalDeclinedModal:
          terminalDeclinedModal ?? this.terminalDeclinedModal,
      terminalApprovedModal:
          terminalApprovedModal ?? this.terminalApprovedModal,
      selectedLineBg: selectedLineBg ?? this.selectedLineBg,
      selectedLineBorder: selectedLineBorder ?? this.selectedLineBorder,
      qtyButtonBg: qtyButtonBg ?? this.qtyButtonBg,
      qtyButtonFg: qtyButtonFg ?? this.qtyButtonFg,
      qtyButtonHoverBg: qtyButtonHoverBg ?? this.qtyButtonHoverBg,
      qtyButtonHoverFg: qtyButtonHoverFg ?? this.qtyButtonHoverFg,
      qtyRemoveBg: qtyRemoveBg ?? this.qtyRemoveBg,
      qtyRemoveFg: qtyRemoveFg ?? this.qtyRemoveFg,
      qtyRing: qtyRing ?? this.qtyRing,
      trashFg: trashFg ?? this.trashFg,
      trashBg: trashBg ?? this.trashBg,
      trashHoverBg: trashHoverBg ?? this.trashHoverBg,
      lineEditBorder: lineEditBorder ?? this.lineEditBorder,
      qtyBadgeBg: qtyBadgeBg ?? this.qtyBadgeBg,
      qtyBadgeFg: qtyBadgeFg ?? this.qtyBadgeFg,
      highlightBg: highlightBg ?? this.highlightBg,
      highlightBorder: highlightBorder ?? this.highlightBorder,
      sidebarActiveTop: sidebarActiveTop ?? this.sidebarActiveTop,
      sidebarActiveBottom: sidebarActiveBottom ?? this.sidebarActiveBottom,
      sidebarHover: sidebarHover ?? this.sidebarHover,
      onlineDot: onlineDot ?? this.onlineDot,
      offlineDot: offlineDot ?? this.offlineDot,
      notificationDot: notificationDot ?? this.notificationDot,
      avatarBg: avatarBg ?? this.avatarBg,
      avatarBorder: avatarBorder ?? this.avatarBorder,
      brandMark: brandMark ?? this.brandMark,
      brandMarkShadow: brandMarkShadow ?? this.brandMarkShadow,
      offlineBannerBg: offlineBannerBg ?? this.offlineBannerBg,
      offlineBannerFg: offlineBannerFg ?? this.offlineBannerFg,
      categoryStar: categoryStar ?? this.categoryStar,
      categoryIcon3: categoryIcon3 ?? this.categoryIcon3,
      categoryIcon4: categoryIcon4 ?? this.categoryIcon4,
      categoryIcon5: categoryIcon5 ?? this.categoryIcon5,
      categorySelectedTop: categorySelectedTop ?? this.categorySelectedTop,
      categorySelectedBottom:
          categorySelectedBottom ?? this.categorySelectedBottom,
      selectedTabBg: selectedTabBg ?? this.selectedTabBg,
      viewToggleFg: viewToggleFg ?? this.viewToggleFg,
      productHoverBorder: productHoverBorder ?? this.productHoverBorder,
      productInCartBorder: productInCartBorder ?? this.productInCartBorder,
      productStepperBg: productStepperBg ?? this.productStepperBg,
      favouriteFg: favouriteFg ?? this.favouriteFg,
      favouriteActive: favouriteActive ?? this.favouriteActive,
      favouriteFill: favouriteFill ?? this.favouriteFill,
      scrollThumb: scrollThumb ?? this.scrollThumb,
      scrollThumbCart: scrollThumbCart ?? this.scrollThumbCart,
      stockOkBg: stockOkBg ?? this.stockOkBg,
      stockOkFg: stockOkFg ?? this.stockOkFg,
      stockLowBg: stockLowBg ?? this.stockLowBg,
      stockLowFg: stockLowFg ?? this.stockLowFg,
      greenIcon: greenIcon ?? this.greenIcon,
      saleToggleIdleFg: saleToggleIdleFg ?? this.saleToggleIdleFg,
      radioBorder: radioBorder ?? this.radioBorder,
      cashChosenFg: cashChosenFg ?? this.cashChosenFg,
      cashChosenBg: cashChosenBg ?? this.cashChosenBg,
      creditChosenFg: creditChosenFg ?? this.creditChosenFg,
      creditChosenBg: creditChosenBg ?? this.creditChosenBg,
      validation: validation ?? this.validation,
      toastSuccess: toastSuccess ?? this.toastSuccess,
      toastSuccessIcon: toastSuccessIcon ?? this.toastSuccessIcon,
      toastError: toastError ?? this.toastError,
      toastWarning: toastWarning ?? this.toastWarning,
      toastInfo: toastInfo ?? this.toastInfo,
      tooltipBg: tooltipBg ?? this.tooltipBg,
      modalOverlay: modalOverlay ?? this.modalOverlay,
      modalSymbolBg: modalSymbolBg ?? this.modalSymbolBg,
      modalSymbolGreenBg: modalSymbolGreenBg ?? this.modalSymbolGreenBg,
      modalSymbolGreenFg: modalSymbolGreenFg ?? this.modalSymbolGreenFg,
      spinnerTrack: spinnerTrack ?? this.spinnerTrack,
      chartTop: chartTop ?? this.chartTop,
      chartBottom: chartBottom ?? this.chartBottom,
      productImageMultiply: productImageMultiply ?? this.productImageMultiply,
      productImageRadius: productImageRadius ?? this.productImageRadius,
      quickActionHoverBrightness:
          quickActionHoverBrightness ?? this.quickActionHoverBrightness,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      white: Color.lerp(white, other.white, t)!,
      summaryRowText: Color.lerp(summaryRowText, other.summaryRowText, t)!,
      labelText: Color.lerp(labelText, other.labelText, t)!,
      placeholder: Color.lerp(placeholder, other.placeholder, t)!,
      globalSearchFg: Color.lerp(globalSearchFg, other.globalSearchFg, t)!,
      fieldIcon: Color.lerp(fieldIcon, other.fieldIcon, t)!,
      searchFieldFg: Color.lerp(searchFieldFg, other.searchFieldFg, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryGreen: Color.lerp(primaryGreen, other.primaryGreen, t)!,
      actionBlueBg: Color.lerp(actionBlueBg, other.actionBlueBg, t)!,
      actionBlueFg: Color.lerp(actionBlueFg, other.actionBlueFg, t)!,
      actionBlueHover: Color.lerp(actionBlueHover, other.actionBlueHover, t)!,
      actionRedBg: Color.lerp(actionRedBg, other.actionRedBg, t)!,
      actionRedFg: Color.lerp(actionRedFg, other.actionRedFg, t)!,
      actionRedHover: Color.lerp(actionRedHover, other.actionRedHover, t)!,
      actionPurpleBg: Color.lerp(actionPurpleBg, other.actionPurpleBg, t)!,
      actionPurpleFg: Color.lerp(actionPurpleFg, other.actionPurpleFg, t)!,
      actionPurpleHover: Color.lerp(
        actionPurpleHover,
        other.actionPurpleHover,
        t,
      )!,
      actionOrangeBg: Color.lerp(actionOrangeBg, other.actionOrangeBg, t)!,
      actionOrangeFg: Color.lerp(actionOrangeFg, other.actionOrangeFg, t)!,
      actionOrangeHover: Color.lerp(
        actionOrangeHover,
        other.actionOrangeHover,
        t,
      )!,
      actionNeutralBg: Color.lerp(actionNeutralBg, other.actionNeutralBg, t)!,
      actionNeutralFg: Color.lerp(actionNeutralFg, other.actionNeutralFg, t)!,
      actionNeutralHover: Color.lerp(
        actionNeutralHover,
        other.actionNeutralHover,
        t,
      )!,
      actionHoverRing: Color.lerp(actionHoverRing, other.actionHoverRing, t)!,
      smallBadge: Color.lerp(smallBadge, other.smallBadge, t)!,
      discountDot: Color.lerp(discountDot, other.discountDot, t)!,
      clearHoldClock: Color.lerp(clearHoldClock, other.clearHoldClock, t)!,
      invoiceBg: Color.lerp(invoiceBg, other.invoiceBg, t)!,
      invoiceFg: Color.lerp(invoiceFg, other.invoiceFg, t)!,
      applyDiscountBg: Color.lerp(applyDiscountBg, other.applyDiscountBg, t)!,
      payCashTop: Color.lerp(payCashTop, other.payCashTop, t)!,
      payCashBottom: Color.lerp(payCashBottom, other.payCashBottom, t)!,
      payCashIdleFg: Color.lerp(payCashIdleFg, other.payCashIdleFg, t)!,
      payCashIdleBorder: Color.lerp(
        payCashIdleBorder,
        other.payCashIdleBorder,
        t,
      )!,
      payCardTop: Color.lerp(payCardTop, other.payCardTop, t)!,
      payCardBottom: Color.lerp(payCardBottom, other.payCardBottom, t)!,
      payCardIdleFg: Color.lerp(payCardIdleFg, other.payCardIdleFg, t)!,
      payCardIdleBorder: Color.lerp(
        payCardIdleBorder,
        other.payCardIdleBorder,
        t,
      )!,
      completeDisabledBg: Color.lerp(
        completeDisabledBg,
        other.completeDisabledBg,
        t,
      )!,
      completeDisabledFg: Color.lerp(
        completeDisabledFg,
        other.completeDisabledFg,
        t,
      )!,
      completeDisabledBorder: Color.lerp(
        completeDisabledBorder,
        other.completeDisabledBorder,
        t,
      )!,
      quickAmountBg: Color.lerp(quickAmountBg, other.quickAmountBg, t)!,
      quickAmountHover: Color.lerp(
        quickAmountHover,
        other.quickAmountHover,
        t,
      )!,
      changeDueGreen: Color.lerp(changeDueGreen, other.changeDueGreen, t)!,
      shortChangeRed: Color.lerp(shortChangeRed, other.shortChangeRed, t)!,
      terminalApproved: Color.lerp(
        terminalApproved,
        other.terminalApproved,
        t,
      )!,
      terminalDeclined: Color.lerp(
        terminalDeclined,
        other.terminalDeclined,
        t,
      )!,
      terminalDeclinedModal: Color.lerp(
        terminalDeclinedModal,
        other.terminalDeclinedModal,
        t,
      )!,
      terminalApprovedModal: Color.lerp(
        terminalApprovedModal,
        other.terminalApprovedModal,
        t,
      )!,
      selectedLineBg: Color.lerp(selectedLineBg, other.selectedLineBg, t)!,
      selectedLineBorder: Color.lerp(
        selectedLineBorder,
        other.selectedLineBorder,
        t,
      )!,
      qtyButtonBg: Color.lerp(qtyButtonBg, other.qtyButtonBg, t)!,
      qtyButtonFg: Color.lerp(qtyButtonFg, other.qtyButtonFg, t)!,
      qtyButtonHoverBg: Color.lerp(
        qtyButtonHoverBg,
        other.qtyButtonHoverBg,
        t,
      )!,
      qtyButtonHoverFg: Color.lerp(
        qtyButtonHoverFg,
        other.qtyButtonHoverFg,
        t,
      )!,
      qtyRemoveBg: Color.lerp(qtyRemoveBg, other.qtyRemoveBg, t)!,
      qtyRemoveFg: Color.lerp(qtyRemoveFg, other.qtyRemoveFg, t)!,
      qtyRing: Color.lerp(qtyRing, other.qtyRing, t)!,
      trashFg: Color.lerp(trashFg, other.trashFg, t)!,
      trashBg: Color.lerp(trashBg, other.trashBg, t)!,
      trashHoverBg: Color.lerp(trashHoverBg, other.trashHoverBg, t)!,
      lineEditBorder: Color.lerp(lineEditBorder, other.lineEditBorder, t)!,
      qtyBadgeBg: Color.lerp(qtyBadgeBg, other.qtyBadgeBg, t)!,
      qtyBadgeFg: Color.lerp(qtyBadgeFg, other.qtyBadgeFg, t)!,
      highlightBg: Color.lerp(highlightBg, other.highlightBg, t)!,
      highlightBorder: Color.lerp(highlightBorder, other.highlightBorder, t)!,
      sidebarActiveTop: Color.lerp(
        sidebarActiveTop,
        other.sidebarActiveTop,
        t,
      )!,
      sidebarActiveBottom: Color.lerp(
        sidebarActiveBottom,
        other.sidebarActiveBottom,
        t,
      )!,
      sidebarHover: Color.lerp(sidebarHover, other.sidebarHover, t)!,
      onlineDot: Color.lerp(onlineDot, other.onlineDot, t)!,
      offlineDot: Color.lerp(offlineDot, other.offlineDot, t)!,
      notificationDot: Color.lerp(notificationDot, other.notificationDot, t)!,
      avatarBg: Color.lerp(avatarBg, other.avatarBg, t)!,
      avatarBorder: Color.lerp(avatarBorder, other.avatarBorder, t)!,
      brandMark: Color.lerp(brandMark, other.brandMark, t)!,
      brandMarkShadow: Color.lerp(brandMarkShadow, other.brandMarkShadow, t)!,
      offlineBannerBg: Color.lerp(offlineBannerBg, other.offlineBannerBg, t)!,
      offlineBannerFg: Color.lerp(offlineBannerFg, other.offlineBannerFg, t)!,
      categoryStar: Color.lerp(categoryStar, other.categoryStar, t)!,
      categoryIcon3: Color.lerp(categoryIcon3, other.categoryIcon3, t)!,
      categoryIcon4: Color.lerp(categoryIcon4, other.categoryIcon4, t)!,
      categoryIcon5: Color.lerp(categoryIcon5, other.categoryIcon5, t)!,
      categorySelectedTop: Color.lerp(
        categorySelectedTop,
        other.categorySelectedTop,
        t,
      )!,
      categorySelectedBottom: Color.lerp(
        categorySelectedBottom,
        other.categorySelectedBottom,
        t,
      )!,
      selectedTabBg: Color.lerp(selectedTabBg, other.selectedTabBg, t)!,
      viewToggleFg: Color.lerp(viewToggleFg, other.viewToggleFg, t)!,
      productHoverBorder: Color.lerp(
        productHoverBorder,
        other.productHoverBorder,
        t,
      )!,
      productInCartBorder: Color.lerp(
        productInCartBorder,
        other.productInCartBorder,
        t,
      )!,
      productStepperBg: Color.lerp(
        productStepperBg,
        other.productStepperBg,
        t,
      )!,
      favouriteFg: Color.lerp(favouriteFg, other.favouriteFg, t)!,
      favouriteActive: Color.lerp(favouriteActive, other.favouriteActive, t)!,
      favouriteFill: Color.lerp(favouriteFill, other.favouriteFill, t)!,
      scrollThumb: Color.lerp(scrollThumb, other.scrollThumb, t)!,
      scrollThumbCart: Color.lerp(scrollThumbCart, other.scrollThumbCart, t)!,
      stockOkBg: Color.lerp(stockOkBg, other.stockOkBg, t)!,
      stockOkFg: Color.lerp(stockOkFg, other.stockOkFg, t)!,
      stockLowBg: Color.lerp(stockLowBg, other.stockLowBg, t)!,
      stockLowFg: Color.lerp(stockLowFg, other.stockLowFg, t)!,
      greenIcon: Color.lerp(greenIcon, other.greenIcon, t)!,
      saleToggleIdleFg: Color.lerp(
        saleToggleIdleFg,
        other.saleToggleIdleFg,
        t,
      )!,
      radioBorder: Color.lerp(radioBorder, other.radioBorder, t)!,
      cashChosenFg: Color.lerp(cashChosenFg, other.cashChosenFg, t)!,
      cashChosenBg: Color.lerp(cashChosenBg, other.cashChosenBg, t)!,
      creditChosenFg: Color.lerp(creditChosenFg, other.creditChosenFg, t)!,
      creditChosenBg: Color.lerp(creditChosenBg, other.creditChosenBg, t)!,
      validation: Color.lerp(validation, other.validation, t)!,
      toastSuccess: Color.lerp(toastSuccess, other.toastSuccess, t)!,
      toastSuccessIcon: Color.lerp(
        toastSuccessIcon,
        other.toastSuccessIcon,
        t,
      )!,
      toastError: Color.lerp(toastError, other.toastError, t)!,
      toastWarning: Color.lerp(toastWarning, other.toastWarning, t)!,
      toastInfo: Color.lerp(toastInfo, other.toastInfo, t)!,
      tooltipBg: Color.lerp(tooltipBg, other.tooltipBg, t)!,
      modalOverlay: Color.lerp(modalOverlay, other.modalOverlay, t)!,
      modalSymbolBg: Color.lerp(modalSymbolBg, other.modalSymbolBg, t)!,
      modalSymbolGreenBg: Color.lerp(
        modalSymbolGreenBg,
        other.modalSymbolGreenBg,
        t,
      )!,
      modalSymbolGreenFg: Color.lerp(
        modalSymbolGreenFg,
        other.modalSymbolGreenFg,
        t,
      )!,
      spinnerTrack: Color.lerp(spinnerTrack, other.spinnerTrack, t)!,
      chartTop: Color.lerp(chartTop, other.chartTop, t)!,
      chartBottom: Color.lerp(chartBottom, other.chartBottom, t)!,
      productImageMultiply: t < 0.5
          ? productImageMultiply
          : other.productImageMultiply,
      productImageRadius: lerpDouble(
        productImageRadius,
        other.productImageRadius,
        t,
      )!,
      quickActionHoverBrightness: lerpDouble(
        quickActionHoverBrightness,
        other.quickActionHoverBrightness,
        t,
      )!,
    );
  }

  /// All colors by name, for the swatch page and the css_metrics tests.
  Map<String, Color> toMap() => <String, Color>{
    'background': background,
    'card': card,
    'secondary': secondary,
    'text': text,
    'muted': muted,
    'border': border,
    'blue': blue,
    'white': white,
    'summaryRowText': summaryRowText,
    'labelText': labelText,
    'placeholder': placeholder,
    'globalSearchFg': globalSearchFg,
    'fieldIcon': fieldIcon,
    'searchFieldFg': searchFieldFg,
    'focusRing': focusRing,
    'primary': primary,
    'primaryGreen': primaryGreen,
    'actionBlueBg': actionBlueBg,
    'actionBlueFg': actionBlueFg,
    'actionBlueHover': actionBlueHover,
    'actionRedBg': actionRedBg,
    'actionRedFg': actionRedFg,
    'actionRedHover': actionRedHover,
    'actionPurpleBg': actionPurpleBg,
    'actionPurpleFg': actionPurpleFg,
    'actionPurpleHover': actionPurpleHover,
    'actionOrangeBg': actionOrangeBg,
    'actionOrangeFg': actionOrangeFg,
    'actionOrangeHover': actionOrangeHover,
    'actionNeutralBg': actionNeutralBg,
    'actionNeutralFg': actionNeutralFg,
    'actionNeutralHover': actionNeutralHover,
    'actionHoverRing': actionHoverRing,
    'smallBadge': smallBadge,
    'discountDot': discountDot,
    'clearHoldClock': clearHoldClock,
    'invoiceBg': invoiceBg,
    'invoiceFg': invoiceFg,
    'applyDiscountBg': applyDiscountBg,
    'payCashTop': payCashTop,
    'payCashBottom': payCashBottom,
    'payCashIdleFg': payCashIdleFg,
    'payCashIdleBorder': payCashIdleBorder,
    'payCardTop': payCardTop,
    'payCardBottom': payCardBottom,
    'payCardIdleFg': payCardIdleFg,
    'payCardIdleBorder': payCardIdleBorder,
    'completeDisabledBg': completeDisabledBg,
    'completeDisabledFg': completeDisabledFg,
    'completeDisabledBorder': completeDisabledBorder,
    'quickAmountBg': quickAmountBg,
    'quickAmountHover': quickAmountHover,
    'changeDueGreen': changeDueGreen,
    'shortChangeRed': shortChangeRed,
    'terminalApproved': terminalApproved,
    'terminalDeclined': terminalDeclined,
    'terminalDeclinedModal': terminalDeclinedModal,
    'terminalApprovedModal': terminalApprovedModal,
    'selectedLineBg': selectedLineBg,
    'selectedLineBorder': selectedLineBorder,
    'qtyButtonBg': qtyButtonBg,
    'qtyButtonFg': qtyButtonFg,
    'qtyButtonHoverBg': qtyButtonHoverBg,
    'qtyButtonHoverFg': qtyButtonHoverFg,
    'qtyRemoveBg': qtyRemoveBg,
    'qtyRemoveFg': qtyRemoveFg,
    'qtyRing': qtyRing,
    'trashFg': trashFg,
    'trashBg': trashBg,
    'trashHoverBg': trashHoverBg,
    'lineEditBorder': lineEditBorder,
    'qtyBadgeBg': qtyBadgeBg,
    'qtyBadgeFg': qtyBadgeFg,
    'highlightBg': highlightBg,
    'highlightBorder': highlightBorder,
    'sidebarActiveTop': sidebarActiveTop,
    'sidebarActiveBottom': sidebarActiveBottom,
    'sidebarHover': sidebarHover,
    'onlineDot': onlineDot,
    'offlineDot': offlineDot,
    'notificationDot': notificationDot,
    'avatarBg': avatarBg,
    'avatarBorder': avatarBorder,
    'brandMark': brandMark,
    'brandMarkShadow': brandMarkShadow,
    'offlineBannerBg': offlineBannerBg,
    'offlineBannerFg': offlineBannerFg,
    'categoryStar': categoryStar,
    'categoryIcon3': categoryIcon3,
    'categoryIcon4': categoryIcon4,
    'categoryIcon5': categoryIcon5,
    'categorySelectedTop': categorySelectedTop,
    'categorySelectedBottom': categorySelectedBottom,
    'selectedTabBg': selectedTabBg,
    'viewToggleFg': viewToggleFg,
    'productHoverBorder': productHoverBorder,
    'productInCartBorder': productInCartBorder,
    'productStepperBg': productStepperBg,
    'favouriteFg': favouriteFg,
    'favouriteActive': favouriteActive,
    'favouriteFill': favouriteFill,
    'scrollThumb': scrollThumb,
    'scrollThumbCart': scrollThumbCart,
    'stockOkBg': stockOkBg,
    'stockOkFg': stockOkFg,
    'stockLowBg': stockLowBg,
    'stockLowFg': stockLowFg,
    'greenIcon': greenIcon,
    'saleToggleIdleFg': saleToggleIdleFg,
    'radioBorder': radioBorder,
    'cashChosenFg': cashChosenFg,
    'cashChosenBg': cashChosenBg,
    'creditChosenFg': creditChosenFg,
    'creditChosenBg': creditChosenBg,
    'validation': validation,
    'toastSuccess': toastSuccess,
    'toastSuccessIcon': toastSuccessIcon,
    'toastError': toastError,
    'toastWarning': toastWarning,
    'toastInfo': toastInfo,
    'tooltipBg': tooltipBg,
    'modalOverlay': modalOverlay,
    'modalSymbolBg': modalSymbolBg,
    'modalSymbolGreenBg': modalSymbolGreenBg,
    'modalSymbolGreenFg': modalSymbolGreenFg,
    'spinnerTrack': spinnerTrack,
    'chartTop': chartTop,
    'chartBottom': chartBottom,
  };
}
