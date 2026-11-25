<?php

namespace App\Http\Controllers;

use App\Http\Requests\PelangganRequest;
use App\Http\Requests\RiwayatTransaksiPelangganRequest;
use App\Models\PadiMasuk;
use App\Models\Pelanggan;
use App\Services\PadiMasukService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class PelangganController extends Controller
{
    public function __construct(private readonly PadiMasukService $service) {}

    // GET /api/pelanggan?search=&tipe=&page=&limit=
    public function index(Request $request)
    {
        $limit = min(max((int) $request->query('limit', 10), 1), 100);
        $search = $request->query('search');
        $tipe = $request->query('tipe');

        $query = Pelanggan::query();

        if (is_string($search) && trim($search) !== '') {
            $query->where('nama', 'like', '%'.trim($search).'%');
        }
        if (is_string($tipe) && $tipe !== '') {
            $query->where('tipe_pelanggan', $tipe);
        }

        $hasil = $query->orderBy('nama')
            ->paginate($limit, ['id', 'nama', 'kontak', 'tipe_pelanggan', 'created_at']);

        return ApiResponse::sukses('Daftar pelanggan', [
            'items' => $hasil->items(),
            'meta' => [
                'page' => $hasil->currentPage(),
                'limit' => $hasil->perPage(),
                'total' => $hasil->total(),
            ],
        ]);
    }

    // GET /api/pelanggan/{id}
    public function show(string $id)
    {
        $pelanggan = Pelanggan::with('pembuat:id,nama,role')->findOrFail($id);

        return ApiResponse::sukses(
            'Detail pelanggan',
            $pelanggan->only(['id', 'nama', 'kontak', 'tipe_pelanggan', 'created_at', 'updated_at'])
                + ['dibuat_oleh' => $pelanggan->pembuat?->only(['id', 'nama', 'role'])]
        );
    }

    public function riwayatTransaksi(RiwayatTransaksiPelangganRequest $request, string $id): JsonResponse
    {
        $pelanggan = Pelanggan::findOrFail($id);
        $data = $request->validated();
        $limit = (int) ($data['limit'] ?? 10);

        $terakhir = PadiMasuk::query()
            ->where('pelanggan_id', $pelanggan->id)
            ->where('status_transaksi', '!=', PadiMasuk::STATUS_VOID)
            ->orderByDesc('tanggal')
            ->orderByDesc('id')
            ->first();

        $query = PadiMasuk::query()
            ->where('pelanggan_id', $pelanggan->id)
            ->with(['pelanggan', 'kelasPadi', 'penjemuran']);

        if (! empty($data['search'])) {
            $search = $data['search'];

            $query->where(function ($q) use ($search) {
                $q->where('catatan', 'like', '%'.$search.'%')
                    ->orWhereHas('kelasPadi', fn ($k) => $k->where('nama_kelas', 'like', '%'.$search.'%'));
            });
        }

        if (! empty($data['status'])) {
            $query->where('status_transaksi', $data['status']);
        }

        if (! empty($data['tanggal_dari'])) {
            $query->whereDate('tanggal', '>=', $data['tanggal_dari']);
        }

        if (! empty($data['tanggal_sampai'])) {
            $query->whereDate('tanggal', '<=', $data['tanggal_sampai']);
        }

        $hasil = $query->orderByDesc('tanggal')
            ->orderByDesc('id')
            ->paginate($limit);

        $terakhirFormat = $terakhir ? $this->service->format($terakhir) : null;
        $statusTerakhir = $terakhirFormat['status'] ?? null;
        $tanggalTerakhir = $terakhirFormat['tanggal_selesai_giling']
            ?? $terakhirFormat['penjemuran']['tanggal_mulai']
            ?? $terakhirFormat['tanggal']
            ?? null;

        return ApiResponse::sukses('Riwayat transaksi pelanggan', [
            'pelanggan' => array_merge($pelanggan->only(['id', 'nama', 'kontak', 'tipe_pelanggan']), [
                'status_terakhir' => $statusTerakhir,
                'status_terakhir_label' => $statusTerakhir
                    ? (PadiMasuk::LABEL_STATUS[$statusTerakhir] ?? $statusTerakhir)
                    : null,
                'tanggal_terakhir' => $tanggalTerakhir,
            ]),
            'terakhir' => $terakhirFormat,
            'items' => collect($hasil->items())
                ->map(fn (PadiMasuk $padi) => $this->service->format($padi))
                ->values()
                ->all(),
            'meta' => [
                'page' => $hasil->currentPage(),
                'limit' => $hasil->perPage(),
                'total' => $hasil->total(),
            ],
        ]);
    }

    // POST /api/pelanggan
    // Owner dan operator boleh menambah (operator hanya petani/pengepul, lihat PelangganRequest)
    public function store(PelangganRequest $request)
    {
        $data = $request->validated();

        // Tolak duplikat yang jelas: nama dan kontak sama dengan pelanggan aktif.
        // Nama saja tidak cukup karena dua orang bisa bernama sama.
        if (! empty($data['kontak'])
            && Pelanggan::where('kontak', $data['kontak'])
                ->whereRaw('lower(nama) = ?', [mb_strtolower($data['nama'])])
                ->exists()) {
            throw ValidationException::withMessages([
                'nama' => 'Pelanggan dengan nama dan kontak yang sama sudah ada',
            ]);
        }

        $pelanggan = Pelanggan::create($data + ['dibuat_oleh' => $request->user()->id]);

        return ApiResponse::sukses(
            'Pelanggan berhasil ditambahkan',
            $pelanggan->only(['id', 'nama', 'kontak', 'tipe_pelanggan']),
            201
        );
    }

    // PUT /api/pelanggan/{id}
    public function update(PelangganRequest $request, string $id)
    {
        $pelanggan = Pelanggan::findOrFail($id);
        $pelanggan->update(array_merge(['kontak' => null], $request->validated()));

        return ApiResponse::sukses('Pelanggan berhasil diubah', ['id' => $pelanggan->id]);
    }

    // DELETE /api/pelanggan/{id}  (hapus aman)
    public function destroy(string $id)
    {
        Pelanggan::findOrFail($id)->delete();

        return ApiResponse::sukses('Pelanggan berhasil dihapus', null);
    }
}
