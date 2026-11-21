import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/post_model.dart';
import 'imagen_post.dart';
import 'post_tag.dart';
import 'puntuacion_badge.dart';

/// Tarjeta de noticia para la cuadrícula del feed.
class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImagenPost(url: post.imagen),
                  if (post.categoriaNombre.isNotEmpty)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: PostTag(texto: post.categoriaNombre, destacada: true),
                    ),
                  if (post.totalValoraciones > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: PuntuacionBadge(valor: post.promedio, tamano: 38),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: AppColors.textoSuave,
                    ),
                  ),
                  if (post.generos.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      post.generos.map((g) => g.nombre).join(' / '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.azul,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${post.autorNombre}  •  ${post.fechaCorta}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.meta,
                        ),
                      ),
                      const Icon(Icons.chat_bubble_outline,
                          size: 14, color: AppColors.textoSuave),
                      const SizedBox(width: 4),
                      Text('${post.totalComentarios}', style: AppText.meta),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Noticia destacada: imagen a todo el ancho con el titular encima.
class PostHero extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const PostHero({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, caja) {
      final ancho = caja.maxWidth;
      final alto = ancho > 700 ? 380.0 : 280.0;
      return Material(
        color: AppColors.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borde),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: alto,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImagenPost(url: post.imagen),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x330A1226), Color(0xF20A1226)],
                      stops: [0.2, 0.55, 1.0],
                    ),
                  ),
                ),
                if (post.totalValoraciones > 0)
                  Positioned(
                    right: 16,
                    top: 16,
                    child: PuntuacionBadge(valor: post.promedio, tamano: 52),
                  ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
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
                          ...post.generos.take(3).map((g) => PostTag(texto: g.nombre)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        post.titulo,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.titular(ancho > 700 ? 34 : 24).copyWith(
                          shadows: const [Shadow(blurRadius: 12, color: Color(0xAA000000))],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${post.autorNombre}  •  ${post.fechaCorta}  •  ${post.totalComentarios} comentarios',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFFC9D6F2)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
