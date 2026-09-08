import 'dart:convert';

import '../domain/models/onboarding_draft.dart';
import '../domain/models/onboarding_types.dart';
import '../domain/onboarding_validation.dart';
import 'onboarding_draft_migrator.dart';

enum OnboardingDraftDecodeStatus {
  valid,
  migrated,
  recoverableError,
  corrupt,
  unsupportedFutureSchema,
}

class OnboardingDraftDecodeResult {
  const OnboardingDraftDecodeResult({
    required this.status,
    this.draft,
    this.message,
  });

  final OnboardingDraftDecodeStatus status;
  final OnboardingDraft? draft;
  final String? message;

  bool get isUsable => draft != null;
}

/// Explicit, defensive JSON codec for the local onboarding draft.
class OnboardingDraftCodec {
  OnboardingDraftCodec({OnboardingDraftMigrator? migrator})
      : _migrator = migrator ?? const OnboardingDraftMigrator();

  final OnboardingDraftMigrator _migrator;

  Map<String, dynamic> encode(OnboardingDraft draft) {
    _validateEnvelope(draft);
    return <String, dynamic>{
      'draftId': draft.draftId,
      'onboardingOperationId': draft.onboardingOperationId,
      'draftSchemaVersion': draft.draftSchemaVersion,
      'onboardingVersion': draft.onboardingVersion,
      'catalogVersion': draft.catalogVersion,
      'createdAt': draft.createdAt.toUtc().toIso8601String(),
      'updatedAt': draft.updatedAt.toUtc().toIso8601String(),
      'currentStep': draft.currentStep.code,
      'firstName': draft.firstName,
      'goalCodes': draft.goalCodes.toList(growable: false),
      'pace': draft.pace?.code,
      'habit': _jsonValue(draft.habit),
      'reminder': _jsonValue(draft.reminder),
      'shownRecommendationIds':
          draft.shownRecommendationIds.toList(growable: false),
      'discardedRecommendationIds':
          draft.discardedRecommendationIds.toList(growable: false),
      'selectedRecommendationId': draft.selectedRecommendationId,
      'authIntent': draft.authIntent?.code,
      'authEmail': draft.authEmail,
      'completionState': draft.completionState.code,
      'boundUserId': draft.boundUserId,
      'completedAt': draft.completedAt?.toUtc().toIso8601String(),
    };
  }

  String encodeString(OnboardingDraft draft) => jsonEncode(encode(draft));

  OnboardingDraftDecodeResult decodeString(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const OnboardingDraftDecodeResult(
          status: OnboardingDraftDecodeStatus.corrupt,
          message: 'Draft payload is not a JSON object.',
        );
      }
      return decode(Map<String, dynamic>.from(decoded.cast<String, dynamic>()));
    } on FormatException catch (error) {
      return OnboardingDraftDecodeResult(
        status: OnboardingDraftDecodeStatus.corrupt,
        message: error.message,
      );
    } catch (_) {
      return const OnboardingDraftDecodeResult(
        status: OnboardingDraftDecodeStatus.corrupt,
        message: 'Draft payload could not be decoded.',
      );
    }
  }

  OnboardingDraftDecodeResult decode(Object? raw) {
    if (raw is String) return decodeString(raw);
    if (raw is! Map) {
      return const OnboardingDraftDecodeResult(
        status: OnboardingDraftDecodeStatus.corrupt,
        message: 'Draft payload is not a map.',
      );
    }

    try {
      final source = Map<String, dynamic>.from(raw.cast<String, dynamic>());
      final migration = _migrator.migrate(source);
      if (migration.status ==
          OnboardingDraftMigrationStatus.unsupportedFutureSchema) {
        return OnboardingDraftDecodeResult(
          status: OnboardingDraftDecodeStatus.unsupportedFutureSchema,
          message: migration.message,
        );
      }
      if (migration.payload == null) {
        return OnboardingDraftDecodeResult(
          status: OnboardingDraftDecodeStatus.corrupt,
          message: migration.message,
        );
      }

      final result = _decodeCurrent(migration.payload!);
      if (result.draft == null) return result;
      if (migration.status == OnboardingDraftMigrationStatus.migrated &&
          result.status == OnboardingDraftDecodeStatus.valid) {
        return OnboardingDraftDecodeResult(
          status: OnboardingDraftDecodeStatus.migrated,
          draft: result.draft,
          message: result.message,
        );
      }
      return result;
    } catch (_) {
      return const OnboardingDraftDecodeResult(
        status: OnboardingDraftDecodeStatus.corrupt,
        message: 'Draft payload is not compatible with the local contract.',
      );
    }
  }

  OnboardingDraftDecodeResult _decodeCurrent(Map<String, dynamic> json) {
    final draftId = _uuid(json['draftId']);
    final operationId = _uuid(json['onboardingOperationId']);
    final createdAt = _date(json['createdAt']);
    final updatedAt = _date(json['updatedAt']);
    final currentStep = OnboardingStep.fromCode(json['currentStep']);
    if (draftId == null ||
        operationId == null ||
        draftId == operationId ||
        createdAt == null ||
        updatedAt == null) {
      return const OnboardingDraftDecodeResult(
        status: OnboardingDraftDecodeStatus.corrupt,
        message: 'Draft envelope is incomplete or invalid.',
      );
    }

    final firstName = _nullableString(json['firstName']);
    final goals = _stringSet(json['goalCodes']);
    final shown = _stringSet(json['shownRecommendationIds']);
    final discarded = _stringSet(json['discardedRecommendationIds']);
    final pace = OnboardingPace.fromCode(json['pace']);
    final authIntent = AuthIntent.fromCode(json['authIntent']);
    final completion = OnboardingCompletionState.fromCode(
          json['completionState'],
        ) ??
        OnboardingCompletionState.draft;
    final habit = _jsonMap(json['habit']);
    final reminder = _jsonMap(json['reminder']);
    final completedAt = _date(json['completedAt']);
    final draft = OnboardingDraft(
      draftId: draftId,
      onboardingOperationId: operationId,
      draftSchemaVersion: _positiveInt(json['draftSchemaVersion']) ??
          OnboardingVersions.draftSchemaVersion,
      onboardingVersion: _positiveInt(json['onboardingVersion']) ??
          OnboardingVersions.onboardingVersion,
      catalogVersion: _positiveInt(json['catalogVersion']) ??
          OnboardingVersions.catalogVersion,
      createdAt: createdAt,
      updatedAt: updatedAt,
      currentStep: currentStep ?? OnboardingStep.name,
      firstName: firstName,
      goalCodes: goals,
      pace: pace,
      habit: habit,
      reminder: reminder,
      shownRecommendationIds: shown,
      discardedRecommendationIds: discarded,
      selectedRecommendationId:
          _nullableString(json['selectedRecommendationId']),
      authIntent: authIntent,
      authEmail: _nullableString(json['authEmail']),
      completionState: completion,
      boundUserId: _nullableString(json['boundUserId']),
      completedAt: completedAt,
    );

    final hasRecoverableUnknown = currentStep == null ||
        (json['pace'] != null &&
            json['pace'].toString().trim().isNotEmpty &&
            pace == null) ||
        (json['authIntent'] != null &&
            json['authIntent'].toString().trim().isNotEmpty &&
            authIntent == null) ||
        (json['completionState'] != null &&
            json['completionState'].toString().trim().isNotEmpty &&
            OnboardingCompletionState.fromCode(json['completionState']) ==
                null) ||
        _hasRecoverableDataIssues(json, draft);

    return OnboardingDraftDecodeResult(
      status: hasRecoverableUnknown
          ? OnboardingDraftDecodeStatus.recoverableError
          : OnboardingDraftDecodeStatus.valid,
      draft: draft,
      message: hasRecoverableUnknown
          ? 'Draft contains data that needs safe recovery.'
          : null,
    );
  }

  bool _hasRecoverableDataIssues(
    Map<String, dynamic> json,
    OnboardingDraft draft,
  ) {
    final rawName = json['firstName'];
    if (rawName != null && rawName is! String) return true;
    if (draft.firstName != null &&
        !OnboardingDraftValidator.validateFirstName(
          draft.firstName,
          required: false,
        ).isValid) {
      return true;
    }

    final rawGoals = json['goalCodes'];
    if (rawGoals != null && rawGoals is! List) return true;
    if (rawGoals is List) {
      if (rawGoals.any((value) => value is! String)) return true;
      if (rawGoals.length != draft.goalCodes.length) return true;
      if (rawGoals.isNotEmpty &&
          !OnboardingDraftValidator.validateGoalCodes(draft.goalCodes)
              .isValid) {
        return true;
      }
    }

    if (json['habit'] != null && json['habit'] is! Map) {
      return true;
    }
    if (json['reminder'] != null && json['reminder'] is! Map) {
      return true;
    }
    if (json['boundUserId'] != null && json['boundUserId'] is! String) {
      return true;
    }
    if (json['completedAt'] != null &&
        json['completedAt'].toString().trim().isNotEmpty &&
        draft.completedAt == null) {
      return true;
    }
    return false;
  }

  void _validateEnvelope(OnboardingDraft draft) {
    if (_uuid(draft.draftId) == null ||
        _uuid(draft.onboardingOperationId) == null ||
        draft.draftId == draft.onboardingOperationId) {
      throw const FormatException('Draft IDs must be distinct UUIDs.');
    }
    if (draft.draftSchemaVersion != OnboardingVersions.draftSchemaVersion) {
      throw const FormatException('Draft schema version is not current.');
    }
  }

  static dynamic _jsonValue(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is List) return value.map(_jsonValue).toList(growable: false);
    if (value is Map) {
      return value.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), _jsonValue(value)),
      );
    }
    throw const FormatException('Draft contains a non-JSON value.');
  }

  static Map<String, dynamic>? _jsonMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    final mapped = <String, dynamic>{};
    for (final entry in value.entries) {
      mapped[entry.key.toString()] = _jsonValue(entry.value);
    }
    return mapped;
  }

  static Set<String> _stringSet(Object? value) {
    if (value is! List) return <String>{};
    return value.whereType<String>().toSet();
  }

  static String? _uuid(Object? value) {
    final normalized = _nullableString(value);
    if (normalized == null) return null;
    final regex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return regex.hasMatch(normalized) ? normalized : null;
  }

  static DateTime? _date(Object? value) {
    final raw = _nullableString(value);
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    return parsed?.toUtc();
  }

  static String? _nullableString(Object? value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static int? _positiveInt(Object? value) {
    final parsed = value is int
        ? value
        : value is num
            ? value.toInt()
            : int.tryParse((value ?? '').toString().trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }
}
