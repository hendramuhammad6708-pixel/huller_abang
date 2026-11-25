import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Bagikan PDF lewat Web Share API (di HP membuka pilihan aplikasi, mis. WhatsApp).
/// Mengembalikan true bila dialog berbagi tampil (termasuk bila dibatalkan
/// pengguna) dan false bila browser tidak mendukung berbagi file, supaya
/// pemanggil bisa beralih ke unduh manual.
Future<bool> bagikanPdfLewatWebShare({
  required Uint8List bytes,
  required String fileName,
  required String text,
}) async {
  try {
    final berkas = web.File(
      <JSAny>[bytes.toJS].toJS,
      fileName,
      web.FilePropertyBag(type: 'application/pdf'),
    );
    final data = web.ShareData(
      files: <web.File>[berkas].toJS,
      title: fileName,
      text: text,
    );
    if (!web.window.navigator.canShare(data)) return false;
    await web.window.navigator.share(data).toDart;
    return true;
  } catch (e) {
    // Pengguna menutup dialog berbagi: jangan lanjut ke cara lain
    return e.toString().contains('AbortError');
  }
}
