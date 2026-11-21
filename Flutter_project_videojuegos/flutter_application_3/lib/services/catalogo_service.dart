import '../core/api_client.dart';
import '../models/catalogo_model.dart';

/// Géneros de videojuegos (`genres`) o categorías editoriales (`categories`).
class CatalogoService {
  final String ruta;

  const CatalogoService._(this.ruta);

  static const CatalogoService generos = CatalogoService._('genres');
  static const CatalogoService categorias = CatalogoService._('categories');

  Future<List<CatalogoItem>> listar({bool incluirInactivos = false}) async {
    final datos = await ApiClient.get(
      '/$ruta',
      query: incluirInactivos ? {'incluir_inactivos': 'true'} : null,
    );
    return CatalogoItem.listaDesdeJson(datos);
  }

  Future<void> crear(String nombre) =>
      ApiClient.post('/$ruta', body: {'nombre': nombre.trim()});

  Future<void> actualizar(int id, String nombre, bool activo) =>
      ApiClient.put('/$ruta/$id',
          body: {'nombre': nombre.trim(), 'estatus': activo ? 1 : 0});

  Future<void> eliminar(int id) => ApiClient.delete('/$ruta/$id');
}
