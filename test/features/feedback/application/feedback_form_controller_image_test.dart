import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/features/feedback/application/feedback_form_controller.dart';
import 'package:rutio/features/feedback/data/feedback_image_service.dart';
import 'package:rutio/features/feedback/data/feedback_repository.dart';
import 'package:rutio/features/feedback/data/feedback_storage_service.dart';
import 'package:rutio/features/feedback/data/feedback_technical_context_service.dart';
import 'package:rutio/features/feedback/domain/feedback_category.dart';
import 'package:rutio/features/feedback/domain/feedback_report.dart';
import 'package:rutio/features/feedback/domain/feedback_status.dart';
import 'package:rutio/features/feedback/domain/feedback_technical_context.dart';

const String _feedbackUserId = '11111111-1111-1111-1111-111111111111';
const String _feedbackId = '22222222-2222-4222-8222-222222222222';
const String _screenshotId = '33333333-3333-4333-8333-333333333333';

void main() {
  test('canceling screenshot selection does not set an error', () async {
    final controller = _buildController(
      imageService: _FakeFeedbackImageService(
        selection: null,
      ),
    );
    await controller.selectScreenshot();

    expect(controller.hasScreenshotSelection, isFalse);
    expect(controller.imageIssue, isNull);
    expect(controller.isDirty, isFalse);
  });

  test('selecting and removing a screenshot updates dirty state', () async {
    final controller = _buildController(
      imageService: _FakeFeedbackImageService(
        selection: _selection(),
      ),
    );
    await controller.selectScreenshot();

    expect(controller.hasScreenshotSelection, isTrue);
    expect(controller.screenshotPreviewBytes, isNotNull);
    expect(controller.isDirty, isTrue);

    controller.removeScreenshot();

    expect(controller.hasScreenshotSelection, isFalse);
    expect(controller.isDirty, isFalse);
  });

  test('selecting an unsupported image maps an image error', () async {
    final controller = _buildController(
      imageService: _FakeFeedbackImageService(
        pickError: const FeedbackImageException(
          FeedbackImageErrorType.unsupportedType,
        ),
      ),
    );
    await controller.selectScreenshot();

    expect(controller.imageIssue, FeedbackImageErrorType.unsupportedType);
  });

  test('submit with a screenshot uploads before inserting', () async {
    final events = <String>[];
    final imageService = _FakeFeedbackImageService(
      selection: _selection(),
      events: events,
    );
    final storageService = _FakeFeedbackStorageService(
      events: events,
      uploadPath: '$_feedbackUserId/$_feedbackId/screenshot_$_screenshotId.jpg',
    );
    final repository = _FakeFeedbackRepository(events: events);
    final controller = _buildController(
      repository: repository,
      imageService: imageService,
      storageService: storageService,
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => _feedbackId,
      screenshotIdGenerator: () => _screenshotId,
    );
    controller.selectCategory(FeedbackCategory.bug);
    controller.setDescription('A' * 20);
    await controller.selectScreenshot();

    final result = await controller.submit();

    expect(result?.isSuccess, isTrue);
    expect(events, <String>['pick', 'prepare', 'upload', 'create']);
    expect(storageService.uploadCalls, 1);
    expect(repository.callCount, 1);
    expect(repository.lastRequest?.screenshotPath, isNotNull);
    expect(repository.lastRequest?.screenshotPath, storageService.uploadPath);
    expect(storageService.removeCalls, 0);
  });

  test('upload failure keeps the form editable and skips the repository',
      () async {
    final events = <String>[];
    final imageService = _FakeFeedbackImageService(
      selection: _selection(),
      events: events,
    );
    final storageService = _FakeFeedbackStorageService(
      events: events,
      failUpload: true,
    );
    final repository = _FakeFeedbackRepository(events: events);
    final controller = _buildController(
      repository: repository,
      imageService: imageService,
      storageService: storageService,
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => _feedbackId,
      screenshotIdGenerator: () => _screenshotId,
    );
    controller.selectCategory(FeedbackCategory.bug);
    controller.setDescription('A' * 20);
    await controller.selectScreenshot();

    final result = await controller.submit();

    expect(result?.isSuccess, isFalse);
    expect(controller.imageIssue, FeedbackImageErrorType.uploadFailed);
    expect(repository.callCount, 0);
    expect(storageService.uploadCalls, 1);
    expect(controller.hasScreenshotSelection, isTrue);
  });

  test('insert failure removes the orphaned upload exactly once', () async {
    final events = <String>[];
    final imageService = _FakeFeedbackImageService(
      selection: _selection(),
      events: events,
    );
    final storageService = _FakeFeedbackStorageService(
      events: events,
      uploadPath: '$_feedbackUserId/$_feedbackId/screenshot_$_screenshotId.jpg',
    );
    final repository = _FakeFeedbackRepository(
      events: events,
      result: RepositoryResult<FeedbackReport>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'db failed',
        ),
      ),
    );
    final controller = _buildController(
      repository: repository,
      imageService: imageService,
      storageService: storageService,
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => _feedbackId,
      screenshotIdGenerator: () => _screenshotId,
    );
    controller.selectCategory(FeedbackCategory.bug);
    controller.setDescription('A' * 20);
    await controller.selectScreenshot();

    final result = await controller.submit();

    expect(result?.isSuccess, isFalse);
    expect(storageService.removeCalls, 1);
    expect(repository.callCount, 1);
    expect(controller.imageIssue, isNull);
    expect(controller.hasScreenshotSelection, isTrue);
  });

  test('double submit does not duplicate upload or insert', () async {
    final events = <String>[];
    final pending = Completer<RepositoryResult<FeedbackReport>>();
    final imageService = _FakeFeedbackImageService(
      selection: _selection(),
      events: events,
    );
    final storageService = _FakeFeedbackStorageService(
      events: events,
      uploadPath: '$_feedbackUserId/$_feedbackId/screenshot_$_screenshotId.jpg',
    );
    final repository = _FakeFeedbackRepository(
      events: events,
      pendingResult: pending,
    );
    final controller = _buildController(
      repository: repository,
      imageService: imageService,
      storageService: storageService,
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => _feedbackId,
      screenshotIdGenerator: () => _screenshotId,
    );
    controller.selectCategory(FeedbackCategory.bug);
    controller.setDescription('A' * 20);
    await controller.selectScreenshot();

    final firstSubmit = controller.submit();
    await Future<void>.delayed(Duration.zero);
    final secondSubmit = controller.submit();

    expect(controller.isSubmitting, isTrue);
    expect(await secondSubmit, isNull);

    pending.complete(
      RepositoryResult<FeedbackReport>.success(
        data: _submittedReport(
          id: _feedbackId,
          category: FeedbackCategory.bug,
          description: 'A' * 20,
          contactAllowed: false,
          technicalContext: _FakeTechnicalContextService.defaultContext,
        ),
      ),
    );

    final result = await firstSubmit;

    expect(result?.isSuccess, isTrue);
    expect(storageService.uploadCalls, 1);
    expect(repository.callCount, 1);
  });

  test('retry after upload failure can submit successfully', () async {
    final events = <String>[];
    final imageService = _FakeFeedbackImageService(
      selection: _selection(),
      events: events,
    );
    final storageService = _FakeFeedbackStorageService(
      events: events,
      failUpload: true,
      uploadPath: '$_feedbackUserId/$_feedbackId/screenshot_$_screenshotId.jpg',
    );
    final repository = _FakeFeedbackRepository(events: events);
    final controller = _buildController(
      repository: repository,
      imageService: imageService,
      storageService: storageService,
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => _feedbackId,
      screenshotIdGenerator: () => _screenshotId,
    );
    controller.selectCategory(FeedbackCategory.bug);
    controller.setDescription('A' * 20);
    await controller.selectScreenshot();

    final firstResult = await controller.submit();
    expect(firstResult?.isSuccess, isFalse);
    expect(repository.callCount, 0);
    expect(controller.imageIssue, FeedbackImageErrorType.uploadFailed);

    storageService.failUpload = false;

    final secondResult = await controller.submit();

    expect(secondResult?.isSuccess, isTrue);
    expect(repository.callCount, 1);
    expect(storageService.uploadCalls, 2);
    expect(controller.imageIssue, isNull);
  });
}

FeedbackFormController _buildController({
  FeedbackRepository? repository,
  FeedbackImageService? imageService,
  FeedbackStorageService? storageService,
  FeedbackTechnicalContextService? technicalContextService,
  String Function()? feedbackIdGenerator,
  String Function()? screenshotIdGenerator,
}) {
  final controller = FeedbackFormController(
    repository: repository ?? _FakeFeedbackRepository(),
    imageService: imageService ?? _FakeFeedbackImageService(),
    storageService: storageService ?? _FakeFeedbackStorageService(),
    technicalContextService:
        technicalContextService ?? _FakeTechnicalContextService(),
    feedbackIdGenerator: feedbackIdGenerator ?? () => 'feedback-123',
    screenshotIdGenerator: screenshotIdGenerator ?? () => 'screenshot-123',
  );
  return controller;
}

FeedbackScreenshotSelection _selection() {
  final bytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);
  final file = XFile.fromData(
    bytes,
    name: 'capture.png',
    mimeType: 'image/png',
  );
  return FeedbackScreenshotSelection(
    file: file,
    previewBytes: bytes,
    mimeType: 'image/png',
  );
}

FeedbackReport _submittedReport({
  required String id,
  required FeedbackCategory category,
  required String description,
  required bool contactAllowed,
  required FeedbackTechnicalContext technicalContext,
}) {
  return FeedbackReport(
    id: id,
    category: category,
    description: description,
    contactAllowed: contactAllowed,
    status: FeedbackStatus.submitted,
    technicalContext: technicalContext,
    createdAt: DateTime(2026, 8, 30, 12, 0),
  );
}

class _FakeFeedbackRepository implements FeedbackRepository {
  _FakeFeedbackRepository({
    this.result,
    this.pendingResult,
    this.events,
  });

  final RepositoryResult<FeedbackReport>? result;
  final Completer<RepositoryResult<FeedbackReport>>? pendingResult;
  final List<String>? events;

  int callCount = 0;
  _CreateFeedbackRequest? lastRequest;

  @override
  Future<RepositoryResult<FeedbackReport>> createFeedback({
    required String id,
    required FeedbackCategory category,
    required String description,
    required bool contactAllowed,
    required FeedbackTechnicalContext technicalContext,
    String? screenshotPath,
  }) async {
    callCount += 1;
    events?.add('create');
    lastRequest = _CreateFeedbackRequest(
      id: id,
      category: category,
      description: description,
      contactAllowed: contactAllowed,
      technicalContext: technicalContext,
      screenshotPath: screenshotPath,
    );

    if (pendingResult != null) {
      return pendingResult!.future;
    }

    return result ??
        RepositoryResult<FeedbackReport>.success(
          data: _submittedReport(
            id: id,
            category: category,
            description: description,
            contactAllowed: contactAllowed,
            technicalContext: technicalContext,
          ),
        );
  }

  @override
  Future<RepositoryResult<FeedbackReport>> updateMyFeedback({
    required String feedbackId,
    required String description,
    required bool contactAllowed,
    String? screenshotPath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RepositoryResult<String?>> deleteMyFeedback({
    required String feedbackId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RepositoryResult<List<FeedbackReport>>> getMyFeedback() async {
    return const RepositoryResult<List<FeedbackReport>>.failure(
      RepositoryError(
        code: RepositoryErrorCode.unknown,
        message: 'Not implemented in image controller tests.',
      ),
    );
  }

  @override
  Future<RepositoryResult<FeedbackReport>> getMyFeedbackById({
    required String feedbackId,
  }) async {
    return const RepositoryResult<FeedbackReport>.failure(
      RepositoryError(
        code: RepositoryErrorCode.notFound,
        message: 'Not implemented in image controller tests.',
      ),
    );
  }
}

class _FakeFeedbackImageService extends FeedbackImageService {
  _FakeFeedbackImageService({
    this.selection,
    this.pickError,
    this.events,
  }) : super(
          picker: _NoopImagePicker(),
          compressor: _NoopImageCompressor(),
          tempDirectoryProvider: _tempDirectoryProvider,
        );

  final FeedbackScreenshotSelection? selection;
  final FeedbackImageException? pickError;
  final List<String>? events;

  @override
  Future<FeedbackScreenshotSelection?> pickFromGallery() async {
    events?.add('pick');
    if (pickError != null) throw pickError!;
    return selection;
  }

  @override
  Future<FeedbackPreparedImage> prepareForUpload(
    FeedbackScreenshotSelection selection,
  ) async {
    events?.add('prepare');

    final tempDir = await Directory.systemTemp.createTemp(
      'feedback-controller-image-',
    );
    final file = File('${tempDir.path}/prepared.jpg')
      ..writeAsBytesSync(selection.previewBytes, flush: true);

    return FeedbackPreparedImage(
      file: file,
      bytes: selection.previewBytes,
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
}

class _FakeFeedbackStorageService extends FeedbackStorageService {
  _FakeFeedbackStorageService({
    this.events,
    this.failUpload = false,
    this.uploadPath,
  }) : super(
          gateway: _NoopStorageGateway(),
          currentUserIdProvider: () => _feedbackUserId,
        );

  final List<String>? events;
  bool failUpload;
  String? uploadPath;

  int uploadCalls = 0;
  int removeCalls = 0;

  @override
  Future<String> uploadScreenshot({
    required String feedbackId,
    required String screenshotId,
    required FeedbackPreparedImage image,
  }) async {
    uploadCalls += 1;
    events?.add('upload');
    if (failUpload) {
      throw const FeedbackStorageException(
        FeedbackStorageErrorType.uploadFailed,
      );
    }

    return uploadPath ??
        buildScreenshotPath(
          userId: _feedbackUserId,
          feedbackId: feedbackId,
          screenshotId: screenshotId,
        );
  }

  @override
  Future<void> removeScreenshot({
    required String path,
  }) async {
    removeCalls += 1;
    events?.add('remove');
  }
}

class _FakeTechnicalContextService extends FeedbackTechnicalContextService {
  static const FeedbackTechnicalContext defaultContext =
      FeedbackTechnicalContext(
    appVersion: '1.0.0',
    buildNumber: '1',
    platform: 'android',
    osVersion: '15',
    deviceModel: 'device',
    appLocale: 'es_ES',
    sourceRoute: '/feedback/new',
  );

  @override
  Future<FeedbackTechnicalContext> buildTechnicalContext({
    required String sourceRoute,
  }) async {
    return FeedbackTechnicalContext(
      appVersion: defaultContext.appVersion,
      buildNumber: defaultContext.buildNumber,
      platform: defaultContext.platform,
      osVersion: defaultContext.osVersion,
      deviceModel: defaultContext.deviceModel,
      appLocale: defaultContext.appLocale,
      sourceRoute: sourceRoute.trim(),
    );
  }
}

class _CreateFeedbackRequest {
  const _CreateFeedbackRequest({
    required this.id,
    required this.category,
    required this.description,
    required this.contactAllowed,
    required this.technicalContext,
    required this.screenshotPath,
  });

  final String id;
  final FeedbackCategory category;
  final String description;
  final bool contactAllowed;
  final FeedbackTechnicalContext technicalContext;
  final String? screenshotPath;
}

class _NoopImagePicker implements FeedbackImagePicker {
  @override
  Future<XFile?> pickGalleryImage() async => null;
}

class _NoopImageCompressor implements FeedbackImageCompressor {
  @override
  Future<Uint8List?> compress({
    required String sourcePath,
    required int quality,
    required int minWidth,
    required int minHeight,
  }) async {
    return Uint8List.fromList(<int>[1, 2, 3, 4]);
  }
}

class _NoopStorageGateway implements FeedbackStorageGateway {
  @override
  Future<void> remove({
    required String bucket,
    required String path,
  }) async {}

  @override
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
    required bool upsert,
  }) async {}

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresInSeconds,
  }) async {
    return 'https://example.com/$bucket/$path?expires=$expiresInSeconds';
  }
}

Future<Directory> _tempDirectoryProvider() async {
  return Directory.systemTemp.createTemp('feedback-controller-test-');
}
