import '../core/api_client.dart';
import '../core/session.dart';
import '../models/user_model.dart';

class UserService {
  // ---------- Administrador ----------
  Future<List<UserModel>> obtenerUsuarios() async {
    final datos = await ApiClient.get('/users');
    return (datos as List)
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> crearUsuario({
    required String nombre,
    required String correo,
    required String password,
    String? direccion,
    required int rol,
  }) async {
    await ApiClient.post('/users', body: {
      'nom_usr': nombre.trim(),
      'mail': correo.trim().toLowerCase(),
      'password': password,
      'dir_usr': (direccion == null || direccion.trim().isEmpty)
          ? null
          : direccion.trim(),
      'tip_usu': rol,
    });
  }

  Future<void> actualizarUsuario(UserModel u) async {
    await ApiClient.put('/users/${u.id}', body: {
      'nom_usr': u.nombre.trim(),
      'mail': u.correo.trim().toLowerCase(),
      'dir_usr': (u.direccion == null || u.direccion!.trim().isEmpty)
          ? null
          : u.direccion!.trim(),
      'tip_usu': u.tipoUsuario,
      'estatus': u.activo ? 1 : 0,
    });
  }

  // ---------- Perfil propio ----------
  Future<void> actualizarPerfil({
    required String nombre,
    required String correo,
    String? direccion,
    required List<int> generos,
  }) async {
    final datos = await ApiClient.put('/users/me', body: {
      'nom_usr': nombre.trim(),
      'mail': correo.trim().toLowerCase(),
      'dir_usr': (direccion == null || direccion.trim().isEmpty)
          ? null
          : direccion.trim(),
      'generos': generos,
    });
    await Session.actualizarUsuario(Map<String, dynamic>.from(datos as Map));
  }

  Future<void> cambiarPassword(String actual, String nueva) async {
    await ApiClient.put('/users/me/password',
        body: {'actual': actual, 'nueva': nueva});
  }
}
