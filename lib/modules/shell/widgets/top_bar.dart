import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/controllers/search_field_controller.dart';
import '../../../shared/controllers/shell_chrome_controller.dart';
import '../../../shared/controllers/toast_controller.dart';
import '../../../shared/widgets/app_popover.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../../shared/widgets/app_select.dart';
import '../../../shared/widgets/badge_dot.dart';
import '../../../shared/widgets/css_gradient.dart';
import '../../../shared/widgets/focus_outline.dart';
import '../../../shared/widgets/kbd_chip.dart';
import '../controllers/settings_controller.dart';
import '../../../core/theme/tokens/app_icons.dart';

/// Brand, store select, global search, online chip, notifications, profile
/// and the user menu (prototype `<header class="topbar">`).
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    return SizedBox(
      height: m.topbarHeight,
      child: CssGradientBox(
        angleDeg: 110,
        colors: <Color>[c.background, c.card, c.background],
        border: Border(bottom: BorderSide(color: c.border)),
        padding: EdgeInsets.symmetric(horizontal: m.topbarPadX),
        child: Row(
          children: <Widget>[
            const _Brand(),
            SizedBox(width: m.topbarGap),
            const _StoreSelect(),
            SizedBox(width: m.topbarGap),
            const Expanded(child: _GlobalSearch()),
            SizedBox(width: m.topbarGap),
            const _OnlineChip(),
            SizedBox(width: m.topbarGap),
            const _NotificationsButton(),
            SizedBox(width: m.topbarGap),
            const _ProfileButton(),
            SizedBox(width: m.topbarGap),
            const _UserMenuButton(),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    final s = context.strings;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: m.brandMarkWidth,
          child: Text(
            s.brandMark(),
            textAlign: TextAlign.center,
            style: AppTypography.arial(
              m.brandMarkFont,
              weight: FontWeight.w900,
              style: FontStyle.italic,
              shadows: <Shadow>[
                Shadow(
                  color: c.brandMarkShadow,
                  offset: const Offset(AppSpacing.s2, AppSpacing.s2),
                ),
              ],
            ).copyWith(color: c.brandMark),
          ),
        ),
        SizedBox(width: m.brandGap),
        Text(
          s.brandName(),
          maxLines: 1,
          style: context.text
              .fluid(
                m.brandFont,
                weight: AppFontWeight.bold,
                letterSpacing: AppTracking.brand,
              )
              .copyWith(color: c.text),
        ),
      ],
    );
  }
}

class _StoreSelect extends StatelessWidget {
  const _StoreSelect();

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final s = context.strings;
    final settings = Get.find<SettingsController>();
    final stores = <String>[
      s.storeNameOzone(),
      s.storeNameCentral(),
      s.storeNameMarina(),
    ];
    return SizedBox(
      width: m.storeWidth,
      child: Obx(
        () => AppSelect(
          value: settings.settings.value.store,
          items: stores,
          fontSize: m.storeFont,
          semanticLabel: s.storeSelectLabel(),
          onChanged: (value) {
            settings.setStore(value);
            Get.find<ToastController>().show(s.storeSwitched());
            Get.find<SearchFieldController>().refocus();
          },
        ),
      ),
    );
  }
}

/// "⌘K" on macOS (the prototype's glyph), "Ctrl+K" elsewhere (DEC-007).
String searchShortcutLabel(AppStrings s, TargetPlatform platform) =>
    platform == TargetPlatform.macOS
    ? s.searchShortcutMac()
    : s.searchShortcutOther();

class _GlobalSearch extends StatelessWidget {
  const _GlobalSearch();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    final s = context.strings;
    final search = Get.find<SearchFieldController>();
    final fieldStyle = context.text.fluid(m.searchFont).copyWith(color: c.text);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: m.searchMarginX),
      child: Container(
        height: m.searchHeight,
        padding: EdgeInsets.symmetric(horizontal: m.searchPadX),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppRadii.r9),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: <Widget>[
            Icon(AppIcons.search, size: 20, color: c.globalSearchFg),
            SizedBox(width: m.searchGap),
            Expanded(
              child: FocusOutline(
                focusNode: search.focusNode,
                child: TextField(
                  controller: search.text,
                  focusNode: search.focusNode,
                  style: fieldStyle,
                  cursorColor: c.text,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: s.searchHint(),
                    hintStyle: fieldStyle.copyWith(color: c.placeholder),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            if (m.showShortcutHint) ...<Widget>[
              SizedBox(width: m.searchGap),
              KbdChip(searchShortcutLabel(s, defaultTargetPlatform)),
            ],
            SizedBox(width: m.searchGap),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: c.border)),
              ),
              child: Padding(
                padding: EdgeInsets.only(left: m.searchGap),
                child: AppPressable(
                  tooltip: s.scanTooltip(),
                  onTap: () => Get.find<OverlayController>().open('scan'),
                  builder: (context, hovered) =>
                      Icon(AppIcons.barcode, size: 23, color: c.globalSearchFg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineChip extends StatelessWidget {
  const _OnlineChip();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    final s = context.strings;
    final chrome = Get.find<ShellChromeController>();
    return Obx(() {
      final online = chrome.online.value;
      return AppPressable(
        onTap: () {
          chrome.toggleOnline();
          Get.find<SearchFieldController>().refocus();
        },
        builder: (context, hovered) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: AppSizes.onlineDot,
              height: AppSizes.onlineDot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online ? c.onlineDot : c.offlineDot,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              online ? s.online() : s.offline(),
              maxLines: 1,
              style: context.text.fluid(m.searchFont).copyWith(color: c.text),
            ),
          ],
        ),
      );
    });
  }
}

class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final chrome = Get.find<ShellChromeController>();
    return Obx(
      () => AppPopover(
        open: chrome.menu.value == ShellMenu.notifications,
        minWidth: AppSizes.notificationsMinWidth,
        padding: const EdgeInsets.all(AppSpacing.s16),
        anchor: AppPressable(
          tooltip: s.notificationsTooltip(),
          borderRadius: AppRadii.r6,
          onTap: chrome.toggleNotifications,
          builder: (context, hovered) => Padding(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Icon(AppIcons.bell, size: 24, color: c.text),
                if (chrome.unread.value)
                  const Positioned(
                    top: -AppSpacing.s6,
                    right: -AppSpacing.s4,
                    child: BadgeDot('3'),
                  ),
              ],
            ),
          ),
        ),
        child: const _NotificationsBody(),
      ),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final style = context.text.of(AppFontSize.s14).copyWith(color: c.text);
    Widget row(String text) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s11),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Text(text, style: style),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          s.notificationsTitle(),
          style: context.text
              .of(AppFontSize.s17, weight: AppFontWeight.bold)
              .copyWith(color: c.text),
        ),
        const SizedBox(height: AppSpacing.s12),
        row(s.notificationLowStock()),
        row(s.notificationSynced()),
        // Held bills arrive in S4; until then the count is zero.
        row(s.notificationHeld(count: 0)),
      ],
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    final s = context.strings;
    final chrome = Get.find<ShellChromeController>();
    return AppPressable(
      onTap: chrome.toggleUserMenu,
      builder: (context, hovered) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: c.border)),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: m.profilePadLeft),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: m.avatarSize,
                height: m.avatarSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.avatarBg,
                  border: Border.all(color: c.avatarBorder, width: 2),
                ),
                child: Text(
                  s.userInitial(),
                  style: AppTypography.arial(23).copyWith(color: c.white),
                ),
              ),
              if (m.showProfileText) ...<Widget>[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      s.userName(),
                      style: context.text
                          .fluid(m.searchFont, weight: AppFontWeight.semiBold)
                          .copyWith(color: c.text),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    Text(
                      s.userRole(),
                      style: context.text
                          .of(AppFontSize.s12)
                          .copyWith(color: c.muted),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserMenuButton extends StatelessWidget {
  const _UserMenuButton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final chrome = Get.find<ShellChromeController>();
    final overlay = Get.find<OverlayController>();
    final entries = <(IconData, String, String)>[
      (AppIcons.userRound, s.menuProfile(), 'profile'),
      (AppIcons.settings, s.menuSettings(), 'settings'),
      (AppIcons.keyboard, s.menuShortcuts(), 'shortcuts'),
      (AppIcons.logOut, s.menuLogout(), 'close'),
    ];
    return Obx(
      () => AppPopover(
        open: chrome.menu.value == ShellMenu.user,
        anchor: AppPressable(
          tooltip: s.moreOptionsTooltip(),
          borderRadius: AppRadii.r6,
          onTap: chrome.toggleUserMenu,
          builder: (context, hovered) => Padding(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: Icon(AppIcons.ellipsisVertical, size: 24, color: c.text),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final (icon, label, id) in entries)
              AppPressable(
                borderRadius: AppRadii.r6,
                onTap: () => overlay.open(id),
                builder: (context, hovered) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: hovered ? c.secondary : null,
                    borderRadius: BorderRadius.circular(AppRadii.r6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s11),
                    child: Row(
                      children: <Widget>[
                        Icon(icon, size: 18, color: c.text),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          label,
                          style: context.text
                              .of(AppFontSize.s14)
                              .copyWith(color: c.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
