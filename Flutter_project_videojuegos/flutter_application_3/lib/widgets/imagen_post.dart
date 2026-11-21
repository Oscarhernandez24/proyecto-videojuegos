import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Imagen de portada con marcador de posición (mando de juego) si no existe o falla la carga.
class ImagenPost extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const ImagenPost({super.key, required this.url, this.fit = BoxFit.cover});

  Widget _marcador() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B3A7A), Color(0xFF0E1A38)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.sports_esports, size: 56, color: Color(0x66FFFFFF)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _marcador();
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progreso) {
        if (progreso == null) return child;
        return Container(
          color: AppColors.superficieAlta,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (context, error, stackTrace) => _marcador(),
    );
  }
}
