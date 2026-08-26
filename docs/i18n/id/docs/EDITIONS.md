# Perbandingan Versi (Editions Comparison)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

Sistem Manajemen Properti dibagi menjadi tiga versi: Lite、Standard、Full, meningkat secara bertahap.

---

## Ikhtisar

| Indikator | Lite | Standard | Full |
|------|:-----------:|:---------------:|:-----------:|
| Tabel database | **21** | **31** | **65** |
| Model Eloquent | 19 | 30 | 58 |
| Controller panel admin | 17 | 28 | 47 |
| Controller portal pemilik | 9 | 12 | 17 |
| Route API | 35 | 70 | 178 |
| Modul bisnis | 10 | 18 | 34 |
| Layer keamanan | 18 lapis | 18 lapis | 18 lapis |

---

## Perbandingan Modul Fungsi

### Lite

Manajemen properti inti, mencakup sistem umum backoffice + 10 modul bisnis inti.

**Panel admin**: dashboard、CRUD user/peran/izin/konfigurasi/log、CRUD komunitas/gedung/unit/tipe ruangan/properti/pemilik/penyewa/biaya/perbaikan/pengumuman

**Portal pemilik**: registrasi/login、beranda、properti saya、bayar tagihan、submit perbaikan/penilaian、lihat pengumuman、informasi pribadi

---

### Standard

Di atas Lite menambah 6 modul bisnis bantu + visualisasi panel + ekspor data.


**Panel admin baru**: CRUD tempat parkir/kendaraan、aset peralatan+perawatan、penanganan keluhan+kunjungan balik、persetujuan tamu、manajemen kontrak、manajemen pemasukan/pengeluaran+statistik

**Portal pemilik baru**: kendaraan/tempat parkir saya、rekaman parkir、reservasi tamu/kode akses

---

### Full

Di atas Standard menambah modul lanjutan + 12 fitur ekstensi.

**Panel admin baru**: rute patroli+rekaman、area kebersihan+rekaman、area hijau+perawatan、manajemen aktivitas komunitas、meter energi+pencatatan meter、manajemen karyawan、template notifikasi+kirim、mesin persetujuan、order pembayaran+refund、manajemen voting+aturan SLA+strategi penagihan+tugas pemeliharaan+manajemen toko+review face+manajemen grup+knowledge base

**Portal pemilik baru**: daftar aktivitas komunitas、reservasi parkir/tamu、notifikasi pesan、voting+penghitungan suara、lihat produk+order、tanya jawab cerdas、registrasi face

---

## Perbandingan Indikator Teknis

| Indikator | Lite | Standard | Full |
|------|:------:|:------:|:------:|
| Tabel database | 21 | 31 | 65 |
| File model | 19 | 30 | 58 |
| Controller admin | 17 | 28 | 47 |
| Controller service | 9 | 12 | 17 |
| Route admin | 45 | 80 | 123 |
| Route service | 20 | 35 | 55 |
| Halaman Flutter Admin | 4 | 7 | 57 |
| Halaman HarmonyOS | 2 | 3 | 7 |
| Middleware | 7 | 8 | 9 |
| Test PHP | 18 | 18 | 133 |

---

## Sistem Keamanan (umum untuk tiga versi)

Pertahanan berlapis 18 lapis: captcha → konfirmasi kata sandi → verifikasi acak → pemindaian keamanan → pemblokiran serangan → HTTPS + AES-256-CBC → JWT → kontrol sesi → penguncian akun → RBAC → rate limit → proteksi ID → enkripsi request → enkripsi penyimpanan → masking tampilan → audit → CSP → watermark hak cipta

---

## Jalur Migrasi

```
Lite
  │
  │  + 6 modul bantu + panel + ekspor
  ▼
Standard
  │
  │  + 6 modul lanjutan + 12 fitur ekstensi
  ▼
Full
```

Upgrade hanya perlu mengeksekusi file migrasi SQL batch yang sesuai, tanpa migrasi data atau perubahan destruktif.

---

## Alur Demo

**Persiapan**: sudah dieksekusi `docs/install.sql` (struktur tabel lengkap, berisi tabel semua versi); `admin/.env` sudah dikonfigurasi koneksi database. Perbedaan versi ada di pendaftaran route dan visibilitas fungsi, struktur tabel disatukan menjadi lengkap.

### Lite

1. Eksekusi data demo: `cd admin && php ../scripts/demo_data.php` (idempoten, dapat diulang)
2. Cakupan data demo: komunitas/gedung/unit/tipe ruangan/properti/pemilik/penyewa/biaya/tagihan/pengumuman + akun demo, mencakup modul inti Lite
3. Lihat apa: dashboard panel admin + CRUD user/peran/izin/konfigurasi/log + properti/pemilik/penyewa/biaya/perbaikan/pengumuman; portal pemilik registrasi/login、beranda、properti saya、bayar tagihan、perbaikan、pengumuman
4. Perbedaan route: hanya grup Lite terdaftar, blok yang dibungkus `edition_supports('standard'/'full')` tidak terdaftar (`admin/config/route.php`)

### Standard

1. Eksekusi data demo: `cd admin && php ../scripts/demo_data.php` (idempoten, ulangi hanya melengkapi yang kurang tidak membuat data duplikat)
2. Data modul bantu sedikit, parkir/peralatan/keluhan/tamu/kontrak/pemasukan-pengeluaran cukup diisi sedikit oleh demo
3. Lihat apa: panel admin baru tempat parkir/kendaraan、aset peralatan+perawatan、penanganan keluhan+kunjungan balik、persetujuan tamu、manajemen kontrak、manajemen pemasukan/pengeluaran+statistik; portal pemilik baru kendaraan/tempat parkir saya、rekaman parkir、reservasi tamu/kode akses
4. Perbedaan route: tambah grup `edition_supports('standard')`, grup Lite dipertahankan

### Full

1. Eksekusi data demo: `cd admin && php ../scripts/demo_data.php` (idempoten)
2. Data demo modul lanjutan (pembayaran/persetujuan/voting/toko/pemeliharaan/face/grup/knowledge base) diisi sesuai kebutuhan, atau langsung buat data dengan akun demo
3. Lihat apa: di atas Standard tambah patroli/kebersihan/hijau/energi/karyawan/template notifikasi/mesin persetujuan/order pembayaran/voting/SLA/penagihan/pemeliharaan/toko/face/grup/knowledge base; portal pemilik daftar aktivitas、notifikasi pesan、voting、order toko、tanya jawab cerdas、registrasi face
4. Perbedaan route: registrasi penuh, grup `edition_supports('full')` berlaku (`admin/config/route.php`)

### Beralih Versi

```bash
# admin/.env set versi target (meningkat bertahap, full mencakup semua fungsi)
EDITIONS=lite|standard|full

# Restart webman agar berlaku (deploy container: docker compose restart app; bare metal: php start.php restart)
```

- Konfigurasi fail-fast: nilai `EDITIONS` tidak valid langsung throw error (`admin/config/edition.php`), tidak akan diam-diam fallback ke versi salah.
- Skrip data demo idempoten, beralih versi tidak perlu bersihkan database; data modul Standard/Full sedikit, diisi oleh bisnis nyata saja.
