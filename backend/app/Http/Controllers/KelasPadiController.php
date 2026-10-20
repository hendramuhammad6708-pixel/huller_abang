<?php

namespace App\Http\Controllers;

use App\Http\Requests\KelasPadiRequest;
use App\Models\KelasPadi;
use App\Support\ApiResponse;
use Illuminate\Database\QueryException;

class KelasPadiController extends Controller
{
    // GET /api/kelas-padi
    public function index()
    {
        $items = KelasPadi::orderBy('nama_kelas')->get(['id', 'nama_kelas']);

        return ApiResponse::sukses('Daftar kelas padi', ['items' => $items]);
    }

    // POST /api/kelas-padi
    public function store(KelasPadiRequest $request)
    {
        $kelas = KelasPadi::create($request->validated());

        return ApiResponse::sukses('Kelas padi berhasil ditambahkan', ['id' => $kelas->id], 201);
    }

    // PUT /api/kelas-padi/{id}
    public function update(KelasPadiRequest $request, string $id)
    {
        $kelas = KelasPadi::findOrFail($id);
        $kelas->update($request->validated());

        return ApiResponse::sukses('Kelas padi berhasil diubah', ['id' => $kelas->id]);
    }

    // DELETE /api/kelas-padi/{id}
    public function destroy(string $id)
    {
        $kelas = KelasPadi::findOrFail($id);

        try {
            $kelas->delete();
        } catch (QueryException $e) {
            // Aktif mulai Sprint 2: saat tabel padi_masuk sudah memakai kelas_padi (foreign key)
            if ((string) $e->getCode() === '23000') {
                return ApiResponse::gagal(
                    'Kelas padi tidak bisa dihapus karena sudah dipakai data padi masuk',
                    409
                );
            }
            throw $e;
        }

        return ApiResponse::sukses('Kelas padi berhasil dihapus', null);
    }
}
