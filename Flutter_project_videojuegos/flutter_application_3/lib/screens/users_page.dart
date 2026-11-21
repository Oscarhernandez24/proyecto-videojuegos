import 'package:flutter/material.dart';

import '../config/app_theme.dart';

import '../core/session.dart';
import '../core/ui.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/error_vista.dart';

/// Panel del administrador: alta, edición de datos/rol y baja lógica de usuarios.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final UserService _servicio = UserService();
  late Future<List<UserModel>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.obtenerUsuarios();
  }

  void _recargar() {
    setState(() {
      _futuro = _servicio.obtenerUsuarios();
    });
  }

  Future<void> _formulario({UserModel? usuario}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _UsuarioDialog(usuario: usuario, servicio: _servicio),
    );
    if (ok == true && mounted) {
      mensaje(context, usuario == null
          ? 'Usuario creado correctamente'
          : 'Usuario actualizado correctamente');
      _recargar();
    }
  }

  Future<void> _cambiarEstatus(UserModel u) async {
    final desactivar = u.activo;
    final ok = await confirmar(
      context,
      titulo: desactivar ? 'Desactivar usuario' : 'Activar usuario',
      texto: desactivar
          ? '${u.nombre} ya no podrá iniciar sesión. Sus publicaciones se conservan.'
          : '${u.nombre} podrá volver a iniciar sesión.',
      botonAceptar: desactivar ? 'Desactivar' : 'Activar',
    );
    if (!ok) return;
    try {
      await _servicio.actualizarUsuario(UserModel(
        id: u.id,
        nombre: u.nombre,
        correo: u.correo,
        direccion: u.direccion,
        tipoUsuario: u.tipoUsuario,
        activo: !u.activo,
      ));
      if (!mounted) return;
      mensaje(context, desactivar ? 'Usuario desactivado' : 'Usuario activado');
      _recargar();
    } catch (e) {
      if (mounted) mensaje(context, textoError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de usuarios')),
        drawer: const AppDrawer(rutaActual: '/users'),
        body: const Center(child: Text('Solo el administrador puede ver esta sección.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de usuarios'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _recargar,
          ),
        ],
      ),
      drawer: const AppDrawer(rutaActual: '/users'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formulario(),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo usuario'),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorVista(
              texto: textoError(snapshot.error!),
              onReintentar: _recargar,
            );
          }
          final usuarios = snapshot.data ?? [];
          if (usuarios.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: usuarios.length,
            itemBuilder: (context, i) {
              final u = usuarios[i];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.colorRol(u.tipoUsuario).withAlpha(50),
                        foregroundColor: AppColors.colorRol(u.tipoUsuario),
                        child: Icon(u.tipoUsuario == Session.rolAdmin
                            ? Icons.admin_panel_settings
                            : Icons.person),
                      ),
                      title: Text(u.nombre),
                      subtitle: Text(
                        '${u.correo}\n${Session.nombreRol(u.tipoUsuario)}'
                        '${u.activo ? '' : '  •  Desactivado'}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (op) {
                          if (op == 'editar') _formulario(usuario: u);
                          if (op == 'estatus') _cambiarEstatus(u);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'editar', child: Text('Editar')),
                          PopupMenuItem(
                            value: 'estatus',
                            child: Text(u.activo ? 'Desactivar' : 'Activar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _UsuarioDialog extends StatefulWidget {
  final UserModel? usuario;
  final UserService servicio;

  const _UsuarioDialog({required this.usuario, required this.servicio});

  @override
  State<_UsuarioDialog> createState() => _UsuarioDialogState();
}

class _UsuarioDialogState extends State<_UsuarioDialog> {
  late final TextEditingController _nombre =
      TextEditingController(text: widget.usuario?.nombre ?? '');
  late final TextEditingController _correo =
      TextEditingController(text: widget.usuario?.correo ?? '');
  late final TextEditingController _direccion =
      TextEditingController(text: widget.usuario?.direccion ?? '');
  final TextEditingController _password = TextEditingController();

  late int _rol = widget.usuario?.tipoUsuario ?? Session.rolLector;
  late bool _activo = widget.usuario?.activo ?? true;
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.usuario != null;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _direccion.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    final correo = _correo.text.trim();
    if (nombre.length < 2 || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
      setState(() => _error = 'Ingresa un nombre y un correo válidos');
      return;
    }
    if (!_esEdicion) {
      final p = _password.text;
      if (p.length < 8 || !RegExp(r'[A-Za-z]').hasMatch(p) || !RegExp(r'\d').hasMatch(p)) {
        setState(() => _error = 'La contraseña debe tener 8+ caracteres con letras y números');
        return;
      }
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      if (_esEdicion) {
        await widget.servicio.actualizarUsuario(UserModel(
          id: widget.usuario!.id,
          nombre: nombre,
          correo: correo,
          direccion: _direccion.text,
          tipoUsuario: _rol,
          activo: _activo,
        ));
      } else {
        await widget.servicio.crearUsuario(
          nombre: nombre,
          correo: correo,
          password: _password.text,
          direccion: _direccion.text,
          rol: _rol,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = textoError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar usuario' : 'Nuevo usuario'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
              ),
              TextField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
              ),
              TextField(
                controller: _direccion,
                decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
              ),
              if (!_esEdicion)
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _rol,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Administrador')),
                  DropdownMenuItem(value: 2, child: Text('Autor')),
                  DropdownMenuItem(value: 3, child: Text('Lector')),
                ],
                onChanged: (v) => setState(() => _rol = v ?? _rol),
              ),
              if (_esEdicion)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cuenta activa'),
                  value: _activo,
                  onChanged: (v) => setState(() => _activo = v),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!, style: const TextStyle(color: AppColors.rojo)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: Text(_guardando ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}
