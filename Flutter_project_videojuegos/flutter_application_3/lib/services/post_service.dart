import 'dart:typed_data';

import '../core/api_client.dart';
import '../models/post_model.dart';

class PostService {
  Future<List<PostModel>> obtenerPosts({
    int? generoId,
    int? categoriaId,
    String? busqueda,
  }) async {
    final query = <String, String>{
      if (generoId != null) 'genre_id': '$generoId',
      if (categoriaId != null) 'category_id': '$categoriaId',
      if (busqueda != null && busqueda.trim().isNotEmpty) 'q': busqueda.trim(),
    };
    final datos = await ApiClient.get('/posts', query: query);
    return (datos as List)
        .map((e) => PostModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<PostModel> obtenerPost(int id) async {
    final datos = await ApiClient.get('/posts/$id');
    return PostModel.fromJson(Map<String, dynamic>.from(datos as Map));
  }

  /// Crea (id == null) o edita una publicación. Se envía como multipart por la imagen.
  Future<PostModel> guardarPost({
    int? id,
    required String titulo,
    required String descripcion,
    required int categoriaId,
    required List<int> generos,
    String? tags,
    Uint8List? imagenBytes,
    String? nombreArchivo,
  }) async {
    final campos = <String, String>{
      'titulo': titulo.trim(),
      'descripcion': descripcion.trim(),
      'categoria_id': '$categoriaId',
      'generos': generos.join(','),
      if (tags != null && tags.trim().isNotEmpty) 'tags': tags.trim(),
    };
    final datos = await ApiClient.multipart(
      id == null ? 'POST' : 'PUT',
      id == null ? '/posts' : '/posts/$id',
      campos,
      bytes: imagenBytes,
      nombreArchivo: nombreArchivo,
    );
    return PostModel.fromJson(Map<String, dynamic>.from(datos as Map));
  }

  Future<void> eliminarPost(int id) => ApiClient.delete('/posts/$id');
}
