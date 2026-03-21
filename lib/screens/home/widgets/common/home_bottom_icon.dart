/// HomeBottomIcon dibuja un botón secundario de acción en la zona inferior.
///
/// Se usa como pieza visual reutilizable: icono, texto y tap handler con un
/// estilo suave que encaja con el look iOS/cálido de la Home.
library;

import 'package:flutter/material.dart';

class HomeBottomIcon extends StatelessWidget {
  const HomeBottomIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black.withValues(alpha: 0.65)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
