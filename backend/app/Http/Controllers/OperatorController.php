<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class OperatorController extends Controller
{
    // GET /api/operators?search=&aktif=&page=&limit=
    public function index(Request $request): JsonResponse
    {
        $limit = min(max((int) $request->query('limit', 10), 1), 100);
        $search = $request->query('search');
        $aktif = $request->query('aktif');

        $query = User::where('role', 'operator');

        if (is_string($search) && trim($search) !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('nama', 'like', '%'.trim($search).'%')
                    ->orWhere('username', 'like', '%'.trim($search).'%');
            });
        }
        if ($aktif === '1' || $aktif === 'true') {
            $query->where('aktif', true);
        } elseif ($aktif === '0' || $aktif === 'false') {
            $query->where('aktif', false);
        }

        $hasil = $query->orderBy('nama')
            ->paginate($limit, ['id', 'nama', 'username', 'aktif', 'created_at']);

        return ApiResponse::sukses('Daftar operator', [
            'items' => $hasil->items(),
            'meta' => [
                'page' => $hasil->currentPage(),
                'limit' => $hasil->perPage(),
                'total' => $hasil->total(),
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:100'],
            'username' => ['required', 'string', 'max:50', 'unique:users,username'],
            'password' => ['required', 'string', 'min:6'],
            'aktif' => ['sometimes', 'boolean'],
        ]);

        $operator = User::create([
            'nama' => $data['nama'],
            'username' => $data['username'],
            'password' => Hash::make($data['password']),
            'role' => 'operator',
            'aktif' => $data['aktif'] ?? true,
        ]);

        return ApiResponse::sukses('Operator berhasil ditambahkan', [
            'operator' => $this->formatOperator($operator),
        ], 201);
    }

    public function show(User $user): JsonResponse
    {
        if ($user->role !== 'operator') {
            return ApiResponse::gagal('Data operator tidak ditemukan', 404);
        }

        return ApiResponse::sukses('Detail operator', [
            'operator' => $this->formatOperator($user),
        ]);
    }

    public function update(Request $request, User $user): JsonResponse
    {
        if ($user->role !== 'operator') {
            return ApiResponse::gagal('Data operator tidak ditemukan', 404);
        }

        $data = $request->validate([
            'nama' => ['sometimes', 'string', 'max:100'],
            'username' => ['sometimes', 'string', 'max:50', Rule::unique('users', 'username')->ignore($user->id)],
            'password' => ['sometimes', 'string', 'min:6'],
            'aktif' => ['sometimes', 'boolean'],
        ]);

        if (isset($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        }

        $user->update($data);

        return ApiResponse::sukses('Operator berhasil diperbarui', [
            'operator' => $this->formatOperator($user->fresh()),
        ]);
    }

    public function destroy(User $user): JsonResponse
    {
        if ($user->role !== 'operator') {
            return ApiResponse::gagal('Data operator tidak ditemukan', 404);
        }

        $user->tokens()->delete();
        $user->delete();

        return ApiResponse::sukses('Operator berhasil dihapus');
    }

    private function formatOperator(User $user): array
    {
        return $user->only(['id', 'nama', 'username', 'aktif', 'created_at', 'updated_at']);
    }
}
