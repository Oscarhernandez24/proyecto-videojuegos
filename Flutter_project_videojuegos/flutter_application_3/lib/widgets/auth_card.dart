import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Panel central de acceso: superficie oscura con borde y resplandor azul.
class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xEE111C36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x662E8BFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332E8BFF),
            blurRadius: 40,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SizedBox(width: 360, child: child),
      ),
    );
  }
}

/// Título de pantalla de acceso (mismo estilo en login, registro y recuperación).
class AuthTitulo extends StatelessWidget {
  final String texto;
  final String? subtitulo;

  const AuthTitulo({super.key, required this.texto, this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          texto,
          textAlign: TextAlign.center,
          style: AppText.titular(24),
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitulo!,
            textAlign: TextAlign.center,
            style: AppText.meta,
          ),
        ],
      ],
    );
  }
}
