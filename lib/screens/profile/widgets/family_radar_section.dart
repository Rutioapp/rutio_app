import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../models/family_color_ref.dart';
import '../models/family_level.dart';
import '../models/radar_datum.dart';
import '../painters/radar_painter.dart';
import '../utils/profile_xp.dart';
import 'progress_bar.dart';
import 'section_card.dart';

class FamilyRadarSection extends StatelessWidget {
  final Color accent;
  final List<FamilyLevel> familyLevels;
  final Map<String, Color>? familyColors;
  final Color Function(FamilyColorRef ref)? familyColorResolver;

  const FamilyRadarSection({
    super.key,
    required this.accent,
    required this.familyLevels,
    required this.familyColors,
    this.familyColorResolver,
  });

  String _norm(String? s) {
    final t = (s ?? '').trim().toLowerCase();
    return t
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ñ', 'n');
  }

  int _familyRank(FamilyLevel f) {
    final id = _norm(f.id);
    final name = _norm(f.name);
    bool has(String token) => id.contains(token) || name.contains(token);
    if (has('ment') || has('mind')) return 0;
    if (has('disc')) return 1;
    if (has('espirit') || has('spirit')) return 2;
    if (has('profes') || has('professional') || has('work')) return 3;
    if (has('cuerp') || has('body') || has('fit')) return 4;
    if (has('emoc') || has('emotion')) return 5;
    if (has('soci') || has('social')) return 6;
    return 999;
  }

  Color _familyColor(String id, {String? name}) {
    final map = familyColors;
    if (map != null && map.isNotEmpty) {
      final candidates = <String>[
        id,
        id.toLowerCase(),
        _norm(id),
        if (name != null) name,
        if (name != null) name.toLowerCase(),
        if (name != null) _norm(name),
        if (name != null) _familyTitle(id, name: name),
        if (name != null) _norm(_familyTitle(id, name: name)),
      ];
      for (final k in candidates) {
        final c = map[k];
        if (c != null) return c;
      }
      final nid = _norm(id);
      final nname = _norm(name);
      for (final entry in map.entries) {
        final nk = _norm(entry.key);
        if (nk == nid || nk == nname) return entry.value;
      }
      for (final entry in map.entries) {
        final nk = _norm(entry.key);
        if (nid.isNotEmpty && nk.contains(nid)) return entry.value;
        if (nname.isNotEmpty && nk.contains(nname)) return entry.value;
      }
    }

    if (familyColorResolver != null) {
      try {
        return familyColorResolver!(
          FamilyColorRef(
            familyId: id,
            familyName: name,
            data: {
              'familyId': id,
              'family': id,
              'id': id,
              'name': name,
              'title': name,
              'label': name,
            },
          ),
        );
      } catch (_) {}
    }

    return accent;
  }

  String _familyTitle(String id, {String? name}) {
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final t = id.replaceAll('_', ' ').trim();
    if (t.isEmpty) return id;
    return t[0].toUpperCase() + t.substring(1);
  }

  Widget _radarWithLabels(
    BuildContext context,
    List<FamilyLevel> ordered,
    List<RadarDatum> data,
  ) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        const labelW = 100.0;
        const labelH = 46.0;
        const labelGap = 24.0;

        final sidePadH = labelGap + labelW / 2 + 4;
        final sidePadV = labelGap + labelH / 2 + 4;
        final radarSize =
            (constraints.maxWidth - sidePadH * 2).clamp(80.0, 220.0);
        final canvasW = radarSize + sidePadH * 2;
        final canvasH = radarSize + sidePadV * 2;

        final center = Offset(canvasW / 2, canvasH / 2);
        final labelRadius = radarSize / 2 + labelGap;
        const startAngle = -math.pi / 2;

        return SizedBox(
          width: canvasW,
          height: canvasH,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: sidePadH,
                top: sidePadV,
                width: radarSize,
                height: radarSize,
                child: CustomPaint(
                  painter: RadarPainter(
                    data: data,
                    gridColor: const Color(0xFFEAEAEA),
                    borderColor: accent,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              for (int i = 0; i < ordered.length; i++)
                _vertexLabel(
                  center: center,
                  angle: startAngle + (2 * math.pi * i / ordered.length),
                  radius: labelRadius,
                  title: _familyTitle(ordered[i].id, name: ordered[i].name),
                  levelLabel:
                      context.l10n.profileFamilyLevelShort(ordered[i].level),
                  w: labelW,
                  h: labelH,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _vertexLabel({
    required Offset center,
    required double angle,
    required double radius,
    required String title,
    required String levelLabel,
    required double w,
    required double h,
  }) {
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);

    return Positioned(
      left: x - w / 2,
      top: y - h / 2,
      width: w,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                levelLabel,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordered = [...familyLevels]..sort((a, b) {
        final ra = _familyRank(a);
        final rb = _familyRank(b);
        if (ra != rb) return ra.compareTo(rb);
        return _familyTitle(a.id, name: a.name)
            .compareTo(_familyTitle(b.id, name: b.name));
      });

    final data = ordered.map((f) {
      final ld = LevelData(level: f.level, xpToNext: f.xpToNext);
      final v = normalizedRadarValue(xp: f.xp, levelData: ld);
      return RadarDatum(
        label: f.name,
        value: v,
        color: _familyColor(f.id, name: f.name),
      );
    }).toList();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.profileFamiliesProgressTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Center(child: _radarWithLabels(context, ordered, data)),
          const SizedBox(height: 16),
          ...ordered.map((f) {
            final ld = LevelData(level: f.level, xpToNext: f.xpToNext);
            final v = normalizedRadarValue(xp: f.xp, levelData: ld);
            final col = _familyColor(f.id, name: f.name);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: col,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _familyTitle(f.id, name: f.name),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              context.l10n.profileFamilyLevelLabel(f.level),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF7A7A7A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ProgressBar(value: v, color: col),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
