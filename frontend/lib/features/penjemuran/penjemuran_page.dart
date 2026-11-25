import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/ui.dart';
import '../pelanggan/widgets/format.dart';
import '../penggilingan/models/padi_masuk.dart' show formatTanggal;
import '../widgets/status_badge.dart';
import 'penjemuran_model.dart';
import 'penjemuran_service.dart';

// Memakai pemformat bersama (sama dengan halaman lain): "25 Nov 2026",
// "1.250,5 kg", dan koma desimal pada persen.
String _tgl(DateTime? d) => d == null ? '-' : formatTanggal(d);
String _kg(num? n) => n == null ? '-' : formatKg(n.toDouble());

class PenjemuranPage extends StatefulWidget {
  final PenjemuranService? service;
  const PenjemuranPage({super.key, this.service});

  @override
  State<PenjemuranPage> createState() => _PenjemuranPageState();
}

class _PenjemuranPageState extends State<PenjemuranPage> {
  late final PenjemuranService _service = widget.service ?? PenjemuranService();
  List<Penjemuran> _data = [];
  StatusPenjemuran? _filter;
  DateTimeRange? _rentang;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String? status;
      if (_filter == StatusPenjemuran.masuk) status = 'masuk';
      if (_filter == StatusPenjemuran.dijemur) status = 'dijemur';
      if (_filter == StatusPenjemuran.siapGiling) status = 'siap_giling';

      final d = await _service.ambilSemua(
        status: status,
        tanggalDari: _rentang?.start,
        tanggalSampai: _rentang?.end,
      );
      if (!mounted) return;
      setState(() => _data = d);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String pesan, {bool galat = false}) {
    if (!mounted) return;
    tampilkanPesan(context, pesan, galat: galat);
  }

  Future<void> _mulai(Penjemuran p) async {
    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final tanggal = await showDatePicker(
      context: context,
      initialDate: hariIni,
      firstDate: p.tanggalMasuk,
      // Server menolak tanggal di masa depan
      lastDate: hariIni,
      helpText: 'Tanggal mulai jemur',
    );
    if (tanggal == null) return;
    try {
      await _service.mulai(p.id, tanggal);
      _snack('Penjemuran dimulai');
      _muat();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), galat: true);
    }
  }

  Future<void> _selesai(Penjemuran p) async {
    final hasil = await showModalBottomSheet<_HasilJemur>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormSelesai(item: p),
    );
    if (hasil == null) return;
    try {
      await _service.selesai(p.id, hasil.tanggal, hasil.beratKering);
      _snack('Hasil jemur disimpan. Padi siap digiling');
      _muat();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), galat: true);
    }
  }

  Future<void> _pilihRentang() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _rentang,
    );
    if (picked != null) {
      setState(() => _rentang = picked);
      await _muat();
    }
  }

  Future<void> _selesaiGiling(Penjemuran p) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('dialog-selesai-giling'),
        title: const Text('Padi sudah selesai digiling?'),
        content: Text(
          '${p.pelanggan} · ${_kg(p.beratBasah)} basah. Setelah ini padi hilang '
          'dari daftar penjemuran dan transaksinya tidak bisa dibatalkan lagi.',
          style: const TextStyle(color: AppColors.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Belum'),
          ),
          FilledButton(
            key: const Key('btn-ya-selesai-giling'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, selesai'),
          ),
        ],
      ),
    );
    if (ya != true) return;
    try {
      await _service.selesaiGiling(p.id);
      _snack('Penggilingan selesai. Tercatat di riwayat padi masuk');
      _muat();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), galat: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jumlah per status hanya akurat saat tidak ada filter status (data lengkap)
    int jumlah(StatusPenjemuran s) => _data.where((e) => e.status == s).length;
    String label(StatusPenjemuran s) => _filter == null && !_loading
        ? '${labelStatus(s)} (${jumlah(s)})'
        : labelStatus(s);

    return Scaffold(
      body: Column(
        children: [
          // Satu baris filter (dulu dua baris tombol besar): chip status yang bisa
          // digeser, dan ikon tanggal yang disematkan di kanan supaya tetap
          // terlihat di layar sempit (tidak ikut tergeser keluar layar).
          SizedBox(
            height: 56,
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 8, 4, 8),
                    children: [
                      _chip('Semua', _filter == null, () async {
                        setState(() => _filter = null);
                        await _muat();
                      }),
                      for (final s in StatusPenjemuran.values)
                        _chip(label(s), _filter == s, () async {
                          setState(() => _filter = s);
                          await _muat();
                        }),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('filter-tanggal-penjemuran'),
                  tooltip: 'Filter tanggal masuk',
                  onPressed: _pilihRentang,
                  style: IconButton.styleFrom(
                    backgroundColor: _rentang == null ? null : AppColors.mint,
                  ),
                  icon: Icon(
                    Icons.date_range_rounded,
                    color: _rentang == null
                        ? AppColors.textMuted
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          // Rentang aktif tampil sebagai chip yang bisa dihapus (hanya saat aktif)
          if (_rentang != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  key: const Key('filter-tanggal-aktif'),
                  avatar: const Icon(Icons.event_rounded, size: 18),
                  label: Text(
                    'Masuk ${_tgl(_rentang!.start)} – ${_tgl(_rentang!.end)}',
                  ),
                  onPressed: _pilihRentang,
                  onDeleted: () async {
                    setState(() => _rentang = null);
                    await _muat();
                  },
                ),
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isi(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => onTap(),
    ),
  );

  Widget _isi() {
    if (_loading) {
      return ListView(
        key: const ValueKey('memuat'),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: const [
          SkeletonKartu(baris: 4),
          SizedBox(height: 12),
          SkeletonKartu(baris: 5),
          SizedBox(height: 12),
          SkeletonKartu(baris: 3),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        key: const ValueKey('galat'),
        padding: const EdgeInsets.all(20),
        children: [BannerGalat(_error!, onUlangi: _muat)],
      );
    }
    if (_data.isEmpty) {
      final adaFilter = _filter != null || _rentang != null;
      return Center(
        child: KeadaanKosong(
          icon: Icons.wb_sunny_outlined,
          judul: adaFilter ? 'Tidak ada hasil' : 'Belum ada padi masuk',
          pesan: adaFilter
              ? 'Tidak ada padi yang cocok dengan filter ini.'
              : 'Catat dulu padi masuk di tab Padi Masuk, lalu mulai penjemurannya di sini.',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView.builder(
        key: const ValueKey('data'),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: _data.length,
        itemBuilder: (_, i) => _kartu(_data[i]),
      ),
    );
  }

  Widget _kartu(Penjemuran p) {
    final durasi = p.durasiHari;
    final terlaluLama = p.terlaluLama;
    final singkat =
        p.status == StatusPenjemuran.siapGiling &&
        durasi != null &&
        durasi < minHariJemur;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: KartuApp(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.pelanggan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: nilaiApi(p.status)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${p.kelas} · masuk ${_tgl(p.tanggalMasuk)}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
            const Divider(height: 20),
            _baris('Berat basah', _kg(p.beratBasah)),
            _baris(
              'Mulai - selesai',
              '${_tgl(p.tanggalMulai)} - ${_tgl(p.tanggalSelesai)}',
            ),
            _baris('Durasi', durasi == null ? '-' : '$durasi hari'),
            if (terlaluLama)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Lencana(
                    'Terlalu Lama',
                    key: Key('peringatan-terlalu-lama-${p.id}'),
                    latar: AppColors.dangerSoft,
                    warna: AppColors.danger,
                  ),
                ),
              ),
            _baris('Berat kering', _kg(p.beratKering)),
            _baris(
              'Susut',
              p.persenSusut == null ? '-' : formatPersenSusut(p.persenSusut!),
            ),
            if (singkat) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Durasi jemur kurang dari $minHariJemur hari',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Belum 2 hari dijemur: tidak bisa diselesaikan, jelaskan sampai kapan
            if (p.status == StatusPenjemuran.dijemur &&
                !p.bolehDiselesaikan) ...[
              const SizedBox(height: 8),
              Row(
                key: Key('info-belum-bisa-selesai-${p.id}'),
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Belum bisa diselesaikan: minimal $minHariJemur hari '
                      'jemur. Paling cepat ${_tgl(p.tanggalPalingCepatSelesai)}.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Langkah terakhir alur: dari Siap Giling ke Selesai Giling
            if (p.status == StatusPenjemuran.siapGiling) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: Key('btn-selesai-giling-${p.id}'),
                  onPressed: () => _selesaiGiling(p),
                  icon: const Icon(Icons.task_alt_rounded, size: 20),
                  label: const Text('Selesai digiling'),
                ),
              ),
            ],
            if (p.status != StatusPenjemuran.siapGiling) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: p.status == StatusPenjemuran.masuk
                    ? FilledButton.icon(
                        onPressed: () => _mulai(p),
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text('Mulai jemur'),
                      )
                    : FilledButton.icon(
                        key: Key('btn-selesaikan-${p.id}'),
                        onPressed: p.bolehDiselesaikan
                            ? () => _selesai(p)
                            : null,
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text('Selesaikan'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _baris(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          k,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HasilJemur {
  final DateTime tanggal;
  final double beratKering;
  _HasilJemur(this.tanggal, this.beratKering);
}

class _FormSelesai extends StatefulWidget {
  final Penjemuran item;
  const _FormSelesai({required this.item});

  @override
  State<_FormSelesai> createState() => _FormSelesaiState();
}

class _FormSelesaiState extends State<_FormSelesai> {
  final _key = GlobalKey<FormState>();
  final _kering = TextEditingController();

  static DateTime _hari(DateTime d) => DateTime(d.year, d.month, d.day);

  // Tanggal selesai paling cepat = mulai + minHariJemur hari; paling lambat hari ini
  late final DateTime _paling = _hari(
    p.tanggalPalingCepatSelesai ??
        _hari(p.tanggalMulai!).add(const Duration(days: minHariJemur)),
  );
  late DateTime _selesai = _hari(DateTime.now()).isBefore(_paling)
      ? _paling
      : _hari(DateTime.now());

  Penjemuran get p => widget.item;
  double? get _k => double.tryParse(_kering.text.replaceAll(',', '.'));
  int get _durasi {
    final hari = DateTime(_selesai.year, _selesai.month, _selesai.day)
        .difference(
          DateTime(
            p.tanggalMulai!.year,
            p.tanggalMulai!.month,
            p.tanggalMulai!.day,
          ),
        )
        .inDays;
    return hari < 0 ? 0 : hari;
  }

  Future<void> _pilihTanggal() async {
    final t = await showDatePicker(
      context: context,
      initialDate: _selesai,
      firstDate: _paling,
      // Server menolak tanggal di masa depan
      lastDate: _hari(DateTime.now()).isBefore(_paling)
          ? _paling
          : _hari(DateTime.now()),
      helpText: 'Tanggal selesai (minimal $minHariJemur hari jemur)',
    );
    if (t != null) {
      setState(() => _selesai = t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final susut = hitungSusut(p.beratBasah, _k);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selesaikan penjemuran',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${p.pelanggan} · ${p.kelas} · basah ${_kg(p.beratBasah)}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pilihTanggal,
              icon: const Icon(Icons.event, size: 18),
              label: Text('Tanggal selesai: ${_tgl(_selesai)}'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kering,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Berat kering (kg)',
                helperText: 'Tidak boleh melebihi berat basah',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final k = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (k == null || k <= 0) {
                  return 'Berat kering wajib diisi dan lebih dari 0';
                }
                if (k > p.beratBasah) {
                  return 'Tidak boleh melebihi berat basah (${_kg(p.beratBasah)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Durasi: $_durasi hari   ·   Susut: ${susut == null ? '-' : formatPersenSusut(susut)}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            if (_durasi > batasDurasiTerlaluLama) ...[
              const SizedBox(height: 10),
              Lencana(
                'Terlalu Lama',
                key: const Key('peringatan-terlalu-lama-form'),
                latar: AppColors.dangerSoft,
                warna: AppColors.danger,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  // Pengaman: tanggal selalu >= mulai + minHariJemur lewat pemilih tanggal
                  onPressed: _durasi < minHariJemur
                      ? null
                      : () {
                          if (_key.currentState!.validate()) {
                            Navigator.pop(context, _HasilJemur(_selesai, _k!));
                          }
                        },
                  child: const Text('Simpan hasil jemur'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _kering.dispose();
    super.dispose();
  }
}
