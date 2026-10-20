INSERT INTO pengaturan (kunci, nilai, keterangan) VALUES
  ('persen_upah', '5', 'Persentase upah huller dari beras bersih'),
  ('persen_hak_operator', '5', 'Persentase hak operator dari upah kotor')
ON DUPLICATE KEY UPDATE kunci = kunci;

INSERT INTO kelas_padi (nama_kelas) VALUES ('Kelas 1'), ('Kelas 2')
ON DUPLICATE KEY UPDATE nama_kelas = nama_kelas;