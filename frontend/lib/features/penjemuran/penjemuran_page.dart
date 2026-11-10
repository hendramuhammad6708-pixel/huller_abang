import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/ui.dart';
import '../pelanggan/models/pelanggan.dart';
import '../pelanggan/pelanggan_controller.dart';
import '../pelanggan/widgets/format.dart';
import 'penjemuran_model.dart';
import 'penjemuran_service.dart';

const int minHariJemur = 2; // peringatan jika jemur < 2 hari

class PenjemuranPage extends StatefulWidget {
  final PenjemuranService? service;
  final PelangganController? pelanggan;

  const PenjemuranPage({super.key, this.service, this.pelanggan});

  @override
  State<PenjemuranPage> createState() => _PenjemuranPageState();
}

class _PenjemuranPageState extends State<PenjemuranPage> {
  late final PenjemuranService _service = widget.service ?? PenjemuranService();
  List<Penjemuran> _data = [];
  StatusPenjemuran? _filter;
  int? _pelangganId;
  DateTimeRange? _rentang;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.pelanggan?.addListener(_perbaruiPelanggan);
    widget.pelanggan?.muat();
    _muat();
  }

  @override
  void dispose() {
    widget.pelanggan?.removeListener(_perbaruiPelanggan);
    super.dispose();
  }

  void _perbaruiPelanggan() {
    if (mounted) setState(() {});
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _service.ambilSemua(
        status: switch (_filter) {
          StatusPenjemuran.masuk => 'masuk',
          StatusPenjemuran.dijemur => 'dijemur',
          StatusPenjemuran.siapGiling => 'siap_giling',
          null => null,
        },
        pelangganId: _pelangganId,
        tanggalDari: _rentang?.start,
        tanggalSampai: _rentang?.end,
      );
      if (!mounted) return;
      setState(() => _data = d);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _pesanGalat(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _pesanGalat(Object e) {
    final pesan = e.toString().replaceFirst('Exception: ', '');
    if (pesan.contains('404')) {
      return 'Data penjemuran belum tersedia di server.';
    }
    return pesan.isEmpty ? 'Gagal memuat penjemuran.' : pesan;
  }

  void _pesan(String msg, {bool galat = false}) =>
      tampilkanPesan(context, msg, galat: galat);

  Future<void> _mulai(Penjemuran p) async {
    final tanggal = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: p.tanggalMasuk,
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Tanggal mulai jemur',
    );
    if (tanggal == null || !mounted) return;
    try {
      await _service.mulai(p.id, tanggal);
      if (!mounted) return;
      _pesan('Penjemuran ${p.pelanggan} dimulai');
      await _muat();
    } catch (e) {
      if (mounted) _pesan(_pesanGalat(e), galat: true);
    }
  }

  Future<void> _selesai(Penjemuran p) async {
    final hasil = await showModalBottomSheet<_HasilJemur>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormSelesai(item: p),
    );
    if (hasil == null || !mounted) return;
    try {
      await _service.selesai(p.id, hasil.tanggal, hasil.beratKering);
      if (!mounted) return;
      _pesan('Hasil jemur disimpan. Padi siap digiling');
      await _muat();
    } catch (e) {
      if (mounted) _pesan(_pesanGalat(e), galat: true);
    }
  }

  Future<void> _pilihRentang() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _rentang,
      helpText: 'Pilih rentang tanggal',
    );
    if (picked == null || !mounted) return;
    setState(() => _rentang = picked);
    await _muat();
  }

  void _resetFilter() {
    setState(() {
      _filter = null;
      _pelangganId = null;
      _rentang = null;
    });
    _muat();
  }

  bool get _adaFilter =>
      _filter != null || _pelangganId != null || _rentang != null;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, batas) => RefreshIndicator(
        onRefresh: _muat,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                jarakSamping(batas.maxWidth),
                4,
                jarakSamping(batas.maxWidth),
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ringkasan(),
                  const SizedBox(height: 16),
                  _filterBar(),
                  const SizedBox(height: 14),
                ]),
              ),
            ),
            if (_loading && _data.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  jarakSamping(batas.maxWidth),
                  0,
                  jarakSamping(batas.maxWidth),
                  32,
                ),
                sliver: SliverToBoxAdapter(
                  child: BannerGalat(_error!, onUlangi: _muat),
                ),
              )
            else if (_data.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _adaFilter
                    ? const KeadaanKosong(
                        icon: Icons.filter_alt_off_rounded,
                        judul: 'Tidak ada penjemuran',
                        pesan: 'Tidak ada data untuk filter yang dipilih.',
                      )
                    : const KeadaanKosong(
                        icon: Icons.wb_sunny_outlined,
                        judul: 'Belum ada penjemuran',
                        pesan:
                            'Catat padi masuk terlebih dahulu, lalu mulai '
                            'penjemuran dari sini.',
                      ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  jarakSamping(batas.maxWidth),
                  0,
                  jarakSamping(batas.maxWidth),
                  32,
                ),
                sliver: SliverList.separated(
                  itemCount: _data.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _kartu(_data[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _ringkasan() {
    final totalKg = _data.fold<double>(0, (j, e) => j + e.beratBasah);
    final dijemur = _data
        .where((e) => e.status == StatusPenjemuran.dijemur)
        .length;
    final siap = _data
        .where((e) => e.status == StatusPenjemuran.siapGiling)
        .length;

    return PanelHero(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _adaFilter ? 'Penjemuran (terfilter)' : 'Total padi dijemur',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatKg(totalKg),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_data.length} catatan',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.aksen,
              borderRadius: BorderRadius.circular(AppRadius.sedang),
            ),
            child: Column(
              children: [
                Text(
                  '$dijemur',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const Text(
                  'dijemur',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$siap siap giling',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    final pelanggan = widget.pelanggan?.items ?? const <Pelanggan>[];
    final adaPelanggan = pelanggan.any((p) => p.id != null);
    final idValid = pelanggan.any((p) => p.id == _pelangganId);

    return KartuApp(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _filter == null,
                  onSelected: (_) {
                    setState(() => _filter = null);
                    _muat();
                  },
                ),
                for (final s in StatusPenjemuran.values) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(labelStatus(s)),
                    selected: _filter == s,
                    onSelected: (_) {
                      setState(() => _filter = s);
                      _muat();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pilihRentang,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.date_range_rounded, size: 19),
                  label: Text(
                    _rentang == null
                        ? 'Tanggal'
                        : '${_tgl(_rentang!.start)} - '
                              '${_tgl(_rentang!.end)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  key: ValueKey(
                    'filter-pelanggan-penjemuran-${idValid ? _pelangganId : 'semua'}',
                  ),
                  initialValue: idValid ? _pelangganId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  hint: const Text('Pelanggan'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Semua pelanggan'),
                    ),
                    for (final p in pelanggan)
                      if (p.id != null)
                        DropdownMenuItem<int?>(
                          value: p.id,
                          child: Text(p.nama, overflow: TextOverflow.ellipsis),
                        ),
                  ],
                  onChanged: adaPelanggan
                      ? (v) {
                          setState(() => _pelangganId = v);
                          _muat();
                        }
                      : null,
                ),
              ),
            ],
          ),
          if (_adaFilter)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _resetFilter,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: const Text('Hapus filter'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kartu(Penjemuran p) {
    final durasi = p.durasiHari;
    final singkat =
        p.status == StatusPenjemuran.siapGiling &&
        durasi != null &&
        durasi < minHariJemur;

    return KartuApp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.pelanggan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${p.kelas} - masuk ${_tgl(p.tanggalMasuk)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(status: p.status),
            ],
          ),
          const SizedBox(height: 16),
          _AlurStatus(status: p.status),
          const Divider(height: 24),
          _baris('Berat basah', formatKg(p.beratBasah)),
          _baris(
            'Mulai - selesai',
            '${_tgl(p.tanggalMulai)} - ${_tgl(p.tanggalSelesai)}',
          ),
          _baris(
            'Durasi',
            durasi == null
                ? '-'
                : '$durasi hari${singkat ? ' (kurang dari $minHariJemur hari)' : ''}',
            peringatan: singkat,
          ),
          _baris(
            'Berat kering',
            p.beratKering == null ? '-' : formatKg(p.beratKering!),
          ),
          _baris(
            'Susut',
            p.persenSusut == null
                ? '-'
                : '${p.persenSusut!.toStringAsFixed(1)}%',
          ),
          if (p.status != StatusPenjemuran.siapGiling) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: p.status == StatusPenjemuran.masuk
                  ? FilledButton.icon(
                      onPressed: () => _mulai(p),
                      icon: const Icon(Icons.wb_sunny_rounded),
                      label: const Text('Mulai jemur'),
                    )
                  : FilledButton.icon(
                      onPressed: () => _selesai(p),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Selesaikan penjemuran'),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _baris(String k, String v, {bool peringatan = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            k,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: peringatan ? AppColors.gold : AppColors.textDark,
            ),
          ),
        ),
      ],
    ),
  );
}

String _tgl(DateTime? d) => d == null
    ? '-'
    : '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Langkah status yang mudah dipindai: Masuk -> Dijemur -> Siap giling.
class _AlurStatus extends StatelessWidget {
  final StatusPenjemuran status;

  const _AlurStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    final aktif = status.index;
    return Row(
      children: [
        for (var i = 0; i < StatusPenjemuran.values.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: i <= aktif ? AppColors.primaryLight : AppColors.border,
              ),
            ),
          _Langkah(
            label: labelStatus(StatusPenjemuran.values[i]),
            selesai: i <= aktif,
            aktif: i == aktif,
          ),
        ],
      ],
    );
  }
}

class _Langkah extends StatelessWidget {
  final String label;
  final bool selesai;
  final bool aktif;

  const _Langkah({
    required this.label,
    required this.selesai,
    required this.aktif,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 74,
    child: Column(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selesai ? AppColors.primary : AppColors.background,
            border: Border.all(
              color: selesai ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: Icon(
            selesai ? Icons.check_rounded : Icons.circle,
            size: selesai ? 14 : 6,
            color: selesai ? Colors.white : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: aktif ? FontWeight.w800 : FontWeight.w600,
            color: selesai ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ],
    ),
  );
}

class StatusBadge extends StatelessWidget {
  final StatusPenjemuran status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (latar, warna) = switch (status) {
      StatusPenjemuran.masuk => (AppColors.blueSoft, AppColors.blue),
      StatusPenjemuran.dijemur => (AppColors.goldSoft, AppColors.gold),
      StatusPenjemuran.siapGiling => (AppColors.mint, AppColors.mintText),
    };
    return Lencana(labelStatus(status), latar: latar, warna: warna);
  }
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
  int get _durasi => DateTime(_selesai.year, _selesai.month, _selesai.day)
      .difference(
        DateTime(
          p.tanggalMulai!.year,
          p.tanggalMulai!.month,
          p.tanggalMulai!.day,
        ),
      )
      .inDays;

  Future<void> _pilihTanggal() async {
    final t = await showDatePicker(
      context: context,
      initialDate: _selesai,
      firstDate: p.tanggalMulai!,
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (t != null) setState(() => _selesai = t);
  }

  @override
  Widget build(BuildContext context) {
    final susut = hitungSusut(p.beratBasah, _k);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + keyboard),
      child: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const IkonKotak(
                  Icons.wb_sunny_rounded,
                  latar: AppColors.goldSoft,
                  warna: AppColors.gold,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selesaikan penjemuran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '${p.pelanggan} - ${p.kelas}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _pilihTanggal,
              icon: const Icon(Icons.event_rounded),
              label: Text('Tanggal selesai: ${_tgl(_selesai)}'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kering,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Berat kering',
                prefixIcon: Icon(Icons.scale_outlined),
                suffixText: 'kg',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final k = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (k == null || k <= 0) {
                  return 'Berat kering wajib diisi dan lebih dari 0';
                }
                if (k > p.beratBasah) {
                  return 'Tidak boleh melebihi berat basah '
                      '(${formatKg(p.beratBasah)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mint.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppRadius.sedang),
              ),
              child: Row(
                children: [
                  Expanded(child: _info('Durasi', '$_durasi hari')),
                  Expanded(
                    child: _info(
                      'Susut',
                      susut == null ? '-' : '${susut.toStringAsFixed(1)}%',
                    ),
                  ),
                  Expanded(child: _info('Berat basah', formatKg(p.beratBasah))),
                ],
              ),
            ),
            if (_durasi < minHariJemur) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(AppRadius.kecil),
                ),
                child: const Text(
                  'Durasi jemur kurang dari $minHariJemur hari. Padi mungkin '
                  'belum cukup kering, tetapi hasil tetap bisa disimpan.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.gold),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (_key.currentState!.validate()) {
                        Navigator.pop(context, _HasilJemur(_selesai, _k!));
                      }
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Simpan hasil'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String nilai) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
      const SizedBox(height: 2),
      Text(
        nilai,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
    ],
  );

  @override
  void dispose() {
    _kering.dispose();
    super.dispose();
  }
}
