<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\KelasPadiController;
use App\Http\Controllers\OperatorController;
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
    } catch (Throwable $e) {
        return ApiResponse::gagal('Database tidak terhubung', 500);
    }
});

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::get('/dashboard/summary', [DashboardController::class, 'summary']);
});

Route::middleware(['auth:sanctum', 'role:owner'])
    ->prefix('operators')
    ->group(function () {
        Route::get('/', [OperatorController::class, 'index']);
        Route::post('/', [OperatorController::class, 'store']);
        Route::get('/{user}', [OperatorController::class, 'show']);
        Route::put('/{user}', [OperatorController::class, 'update']);
        Route::patch('/{user}', [OperatorController::class, 'update']);
        Route::delete('/{user}', [OperatorController::class, 'destroy']);
    });

// Daftar route modul: tiap modul menambah barisnya di bawah ini

// Modul di bawah ini butuh token Sanctum + role owner (lihat docs/api/*.md)
Route::middleware(['auth:sanctum', 'role:owner'])->group(function () {
    // --- Pelanggan (feature/be-pelanggann)
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
});
