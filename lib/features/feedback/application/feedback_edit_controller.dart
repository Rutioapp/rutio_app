
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/repository_result.dart';
import '../data/feedback_image_service.dart';
import '../data/feedback_repository.dart';
import '../data/feedback_storage_service.dart';
import '../data/supabase_feedback_repository.dart';
import '../domain/feedback_category.dart';
import '../domain/feedback_report.dart';
import 'feedback_form_controller.dart';

class FeedbackEditController extends ChangeNotifier {
  FeedbackEditController({
    required FeedbackReport report,
    FeedbackRepository? repository,
    FeedbackImageService? imageService,
    FeedbackStorageService? storageService,
    FeedbackCurrentUserIdProvider? currentUserIdProvider,
    String Function()? screenshotIdGenerator,
    void Function(String message)? logger,
  })  : _report = report,
        _repository = repository ??
            SupabaseFeedbackRepository(
              currentUserIdProvider: currentUserIdProvider,
            ),
        _imageService = imageService ?? FeedbackImageService(),
        _storageService = storageService ??
            FeedbackStorageService(
              currentUserIdProvider: currentUserIdProvider,
            ),
        _screenshotIdGenerator =
            screenshotIdGenerator ?? _defaultScreenshotIdGenerator,
        _logger = logger,
        _baselineDescription = report.description,
        _baselineContactAllowed = report.contactAllowed,
        _baselineScreenshotPath = _normalizeOptionalPath(report.screenshotPath),
        _description = report.description,
        _contactAllowed = report.contactAllowed {
    _descriptionController = TextEditingController(text: report.description)
      ..addListener(_handleDescriptionChanged);
  }

  late final TextEditingController _descriptionController;

  final FeedbackRepository _repository;
  final FeedbackImageService _imageService;
  final FeedbackStorageService _storageService;
  final String Function() _screenshotIdGenerator;
  final void Function(String message)? _logger;

  FeedbackReport _report;
  String _baselineDescription;
  bool _baselineContactAllowed;
  String? _baselineScreenshotPath;
  String _description;
  bool _contactAllowed;
  bool _isSaving = false;
  bool _isSelectingScreenshot = false;
  FeedbackScreenshotSelection? _selectedScreenshot;
  bool _screenshotRemoved = false;
  FeedbackImageErrorType? _imageIssue;

  FeedbackReport get report => _report;
  FeedbackCategory get category => _report.category;
  String get description => _description;
  bool get contactAllowed => _contactAllowed;
  bool get isSaving => _isSaving;
  bool get isSelectingScreenshot => _isSelectingScreenshot;
  FeedbackImageErrorType? get imageIssue => _imageIssue;
  TextEditingController get descriptionController => _descriptionController;

  int get descriptionLength => _description.length;
  int get trimmedDescriptionLength => feedbackDescriptionTrimmedLength(_description);
  String get trimmedDescription => _description.trim();

  bool get isDescriptionValid => isFeedbackDescriptionValid(_description);

  bool get hasSelectedScreenshot => _selectedScreenshot != null;
  bool get hasExistingScreenshot => _baselineScreenshotPath != null;
  bool get hasVisibleCurrentScreenshot =>
      _selectedScreenshot == null &&
      !_screenshotRemoved &&
      _baselineScreenshotPath != null;
  String? get currentScreenshotPath =>
      hasVisibleCurrentScreenshot ? _baselineScreenshotPath : null;
  Uint8List? get selectedScreenshotPreviewBytes =>
      _selectedScreenshot?.previewBytes;

  bool get isDirty =>
      _description != _baselineDescription ||
      _contactAllowed != _baselineContactAllowed ||
      _selectedScreenshot != null ||
      (_baselineScreenshotPath != null && _screenshotRemoved);

  bool get canSave =>
      !_isSaving && !_isSelectingScreenshot && isDescriptionValid && isDirty;

  bool get canEditScreenshot => !_isSaving && !_isSelectingScreenshot;

  void setDescription(String value) {
    if (_descriptionController.text == value) return;
    _descriptionController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  void setContactAllowed(bool value) {
    if (_contactAllowed == value) return;
    _contactAllowed = value;
    notifyListeners();
  }

  void toggleContactAllowed() {
    setContactAllowed(!_contactAllowed);
  }

  Future<void> selectScreenshot() async {
    if (!canEditScreenshot) return;

    _isSelectingScreenshot = true;
    notifyListeners();

    try {
      final selection = await _imageService.pickFromGallery();
      if (selection == null) return;

      _selectedScreenshot = selection;
      _screenshotRemoved = false;
      _imageIssue = null;
    } on FeedbackImageException catch (error) {
      _imageIssue = error.type;
    } catch (error) {
      _imageIssue = FeedbackImageErrorType.notProcessable;
      if (kDebugMode) {
        _logger?.call(
          '[feedback_edit_controller] unexpected screenshot selection error: '
          '${error.runtimeType}',
        );
      }
    } finally {
      _isSelectingScreenshot = false;
      notifyListeners();
    }
  }

  void removeScreenshot() {
    if (!canEditScreenshot) return;
    if (_selectedScreenshot == null && _baselineScreenshotPath == null) return;

    if (_selectedScreenshot != null) {
      _selectedScreenshot = null;
      _imageIssue = null;
      notifyListeners();
      return;
    }

    if (_baselineScreenshotPath != null) {
      _screenshotRemoved = true;
      _imageIssue = null;
      notifyListeners();
    }
  }

  Future<RepositoryResult<FeedbackReport>?> save() async {
    if (!canSave || _isSaving) return null;

    _isSaving = true;
    _imageIssue = null;
    notifyListeners();

    FeedbackPreparedImage? preparedImage;
    String? uploadedScreenshotPath;
    final previousScreenshotPath = _baselineScreenshotPath;

    try {
      final feedbackId = _report.id.trim();
      String? screenshotPathToPersist = previousScreenshotPath;

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
        screenshotPathToPersist = uploadedScreenshotPath;
      } else if (_baselineScreenshotPath != null && _screenshotRemoved) {
        screenshotPathToPersist = null;
      }

      final result = await _repository.updateMyFeedback(
        feedbackId: feedbackId,
        description: trimmedDescription,
        screenshotPath: screenshotPathToPersist,
        contactAllowed: _contactAllowed,
      );

      if (!result.isSuccess || result.data == null) {
        if (uploadedScreenshotPath != null) {
          await _bestEffortRemoveRemoteScreenshot(uploadedScreenshotPath);
        }
        return result;
      }

      final updated = result.data!;
      _report = updated;
      _baselineDescription = updated.description;
      _baselineContactAllowed = updated.contactAllowed;
      _baselineScreenshotPath = _normalizeOptionalPath(updated.screenshotPath);
      _description = updated.description;
      _contactAllowed = updated.contactAllowed;
      _selectedScreenshot = null;
      _screenshotRemoved = false;
      _descriptionController.value = TextEditingValue(
        text: updated.description,
        selection: TextSelection.collapsed(offset: updated.description.length),
        composing: TextRange.empty,
      );

      if (previousScreenshotPath != null &&
          previousScreenshotPath != _baselineScreenshotPath) {
        await _bestEffortRemoveRemoteScreenshot(previousScreenshotPath);
      }

      return RepositoryResult<FeedbackReport>.success(data: updated);
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
          message: 'Could not update this feedback.',
          cause: error,
        ),
      );
    } finally {
      if (preparedImage != null) {
        try {
          await preparedImage.cleanup();
        } catch (error) {
          if (kDebugMode) {
            _logger?.call(
              '[feedback_edit_controller] temporary screenshot cleanup failed: '
              '${error.runtimeType}',
            );
          }
        }
      }

      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _bestEffortRemoveRemoteScreenshot(String path) async {
    try {
      await _storageService.removeScreenshot(path: path);
    } on FeedbackStorageException catch (error) {
      if (kDebugMode) {
        _logger?.call(
          '[feedback_edit_controller] remote screenshot cleanup failed: '
          '${error.type}',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        _logger?.call(
          '[feedback_edit_controller] remote screenshot cleanup failed: '
          '${error.runtimeType}',
        );
      }
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
      FeedbackStorageErrorType.signedUrlFailed => RepositoryErrorCode.network,
    };
  }

  void _handleDescriptionChanged() {
    final next = _descriptionController.text;
    if (_description == next) return;
    _description = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _descriptionController
      ..removeListener(_handleDescriptionChanged)
      ..dispose();
    super.dispose();
  }

  static String _defaultScreenshotIdGenerator() => const Uuid().v4();

  static String? _normalizeOptionalPath(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}

