<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Riwayat perubahan persentase (dipakai PengaturanController::update)
        Schema::create('log_pengaturan', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users');
            $table->decimal('upah_lama', 5, 2)->nullable();
            $table->decimal('upah_baru', 5, 2)->nullable();
            $table->decimal('hak_operator_lama', 5, 2)->nullable();
            $table->decimal('hak_operator_baru', 5, 2)->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('log_pengaturan');
    }
};
