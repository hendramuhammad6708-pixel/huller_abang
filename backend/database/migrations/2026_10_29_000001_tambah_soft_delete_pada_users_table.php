<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Hapus operator tidak boleh menghapus barisnya: transaksi padi masuk,
        // log, dan pelanggan merujuk ke users lewat foreign key (dibuat_oleh,
        // void_by, user_id). Dengan soft delete riwayatnya tetap utuh.
        Schema::table('users', function (Blueprint $table) {
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropSoftDeletes();
        });
    }
};
