import 'package:zip_future/zip_future.dart';

void main() {
  final future1 = Future.value(1);
  final future2 = Future.value(2);
  final future3 = Future.value(3);

  final zipFuture = ZipFuture.zip([future1, future2, future3]);

  zipFuture.execute().then((results) {
    print(results); // [1, 2, 3]
  });

  // Map the results to sum all elements
  zipFuture.executeThenMap<num>((results) {
    return results.fold(0, (previousValue, element) => previousValue + element);
  }).then((result) {
    print(result); // 6
  });
}
