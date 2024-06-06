/// A class that wraps a list of futures and provides methods to
/// execute them concurrently.
class ZipFuture {
  /// The list of futures to be executed.
  List<Future> futures;

  /// Private constructor to create a [ZipFuture] instance.
  ZipFuture._({
    required this.futures,
  });

  /// Factory method to create a [ZipFuture] instance with the given futures.
  ///
  /// [futures] is the list of futures to be executed.
  factory ZipFuture.zip(List<Future> futures) {
    return ZipFuture._(futures: futures);
  }

  /// Executes all the futures concurrently and returns a list of their results.
  ///
  /// [onError] is an optional function that will be called if an error occurs
  /// while awaiting a future. The function receives the index of the future and
  /// the error. If [onError] is not provided, the error will be rethrown.
  ///
  /// Returns a [Future] that completes with a list of the results of the futures.
  Future<List<dynamic>> execute({
    void Function(int index, dynamic error)? onError,
  }) async {
    final results = [];

    for (int i = 0; i < futures.length; i++) {
      try {
        results.add(await futures[i]);
      } catch (error) {
        if (onError != null) {
          onError(i, error);
        } else {
          rethrow;
        }
      }
    }

    return results;
  }

  /// Executes all the futures concurrently, maps their results using the given
  /// [mapper] function, and returns the mapped result.
  ///
  /// [mapper] is a function that takes a list of results and maps them to a value of type [T].
  /// [onError] is an optional function that will be called if an error occurs
  /// while awaiting a future. The function receives the index of the future and
  /// the error. If [onError] is not provided, the error will be rethrown.
  ///
  /// Returns a [Future] that completes with the mapped result of type [T].
  Future<T> executeThenMap<T>(
    T Function(List<dynamic>) mapper, {
    void Function(int index, dynamic error)? onError,
  }) async {
    final results = await execute(onError: onError);

    return mapper(results);
  }
}
