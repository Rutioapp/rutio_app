import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/repository_result.dart';
import '../data/feedback_repository.dart';
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
    String Function()? feedbackIdGenerator,
    String sourceRoute = '/feedback/new',
    FeedbackCategory? initialCategory,
    String initialDescription = '',
    bool initialContactAllowed = false,
  })  : _initialCategory = initialCategory,
        _initialDescription = initialDescription,
        _initialContactAllowed = initialContactAllowed,
        _repository = repository ?? SupabaseFeedbackRepository(),
        _technicalContextService =
            technicalContextService ?? FeedbackTechnicalContextService(),
        _feedbackIdGenerator =
            feedbackIdGenerator ?? _defaultFeedbackIdGenerator,
        _sourceRoute = sourceRoute,
        _category = initialCategory,
        _contactAllowed = initialContactAllowed {
    _descriptionController = TextEditingController(text: initialDescription)
      ..addListener(_handleDescriptionChanged);
  }

  late final TextEditingController _descriptionController;

  final FeedbackCategory? _initialCategory;
  final String _initialDescription;
  final bool _initialContactAllowed;
  final FeedbackRepository _repository;
  final FeedbackTechnicalContextService _technicalContextService;
  final String Function() _feedbackIdGenerator;
  final String _sourceRoute;

  FeedbackCategory? _category;
  String _description = '';
  bool _contactAllowed = false;
  bool _isSubmitting = false;

  FeedbackCategory? get category => _category;
  String get description => _description;
  bool get contactAllowed => _contactAllowed;
  bool get isSubmitting => _isSubmitting;
  TextEditingController get descriptionController => _descriptionController;

  int get descriptionLength => _description.length;
  int get trimmedDescriptionLength =>
      feedbackDescriptionTrimmedLength(_description);
  String get trimmedDescription => _description.trim();

  bool get isDescriptionValid => isFeedbackDescriptionValid(_description);

  bool get isDirty =>
      _category != _initialCategory ||
      _description != _initialDescription ||
      _contactAllowed != _initialContactAllowed;

  bool get canSubmit =>
      !_isSubmitting && _category != null && isDescriptionValid;

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

  Future<RepositoryResult<FeedbackReport>?> submit() async {
    if (!canSubmit || _isSubmitting) return null;

    _isSubmitting = true;
    notifyListeners();

    try {
      final feedbackId = _feedbackIdGenerator().trim();
      final technicalContext = await _technicalContextService
          .buildTechnicalContext(sourceRoute: _sourceRoute);
      return await _repository.createFeedback(
        id: feedbackId,
        category: _category!,
        description: trimmedDescription,
        screenshotPath: null,
        contactAllowed: _contactAllowed,
        technicalContext: technicalContext,
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
      if (_isSubmitting) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  static String _defaultFeedbackIdGenerator() => const Uuid().v4();

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
}
