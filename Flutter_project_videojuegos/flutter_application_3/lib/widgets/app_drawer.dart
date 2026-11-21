import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/session.dart';
import '../services/auth_service.dart';
import 'logo_marca.dart';

/// Menú lateral: las opciones cambian según el rol (Administrador, Autor, Lector, Invitado).
class AppDrawer extends StatelessWidget {
  final String rutaActual;

  const AppDrawer({super.key, required this.rutaActual});

  void _ir(BuildContext context, String ruta) {
    Navigator.pop(context);
    if (ruta == rutaActual) return;
    Navigator.pushReplacementNamed(context, ruta);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _cabecera(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _opcion(context, Icons.newspaper, 'Noticias', '/blog'),
                  if (Session.puedePublicar)
                    ListTile(
                      leading: const Icon(Icons.edit_note),
                      title: const Text('Nueva publicación'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/post-form');
                      },
                    ),
                  if (Session.logueado)
                    _opcion(context, Icons.account_circle_outlined, 'Mi perfil', '/profile'),
                  if (Session.esAdmin) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
                      child: Text('ADMINISTRACIÓN', style: AppText.meta),
                    ),
                    _opcion(context, Icons.people_alt_outlined, 'Usuarios', '/users'),
                    _opcion(context, Icons.category_outlined, 'Géneros de videojuegos',
                        '/genres-admin'),
                    _opcion(context, Icons.label_outline, 'Categorías', '/categories-admin'),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            if (Session.logueado)
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.rojo),
                title: const Text('Cerrar sesión', style: TextStyle(color: AppColors.rojo)),
                onTap: () async {
                  await AuthService().cerrarSesion();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Iniciar sesión'),
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Crear cuenta'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/register');
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _cabecera() {
    final inicial = Session.nombre.isNotEmpty ? Session.nombre[0].toUpperCase() : '?';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16397A), AppColors.superficie],
        ),
        border: Border(bottom: BorderSide(color: AppColors.borde)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LogoMarca(tamano: 40, conTexto: true),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Session.logueado
                        ? AppColors.colorRol(Session.rol)
                        : AppColors.borde,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.superficieAlta,
                  child: Session.logueado
                      ? Text(inicial,
                          style: const TextStyle(fontWeight: FontWeight.w900))
                      : const Icon(Icons.person_outline, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Session.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Session.logueado
                          ? Session.nombreRol(Session.rol)
                          : 'Sin iniciar sesión',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Session.logueado
                            ? AppColors.colorRol(Session.rol)
                            : AppColors.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _opcion(BuildContext context, IconData icono, String titulo, String ruta) {
    return ListTile(
      leading: Icon(icono),
      title: Text(titulo),
      selected: ruta == rutaActual,
      onTap: () => _ir(context, ruta),
    );
  }
}
