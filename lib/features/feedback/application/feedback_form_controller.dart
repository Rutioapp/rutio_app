import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/repository_result.dart';
import '../data/feedback_image_service.dart';
import '../data/feedback_repository.dart';
import '../data/feedback_storage_service.dart';
import '../data/feedback_technical_context_service.dart';
import '../data/supabase_feedback_repository.dart';
import '../domain/feedback_category.dart';
import '../domain/feedback_report.dart';

const int feedbackDescriptionMinLength = 20;
const int feedbackDescriptionMaxLength = 5000;

bool isFeedbackDescriptionValid(String value) {
  final trimmedLength = value.trim().length;
  return trimmedLength >= feedbackDescriptionMinLength &&
      trimmedLength <= feedbackDescriptionMaxLength;
}

int feedbackDescriptionTrimmedLength(String value) => value.trim().length;

class FeedbackFormController extends ChangeNotifier {
  FeedbackFormController({
    FeedbackRepository? repository,
    FeedbackTechnicalContextService? technicalContextService,
    FeedbackImageService? imageService,
    FeedbackStorageService? storageService,
    String Function()? feedbackIdGenerator,
    String Function()? screenshotIdGenerator,
    String sourceRoute = '/feedback/new',
    FeedbackCategory? initialCategory,
    String initialDescription = '',
    bool initialContactAllowed = false,
    String? initialScreenshotPath,
    void Function(String message)? logger,
  })  : _initialCategory = initialCategory,
        _initialDescription = initialDescription,
        _initialContactAllowed = initialContactAllowed,
        _initialScreenshotPath = _normalizeOptionalPath(initialScreenshotPath),
        _repository = repository ?? SupabaseFeedbackRepository(),
        _technicalContextService =
            technicalContextService ?? FeedbackTechnicalContextService(),
        _imageService = imageService ?? FeedbackImageService(),
        _storageService = storageService ?? FeedbackStorageService(),
        _feedbackIdGenerator =
            feedbackIdGenerator ?? _defaultFeedbackIdGenerator,
        _screenshotIdGenerator =
            screenshotIdGenerator ?? _defaultScreenshotIdGenerator,
        _sourceRoute = sourceRoute,
        _logger = logger,
        _category = initialCategory,
        _contactAllowed = initialContactAllowed,
        _selectedScreenshotPath = _normalizeOptionalPath(initialScreenshotPath) {
    _descriptionController = TextEditingController(text: initialDescription)
      ..addListener(_handleDescriptionChanged);
  }

  late final TextEditingController _descriptionController;

  final FeedbackCategory? _initialCategory;
  final String _initialDescription;
  final bool _initialContactAllowed;
  final String? _initialScreenshotPath;
  final FeedbackRepository _repository;
  final FeedbackTechnicalContextService _technicalContextService;
  final FeedbackImageService _imageService;
  final FeedbackStorageService _storageService;
  final String Function() _feedbackIdGenerator;
  final String Function() _screenshotIdGenerator;
  final String _sourceRoute;
  final void Function(String message)? _logger;

  FeedbackCategory? _category;
  String _description = '';
  bool _contactAllowed = false;
  bool _isSubmitting = false;
  bool _isSelectingScreenshot = false;
  FeedbackScreenshotSelection? _selectedScreenshot;
  String? _selectedScreenshotPath;
  FeedbackImageErrorType? _imageIssue;

  FeedbackCategory? get category => _category;
  String get description => _description;
  bool get contactAllowed => _contactAllowed;
  bool get isSubmitting => _isSubmitting;
  bool get isSelectingScreenshot => _isSelectingScreenshot;
  FeedbackImageErrorType? get imageIssue => _imageIssue;
  TextEditingController get descriptionController => _descriptionController;

  int get descriptionLength => _description.length;
  int get trimmedDescriptionLength =>
      feedbackDescriptionTrimmedLength(_description);
  String get trimmedDescription => _description.trim();

  bool get isDescriptionValid => isFeedbackDescriptionValid(_description);

  bool get hasScreenshotSelection => _selectedScreenshot != null;
  String? get screenshotPreviewPath => _selectedScreenshot?.path;
  Uint8List? get screenshotPreviewBytes => _selectedScreenshot?.previewBytes;
  String? get screenshotMimeType => _selectedScreenshot?.mimeType;

  bool get isDirty =>
      _category != _initialCategory ||
      _description != _initialDescription ||
      _contactAllowed != _initialContactAllowed ||
      _selectedScreenshotPath != _initialScreenshotPath;

  bool get canSubmit =>
      !_isSubmitting && _category != null && isDescriptionValid;

  bool get canEditScreenshot => !_isSubmitting && !_isSelectingScreenshot;

  void selectCategory(FeedbackCategory? category) {
    if (_category == category) return;
    _category = category;
    notifyListeners();
  }

  void setContactAllowed(bool value) {
    if (_contactAllowed == value) return;
    _contactAllowed = value;
    notifyListeners();
  }

  void toggleContactAllowed() {
    setContactAllowed(!_contactAllowed);
  }

  void setDescription(String value) {
    if (_descriptionController.text == value) return;
    _descriptionController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  Future<void> selectScreenshot() async {
    if (_isSubmitting || _isSelectingScreenshot) return;

    _isSelectingScreenshot = true;
    notifyListeners();

    try {
      final selection = await _imageService.pickFromGallery();
      if (selection == null) return;

      _selectedScreenshot = selection;
      _selectedScreenshotPath = selection.path.trim();
      _imageIssue = null;
    } on FeedbackImageException catch (error) {
      _imageIssue = error.type;
    } catch (error) {
      _imageIssue = FeedbackImageErrorType.notProcessable;
      if (error is Error || error is Exception) {
        _log('[feedback_form] unexpected screenshot selection error: '
            '${error.runtimeType}');
      }
    } finally {
      _isSelectingScreenshot = false;
      notifyListeners();
    }
  }

  void removeScreenshot() {
    if (_isSubmitting || _isSelectingScreenshot) return;
    if (_selectedScreenshot == null && _selectedScreenshotPath == null) return;

    _selectedScreenshot = null;
    _selectedScreenshotPath = null;
    _imageIssue = null;
    notifyListeners();
  }

  Future<RepositoryResult<FeedbackReport>?> submit() async {
    if (!canSubmit || _isSubmitting) return null;

    _isSubmitting = true;
    _imageIssue = null;
    notifyListeners();

    FeedbackPreparedImage? preparedImage;
    String? uploadedScreenshotPath;

    try {
      final feedbackId = _feedbackIdGenerator().trim();
      final technicalContext = await _technicalContextService
          .buildTechnicalContext(sourceRoute: _sourceRoute);

      if (_selectedScreenshot != null) {
        preparedImage = await _imageService.prepareForUpload(
          _selectedScreenshot!,
        );

        final screenshotId = _screenshotIdGenerator().trim();
        uploadedScreenshotPath = await _storageService.uploadScreenshot(
          feedbackId: feedbackId,
          screenshotId: screenshotId,
          image: preparedImage,
        );
      }

      final result = await _repository.createFeedback(
        id: feedbackId,
        category: _category!,
        description: trimmedDescription,
        screenshotPath: uploadedScreenshotPath,
        contactAllowed: _contactAllowed,
        technicalContext: technicalContext,
      );

      if (!result.isSuccess && uploadedScreenshotPath != null) {
        await _bestEffortRemoveRemoteScreenshot(uploadedScreenshotPath);
      }

      return result;
    } on FeedbackImageException catch (error) {
      _imageIssue = error.type;
      return RepositoryResult<FeedbackReport>.failure(
        RepositoryError(
          code: _mapImageIssueToRepositoryCode(error.type),
          message: error.type.name,
          cause: error,
        ),
      );
    } on FeedbackStorageException catch (error) {
      _imageIssue = error.type == FeedbackStorageErrorType.uploadFailed
          ? FeedbackImageErrorType.uploadFailed
          : FeedbackImageErrorType.cleanupFailed;
      return RepositoryResult<FeedbackReport>.failure(
        RepositoryError(
          code: _mapStorageIssueToRepositoryCode(error.type),
          message: error.type.name,
          cause: error,
        ),
      );
    } on FormatException catch (error) {
      return RepositoryResult<FeedbackReport>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message,
          cause: error,
        ),
      );
    } catch (error) {
      return RepositoryResult<FeedbackReport>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not send feedback.',
          cause: error,
        ),
      );
    } finally {
      if (preparedImage != null) {
        try {
          await preparedImage.cleanup();
        } catch (error) {
          _log(
            '[feedback_form] temporary screenshot cleanup failed: '
            '${error.runtimeType}',
          );
        }
      }

      _isSubmitting = false;
      notifyListeners();
    }
  }

  static String _defaultFeedbackIdGenerator() => const Uuid().v4();

  static String _defaultScreenshotIdGenerator() => const Uuid().v4();

  void _handleDescriptionChanged() {
    final next = _descriptionController.text;
    if (_description == next) return;
    _description = next;
    notifyListeners();
  }

  Future<void> _bestEffortRemoveRemoteScreenshot(String path) async {
    try {
      await _storageService.removeScreenshot(path: path);
    } on FeedbackStorageException catch (error) {
      _log(
        '[feedback_form] remote screenshot cleanup failed: ${error.type}',
      );
    } catch (error) {
      _log(
        '[feedback_form] remote screenshot cleanup failed: '
        '${error.runtimeType}',
      );
    }
  }

  RepositoryErrorCode _mapImageIssueToRepositoryCode(
    FeedbackImageErrorType type,
  ) {
    return switch (type) {
      FeedbackImageErrorType.uploadFailed => RepositoryErrorCode.network,
      FeedbackImageErrorType.cleanupFailed => RepositoryErrorCode.unknown,
      FeedbackImageErrorType.tooLarge ||
      FeedbackImageErrorType.notProcessable ||
      FeedbackImageErrorType.compressionFailed ||
      FeedbackImageErrorType.unsupportedType =>
        RepositoryErrorCode.invalidResponse,
    };
  }

  RepositoryErrorCode _mapStorageIssueToRepositoryCode(
    FeedbackStorageErrorType type,
  ) {
    return switch (type) {
      FeedbackStorageErrorType.notAuthenticated =>
        RepositoryErrorCode.notAuthenticated,
      FeedbackStorageErrorType.invalidPath =>
        RepositoryErrorCode.invalidResponse,
      FeedbackStorageErrorType.uploadFailed => RepositoryErrorCode.network,
      FeedbackStorageErrorType.removeFailed => RepositoryErrorCode.unknown,
    };
  }

  void _log(String message) {
    _logger?.call(message);
  }

  @override
  void dispose() {
    _descriptionController
      ..removeListener(_handleDescriptionChanged)
      ..dispose();
    super.dispose();
  }

  static String? _normalizeOptionalPath(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
