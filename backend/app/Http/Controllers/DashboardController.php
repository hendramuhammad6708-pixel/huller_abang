<?php

namespace App\Http\Controllers;

use App\Models\KelasPadi;
use App\Models\PadiMasuk;
use App\Models\Pelanggan;
use App\Models\Pengaturan;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function summary(): JsonResponse
    {
        $operator = User::where('role', 'operator')
            ->selectRaw('count(*) as total, coalesce(sum(case when aktif = 1 then 1 else 0 end), 0) as aktif')
            ->first();

        $padi = $this->ringkasPadiMasuk(now()->toDateString());

        return ApiResponse::sukses('Ringkasan dashboard', [
            'total_operator' => (int) $operator->total,
            'operator_aktif' => (int) $operator->aktif,
            'total_pelanggan' => Pelanggan::count(),
            'pelanggan_per_tipe' => $this->hitungPelangganPerTipe(),
            'total_kelas_padi' => KelasPadi::count(),
            'total_pengaturan' => Pengaturan::count(),
            'padi_masuk' => [
                'jumlah_transaksi' => $padi['jumlah'],
                'total_berat_kg' => $padi['berat'],
                'hari_ini' => [
                    'jumlah_transaksi' => $padi['jumlah_hari_ini'],
                    'total_berat_kg' => $padi['berat_hari_ini'],
                ],
            ],
            'penjemuran' => [
                'sedang_dijemur' => $padi['dijemur'],
                'siap_giling' => $padi['siap_giling'],
            ],
            // Kunci di bawah dipertahankan untuk kontrak dengan aplikasi:
            // "transaksi" sama dengan padi_masuk.jumlah_transaksi, dan "stok"
            // masih nol sampai modul stok dibuat.
            'transaksi' => $padi['jumlah'],
            'stok' => 0,
        ]);
    }

    /**
     * Seluruh angka padi masuk (tanpa void) dalam satu query agregat, bukan
     * satu query per angka.
     */
    private function ringkasPadiMasuk(string $hariIni): array
    {
        $baris = PadiMasuk::where('status_transaksi', '!=', PadiMasuk::STATUS_VOID)
            ->selectRaw(
                'count(*) as jumlah,'
                .' coalesce(sum(berat_basah_kg), 0) as berat,'
                .' coalesce(sum(case when date(tanggal) = ? then 1 else 0 end), 0) as jumlah_hari_ini,'
                .' coalesce(sum(case when date(tanggal) = ? then berat_basah_kg else 0 end), 0) as berat_hari_ini,'
                .' coalesce(sum(case when status_transaksi = ? then 1 else 0 end), 0) as dijemur,'
                .' coalesce(sum(case when status_transaksi = ? then 1 else 0 end), 0) as siap_giling',
                [$hariIni, $hariIni, PadiMasuk::STATUS_DIJEMUR, PadiMasuk::STATUS_SIAP_GILING]
            )
            ->first();

        return [
            'jumlah' => (int) $baris->jumlah,
            'berat' => (float) $baris->berat,
            'jumlah_hari_ini' => (int) $baris->jumlah_hari_ini,
            'berat_hari_ini' => (float) $baris->berat_hari_ini,
            'dijemur' => (int) $baris->dijemur,
            'siap_giling' => (int) $baris->siap_giling,
        ];
    }

    private function hitungPelangganPerTipe(): array
    {
        $hitung = Pelanggan::query()
            ->selectRaw('tipe_pelanggan, count(*) as jumlah')
            ->groupBy('tipe_pelanggan')
            ->pluck('jumlah', 'tipe_pelanggan');

        $hasil = ['pengepul' => 0, 'petani' => 0, 'milik_huller' => 0];

        foreach ($hitung as $tipe => $jumlah) {
            $hasil[$tipe] = (int) $jumlah;
        }

        return $hasil;
    }
}
