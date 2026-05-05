import 'package:flutter/material.dart';

import '../../../../../widgets/stats/helpers/stats_card_surface.dart';
import '../statistics_v2_tokens.dart';

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
            style: StatisticsV2Tokens.title.copyWith(fontSize: 16),
          ),
          if ((subtitle ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: StatisticsV2Tokens.subtitle,
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
