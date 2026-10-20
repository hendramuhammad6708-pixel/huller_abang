<?php

namespace App\Http\Controllers;

use App\Models\KelasPadi;
use App\Models\Pelanggan;
use App\Models\Pengaturan;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function summary(): JsonResponse
    {
        return ApiResponse::sukses('Ringkasan dashboard', [
            'total_operator' => User::where('role', 'operator')->count(),
            'operator_aktif' => User::where('role', 'operator')->where('aktif', true)->count(),
            'total_pelanggan' => Pelanggan::count(),
            'pelanggan_per_tipe' => $this->hitungPelangganPerTipe(),
            'total_kelas_padi' => KelasPadi::count(),
            'total_pengaturan' => Pengaturan::count(),
            'transaksi' => 0,
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
