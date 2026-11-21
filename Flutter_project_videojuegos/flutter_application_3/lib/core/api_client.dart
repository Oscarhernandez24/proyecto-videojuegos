import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'session.dart';

/// Error legible para mostrar al usuario.
class ApiException implements Exception {
  final String mensaje;
  final int? codigo;

  ApiException(this.mensaje, [this.codigo]);

  bool get sinConexion => codigo == null;

  @override
  String toString() => mensaje;
}

/// Cliente HTTP único de la app: agrega el token, decodifica UTF-8 y traduce errores.
class ApiClient {
  static const Duration _timeout = Duration(seconds: 15);
  static const String mensajeSinConexion =
      'Sin conexión a internet. Por favor verifique su red.';

  static Uri _uri(String ruta, [Map<String, String>? query]) {
    final uri = Uri.parse('${ApiConfig.apiUrl}$ruta');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  static Map<String, String> _headers({bool json = true}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        if (Session.token != null) 'Authorization': 'Bearer ${Session.token}',
      };

  static Future<dynamic> get(String ruta, {Map<String, String>? query}) {
    return _enviar(() => http.get(_uri(ruta, query), headers: _headers()));
  }

  static Future<dynamic> post(String ruta, {Object? body}) {
    return _enviar(() => http.post(
          _uri(ruta),
          headers: _headers(),
          body: body == null ? null : jsonEncode(body),
        ));
  }

  static Future<dynamic> put(String ruta, {Object? body}) {
    return _enviar(() => http.put(
          _uri(ruta),
          headers: _headers(),
          body: body == null ? null : jsonEncode(body),
        ));
  }

  static Future<dynamic> delete(String ruta) {
    return _enviar(() => http.delete(_uri(ruta), headers: _headers()));
  }

  /// Envío multipart (texto + imagen opcional) para crear o editar publicaciones.
  static Future<dynamic> multipart(
    String metodo,
    String ruta,
    Map<String, String> campos, {
    Uint8List? bytes,
    String? nombreArchivo,
  }) {
    return _enviar(() async {
      final peticion = http.MultipartRequest(metodo, _uri(ruta))
        ..headers.addAll(_headers(json: false))
        ..fields.addAll(campos);
      if (bytes != null && nombreArchivo != null && nombreArchivo.isNotEmpty) {
        peticion.files.add(
          http.MultipartFile.fromBytes('imagen', bytes, filename: nombreArchivo),
        );
      }
      final respuesta = await peticion.send();
      return http.Response.fromStream(respuesta);
    });
  }

  static Future<dynamic> _enviar(Future<http.Response> Function() peticion) async {
    final http.Response respuesta;
    try {
      respuesta = await peticion().timeout(_timeout);
    } catch (_) {
      // Cualquier fallo al llegar al servidor (sin red, timeout, servidor apagado).
      throw ApiException(mensajeSinConexion);
    }
    return _procesar(respuesta);
  }

  static Future<dynamic> _procesar(http.Response respuesta) async {
    dynamic datos;
    if (respuesta.bodyBytes.isNotEmpty) {
      try {
        // Se decodifica como UTF-8 explícitamente para respetar acentos y emojis.
        datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      } catch (_) {}
    }

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) return datos;

    // Token vencido o inválido: se cierra la sesión y se regresa al login.
    if (respuesta.statusCode == 401 && Session.token != null) {
      await Session.limpiar();
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (route) => false);
      throw ApiException(
        'Tu sesión expiró. Inicia sesión de nuevo.',
        respuesta.statusCode,
      );
    }

    throw ApiException(_mensajeError(datos, respuesta.statusCode), respuesta.statusCode);
  }

  static String _mensajeError(dynamic datos, int codigo) {
    if (datos is Map && datos['detail'] != null) {
      final detalle = datos['detail'];
      if (detalle is List && detalle.isNotEmpty) {
        final primero = detalle.first;
        if (primero is Map && primero['msg'] != null) {
          return primero['msg'].toString();
        }
      }
      return detalle.toString();
    }
    if (codigo >= 500) return 'El servidor tuvo un problema. Intenta más tarde.';
    return 'Ocurrió un error inesperado (HTTP $codigo).';
  }
}
