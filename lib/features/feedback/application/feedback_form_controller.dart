import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/feedback_category.dart';

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
    FeedbackCategory? initialCategory,
    String initialDescription = '',
    bool initialContactAllowed = false,
  })  : _initialCategory = initialCategory,
        _initialDescription = initialDescription,
        _initialContactAllowed = initialContactAllowed,
        _category = initialCategory,
        _contactAllowed = initialContactAllowed {
    _descriptionController = TextEditingController(text: initialDescription)
      ..addListener(_handleDescriptionChanged);
  }

  late final TextEditingController _descriptionController;

  final FeedbackCategory? _initialCategory;
  final String _initialDescription;
  final bool _initialContactAllowed;

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
  int get trimmedDescriptionLength => feedbackDescriptionTrimmedLength(_description);
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

  Future<bool> submit(FutureOr<void> Function() onValidSubmit) async {
    if (!canSubmit) return false;

    _isSubmitting = true;
    notifyListeners();

    try {
      await onValidSubmit();
      return true;
    } finally {
      if (_isSubmitting) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
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
}
