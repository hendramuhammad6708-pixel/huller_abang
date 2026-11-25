/// Format kg gaya Indonesia: 18.650 kg, 783,75 kg.
String formatKg(double kg) {
  final fixed = kg == kg.roundToDouble()
      ? kg.toStringAsFixed(0)
      : kg.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${parts.length > 1 ? '$intPart,${parts[1]}' : intPart} kg';
}

/// Persen susut gaya Indonesia dengan koma desimal dan tanda %: 20,0%.
/// (Bukan `formatPersen` di pengaturan, yang tanpa tanda % untuk isian angka.)
String formatPersenSusut(double nilai, {int desimal = 1}) =>
    '${nilai.toStringAsFixed(desimal).replaceAll('.', ',')}%';

String formatTerakhir(
  DateTime? date, {
  String status = '',
  String statusLabel = '',
}) {
  if (date == null) return 'Belum ada transaksi';
  final today = DateTime.now();
  final days = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(date.year, date.month, date.day)).inDays;
  final aman = days < 0 ? 0 : days;
  final label = statusLabel.trim().isEmpty ? status : statusLabel.trim();

  switch (status) {
    case 'dijemur':
      return aman == 0
          ? 'Sedang Dijemur hari ini'
          : 'Sedang Dijemur $aman hari';
    case 'siap_giling':
      return aman == 0 ? 'Siap Giling hari ini' : 'Siap Giling $aman hari';
    case 'selesai_giling':
      return _formatGiling(aman);
    case 'void':
      return 'Dibatalkan ${_hariLalu(aman)}';
    case 'masuk':
      return 'Masuk ${_hariLalu(aman)}';
    default:
      return label.isEmpty ? _formatGiling(aman) : '$label ${_hariLalu(aman)}';
  }
}

String _formatGiling(int days) {
  if (days == 0) return 'Giling hari ini';
  if (days == 1) return 'Giling kemarin';
  if (days < 30) return 'Giling $days hari lalu';
  return 'Giling ${days ~/ 30} bln lalu';
}

String _hariLalu(int days) {
  if (days == 0) return 'hari ini';
  if (days == 1) return 'kemarin';
  if (days < 30) return '$days hari lalu';
  return '${days ~/ 30} bln lalu';
}
