import '../print_service.dart';
import 'unsupported_print_service.dart';

PrintService createPlatformPrintService() => const UnsupportedPrintService();
