import 'package:flutter/animation.dart';

/// Motion of the splash and login screens (demo entry flow). Durations in
/// milliseconds; all of it collapses to zero when the platform asks for
/// reduced motion (`MediaQuery.disableAnimations`).
abstract final class AppEntryMotion {
  /// How long the splash stays before it moves on to the login (1.8 to 2.2 s).
  static const int splashHoldMs = 2000;

  /// Logo scale and fade in on the splash.
  static const int splashLogoInMs = 700;
  static const Curve splashLogoInCurve = Curves.easeOutBack;
  static const double splashLogoStartScale = 0.7;

  /// Splash to login: route cross-fade, the logo flies into place (Hero).
  static const int splashToLoginMs = 700;
  static const Curve splashToLoginCurve = Curves.easeInOutCubic;

  /// The login form fades up while the logo is still arriving.
  static const int formRiseMs = 600;
  static const int formRiseDelayMs = 200;
  static const double formRiseOffset = 24;
  static const Curve formRiseCurve = Curves.easeOutCubic;

  /// Login to landing: clean fade.
  static const int loginToLandingMs = 400;
  static const Curve loginToLandingCurve = Curves.easeInOut;

  /// Fake sign-in delay (no real authentication yet).
  static const int fakeLoginMs = 600;

  /// Field border and button color transitions.
  static const int controlMs = 150;
}

/// Sizes of the splash and login screens in logical px at the 1672 px wide
/// reference (`reference_screenshots/splash.png`, `login.png`). The login
/// screen scales them with the window width (see `EntryMetrics`).
abstract final class AppEntrySizes {
  static const double referenceWidth = 1672;
  static const double minScale = 0.8;
  static const double maxScale = 1.1;

  // Splash
  static const double splashLogo = 224;
  static const double splashBarWidth = 198;
  static const double splashBarHeight = 14;
  static const double splashGap = 40;

  // Login layout
  static const double loginLogo = 64;
  static const double panelFraction = 0.406;
  static const double photoFadeEndFraction = 0.5;
  static const double formWidth = 516;
  static const double formMinWidth = 320;
  static const double panelPadding = 24;
  static const double panelRadius = 24;
  static const double panelCoverAlpha = 0.94;

  // Login form
  static const double titleFont = 46;
  static const double subtitleFont = 24;
  static const double labelFont = 17;
  static const double inputFont = 18;
  static const double smallFont = 16;
  static const double buttonFont = 20;
  static const double fieldHeight = 62;
  static const double buttonHeight = 64;
  static const double fieldRadius = 10;
  static const double fieldIcon = 24;
  static const double fieldPadding = 16;
  static const double fieldIconGap = 14;
  static const double buttonIconGap = 12;
  static const double titleGap = 8;
  static const double subtitleGap = 40;
  static const double labelGap = 8;
  static const double fieldGap = 20;
  static const double rowGap = 20;
  static const double rowButtonGap = 20;
  static const double dividerGap = 14;
  static const double footerGap = 22;
  static const double logoGap = 28;
  static const double checkbox = 24;
  static const double checkboxRadius = 6;
  static const double checkboxGap = 12;
  static const double spinner = 22;
  static const double spinnerStroke = 2.5;
  static const double minTouch = 48;

  // Language chip
  static const double chipHeight = 51;
  static const double chipWidth = 188;
  static const double chipRadius = 12;
  static const double chipInset = 49;
}
