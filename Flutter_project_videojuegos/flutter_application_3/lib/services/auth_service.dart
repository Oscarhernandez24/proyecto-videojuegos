import '../core/api_client.dart';
import '../core/session.dart';

class AuthService {
  static final RegExp _patronCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? validarLogin({required String usuario, required String password}) {
    if (usuario.trim().isEmpty || password.isEmpty) {
      return 'Ingresa tu correo y contraseña';
    }
    return null;
  }

  /// Mínimo 8 caracteres con letras y números (misma regla que la API).
  String? validarPassword(String password) {
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'La contraseña debe incluir letras y números';
    }
    return null;
  }

  String? validarRegistro({
    required String nombre,
    required String correo,
    required String password,
    required String confirmarpassword,
  }) {
    if (nombre.trim().length < 2 ||
        correo.trim().isEmpty ||
        password.isEmpty ||
        confirmarpassword.isEmpty) {
      return 'Completa todos los campos obligatorios';
    }
    if (!_patronCorreo.hasMatch(correo.trim())) {
      return 'Ingresa un correo válido (usuario@dominio.com)';
    }
    final errorPassword = validarPassword(password);
    if (errorPassword != null) return errorPassword;
    if (password != confirmarpassword) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  /// POST /auth/login. Guarda el token y los datos del usuario en la sesión.
  Future<void> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    await Session.limpiar();
    final datos = await ApiClient.post('/auth/login', body: {
      'mail': correo.trim().toLowerCase(),
      'password': password,
    });
    await Session.guardar(
      datos['access_token'] as String,
      Map<String, dynamic>.from(datos['usuario'] as Map),
    );
  }

  /// POST /auth/register (el servidor asigna el rol Lector).
  Future<void> registrar({
    required String nombre,
    required String correo,
    required String password,
    String? direccion,
    List<int> generos = const [],
  }) async {
    await ApiClient.post('/auth/register', body: {
      'nom_usr': nombre.trim(),
      'mail': correo.trim().toLowerCase(),
      'password': password,
      'dir_usr': (direccion == null || direccion.trim().isEmpty)
          ? null
          : direccion.trim(),
      'generos': generos,
    });
  }

  /// POST /auth/forgot-password. En modo desarrollo la API devuelve `codigo_dev`.
  Future<Map<String, dynamic>> solicitarCodigo(String correo) async {
    final datos = await ApiClient.post('/auth/forgot-password',
        body: {'mail': correo.trim().toLowerCase()});
    return Map<String, dynamic>.from(datos as Map);
  }

  Future<void> restablecerPassword({
    required String correo,
    required String codigo,
    required String nuevaPassword,
  }) async {
    await ApiClient.post('/auth/reset-password', body: {
      'mail': correo.trim().toLowerCase(),
      'codigo': codigo.trim(),
      'nueva_password': nuevaPassword,
    });
  }

  /// Revisa que el token guardado siga siendo válido al abrir la app.
  /// Devuelve true si hay una sesión utilizable.
  Future<bool> restaurarSesion() async {
    if (Session.token == null) return false;
    try {
      final datos = await ApiClient.get('/auth/me');
      await Session.actualizarUsuario(Map<String, dynamic>.from(datos as Map));
      return true;
    } on ApiException catch (e) {
      if (e.sinConexion) return Session.usuario.isNotEmpty; // sin red: usar datos guardados
      await Session.limpiar();
      return false;
    }
  }

  /// Cierra la sesión: destruye el token almacenado en el dispositivo.
  Future<void> cerrarSesion() => Session.limpiar();
}
