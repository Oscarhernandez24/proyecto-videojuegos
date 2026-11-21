import 'catalogo_model.dart';

class UserModel {
  final int id;
  final String nombre;
  final String correo;
  final String? direccion;
  final int tipoUsuario;
  final bool activo;
  final List<CatalogoItem> generos;

  const UserModel({
    required this.id,
    required this.nombre,
    required this.correo,
    this.direccion,
    this.tipoUsuario = 3,
    this.activo = true,
    this.generos = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id_usr'] as num).toInt(),
      nombre: json['nom_usr']?.toString() ?? '',
      correo: json['mail']?.toString() ?? '',
      direccion: json['dir_usr']?.toString(),
      tipoUsuario: (json['tip_usu'] as num?)?.toInt() ?? 3,
      activo: ((json['estatus'] as num?)?.toInt() ?? 1) == 1,
      generos: CatalogoItem.listaDesdeJson(json['generos']),
    );
  }
}
