import 'app_failure.dart';

final class DataSourceFailure extends AppFailure {
  const DataSourceFailure({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
