<?php

use App\Http\Controllers\PelangganController;
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
Route::get('/pelanggan', [PelangganController::class, 'index']);
Route::post('/pelanggan', [PelangganController::class, 'store']);
Route::get('/pelanggan/{id}', [PelangganController::class, 'show']);
Route::put('/pelanggan/{id}', [PelangganController::class, 'update']);
Route::delete('/pelanggan/{id}', [PelangganController::class, 'destroy']);
