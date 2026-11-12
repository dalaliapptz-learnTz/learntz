import 'dart:typed_data';

import 'package:crypto/crypto.dart';

abstract final class CurriculumDocumentFile {
  static const maxBytes = 25 * 1024 * 1024;
  static const contentTypes = {
    'pdf': 'application/pdf',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xlsx':
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'csv': 'text/csv',
    'json': 'application/json',
  };

  static String checksum(Uint8List bytes) => sha256.convert(bytes).toString();

  static String? contentTypeForFilename(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return contentTypes[extension];
  }

  static void validate({
    required Uint8List bytes,
    required String filename,
    required String expectedContentType,
  }) {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const FormatException(
        'The document size must be between 1 byte and 25 MB.',
      );
    }
    if (contentTypeForFilename(filename) != expectedContentType) {
      throw const FormatException(
        'The selected file extension does not match the reviewed document format.',
      );
    }
    if (filename.length > 255 ||
        filename.contains('/') ||
        filename.contains('\\') ||
        filename.runes.any((rune) => rune < 32)) {
      throw const FormatException('The selected filename is invalid.');
    }
  }
}
