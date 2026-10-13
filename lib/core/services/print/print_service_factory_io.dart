import 'dart:io' show Platform;

import '../print_service.dart';
import 'system_print_service.dart';
import 'unsupported_print_service.dart';

/// Windows, macOS, Linux, Android and iOS have a system print dialog; any
/// other platform reports `unsupported`.
PrintService createPlatformPrintService() =>
    Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux ||
        Platform.isAndroid ||
        Platform.isIOS
    ? SystemPrintService()
    : const UnsupportedPrintService();
