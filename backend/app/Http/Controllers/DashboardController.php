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
        $hariIni = now()->toDateString();
        $aktif = fn () => PadiMasuk::where('status_transaksi', '!=', PadiMasuk::STATUS_VOID);

        return ApiResponse::sukses('Ringkasan dashboard', [
            'total_operator' => User::where('role', 'operator')->count(),
            'operator_aktif' => User::where('role', 'operator')->where('aktif', true)->count(),
            'total_pelanggan' => Pelanggan::count(),
            'pelanggan_per_tipe' => $this->hitungPelangganPerTipe(),
            'total_kelas_padi' => KelasPadi::count(),
            'total_pengaturan' => Pengaturan::count(),
            'padi_masuk' => [
                'jumlah_transaksi' => $aktif()->count(),
                'total_berat_kg' => (float) $aktif()->sum('berat_basah_kg'),
                'hari_ini' => [
                    'jumlah_transaksi' => $aktif()->whereDate('tanggal', $hariIni)->count(),
                    'total_berat_kg' => (float) $aktif()->whereDate('tanggal', $hariIni)->sum('berat_basah_kg'),
                ],
            ],
            'penjemuran' => [
                'sedang_dijemur' => $aktif()->where('status_transaksi', PadiMasuk::STATUS_DIJEMUR)->count(),
                'siap_giling' => $aktif()->where('status_transaksi', PadiMasuk::STATUS_SIAP_GILING)->count(),
            ],
            'transaksi' => $aktif()->count(),
            'stok' => 0,
        ]);
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
