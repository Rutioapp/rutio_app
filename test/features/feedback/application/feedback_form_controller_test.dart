import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/feedback/application/feedback_form_controller.dart';
import 'package:rutio/features/feedback/domain/feedback_category.dart';

void main() {
  test('initial category is null', () {
    final controller = FeedbackFormController();
    addTearDown(controller.dispose);

    expect(controller.category, isNull);
  });

  test('initial contactAllowed is false', () {
    final controller = FeedbackFormController();
    addTearDown(controller.dispose);

    expect(controller.contactAllowed, isFalse);
  });

  test('selecting a category updates state', () {
    final controller = FeedbackFormController();
    addTearDown(controller.dispose);

    controller.selectCategory(FeedbackCategory.bug);

    expect(controller.category, FeedbackCategory.bug);
  });

  test('only one category stays active at a time', () {
    final controller = FeedbackFormController();
    addTearDown(controller.dispose);

    controller.selectCategory(FeedbackCategory.bug);
    controller.selectCategory(FeedbackCategory.other);

    expect(controller.category, FeedbackCategory.other);
  });

  test('description with 19 trimmed characters is invalid', () {
    final controller = FeedbackFormController();
    addTearDown(controller.dispose);

    controller.setDescription('a' * 19);

    expect(isFeedbackDescriptionValid(controller.description), isFalse);
  });

  test('description with 20 trimmed characters is valid', () {
    final controller = FeedbackFormController();
    addTearDown(controller.dispose);

    controller.setDescription('a' * 20);

    expect(isFeedbackDescriptionValid(controller.description), isTrue);
  });

  test('description with 5000 trimmed characters is valid', () {
    final controller = FeedbackFormController();
    addTearDown(controller.dispose);

    controller.setDescription('a' * 5000);

    expect(isFeedbackDescriptionValid(controller.description), isTrue);
  });

  test('description with 5001 trimmed characters is invalid', () {
    final controller = FeedbackFormController();
    addTearDown(controller.dispose);

    controller.setDescription('a' * 5001);

    expect(isFeedbackDescriptionValid(controller.description), isFalse);
  });

  test('trim is applied when validating description', () {
    final controller = FeedbackFormController();
    addTearDown(controller.dispose);

    controller.setDescription('  ${'a' * 20}  ');

    expect(controller.trimmedDescription, 'a' * 20);
    expect(isFeedbackDescriptionValid(controller.description), isTrue);
  });

  test('canSubmit requires category and valid description', () {
    final controller = FeedbackFormController();
    addTearDown(controller.dispose);

    expect(controller.canSubmit, isFalse);

    controller.selectCategory(FeedbackCategory.bug);
    controller.setDescription('a' * 19);
    expect(controller.canSubmit, isFalse);

    controller.setDescription('a' * 20);
    expect(controller.canSubmit, isTrue);
  });

  test('dirty state tracks modified fields', () {
    final controller = FeedbackFormController();
    addTearDown(controller.dispose);

    expect(controller.isDirty, isFalse);

    controller.selectCategory(FeedbackCategory.bug);
    expect(controller.isDirty, isTrue);

    controller.selectCategory(null);
    expect(controller.isDirty, isFalse);

    controller.setDescription('a');
    expect(controller.isDirty, isTrue);

    controller.setDescription('');
    expect(controller.isDirty, isFalse);

    controller.setContactAllowed(true);
    expect(controller.isDirty, isTrue);
  });
}
