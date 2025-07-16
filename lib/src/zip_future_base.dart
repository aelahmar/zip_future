import 'dart:async';
import 'dart:math';

/// Policies for handling errors during zipping.
enum ErrorPolicy { failFast, collect, skip }

/// Exception thrown when multiple errors are collected in ZipFuture.
class ZipFutureException implements Exception {
  final Map<int, Object> errors;
  final Map<int, StackTrace> traces;

  ZipFutureException(this.errors, this.traces);

  @override
  String toString() => 'ZipFutureException(errors: $errors)';
}

/// Utility to zip a list of futures into a single Future<List<T?>>.
/// If [errorPolicy] is [skip], failed futures yield null entries.
class ZipFuture<T> {
  final List<Future<T>> _futures;
  final ErrorPolicy errorPolicy;
  final int maxConcurrent;
  final Duration? timeout;

  ZipFuture._(
    this._futures, {
    this.errorPolicy = ErrorPolicy.failFast,
    this.maxConcurrent = 1,
    this.timeout,
  });

  /// Creates a ZipFuture with optional error policy, concurrency limit, and timeout.
  factory ZipFuture.zip(
    List<Future<T>> futures, {
    ErrorPolicy errorPolicy = ErrorPolicy.failFast,
    int maxConcurrent = 1,
    Duration? timeout,
  }) =>
      ZipFuture._(
        futures,
        errorPolicy: errorPolicy,
        maxConcurrent: maxConcurrent,
        timeout: timeout,
      );

  /// Executes all futures according to the configured policies,
  /// returning their results as a List<T?> (null for skipped failures).
  Future<List<T?>> execute({
    void Function(int index, Object error, StackTrace trace)? onError,
  }) async {
    final results = List<T?>.filled(_futures.length, null);
    final errors = <int, Object>{};
    final traces = <int, StackTrace>{};

    for (var i = 0; i < _futures.length; i += maxConcurrent) {
      final end = min(i + maxConcurrent, _futures.length);
      final chunk = _futures.sublist(i, end);
      final tasks = <Future<void>>[];

      for (var j = 0; j < chunk.length; j++) {
        var f = chunk[j];
        if (timeout != null) f = f.timeout(timeout!);
        final idx = i + j;
        tasks.add(f.then((value) {
          results[idx] = value;
        }).catchError((e, st) {
          onError?.call(idx, e, st);
          switch (errorPolicy) {
            case ErrorPolicy.failFast:
              throw e;
            case ErrorPolicy.collect:
              errors[idx] = e;
              traces[idx] = st;
              break;
            case ErrorPolicy.skip:
              results[idx] = null;
              break;
          }
        }));
      }

      try {
        await Future.wait(
          tasks,
          eagerError: errorPolicy == ErrorPolicy.failFast,
        );
      } catch (_) {
        if (errorPolicy == ErrorPolicy.failFast) rethrow;
      }
    }

    if (errorPolicy == ErrorPolicy.collect && errors.isNotEmpty) {
      throw ZipFutureException(errors, traces);
    }

    return results;
  }

  /// Executes all futures, applies [mapper] to the list of results (List<T?>),
  /// and returns the mapped value of type [R].
  Future<R> executeThenMap<R>(
    R Function(List<T?>) mapper, {
    void Function(int index, Object error, StackTrace trace)? onError,
  }) async {
    final results = await execute(onError: onError);
    return mapper(results);
  }
}

/// Exception thrown when multiple errors are collected in ZipFutureMap.
class ZipFutureMapException<K> implements Exception {
  final Map<K, Object> errors;
  final Map<K, StackTrace> traces;

  ZipFutureMapException(this.errors, this.traces);

  @override
  String toString() => 'ZipFutureMapException(errors: $errors)';
}

/// Utility to zip a map of futures into a single Future<Map<K, V>>.
class ZipFutureMap<K, V> {
  final Map<K, Future<V>> _futures;
  final ErrorPolicy errorPolicy;
  final int maxConcurrent;
  final Duration? timeout;

  ZipFutureMap._(
    this._futures, {
    this.errorPolicy = ErrorPolicy.failFast,
    this.maxConcurrent = 1,
    this.timeout,
  });

  /// Creates a ZipFutureMap with optional error policy, concurrency limit, and timeout.
  factory ZipFutureMap.map(
    Map<K, Future<V>> futures, {
    ErrorPolicy errorPolicy = ErrorPolicy.failFast,
    int maxConcurrent = 1,
    Duration? timeout,
  }) =>
      ZipFutureMap._(
        futures,
        errorPolicy: errorPolicy,
        maxConcurrent: maxConcurrent,
        timeout: timeout,
      );

  /// Executes all map futures according to the configured policies,
  /// returning their results as a Map<K, V> (missing keys for skipped failures).
  Future<Map<K, V>> execute({
    void Function(K key, Object error, StackTrace trace)? onError,
  }) async {
    final keys = _futures.keys.toList();
    final results = <K, V>{};
    final errors = <K, Object>{};
    final traces = <K, StackTrace>{};

    for (var i = 0; i < keys.length; i += maxConcurrent) {
      final end = min(i + maxConcurrent, keys.length);
      final chunkKeys = keys.sublist(i, end);
      final tasks = <Future<void>>[];

      for (var key in chunkKeys) {
        var f = _futures[key]!;
        if (timeout != null) f = f.timeout(timeout!);
        tasks.add(f.then((value) {
          results[key] = value;
        }).catchError((e, st) {
          onError?.call(key, e, st);
          switch (errorPolicy) {
            case ErrorPolicy.failFast:
              throw e;
            case ErrorPolicy.collect:
              errors[key] = e;
              traces[key] = st;
              break;
            case ErrorPolicy.skip:
              break;
          }
        }));
      }

      try {
        await Future.wait(
          tasks,
          eagerError: errorPolicy == ErrorPolicy.failFast,
        );
      } catch (_) {
        if (errorPolicy == ErrorPolicy.failFast) rethrow;
      }
    }

    if (errorPolicy == ErrorPolicy.collect && errors.isNotEmpty) {
      throw ZipFutureMapException<K>(errors, traces);
    }

    return results;
  }
}
