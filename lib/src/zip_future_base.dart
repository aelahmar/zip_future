class ZipFuture {
  List<Future> futures;

  ZipFuture._({required this.futures});

  factory ZipFuture.zip(List<Future> futures) {
    return ZipFuture._(futures: futures);
  }

  Future<List<dynamic>> execute() async {
    final results = [];

    for (final future in futures) {
      results.add(await future);
    }

    return results;
  }

  Future<T> executeThenMap<T>(T Function(List<dynamic>) mapper) async {
    final results = await execute();

    return mapper(results);
  }
}
