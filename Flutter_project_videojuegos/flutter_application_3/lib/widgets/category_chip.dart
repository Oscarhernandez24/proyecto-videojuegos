import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Etiqueta seleccionable (filtro de género).
class CategoryChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.azul : AppColors.superficieAlta,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.azul : AppColors.borde,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textoSuave,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
