import '../core/api_client.dart';
import '../models/comentario_model.dart';

class ComentarioService {
  Future<List<ComentarioModel>> obtenerComentarios(int blogId) async {
    final datos = await ApiClient.get('/posts/$blogId/comments');
    return (datos as List)
        .map((e) => ComentarioModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> agregarComentario(int blogId, String texto, {int? parentId}) =>
      ApiClient.post('/posts/$blogId/comments',
          body: {'comentario': texto.trim(), 'parent_id': parentId});

  Future<void> editarComentario(int id, String texto) =>
      ApiClient.put('/comments/$id', body: {'comentario': texto.trim()});

  Future<void> eliminarComentario(int id) => ApiClient.delete('/comments/$id');

  /// valor: 1 = like, -1 = dislike, 0 = quitar voto.
  Future<void> votar(int id, int valor) =>
      ApiClient.post('/comments/$id/vote', body: {'valor': valor});
}
