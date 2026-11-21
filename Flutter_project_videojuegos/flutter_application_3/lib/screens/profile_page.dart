import 'package:flutter/material.dart';

import '../config/app_theme.dart';

import '../core/session.dart';
import '../core/ui.dart';
import '../models/catalogo_model.dart';
import '../services/auth_service.dart';
import '../services/catalogo_service.dart';
import '../services/user_service.dart';
import '../widgets/app_drawer.dart';

/// Perfil del usuario: datos personales, géneros favoritos y cambio de contraseña.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _servicio = UserService();
  final _auth = AuthService();

  late final TextEditingController _nombre =
      TextEditingController(text: Session.nombre);
  late final TextEditingController _correo =
      TextEditingController(text: Session.correo);
  late final TextEditingController _direccion =
      TextEditingController(text: Session.usuario['dir_usr']?.toString() ?? '');
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();

  List<CatalogoItem> _generos = [];
  final Set<int> _generosSel = {};
  bool _guardando = false;
  bool _cambiandoPassword = false;

  @override
  void initState() {
    super.initState();
    final guardados = Session.usuario['generos'];
    if (guardados is List) {
      for (final g in guardados) {
        _generosSel.add((g['id'] as num).toInt());
      }
    }
    _cargarGeneros();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _direccion.dispose();
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _cargarGeneros() async {
    try {
      final lista = await CatalogoService.generos.listar();
      if (!mounted) return;
      setState(() {
        _generos = lista;
        // Quita preferencias de géneros que ya no están activos.
        _generosSel.removeWhere((id) => !lista.any((g) => g.id == id));
      });
    } catch (_) {}
  }

  Future<void> _guardarPerfil() async {
    final nombre = _nombre.text.trim();
    final correo = _correo.text.trim();
    if (nombre.length < 2 || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
      mensaje(context, 'Ingresa un nombre y un correo válidos');
      return;
    }
    setState(() => _guardando = true);
    try {
      await _servicio.actualizarPerfil(
        nombre: nombre,
        correo: correo,
        direccion: _direccion.text,
        generos: _generosSel.toList(),
      );
      if (mounted) {
        setState(() {});
        mensaje(context, 'Perfil actualizado correctamente');
      }
    } catch (e) {
      if (mounted) mensaje(context, textoError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _cambiarPassword() async {
    final error = _auth.validarPassword(_nueva.text);
    if (_actual.text.isEmpty) {
      mensaje(context, 'Ingresa tu contraseña actual');
      return;
    }
    if (error != null) {
      mensaje(context, error);
      return;
    }
    if (_nueva.text != _confirmar.text) {
      mensaje(context, 'Las contraseñas no coinciden');
      return;
    }
    setState(() => _cambiandoPassword = true);
    try {
      await _servicio.cambiarPassword(_actual.text, _nueva.text);
      if (!mounted) return;
      _actual.clear();
      _nueva.clear();
      _confirmar.clear();
      mensaje(context, 'Contraseña actualizada correctamente');
    } catch (e) {
      if (mounted) mensaje(context, textoError(e));
    } finally {
      if (mounted) setState(() => _cambiandoPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.logueado) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi perfil')),
        drawer: const AppDrawer(rutaActual: '/profile'),
        body: const Center(child: Text('Inicia sesión para ver tu perfil.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      drawer: const AppDrawer(rutaActual: '/profile'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.colorRol(Session.rol),
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.superficieAlta,
                              child: Text(
                                Session.nombre.isNotEmpty
                                    ? Session.nombre[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(Session.nombre,
                                    style: Theme.of(context).textTheme.titleLarge),
                                Chip(
                                  label: Text(
                                    Session.nombreRol(Session.rol).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                      color: AppColors.colorRol(Session.rol),
                                    ),
                                  ),
                                  backgroundColor:
                                      AppColors.colorRol(Session.rol).withAlpha(40),
                                  side: BorderSide(color: AppColors.colorRol(Session.rol)),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nombre,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _correo,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _direccion,
                        decoration: const InputDecoration(
                          labelText: 'Dirección (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_generos.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Géneros favoritos',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: _generos
                              .map((g) => FilterChip(
                                    label: Text(g.nombre),
                                    selected: _generosSel.contains(g.id),
                                    onSelected: (v) => setState(() {
                                      v ? _generosSel.add(g.id) : _generosSel.remove(g.id);
                                    }),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardarPerfil,
                        icon: const Icon(Icons.save),
                        label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Cambiar contraseña',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _actual,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña actual',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nueva,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nueva contraseña',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmar,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar nueva contraseña',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _cambiandoPassword ? null : _cambiarPassword,
                        icon: const Icon(Icons.lock_reset),
                        label: Text(_cambiandoPassword
                            ? 'Actualizando...'
                            : 'Actualizar contraseña'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
