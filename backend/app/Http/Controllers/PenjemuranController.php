<?php

namespace App\Http\Controllers;

use App\Models\PadiMasuk;
use App\Services\PadiMasukService;
use App\Support\ApiResponse;
use DomainException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class PenjemuranController extends Controller
{
    /** Status yang tampil di halaman penjemuran. */
    private const STATUS_TAMPIL = [
        PadiMasuk::STATUS_MASUK,
        PadiMasuk::STATUS_DIJEMUR,
        PadiMasuk::STATUS_SIAP_GILING,
    ];

    public function __construct(private readonly PadiMasukService $service) {}

    // GET /api/penjemuran?status=&pelanggan_id=&tanggal_dari=&tanggal_sampai=
    // Mengembalikan daftar biasa (bukan items/meta) karena itu yang dibaca
    // PenjemuranService di Flutter; transaksi aktif yang belum selesai giling jumlahnya kecil.
    public function index(Request $request): JsonResponse
    {
        $data = $request->validate([
            'status' => ['nullable', Rule::in(self::STATUS_TAMPIL)],
            'pelanggan_id' => ['nullable', 'integer'],
            'tanggal_dari' => ['nullable', 'date_format:Y-m-d'],
            'tanggal_sampai' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:tanggal_dari'],
        ], [
            'status.in' => 'Status harus masuk, dijemur, atau siap_giling',
            'tanggal_sampai.after_or_equal' => 'Tanggal sampai tidak boleh sebelum tanggal dari',
        ]);

        $query = PadiMasuk::query()
            ->with(['pelanggan', 'kelasPadi', 'penjemuran'])
            ->whereIn('status_transaksi', self::STATUS_TAMPIL);

        if (! empty($data['status'])) {
            $query->where('status_transaksi', $data['status']);
        }
        if (! empty($data['pelanggan_id'])) {
            $query->where('pelanggan_id', $data['pelanggan_id']);
        }
        if (! empty($data['tanggal_dari'])) {
            $query->whereDate('tanggal', '>=', $data['tanggal_dari']);
        }
        if (! empty($data['tanggal_sampai'])) {
            $query->whereDate('tanggal', '<=', $data['tanggal_sampai']);
        }

        $baris = $query->orderByDesc('tanggal')->orderByDesc('id')->get()
            ->map(fn (PadiMasuk $padi) => $this->service->formatPenjemuran($padi))
            ->values()
            ->all();

        return ApiResponse::sukses('Daftar penjemuran', $baris);
    }

    // POST /api/padi-masuk/{padiMasuk}/penjemuran  {tanggal_mulai}
    public function store(Request $request, PadiMasuk $padiMasuk): JsonResponse
    {
        return $this->mulaiJemur($request, $padiMasuk, 'Penjemuran dimulai', 201);
    }

    // POST /api/penjemuran/{padiMasuk}/mulai  {tanggal_mulai}
    public function mulai(Request $request, PadiMasuk $padiMasuk): JsonResponse
    {
        return $this->mulaiJemur($request, $padiMasuk, 'Penjemuran dimulai', 200);
    }

    // PUT /api/padi-masuk/{padiMasuk}/penjemuran  {tanggal_mulai?, tanggal_selesai?, berat_kering?}
    public function update(Request $request, PadiMasuk $padiMasuk): JsonResponse
    {
        $data = $request->validate([
            'tanggal_mulai' => $this->aturanTanggalMulai($padiMasuk, wajib: false),
            'tanggal_selesai' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
            'berat_kering' => $this->aturanBeratKering($padiMasuk, wajib: false),
        ], $this->pesan());

        return $this->jalankan(fn () => ApiResponse::sukses(
            'Data penjemuran diubah',
            $this->service->formatPenjemuran($this->service->ubahJemur($padiMasuk, $data, $request->user()))
        ));
    }

    // POST /api/penjemuran/{padiMasuk}/selesai  {tanggal_selesai, berat_kering}
    public function selesai(Request $request, PadiMasuk $padiMasuk): JsonResponse
    {
        $padiMasuk->loadMissing('penjemuran');
        $mulai = $padiMasuk->penjemuran?->tanggal_mulai ?? $padiMasuk->tanggal;
        $paling = $mulai->copy()->addDays(PadiMasukService::MIN_JEMUR_HARI)->toDateString();

        // Penjemuran minimal 2 hari: tanggal selesai paling cepat $paling. Aturan ini
        // diperiksa lebih dulu dari "tidak di masa depan" agar pesannya menjelaskan
        // alasan sebenarnya saat padi dijemur kurang dari 2 hari.
        $data = $request->validate([
            'tanggal_selesai' => [
                'bail', 'required', 'date_format:Y-m-d',
                'after_or_equal:'.$paling,
                'before_or_equal:today',
            ],
            'berat_kering' => $this->aturanBeratKering($padiMasuk, wajib: true),
        ], array_merge($this->pesan(), [
            'tanggal_selesai.after_or_equal' => $this->service->pesanDurasiMinimal($mulai),
        ]));

        return $this->jalankan(fn () => ApiResponse::sukses(
            'Penjemuran selesai, padi siap giling',
            $this->service->formatPenjemuran($this->service->selesaiJemur(
                $padiMasuk,
                $data['tanggal_selesai'],
                (float) $data['berat_kering'],
                $request->user()
            ))
        ));
    }

    private function mulaiJemur(Request $request, PadiMasuk $padiMasuk, string $pesan, int $status): JsonResponse
    {
        $data = $request->validate([
            'tanggal_mulai' => $this->aturanTanggalMulai($padiMasuk, wajib: true),
        ], $this->pesan());

        return $this->jalankan(fn () => ApiResponse::sukses(
            $pesan,
            $this->service->formatPenjemuran($this->service->mulaiJemur($padiMasuk, $data['tanggal_mulai'], $request->user())),
            $status
        ));
    }

    private function aturanTanggalMulai(PadiMasuk $padi, bool $wajib): array
    {
        return [
            'bail',
            $wajib ? 'required' : 'nullable',
            'date_format:Y-m-d',
            'before_or_equal:today',
            'after_or_equal:'.$padi->tanggal->toDateString(),
        ];
    }

    private function aturanBeratKering(PadiMasuk $padi, bool $wajib): array
    {
        return [
            'bail',
            $wajib ? 'required' : 'nullable',
            'numeric',
            'gt:0',
            'lte:'.$padi->berat_basah_kg,
        ];
    }

    private function pesan(): array
    {
        return [
            'tanggal_mulai.required' => 'Tanggal mulai wajib diisi',
            'tanggal_mulai.date_format' => 'Format tanggal harus YYYY-MM-DD',
            'tanggal_mulai.before_or_equal' => 'Tanggal mulai tidak boleh di masa depan',
            'tanggal_mulai.after_or_equal' => 'Tanggal mulai tidak boleh sebelum tanggal padi masuk',
            'tanggal_selesai.required' => 'Tanggal selesai wajib diisi',
            'tanggal_selesai.date_format' => 'Format tanggal harus YYYY-MM-DD',
            'tanggal_selesai.before_or_equal' => 'Tanggal selesai tidak boleh di masa depan',
            'tanggal_selesai.after_or_equal' => 'Tanggal selesai tidak boleh sebelum tanggal mulai',
            'berat_kering.required' => 'Berat kering wajib diisi',
            'berat_kering.numeric' => 'Berat kering harus berupa angka',
            'berat_kering.gt' => 'Berat kering harus lebih dari 0',
            'berat_kering.lte' => 'Berat kering tidak boleh melebihi berat basah',
        ];
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
