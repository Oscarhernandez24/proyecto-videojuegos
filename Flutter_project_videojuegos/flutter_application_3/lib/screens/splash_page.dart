import 'package:flutter/material.dart';

import '../widgets/logo_marca.dart';

import '../core/session.dart';
import '../services/auth_service.dart';
import '../widgets/auth_background.dart';

/// Pantalla inicial: restaura la sesión guardada (si existe y sigue vigente).
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    await Session.cargar();
    final haySesion = await AuthService().restaurarSesion();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, haySesion ? '/blog' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AuthBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LogoMarca(tamano: 84),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
