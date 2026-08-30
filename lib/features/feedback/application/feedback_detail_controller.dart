import 'package:flutter/foundation.dart';

import '../../../data/repositories/repository_result.dart';
import '../data/feedback_repository.dart';
import '../data/feedback_storage_service.dart';
import '../data/supabase_feedback_repository.dart';
import '../domain/feedback_report.dart';

enum FeedbackDetailStatus {
  initial,
  loading,
  loaded,
  error,
  notFound,
}

enum FeedbackDetailScreenshotStatus {
  idle,
  loading,
  loaded,
  error,
}

@immutable
class FeedbackDetailState {
  const FeedbackDetailState._({
    required this.status,
    required this.screenshotStatus,
    this.report,
    this.screenshotSignedUrl,
    this.error,
  });

  final FeedbackDetailStatus status;
  final FeedbackDetailScreenshotStatus screenshotStatus;
  final FeedbackReport? report;
  final String? screenshotSignedUrl;
  final RepositoryError? error;

  factory FeedbackDetailState.initial() {
    return const FeedbackDetailState._(
      status: FeedbackDetailStatus.initial,
      screenshotStatus: FeedbackDetailScreenshotStatus.idle,
    );
  }

  factory FeedbackDetailState.loading({
    FeedbackReport? report,
  }) {
    return FeedbackDetailState._(
      status: FeedbackDetailStatus.loading,
      screenshotStatus: report?.hasScreenshot == true
          ? FeedbackDetailScreenshotStatus.loading
          : FeedbackDetailScreenshotStatus.idle,
      report: report,
    );
  }

  factory FeedbackDetailState.loaded({
    required FeedbackReport report,
    FeedbackDetailScreenshotStatus screenshotStatus =
        FeedbackDetailScreenshotStatus.idle,
    String? screenshotSignedUrl,
  }) {
    return FeedbackDetailState._(
      status: FeedbackDetailStatus.loaded,
      screenshotStatus: screenshotStatus,
      report: report,
      screenshotSignedUrl: screenshotSignedUrl,
    );
  }

  factory FeedbackDetailState.error({
    required RepositoryError error,
    FeedbackReport? report,
  }) {
    return FeedbackDetailState._(
      status: FeedbackDetailStatus.error,
      screenshotStatus: FeedbackDetailScreenshotStatus.idle,
      report: report,
      error: error,
    );
  }

  factory FeedbackDetailState.notFound() {
    return const FeedbackDetailState._(
      status: FeedbackDetailStatus.notFound,
      screenshotStatus: FeedbackDetailScreenshotStatus.idle,
    );
  }

  bool get hasReport => report != null;

  bool get isLoading => status == FeedbackDetailStatus.loading;

  bool get isLoaded => status == FeedbackDetailStatus.loaded;

  bool get canEdit => report?.canEdit == true && isLoaded;

  bool get canDelete => report?.canDelete == true && isLoaded;

  bool get hasScreenshot => report?.hasScreenshot == true;

  bool get isScreenshotLoading =>
      screenshotStatus == FeedbackDetailScreenshotStatus.loading;

  bool get isScreenshotLoaded =>
      screenshotStatus == FeedbackDetailScreenshotStatus.loaded;

  bool get isScreenshotError =>
      screenshotStatus == FeedbackDetailScreenshotStatus.error;

  FeedbackDetailState copyWith({
    FeedbackDetailStatus? status,
    FeedbackDetailScreenshotStatus? screenshotStatus,
    FeedbackReport? report,
    String? screenshotSignedUrl,
    RepositoryError? error,
    bool clearReport = false,
    bool clearScreenshotSignedUrl = false,
    bool clearError = false,
  }) {
    return FeedbackDetailState._(
      status: status ?? this.status,
      screenshotStatus: screenshotStatus ?? this.screenshotStatus,
      report: clearReport ? null : (report ?? this.report),
      screenshotSignedUrl: clearScreenshotSignedUrl
          ? null
          : (screenshotSignedUrl ?? this.screenshotSignedUrl),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FeedbackDetailController extends ChangeNotifier {
  FeedbackDetailController({
    FeedbackRepository? repository,
    FeedbackStorageService? storageService,
    FeedbackCurrentUserIdProvider? currentUserIdProvider,
  })  : _repository = repository ??
            SupabaseFeedbackRepository(
              currentUserIdProvider: currentUserIdProvider,
            ),
        _storageService = storageService ??
            FeedbackStorageService(
              currentUserIdProvider: currentUserIdProvider,
            );

  final FeedbackRepository _repository;
  final FeedbackStorageService _storageService;

  FeedbackDetailState _state = FeedbackDetailState.initial();
  String? _feedbackId;
  int _loadEpoch = 0;
  int _screenshotEpoch = 0;
  bool _isDisposed = false;

  FeedbackDetailState get state => _state;

  Future<void> load(
    String feedbackId, {
    FeedbackReport? initialReport,
  }) async {
    final normalizedFeedbackId = feedbackId.trim();
    if (normalizedFeedbackId.isEmpty) {
      _state = FeedbackDetailState.error(
        error: const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Feedback id is required.',
        ),
      );
      _notify();
      return;
    }

    _feedbackId = normalizedFeedbackId;
    final requestEpoch = ++_loadEpoch;
    _state = FeedbackDetailState.loading(report: initialReport);
    _notify();

    final result = await _repository.getMyFeedbackById(
      feedbackId: normalizedFeedbackId,
    );
    if (!_isCurrentLoad(requestEpoch)) {
      return;
    }

    if (!result.isSuccess || result.data == null) {
      final error = result.error ??
          const RepositoryError(
            code: RepositoryErrorCode.unknown,
            message: 'Could not load this feedback.',
          );
      if (error.code == RepositoryErrorCode.notFound) {
        _state = FeedbackDetailState.notFound();
      } else {
        _state = FeedbackDetailState.error(error: error);
      }
      _notify();
      return;
    }

    final report = result.data!;
    _state = FeedbackDetailState.loaded(
      report: report,
      screenshotStatus: report.hasScreenshot
          ? FeedbackDetailScreenshotStatus.loading
          : FeedbackDetailScreenshotStatus.idle,
    );
    _notify();

    if (!report.hasScreenshot) {
      return;
    }

    await _loadScreenshot(report: report, loadEpoch: requestEpoch);
  }

  Future<void> refresh() async {
    final feedbackId = _feedbackId;
    if (feedbackId == null || feedbackId.trim().isEmpty) return;
    await load(
      feedbackId,
      initialReport: _state.report,
    );
  }

  Future<void> retryScreenshot() async {
    final report = _state.report;
    if (report?.hasScreenshot != true) return;
    if (_feedbackId == null || _feedbackId!.trim().isEmpty) return;
    await _loadScreenshot(report: report!, loadEpoch: _loadEpoch);
  }

  Future<void> _loadScreenshot({
    required FeedbackReport report,
    required int loadEpoch,
  }) async {
    if (!_isCurrentLoad(loadEpoch)) return;

    final screenshotEpoch = ++_screenshotEpoch;
    _state = _state.copyWith(
      status: FeedbackDetailStatus.loaded,
      screenshotStatus: FeedbackDetailScreenshotStatus.loading,
      report: report,
      clearScreenshotSignedUrl: true,
      clearError: true,
    );
    _notify();

    try {
      final signedUrl = await _storageService.createSignedScreenshotUrl(
        path: report.screenshotPath!,
      );
      if (!_isCurrentLoad(loadEpoch) || screenshotEpoch != _screenshotEpoch) {
        return;
      }

      _state = _state.copyWith(
        status: FeedbackDetailStatus.loaded,
        screenshotStatus: FeedbackDetailScreenshotStatus.loaded,
        report: report,
        screenshotSignedUrl: signedUrl,
        clearError: true,
      );
      _notify();
    } on FeedbackStorageException catch (_) {
      if (!_isCurrentLoad(loadEpoch) || screenshotEpoch != _screenshotEpoch) {
        return;
      }

      _state = _state.copyWith(
        status: FeedbackDetailStatus.loaded,
        screenshotStatus: FeedbackDetailScreenshotStatus.error,
        report: report,
        clearScreenshotSignedUrl: true,
        clearError: true,
      );
      _notify();
    } catch (error) {
      if (!_isCurrentLoad(loadEpoch) || screenshotEpoch != _screenshotEpoch) {
        return;
      }

      if (kDebugMode) {
        debugPrint(
          '[feedback_detail_controller] unexpected screenshot error: '
          '${error.runtimeType}',
        );
      }

      _state = _state.copyWith(
        status: FeedbackDetailStatus.loaded,
        screenshotStatus: FeedbackDetailScreenshotStatus.error,
        report: report,
        clearScreenshotSignedUrl: true,
        clearError: true,
      );
      _notify();
    }
  }

  bool _isCurrentLoad(int requestEpoch) {
    return !_isDisposed && _loadEpoch == requestEpoch;
  }

  void _notify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
