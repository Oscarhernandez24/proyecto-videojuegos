class ComentarioModel {
  final int id;
  final String comentario;
  final String fecha;
  final int usuarioId;
  final String nombreUsuario;
  final int blogId;
  final int? parentId;
  final int likes;
  final int dislikes;
  final int miVoto; // 1 = like, -1 = dislike, 0 = sin voto

  const ComentarioModel({
    required this.id,
    required this.comentario,
    required this.fecha,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.blogId,
    required this.parentId,
    required this.likes,
    required this.dislikes,
    required this.miVoto,
  });

  factory ComentarioModel.fromJson(Map<String, dynamic> json) {
    return ComentarioModel(
      id: (json['id_com'] as num).toInt(),
      comentario: json['comentario']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      usuarioId: (json['usr_id'] as num).toInt(),
      nombreUsuario: json['nom_usr']?.toString() ?? 'Usuario',
      blogId: (json['blog_id'] as num).toInt(),
      parentId: (json['parent_id'] as num?)?.toInt(),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      dislikes: (json['dislikes'] as num?)?.toInt() ?? 0,
      miVoto: (json['mi_voto'] as num?)?.toInt() ?? 0,
    );
  }

  /// "2026-11-12T17:29:00" -> "2026-11-12 17:29"
  String get fechaCorta =>
      fecha.length >= 16 ? fecha.substring(0, 16).replaceFirst('T', ' ') : fecha;
}
