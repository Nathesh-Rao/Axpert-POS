import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/database/export/database_export_saver.dart';
import '../../../core/database/export/database_export_service.dart';
import '../../../core/database/export/export_file_name.dart';
import '../../../features/session/presentation/controllers/active_session.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/controllers/toast_controller.dart';

/// "Export database" (admin only): confirms, builds a snapshot through the
/// [DatabaseExportService], hands it to the [DatabaseExportSaver] and tells the
/// user where it went. The role is checked here as well as in the view.
class DatabaseExportController extends GetxController {
  DatabaseExportController({
    required DatabaseExportService service,
    required DatabaseExportSaver saver,
    required ActiveSession session,
    required ToastController toasts,
    required OverlayController overlay,
    DateTime Function()? now,
    Future<void> Function(String text)? copyToClipboard,
  }) : _service = service,
       _saver = saver,
       _session = session,
       _toasts = toasts,
       _overlay = overlay,
       _now = now ?? DateTime.now,
       _copy =
           copyToClipboard ??
           ((text) => Clipboard.setData(ClipboardData(text: text)));

  final DatabaseExportService _service;
  final DatabaseExportSaver _saver;
  final ActiveSession _session;
  final ToastController _toasts;
  final OverlayController _overlay;
  final DateTime Function() _now;
  final Future<void> Function(String text) _copy;

  final RxBool busy = false.obs;

  AppStrings get _s => AppStrings.current;

  static const String adminRole = 'admin';

  bool get canExport => _session.user.value?.role == adminRole;

  /// The button: asks first, then exports.
  void requestExport() {
    if (!canExport || busy.value) return;
    _overlay.openConfirm(_s.exportDbConfirm(), export);
  }

  Future<void> export() async {
    if (!canExport || busy.value) return;
    busy.value = true;
    try {
      final store = _session.store.value;
      final snapshot = await _service.createSnapshot();
      final name = databaseExportFileName(
        storeName: store?.name ?? '',
        storeId: store?.id ?? '',
        now: _now(),
      );
      final saved = await _saver.save(name, snapshot.bytes);
      // No audit log exists yet (KG-234): the event goes to the debug log.
      debugPrint(
        '[audit] database export by ${_session.user.value?.username} '
        'file=${saved.fileName} bytes=${snapshot.bytes.length} '
        'tables=${snapshot.tableCount} schema=${snapshot.schemaVersion}',
      );
      final path = saved.path;
      if (path == null) {
        _toasts.show(_s.exportDbDownloaded(saved.fileName));
      } else {
        _toasts.show(
          _s.exportDbSavedFile(path),
          actionLabel: _s.exportDbCopy(),
          onUndo: () {
            _copy(path);
            _toasts.show(_s.exportDbPathCopied());
          },
        );
      }
    } on Object catch (error) {
      debugPrint('[audit] database export failed: $error');
      _toasts.show(_s.exportDbFailed(), kind: ToastKind.error);
    } finally {
      busy.value = false;
    }
  }
}
