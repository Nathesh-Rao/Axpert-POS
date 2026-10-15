// The product form (DEC-152, DEC-153), light and dark. Regression only: the
// prototype has no product form, so there is no reference screenshot
// (unverified visually, KG list).

@Tags(<String>['golden'])
@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show SingleChildScrollView;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';
import 'package:pos_application/features/offers/domain/entities/offer.dart';
import 'package:pos_application/features/offers/domain/entities/offer_draft.dart';
import 'package:pos_application/features/products/presentation/controllers/product_admin_controller.dart';
import 'package:pos_application/features/products/presentation/controllers/product_form_controller.dart';
import 'package:pos_application/main.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../support/test_app.dart';
import '../support/test_session.dart';
import 'harness.dart';
import 'images.dart';

void main() {
  useTolerantGoldens();
  useTestApp();
  final skipReason = fontsSkipReason();
  final skip = skipReason.isNotEmpty;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!skip) await loadTestFonts();
  });
  final prefix = skip ? '[$skipReason] ' : '';

  for (final dark in <bool>[false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('${prefix}Product form with a carton and an offer ($mode)', (
      tester,
    ) async {
      useRealShadows();
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        useReferenceViewport(tester);
        final binding = await bootInWidgetTest(
          tester,
          session: roleSession('admin'),
        );
        AppTypography.useBundledFonts = true;
        if (dark) {
          await tester.runAsync(
            () => Get.find<SettingsController>().setDark(true),
          );
        }
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();
        Get.offAllNamed<void>(AppRoutes.products);
        await tester.pumpAndSettle();
        Get.find<ProductAdminController>().openAdd();
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
        final form = Get.find<ProductFormController>();
        form.name.text = 'Coca Cola 500ml';
        form.sku.text = 'BDV001';
        form.price.text = '40';
        form.barcodes.add('8901234560000');
        form.addPackaging();
        form.packagings.single.factor.text = '24';
        form.packagings.single.barcode.text = '8901234560024';
        form.packagings.single.stockCount.text = '3';
        form.stockBase.text = '5';
        form.offerEditor.load(const <OfferDraft>[
          OfferDraft(
            kind: OfferKind.discount,
            name: 'Cola 20%',
            percentBp: 2000,
          ),
        ]);
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        Get.find<ToastController>().toasts.clear();
        await tester.pumpAndSettle();
        await settleImages(tester);
        // The bottom of the form: offers and the buttons.
        await tester.drag(
          find.byType(SingleChildScrollView).last,
          const Offset(0, -3000),
        );
        await tester.pumpAndSettle();
        await expectGolden(find.byType(PosApp), 'product_form_$mode');
      } finally {
        if (Get.isRegistered<ToastController>()) {
          Get.find<ToastController>().onClose();
        }
        debugDefaultTargetPlatformOverride = null;
        restoreDefaultShadows();
      }
    }, skip: skip);
  }
}
