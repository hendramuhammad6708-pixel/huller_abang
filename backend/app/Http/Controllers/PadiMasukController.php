<?php

namespace App\Http\Controllers;

use App\Http\Requests\PadiMasukRequest;
use App\Models\PadiMasuk;
use App\Services\PadiMasukService;
use App\Support\ApiResponse;
use DomainException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class PadiMasukController extends Controller
{
    public function __construct(private readonly PadiMasukService $service) {}

    // GET /api/padi-masuk?dari=&sampai=&pelanggan_id=&kelas_padi_id=&status=&page=&limit=
    public function index(Request $request): JsonResponse
    {
        $data = $request->validate([
            'dari' => ['nullable', 'date_format:Y-m-d'],
            'sampai' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:dari'],
            'pelanggan_id' => ['nullable', 'integer'],
            'kelas_padi_id' => ['nullable', 'integer'],
            'status' => ['nullable', Rule::in(PadiMasuk::daftarStatus())],
            'page' => ['nullable', 'integer', 'min:1'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:100'],
        ], [
            'sampai.after_or_equal' => 'Tanggal sampai tidak boleh sebelum tanggal dari',
            'status.in' => 'Status tidak dikenal',
            'limit.max' => 'Limit maksimal 100',
        ]);

        $query = PadiMasuk::query()->with(['pelanggan', 'kelasPadi', 'penjemuran']);

        if (! empty($data['dari'])) {
            $query->whereDate('tanggal', '>=', $data['dari']);
        }
        if (! empty($data['sampai'])) {
            $query->whereDate('tanggal', '<=', $data['sampai']);
        }
        if (! empty($data['pelanggan_id'])) {
            $query->where('pelanggan_id', $data['pelanggan_id']);
        }
        if (! empty($data['kelas_padi_id'])) {
            $query->where('kelas_padi_id', $data['kelas_padi_id']);
        }
        if (! empty($data['status'])) {
            $query->where('status_transaksi', $data['status']);
        }

        // Ringkasan seluruh hasil filter (bukan hanya halaman ini), tanpa transaksi void,
        // supaya angka di aplikasi benar walau datanya dimuat bertahap.
        $aktif = (clone $query)->where('status_transaksi', '!=', PadiMasuk::STATUS_VOID);
        $jumlahAktif = (clone $aktif)->count();
        $totalBerat = (float) (clone $aktif)->sum('berat_basah_kg');

        $hasil = $query->orderByDesc('tanggal')
            ->orderByDesc('id')
            ->paginate((int) ($data['limit'] ?? 10));

        return ApiResponse::sukses('Daftar padi masuk', [
            'items' => collect($hasil->items())
                ->map(fn (PadiMasuk $padi) => $this->service->format($padi))
                ->values()
                ->all(),
            'meta' => [
                'page' => $hasil->currentPage(),
                'limit' => $hasil->perPage(),
                'total' => $hasil->total(),
                'jumlah_aktif' => $jumlahAktif,
                'total_berat_kg' => $totalBerat,
            ],
        ]);
    }

    // POST /api/padi-masuk
    public function store(PadiMasukRequest $request): JsonResponse
    {
        $padi = $this->service->buat($request->validated(), $request->user());

        return ApiResponse::sukses('Padi masuk berhasil dicatat', $this->service->format($padi), 201);
    }

    // GET /api/padi-masuk/{padiMasuk}
    public function show(PadiMasuk $padiMasuk): JsonResponse
    {
        return ApiResponse::sukses('Detail padi masuk', $this->service->format($padiMasuk));
    }

    // PUT /api/padi-masuk/{padiMasuk}  (hanya selama status masih "masuk")
    public function update(PadiMasukRequest $request, PadiMasuk $padiMasuk): JsonResponse
    {
        return $this->jalankan(fn () => ApiResponse::sukses(
            'Padi masuk berhasil diubah',
            $this->service->format($this->service->ubah($padiMasuk, $request->validated(), $request->user()))
        ));
    }

    // POST /api/padi-masuk/{padiMasuk}/void  {alasan}
    public function void(Request $request, PadiMasuk $padiMasuk): JsonResponse
    {
        $data = $request->validate([
            'alasan' => ['bail', 'required', 'string', 'min:3', 'max:255'],
        ], [
            'alasan.required' => 'Alasan pembatalan wajib diisi',
            'alasan.min' => 'Alasan minimal 3 karakter',
            'alasan.max' => 'Alasan maksimal 255 karakter',
        ]);

        return $this->jalankan(fn () => ApiResponse::sukses(
            'Transaksi dibatalkan (void)',
            $this->service->format($this->service->batalkan($padiMasuk, trim($data['alasan']), $request->user()))
        ));
    }

    // POST /api/padi-masuk/{padiMasuk}/selesai-giling  {tanggal_selesai_giling?}
    public function selesaikanGiling(Request $request, PadiMasuk $padiMasuk): JsonResponse
    {
        $data = $request->validate([
            'tanggal_selesai_giling' => [
                'nullable', 'date_format:Y-m-d',
                'before_or_equal:today',
                'after_or_equal:'.$padiMasuk->tanggal->toDateString(),
            ],
        ], [
            'tanggal_selesai_giling.before_or_equal' => 'Tanggal tidak boleh di masa depan',
            'tanggal_selesai_giling.after_or_equal' => 'Tanggal tidak boleh sebelum tanggal padi masuk',
        ]);

        return $this->jalankan(fn () => ApiResponse::sukses(
            'Penggilingan diselesaikan',
            $this->service->format(
                $this->service->selesaikanGiling($padiMasuk, $data['tanggal_selesai_giling'] ?? null, $request->user())
            )
        ));
    }

    // GET /api/padi-masuk/{padiMasuk}/log
    public function log(Request $request, PadiMasuk $padiMasuk): JsonResponse
    {
        $data = $request->validate([
            'page' => ['nullable', 'integer', 'min:1'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $hasil = $padiMasuk->log()
            ->with('user:id,nama')
            ->orderByDesc('id')
            ->paginate((int) ($data['limit'] ?? 20));

        return ApiResponse::sukses('Log padi masuk', [
            'items' => collect($hasil->items())->map(fn ($l) => [
                'id' => $l->id,
                'aksi' => $l->aksi,
                'keterangan' => $l->keterangan,
                'user' => $l->user?->only(['id', 'nama']),
                'created_at' => $l->created_at?->toISOString(),
            ])->values()->all(),
            'meta' => [
                'page' => $hasil->currentPage(),
                'limit' => $hasil->perPage(),
                'total' => $hasil->total(),
            ],
        ]);
    }

    /** Aturan bisnis yang dilanggar (status tidak cocok) menjadi 409 Conflict. */
    private function jalankan(callable $aksi): JsonResponse
    {
        try {
            return $aksi();
        } catch (DomainException $e) {
            return ApiResponse::gagal($e->getMessage(), 409);
        }
    }
}
