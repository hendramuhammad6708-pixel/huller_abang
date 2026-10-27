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
        $totalBeratMasuk = PadiMasuk::sum('berat_basah_kg');
        $transaksiHariIni = PadiMasuk::whereDate('tanggal', now()->toDateString())->count();
        $totalBeratHariIni = PadiMasuk::whereDate('tanggal', now()->toDateString())->sum('berat_basah_kg');

        return ApiResponse::sukses('Ringkasan dashboard', [
            'total_operator' => User::where('role', 'operator')->count(),
            'operator_aktif' => User::where('role', 'operator')->where('aktif', true)->count(),
            'total_pelanggan' => Pelanggan::count(),
            'pelanggan_per_tipe' => $this->hitungPelangganPerTipe(),
            'total_kelas_padi' => KelasPadi::count(),
            'total_pengaturan' => Pengaturan::count(),
            'transaksi' => PadiMasuk::count(),
            'stok' => PadiMasuk::whereIn('status', [PadiMasuk::STATUS_MASUK, PadiMasuk::STATUS_DIJEMUR])->count(),
            'total_berat_basah_kg' => (float) $totalBeratMasuk,
            'total_berat_kg' => (float) $totalBeratMasuk,
            'padi_masuk' => [
                'jumlah_transaksi' => PadiMasuk::count(),
                'total_berat_kg' => (float) $totalBeratMasuk,
                'hari_ini' => [
                    'jumlah_transaksi' => $transaksiHariIni,
                    'total_berat_kg' => (float) $totalBeratHariIni,
                ],
            ],
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
