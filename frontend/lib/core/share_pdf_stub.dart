import 'dart:typed_data';

/// Platform non-web: Web Share tidak tersedia, pemanggil memakai cara lain.
Future<bool> bagikanPdfLewatWebShare({
  required Uint8List bytes,
  required String fileName,
  required String text,
}) async => false;
