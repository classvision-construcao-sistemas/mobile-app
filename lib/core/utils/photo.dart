import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart' show XFile;

/// Fotos tiradas pela câmera ou escolhidas no aparelho, em qualquer
/// plataforma. No Android, iOS e desktop o caminho é um arquivo local; no
/// Flutter Web é uma URL `blob:` do navegador, que não pode ser aberta com
/// `dart:io`. O `XFile` lê os dois casos.

/// Lê a foto em [path] e monta o campo multipart [field] para envio.
///
/// Lança [StateError] quando a foto não existe mais ou está vazia.
Future<http.MultipartFile> photoMultipart(String field, String path) async {
  final Uint8List bytes;
  final file = XFile(path);
  try {
    bytes = await file.readAsBytes();
  } catch (_) {
    throw StateError('A foto não está mais disponível.');
  }
  if (bytes.isEmpty) throw StateError('A foto está vazia.');
  final name = file.name.contains('.') ? file.name : 'foto.jpg';
  return http.MultipartFile.fromBytes(field, bytes, filename: name);
}

/// Pré-visualização da foto em [path] (arquivo local ou URL `blob:` na web).
Widget photoPreview(
  String path, {
  BoxFit fit = BoxFit.cover,
  ImageErrorWidgetBuilder? errorBuilder,
}) => kIsWeb
    ? Image.network(path, fit: fit, errorBuilder: errorBuilder)
    : Image.file(File(path), fit: fit, errorBuilder: errorBuilder);
