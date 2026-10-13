import '../print_service.dart';
import 'print_service_factory_stub.dart'
    if (dart.library.io) 'print_service_factory_io.dart'
    if (dart.library.js_interop) 'print_service_factory_web.dart'
    as platform;

/// The print service of this platform: the system print dialog where there is
/// one, a service that reports `unsupported` everywhere else.
PrintService createPrintService() => platform.createPlatformPrintService();
