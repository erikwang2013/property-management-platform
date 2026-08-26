# Rencana SaaS Multi-Tenant (Multi-Tenant Plan)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Status: Draft review (P3-① tugas awal) | Tanggal: 2026-08-16

## 1. Inventaris Status Saat Ini

### 1.1 Klasifikasi Struktur Tabel (65 tabel, diverifikasi docs/install.sql)

| Kategori | Tabel | Deskripsi |
|------|-----|------|
| Tabel global/platform | erik_admin_user / admin_role / admin_permission / admin_user_role / admin_role_permission、erik_system_config、erik_operation_log | Autentikasi, konfigurasi, audit, secara alami level platform, tidak terikat tenant |
| Tabel dimensi komunitas | erik_community dan 40+ tabel bisnis yang dimiliki melalui community_id (building/unit/room/owner/fee_*/repair_order/parking_*/announcement dll.) | Dimiliki tenant secara tidak langsung melalui community_id |
| Tabel kaitan grup | erik_group (grup)、erik_group_community (grup↔komunitas) | Saat ini **kaitan opsional**, tanpa semantik tenant, agregasi lintas area mengandalkan join |
| Tabel ekstensi platform | erik_notification_template、erik_knowledge_base、erik_mall_*、erik_face_info dll. | Sebagian level platform, sebagian level komunitas, perlu konfirmasi per kasus |
| Tabel yang mudah membingungkan | **erik_tenant (tabel penyewa)** | ⚠️ Konflik semantik: adalah "penyewa rumah" (dimensi room_id/owner_id), **bukan** tenant SaaS |

### 1.2 Rantai Autentikasi (sisi admin, diverifikasi kode)

```
Middleware global: Cors → SecurityFilter → RateLimit
Middleware grup route: AdminAuth(JWT → $request->adminId) → AdminPermission(RBAC method.path) → OperationLog → Controller
```

- `AdminAuth` sudah membangun pola injeksi request (`$request->adminId`), konteks tenant dapat direplikasi penuh
- `AdminPermission` adalah RBAC level platform, **ortogonal** dengan isolasi tenant, dapat ditumpuk
- Portal pemilik service: JWT membawa owner_id, data secara alami dibatasi melalui room_owner → room.community_id, risiko lintas tenant rendah

### 1.3 Kesimpulan Kunci

- Tidak ada model tenant SaaS yang ada; nama `erik_tenant` sudah dipakai penyewa, konsep baru harus menghindari nama tersebut
- Semua controller langsung query Eloquent, tanpa layer repository, tanpa global scope — perubahan isolasi perlu dilakukan di layer model
- config/database.php single connection, tetapi illuminate/database mendukung multiple connection secara native (cadangan untuk evolusi database terpisah)

## 2. Perbandingan Solusi dan Rekomendasi

| Solusi | Mekanisme | Besar perubahan | Biaya operasional | Cocok untuk |
|------|------|--------|----------|------|
| **A. Shared database + isolasi baris tenant_id (disarankan)** | Tabel tenant + kolom tenant_id tabel bisnis + filter global scope Eloquent | Sedang (2 tabel tambah kolom + middleware + global scope + backfill data lama) | Rendah (backup/migrasi satu database tidak berubah) | Properti menengah-kecil, satu tenant <5 juta baris |
| B. Database terpisah (satu database per tenant) | Routing koneksi + agregasi lintas database | Tinggi (manajemen koneksi/laporan lintas database/migrasi×N/backup×N) | Tinggi | Grup besar, kebutuhan isolasi kepatuhan |
| C. Hybrid (database sensitif terpisah + shared) | Kombinasi A+B | Tinggi | Tinggi | Skenario isolasi kuat seperti pembayaran/face |

**Rekomendasi A, B sebagai arah evolusi.** Alasan:

1. 65 tabel yang ada terpadu dalam satu database, model data tenant_id A tidak menghalangi pemecahan database di masa depan (granularitas filter dari baris menjadi database saja, di bawah solusi A tenant ID sudah dimodelkan global)
2. Data bisnis semuanya dimiliki melalui community_id, tenant_id hanya perlu ditambahkan di **tabel tingkat atas**, 40 tabel bisnis di tengah dijamin oleh jalur akses, menghindari penambahan kolom per tabel
3. Kedua sisi (admin/service) berbagi model data yang sama, perubahan A terpusat di layer runtime admin
4. Di bawah status deployment single-host, kompleksitas backup/migrasi B tidak tertahankan

## 3. Desain Titik Isolasi

### 3.1 Model Data (set minimal)

- Buat baru `erik_platform_tenant` (hindari konflik dengan tabel penyewa erik_tenant): id/name/status/created_at dll.
- `erik_community` tambah `tenant_id BIGINT NOT NULL DEFAULT 0`, indeks `(tenant_id, community_id)`
- `erik_admin_user` tambah `tenant_id BIGINT NOT NULL DEFAULT 0` (0 = super admin platform)
- Tabel perantara bisnis (building/room/fee_bill dll. 40 tabel) **tidak tambah kolom**, dimiliki melalui community_id

### 3.2 Tiga Perangkat Layer Runtime

1. **Middleware TenantContext**: payload JWT tambah klaim `tenant_id` → `$request->tenantId` (mereplikasi pola injeksi AdminAuth); daftar izin route login/instalasi/level platform (user/role/permission/config)
2. **Global scope TenantScope**: untuk Community dan model bisnis level platform pasang global scope Eloquent, filter otomatis sesuai `$request->tenantId`; `find()` juga dibatasi scope, secara alami mencegah query langsung single-record lintas tenant
3. **Konteks eksplisit Tenant::for()**: tugas terjadwal/antrian/impor tanpa request HTTP, gunakan closure untuk menentukan tenant secara eksplisit; saat konteks hilang **fail-closed** (tolak query), tidak mengizinkan pelolosan tanpa filter secara diam-diam

### 3.3 Poin Uji Proteksi Otorisasi Berlebih (matriks penerimaan)

| Kasus uji | Ekspektasi |
|------|------|
| Admin tenant A list community/building/fee_bill milik tenant B | Kembalikan kosong atau hanya data A |
| Admin tenant A find/update/delete satu rekaman tenant B (query langsung id) | 403 / data kosong / tolak |
| Admin platform (tenant_id=0) operasi lintas tenant | Izinkan (kemampuan level platform) |
| Pemilik service operasi lintas komunitas (bayar/perbaikan) | Tolak (validasi kepemilikan community) |
| Tugas terjadwal/antrian tanpa menentukan konteks tenant | fail-closed error, bukan tanpa filter |

## 4. Jalur Evolusi (migrasi bertahap)

| Langkah | Konten | Penerimaan |
|------|------|------|
| 1. Layer data | Buat tabel platform_tenant + tambah kolom community/admin_user + migrasi idempoten + inisialisasi tenant default dan backfill data lama | Setiap community wajib terikat tenant, laporan data yatim piatu nol |
| 2. Layer runtime | Middleware TenantContext + TenantScope + alat Tenant::for() + daftar izin route | Regresi satu tenant: semua 133 tes lulus |
| 3. Modul pilot | Manajemen grup → komunitas → pemilik → biaya (tagihan) empat modul dulu aktifkan isolasi | Matriks uji otorisasi berlebih lulus |
| 4. Peluncuran penuh | Sesuai batch (Batch 1 inti → Batch 2 bantu → modul ekstensi) aktifkan isolasi per modul | Semua matriks otorisasi berlebih modul lulus |
| 5. Evolusi | Saat data satu tenant >5 juta baris atau kebutuhan kepatuhan, evaluasi pemecahan database (solusi B), model data A tidak memblokir | Review solusi pemecahan database |

Strategi migrasi data: semua data lama dimasukkan ke "tenant default" (dibuat skrip migrasi), tidak menghapus atau mengubah data bisnis; skrip migrasi idempoten, dapat dieksekusi berulang.

## 5. Daftar Risiko

| Risiko | Dampak | Mitigasi / Rollback |
|------|--------|-------------|
| Perubahan jalur query 58+17 controller besar | Semua endpoint bisnis | Global scope mencakup ~80% daftar/detail; raw query dan impor massal pakai Tenant::for(); gray release per batch |
| Global scope salah memengaruhi query level platform (agregasi lintas area dashboard) | Dashboard/laporan | Endpoint level platform eksplisit Tenant::without() atau bypass tenant_id=0 |
| Tugas terjadwal/antrian tanpa konteks request | Tugas background penagihan/SLA/notifikasi dll. | Bungkus eksplisit Tenant::for() + fail-closed |
| Kesalahan backfill data lama | Semua data lama | Skrip idempoten + validasi backfill + mode dry-run |
| Dampak indeks/performa | Tabel frekuensi tinggi (fee_bill/room/owner) | Indeks gabungan (tenant_id, community_id); tinjau ulang log slow query |
| Regresi 133 tes | Semua | Setelah injeksi scope, jalankan regresi penuh dulu baru mulai pilot |
| Kebingungan nama (penyewa erik_tenant vs tenant SaaS) | Kognisi pengembangan | Nama tabel baru platform_tenant, deklarasi eksplisit di dokumentasi |
| **Rencana rollback** | — | Global scope dapat dimatikan sekali klik melalui saklar konfigurasi (kembali ke semantik single-tenant), kolom data dipertahankan tidak dihapus, tanpa perubahan destruktif |

## 6. Kesimpulan Review

**Disarankan segera dilakukan**:
- Shared database + isolasi baris tenant_id (solusi A), buat tabel `erik_platform_tenant` baru, tambah kolom community/admin_user
- Middleware TenantContext + global scope TenantScope + alat Tenant::for()
- Urutan pilot: grup → komunitas → pemilik → biaya
- Dependensi awal: sudah selesai — tabel/kolom/backfill multi-tenant sudah inline ke docs/install.sql (digabung 2026-08-16, entry pembuatan database tunggal)

**Disarankan ditunda**:
- Isolasi database terpisah (B): hanya dimulai saat satu tenant >5 juta baris atau kebutuhan kepatuhan, model data sudah dicadangkan
- Solusi hybrid (C): evaluasi lagi jika pelanggan secara eksplisit meminta skenario isolasi kuat pembayaran/face

**Tidak disarankan**:
- Isolasi level schema (MySQL tanpa semantik schema independen, biaya setara database terpisah)
- Routing multi-database dinamis (tanpa manfaat di bawah deployment single-host)
- Schema/field personalisasi level tenant (YAGNI)
- Menggunakan/mengubah tabel penyewa erik_tenant sebagai tenant SaaS (konflik semantik, merusak bisnis penyewa)
