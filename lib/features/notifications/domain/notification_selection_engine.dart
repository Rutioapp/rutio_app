import 'notification_random_source.dart';
import 'notification_selection_models.dart';
import 'notification_selection_policy.dart';
import 'notification_template_content.dart';
import 'personalized_notification_models.dart';
import 'personalized_notification_ports.dart';

class NotificationSelectionEngine {
  NotificationSelectionEngine({
    required NotificationTemplateCatalog templateCatalog,
    required NotificationRandomSource randomSource,
    NotificationSelectionPolicy? policy,
  })  : _templateCatalog = templateCatalog,
        _randomSource = randomSource,
        _policy = policy ?? const NotificationSelectionPolicy();

  final NotificationTemplateCatalog _templateCatalog;
  final NotificationRandomSource _randomSource;
  final NotificationSelectionPolicy _policy;

  Future<NotificationSelectionResult> selectTemplate({
    required NotificationSelectionContext context,
    required NotificationPreferences preferences,
  }) async {
    final suppression = _policy.upfrontSuppressionReason(
      context: context,
      preferences: preferences,
    );
    if (suppression != null) {
      return NotificationSelectionResult.suppressed(
        suppressionReason: suppression,
        diagnostics: NotificationSelectionDiagnostics(
          discoveredReasons: const <String>[],
          consideredTemplateIds: const <String>[],
          eligibleTemplateIds: const <String>[],
          blockedByMissingContext: const <String>[],
          blockedByCooldown: const <String>[],
          blockedByCategoryCooldown: const <String>[],
          blockedByFrequencyLimit: const <String>[],
          usedRelaxedCategoryCooldown: false,
          usedRelaxedTemplateCooldown: false,
          usedEmergencyLastTemplateFallback: false,
        ),
      );
    }

    final templates = await _templateCatalog.listAll();
    final opportunities = _policy.discoverOpportunities(context, preferences);
    final diagnosticsBuilder = _SelectionDiagnosticsBuilder(
      discoveredReasons: opportunities
          .map((opportunity) => opportunity.reason.name)
          .toList(growable: false),
    );

    if (templates.isEmpty) {
      return NotificationSelectionResult.suppressed(
        suppressionReason:
            NotificationSelectionSuppressionReason.invalidCatalogState,
        diagnostics: diagnosticsBuilder.build(),
      );
    }

    final candidatePool = _buildCandidatePool(
      templates: templates,
      opportunities: opportunities,
      context: context,
      preferences: preferences,
      diagnosticsBuilder: diagnosticsBuilder,
    );

    if (candidatePool.isEmpty) {
      return NotificationSelectionResult.suppressed(
        suppressionReason: _policy.suppressionReasonForEmptyCatalog(
          context: context,
          opportunities: opportunities,
        ),
        diagnostics: diagnosticsBuilder.build(),
      );
    }

    final strictCandidates = _applyCooldownStage(
      candidatePool,
      context: context,
      diagnosticsBuilder: diagnosticsBuilder,
      ignoreCategoryCooldown: false,
      ignoreTemplateCooldown: false,
      allowLastTemplateFallback: false,
    );
    final selectedStrict = _pickCandidate(strictCandidates);
    if (selectedStrict != null) {
      diagnosticsBuilder.eligibleTemplateIds = strictCandidates
          .map((candidate) => candidate.template.templateId)
          .toList(growable: false);
      return NotificationSelectionResult.selected(
        selected: selectedStrict.toSelection(context),
        diagnostics: diagnosticsBuilder.build(),
      );
    }

    diagnosticsBuilder.usedRelaxedCategoryCooldown = true;
    final relaxedCategoryCandidates = _applyCooldownStage(
      candidatePool,
      context: context,
      diagnosticsBuilder: diagnosticsBuilder,
      ignoreCategoryCooldown: true,
      ignoreTemplateCooldown: false,
      allowLastTemplateFallback: false,
    );
    final selectedRelaxedCategory = _pickCandidate(relaxedCategoryCandidates);
    if (selectedRelaxedCategory != null) {
      diagnosticsBuilder.eligibleTemplateIds = relaxedCategoryCandidates
          .map((candidate) => candidate.template.templateId)
          .toList(growable: false);
      return NotificationSelectionResult.selected(
        selected: selectedRelaxedCategory.toSelection(context),
        diagnostics: diagnosticsBuilder.build(),
      );
    }

    diagnosticsBuilder.usedRelaxedTemplateCooldown = true;
    final relaxedTemplateCandidates = _applyCooldownStage(
      candidatePool,
      context: context,
      diagnosticsBuilder: diagnosticsBuilder,
      ignoreCategoryCooldown: true,
      ignoreTemplateCooldown: true,
      allowLastTemplateFallback: false,
    );
    final selectedRelaxedTemplate = _pickCandidate(relaxedTemplateCandidates);
    if (selectedRelaxedTemplate != null) {
      diagnosticsBuilder.eligibleTemplateIds = relaxedTemplateCandidates
          .map((candidate) => candidate.template.templateId)
          .toList(growable: false);
      return NotificationSelectionResult.selected(
        selected: selectedRelaxedTemplate.toSelection(context),
        diagnostics: diagnosticsBuilder.build(),
      );
    }

    diagnosticsBuilder.usedEmergencyLastTemplateFallback = true;
    final emergencyFallbackCandidates = _applyCooldownStage(
      candidatePool
          .where((candidate) => candidate.template.isFallbackCandidate),
      context: context,
      diagnosticsBuilder: diagnosticsBuilder,
      ignoreCategoryCooldown: true,
      ignoreTemplateCooldown: true,
      allowLastTemplateFallback: true,
    );
    final selectedEmergency = _pickCandidate(emergencyFallbackCandidates);
    if (selectedEmergency != null) {
      diagnosticsBuilder.eligibleTemplateIds = emergencyFallbackCandidates
          .map((candidate) => candidate.template.templateId)
          .toList(growable: false);
      return NotificationSelectionResult.selected(
        selected: selectedEmergency.toSelection(context),
        diagnostics: diagnosticsBuilder.build(),
      );
    }

    return NotificationSelectionResult.suppressed(
      suppressionReason:
          NotificationSelectionSuppressionReason.frequencyLimitReached,
      diagnostics: diagnosticsBuilder.build(),
    );
  }

  List<_TemplateSelectionCandidate> _buildCandidatePool({
    required List<NotificationTemplateDescriptor> templates,
    required List<NotificationSelectionOpportunity> opportunities,
    required NotificationSelectionContext context,
    required NotificationPreferences preferences,
    required _SelectionDiagnosticsBuilder diagnosticsBuilder,
  }) {
    final candidatesByTemplate = <String, _TemplateSelectionCandidate>{};

    for (final template in templates) {
      diagnosticsBuilder.consideredTemplateIds.add(template.templateId);
      if (!_policy.isTemplateEligible(template: template, context: context)) {
        diagnosticsBuilder.blockedByMissingContext.add(template.templateId);
        continue;
      }

      _TemplateSelectionCandidate? bestForTemplate;
      for (final opportunity in opportunities) {
        if (!template.supports(opportunity.kind) ||
            !opportunity.matchesCategory(template.category)) {
          continue;
        }

        final candidate = _TemplateSelectionCandidate(
          template: template,
          opportunity: opportunity,
          priorityScore: opportunity.priority,
          effectiveWeight: template.weight *
              _policy.contextualWeightMultiplier(
                template: template,
                opportunity: opportunity,
                context: context,
                preferences: preferences,
              ) *
              _policy.antiRepeatPenalty(
                template: template,
                context: context,
                opportunity: opportunity,
              ),
        );

        if (bestForTemplate == null ||
            candidate.effectiveWeight > bestForTemplate.effectiveWeight ||
            (candidate.effectiveWeight == bestForTemplate.effectiveWeight &&
                candidate.priorityScore > bestForTemplate.priorityScore)) {
          bestForTemplate = candidate;
        }
      }

      if (bestForTemplate != null) {
        candidatesByTemplate[template.templateId] = bestForTemplate;
      }
    }

    return candidatesByTemplate.values.toList(growable: false);
  }

  List<_TemplateSelectionCandidate> _applyCooldownStage(
    Iterable<_TemplateSelectionCandidate> candidates, {
    required NotificationSelectionContext context,
    required _SelectionDiagnosticsBuilder diagnosticsBuilder,
    required bool ignoreCategoryCooldown,
    required bool ignoreTemplateCooldown,
    required bool allowLastTemplateFallback,
  }) {
    final accepted = <_TemplateSelectionCandidate>[];
    for (final candidate in candidates) {
      final blocked = _policy.isTemplateBlockedByCooldown(
        template: candidate.template,
        context: context,
        opportunity: candidate.opportunity,
        ignoreCategoryCooldown: ignoreCategoryCooldown,
        ignoreTemplateCooldown: ignoreTemplateCooldown,
        allowLastTemplateFallback: allowLastTemplateFallback,
      );
      if (!blocked) {
        accepted.add(candidate);
        continue;
      }

      final templateId = candidate.template.templateId;
      final lastCategoryAt = context.recentMessageHistory
          .lastSelectedAtByCategoryTag[candidate.template.category.wireName];
      final lastTemplateAt =
          context.recentMessageHistory.lastSelectedAtByTemplateId[templateId];
      final usesIn7d =
          context.recentMessageHistory.recentDeliveries.where((record) {
        return record.templateId == templateId &&
            context.now.difference(record.scheduledAt) <=
                const Duration(days: 7);
      }).length;

      if (usesIn7d >= candidate.template.maxUsesPer7d) {
        diagnosticsBuilder.blockedByFrequencyLimit.add(templateId);
      } else if (!ignoreTemplateCooldown &&
          lastTemplateAt != null &&
          context.now.difference(lastTemplateAt) <
              candidate.template.cooldown) {
        diagnosticsBuilder.blockedByCooldown.add(templateId);
      } else if (!ignoreCategoryCooldown &&
          lastCategoryAt != null &&
          context.now.difference(lastCategoryAt) <
              NotificationSelectionPolicy.categoryCooldown) {
        diagnosticsBuilder.blockedByCategoryCooldown.add(templateId);
      } else {
        diagnosticsBuilder.blockedByCooldown.add(templateId);
      }
    }
    return accepted;
  }

  _TemplateSelectionCandidate? _pickCandidate(
    List<_TemplateSelectionCandidate> candidates,
  ) {
    if (candidates.isEmpty) {
      return null;
    }

    final positiveCandidates = candidates
        .where((candidate) => candidate.effectiveWeight > 0)
        .toList(growable: false)
      ..sort((a, b) {
        final byWeight = b.effectiveWeight.compareTo(a.effectiveWeight);
        if (byWeight != 0) {
          return byWeight;
        }
        return b.priorityScore.compareTo(a.priorityScore);
      });
    if (positiveCandidates.isEmpty) {
      return null;
    }

    final totalWeight = positiveCandidates.fold<double>(
      0,
      (sum, candidate) => sum + candidate.effectiveWeight,
    );
    final ticket = _randomSource.nextDouble() * totalWeight;

    var cumulative = 0.0;
    for (final candidate in positiveCandidates) {
      cumulative += candidate.effectiveWeight;
      if (ticket < cumulative) {
        return candidate;
      }
    }

    return positiveCandidates.last;
  }
}

class _TemplateSelectionCandidate {
  const _TemplateSelectionCandidate({
    required this.template,
    required this.opportunity,
    required this.priorityScore,
    required this.effectiveWeight,
  });

  final NotificationTemplateDescriptor template;
  final NotificationSelectionOpportunity opportunity;
  final double priorityScore;
  final double effectiveWeight;

  SelectedNotificationTemplate toSelection(
    NotificationSelectionContext context,
  ) {
    return SelectedNotificationTemplate(
      template: template,
      kind: opportunity.kind,
      category: template.category,
      reason: opportunity.reason,
      priorityScore: priorityScore,
      effectiveWeight: effectiveWeight,
      renderContext: context.toRenderContext(),
      opportunity: opportunity,
    );
  }
}

class _SelectionDiagnosticsBuilder {
  _SelectionDiagnosticsBuilder({
    required this.discoveredReasons,
  });

  final List<String> discoveredReasons;
  final List<String> consideredTemplateIds = <String>[];
  List<String> eligibleTemplateIds = <String>[];
  final List<String> blockedByMissingContext = <String>[];
  final List<String> blockedByCooldown = <String>[];
  final List<String> blockedByCategoryCooldown = <String>[];
  final List<String> blockedByFrequencyLimit = <String>[];
  bool usedRelaxedCategoryCooldown = false;
  bool usedRelaxedTemplateCooldown = false;
  bool usedEmergencyLastTemplateFallback = false;

  NotificationSelectionDiagnostics build() {
    return NotificationSelectionDiagnostics(
      discoveredReasons: discoveredReasons,
      consideredTemplateIds:
          consideredTemplateIds.toSet().toList(growable: false),
      eligibleTemplateIds: eligibleTemplateIds.toSet().toList(growable: false),
      blockedByMissingContext:
          blockedByMissingContext.toSet().toList(growable: false),
      blockedByCooldown: blockedByCooldown.toSet().toList(growable: false),
      blockedByCategoryCooldown:
          blockedByCategoryCooldown.toSet().toList(growable: false),
      blockedByFrequencyLimit:
          blockedByFrequencyLimit.toSet().toList(growable: false),
      usedRelaxedCategoryCooldown: usedRelaxedCategoryCooldown,
      usedRelaxedTemplateCooldown: usedRelaxedTemplateCooldown,
      usedEmergencyLastTemplateFallback: usedEmergencyLastTemplateFallback,
    );
  }
}
