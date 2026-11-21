import 'package:flutter/material.dart';

/// Nota de la comunidad (0 a 5) con el aspecto de las puntuaciones de reseñas de videojuegos.
class PuntuacionBadge extends StatelessWidget {
  final double valor;
  final double tamano;

  const PuntuacionBadge({super.key, required this.valor, this.tamano = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tamano * 0.22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFB347), Color(0xFFE0700A)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x55FF9A1F), blurRadius: 12),
        ],
      ),
      child: Text(
        valor.toStringAsFixed(1),
        style: TextStyle(
          fontSize: tamano * 0.4,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF2A1600),
        ),
      ),
    );
  }
}
