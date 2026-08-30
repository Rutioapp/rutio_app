import 'package:flutter/foundation.dart';

import '../../../data/repositories/repository_result.dart';
import '../data/feedback_repository.dart';
import '../data/supabase_feedback_repository.dart';
import '../domain/feedback_report.dart';
import '../domain/feedback_status.dart';

enum FeedbackMineFilter {
  all,
  submitted,
  inReview,
  closed,
}

enum FeedbackMineStatus {
  initial,
  loading,
  loaded,
  empty,
  error,
}

@immutable
class FeedbackMineState {
  const FeedbackMineState._({
    required this.status,
    required this.reports,
    this.error,
  });

  final FeedbackMineStatus status;
  final List<FeedbackReport> reports;
  final RepositoryError? error;

  factory FeedbackMineState.initial() {
    return const FeedbackMineState._(
      status: FeedbackMineStatus.initial,
      reports: <FeedbackReport>[],
    );
  }

  factory FeedbackMineState.loading({
    List<FeedbackReport> reports = const <FeedbackReport>[],
  }) {
    return FeedbackMineState._(
      status: FeedbackMineStatus.loading,
      reports: List<FeedbackReport>.unmodifiable(reports),
    );
  }

  factory FeedbackMineState.loaded({
    required List<FeedbackReport> reports,
  }) {
    return FeedbackMineState._(
      status: FeedbackMineStatus.loaded,
      reports: List<FeedbackReport>.unmodifiable(reports),
    );
  }

  factory FeedbackMineState.empty({
    List<FeedbackReport> reports = const <FeedbackReport>[],
  }) {
    return FeedbackMineState._(
      status: FeedbackMineStatus.empty,
      reports: List<FeedbackReport>.unmodifiable(reports),
    );
  }

  factory FeedbackMineState.error({
    required RepositoryError error,
    List<FeedbackReport> reports = const <FeedbackReport>[],
  }) {
    return FeedbackMineState._(
      status: FeedbackMineStatus.error,
      reports: List<FeedbackReport>.unmodifiable(reports),
      error: error,
    );
  }

  bool get isLoading => status == FeedbackMineStatus.loading;

  bool get hasReports => reports.isNotEmpty;
}

class FeedbackMineController extends ChangeNotifier {
  FeedbackMineController({
    FeedbackRepository? repository,
    FeedbackCurrentUserIdProvider? currentUserIdProvider,
  }) : _repository = repository ??
            SupabaseFeedbackRepository(
              currentUserIdProvider: currentUserIdProvider,
            );

  final FeedbackRepository _repository;

  FeedbackMineState _state = FeedbackMineState.initial();
  FeedbackMineFilter _filter = FeedbackMineFilter.all;
  int _requestEpoch = 0;
  bool _isDisposed = false;

  FeedbackMineState get state => _state;

  FeedbackMineFilter get filter => _filter;

  List<FeedbackReport> get reports => _state.reports;

  List<FeedbackReport> get visibleReports =>
      _filterReports(_state.reports, _filter);

  Future<void> load() async {
    await _fetch();
  }

  Future<void> refresh() async {
    await _fetch();
  }

  Future<void> retry() async {
    await _fetch();
  }

  void setFilter(FeedbackMineFilter value) {
    if (_filter == value) return;
    _filter = value;
    _notify();
  }

  Future<void> _fetch() async {
    if (_isDisposed) return;

    final requestEpoch = ++_requestEpoch;
    final previousReports = _state.reports;
    _state = FeedbackMineState.loading(reports: previousReports);
    _notify();

    final result = await _repository.getMyFeedback();
    if (!_isRequestCurrent(requestEpoch)) {
      return;
    }

    if (!result.isSuccess || result.data == null) {
      final error = result.error ??
          const RepositoryError(
            code: RepositoryErrorCode.unknown,
            message: 'Could not load your feedback.',
          );
      _state = FeedbackMineState.error(
        error: error,
        reports: previousReports,
      );
      _notify();
      return;
    }

    final reports = _sortReports(result.data!);
    if (reports.isEmpty) {
      _state = FeedbackMineState.empty(reports: reports);
    } else {
      _state = FeedbackMineState.loaded(reports: reports);
    }
    _notify();
    return;
  }

  List<FeedbackReport> _sortReports(List<FeedbackReport> reports) {
    final sorted = List<FeedbackReport>.from(reports)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  List<FeedbackReport> _filterReports(
    List<FeedbackReport> reports,
    FeedbackMineFilter filter,
  ) {
    return reports.where((report) {
      switch (filter) {
        case FeedbackMineFilter.all:
          return true;
        case FeedbackMineFilter.submitted:
          return report.status == FeedbackStatus.submitted;
        case FeedbackMineFilter.inReview:
          return report.status == FeedbackStatus.inReview;
        case FeedbackMineFilter.closed:
          return report.status == FeedbackStatus.resolved ||
              report.status == FeedbackStatus.dismissed;
      }
    }).toList(growable: false);
  }

  bool _isRequestCurrent(int requestEpoch) {
    return !_isDisposed && _requestEpoch == requestEpoch;
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
