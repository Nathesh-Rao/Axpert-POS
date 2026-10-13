import 'package:get/get.dart';

import '../../../shared/controllers/search_field_controller.dart';
import '../../shell/controllers/settings_controller.dart';

/// The collapsible Products panel of the desktop POS layout (DEC-138). Only a
/// view preference: it lives in the settings (`products_panel_open`), not in
/// business data, and the touch layout ignores it.
class ProductsPanelController extends GetxController {
  ProductsPanelController(this._settings, this._search);

  final SettingsController _settings;
  final SearchFieldController _search;

  /// True while the panel is expanded (reactive through the settings).
  bool get isOpen => _settings.settings.value.productsPanelOpen;

  Future<void> toggle() => setOpen(!isOpen);

  Future<void> open() => setOpen(true);

  /// Collapses the panel and puts the focus back on the search box.
  Future<void> close() async {
    if (!isOpen) return;
    await setOpen(false);
    _search.refocus();
  }

  Future<void> setOpen(bool value) {
    if (value == isOpen) return Future<void>.value();
    return _settings.setProductsPanelOpen(value);
  }
}
