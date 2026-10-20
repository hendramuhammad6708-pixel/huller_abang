<?php

use App\Http\Controllers\KelasPadiController;
use App\Http\Controllers\PelangganController;
use App\Http\Controllers\PengaturanController;
use App\Support\ApiResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

// Alamat uji: cek server dan database hidup  ->  GET /api/health
Route::get('/health', function () {
    try {
        DB::select('select 1');

        return ApiResponse::sukses('ok', ['database' => 'terhubung']);
    } catch (\Throwable $e) {
        return ApiResponse::gagal('Database tidak terhubung', 500);
    }
});

// Daftar route modul: tiap modul menambah barisnya di bawah ini

// TODO: setelah be-role-middleware (Azlan) di-merge, bungkus dengan
// Route::middleware(['auth:sanctum', 'role:owner'])->group(function () { ... });

// --- Pelanggan (feature/be-pelanggan)
Route::get('/pelanggan', [PelangganController::class, 'index']);
Route::post('/pelanggan', [PelangganController::class, 'store']);
Route::get('/pelanggan/{id}', [PelangganController::class, 'show']);
Route::put('/pelanggan/{id}', [PelangganController::class, 'update']);
Route::delete('/pelanggan/{id}', [PelangganController::class, 'destroy']);

// --- Pengaturan & kelas padi (feature/be-pengaturan)
Route::get('/pengaturan', [PengaturanController::class, 'show']);
Route::put('/pengaturan', [PengaturanController::class, 'update']);

Route::get('/kelas-padi', [KelasPadiController::class, 'index']);
Route::post('/kelas-padi', [KelasPadiController::class, 'store']);
Route::put('/kelas-padi/{id}', [KelasPadiController::class, 'update']);
Route::delete('/kelas-padi/{id}', [KelasPadiController::class, 'destroy']);
