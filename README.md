# ZipFutures

A Dart package for efficiently managing and executing multiple asynchronous operations (Futures) with advanced control over error handling, concurrency, and timeouts.

## Features

- **List Zipping**: Combine a list of `Future<T>` into a single `Future<List<T?>>`.
- **Map Zipping**: Combine a map of named futures into a `Future<Map<K, V>>` with `ZipFutureMap.map`.
- **Error Policies**:
    - **failFast** (default): stop and rethrow on the first error.
    - **skip**: skip failed futures and insert `null` (for lists) or drop keys (for maps).
    - **collect**: wait for all futures, then throw a `ZipFutureException` or `ZipFutureMapException` containing all errors.
- **Concurrency Limits**: Control how many futures run simultaneously via `maxConcurrent`.
- **Timeouts**: Specify a per-future `timeout` to fail slow operations.
- **Result Mapping**: Use `executeThenMap` to post-process the list of results into any desired shape.

## Getting Started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  zip_futures: ^1.2.0
```

Run:

```bash
flutter pub get
```

Import:

```dart
import 'package:zip_future/zip_future.dart';
```

## Usage

### 1. Basic List Zipping

```dart
final results = await ZipFuture.zip([
  Future.value(1),
  Future.value(2),
  Future.value(3),
]).execute();
// results == [1, 2, 3]
```

### 2. List Zipping with Error Policy, Concurrency, and Timeout

```dart
final results = await ZipFuture.zip(
  [fetchA(), fetchB(), fetchC()],
  errorPolicy: ErrorPolicy.skip,
  maxConcurrent: 2,
  timeout: Duration(seconds: 1),
).execute(
  onError: (index, error, stack) => print('Error at \$index: \$error'),
);
// failures yield null entries: [A, null, C]
```

### 3. Collect Errors After All Complete

```dart
try {
  await ZipFuture.zip(
    [fetchX(), fetchY(), fetchZ()],
    errorPolicy: ErrorPolicy.collect,
  ).execute(
    onError: (i, e, st) => print('Error at \$i: \$e'),
  );
} catch (e) {
  // e is ZipFutureException containing all errors
  print(e);
}
```

### 4. Mapping Results

```dart
final sum = await ZipFuture.zip([
  Future.value(1),
  Future.value(2),
  Future.value(3),
]).executeThenMap((list) => list.whereType<int>().reduce((a, b) => a + b));
// sum == 6
```

### 5. Map-Based Zipping

```dart
final userData = await ZipFutureMap<String, dynamic>.map(
  {
    'user': fetchUser(),
    'posts': fetchPosts(),
  },
  errorPolicy: ErrorPolicy.failFast,
  maxConcurrent: 2,
).execute(
  onError: (key, error, st) => print('Error at \$key: \$error'),
);
// userData == {'user': User(...), 'posts': [...]} 
```

### 6. Map Zipping with Skip or Collect Policies

```dart
// Skip failures: missing keys dropped
final partial = await ZipFutureMap<String, int>.map(
  {'a': fA(), 'b': fB(), 'c': fC()},
  errorPolicy: ErrorPolicy.skip,
).execute();

// Collect errors: throws ZipFutureMapException with all errors
try {
  await ZipFutureMap.map<String, int>(
    {'x': fX(), 'y': fY()},
    errorPolicy: ErrorPolicy.collect,
  ).execute();
} catch (e) {
  print(e);
}
```

## API Reference

- **`ZipFuture.zip(List<Future<T>> futures, {ErrorPolicy errorPolicy, int maxConcurrent, Duration? timeout})`**
- **`Future<List<T?>> execute({void onError(int index, Object error, StackTrace trace)})`**
- **`Future<R> executeThenMap<R>(R Function(List<T?>) mapper, {void onError(int index, Object error, StackTrace trace)})`**
- **`ZipFutureMap<K, V>.map(Map<K, Future<V>> futures, {ErrorPolicy errorPolicy, int maxConcurrent, Duration? timeout})`**
- **`Future<Map<K, V>> execute({void onError(K key, Object error, StackTrace trace)})`**

## Contributing

Contributions and feedback are welcome! Please open issues or pull requests on GitHub.

---

Thank you for using **ZipFutures**! We hope it streamlines your asynchronous workflows.
