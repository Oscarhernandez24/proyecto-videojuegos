import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import 'package:image_picker/image_picker.dart';

import '../core/session.dart';
import '../core/ui.dart';
import '../models/catalogo_model.dart';
import '../models/post_model.dart';
import '../services/catalogo_service.dart';
import '../services/post_service.dart';
import '../widgets/app_drawer.dart';

/// Crear o editar una publicación (si se recibe un PostModel como argumento, es edición).
class PostFormPage extends StatefulWidget {
  const PostFormPage({super.key});

  @override
  State<PostFormPage> createState() => _PostFormPageState();
}

class _PostFormPageState extends State<PostFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _tags = TextEditingController();
  final _servicio = PostService();
  final _picker = ImagePicker();

  PostModel? _post;
  bool _iniciado = false;
  bool _guardando = false;
  bool _cargandoCatalogos = true;
  String? _errorCatalogos;

  List<CatalogoItem> _categorias = [];
  List<CatalogoItem> _generos = [];
  int? _categoriaId;
  final Set<int> _generosSel = {};

  XFile? _foto;
  Uint8List? _imagenBytes;

  bool get _editando => _post != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is PostModel) {
      _post = args;
      _titulo.text = args.titulo;
      _descripcion.text = args.descripcion;
      _tags.text = args.tags;
    }
    _cargarCatalogos();
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogos() async {
    setState(() {
      _cargandoCatalogos = true;
      _errorCatalogos = null;
    });
    try {
      final categorias = await CatalogoService.categorias.listar();
      final generos = await CatalogoService.generos.listar();
      if (!mounted) return;
      setState(() {
        _categorias = categorias;
        _generos = generos;
        final post = _post;
        if (post != null) {
          // Solo se preseleccionan elementos que sigan activos.
          if (categorias.any((c) => c.id == post.categoriaId)) {
            _categoriaId = post.categoriaId;
          }
          for (final g in post.generos) {
            if (generos.any((x) => x.id == g.id)) _generosSel.add(g.id);
          }
        }
        _cargandoCatalogos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCatalogos = textoError(e);
        _cargandoCatalogos = false;
      });
    }
  }

  // La cámara solo existe en celulares; en web/escritorio se usa la galería.
  bool get _camaraDisponible =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _seleccionarImagen(ImageSource fuente) async {
    try {
      final imagen = await _picker.pickImage(source: fuente, imageQuality: 75);
      if (imagen == null) return;
      final bytes = await imagen.readAsBytes();
      if (!mounted) return;
      setState(() {
        _foto = imagen;
        _imagenBytes = bytes;
      });
    } catch (e) {
      if (mounted) mensaje(context, 'No se pudo obtener la imagen: $e');
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      mensaje(context, 'Selecciona una categoría');
      return;
    }
    if (_generosSel.isEmpty) {
      mensaje(context, 'Selecciona al menos un género de videojuego');
      return;
    }
    setState(() => _guardando = true);
    try {
      await _servicio.guardarPost(
        id: _post?.id,
        titulo: _titulo.text,
        descripcion: _descripcion.text,
        categoriaId: _categoriaId!,
        generos: _generosSel.toList(),
        tags: _tags.text,
        imagenBytes: _imagenBytes,
        nombreArchivo: _foto?.name,
      );
      if (!mounted) return;
      mensaje(
        context,
        _editando
            ? 'Publicación actualizada correctamente'
            : 'Publicación agregada correctamente',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mensaje(context, 'No fue posible guardar la información: ${textoError(e)}');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.puedePublicar) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nueva publicación')),
        drawer: const AppDrawer(rutaActual: '/post-form'),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Solo los autores y administradores pueden crear publicaciones.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar publicación' : 'Nueva publicación'),
      ),
      body: _cargandoCatalogos
          ? const Center(child: CircularProgressIndicator())
          : _errorCatalogos != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorCatalogos!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _cargarCatalogos,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _formulario(),
    );
  }

  Widget _formulario() {
    final imagenActual = _post?.imagen ?? '';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _editando ? 'Modificar publicación' : 'Nueva publicación',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text('Autor: ${Session.nombre}'),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titulo,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().length < 2
                          ? 'Ingresa el título'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descripcion,
                      maxLines: 6,
                      maxLength: 5000,
                      decoration: const InputDecoration(
                        labelText: 'Contenido',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Ingresa el contenido'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: _categoriaId,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de entrada (categoría)',
                        border: OutlineInputBorder(),
                      ),
                      items: _categorias
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.nombre),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _categoriaId = v),
                      validator: (v) => v == null ? 'Selecciona una categoría' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Géneros de videojuego (elige al menos uno)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: _generos
                          .map((g) => FilterChip(
                                label: Text(g.nombre),
                                selected: _generosSel.contains(g.id),
                                onSelected: (v) => setState(() {
                                  v ? _generosSel.add(g.id) : _generosSel.remove(g.id);
                                }),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _tags,
                      decoration: const InputDecoration(
                        labelText: 'Etiquetas (opcional)',
                        hintText: 'mundo abierto, indie, multijugador',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _seleccionarImagen(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: Text(_foto == null && imagenActual.isEmpty
                              ? 'Elegir imagen de portada'
                              : 'Cambiar imagen'),
                        ),
                        if (_camaraDisponible)
                          OutlinedButton.icon(
                            onPressed: () => _seleccionarImagen(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Tomar foto'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_imagenBytes != null)
                      _vistaPrevia(Image.memory(_imagenBytes!, fit: BoxFit.cover))
                    else if (imagenActual.isNotEmpty)
                      _vistaPrevia(Image.network(
                        imagenActual,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            const Center(child: Icon(Icons.image_not_supported)),
                      )),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_guardando
                          ? 'Guardando...'
                          : (_editando ? 'Guardar cambios' : 'Publicar')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _vistaPrevia(Widget imagen) {
    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borde),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: imagen),
    );
  }
}
