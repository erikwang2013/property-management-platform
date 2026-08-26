# Dokumentasi Fitur (Features)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## Daftar Fitur

| No | Modul | Batch | Panel admin | Portal pemilik | Tabel data |
|------|------|---------|---------|--------|--------|
| 1 | Manajemen komunitas | Batch 1 | CRUD + pencarian & paginasi | Lihat komunitas terikat | erik_community |
| 2 | Manajemen gedung | Batch 1 | CRUD + filter per komunitas | - | erik_building |
| 3 | Manajemen unit | Batch 1 | CRUD + filter per gedung | - | erik_unit |
| 4 | Manajemen tipe ruangan | Batch 1 | CRUD | - | erik_room_type |
| 5 | Manajemen properti | Batch 1 | CRUD + pohon rumah + bind pemilik massal | Daftar/detail properti saya | erik_room |
| 6 | Manajemen pemilik | Batch 1 | CRUD + impor massal/aktif-nonaktif/hapus | Registrasi/login/info pribadi | erik_owner, erik_room_owner |
| 7 | Manajemen penyewa | Batch 1 | CRUD + filter per properti | - | erik_tenant |
| 8 | Manajemen biaya | Batch 1 | CRUD tipe biaya + manajemen tagihan + generate massal + penerimaan offline | Cek tagihan + bayar online + statistik biaya | erik_fee_type, erik_fee_bill, erik_fee_payment |
| 9 | Manajemen perbaikan | Batch 1 | Daftar perbaikan + dispatch + update progres | Submit perbaikan + lihat progres + penilaian | erik_repair_order, erik_repair_progress |
| 10 | Pengumuman | Batch 1 | CRUD + terbit/pin | Daftar/detail pengumuman | erik_announcement |
| 11 | Manajemen parkir | Batch 2 | Manajemen tempat/kendaraan + rekaman parkir | Tempat/kendaraan saya + rekaman parkir | erik_parking_space, erik_parking_vehicle, erik_parking_record |
| 12 | Manajemen peralatan | Batch 2 | Aset peralatan + rekaman pemeliharaan | - | erik_equipment, erik_equipment_maintenance |
| 13 | Keluhan dan saran | Batch 2 | Daftar keluhan + penanganan + kunjungan balik | Submit keluhan + lihat progres + penilaian | erik_complaint |
| 14 | Manajemen tamu | Batch 2 | Persetujuan tamu + cek rekaman | Reservasi tamu + kode akses | erik_visitor |
| 15 | Manajemen kontrak | Batch 2 | CRUD + manajemen status | - | erik_contract |
| 16 | Manajemen keuangan | Batch 2 | Manajemen pemasukan/pengeluaran + laporan statistik | - | erik_finance_income, erik_finance_expense |
| 17 | Patroli keamanan | Batch 3 | Rute patroli + rekaman patroli | - | erik_security_patrol, erik_patrol_record |
| 18 | Manajemen kebersihan | Batch 3 | Area kebersihan + rekaman kebersihan | - | erik_cleaning_area, erik_cleaning_record |
| 19 | Manajemen penghijauan | Batch 3 | Area hijau + rekaman perawatan | - | erik_green_area, erik_green_maintenance |
| 20 | Aktivitas komunitas | Batch 3 | Manajemen aktivitas + lihat pendaftaran | Daftar aktivitas + daftar | erik_community_activity, erik_activity_signup |
| 21 | Manajemen energi | Batch 3 | Manajemen meter + rekaman pencatatan meter | - | erik_energy_meter, erik_energy_record |
| 22 | Manajemen karyawan | Batch 3 | CRUD + manajemen status | - | erik_staff |

## Fitur Ekstensi (Batch 4 — 12 modul)

| No | Modul | Panel admin | Portal pemilik | Tabel data |
|------|------|---------|--------|--------|
| 23 | Notifikasi pesan | CRUD template + kirim manual + daftar | Pesan saya + tandai sudah dibaca | erik_notification_template, erik_notification |
| 24 | Alur persetujuan | Tipe persetujuan + instance + alur langkah | - | erik_approval_type, erik_approval, erik_approval_record |
| 25 | Integrasi pembayaran | Manajemen order + refund + callback WeChat/Alipay | - | erik_payment_order |
| 26 | Voting pemilik | CRUD voting + opsi + statistik berbobot luas | Daftar voting + voting + bobot luas | erik_vote, erik_vote_option, erik_vote_record |
| 27 | Eskalasi SLA otomatis | Konfigurasi aturan + cek timeout + denda | - | erik_sla_rule, erik_sla_record |
| 28 | Penagihan cerdas | Konfigurasi strategi + pencocokan keterlambatan + denda | - | erik_collection_strategy, erik_collection_record |
| 29 | Pemeliharaan mobile | Dispatch tugas + GPS check-in + foto | - | erik_inspection_task, erik_inspection_checkpoint |
| 30 | Toko komunitas | Manajemen kategori/produk/order/pengiriman | Lihat produk + order + order saya | erik_mall_category, erik_mall_product, erik_mall_order |
| 31 | Pengenalan wajah | Manajemen review | Registrasi wajah + status autentikasi | erik_face_info |
| 32 | Manajemen grup | CRUD grup + kaitan komunitas + agregasi lintas area | - | erik_group, erik_group_community |
| 33 | Tanya jawab cerdas | Knowledge base + riwayat percakapan + statistik | Bertanya + pencocokan kata kunci | erik_knowledge_base, erik_chat_record |
| - | Data besar | Visualisasi data properti real-time layar penuh | - | (reuse endpoint data yang ada) |

## Modul Panel Admin (sudah ada di admin)

| Modul | Fungsi |
|------|------|
| Dashboard | Statistik real-time/trend/distribusi/log (cache Redis 5m) |
| Manajemen pengguna | CRUD pengguna admin + hapus massal/aktif-nonaktif + impor Excel |
| Peran & izin | CRUD + pohon izin + otorisasi RBAC method.path |
| Konfigurasi sistem | CRUD key-value |
| Audit operasi | Cek log + deteksi otomatis 8 sumber platform |
| Manajemen file | Upload + ekspor Excel/PDF (masking data sensitif) |
| Manajemen keamanan | Pertahanan berlapis 18 lapis + security.txt |
| Monitoring operasional | Health check + metrik Prometheus + dokumentasi API |
| Internasionalisasi | Dua bahasa Mandarin/Inggris, PHP symfony/translation + Flutter GetX Translations + qualifier resource HarmonyOS |
| Dokumentasi API | Dibuat otomatis `hg/apidoc`, admin 10 grup + service 9 grup, diorganisasi per modul fungsi |

## Fitur Lintas Modul

### Enkripsi transfer ID
Semua field ID dalam request dan respons API menggunakan encoding/dekoding `erikwang2013/hashids`. Client menerima string hashid (contoh `aB3xK9mW2pQ7rT5v`), backend mendekode menjadi BIGINT untuk beroperasi.

### Proteksi data sensitif
- Lapisan transfer API: `erikwang2013/encryption` — AES-256-CBC
- Lapisan penyimpanan database: `erikwang2013/encryptable` — cast Eloquent Model enkripsi/dekripsi otomatis
- Lapisan tampilan frontend: nomor ponsel 138****1234, email a***@e.com

### Audit operasi
Semua operasi POST/PUT/DELETE panel admin tercatat otomatis, berisi user operasi, IP, path, parameter (sudah di-mask), waktu operasi, sumber (web/ios/android/harmonyos/windows/macos/linux/ipados).

### Kontrol izin
- Panel admin: otorisasi granularitas RBAC method.path, super admin `*` melewati pemeriksaan
- Portal pemilik: autentikasi JWT Bearer Token, pemilik hanya bisa mengoperasikan datanya sendiri

### Perlindungan keamanan
Pertahanan berlapis 18 lapis: captcha → konfirmasi kata sandi → verifikasi acak → pemindaian keamanan → pemblokiran serangan → enkripsi transfer → JWT → kontrol sesi → penguncian akun → RBAC → rate limit → proteksi ID → enkripsi request → enkripsi penyimpanan → masking tampilan → audit → CSP → watermark hak cipta

### Fungsi ekspor
- Excel: PhpSpreadsheet, header biru teks putih + freeze baris pertama + autofilter + masking data sensitif
- PDF: Dompdf A4 lanskap, hak cipta header halaman + watermark hak cipta footer yang tidak bisa dihapus
- Ekspor data visualisasi panel ke PDF

### Mesin pencari
- `erikwang2013/webman-scout` menggerakkan Elasticsearch
- Sinkronisasi indeks otomatis (perubahan tambah/hapus/ubah otomatis didorong)
- Prefiks indeks `erik_`, konsisten dengan prefiks tabel database

### Internasionalisasi (i18n)
- **Backend PHP**: symfony/translation — `resource/translations/{zh_CN,en}/messages.php`, 42 kunci terjemahan, controller mengambil terjemahan melalui metode `__()`
- **Flutter Web**: GetX `Translations` — `lib/i18n/messages.dart`, 101 kunci terjemahan, halaman menggunakan ekstensi `.tr`
- **HarmonyOS**: qualifier resource `resources/{base,en_US}/element/string.json`
- **Bahasa default**: Mandarin Sederhana (zh_CN), fallback bahasa Inggris (en)
- **Request header**: mendukung `Accept-Language` mengontrol bahasa respons

### Cakupan pengujian
- **Framework pengujian**: PHPUnit 12.x
- **Alur TDD**: merah→hijau→refactor, test dulu baru kode
- **Panel admin**: 60 test, 164 assertion, mencakup layanan dasar, konfigurasi lingkungan, verifikasi keamanan
- **Portal pemilik**: 18 test, 45 assertion, tingkat kelulusan 100%
- **Total**: 78 test, 209 assertion
- **Cakupan**: keunikan generator Snowflake ID, round-trip encoding/dekoding Hashids, format respons terpadu, verifikasi skema 64 tabel, konsistensi kunci terjemahan Mandarin-Inggris
- **Flutter**: flutter analyze nol masalah
- **Dokumentasi API**: `hg/apidoc` dibuat otomatis, admin (10 grup) + service (9 grup), dokumentasi interface diorganisasi per modul fungsi
