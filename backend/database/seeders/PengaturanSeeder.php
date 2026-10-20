<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PengaturanSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('pengaturan')->insertOrIgnore([
            [
                'kunci' => 'persen_upah',
                'nilai' => '5',
                'keterangan' => 'Persentase upah huller dari beras bersih',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'kunci' => 'persen_hak_operator',
                'nilai' => '5',
                'keterangan' => 'Persentase hak operator dari upah kotor',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
