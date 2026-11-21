import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/session.dart';
import '../core/ui.dart';
import '../services/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/logo_marca.dart';
import '../widgets/primary_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();

  bool ocultarPassword = true;
  bool cargando = false;

  @override
  void dispose() {
    usuarioController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
    final error = authService.validarLogin(
      usuario: usuarioController.text,
      password: passwordController.text,
    );
    if (error != null) {
      mensaje(context, error);
      return;
    }

    setState(() => cargando = true);
    try {
      await authService.iniciarSesion(
        correo: usuarioController.text,
        password: passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/blog', (route) => false);
    } catch (e) {
      if (mounted) mensaje(context, textoError(e));
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  /// Un invitado puede consultar el feed y los comentarios, pero no publicar ni reaccionar.
  Future<void> entrarComoInvitado() async {
    await Session.limpiar();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/blog', (route) => false);
  }

  /// Panel de bienvenida que se muestra a la izquierda en pantallas anchas.
  Widget _panelBienvenida() {
    Widget punto(IconData icono, String titulo, String texto) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x262E8BFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x552E8BFF)),
              ),
              child: Icon(icono, color: AppColors.azul, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(texto, style: AppText.meta),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const LogoMarca(tamano: 64, conTexto: true),
          const SizedBox(height: 36),
          Text('TU PRÓXIMA\nPARTIDA EMPIEZA\nAQUÍ', style: AppText.titular(40)),
          const SizedBox(height: 14),
          const Text(
            'Reseñas, noticias de lanzamientos y guías escritas por la comunidad.',
            style: TextStyle(fontSize: 16, height: 1.5, color: AppColors.textoSuave),
          ),
          const SizedBox(height: 32),
          punto(Icons.rate_review_outlined, 'Reseñas y guías',
              'Valora cada publicación de 1 a 5 estrellas.'),
          punto(Icons.forum_outlined, 'Comunidad',
              'Comenta, responde y reacciona con emojis.'),
          punto(Icons.category_outlined, 'Tus géneros',
              'Filtra el contenido por los juegos que te gustan.'),
        ],
      ),
    );
  }

  Widget _formulario() {
    return AuthCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LogoMarca(tamano: 60),
          const SizedBox(height: 18),
          const AuthTitulo(
            texto: 'INICIAR SESIÓN',
            subtitulo: 'Entra para publicar, comentar y valorar.',
          ),
          const SizedBox(height: 26),
          CustomTextField(
            controller: usuarioController,
            label: 'Correo electrónico',
            prefixIcon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: passwordController,
            label: 'Contraseña',
            prefixIcon: Icons.lock_outline,
            obscureText: ocultarPassword,
            suffixIcon: IconButton(
              icon: Icon(ocultarPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () => setState(() => ocultarPassword = !ocultarPassword),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: 4),
          PrimaryButton(
            text: cargando ? 'VALIDANDO...' : 'INGRESAR',
            onPressed: cargando ? () {} : iniciarSesion,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: cargando ? null : entrarComoInvitado,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Continuar como invitado'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('¿No tienes cuenta?',
                  style: TextStyle(color: AppColors.textoSuave)),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Registrarse'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: LayoutBuilder(
          builder: (context, caja) {
            final ancha = caja.maxWidth >= 1060;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: ancha
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _panelBienvenida(),
                          const SizedBox(width: 72),
                          _formulario(),
                        ],
                      )
                    : _formulario(),
              ),
            );
          },
        ),
      ),
    );
  }
}
