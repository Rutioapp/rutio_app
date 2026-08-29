import '../../domain/feedback_category.dart';
import '../../domain/feedback_report.dart';
import '../../domain/feedback_status.dart';

class FeedbackMockReports {
  FeedbackMockReports._();

  static final List<FeedbackReport> examples = <FeedbackReport>[
    FeedbackReport(
      id: 'feedback-2026-08-29-1',
      userId: 'rutio-user-001',
      category: FeedbackCategory.bug,
      description:
          'La pantalla de hábitos se queda corta en el iPhone pequeño y el botón de guardar desaparece al abrir el teclado.',
      screenshotPath: null,
      contactAllowed: true,
      status: FeedbackStatus.submitted,
      teamResponse: null,
      createdAt: DateTime(2026, 8, 29, 9, 20),
    ),
    FeedbackReport(
      id: 'feedback-2026-08-27-2',
      userId: 'rutio-user-001',
      category: FeedbackCategory.improvement,
      description:
          'Me gustaría poder guardar borradores del feedback para terminarlo después con más calma.',
      screenshotPath: 'mock://feedback/screenshots/draft-layout.png',
      contactAllowed: false,
      status: FeedbackStatus.inReview,
      teamResponse: null,
      createdAt: DateTime(2026, 8, 27, 18, 45),
      reviewStartedAt: DateTime(2026, 8, 28, 10, 5),
    ),
    FeedbackReport(
      id: 'feedback-2026-08-25-3',
      userId: 'rutio-user-001',
      category: FeedbackCategory.suggestion,
      description:
          'Sería útil tener un resumen visual del progreso antes de entrar al detalle para revisar más rápido.',
      screenshotPath: 'mock://feedback/screenshots/progress-layout.png',
      contactAllowed: true,
      status: FeedbackStatus.resolved,
      teamResponse:
          'Gracias por la sugerencia. Hemos mejorado la visibilidad del resumen en el flujo de Feedback.',
      createdAt: DateTime(2026, 8, 25, 12, 10),
      reviewStartedAt: DateTime(2026, 8, 26, 8, 30),
      closedAt: DateTime(2026, 8, 28, 15, 40),
    ),
    FeedbackReport(
      id: 'feedback-2026-08-22-4',
      userId: 'rutio-user-001',
      category: FeedbackCategory.other,
      description:
          'Solo quería dejar constancia de que el nuevo flujo de soporte visual se entiende mucho mejor.',
      screenshotPath: null,
      contactAllowed: false,
      status: FeedbackStatus.dismissed,
      teamResponse:
          'Gracias por escribirnos. Este caso no requiere más seguimiento por ahora.',
      createdAt: DateTime(2026, 8, 22, 19, 5),
      reviewStartedAt: DateTime(2026, 8, 23, 11, 0),
      closedAt: DateTime(2026, 8, 24, 17, 15),
    ),
  ];

  static FeedbackReport get fallbackSubmittedReport => examples.first;

  static FeedbackReport get fallbackDetailReport =>
      examples.firstWhere((report) => report.status == FeedbackStatus.resolved);

  static List<FeedbackReport> mineReports({
    FeedbackReport? submittedReport,
  }) {
    final reports = <FeedbackReport>[
      if (submittedReport != null) submittedReport,
      ...examples,
    ];

    final deduplicated = <String, FeedbackReport>{};
    for (final report in reports) {
      deduplicated[report.id] = report;
    }

    final sorted = deduplicated.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  static FeedbackReport buildSubmittedReport({
    required FeedbackCategory category,
    required String description,
    required bool contactAllowed,
    String? screenshotPath,
    String? userId,
  }) {
    final createdAt = DateTime.now();

    return FeedbackReport(
      id: 'feedback-local-${createdAt.microsecondsSinceEpoch}',
      userId: userId,
      category: category,
      description: description,
      screenshotPath: screenshotPath,
      contactAllowed: contactAllowed,
      status: FeedbackStatus.submitted,
      teamResponse: null,
      createdAt: createdAt,
    );
  }
}
