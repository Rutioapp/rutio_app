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
  });

  final RepositoryErrorCode code;
  final String message;
  final Object? cause;
}

@immutable
class RepositoryResult<T> {
  const RepositoryResult.success({this.data}) : error = null;

  const RepositoryResult.failure(this.error) : data = null;

  final T? data;
  final RepositoryError? error;

  bool get isSuccess => error == null;
}
