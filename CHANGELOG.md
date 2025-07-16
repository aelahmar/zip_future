# Changelog

## 1.2.0

- Added map-based zipping: `ZipFutureMap.map` for `Map<K, Future<V>>` with same error policies, concurrency limits, and timeouts.
- Enhanced `ZipFuture` with partial-failure strategies (`skip`, `collect`) alongside existing `failFast` policy.
- Introduced `maxConcurrent` parameter to control concurrency and per-future `timeout` support for both list and map zipping.
- Reintroduced `executeThenMap<R>` to post-process results (`List<T?>`) directly.

## 1.1.0

- Added error handling with optional `onError` callback for `execute` and `executeThenMap` methods.
- Updated README with examples demonstrating error handling.
- Added Dart documentation comments throughout the library.

## 1.0.0

- Initial version.