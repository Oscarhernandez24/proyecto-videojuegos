import 'package:flutter/material.dart';

import '../config/app_theme.dart';

import '../core/session.dart';
import '../core/ui.dart';
import '../models/catalogo_model.dart';
import '../services/catalogo_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/error_vista.dart';

/// CRUD de géneros de videojuegos o de categorías (solo administrador).
class CatalogAdminPage extends StatefulWidget {
  final bool esGenero;

  const CatalogAdminPage({super.key, required this.esGenero});

  @override
  State<CatalogAdminPage> createState() => _CatalogAdminPageState();
}

class _CatalogAdminPageState extends State<CatalogAdminPage> {
  late final CatalogoService _servicio =
      widget.esGenero ? CatalogoService.generos : CatalogoService.categorias;
  late Future<List<CatalogoItem>> _futuro;

  String get _titulo => widget.esGenero ? 'Géneros de videojuegos' : 'Categorías';
  String get _singular => widget.esGenero ? 'género' : 'categoría';
  String get _ruta => widget.esGenero ? '/genres-admin' : '/categories-admin';

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.listar(incluirInactivos: true);
  }

  void _recargar() {
    setState(() {
      _futuro = _servicio.listar(incluirInactivos: true);
    });
  }

  Future<void> _formulario({CatalogoItem? item}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _CatalogoDialog(
        item: item,
        servicio: _servicio,
        singular: _singular,
      ),
    );
    if (ok == true && mounted) {
      mensaje(context, item == null ? 'Registro creado' : 'Registro actualizado');
      _recargar();
    }
  }

  Future<void> _eliminar(CatalogoItem item) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar $_singular',
      texto: '¿Deseas eliminar "${item.nombre}"?',
    );
    if (!ok) return;
    try {
      await _servicio.eliminar(item.id);
      if (!mounted) return;
      mensaje(context, 'Eliminado correctamente');
      _recargar();
    } catch (e) {
      if (mounted) mensaje(context, textoError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.esAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(_titulo)),
        drawer: AppDrawer(rutaActual: _ruta),
        body: const Center(child: Text('Solo el administrador puede ver esta sección.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulo),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _recargar,
          ),
        ],
      ),
      drawer: AppDrawer(rutaActual: _ruta),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formulario(),
        icon: const Icon(Icons.add),
        label: Text('Nuevo $_singular'),
      ),
      body: FutureBuilder<List<CatalogoItem>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorVista(
              texto: textoError(snapshot.error!),
              onReintentar: _recargar,
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(child: Text('Aún no hay registros de $_titulo.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    child: ListTile(
                      title: Text(item.nombre),
                      subtitle: Text(
                        item.activo ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: item.activo ? AppColors.azul : AppColors.textoSuave,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _formulario(item: item),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _eliminar(item),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CatalogoDialog extends StatefulWidget {
  final CatalogoItem? item;
  final CatalogoService servicio;
  final String singular;

  const _CatalogoDialog({
    required this.item,
    required this.servicio,
    required this.singular,
  });

  @override
  State<_CatalogoDialog> createState() => _CatalogoDialogState();
}

class _CatalogoDialogState extends State<_CatalogoDialog> {
  late final TextEditingController _nombre =
      TextEditingController(text: widget.item?.nombre ?? '');
  late bool _activo = widget.item?.activo ?? true;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    if (nombre.length < 2) {
      setState(() => _error = 'El nombre debe tener al menos 2 caracteres');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      if (widget.item == null) {
        await widget.servicio.crear(nombre);
      } else {
        await widget.servicio.actualizar(widget.item!.id, nombre, _activo);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = textoError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null
          ? 'Nuevo ${widget.singular}'
          : 'Editar ${widget.singular}'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombre,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            if (widget.item != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activo'),
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: const TextStyle(color: AppColors.rojo)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: Text(_guardando ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}
