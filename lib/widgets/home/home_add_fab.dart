import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';

class HomeAddFab extends StatelessWidget {
  const HomeAddFab({
    super.key,
    required this.onPressed,
    this.heroTag = 'home_add_fab',
    this.tooltip,
  });

  final VoidCallback onPressed;
  final Object heroTag;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      tooltip: tooltip ?? context.l10n.homeAddFabTooltip,
      onPressed: onPressed,
      child: const Icon(Icons.add),
    );
  }
}
