# Dokumen Desain Fitur (Feature Design)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

<img src="../../../images/pet_xiaozhu.svg" alt="小筑 · project mascot" width="110" align="right">

<img src="../../../images/design_function.svg" alt="Panorama Modul Fungsi" width="1000">

> English edition: `../../../images/design_function_en.svg`


## Ikhtisar

Sistem Manajemen Properti dibagi menjadi **panel admin** (digunakan internal perusahaan properti) dan **portal pemilik** (pemilik/penyewa komunitas), mencakup 15 modul bisnis, diserahkan dalam 3 batch.

---

## Batch 1: Bisnis Inti

### 1. Manajemen Komunitas (Community)

**Panel admin:**
- Daftar komunitas (pencarian、paginasi、filter status)
- Buat/lihat/edit/hapus komunitas
- Informasi komunitas: nama、alamat (provinsi-kota-kabupaten)、luas bangunan、jumlah gedung、jumlah unit rumah、pengembang、perusahaan properti、nomor telepon
- Hapus perlu konfirmasi kata sandi kedua, menggunakan soft delete

**Portal pemilik:** Tanpa perlu permission manajemen, beranda menampilkan informasi komunitas yang terikat.

### 2. Manajemen Gedung (Building)

**Panel admin:**
- Filter daftar gedung per komunitas
- Buat/lihat/edit/hapus gedung
- Informasi gedung: nama、tipe (menara/papan/villa/komersial)、jumlah lantai、jumlah unit、jumlah lift、tahun dibangun、tipe struktur
- Mendukung pengurutan

### 3. Manajemen Unit (Unit)

**Panel admin:**
- Filter daftar unit per gedung
- Buat/lihat/edit/hapus unit
- Informasi unit: nama、jumlah rumah per lantai

### 4. Manajemen Tipe Ruangan (RoomType)

**Panel admin:**
- CRUD daftar tipe ruangan
- Informasi tipe ruangan: nama (3 kamar 2 ruang tamu)、jumlah kamar/ruang tamu/kamar mandi、denah

### 5. Manajemen Properti (Room)

**Panel admin:**
- Tampilan pohon rumah (komunitas→gedung→unit→rumah)
- Buat/lihat/edit/hapus rumah
- Informasi rumah: nomor rumah、lantai、tipe ruangan、luas (dalam ruangan/bagikan/total)、orientasi、dekorasi、fungsi (hunian/komersial/kantor)、status (kosong/terjual/disewa/dihuni sendiri)
- Bind/unbind pemilik massal

**Portal pemilik:**
- Lihat daftar properti yang saya bind
- Lihat detail properti (luas、orientasi、tipe ruangan、informasi kepemilikan)

### 6. Manajemen Pemilik (Owner)

**Panel admin:**
- Daftar pemilik (pencarian、paginasi、filter status)
- Buat/lihat/edit/hapus pemilik
- Informasi pemilik: nama、nomor ponsel (terenkripsi)、email (terenkripsi)、KTP (terenkripsi)、jenis kelamin、tanggal lahir、kontak darurat、tanggal check-in
- Impor massal (Excel)、aktif/nonaktif massal、hapus massal
- Bind/unbind properti

**Portal pemilik:**
- Registrasi (nomor ponsel+kata sandi+captcha, dapat validasi bind properti)
- Login (nomor ponsel+kata sandi+captcha klik, proteksi penguncian akun)
- Lihat/ubah informasi pribadi
- Ubah kata sandi、logout

### 7. Manajemen Penyewa (Tenant)

**Panel admin:**
- Filter daftar penyewa per properti/pemilik rumah
- Buat/lihat/edit/hapus penyewa
- Informasi penyewa: nama、nomor ponsel (terenkripsi)、KTP (terenkripsi)、awal-akhir kontrak sewa、sewa bulanan、status

### 8. Manajemen Biaya (Fee)

**Tipe biaya (panel admin):**
- CRUD tipe biaya: biaya properti、air、listrik、gas、pemanas、biaya parkir、dana perbaikan、lainnya
- Harga satuan、unit penagihan (RMB/m²/bulan、RMB/ton、RMB/kWh dll.)、periode penagihan (bulanan/kuartalan/tahunan)、apakah wajib

**Manajemen tagihan (panel admin):**
- Cek tagihan per komunitas/gedung/properti
- Buat/edit tagihan manual
- Generate tagihan massal (pilih komunitas+tipe biaya+periode, otomatis generate untuk semua rumah)
- Informasi tagihan: tipe biaya、jumlah、denda keterlambatan、periode biaya、tanggal jatuh tempo
- Status: belum bayar/sebagian bayar/sudah bayar/terlambat/dibebaskan
- Notifikasi penagihan massal

**Tagihan (portal pemilik):**
- Daftar tagihan saya (filter per status: belum bayar/sudah bayar/terlambat)
- Detail tagihan
- Bayar online (WeChat/Alipay, perlu konfirmasi kata sandi kedua)
- Cek rekaman pembayaran
- Statistik biaya (trend tahunan-bulanan、proporsi kategori biaya)

**Rekaman pembayaran (panel admin):**
- Cek rekaman pembayaran
- Registrasi penerimaan offline (tunai/kartu/transfer bank)

### 9. Manajemen Permintaan Perbaikan (Repair)

**Panel admin:**
- Daftar perbaikan (filter per status/kategori)
- Lihat detail perbaikan
- Dispatch (alokasikan petugas perbaikan)
- Update progres perbaikan

**Portal pemilik:**
- Daftar perbaikan saya
- Submit perbaikan (pilih properti、kategori、tingkat urgensi、deskripsi、upload gambar、waktu janji)
- Lihat detail dan progres perbaikan
- Batalkan perbaikan (hanya status menunggu dispatch, perlu konfirmasi kata sandi)
- Penilaian perbaikan (1-5 bintang + penilaian teks)

### 10. Pengumuman (Announcement)

**Panel admin:**
- CRUD daftar pengumuman
- Terbitkan pengumuman per komunitas
- Kategori: notifikasi/pengumuman/pengingat/aktivitas
- Pin、status draft/terbit

**Portal pemilik:**
- Lihat daftar pengumuman yang sudah diterbitkan (filter per kategori)
- Detail pengumuman

---

## Batch 2: Bisnis Pendukung

### 11. Manajemen Parkir (Parking)

**Panel admin:**
- Manajemen tempat parkir (nomor、atas/bawah tanah、luas、status: kosong/terjual/disewa/diperbaiki)
- Manajemen kendaraan (plat nomor terenkripsi、merek、warna、tipe、bind tempat parkir/pemilik)
- Cek rekaman parkir (waktu masuk/keluar、durasi tinggal、biaya)

**Portal pemilik:**
- Daftar kendaraan saya
- Daftar tempat parkir saya
- Cek rekaman parkir

### 12. Manajemen Peralatan (Equipment)

**Panel admin:**
- Aset peralatan (nama、nomor、kategori: lift/pemadam kebakaran/akses kontrol/CCTV/saluran air/listrik/HVAC)
- Informasi peralatan: merek、model、lokasi pemasangan、tanggal pemasangan、kedaluwarsa garansi、umur desain
- Rekaman perawatan: inspeksi harian/perawatan berkala/perbaikan kerusakan/overhaul/penggantian
- Personel perawatan、biaya、unit perawatan、tanggal perawatan berikutnya

### 13. Keluhan dan Saran (Complaint)

**Panel admin:**
- Daftar keluhan (filter per tipe/status)
- Tangani keluhan (alokasikan penanggung jawab、isi catatan penanganan)
- Registrasi kunjungan balik (catatan kunjungan balik、rekaman kepuasan)

**Portal pemilik:**
- Daftar keluhan/saran saya
- Submit keluhan/saran (tipe: keluhan/saran/pujian, kategori: layanan/lingkungan/keamanan/fasilitas/kebisingan/bangunan liar)
- Mendukung submit anonim、upload gambar
- Lihat progres penanganan
- Penilaian kepuasan

### 14. Manajemen Tamu (Visitor)

**Panel admin:**
- Persetujuan reservasi tamu
- Cek rekaman tamu

**Portal pemilik:**
- Reservasi tamu (nama tamu、telepon、KTP、plat nomor、jumlah orang rombongan、keperluan kunjungan、perkiraan waktu)
- Generate kode akses
- Ubah/batalkan reservasi

### 15. Manajemen Kontrak (Contract)

**Panel admin:**
- Daftar kontrak (filter per tipe/status)
- Tipe kontrak: kontrak properti/kontrak sewa/kontrak perawatan/kontrak layanan/kontrak pengadaan
- Informasi kontrak: nomor、pihak A dan B、jumlah、tanggal mulai-berakhir、tanggal penandatanganan、lampiran
- Status: draft/berjalan/sudah kedaluwarsa/sudah dihentikan/perpanjangan

### 16. Manajemen Keuangan (Finance)

**Panel admin:**
- Manajemen pemasukan (biaya properti/biaya parkir/sewa/biaya iklan/dana perbaikan/lainnya)
- Manajemen pengeluaran (SDM/pengadaan peralatan/perawatan/energi/kebersihan penghijauan/kantor/pajak/lainnya)
- Laporan statistik pemasukan-pengeluaran (bulanan/kuartalan/tahunan)

---

## Batch 3: Fungsi Lanjutan

### 17. Patroli Keamanan (Security Patrol)

**Panel admin:**
- Manajemen rute patroli (koordinat rute、titik check-in)
- Rekaman patroli (waktu mulai/selesai、durasi、catatan anomali)
- Statistik tingkat penyelesaian patroli

### 18. Manajemen Kebersihan (Cleaning)

**Panel admin:**
- Manajemen area kebersihan (lokasi、luas、frekuensi: harian/mingguan/dua mingguan/bulanan)
- Rekaman kebersihan (waktu pembersihan、pemeriksa、catatan pemeriksaan、gambar lokasi)
- Statistik tingkat penyelesaian kebersihan

### 19. Manajemen Penghijauan (Green)

**Panel admin:**
- Manajemen area hijau (lokasi、luas、tanaman utama)
- Rekaman perawatan (penyiraman/pemangkasan/pemupukan/pengendalian hama/penanaman ulang、biaya)

### 20. Aktivitas Komunitas (Activity)

**Panel admin:**
- Manajemen aktivitas (judul、konten、kategori: olahraga/liburan/amal/ceramah/keluarga)
- Gambar sampul、lokasi、jumlah peserta maksimal、waktu、biaya
- Status: sedang daftar/sedang berlangsung/sudah selesai/sudah dibatalkan
- Lihat daftar pendaftaran

**Portal pemilik:**
- Daftar aktivitas (filter: sedang daftar/sedang berlangsung)
- Detail aktivitas
- Daftar ikut/batalkan pendaftaran

### 21. Manajemen Energi (Energy)

**Panel admin:**
- Manajemen meter (meter listrik/air/gas/pemanas、nomor)
- Rekaman pencatatan meter (pembacaan kali ini、pemakaian、harga satuan、biaya)
- Generate tagihan terkait otomatis

### 22. Manajemen Karyawan (Staff)

**Panel admin:**
- Informasi karyawan (nama、nomor ponsel terenkripsi、KTP terenkripsi、jabatan、departemen、tanggal masuk)
- Departemen: manajemen/layanan pelanggan/teknik/keamanan/kebersihan/penghijauan/keuangan
- Status: aktif/keluar/cuti

---

## Visualisasi Panel dan Ekspor

### Panel Dashboard

**Dashboard panel admin:**
- Kartu indikator inti: total piutang、total penerimaan nyata、rasio tunggakan、rasio hunian
- Grafik garis tren biaya (bulanan/kuartalan)
- Pie chart kategori biaya
- Statistik perbaikan (per kategori、per status)
- Statistik keluhan
- Log operasi terbaru

**Beranda portal pemilik:**
- Jumlah properti saya、jumlah tagihan belum dibayar、jumlah perbaikan diproses、pengumuman terbaru

### Ekspor Excel

- Ekspor daftar pemilik
- Ekspor laporan tagihan
- Ekspor rekaman pembayaran
- Ekspor laporan keuangan
- Data sensitif otomatis di-mask saat ekspor

### Ekspor PDF

- Ekspor visualisasi panel dashboard
- Laporan keuangan PDF (hak cipta header halaman + watermark hak cipta footer yang tidak bisa dihapus)
- Layout lanskap A4

---

## Fitur Lintas Modul

| Fitur | Deskripsi |
|------|------|
| Proteksi ID | Semua ID endpoint menggunakan encoding hashids untuk transfer |
| Enkripsi data | Field sensitif (ponsel/email/KTP) lapisan API AES-256-CBC、lapisan DB encryptable |
| Audit operasi | Semua operasi POST/PUT/DELETE admin tercatat otomatis, termasuk deteksi otomatis sumber |
| Kontrol izin | Granularitas RBAC method.path, super admin ditandai * |
| Proteksi rate limit | Sliding window Redis, login 10 kali/menit, registrasi 5 kali/menit |
| Captcha | Captcha Mandarin model klik, wajib untuk login/registrasi |
| Soft delete | Pemilik、komunitas、properti、pengumuman mendukung soft delete |
| Internasionalisasi | Dua bahasa Mandarin/Inggris, PHP symfony/translation + Flutter GetX Translations, default Mandarin、fallback Inggris |
| Dokumentasi API | `hg/apidoc` dibuat otomatis, 57 dari 58 controller diberi anotasi sesuai 10 grup (Base/Docs/Install tidak digrup), `/apidoc/config` menyediakan API konfigurasi |
| Pengujian | Alur TDD, 133 test/465 assertion, service 100% lulus, flutter analyze nol masalah |
| Flutter Web | 13 halaman (login/beranda/biaya/perbaikan/pusat pribadi dll.), gaya desktop PC, manajemen state GetX |
| HarmonyOS | Kerangka proyek lengkap, layer layanan ArkTS + autentikasi + login/beranda, @ohos.net.http |

## Fitur Ekstensi (Batch 4)

### Pusat Notifikasi Pesan
- Template notifikasi dapat dikonfigurasi (push App/SMS/email)
- Pengingat tagihan、progres perbaikan、pengumuman otomatis notifikasi
- Daftar pesan portal pemilik + manajemen sudah dibaca

### Mesin Alur Persetujuan
- Tipe persetujuan dan langkah dapat dikonfigurasi (atasan→manajer→direktur)
- Dispatch perbaikan/persetujuan tamu/persetujuan kontrak melalui alur standar
- Rekaman persetujuan dapat dilacak

### Integrasi Pembayaran
- Manajemen order pembayaran WeChat/Alipay
- Pemrosesan callback pembayaran、refund、statistik rekonsiliasi
- Update otomatis tagihan terkait

### Voting/Pemungutan Suara Pemilik
- Voting biasa + pemungutan suara rapat pemilik (bobot luas)
- Manajemen opsi、rekaman voting、penghitungan suara otomatis
- Statistik tingkat partisipasi

### Eskalasi SLA Otomatis Perbaikan
- Konfigurasi batas waktu respons/selesai sesuai kategori+tingkat urgensi
- Timeout otomatis eskalasi ke peran atasan
- Denda timeout tercatat otomatis

### Penagihan Cerdas
- Konfigurasi strategi penagihan bertahap (hari keterlambatan→tindakan)
- Otomatis cocokkan tagihan terlambat eksekusi penagihan (App/SMS/telepon/kunjungan)
- Perhitungan otomatis denda keterlambatan

### Pemeliharaan Mobile
- Dispatch tugas pemeliharaan (rute GPS + titik pemeriksaan)
- Check-in mobile (lokasi + foto + penanda anomali)
- Statistik tingkat penyelesaian pemeliharaan

### Toko Komunitas
- Manajemen kategori produk/tayang/turunkan
- Pemilik lihat + order + lacak order
- Manajemen pengiriman/refund

### Pengenalan Wajah
- Registrasi wajah pemilik (terhubung layanan pengenalan pihak ketiga)
- Review autentikasi panel admin
- Kaitan akses kontrol gerbang

### Manajemen Grup Multi-Komunitas
- Kaitan banyak-ke-banyak grup→komunitas
- Agregasi data lintas komunitas (tampilan terpadu properti/pemilik/penagihan)

### Tanya Jawab Cerdas
- Manajemen knowledge base (kategori/artikel/kata kunci)
- Pertanyaan pemilik otomatis dicocokkan
- Rekaman percakapan + statistik tingkat solusi

### Data Besar
- Visualisasi data properti real-time layar penuh
- Empat panel besar penagihan/perbaikan/peralatan/energi
- Refresh rotasi otomatis
