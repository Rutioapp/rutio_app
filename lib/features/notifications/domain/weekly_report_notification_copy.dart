class WeeklyReportNotificationCopy {
  const WeeklyReportNotificationCopy._();

  static String title(String locale) => locale.toLowerCase().startsWith('en')
      ? 'Review your week'
      : 'Revisa tu semana';

  static String body(String locale) => locale.toLowerCase().startsWith('en')
      ? 'Your weekly report shows what worked and where you can adjust.'
      : 'Tu reporte semanal te ayuda a ver qué funcionó y dónde ajustar.';
}
