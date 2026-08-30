import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/rutio_supabase_client.dart';
import 'feedback_image_service.dart';

const String feedbackScreenshotsBucket = 'feedback-screenshots';

enum FeedbackStorageErrorType {
  notAuthenticated,
  invalidPath,
  uploadFailed,
  removeFailed,
}

class FeedbackStorageException implements Exception {
  const FeedbackStorageException(
    this.type, {
    this.cause,
  });

  final FeedbackStorageErrorType type;
  final Object? cause;

  @override
  String toString() => 'FeedbackStorageException($type, cause: $cause)';
}

abstract interface class FeedbackStorageGateway {
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
    required bool upsert,
  });

  Future<void> remove({
    required String bucket,
    required String path,
  });
}

class SupabaseFeedbackStorageGateway implements FeedbackStorageGateway {
  SupabaseFeedbackStorageGateway({
    SupabaseClient? client,
  }) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _resolvedClient =>
      _client ?? RutioSupabaseClient.instance;

  @override
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
    required bool upsert,
  }) async {
    await _resolvedClient.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: upsert,
          ),
        );
  }

  @override
  Future<void> remove({
    required String bucket,
    required String path,
  }) async {
    await _resolvedClient.storage.from(bucket).remove(<String>[path]);
  }
}

class FeedbackStorageService {
  FeedbackStorageService({
    FeedbackStorageGateway? gateway,
    String? Function()? currentUserIdProvider,
    void Function(String message)? logger,
    this.bucketName = feedbackScreenshotsBucket,
  })  : _gateway = gateway ?? SupabaseFeedbackStorageGateway(),
        _currentUserIdProvider = currentUserIdProvider,
        _logger = logger;

  final FeedbackStorageGateway _gateway;
  final String? Function()? _currentUserIdProvider;
  final void Function(String message)? _logger;
  final String bucketName;

  Future<String> uploadScreenshot({
    required String feedbackId,
    required String screenshotId,
    required FeedbackPreparedImage image,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      throw const FeedbackStorageException(
        FeedbackStorageErrorType.notAuthenticated,
      );
    }

    final path = buildScreenshotPath(
      userId: userId,
      feedbackId: feedbackId,
      screenshotId: screenshotId,
    );

    try {
      await _gateway.uploadBinary(
        bucket: bucketName,
        path: path,
        bytes: image.bytes,
        contentType: image.contentType,
        upsert: false,
      );
      return path;
    } catch (error) {
      if (error is FeedbackStorageException) rethrow;
      if (error is StorageException) {
        if (error.message.toLowerCase().contains('not found')) {
          throw FeedbackStorageException(
            FeedbackStorageErrorType.uploadFailed,
            cause: error,
          );
        }
      }
      if (kDebugMode) {
        _logger?.call(
          '[feedback_storage_service] upload failure: ${error.runtimeType}',
        );
      }
      throw FeedbackStorageException(
        FeedbackStorageErrorType.uploadFailed,
        cause: error,
      );
    }
  }

  Future<void> removeScreenshot({
    required String path,
  }) async {
    if (!_isCanonicalPath(path)) {
      throw const FeedbackStorageException(FeedbackStorageErrorType.invalidPath);
    }

    try {
      await _gateway.remove(
        bucket: bucketName,
        path: path.trim(),
      );
    } catch (error) {
      if (kDebugMode) {
        _logger?.call(
          '[feedback_storage_service] remove failure: ${error.runtimeType}',
        );
      }
      throw FeedbackStorageException(
        FeedbackStorageErrorType.removeFailed,
        cause: error,
      );
    }
  }

  String buildScreenshotPath({
    required String userId,
    required String feedbackId,
    required String screenshotId,
  }) {
    final normalizedUserId = _normalizeUuid(userId, field: 'userId');
    final normalizedFeedbackId = _normalizeUuid(feedbackId, field: 'feedbackId');
    final normalizedScreenshotId =
        _normalizeUuid(screenshotId, field: 'screenshotId');

    return '$normalizedUserId/$normalizedFeedbackId/screenshot_$normalizedScreenshotId.jpg';
  }

  String? _currentUserId() {
    if (_currentUserIdProvider != null) {
      final provided = _currentUserIdProvider!.call();
      final normalizedProvided = provided?.trim();
      if (normalizedProvided != null && normalizedProvided.isNotEmpty) {
        return normalizedProvided;
      }
      return null;
    }

    final current = RutioSupabaseClient.instance.auth.currentUser?.id.trim();
    if (current == null || current.isEmpty) return null;
    return current;
  }

  bool _isCanonicalPath(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty) return false;
    if (normalized.contains('..') || normalized.contains('\\')) return false;
    return _canonicalScreenshotPath.hasMatch(normalized);
  }

  String _normalizeUuid(String value, {required String field}) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw FeedbackStorageException(
        FeedbackStorageErrorType.invalidPath,
        cause: ArgumentError.value(value, field, 'Must not be empty.'),
      );
    }

    if (!Uuid.isValidUUID(fromString: normalized)) {
      throw FeedbackStorageException(
        FeedbackStorageErrorType.invalidPath,
        cause: ArgumentError.value(value, field, 'Must be a UUID.'),
      );
    }

    return normalized.toLowerCase();
  }

  static final RegExp _canonicalScreenshotPath = RegExp(
    r'^[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}/screenshot_[0-9a-fA-F-]{36}\.jpg$',
  );
}
