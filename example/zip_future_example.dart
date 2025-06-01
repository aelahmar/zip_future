import 'package:zip_future/zip_future.dart';

void main() {
  final future1 = Future.value(1);
  final future2 = Future.value(2);
  final future3 = Future.value(3);

  final zipFuture = ZipFuture.zip([future1, future2, future3]);

  zipFuture.execute().then((results) {
    print(results); // [1, 2, 3]
  }).catchError((error) {
    print('Error: $error');
  });

  // Map the results to sum all elements
  zipFuture.executeThenMap<num>((results) {
    return results.fold(0, (previousValue, element) => previousValue + element);
  }).then((result) {
    print(result); // 6
  }).catchError((error) {
    print('Error: $error');
  });

  // Example with error handling
  final future4 = Future.value(1);
  final future5 = Future.error('An error occurred');
  final future6 = Future.value(3);

  final zipFutureWithError = ZipFuture.zip([future4, future5, future6]);

  zipFutureWithError.execute(onError: (index, error, trace) {
    print('Error at index $index: $error');
  }).then((results) {
    print(results); // [1, 3]
  }).catchError((error) {
    print('Unhandled Error: $error');
  });

  // Map the results to sum all elements with error handling
  zipFutureWithError.executeThenMap<num>(
    (results) {
      return results.fold(
          0, (previousValue, element) => previousValue + element);
    },
    onError: (index, error, trace) {
      print('Error at index $index: $error');
    },
  ).then((result) {
    print(result); // 4
  }).catchError((error) {
    print('Unhandled Error: $error');
  });
}
