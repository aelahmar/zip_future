import 'dart:async';

import 'package:test/test.dart';
import 'package:zip_future/zip_future.dart';

Future<T> delayed<T>(T value, [int ms = 10]) =>
    Future.delayed(Duration(milliseconds: ms), () => value);

Future<T> delayedError<T>(Object error, [int ms = 10]) =>
    Future.delayed(Duration(milliseconds: ms), () => throw error);

void main() {
  group('ZipFuture List tests', () {
    test('Basic success', () async {
      final results =
          await ZipFuture.zip([delayed(1), delayed(2), delayed(3)]).execute();
      expect(results, equals([1, 2, 3]));
    });

    test('Fail-fast throws on first error', () async {
      expect(
        () => ZipFuture.zip([
          delayed(1),
          delayedError(Exception('fail')), // error at index 1
          delayed(3)
        ]).execute(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('fail'),
        )),
      );
    });

    test('Skip errors yields null entries without throwing', () async {
      final results = await ZipFuture.zip(
              [delayed(1), delayedError('bad'), delayed(3)],
              errorPolicy: ErrorPolicy.skip)
          .execute(
        onError: (i, e, st) => print('skipped $i: $e'),
      );
      expect(results, equals([1, null, 3]));
    });

    test('Collect errors throws ZipFutureException with details', () async {
      try {
        await ZipFuture.zip(
                [delayed(1), delayedError('e1'), delayedError('e2')],
                errorPolicy: ErrorPolicy.collect)
            .execute(
          onError: (i, e, st) => print('collected $i: $e'),
        );
        fail('Expected ZipFutureException');
      } catch (e) {
        expect(e, isA<ZipFutureException>());
        final ex = e as ZipFutureException;
        expect(ex.errors.length, equals(2));
        expect(ex.errors.keys, containsAll([1, 2]));
      }
    });

    test('Timeout interacts with skip policy', () async {
      final results = await ZipFuture.zip(
        [delayed(1, 5), delayed(2, 50)],
        errorPolicy: ErrorPolicy.skip,
        timeout: Duration(milliseconds: 10),
      ).execute(
        onError: (i, e, st) => expect(e, isA<TimeoutException>()),
      );
      expect(results, equals([1, null]));
    });

    test('executeThenMap transforms results', () async {
      final sum = await ZipFuture.zip([delayed(4), delayed(5)]).executeThenMap(
          (list) => list.whereType<int>().reduce((a, b) => a + b));
      expect(sum, equals(9));
    });
  });

  group('ZipFutureMap tests', () {
    test('Basic map success', () async {
      final mapRes = await ZipFutureMap<String, int>.map(
          {'a': delayed(10), 'b': delayed(20)}).execute();
      expect(mapRes, equals({'a': 10, 'b': 20}));
    });

    test('Map skip policy removes keys for failures', () async {
      final mapRes = await ZipFutureMap<String, int>.map(
              {'x': delayed(1), 'y': delayedError('err')},
              errorPolicy: ErrorPolicy.skip)
          .execute(
        onError: (k, e, st) => print('skipped $k: $e'),
      );
      expect(mapRes.containsKey('x'), isTrue);
      expect(mapRes.containsKey('y'), isFalse);
    });

    test('Map collect policy throws with multiple errors', () async {
      expect(
        () => ZipFutureMap<String, int>.map(
                {'p': delayedError('pErr'), 'q': delayedError('qErr')},
                errorPolicy: ErrorPolicy.collect)
            .execute(
          onError: (k, e, st) => print('collected $k: $e'),
        ),
        throwsA(isA<ZipFutureMapException>()),
      );
    });

    test('Map timeout with failFast policy throws TimeoutException', () async {
      expect(
        () => ZipFutureMap<String, int>.map(
                {'one': delayed(1, 5), 'two': delayed(2, 50)},
                timeout: Duration(milliseconds: 10))
            .execute(),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
