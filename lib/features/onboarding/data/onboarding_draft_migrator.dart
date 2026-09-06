import '../domain/models/onboarding_types.dart';
import 'package:uuid/uuid.dart';

enum OnboardingDraftMigrationStatus {
  current,
  migrated,
  unsupportedFutureSchema,
  unsupportedSchema,
}

class OnboardingDraftMigrationResult {
  const OnboardingDraftMigrationResult({
    required this.status,
    this.payload,
    this.message,
  });

  final OnboardingDraftMigrationStatus status;
  final Map<String, dynamic>? payload;
  final String? message;
}

/// Schema migration is intentionally pure and injectable. It does not write
/// anything: the store only replaces a valid payload after codec validation.
class OnboardingDraftMigrator {
  const OnboardingDraftMigrator({
    this.now = _defaultNow,
    this.uuidGenerator = _defaultUuid,
  });

  final DateTime Function() now;
  final String Function() uuidGenerator;

  OnboardingDraftMigrationResult migrate(Map<String, dynamic> raw) {
    final version = _readInt(raw['draftSchemaVersion']) ?? 0;
    if (version > OnboardingVersions.draftSchemaVersion) {
      return const OnboardingDraftMigrationResult(
        status: OnboardingDraftMigrationStatus.unsupportedFutureSchema,
        message: 'Draft schema is newer than this app understands.',
      );
    }
    if (version == OnboardingVersions.draftSchemaVersion) {
      return OnboardingDraftMigrationResult(
        status: OnboardingDraftMigrationStatus.current,
        payload: Map<String, dynamic>.from(raw),
      );
    }
    if (version != 0) {
      return const OnboardingDraftMigrationResult(
        status: OnboardingDraftMigrationStatus.unsupportedSchema,
        message: 'Draft schema is not supported.',
      );
    }

    final migrated = Map<String, dynamic>.from(raw);
    migrated['draftSchemaVersion'] = OnboardingVersions.draftSchemaVersion;
    migrated['onboardingVersion'] ??= OnboardingVersions.onboardingVersion;
    migrated['catalogVersion'] ??= OnboardingVersions.catalogVersion;
    migrated['draftId'] ??= uuidGenerator();
    migrated['onboardingOperationId'] ??= uuidGenerator();
    final timestamp = now().toUtc().toIso8601String();
    migrated['createdAt'] ??= timestamp;
    migrated['updatedAt'] ??= migrated['createdAt'];
    migrated['currentStep'] ??= OnboardingStep.name.code;
    migrated['completionState'] ??= 'draft';

    return OnboardingDraftMigrationResult(
      status: OnboardingDraftMigrationStatus.migrated,
      payload: migrated,
    );
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString().trim());
  }

  static DateTime _defaultNow() => DateTime.now();
  static String _defaultUuid() => const Uuid().v4();
}
