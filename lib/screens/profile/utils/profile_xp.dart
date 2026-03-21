import '../models/family_level.dart';

/// Reglas de XP alineadas con UserStateStore:
/// - Hábito tipo 'check' completado: 10 XP
/// - Hábito tipo 'count' completado: XP fija según objetivo (cap 5..15)
int xpForCheckCompletion() => 10;

/// Misma fórmula que en UserStateStore:
/// int _xpForCountCompletion(num target) => ((target / 5).ceil() * 2 + 5).clamp(5, 15);
int xpForCountCompletion(num target) =>
    (((target / 5).ceil() * 2) + 5).clamp(5, 15);

/// Progresión alineada con UserStateStore:
/// level = 1 + (xp ~/ 100)
/// xpToNext = 100 - (xp % 100)
LevelData levelFromXp(int xp) {
  final safeXp = xp < 0 ? 0 : xp;
  final level = 1 + (safeXp ~/ 100);
  final into = safeXp % 100;
  final xpToNext = 100 - into;
  return LevelData(level: level, xpToNext: xpToNext);
}

/// Progreso dentro del nivel actual (0..1) para progress bars.
double normalizedProgressWithinLevel({required int xp}) {
  final safeXp = xp < 0 ? 0 : xp;
  return (safeXp % 100) / 100.0;
}

/// Valor 0..1 "global" para el radar:
/// combina nivel + progreso y lo normaliza a un máximo.
/// Ajusta maxLevel según tu UI (10 por defecto).
double normalizedRadarValue({
  required int xp,
  required LevelData levelData,
  int maxLevel = 10,
}) {
  final safeXp = xp < 0 ? 0 : xp;
  final level = levelData.level;
  final local = normalizedProgressWithinLevel(xp: safeXp);
  final global = (level - 1) + local;
  final denom = maxLevel <= 1 ? 1.0 : maxLevel.toDouble();
  final v = global / denom;
  if (v.isNaN) return 0.0;
  return v.clamp(0.0, 1.0);
}
