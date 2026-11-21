import '../core/api_client.dart';

/// Reacciones con emoji y valoración por estrellas.
class InteraccionService {
  /// Debe coincidir con REACCIONES_PERMITIDAS de la API.
  static const List<String> reacciones = ['🔥', '❤️', '😂', '😮', '👏', '🎮'];

  Future<void> reaccionar(int blogId, String emoji) =>
      ApiClient.put('/posts/$blogId/reaction', body: {'emoji': emoji});

  Future<void> quitarReaccion(int blogId) =>
      ApiClient.delete('/posts/$blogId/reaction');

  Future<void> valorar(int blogId, int estrellas) =>
      ApiClient.put('/posts/$blogId/rating', body: {'estrellas': estrellas});
}
