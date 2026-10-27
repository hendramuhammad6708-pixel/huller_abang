import 'package:flutter/material.dart';
import 'penjemuran_model.dart';
import 'penjemuran_service.dart';

const int minHariJemur = 2; // peringatan jika jemur < 2 hari

String _tgl(DateTime? d) => d == null
    ? '-'
    : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _kg(num? n) => n == null ? '-' : '${n.toStringAsFixed(n % 1 == 0 ? 0 : 2)} kg';

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
      final d = await _service.ambilSemua();
      if (!mounted) return;
      setState(() => _data = d);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
      _snack(e.toString().replaceFirst('Exception: ', ''));
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
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tampil = _filter == null ? _data : _data.where((d) => d.status == _filter).toList();
    int hitung(StatusPenjemuran s) => _data.where((d) => d.status == s).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Penjemuran')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _chip('Semua (${_data.length})', _filter == null, () => setState(() => _filter = null)),
                for (final s in StatusPenjemuran.values)
                  _chip('${labelStatus(s)} (${hitung(s)})', _filter == s, () => setState(() => _filter = s)),
              ],
            ),
          ),
          Expanded(child: _isi(tampil)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(label: Text(label), selected: on, onSelected: (_) => onTap()),
  );

  Widget _isi(List<Penjemuran> tampil) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _muat, child: const Text('Coba lagi')),
          ]),
        ),
      );
    }
    if (tampil.isEmpty) {
      return Center(
        child: Text(_filter == null
            ? 'Belum ada padi masuk. Catat dulu di menu Padi Masuk.'
            : 'Tidak ada padi berstatus ${labelStatus(_filter!)}.'),
      );
    }
    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        itemCount: tampil.length,
        itemBuilder: (_, i) => _kartu(tampil[i]),
      ),
    );
  }

  Widget _kartu(Penjemuran p) {
    final durasi = p.durasiHari;
    final singkat = p.status == StatusPenjemuran.siapGiling && durasi != null && durasi < minHariJemur;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(p.pelanggan, style: Theme.of(context).textTheme.titleMedium),
            ),
            StatusBadge(status: p.status),
          ]),
          const SizedBox(height: 4),
          Text('${p.kelas} · masuk ${_tgl(p.tanggalMasuk)}', style: Theme.of(context).textTheme.bodySmall),
          const Divider(height: 20),
          _baris('Berat basah', _kg(p.beratBasah)),
          _baris('Mulai - selesai', '${_tgl(p.tanggalMulai)} - ${_tgl(p.tanggalSelesai)}'),
          _baris('Durasi', durasi == null ? '-' : '$durasi hari${singkat ? '  ⚠ kurang dari $minHariJemur hari' : ''}'),
          _baris('Berat kering', _kg(p.beratKering)),
          _baris('Susut', p.persenSusut == null ? '-' : '${p.persenSusut!.toStringAsFixed(1)}%'),
          if (p.status != StatusPenjemuran.siapGiling) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: p.status == StatusPenjemuran.masuk
                  ? FilledButton(onPressed: () => _mulai(p), child: const Text('Mulai jemur'))
                  : FilledButton(onPressed: () => _selesai(p), child: const Text('Selesaikan')),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _baris(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(k, style: TextStyle(color: Theme.of(context).hintColor)),
      Flexible(child: Text(v, textAlign: TextAlign.right)),
    ]),
  );
}

/// Badge lokal. Setelah branch fe-komponen-status (Zahri) merge, boleh diganti komponen bersama.
class StatusBadge extends StatelessWidget {
  final StatusPenjemuran status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final warna = switch (status) {
      StatusPenjemuran.masuk => Colors.deepPurple,
      StatusPenjemuran.dijemur => Colors.orange.shade800,
      StatusPenjemuran.siapGiling => Colors.green.shade700,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: warna, borderRadius: BorderRadius.circular(99)),
      child: Text(labelStatus(status),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
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
      .difference(DateTime(p.tanggalMulai!.year, p.tanggalMulai!.month, p.tanggalMulai!.day))
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _key,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Selesaikan penjemuran', style: Theme.of(context).textTheme.titleLarge),
          Text('${p.pelanggan} · ${p.kelas} · basah ${_kg(p.beratBasah)}'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pilihTanggal,
            icon: const Icon(Icons.event),
            label: Text('Tanggal selesai: ${_tgl(_selesai)}'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _kering,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Berat kering (kg)', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final k = double.tryParse((v ?? '').replaceAll(',', '.'));
              if (k == null || k <= 0) return 'Berat kering wajib diisi dan lebih dari 0';
              if (k > p.beratBasah) return 'Tidak boleh melebihi berat basah (${_kg(p.beratBasah)})';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Text('Durasi: $_durasi hari   ·   Susut: ${susut == null ? '-' : '${susut.toStringAsFixed(1)}%'}'),
          if (_durasi < minHariJemur)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              color: Colors.amber.shade100,
              child: Text('Durasi jemur kurang dari $minHariJemur hari. Padi mungkin belum cukup kering, tapi tetap bisa disimpan.',
                  style: const TextStyle(color: Colors.black87)),
            ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (_key.currentState!.validate()) Navigator.pop(context, _HasilJemur(_selesai, _k!));
              },
              child: const Text('Simpan hasil jemur'),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _kering.dispose();
    super.dispose();
  }
}