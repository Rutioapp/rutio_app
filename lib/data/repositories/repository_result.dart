import 'package:flutter/foundation.dart';

enum RepositoryErrorCode {
  notAuthenticated,
  notFound,
  permissionDenied,
  network,
  invalidResponse,
  unknown,
}

@immutable
class RepositoryError {
  const RepositoryError({
    required this.code,
    required this.message,
    this.cause,
    this.causeStackTrace,
  });

  final RepositoryErrorCode code;
  final String message;
  final Object? cause;
  final StackTrace? causeStackTrace;

  String diagnosticDescription() {
    final causeDescription =
        cause == null ? '' : ' causeType=${cause.runtimeType} cause=$cause';
    return 'code=${code.name} message=$message$causeDescription';
  }

  @override
  String toString() => 'RepositoryError(${diagnosticDescription()})';
}

@immutable
class RepositoryResult<T> {
  const RepositoryResult.success({this.data}) : error = null;

  const RepositoryResult.failure(this.error) : data = null;

  final T? data;
  final RepositoryError? error;

  bool get isSuccess => error == null;
}
