import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Vista de error con botón para reintentar (sin conexión, servidor caído, etc.).
class ErrorVista extends StatelessWidget {
  final String texto;
  final VoidCallback onReintentar;

  const ErrorVista({
    super.key,
    required this.texto,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.naranja),
            const SizedBox(height: 14),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('REINTENTAR'),
            ),
          ],
        ),
      ),
    );
  }
}
