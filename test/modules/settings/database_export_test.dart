import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/constants/app_strings.dart';
import 'package:pos_application/core/database/export/database_export_saver.dart';
import 'package:pos_application/core/database/export/database_export_service.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/features/session/domain/entities/session_entities.dart';
import 'package:pos_application/features/session/presentation/controllers/active_session.dart';
import 'package:pos_application/modules/settings/controllers/database_export_controller.dart';
import 'package:pos_application/modules/settings/widgets/database_export_row.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';
import '../../support/test_session.dart';
import '../../support/viewport.dart';

class _FakeService implements DatabaseExportService {
  int calls = 0;

  @override
  Future<DatabaseSnapshot> createSnapshot() async {
    calls++;
    return DatabaseSnapshot(
      bytes: Uint8List(4),
      schemaVersion: 10,
      tableCount: 3,
    );
  }
}

class _FakeSaver implements DatabaseExportSaver {
  final List<String> names = <String>[];

  @override
  Future<SavedExport> save(String fileName, Uint8List bytes) async {
    names.add(fileName);
    return SavedExport(fileName: fileName, path: '/dl/$fileName');
  }
}

ActiveSession _session(String role) => ActiveSession.fixed(
  user: AppUser(id: 'u', username: role, displayName: role, role: role),
  store: testAccess.first.store,
  counter: testAccess.first.counters.first,
  access: testAccess,
  quickCash: const <String, List<int>>{},
);

void main() {
  useTestApp();

  DatabaseExportController build(
    String role,
    _FakeService service,
    _FakeSaver saver,
    List<String> copied,
  ) => DatabaseExportController(
    service: service,
    saver: saver,
    session: _session(role),
    toasts: Get.find<ToastController>(),
    overlay: Get.find<OverlayController>(),
    now: () => DateTime(2026, 3, 7, 9, 5),
    copyToClipboard: (t) async => copied.add(t),
  );

  testWidgets('non-admin roles cannot export, even through the controller', (
    tester,
  ) async {
    await bootInWidgetTest(tester);
    for (final role in <String>['cashier', 'manager']) {
      final service = _FakeService();
      final controller = build(role, service, _FakeSaver(), <String>[]);
      expect(controller.canExport, isFalse);
      await controller.export();
      controller.requestExport();
      expect(service.calls, 0, reason: role);
      expect(Get.find<OverlayController>().isOpen, isFalse);
    }
  });

  testWidgets('admin: snapshot, named file, path toast with Copy', (
    tester,
  ) async {
    await bootInWidgetTest(tester);
    final service = _FakeService();
    final saver = _FakeSaver();
    final copied = <String>[];
    final controller = build('admin', service, saver, copied);
    await controller.export();
    expect(service.calls, 1);
    expect(saver.names, <String>['pos_MAISON_GALAXY_-_OZONE_20260307_0905.db']);
    final toast = Get.find<ToastController>().toasts.last;
    expect(toast.text, contains('/dl/pos_MAISON_GALAXY_-_OZONE'));
    expect(toast.actionLabel, AppStrings.current.exportDbCopy());
    Get.find<ToastController>().undo(toast.id);
    expect(copied.single, startsWith('/dl/pos_'));
    expect(controller.busy.value, isFalse);
    await tester.pump(ToastController.lifetime);
  });

  for (final role in <String>['admin', 'cashier']) {
    testWidgets(
      'settings page: $role ${role == 'admin' ? 'sees' : 'does not see'} Export',
      (tester) async {
        useLogicalViewport(tester, const Size(1280, 720));
        final binding = await bootInWidgetTest(
          tester,
          session: role == 'admin' ? _session('admin') : testSession(),
        );
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();
        Get.offAllNamed<void>(AppRoutes.more);
        await tester.pumpAndSettle();
        expect(find.byType(DatabaseExportRow), findsOneWidget);
        expect(
          find.text(AppStrings.current.exportDbTitle()),
          role == 'admin' ? findsOneWidget : findsNothing,
        );
      },
    );
  }

  testWidgets('admin: the button asks for confirmation before exporting', (
    tester,
  ) async {
    useLogicalViewport(tester, const Size(1280, 720));
    final binding = await bootInWidgetTest(tester, session: _session('admin'));
    final service = _FakeService();
    Get.delete<DatabaseExportController>(force: true);
    Get.put(build('admin', service, _FakeSaver(), <String>[]));
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();
    Get.offAllNamed<void>(AppRoutes.more);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.current.exportDbButton()));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.current.exportDbConfirm()), findsOneWidget);
    expect(service.calls, 0);
    await tester.tap(find.text(AppStrings.current.confirmAccept()));
    await tester.pumpAndSettle();
    expect(service.calls, 1);
    await tester.pump(ToastController.lifetime);
  });
}
