/// Runs async tasks one after another, in call order.
///
/// Used by the Drift repositories so overlapping unawaited saves cannot finish
/// out of order (KG-190): the trailing pragma of `durableTransaction` runs
/// outside the transaction, so without the queue the LocalStore copy of a
/// later save can be overtaken by an earlier one and end older than Drift.
///
/// A failing task does not block the next one; the caller of the failing task
/// still receives its error.
class SerialQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
