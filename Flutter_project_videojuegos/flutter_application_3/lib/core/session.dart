import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Permite navegar al login desde cualquier capa (por ejemplo, cuando expira la sesión).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Sesión del usuario: token JWT + datos básicos.
///
/// El token se guarda con `flutter_secure_storage` (Keychain en iOS, almacenamiento
/// cifrado en Android) para que no quede en texto plano en el dispositivo.
class Session {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _kToken = 'token';
  static const String _kUsuario = 'usuario';

  static const int rolAdmin = 1;
  static const int rolAutor = 2;
  static const int rolLector = 3;

  static String? token;
  static Map<String, dynamic> usuario = {};

  static bool get logueado => token != null && usuario.isNotEmpty;
  static int get rol => (usuario['tip_usu'] as num?)?.toInt() ?? 0;
  static int? get idUsuario => (usuario['id_usr'] as num?)?.toInt();
  static String get nombre => usuario['nom_usr']?.toString() ?? 'Invitado';
  static String get correo => usuario['mail']?.toString() ?? '';

  static bool get esAdmin => rol == rolAdmin;
  static bool get puedePublicar => rol == rolAdmin || rol == rolAutor;

  static String nombreRol(int rol) {
    switch (rol) {
      case rolAdmin:
        return 'Administrador';
      case rolAutor:
        return 'Autor';
      case rolLector:
        return 'Lector';
      default:
        return 'Invitado';
    }
  }

  /// Carga la sesión guardada (si existe) al abrir la app.
  static Future<void> cargar() async {
    try {
      token = await _storage.read(key: _kToken);
      final guardado = await _storage.read(key: _kUsuario);
      if (guardado != null) {
        usuario = Map<String, dynamic>.from(jsonDecode(guardado) as Map);
      }
    } catch (_) {
      token = null;
      usuario = {};
    }
  }

  static Future<void> guardar(String nuevoToken, Map<String, dynamic> datos) async {
    token = nuevoToken;
    usuario = Map<String, dynamic>.from(datos);
    try {
      await _storage.write(key: _kToken, value: nuevoToken);
      await _storage.write(key: _kUsuario, value: jsonEncode(usuario));
    } catch (_) {
      // Si el almacenamiento seguro no está disponible la sesión vive solo en memoria.
    }
  }

  static Future<void> actualizarUsuario(Map<String, dynamic> datos) async {
    usuario = Map<String, dynamic>.from(datos);
    try {
      await _storage.write(key: _kUsuario, value: jsonEncode(usuario));
    } catch (_) {}
  }

  /// Destruye el token y los datos de sesión (cierre de sesión).
  static Future<void> limpiar() async {
    token = null;
    usuario = {};
    try {
      await _storage.delete(key: _kToken);
      await _storage.delete(key: _kUsuario);
    } catch (_) {}
  }
}
