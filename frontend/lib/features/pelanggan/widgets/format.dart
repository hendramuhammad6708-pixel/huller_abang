/// Format kg gaya Indonesia: 18.650 kg, 783,75 kg.
String formatKg(double kg) {
  final fixed =
      kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${parts.length > 1 ? '$intPart,${parts[1]}' : intPart} kg';
}

String formatTerakhir(DateTime? date) {
  if (date == null) return 'Belum pernah giling';
  final today = DateTime.now();
  final days = DateTime(today.year, today.month, today.day)
      .difference(DateTime(date.year, date.month, date.day))
      .inDays;
  if (days == 0) return 'Giling hari ini';
  if (days == 1) return 'Giling kemarin';
  if (days < 30) return 'Giling $days hari lalu';
  return 'Giling ${days ~/ 30} bln lalu';
}
