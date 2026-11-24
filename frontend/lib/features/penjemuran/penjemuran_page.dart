import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/ui.dart';
import '../widgets/peringatan_card.dart';
import '../widgets/status_badge.dart';
import 'penjemuran_model.dart';
import 'penjemuran_service.dart';

const int minHariJemur = 2; // peringatan jika jemur < 2 hari

String _tgl(DateTime? d) => d == null
    ? '-'
    : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _kg(num? n) =>
    n == null ? '-' : '${n.toStringAsFixed(n % 1 == 0 ? 0 : 2)} kg';

class PenjemuranPage extends StatefulWidget {
  final PenjemuranService? service;
  const PenjemuranPage({super.key, this.service});

  @override
  State<PenjemuranPage> createState() => _PenjemuranPageState();
}

class _PenjemuranPageState extends State<PenjemuranPage> {
  late final PenjemuranService _service = widget.service ?? PenjemuranService();
  List<Penjemuran> _data = [];
  final List<Map<String, dynamic>> _daftarPelanggan = [];
  StatusPenjemuran? _filter;
  int? _pelangganId;
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
        pelangganId: _pelangganId,
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
    final tanggal = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: p.tanggalMasuk,
      lastDate: DateTime.now().add(const Duration(days: 1)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                _chip('Semua', _filter == null, () async {
                  setState(() => _filter = null);
                  await _muat();
                }),
                for (final s in StatusPenjemuran.values)
                  _chip(labelStatus(s), _filter == s, () async {
                    setState(() => _filter = s);
                    await _muat();
                  }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      _rentang == null
                          ? 'Tanggal'
                          : '${_tgl(_rentang!.start)} - ${_tgl(_rentang!.end)}',
                    ),
                    onPressed: () async {
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
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PopupMenuButton<int?>(
                    onSelected: (v) async {
                      setState(() => _pelangganId = v);
                      await _muat();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('Semua pelanggan'),
                      ),
                      for (final p in _daftarPelanggan)
                        if (p['id'] != null)
                          PopupMenuItem(
                            value: p['id'] as int,
                            child: Text(p['nama']?.toString() ?? '-'),
                          ),
                    ],
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_outline_rounded, size: 18),
                      onPressed: () {},
                      label: Text(
                        _pelangganId == null
                            ? 'Pelanggan'
                            : _daftarPelanggan
                                      .where((e) => e['id'] == _pelangganId)
                                      .map((e) => e['nama']?.toString() ?? '-')
                                      .firstOrNull ??
                                  'Pelanggan',
                      ),
                    ),
                  ),
                ),
                if (_filter != null || _pelangganId != null || _rentang != null)
                  IconButton(
                    tooltip: 'Reset filter',
                    onPressed: () async {
                      setState(() {
                        _filter = null;
                        _pelangganId = null;
                        _rentang = null;
                      });
                      await _muat();
                    },
                    icon: const Icon(Icons.close),
                  ),
              ],
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
      return Center(
        child: KeadaanKosong(
          icon: Icons.wb_sunny_outlined,
          judul: _filter == null ? 'Belum ada padi masuk' : 'Tidak ada hasil',
          pesan: _filter == null
              ? 'Catat dulu padi masuk di tab Padi Masuk, lalu mulai penjemurannya di sini.'
              : 'Tidak ada padi berstatus ${labelStatus(_filter!)}.',
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
              p.persenSusut == null
                  ? '-'
                  : '${p.persenSusut!.toStringAsFixed(1)}%',
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
                        onPressed: () => _selesai(p),
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
  DateTime _selesai = DateTime.now();

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
      firstDate: p.tanggalMulai!,
      lastDate: DateTime.now().add(const Duration(days: 1)),
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
              'Durasi: $_durasi hari   ·   Susut: ${susut == null ? '-' : '${susut.toStringAsFixed(1)}%'}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            if (_durasi < minHariJemur) ...[
              const SizedBox(height: 10),
              const PeringatanCard(
                judul: 'Durasi jemur kurang dari $minHariJemur hari',
                pesan:
                    'Padi mungkin belum cukup kering, tapi tetap bisa disimpan.',
              ),
            ],
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
                  onPressed: () {
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
