import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Fondo de las pantallas de acceso: noche azul con cuadrícula de "pixel art"
/// y destellos de color, como un menú de inicio de videojuego.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF123068), AppColors.fondo, Color(0xFF060B18)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        // Destello azul arriba a la izquierda
        const Positioned(
          left: -120,
          top: -120,
          child: _Destello(color: Color(0x552E8BFF), diametro: 420),
        ),
        // Destello naranja abajo a la derecha
        const Positioned(
          right: -140,
          bottom: -140,
          child: _Destello(color: Color(0x33FF9A1F), diametro: 460),
        ),
        Positioned.fill(child: CustomPaint(painter: _CuadriculaPainter())),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Destello extends StatelessWidget {
  final Color color;
  final double diametro;

  const _Destello({required this.color, required this.diametro});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diametro,
        height: diametro,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, const Color(0x00000000)]),
        ),
      ),
    );
  }
}

class _CuadriculaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linea = Paint()
      ..color = const Color(0x0F8FB6FF)
      ..strokeWidth = 1;
    const paso = 44.0;
    for (double x = 0; x < size.width; x += paso) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linea);
    }
    for (double y = 0; y < size.height; y += paso) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linea);
    }

    // "Píxeles" sueltos, como estrellas de un juego retro.
    final pixel = Paint()..color = const Color(0x55BFD9FF);
    const puntos = [
      [0.12, 0.18], [0.82, 0.12], [0.68, 0.34], [0.22, 0.62],
      [0.9, 0.7], [0.45, 0.86], [0.06, 0.88], [0.58, 0.08],
    ];
    for (final p in puntos) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * p[0], size.height * p[1], 4, 4),
        pixel,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
