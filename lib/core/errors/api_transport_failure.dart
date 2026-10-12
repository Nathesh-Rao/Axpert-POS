import 'app_failure.dart';

final class ApiTransportFailure extends AppFailure {
  const ApiTransportFailure({
    required super.message,
    super.cause,
    super.stackTrace,
    this.statusCode,
  });

  final int? statusCode;
}
