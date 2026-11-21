import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Escudo naranja con un mando de videojuegos, inspirado en los emblemas de clanes gamer.
class _EscudoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final camino = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.12)
      ..lineTo(w, h * 0.55)
      ..quadraticBezierTo(w, h * 0.86, w * 0.5, h)
      ..quadraticBezierTo(0, h * 0.86, 0, h * 0.55)
      ..lineTo(0, h * 0.12)
      ..close();

    canvas.drawShadow(camino, const Color(0xFFFF9A1F), 8, false);
    canvas.drawPath(
      camino,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.naranja, AppColors.naranjaOscuro],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      camino,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..color = const Color(0xFFFFD18A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LogoMarca extends StatelessWidget {
  final double tamano;

  /// Si es true muestra también el nombre del blog junto al escudo.
  final bool conTexto;

  const LogoMarca({super.key, this.tamano = 44, this.conTexto = false});

  @override
  Widget build(BuildContext context) {
    final escudo = SizedBox(
      width: tamano,
      height: tamano * 1.12,
      child: CustomPaint(
        painter: _EscudoPainter(),
        child: Padding(
          padding: EdgeInsets.only(bottom: tamano * 0.1),
          child: Center(
            child: Icon(
              Icons.sports_esports,
              size: tamano * 0.58,
              color: const Color(0xFF2A1600),
            ),
          ),
        ),
      ),
    );

    if (!conTexto) return escudo;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        escudo,
        SizedBox(width: tamano * 0.3),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BLOG DE',
              style: TextStyle(
                fontSize: tamano * 0.26,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: AppColors.textoSuave,
              ),
            ),
            Text(
              'VIDEOJUEGOS',
              style: TextStyle(
                fontSize: tamano * 0.42,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                height: 1.05,
                color: AppColors.texto,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
