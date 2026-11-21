import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/session.dart';
import '../core/ui.dart';
import '../models/catalogo_model.dart';
import '../models/post_model.dart';
import '../services/catalogo_service.dart';
import '../services/post_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/category_chip.dart';
import '../widgets/error_vista.dart';
import '../widgets/imagen_post.dart';
import '../widgets/logo_marca.dart';
import '../widgets/post_card.dart';
import 'post_detail_page.dart';

/// Portada del blog: noticia destacada + cuadrícula de publicaciones.
/// En pantallas anchas aparece una barra lateral con buscador, recientes y géneros.
/// Los invitados pueden consultarla.
class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final PostService _postService = PostService();
  final TextEditingController _busqueda = TextEditingController();

  late Future<List<PostModel>> _futuroPosts;
  List<CatalogoItem> _generos = [];
  List<CatalogoItem> _categorias = [];
  int? _generoSel;
  int? _categoriaSel;

  @override
  void initState() {
    super.initState();
    _futuroPosts = _cargarPosts();
    _cargarCatalogos();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<List<PostModel>> _cargarPosts() => _postService.obtenerPosts(
        generoId: _generoSel,
        categoriaId: _categoriaSel,
        busqueda: _busqueda.text,
      );

  Future<void> _cargarCatalogos() async {
    try {
      final generos = await CatalogoService.generos.listar();
      final categorias = await CatalogoService.categorias.listar();
      if (!mounted) return;
      setState(() {
        _generos = generos;
        _categorias = categorias;
      });
    } catch (_) {
      // Los filtros simplemente no aparecen; el error de red se muestra en el feed.
    }
  }

  void _recargar() {
    setState(() {
      _futuroPosts = _cargarPosts();
    });
  }

  String _textoVacio() {
    if (_generoSel != null) {
      final nombre = _generos.firstWhere((g) => g.id == _generoSel).nombre;
      return 'Aún no hay publicaciones en el género $nombre.'
          '${Session.puedePublicar ? ' ¡Sé el primero en escribir una!' : ''}';
    }
    if (_categoriaSel != null) {
      final nombre = _categorias.firstWhere((c) => c.id == _categoriaSel).nombre;
      return 'Aún no hay publicaciones en la categoría $nombre.';
    }
    if (_busqueda.text.trim().isNotEmpty) {
      return 'No se encontraron publicaciones para "${_busqueda.text.trim()}".';
    }
    return 'Todavía no hay publicaciones.'
        '${Session.puedePublicar ? ' Crea la primera con el botón Publicar.' : ''}';
  }

  Future<void> _abrirPost(PostModel post) async {
    await Navigator.push(
      context,
      MaterialPageRoute<bool>(builder: (_) => PostDetailPage(postId: post.id)),
    );
    if (mounted) _recargar();
  }

  Future<void> _nuevoPost() async {
    final creado = await Navigator.pushNamed(context, '/post-form');
    if (creado == true && mounted) _recargar();
  }

  // ------------------------------------------------------------ cabecera
  Widget _accionSesion() {
    if (!Session.logueado) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TextButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false),
          child: const Text('ENTRAR'),
        ),
      );
    }
    final inicial = Session.nombre.isNotEmpty ? Session.nombre[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Tooltip(
        message: '${Session.nombre} (${Session.nombreRol(Session.rol)})',
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.colorRol(Session.rol), width: 2),
            ),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.superficieAlta,
              child: Text(inicial,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            ),
          ),
        ),
      ),
    );
  }

  /// Pestañas de categorías bajo la cabecera (Reseñas, Noticias, Guías...).
  Widget _pestanasCategorias() {
    Widget pestana(String texto, bool activa, VoidCallback alTocar) {
      return InkWell(
        onTap: alTocar,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: activa ? AppColors.azul : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            texto.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: activa ? AppColors.texto : AppColors.textoSuave,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          pestana('Todo', _categoriaSel == null, () {
            _categoriaSel = null;
            _recargar();
          }),
          ..._categorias.map(
            (c) => pestana(c.nombre, _categoriaSel == c.id, () {
              _categoriaSel = c.id;
              _recargar();
            }),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- componentes
  Widget _tituloSeccion(String texto) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: AppColors.naranja),
        const SizedBox(width: 10),
        Text(texto, style: AppText.seccion),
      ],
    );
  }

  Widget _buscador() {
    return TextField(
      controller: _busqueda,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _recargar(),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Buscar juegos, guías, noticias...',
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        suffixIcon: _busqueda.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _busqueda.clear();
                  _recargar();
                },
              ),
      ),
    );
  }

  Widget _filtroGeneros() {
    if (_generos.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        CategoryChip(
          text: 'Todos los géneros',
          selected: _generoSel == null,
          onTap: () {
            _generoSel = null;
            _recargar();
          },
        ),
        ..._generos.map(
          (g) => CategoryChip(
            text: g.nombre,
            selected: _generoSel == g.id,
            onTap: () {
              _generoSel = g.id;
              _recargar();
            },
          ),
        ),
      ],
    );
  }

  Widget _vacio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
      child: Column(
        children: [
          const Icon(Icons.sports_esports, size: 64, color: AppColors.borde),
          const SizedBox(height: 14),
          Text(_textoVacio(), textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textoSuave, fontSize: 15)),
        ],
      ),
    );
  }

  List<Widget> _principal(List<PostModel> posts, bool conBarra) {
    final resto = posts.length > 1 ? posts.sublist(1) : <PostModel>[];
    return [
      _tituloSeccion('ÚLTIMAS NOTICIAS'),
      const SizedBox(height: 14),
      if (!conBarra) ...[
        _buscador(),
        const SizedBox(height: 12),
        _filtroGeneros(),
        const SizedBox(height: 16),
      ],
      if (posts.isEmpty)
        _vacio()
      else ...[
        PostHero(post: posts.first, onTap: () => _abrirPost(posts.first)),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, caja) {
          final columnas = caja.maxWidth >= 620 ? 2 : 1;
          const separacion = 16.0;
          final ancho = (caja.maxWidth - separacion * (columnas - 1)) / columnas;
          return Wrap(
            spacing: separacion,
            runSpacing: separacion,
            children: resto
                .map((p) => SizedBox(
                      width: ancho,
                      child: PostCard(post: p, onTap: () => _abrirPost(p)),
                    ))
                .toList(),
          );
        }),
      ],
    ];
  }

  Widget _barraLateral(List<PostModel> posts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buscador(),
          const SizedBox(height: 28),
          _tituloSeccion('PUBLICACIONES RECIENTES'),
          const SizedBox(height: 14),
          if (posts.isEmpty)
            const Text('Sin publicaciones por ahora.', style: AppText.meta)
          else
            ...posts.take(5).map(
                  (p) => InkWell(
                    onTap: () => _abrirPost(p),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 72,
                              height: 54,
                              child: ImagenPost(url: p.imagen),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.titulo,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(p.fechaCorta, style: AppText.meta),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 20),
          _tituloSeccion('GÉNEROS'),
          const SizedBox(height: 14),
          _filtroGeneros(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const LogoMarca(tamano: 30, conTexto: true),
        actions: [_accionSesion()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _pestanasCategorias(),
        ),
      ),
      drawer: const AppDrawer(rutaActual: '/blog'),
      floatingActionButton: Session.puedePublicar
          ? FloatingActionButton.extended(
              onPressed: _nuevoPost,
              icon: const Icon(Icons.edit),
              label: const Text('PUBLICAR'),
            )
          : null,
      body: FutureBuilder<List<PostModel>>(
        future: _futuroPosts,
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
          final posts = snapshot.data ?? [];

          return LayoutBuilder(builder: (context, caja) {
            final conBarra = caja.maxWidth >= 1000;

            final lista = RefreshIndicator(
              onRefresh: () async {
                final nuevo = _cargarPosts();
                setState(() => _futuroPosts = nuevo);
                await nuevo;
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 18, conBarra ? 8 : 16, 100),
                children: _principal(posts, conBarra),
              ),
            );

            if (!conBarra) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: lista,
                ),
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: lista),
                    SizedBox(width: 330, child: _barraLateral(posts)),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
