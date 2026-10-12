import '../errors/app_failure.dart';

sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = ResultSuccess<T>;

  const factory Result.failure(AppFailure failure) = ResultFailure<T>;

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppFailure failure) onFailure,
  });
}

final class ResultSuccess<T> extends Result<T> {
  const ResultSuccess(this.value);

  final T value;

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppFailure failure) onFailure,
  }) => onSuccess(value);
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);

  final AppFailure failure;

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppFailure failure) onFailure,
  }) => onFailure(failure);
}
