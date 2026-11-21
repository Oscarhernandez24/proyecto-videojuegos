import 'package:flutter/material.dart';

import '../config/app_theme.dart';

import '../core/session.dart';
import '../core/ui.dart';
import '../models/comentario_model.dart';
import '../services/comentario_service.dart';
import 'error_vista.dart';

/// Sección de comentarios de una publicación: hilo con respuestas, like/dislike,
/// edición y eliminación según los permisos del usuario.
class CommentSection extends StatefulWidget {
  final int blogId;

  /// Se llama cuando cambia la cantidad de comentarios (para refrescar contadores).
  final VoidCallback? onCambio;

  const CommentSection({super.key, required this.blogId, this.onCambio});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final ComentarioService _servicio = ComentarioService();
  final TextEditingController _controller = TextEditingController();
  late Future<List<ComentarioModel>> _futuro;
  ComentarioModel? _respondiendoA;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.obtenerComentarios(widget.blogId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _futuro = _servicio.obtenerComentarios(widget.blogId);
    });
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) {
      mensaje(context, 'Escribe un comentario antes de enviarlo');
      return;
    }
    setState(() => _enviando = true);
    try {
      await _servicio.agregarComentario(
        widget.blogId,
        texto,
        parentId: _respondiendoA?.id,
      );
      if (!mounted) return;
      _controller.clear();
      FocusScope.of(context).unfocus();
      setState(() => _respondiendoA = null);
      _recargar();
      widget.onCambio?.call();
      mensaje(context, 'Comentario publicado');
    } catch (e) {
      if (mounted) mensaje(context, 'No se pudo comentar: ${textoError(e)}');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _votar(ComentarioModel c, int valor) async {
    if (!Session.logueado) {
      mensaje(context, 'Inicia sesión para votar comentarios');
      return;
    }
    try {
      await _servicio.votar(c.id, c.miVoto == valor ? 0 : valor);
      if (mounted) _recargar();
    } catch (e) {
      if (mounted) mensaje(context, textoError(e));
    }
  }

  Future<void> _editar(ComentarioModel c) async {
    final controller = TextEditingController(text: c.comentario);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar comentario'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (nuevo == null || nuevo.isEmpty || nuevo == c.comentario) return;
    try {
      await _servicio.editarComentario(c.id, nuevo);
      if (mounted) _recargar();
    } catch (e) {
      if (mounted) mensaje(context, textoError(e));
    }
  }

  Future<void> _eliminar(ComentarioModel c) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar comentario',
      texto: '¿Deseas eliminar este comentario? También se eliminarán sus respuestas.',
    );
    if (!ok) return;
    try {
      await _servicio.eliminarComentario(c.id);
      if (!mounted) return;
      _recargar();
      widget.onCambio?.call();
    } catch (e) {
      if (mounted) mensaje(context, textoError(e));
    }
  }

  List<Widget> _hilo(List<ComentarioModel> todos, int? padreId, int nivel) {
    final hijos = todos.where((c) => c.parentId == padreId).toList();
    return hijos
        .expand((c) => [
              _tarjeta(c, nivel),
              ..._hilo(todos, c.id, nivel < 3 ? nivel + 1 : nivel),
            ])
        .toList();
  }

  Widget _tarjeta(ComentarioModel c, int nivel) {
    final esMio = Session.idUsuario == c.usuarioId;
    return Padding(
      padding: EdgeInsets.only(left: nivel * 20.0, bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.superficie,
          border: Border(
            left: BorderSide(
              color: nivel > 0 ? AppColors.azul : AppColors.borde,
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.nombreUsuario,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(c.fechaCorta,
                      style: const TextStyle(fontSize: 11, color: AppColors.textoSuave)),
                ],
              ),
              const SizedBox(height: 6),
              Text(c.comentario),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Me gusta',
                    icon: Icon(
                      c.miVoto == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 18,
                    ),
                    onPressed: () => _votar(c, 1),
                  ),
                  Text('${c.likes}'),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'No me gusta',
                    icon: Icon(
                      c.miVoto == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
                      size: 18,
                    ),
                    onPressed: () => _votar(c, -1),
                  ),
                  Text('${c.dislikes}'),
                  if (Session.logueado)
                    TextButton(
                      onPressed: () => setState(() => _respondiendoA = c),
                      child: const Text('Responder'),
                    ),
                  if (esMio)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _editar(c),
                    ),
                  if (esMio || Session.esAdmin)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _eliminar(c),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 18, color: AppColors.naranja),
            const SizedBox(width: 10),
            const Text('COMENTARIOS', style: AppText.seccion),
          ],
        ),
        const SizedBox(height: 12),
        if (Session.logueado) ...[
          if (_respondiendoA != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Respondiendo a ${_respondiendoA!.nombreUsuario}',
                      style: const TextStyle(color: AppColors.textoSuave),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _respondiendoA = null),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un comentario...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Enviar',
                onPressed: _enviando ? null : _enviar,
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ] else
          const Text(
            'Inicia sesión para comentar y reaccionar.',
            style: TextStyle(color: AppColors.textoSuave),
          ),
        const SizedBox(height: 16),
        FutureBuilder<List<ComentarioModel>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 160,
                child: ErrorVista(
                  texto: textoError(snapshot.error!),
                  onReintentar: _recargar,
                ),
              );
            }
            final comentarios = snapshot.data ?? [];
            if (comentarios.isEmpty) {
              return const Text(
                'Aún no hay comentarios. ¡Sé el primero!',
                style: TextStyle(color: AppColors.textoSuave),
              );
            }
            return Column(children: _hilo(comentarios, null, 0));
          },
        ),
      ],
    );
  }
}
