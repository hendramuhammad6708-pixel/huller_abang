<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class KelasPadiRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'nama_kelas' => [
                'bail',
                'required',
                'string',
                'max:50',
                // id kelas yang sedang diubah (kosong saat menambah) tidak dianggap duplikat
                Rule::unique('kelas_padi', 'nama_kelas')->ignore($this->route('id')),
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'nama_kelas.required' => 'Nama kelas wajib diisi',
            'nama_kelas.string' => 'Nama kelas harus berupa teks',
            'nama_kelas.max' => 'Nama kelas maksimal 50 karakter',
            'nama_kelas.unique' => 'Nama kelas sudah ada',
        ];
    }
}
