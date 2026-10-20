<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class KelasPadiSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('kelas_padi')->insertOrIgnore([
            ['nama_kelas' => 'Kelas 1', 'created_at' => now(), 'updated_at' => now()],
            ['nama_kelas' => 'Kelas 2', 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}
