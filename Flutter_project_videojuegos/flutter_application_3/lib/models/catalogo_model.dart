/// Elemento de un catálogo (género de videojuego o categoría editorial).
class CatalogoItem {
  final int id;
  final String nombre;
  final bool activo;

  const CatalogoItem({
    required this.id,
    required this.nombre,
    this.activo = true,
  });

  factory CatalogoItem.fromJson(Map<String, dynamic> json) {
    return CatalogoItem(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      activo: ((json['estatus'] as num?)?.toInt() ?? 1) == 1,
    );
  }

  static List<CatalogoItem> listaDesdeJson(dynamic datos) {
    if (datos is! List) return [];
    return datos
        .map((e) => CatalogoItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
