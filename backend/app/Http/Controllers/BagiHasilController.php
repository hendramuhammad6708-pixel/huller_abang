<?php

namespace App\Http\Controllers;

use App\Models\Pengaturan;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BagiHasilController extends Controller
{
    // POST /api/bagi-hasil  {berat_bersih_kg, persen_upah?, persen_hak_operator?}
    //
    // Rumus (sama dengan BagiHasil.hitung di Flutter, pembulatan 2 desimal):
    //   upah             = beras bersih x persen_upah / 100
    //   hak operator     = upah x persen_hak_operator / 100
    //   hak huller       = upah - hak operator
    //   saldo pelanggan  = beras bersih - upah
    // Persentase yang tidak dikirim diambil dari pengaturan.
    public function hitung(Request $request): JsonResponse
    {
        $data = $request->validate([
            'berat_bersih_kg' => ['bail', 'required', 'numeric', 'gt:0', 'max:99999999.99'],
            'persen_upah' => ['nullable', 'numeric', 'between:0,100'],
            'persen_hak_operator' => ['nullable', 'numeric', 'between:0,100'],
        ], [
            'berat_bersih_kg.required' => 'Berat beras bersih wajib diisi',
            'berat_bersih_kg.numeric' => 'Berat beras bersih harus berupa angka',
            'berat_bersih_kg.gt' => 'Berat beras bersih harus lebih dari 0',
            'berat_bersih_kg.max' => 'Berat beras bersih terlalu besar',
            'persen_upah.numeric' => 'Persen upah harus berupa angka antara 0 sampai 100',
            'persen_upah.between' => 'Persen upah harus berupa angka antara 0 sampai 100',
            'persen_hak_operator.numeric' => 'Persen hak operator harus berupa angka antara 0 sampai 100',
            'persen_hak_operator.between' => 'Persen hak operator harus berupa angka antara 0 sampai 100',
        ]);

        $persenUpah = (float) ($data['persen_upah'] ?? $this->pengaturan('persen_upah'));
        $persenOperator = (float) ($data['persen_hak_operator'] ?? $this->pengaturan('persen_hak_operator'));

        $beras = $this->bulat((float) $data['berat_bersih_kg']);
        $upah = $this->bulat($beras * $persenUpah / 100);
        $operator = $this->bulat($upah * $persenOperator / 100);

        return ApiResponse::sukses('Hasil bagi hasil', [
            'berat_bersih_kg' => $beras,
            'persen_upah' => $persenUpah,
            'persen_hak_operator' => $persenOperator,
            'upah_kg' => $upah,
            'operator_kg' => $operator,
            'huller_kg' => $this->bulat($upah - $operator),
            'saldo_pelanggan_kg' => $this->bulat($beras - $upah),
        ]);
    }

    private function pengaturan(string $kunci): float
    {
        return (float) (Pengaturan::where('kunci', $kunci)->value('nilai') ?? 5);
    }

    private function bulat(float $nilai): float
    {
        return round($nilai, 2);
    }
}
