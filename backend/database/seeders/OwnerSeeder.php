<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class OwnerSeeder extends Seeder
{
    public function run(): void
    {
        $username = env('OWNER_USERNAME', 'owner');
        $password = env('OWNER_PASSWORD');

        if (empty($password)) {
            $this->command?->warn('OWNER_PASSWORD di file .env masih kosong, akun Owner tidak dibuat.');

            return;
        }

        User::updateOrCreate(
            ['username' => $username],
            [
                'nama' => 'Owner Huller Abang',
                'password' => $password,
                'role' => 'owner',
                'aktif' => true,
            ]
        );
    }
}
