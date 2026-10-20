<?php

namespace App\Http\Controllers;

use App\Http\Requests\PengaturanRequest;
use App\Models\Pengaturan;
use App\Support\ApiResponse;
use Illuminate\Support\Facades\DB;

class PengaturanController extends Controller
{
    private const KETERANGAN = [
        'persen_upah' => 'Persentase upah huller dari beras bersih',
        'persen_hak_operator' => 'Persentase hak operator dari upah kotor',
    ];

    // GET /api/pengaturan
    public function show()
    {
        return ApiResponse::sukses('Pengaturan sistem', $this->ambil());
    }

    // PUT /api/pengaturan
    public function update(PengaturanRequest $request)
    {
        $data = $request->validated();

        DB::transaction(function () use ($data) {
            foreach ($data as $kunci => $nilai) {
                Pengaturan::updateOrCreate(
                    ['kunci' => $kunci],
                    ['nilai' => (string) (0 + $nilai), 'keterangan' => self::KETERANGAN[$kunci]]
                );
            }
        });

        return ApiResponse::sukses('Pengaturan berhasil diubah', $this->ambil());
    }

    private function ambil(): array
    {
        $baris = Pengaturan::whereIn('kunci', array_keys(self::KETERANGAN))->pluck('nilai', 'kunci');

        $hasil = [];
        foreach (array_keys(self::KETERANGAN) as $kunci) {
            $nilai = $baris[$kunci] ?? null;
            $hasil[$kunci] = $nilai === null ? null : $this->keAngka($nilai);
        }

        return $hasil;
    }

    // "5" -> 5 (bilangan bulat), "2.5" -> 2.5
    private function keAngka(string $nilai): int|float
    {
        $angka = (float) $nilai;

        return floor($angka) == $angka ? (int) $angka : $angka;
    }
}
