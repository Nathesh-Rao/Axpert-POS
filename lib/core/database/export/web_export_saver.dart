import 'dart:js_interop';
import 'dart:typed_data';

import 'database_export_saver.dart';

DatabaseExportSaver createPlatformExportSaver() => WebExportSaver();

extension type _BlobOptions._(JSObject _) implements JSObject {
  external factory _BlobOptions({String type});
}

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external factory _Blob(JSArray<JSAny> parts, _BlobOptions options);
}

extension type _Anchor._(JSObject _) implements JSObject {
  external set href(String value);
  external set download(String value);
  external void click();
  external void remove();
}

extension type _Body._(JSObject _) implements JSObject {
  external void append(_Anchor node);
}

@JS('URL.createObjectURL')
external String _createObjectUrl(_Blob blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(String url);

@JS('document.createElement')
external _Anchor _createAnchor(String tag);

@JS('document.body')
external _Body get _body;

/// Browser download through a Blob and a temporary anchor (no `dart:html`).
final class WebExportSaver implements DatabaseExportSaver {
  @override
  Future<SavedExport> save(String fileName, Uint8List bytes) async {
    final blob = _Blob(
      <JSAny>[bytes.toJS].toJS,
      _BlobOptions(type: 'application/vnd.sqlite3'),
    );
    final url = _createObjectUrl(blob);
    final anchor = _createAnchor('a')
      ..href = url
      ..download = fileName;
    _body.append(anchor);
    anchor.click();
    anchor.remove();
    _revokeObjectUrl(url);
    return SavedExport(fileName: fileName);
  }
}
