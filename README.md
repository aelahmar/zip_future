# ZipFuture

A Dart package for efficiently managing and executing multiple asynchronous operations using futures.
`ZipFuture` simplifies the process of handling multiple futures by providing a convenient way to execute them simultaneously and retrieve their results.

This package is ideal for use cases where you need to wait for multiple asynchronous operations, such as API calls, database transactions, or file operations, before proceeding.

## Features

- **Parallel Execution**: Execute multiple futures in parallel, improving performance over sequential execution.
- **Result Mapping**: Easily transform the results of multiple futures into a single custom data structure.
- **Error Handling**: Handle errors in individual futures without affecting the execution of others.
- **Easy Integration**: Designed to be straightforward to integrate into any Dart or Flutter project.

## Getting Started

### Installation

To use the ZipFuture package in your Dart or Flutter project, add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  zip_future: ^1.1.0
```

Run `pub get` or `flutter pub get` to install the package.

### Usage

Import the package where you want to use it:

```dart
import 'package:zip_future/zip_future.dart';
```

#### Basic Example

Here's a simple example of how to use `ZipFuture` to execute multiple futures in parallel and handle their results:

```dart
import 'package:zip_future/zip_future.dart';

void main() async {
  Future<String> future1 = Future.delayed(Duration(seconds: 1), () => "Result 1");
  Future<int> future2 = Future.delayed(Duration(seconds: 2), () => 42);

  var zip = ZipFuture.zip([future1, future2]);
  List<dynamic> results = await zip.execute();

  print(results); // Prints: ['Result 1', 42]
}
```

#### Advanced Usage

Using `executeThenMap` to process results after all futures have completed:

```dart
import 'package:zip_future/zip_future.dart';

void main() async {
  var futures = [
    Future.delayed(Duration(seconds: 1), () => "Hello"),
    Future.delayed(Duration(seconds: 2), () => "World"),
  ];

  var zip = ZipFuture.zip(futures);
  String concatenated = await zip.executeThenMap((results) => results.join(" "));

  print(concatenated); // Prints: 'Hello World'
}
```

#### Error Handling

Handling errors in individual futures using the `onError` callback:

```dart
import 'package:zip_future/zip_future.dart';

void main() async {
  Future<String> future1 = Future.delayed(Duration(seconds: 1), () => "Result 1");
  Future<int> future2 = Future.delayed(Duration(seconds: 2), () => throw Exception("Error in future2"));
  Future<double> future3 = Future.delayed(Duration(seconds: 3), () => 3.14);

  var zip = ZipFuture.zip([future1, future2, future3]);

  List<dynamic> results = await zip.execute(onError: (index, error) {
    print('Error at index $index: $error');
  });

  print(results); // Prints: ['Result 1', 3.14]
}
```

Using `executeThenMap` with error handling:

```dart
import 'package:zip_future/zip_future.dart';

void main() async {
  var futures = [
    Future.delayed(Duration(seconds: 1), () => 1),
    Future.delayed(Duration(seconds: 2), () => throw Exception("Error in future2")),
    Future.delayed(Duration(seconds: 3), () => 3),
  ];

  var zip = ZipFuture.zip(futures);

  int sum = await zip.executeThenMap<int>(
        (results) => results.fold(0, (previousValue, element) => previousValue + element),
    onError: (index, error) {
      print('Error at index $index: $error');
    },
  );

  print(sum); // Prints: 4
}
```

## Contributing

Contributions to improve `ZipFuture` are welcome. Feel free to fork the repository and submit pull requests.

Thank you for using or considering `ZipFuture`. We hope it helps you manage your asynchronous Dart operations effectively!
