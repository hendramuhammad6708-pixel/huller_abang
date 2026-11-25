// Berbagi file PDF lewat Web Share API (hanya di web). Di platform lain
// fungsi ini mengembalikan false sehingga pemanggil memakai Printing.sharePdf.
export 'share_pdf_stub.dart' if (dart.library.js_interop) 'share_pdf_web.dart';
