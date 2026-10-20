<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'username' => ['required', 'string', 'max:50'],
            'password' => ['required', 'string'],
        ]);

        $user = User::query()->where('username', $data['username'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            return ApiResponse::gagal('Username atau kata sandi salah.', 401);
        }

        if (! $user->aktif) {
            return ApiResponse::gagal('Akun nonaktif. Hubungi Pemilik.', 403);
        }

        $token = $user->createToken('auth');

        return ApiResponse::sukses('Berhasil masuk', [
            'token' => $token->plainTextToken,
            'token_type' => 'Bearer',
            'user' => $user->only(['id', 'nama', 'username', 'role', 'aktif']),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return ApiResponse::sukses('Berhasil keluar');
    }

    public function me(Request $request): JsonResponse
    {
        return ApiResponse::sukses('Data pengguna', $request->user()->only(['id', 'nama', 'username', 'role', 'aktif']));
    }
}
