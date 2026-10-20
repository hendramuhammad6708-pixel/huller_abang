<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            KelasPadiSeeder::class,
            PengaturanSeeder::class,
            OwnerSeeder::class,
        ]);
    }
}
