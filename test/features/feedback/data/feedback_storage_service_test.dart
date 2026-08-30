import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/feedback/data/feedback_image_service.dart';
import 'package:rutio/features/feedback/data/feedback_storage_service.dart';

void main() {
  const userId = '11111111-1111-4111-8111-111111111111';
  const feedbackId = '22222222-2222-4222-8222-222222222222';
  const screenshotId = '33333333-3333-4333-8333-333333333333';

  test('uploads screenshots into the canonical private bucket path', () async {
    final gateway = _FakeFeedbackStorageGateway();
    final service = FeedbackStorageService(
      gateway: gateway,
      currentUserIdProvider: () => userId,
    );
    final prepared = _preparedImage();
    addTearDown(prepared.cleanup);

    final path = await service.uploadScreenshot(
      feedbackId: feedbackId,
      screenshotId: screenshotId,
      image: prepared,
    );

    expect(
      path,
      '$userId/$feedbackId/screenshot_$screenshotId.jpg',
    );
    expect(gateway.lastBucket, feedbackScreenshotsBucket);
    expect(
      gateway.lastPath,
      '$userId/$feedbackId/screenshot_$screenshotId.jpg',
    );
    expect(gateway.lastBytes, prepared.bytes);
    expect(gateway.lastContentType, feedbackScreenshotOutputMimeType);
    expect(gateway.lastUpsert, isFalse);
  });

  test('removeScreenshot uses the same bucket and path', () async {
    final gateway = _FakeFeedbackStorageGateway();
    final service = FeedbackStorageService(
      gateway: gateway,
      currentUserIdProvider: () => userId,
    );

    await service.removeScreenshot(
      path:
          '$userId/$feedbackId/screenshot_$screenshotId.jpg',
    );

    expect(gateway.removeCalls, 1);
    expect(gateway.lastBucket, feedbackScreenshotsBucket);
    expect(
      gateway.lastPath,
      '$userId/$feedbackId/screenshot_$screenshotId.jpg',
    );
  });

  test('uploadScreenshot fails safely without an authenticated user', () async {
    final gateway = _FakeFeedbackStorageGateway();
    final service = FeedbackStorageService(
      gateway: gateway,
      currentUserIdProvider: () => null,
    );
    final prepared = _preparedImage();
    addTearDown(prepared.cleanup);

    expect(
      () => service.uploadScreenshot(
        feedbackId: feedbackId,
        screenshotId: screenshotId,
        image: prepared,
      ),
      throwsA(
        isA<FeedbackStorageException>().having(
          (error) => error.type,
          'type',
          FeedbackStorageErrorType.notAuthenticated,
        ),
      ),
    );
    expect(gateway.uploadCalls, 0);
  });

  test('upload and remove failures are mapped to storage errors', () async {
    final gateway = _FakeFeedbackStorageGateway()
      ..failUpload = true
      ..failRemove = true;
    final service = FeedbackStorageService(
      gateway: gateway,
      currentUserIdProvider: () => userId,
    );
    final prepared = _preparedImage();
    addTearDown(prepared.cleanup);

    expect(
      () => service.uploadScreenshot(
        feedbackId: feedbackId,
        screenshotId: screenshotId,
        image: prepared,
      ),
      throwsA(
        isA<FeedbackStorageException>().having(
          (error) => error.type,
          'type',
          FeedbackStorageErrorType.uploadFailed,
        ),
      ),
    );

    expect(
      () => service.removeScreenshot(
        path:
            '$userId/$feedbackId/screenshot_$screenshotId.jpg',
      ),
      throwsA(
        isA<FeedbackStorageException>().having(
          (error) => error.type,
          'type',
          FeedbackStorageErrorType.removeFailed,
        ),
      ),
    );
  });

  test('invalid paths are rejected before the gateway is called', () async {
    final gateway = _FakeFeedbackStorageGateway();
    final service = FeedbackStorageService(
      gateway: gateway,
      currentUserIdProvider: () => userId,
    );

    expect(
      () => service.removeScreenshot(path: 'not/a/canonical/path'),
      throwsA(
        isA<FeedbackStorageException>().having(
          (error) => error.type,
          'type',
          FeedbackStorageErrorType.invalidPath,
        ),
      ),
    );
    expect(gateway.removeCalls, 0);
  });
}

FeedbackPreparedImage _preparedImage() {
  final bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
  final tempDir = Directory.systemTemp.createTempSync(
    'feedback-storage-service-test-',
  );
  final file = File('${tempDir.path}/prepared.jpg')
    ..writeAsBytesSync(bytes, flush: true);
  return FeedbackPreparedImage(
    file: file,
    bytes: bytes,
    cleanup: () async {
      if (await file.exists()) {
        await file.delete();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    },
  );
}

class _FakeFeedbackStorageGateway implements FeedbackStorageGateway {
  int uploadCalls = 0;
  int removeCalls = 0;
  String? lastBucket;
  String? lastPath;
  Uint8List? lastBytes;
  String? lastContentType;
  bool? lastUpsert;
  bool failUpload = false;
  bool failRemove = false;

  @override
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
    required bool upsert,
  }) async {
    uploadCalls += 1;
    lastBucket = bucket;
    lastPath = path;
    lastBytes = bytes;
    lastContentType = contentType;
    lastUpsert = upsert;
    if (failUpload) {
      throw StateError('upload failed');
    }
  }

  @override
  Future<void> remove({
    required String bucket,
    required String path,
  }) async {
    removeCalls += 1;
    lastBucket = bucket;
    lastPath = path;
    if (failRemove) {
      throw StateError('remove failed');
    }
  }
}
