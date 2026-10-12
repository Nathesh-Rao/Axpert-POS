abstract class AppFailure {
  const AppFailure({required this.message, this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => message;
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({
    super.message = 'An unexpected error occurred.',
    super.cause,
    super.stackTrace,
  });
}
