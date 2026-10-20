<?php

namespace App\Http\Controllers;

use App\Http\Requests\PelangganRequest;
use App\Models\Pelanggan;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class PelangganController extends Controller
{
    // GET /api/pelanggan?search=&tipe=&page=&limit=
    public function index(Request $request)
    {
        $limit = min(max((int) $request->query('limit', 10), 1), 100);
        $search = $request->query('search');
        $tipe = $request->query('tipe');

        $query = Pelanggan::query();

        if (is_string($search) && trim($search) !== '') {
            $query->where('nama', 'like', '%'.trim($search).'%');
        }
        if (is_string($tipe) && $tipe !== '') {
            $query->where('tipe_pelanggan', $tipe);
        }

        $hasil = $query->orderBy('nama')
            ->paginate($limit, ['id', 'nama', 'kontak', 'tipe_pelanggan', 'created_at']);

        return ApiResponse::sukses('Daftar pelanggan', [
            'items' => $hasil->items(),
            'meta' => [
                'page' => $hasil->currentPage(),
                'limit' => $hasil->perPage(),
                'total' => $hasil->total(),
            ],
        ]);
    }

    // GET /api/pelanggan/{id}
    public function show(string $id)
    {
        $pelanggan = Pelanggan::findOrFail($id);

        return ApiResponse::sukses(
            'Detail pelanggan',
            $pelanggan->only(['id', 'nama', 'kontak', 'tipe_pelanggan', 'created_at', 'updated_at'])
        );
    }

    // POST /api/pelanggan
    public function store(PelangganRequest $request)
    {
        $pelanggan = Pelanggan::create($request->validated());

        return ApiResponse::sukses('Pelanggan berhasil ditambahkan', ['id' => $pelanggan->id], 201);
    }

    // PUT /api/pelanggan/{id}
    public function update(PelangganRequest $request, string $id)
    {
        $pelanggan = Pelanggan::findOrFail($id);
        $pelanggan->update(array_merge(['kontak' => null], $request->validated()));

        return ApiResponse::sukses('Pelanggan berhasil diubah', ['id' => $pelanggan->id]);
    }

    // DELETE /api/pelanggan/{id}  (hapus aman)
    public function destroy(string $id)
    {
        Pelanggan::findOrFail($id)->delete();

        return ApiResponse::sukses('Pelanggan berhasil dihapus', null);
    }
}
