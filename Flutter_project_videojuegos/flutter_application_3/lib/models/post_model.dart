import 'catalogo_model.dart';

class PostModel {
  final int id;
  final String titulo;
  final String descripcion;
  final String imagen;
  final String tags;
  final String fecha;
  final int autorId;
  final String autorNombre;
  final int? categoriaId;
  final String categoriaNombre;
  final List<CatalogoItem> generos;
  final double promedio;
  final int totalValoraciones;
  final int totalComentarios;
  final Map<String, int> reacciones;
  final String? miReaccion;
  final int? miValoracion;

  const PostModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.imagen,
    required this.tags,
    required this.fecha,
    required this.autorId,
    required this.autorNombre,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.generos,
    required this.promedio,
    required this.totalValoraciones,
    required this.totalComentarios,
    required this.reacciones,
    required this.miReaccion,
    required this.miValoracion,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final reacciones = <String, int>{};
    final crudas = json['reacciones'];
    if (crudas is Map) {
      crudas.forEach((k, v) => reacciones[k.toString()] = (v as num).toInt());
    }
    return PostModel(
      id: (json['id_blog'] as num).toInt(),
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      imagen: json['img']?.toString() ?? '',
      tags: json['tags']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      autorId: (json['autor_id'] as num).toInt(),
      autorNombre: json['autor_nombre']?.toString() ?? 'Autor desconocido',
      categoriaId: (json['categoria_id'] as num?)?.toInt(),
      categoriaNombre: json['categoria_nombre']?.toString() ?? '',
      generos: CatalogoItem.listaDesdeJson(json['generos']),
      promedio: (json['promedio'] as num?)?.toDouble() ?? 0,
      totalValoraciones: (json['total_valoraciones'] as num?)?.toInt() ?? 0,
      totalComentarios: (json['total_comentarios'] as num?)?.toInt() ?? 0,
      reacciones: reacciones,
      miReaccion: json['mi_reaccion']?.toString(),
      miValoracion: (json['mi_valoracion'] as num?)?.toInt(),
    );
  }

  /// "2026-11-12T17:29:00" -> "2026-11-12"
  String get fechaCorta => fecha.length >= 10 ? fecha.substring(0, 10) : fecha;
}
