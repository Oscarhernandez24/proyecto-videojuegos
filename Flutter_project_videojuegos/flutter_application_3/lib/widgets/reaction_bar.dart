import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/interaccion_service.dart';

/// Barra de reacciones con emojis y contador por cada una.
class ReactionBar extends StatelessWidget {
  final Map<String, int> conteos;
  final String? miReaccion;
  final ValueChanged<String> onTap;

  const ReactionBar({
    super.key,
    required this.conteos,
    required this.miReaccion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: InteraccionService.reacciones.map((emoji) {
        final total = conteos[emoji] ?? 0;
        final activa = miReaccion == emoji;
        return GestureDetector(
          onTap: () => onTap(emoji),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: activa ? const Color(0x332E8BFF) : AppColors.superficieAlta,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activa ? AppColors.azul : AppColors.borde,
                  width: activa ? 1.6 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  if (total > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '$total',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: activa ? AppColors.azul : AppColors.textoSuave,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
