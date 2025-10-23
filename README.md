<<<<<<< HEAD
=======
## Fitur

>>>>>>> f6d884ef5e128f089d505895d8cbdb023b842417
1. **Tabel tambahan**
   - `SALAM.mata_kuliah`
   - `SALAM.nilai_mahasiswa`
2. **View analitik**
   - `SALAM.vw_rekap_nilai` → ringkasan nilai mahasiswa per mata kuliah.
3. **Trigger otomatis**
   - `SALAM.update_ipk()` → update IPK mahasiswa saat nilai baru dimasukkan.
4. **Hak akses lengkap**
   - `backend_dev` → CRUD semua tabel.
   - `bi_dev` → hanya SELECT tabel & view.
   - `data_engineer` → CREATE, MODIFY, DROP, CRUD semua objek.


