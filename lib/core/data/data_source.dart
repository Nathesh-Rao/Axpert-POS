import '../result/result.dart';

abstract interface class DataSource<T> {
  Future<Result<T>> read();
}
