import 'package:flutter/material.dart';

import '../widgets/logo_marca.dart';

import '../core/ui.dart';
import '../models/catalogo_model.dart';
import '../services/auth_service.dart';
import '../services/catalogo_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

/// RF001 – Registro de usuario (rol Lector por defecto) con géneros favoritos.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmarController = TextEditingController();

  final AuthService authService = AuthService();

  List<CatalogoItem> generos = [];
  final Set<int> generosSeleccionados = {};
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarGeneros();
  }

  Future<void> _cargarGeneros() async {
    try {
      final lista = await CatalogoService.generos.listar();
      if (mounted) setState(() => generos = lista);
    } catch (_) {
      // Si no hay conexión el registro fallará con un mensaje claro al enviarlo.
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  void _salir() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> registrarUsuario() async {
    final error = authService.validarRegistro(
      nombre: nombreController.text,
      correo: correoController.text,
      password: passwordController.text,
      confirmarpassword: confirmarController.text,
    );
    if (error != null) {
      mensaje(context, error);
      return;
    }

    setState(() => cargando = true);
    try {
      await authService.registrar(
        nombre: nombreController.text,
        correo: correoController.text,
        password: passwordController.text,
        generos: generosSeleccionados.toList(),
      );
      if (!mounted) return;
      mensaje(context, 'Registro exitoso. Ya puedes iniciar sesión');
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
                    texto: 'CREAR CUENTA',
                    subtitulo: 'Únete a la comunidad: comenta, reacciona y valora.',
                  ),
                  const SizedBox(height: 25),
                  CustomTextField(
                    controller: nombreController,
                    label: 'Nombre completo',
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: correoController,
                    label: 'Correo electrónico',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: passwordController,
                    label: 'Contraseña (8+ caracteres, letras y números)',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: confirmarController,
                    label: 'Confirmar contraseña',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  if (generos.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tus géneros favoritos (opcional)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 0,
                      children: generos
                          .map((g) => FilterChip(
                                label: Text(g.nombre),
                                selected: generosSeleccionados.contains(g.id),
                                onSelected: (v) => setState(() {
                                  v
                                      ? generosSeleccionados.add(g.id)
                                      : generosSeleccionados.remove(g.id);
                                }),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 25),
                  PrimaryButton(
                    text: cargando ? 'REGISTRANDO...' : 'REGISTRARME',
                    onPressed: cargando ? () {} : registrarUsuario,
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: cargando ? null : _salir,
                    child: const Text('Ya tengo una cuenta'),
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
