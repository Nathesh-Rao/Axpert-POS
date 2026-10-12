import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_entry_tokens.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../controllers/login_controller.dart';
import 'entry_logo.dart';
import 'login_buttons.dart';
import 'login_extras.dart';
import 'login_field.dart';

/// The form column of `login.png`: logo, title, two fields, remember / forgot
/// row, Sign In, `or`, QR login and the footer line.
class LoginForm extends StatelessWidget {
  const LoginForm({required this.scale, super.key});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final ctl = Get.find<LoginController>();
    final k = scale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: EntryLogo(size: AppEntrySizes.loginLogo * k),
        ),
        SizedBox(height: AppEntrySizes.logoGap * k),
        Text(
          s.loginWelcome(),
          style: context.text
              .fluid(AppEntrySizes.titleFont * k, weight: AppFontWeight.bold)
              .copyWith(color: c.text),
        ),
        SizedBox(height: AppEntrySizes.titleGap * k),
        Text(
          s.loginSubtitle(),
          style: context.text
              .fluid(AppEntrySizes.subtitleFont * k)
              .copyWith(color: c.muted),
        ),
        SizedBox(height: AppEntrySizes.subtitleGap * k),
        LoginLabel(text: s.loginUsernameLabel(), scale: k),
        SizedBox(height: AppEntrySizes.labelGap * k),
        Obx(
          () => LoginField(
            controller: ctl.username,
            focusNode: ctl.usernameFocus,
            icon: AppIcons.user,
            hint: s.loginUsernameHint(),
            semanticLabel: s.loginUsernameLabel(),
            scale: k,
            error: ctl.usernameEmpty.value,
            autofillHints: const <String>[],
            onChanged: ctl.usernameChanged,
            onSubmitted: (_) => ctl.submit(),
          ),
        ),
        Obx(
          () => ctl.usernameEmpty.value
              ? Padding(
                  padding: EdgeInsets.only(top: AppEntrySizes.labelGap * k),
                  child: LoginError(text: s.loginUsernameRequired(), scale: k),
                )
              : const SizedBox.shrink(),
        ),
        SizedBox(height: AppEntrySizes.fieldGap * k),
        LoginLabel(text: s.loginPasswordLabel(), scale: k),
        SizedBox(height: AppEntrySizes.labelGap * k),
        Obx(
          () => LoginField(
            controller: ctl.password,
            focusNode: ctl.passwordFocus,
            icon: AppIcons.lock,
            hint: s.loginPasswordHint(),
            semanticLabel: s.loginPasswordLabel(),
            scale: k,
            error: ctl.passwordEmpty.value,
            obscure: ctl.obscure.value,
            autofillHints: const <String>[],
            onChanged: ctl.passwordChanged,
            onSubmitted: (_) => ctl.submit(),
            trailing: AppPressable(
              onTap: ctl.toggleObscure,
              borderRadius: AppEntrySizes.checkboxRadius,
              semanticLabel: ctl.obscure.value
                  ? s.loginShowPassword()
                  : s.loginHidePassword(),
              builder: (context, hovered) => Padding(
                padding: EdgeInsets.all(AppEntrySizes.checkboxGap * k / 2),
                child: Icon(
                  ctl.obscure.value ? AppIcons.eye : AppIcons.eyeOff,
                  size: AppEntrySizes.fieldIcon * k,
                  color: hovered ? c.text : c.fieldIcon,
                ),
              ),
            ),
          ),
        ),
        Obx(
          () => ctl.passwordEmpty.value
              ? Padding(
                  padding: EdgeInsets.only(top: AppEntrySizes.labelGap * k),
                  child: LoginError(text: s.loginPasswordRequired(), scale: k),
                )
              : const SizedBox.shrink(),
        ),
        Obx(() {
          final message =
              ctl.error.value ??
              (ctl.hasUsers.value == false
                  ? '${s.loginNoUsers()} ${s.loginNoUsersHint()}'
                  : null);
          return message == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: EdgeInsets.only(top: AppEntrySizes.labelGap * k),
                  child: LoginError(text: message, scale: k),
                );
        }),
        SizedBox(height: AppEntrySizes.rowGap * k),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Obx(
              () => LoginCheckbox(
                label: s.loginRememberMe(),
                checked: ctl.remember.value,
                scale: k,
                onTap: ctl.toggleRemember,
              ),
            ),
            LoginLink(
              label: s.loginForgotPassword(),
              scale: k,
              onTap: () => ctl.demoOnly(s.loginForgotPassword()),
            ),
          ],
        ),
        SizedBox(height: AppEntrySizes.rowButtonGap * k),
        Obx(
          () => LoginPrimaryButton(
            label: ctl.loading.value ? s.loginSigningIn() : s.loginSignIn(),
            icon: AppIcons.arrowRight,
            scale: k,
            loading: ctl.loading.value,
            onTap: ctl.submit,
          ),
        ),
        SizedBox(height: AppEntrySizes.dividerGap * k),
        LoginDivider(label: s.loginOr(), scale: k),
        SizedBox(height: AppEntrySizes.dividerGap * k),
        LoginOutlineButton(
          label: s.loginWithQr(),
          icon: AppIcons.qrCode,
          scale: k,
          onTap: () => ctl.demoOnly(s.loginWithQr()),
        ),
        SizedBox(height: AppEntrySizes.footerGap * k),
        Text(
          s.loginNoAccount(),
          textAlign: TextAlign.center,
          style: context.text
              .fluid(AppEntrySizes.smallFont * k)
              .copyWith(color: c.muted),
        ),
      ],
    );
  }
}
