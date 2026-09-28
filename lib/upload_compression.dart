import 'dart:io' show File;

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// A file ready to upload: either bytes (compressed in memory) or a path to
/// send as-is (formats that are already compressed, such as .xlsx and .pdf).
class PreparedUpload {
  const PreparedUpload({
    required this.name,
    this.bytes,
    this.path,
    required this.originalSize,
    required this.size,
  });

  final String name;
  final Uint8List? bytes;
  final String? path;
  final int originalSize;
  final int size;

  bool get compressed => size < originalSize;
}

/// Longest side for BOQ photos: matches the server and stays readable.
const scanMaxSide = 2400;

/// Text files smaller than this are sent as they are.
const _gzipThreshold = 16 * 1024;

const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'};
const _textExtensions = {'csv', 'tsv', 'txt'};

String _extensionOf(String name) {
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

String _baseName(String name) {
  final dot = name.lastIndexOf('.');
  return dot <= 0 ? name : name.substring(0, dot);
}

/// Compresses photos (resize + JPEG) and text files (gzip) before upload so
/// they upload faster; the server unpacks and stores them compactly.
/// Spreadsheets and PDFs are already compressed and are returned unchanged.
Future<PreparedUpload> prepareUpload({
  required String name,
  String? path,
  Uint8List? bytes,
  int maxImageSide = scanMaxSide,
}) async {
  final extension = _extensionOf(name);
  final compressible =
      _imageExtensions.contains(extension) ||
      _textExtensions.contains(extension);

  if (!compressible) {
    final size =
        bytes?.length ?? (path != null ? await File(path).length() : 0);
    return PreparedUpload(
      name: name,
      bytes: path == null ? bytes : null,
      path: path,
      originalSize: size,
      size: size,
    );
  }

  final data = bytes ?? await File(path!).readAsBytes();
  final result = await compute(
    _compress,
    _CompressRequest(name, extension, data, maxImageSide),
  );
  return result;
}

class _CompressRequest {
  const _CompressRequest(this.name, this.extension, this.data, this.maxSide);
  final String name;
  final String extension;
  final Uint8List data;
  final int maxSide;
}

PreparedUpload _compress(_CompressRequest request) {
  final data = request.data;
  final unchanged = PreparedUpload(
    name: request.name,
    bytes: data,
    originalSize: data.length,
    size: data.length,
  );

  try {
    if (_textExtensions.contains(request.extension)) {
      if (data.length < _gzipThreshold) return unchanged;
      final gz = GZipEncoder().encodeBytes(data, level: 9);
      if (gz.length >= data.length) return unchanged;
      return PreparedUpload(
        name: '${request.name}.gz',
        bytes: gz,
        originalSize: data.length,
        size: gz.length,
      );
    }

    final decoded = img.decodeImage(data);
    if (decoded == null) return unchanged;
    var image = img.bakeOrientation(decoded);
    final longest = image.width > image.height ? image.width : image.height;
    if (longest > request.maxSide) {
      image = image.width >= image.height
          ? img.copyResize(image, width: request.maxSide)
          : img.copyResize(image, height: request.maxSide);
    }
    final jpg = img.encodeJpg(image, quality: 80);
    if (jpg.length >= data.length) return unchanged;
    return PreparedUpload(
      name: '${_baseName(request.name)}.jpg',
      bytes: jpg,
      originalSize: data.length,
      size: jpg.length,
    );
  } on Object {
    return unchanged; // never block an upload because compression failed
  }
}

/// "2.4 MB → 380 KB"
String describeCompression(PreparedUpload upload) {
  String human(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
    return '$bytes B';
  }

  return '${human(upload.originalSize)} → ${human(upload.size)}';
}
