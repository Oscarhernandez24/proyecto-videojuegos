import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Estrellas de valoración. Si [onChanged] es null solo se muestran (modo lectura).
class RatingStars extends StatelessWidget {
  final double valor;
  final double tamano;
  final ValueChanged<int>? onChanged;

  const RatingStars({
    super.key,
    required this.valor,
    this.tamano = 28,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final posicion = i + 1;
        final IconData icono;
        if (valor >= posicion) {
          icono = Icons.star_rounded;
        } else if (valor >= posicion - 0.5) {
          icono = Icons.star_half_rounded;
        } else {
          icono = Icons.star_outline_rounded;
        }
        final estrella = Icon(
          icono,
          size: tamano,
          color: valor >= posicion - 0.5 ? AppColors.naranja : AppColors.borde,
        );
        if (onChanged == null) return estrella;
        return GestureDetector(
          onTap: () => onChanged!(posicion),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: estrella,
            ),
          ),
        );
      }),
    );
  }
}
