<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Jejak audit: siapa mengubah transaksi padi masuk, kapan, dan apa
        Schema::create('log_padi_masuk', function (Blueprint $table) {
            $table->id();
            $table->foreignId('padi_masuk_id')->constrained('padi_masuk');
            $table->foreignId('user_id')->nullable()->constrained('users');
            $table->string('aksi', 30);
            $table->string('keterangan', 255)->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('log_padi_masuk');
    }
};
