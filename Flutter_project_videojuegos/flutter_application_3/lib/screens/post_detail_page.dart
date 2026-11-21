import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/session.dart';
import '../core/ui.dart';
import '../models/post_model.dart';
import '../services/interaccion_service.dart';
import '../services/post_service.dart';
import '../widgets/comment_section.dart';
import '../widgets/error_vista.dart';
import '../widgets/imagen_post.dart';
import '../widgets/post_tag.dart';
import '../widgets/puntuacion_badge.dart';
import '../widgets/rating_stars.dart';
import '../widgets/reaction_bar.dart';

/// Detalle de una publicación: portada con titular, contenido, nota de la
/// comunidad, reacciones y comentarios.
class PostDetailPage extends StatefulWidget {
  final int postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostService _postService = PostService();
  final InteraccionService _interacciones = InteraccionService();
  late Future<PostModel> _futuro;

  /// Se vuelve true si se editó, valoró o comentó, para que el feed se actualice.
  bool _huboCambios = false;

  @override
  void initState() {
    super.initState();
    _futuro = _postService.obtenerPost(widget.postId);
  }

  void _recargar() {
    setState(() {
      _futuro = _postService.obtenerPost(widget.postId);
    });
  }

  bool _puedeModificar(PostModel post) =>
      Session.logueado && (Session.esAdmin || Session.idUsuario == post.autorId);

  Future<void> _valorar(PostModel post, int estrellas) async {
    if (!Session.logueado) {
      mensaje(context, 'Inicia sesión para valorar publicaciones');
      return;
    }
    try {
      await _interacciones.valorar(post.id, estrellas);
      _huboCambios = true;
      if (mounted) _recargar();
    } catch (e) {
      if (mounted) mensaje(context, textoError(e));
    }
  }

  Future<void> _reaccionar(PostModel post, String emoji) async {
    if (!Session.logueado) {
      mensaje(context, 'Inicia sesión para reaccionar');
      return;
    }
    try {
      if (post.miReaccion == emoji) {
        await _interacciones.quitarReaccion(post.id);
      } else {
        await _interacciones.reaccionar(post.id, emoji);
      }
      if (mounted) _recargar();
    } catch (e) {
      if (mounted) mensaje(context, textoError(e));
    }
  }

  Future<void> _editar(PostModel post) async {
    final cambio = await Navigator.pushNamed(context, '/post-form', arguments: post);
    if (cambio == true) {
      _huboCambios = true;
      if (mounted) _recargar();
    }
  }

  Future<void> _eliminar(PostModel post) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar publicación',
      texto: '¿Deseas eliminar "${post.titulo}"? Esta acción no se puede deshacer.',
    );
    if (!ok) return;
    try {
      await _postService.eliminarPost(post.id);
      if (!mounted) return;
      mensaje(context, 'Publicación eliminada correctamente');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mensaje(context, 'No se pudo eliminar: ${textoError(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, resultado) {
        if (!didPop) Navigator.pop(context, _huboCambios);
      },
      child: Scaffold(
        body: FutureBuilder<PostModel>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  AppBar(title: const Text('Cargando...')),
                  const Expanded(child: Center(child: CircularProgressIndicator())),
                ],
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  AppBar(title: const Text('Publicación')),
                  Expanded(
                    child: ErrorVista(
                      texto: textoError(snapshot.error!),
                      onReintentar: _recargar,
                    ),
                  ),
                ],
              );
            }
            return _contenido(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _contenido(PostModel post) {
    final ancho = MediaQuery.of(context).size.width;
    final altoPortada = ancho > 800 ? 440.0 : 320.0;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: altoPortada,
          backgroundColor: AppColors.fondo,
          actions: [
            if (_puedeModificar(post)) ...[
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit),
                onPressed: () => _editar(post),
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _eliminar(post),
              ),
            ],
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            centerTitle: false,
            titlePadding: const EdgeInsetsDirectional.only(start: 56, end: 110, bottom: 16),
            title: Text(
              post.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                ImagenPost(url: post.imagen),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66000000), Color(0x000A1226), Color(0xFF0A1226)],
                      stops: [0.0, 0.35, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (post.categoriaNombre.isNotEmpty)
                                  PostTag(texto: post.categoriaNombre, destacada: true),
                                ...post.generos.map((g) => PostTag(texto: g.nombre)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              post.titulo,
                              style: AppText.titular(ancho > 800 ? 38 : 27).copyWith(
                                shadows: const [
                                  Shadow(blurRadius: 14, color: Color(0xAA000000)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Por ${post.autorNombre}  •  ${post.fechaCorta}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFC9D6F2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.tags.isNotEmpty) ...[
                      Text(
                        post.tags,
                        style: const TextStyle(
                          color: AppColors.azul,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      post.descripcion.isNotEmpty
                          ? post.descripcion
                          : 'Esta publicación no tiene descripción.',
                      style: const TextStyle(fontSize: 17, height: 1.7),
                    ),
                    const SizedBox(height: 28),
                    _panelValoracion(post),
                    const SizedBox(height: 16),
                    _panelReacciones(post),
                    const SizedBox(height: 28),
                    CommentSection(
                      blogId: post.id,
                      onCambio: () {
                        _huboCambios = true;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _panel({required Widget hijo}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borde),
      ),
      child: hijo,
    );
  }

  Widget _panelValoracion(PostModel post) {
    final hayNota = post.totalValoraciones > 0;
    return _panel(
      hijo: Row(
        children: [
          hayNota
              ? PuntuacionBadge(valor: post.promedio, tamano: 68)
              : Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.borde, width: 2),
                  ),
                  child: const Text('–',
                      style: TextStyle(fontSize: 26, color: AppColors.textoSuave)),
                ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NOTA DE LA COMUNIDAD', style: AppText.seccion),
                const SizedBox(height: 4),
                Text(
                  hayNota
                      ? '${post.totalValoraciones} ${post.totalValoraciones == 1 ? 'valoración' : 'valoraciones'}'
                      : 'Aún nadie la ha valorado',
                  style: AppText.meta,
                ),
                const SizedBox(height: 8),
                RatingStars(
                  valor: (post.miValoracion ?? post.promedio.round()).toDouble(),
                  tamano: 30,
                  onChanged: (n) => _valorar(post, n),
                ),
                if (post.miValoracion != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Tu valoración: ${post.miValoracion} de 5',
                        style: AppText.meta),
                  )
                else if (!Session.logueado)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Inicia sesión para valorar', style: AppText.meta),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelReacciones(PostModel post) {
    return _panel(
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿QUÉ TE PARECIÓ?', style: AppText.seccion),
          const SizedBox(height: 12),
          ReactionBar(
            conteos: post.reacciones,
            miReaccion: post.miReaccion,
            onTap: (emoji) => _reaccionar(post, emoji),
          ),
        ],
      ),
    );
  }
}
