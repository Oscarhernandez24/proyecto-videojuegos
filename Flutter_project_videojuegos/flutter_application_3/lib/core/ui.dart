import 'package:flutter/material.dart';

import 'api_client.dart';

/// Texto legible para cualquier error capturado.
String textoError(Object e) =>
    e is ApiException ? e.mensaje : e.toString().replaceFirst('Exception: ', '');

void mensaje(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}

/// Pide confirmación antes de una acción destructiva. Devuelve true si el usuario acepta.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String texto,
  String botonAceptar = 'Eliminar',
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(botonAceptar),
        ),
      ],
    ),
  );
  return resultado == true;
}
