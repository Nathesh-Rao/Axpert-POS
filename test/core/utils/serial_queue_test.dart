import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/utils/serial_queue.dart';

void main() {
  test('tasks run in call order even when earlier ones are slower', () async {
    final queue = SerialQueue();
    final log = <int>[];

    Future<void> task(int n, int ms) async {
      await Future<void>.delayed(Duration(milliseconds: ms));
      log.add(n);
    }

    await Future.wait([
      queue.run(() => task(1, 30)),
      queue.run(() => task(2, 10)),
      queue.run(() => task(3, 0)),
    ]);

    expect(log, [1, 2, 3]);
  });

  test('returns each task value', () async {
    final queue = SerialQueue();

    final a = queue.run(() async => 'a');
    final b = queue.run(() async => 2);

    expect(await a, 'a');
    expect(await b, 2);
  });

  test(
    'a failing task reaches its caller and does not block the next',
    () async {
      final queue = SerialQueue();
      final log = <String>[];

      final failing = queue.run<void>(() async => throw StateError('boom'));
      final next = queue.run(() async => log.add('next'));

      await expectLater(failing, throwsStateError);
      await next;
      expect(log, ['next']);
    },
  );
}
