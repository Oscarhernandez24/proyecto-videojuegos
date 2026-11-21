import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Etiqueta pequeña sobre imágenes o titulares. [destacada] = naranja (categoría).
class PostTag extends StatelessWidget {
  final String texto;
  final bool destacada;

  const PostTag({super.key, required this.texto, this.destacada = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: destacada ? AppColors.naranja : const Color(0x99000000),
        borderRadius: BorderRadius.circular(5),
        border: destacada ? null : Border.all(color: const Color(0x55FFFFFF)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: destacada ? const Color(0xFF2A1600) : Colors.white,
        ),
      ),
    );
  }
}
