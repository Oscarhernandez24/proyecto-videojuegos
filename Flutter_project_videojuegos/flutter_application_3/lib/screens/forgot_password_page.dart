import 'package:flutter/material.dart';

import '../widgets/logo_marca.dart';

import '../core/ui.dart';
import '../services/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

/// Recuperación de contraseña en dos pasos: solicitar código y establecer la nueva contraseña.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmarController = TextEditingController();
  final AuthService authService = AuthService();

  bool codigoEnviado = false;
  bool cargando = false;
  String? codigoDev;

  @override
  void dispose() {
    correoController.dispose();
    codigoController.dispose();
    passwordController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  Future<void> solicitarCodigo() async {
    final correo = correoController.text.trim();
    if (!correo.contains('@')) {
      mensaje(context, 'Ingresa tu correo registrado');
      return;
    }
    setState(() => cargando = true);
    try {
      final respuesta = await authService.solicitarCodigo(correo);
      if (!mounted) return;
      setState(() {
        codigoEnviado = true;
        codigoDev = respuesta['codigo_dev']?.toString();
      });
      mensaje(context, respuesta['mensaje']?.toString() ?? 'Código enviado');
    } catch (e) {
      if (mounted) mensaje(context, textoError(e));
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> restablecer() async {
    if (codigoController.text.trim().isEmpty) {
      mensaje(context, 'Ingresa el código de verificación');
      return;
    }
    final errorPassword = authService.validarPassword(passwordController.text);
    if (errorPassword != null) {
      mensaje(context, errorPassword);
      return;
    }
    if (passwordController.text != confirmarController.text) {
      mensaje(context, 'Las contraseñas no coinciden');
      return;
    }
    setState(() => cargando = true);
    try {
      await authService.restablecerPassword(
        correo: correoController.text,
        codigo: codigoController.text,
        nuevaPassword: passwordController.text,
      );
      if (!mounted) return;
      mensaje(context, 'Contraseña actualizada. Ya puedes iniciar sesión');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (mounted) mensaje(context, textoError(e));
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: AuthCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LogoMarca(tamano: 52),
                  const SizedBox(height: 16),
                  const AuthTitulo(
                    texto: 'RECUPERAR CONTRASEÑA',
                    subtitulo: 'Te enviaremos un código para crear una nueva.',
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: correoController,
                    label: 'Correo electrónico',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),
                  if (!codigoEnviado)
                    PrimaryButton(
                      text: cargando ? 'ENVIANDO...' : 'ENVIAR CÓDIGO',
                      onPressed: cargando ? () {} : solicitarCodigo,
                    )
                  else ...[
                    if (codigoDev != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0x26FF9A1F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Modo desarrollo: tu código es $codigoDev',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    CustomTextField(
                      controller: codigoController,
                      label: 'Código de verificación',
                      prefixIcon: Icons.pin,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: passwordController,
                      label: 'Nueva contraseña',
                      prefixIcon: Icons.lock,
                      obscureText: true,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: confirmarController,
                      label: 'Confirmar nueva contraseña',
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: cargando ? 'GUARDANDO...' : 'CAMBIAR CONTRASEÑA',
                      onPressed: cargando ? () {} : restablecer,
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver al inicio de sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
