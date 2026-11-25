import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../pelanggan/widgets/format.dart';
import 'models/padi_masuk.dart';

/// Buat PDF struk satu transaksi padi masuk (ukuran kertas A6).
/// Memakai font bawaan PDF, jadi teks dibatasi karakter ASCII.
Future<Uint8List> hasilkanPdfStrukPadiMasuk(PadiMasuk p) async {
  final dokumen = pw.Document(
    title: 'Struk ${p.nomorTransaksi}',
    author: 'Huller Abang',
  );

  pw.Widget baris(String label, String nilai, {bool tebal = false}) {
    final gaya = pw.TextStyle(
      fontSize: 11,
      fontWeight: tebal ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 82,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          ),
          pw.Expanded(child: pw.Text(nilai, style: gaya)),
        ],
      ),
    );
  }

  final garis = pw.Divider(thickness: 0.6, color: PdfColors.grey600);

  dokumen.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a6,
      margin: const pw.EdgeInsets.all(20),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              'HULLER ABANG',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Center(
            child: pw.Text(
              'Struk Padi Masuk',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          garis,
          baris('No. Transaksi', p.nomorTransaksi, tebal: true),
          baris('Tanggal', formatTanggal(p.tanggal)),
          baris('Pelanggan', p.pelangganNama.isEmpty ? '-' : p.pelangganNama),
          baris('Kelas padi', p.kelasNama.isEmpty ? '-' : p.kelasNama),
          garis,
          baris('Berat basah', formatKg(p.beratKg), tebal: true),
          if (p.catatan.isNotEmpty) baris('Catatan', p.catatan),
          garis,
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Terima kasih',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    ),
  );

  return dokumen.save();
}

/// Buka dialog cetak sistem untuk struk (di web membuka pratinjau cetak browser).
Future<void> cetakStrukPadiMasuk(PadiMasuk p) async {
  final bytes = await hasilkanPdfStrukPadiMasuk(p);
  await Printing.layoutPdf(
    name: p.nomorTransaksi,
    format: PdfPageFormat.a6,
    onLayout: (_) async => bytes,
  );
}
