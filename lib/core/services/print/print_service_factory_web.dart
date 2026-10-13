import '../print_service.dart';
import 'system_print_service.dart';

/// Web: the browser's print dialog.
PrintService createPlatformPrintService() => SystemPrintService();
