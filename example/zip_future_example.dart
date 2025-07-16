import 'dart:async';

import 'package:zip_future/zip_future.dart';

Future<int> delayedInt(int value, int ms) =>
    Future.delayed(Duration(milliseconds: ms), () {
      if (value == 2) throw Exception('Value $value failed');
      return value;
    });

void main() async {
  // 1. Basic failFast (default) – throws on first error
  try {
    final failFastResult =
        await ZipFuture.zip([delayedInt(1, 100), delayedInt(2, 200)]).execute();
    print('failFastResult: $failFastResult');
  } catch (e) {
    print('failFast error: $e');
  }

  // 2. Skip failures, limit concurrency to 2, 1s timeout
  final skipResults = await ZipFuture.zip(
    [
      delayedInt(1, 100),
      delayedInt(2, 1200),
      delayedInt(3, 50),
    ],
    errorPolicy: ErrorPolicy.skip,
    maxConcurrent: 2,
    timeout: Duration(seconds: 1),
  ).execute(onError: (i, e, _) => print('skipped at $i: $e'));
  print('skipResults (null = skipped): $skipResults');

  // 3. Collect errors, concurrency 3, no timeout
  try {
    final collectResults = await ZipFuture.zip(
      [delayedInt(1, 100), delayedInt(2, 150), delayedInt(3, 50)],
      errorPolicy: ErrorPolicy.collect,
      maxConcurrent: 3,
    ).execute(onError: (i, e, _) => print('collected at $i: $e'));
    print('collectResults: $collectResults');
  } catch (e) {
    print('collected exception: $e');
  }

  // 4. Using executeThenMap to sum non-null results
  final sum = await ZipFuture.zip([
    delayedInt(1, 50),
    delayedInt(3, 50),
    delayedInt(5, 50),
  ]).executeThenMap(
    (list) => list.whereType<int>().reduce((a, b) => a + b),
  );
  print('sum: $sum');

  // 5. Map-version with collect policy & concurrency 2
  try {
    final mapRes = await ZipFutureMap<String, int>.map(
      {
        'a': delayedInt(1, 100),
        'b': delayedInt(2, 300),
        'c': delayedInt(4, 50),
      },
      errorPolicy: ErrorPolicy.collect,
      maxConcurrent: 2,
      timeout: Duration(seconds: 1),
    ).execute(onError: (k, e, _) => print('map error at $k: $e'));
    print('mapRes: $mapRes');
  } catch (e) {
    print('map collected exception: $e');
  }
}
