import 'package:flutter/material.dart';

import '../../../../../widgets/stats/helpers/stats_card_surface.dart';

class StatisticsOverviewSectionCard extends StatelessWidget {
  const StatisticsOverviewSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: StatsCardSurface.decoration(context),
      padding: StatsCardSurface.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          if ((subtitle ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.58),
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
