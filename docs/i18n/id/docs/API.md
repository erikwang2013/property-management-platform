# Dokumentasi API (API Reference)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## Ikhtisar

- API panel admin berjalan di `http://localhost:8787`
- API portal pemilik berjalan di `http://localhost:8788`
- Format respons terpadu: `{"code": 0, "message": "success", "data": {...}}`
- Semua field ID menggunakan encoding hashids untuk transfer
- Versi API dikontrol melalui header request `API-Version` (default `v1`)
- Bahasa dikontrol melalui header request `Accept-Language`（`zh-CN` / `en-US`，default `zh-CN`）

### Dokumentasi API Online

Setelah layanan berjalan akses dokumentasi interaktif yang dibuat otomatis `hg/apidoc`:

| Sisi | Alamat | Jumlah grup |
|----|------|--------|
| Panel admin | `http://localhost:8787/apidoc` | 10 grup（common/dashboard/system/property-core/property-aux/property-adv/extensions/export/import/upload） |
| Portal pemilik | `http://localhost:8788/apidoc` | 9 grup（publik/beranda/biaya/perbaikan/umpan balik/parkir/aktivitas/pribadi/ekstensi） |

---

## API Panel Admin (admin :8787)

### Endpoint Publik — tanpa autentikasi

#### POST /api/captcha/generate
Mendapatkan captcha klik.

Parameter request: tidak ada

Respons:
```json
{
  "code": 0,
  "data": {
    "key": "captcha_key_string",
    "image": "base64_encoded_png",
    "extra": { "targets": ["树", "鸟", "花"] }
  }
}
```

#### POST /api/captcha/verify
Memvalidasi captcha klik.

Parameter request:
| Parameter | Tipe | Deskripsi |
|------|------|------|
| key | string | Key captcha, dikembalikan oleh generate |
| clicks | array | Koordinat klik [{x, y}, ...] |

Respons:
```json
{
  "code": 0,
  "data": { "valid": true }
}
```

Saat validasi gagal `code` adalah 422, `data.valid` adalah `false`.

#### POST /api/auth/login
Login admin.

Parameter request:
| Parameter | Tipe | Deskripsi |
|------|------|------|
| username | string | Username |
| password | string | Kata sandi |
| captcha_key | string | Key captcha |
| clicks | array | Koordinat klik [{x, y}, ...] |

Respons:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "user": { "id": "aB3xK9mW...", "username": "admin", "real_name": "管理员" }
  }
}
```

#### POST /api/auth/refresh
Menyegarkan Token.

Parameter request:
| Parameter | Tipe | Deskripsi |
|------|------|------|
| refresh_token | string | Refresh token |

Respons:
```json
{
  "code": 0,
  "data": { "access_token": "eyJ..." }
}
```

#### GET /health
Health check.

#### GET /metrics
Metrik monitoring Prometheus.

#### GET /api/docs
Dokumentasi OpenAPI.

---

### Endpoint Panel Admin — perlu autentikasi (Bearer Token)

Semua endpoint berprefiks `/admin`, perlu membawa `Authorization: Bearer {access_token}`.

#### Dashboard

**GET /admin/dashboard**
Mendapatkan data statistik dashboard.

#### Manajemen Pengguna Admin

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/user | Daftar user (?keyword=&status=&page=&page_size=) |
| POST | /admin/user | Buat user |
| GET | /admin/user/{hashid} | Detail user |
| PUT | /admin/user/{hashid} | Update user |
| DELETE | /admin/user/{hashid} | Hapus user (perlu konfirmasi kata sandi) |
| POST | /admin/user/batch/destroy | Hapus massal |
| POST | /admin/user/batch/status | Aktif/nonaktif massal |
| POST | /admin/import/users | Impor user Excel |

#### Manajemen Peran & Izin

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/role | Daftar peran |
| POST | /admin/role | Buat peran |
| GET | /admin/role/{hashid} | Detail peran |
| PUT | /admin/role/{hashid} | Update peran |
| DELETE | /admin/role/{hashid} | Hapus peran |
| GET | /admin/permission | Daftar izin (pohon) |
| POST | /admin/permission | Buat izin |
| PUT | /admin/permission/{hashid} | Update izin |
| DELETE | /admin/permission/{hashid} | Hapus izin |

#### Konfigurasi Sistem

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/config | Daftar konfigurasi (?group=) |
| POST | /admin/config | Buat konfigurasi |
| PUT | /admin/config/{hashid} | Update konfigurasi |
| DELETE | /admin/config/{hashid} | Hapus konfigurasi |

#### Log Operasi

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/log | Daftar log (?user_id=&action=&method=&source=&start_date=&end_date=) |

#### Pusat Pribadi

| Metode | Path | Deskripsi |
|------|------|------|
| PUT | /admin/profile | Ubah informasi pribadi |
| PUT | /admin/profile/password | Ubah kata sandi |
| POST | /admin/profile/logout | Logout |

#### Ekspor

| Metode | Path | Deskripsi |
|------|------|------|
| POST | /admin/export/excel | Ekspor Excel ({ table, columns, conditions, title }) |
| POST | /admin/export/pdf | Ekspor PDF ({ type, title, data }) |

---

### Manajemen Properti — Endpoint Panel Admin

#### Manajemen Komunitas

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/community | Daftar (?keyword=&status=) |
| POST | /admin/community | Buat |
| GET | /admin/community/{hashid} | Detail |
| PUT | /admin/community/{hashid} | Update |
| DELETE | /admin/community/{hashid} | Hapus (perlu kata sandi) |

#### Manajemen Gedung

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/building | Daftar (?community_id=&keyword=) |
| POST | /admin/building | Buat |
| GET | /admin/building/{hashid} | Detail |
| PUT | /admin/building/{hashid} | Update |
| DELETE | /admin/building/{hashid} | Hapus |

#### Manajemen Unit

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/unit | Daftar (?building_id=) |
| POST | /admin/unit | Buat |
| GET | /admin/unit/{hashid} | Detail |
| PUT | /admin/unit/{hashid} | Update |
| DELETE | /admin/unit/{hashid} | Hapus |

#### Manajemen Tipe Ruangan

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/room-type | Daftar |
| POST | /admin/room-type | Buat |
| GET | /admin/room-type/{hashid} | Detail |
| PUT | /admin/room-type/{hashid} | Update |
| DELETE | /admin/room-type/{hashid} | Hapus |

#### Manajemen Properti

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/room | Daftar (?community_id=&building_id=&unit_id=&status=) |
| POST | /admin/room | Buat |
| GET | /admin/room/{hashid} | Detail |
| PUT | /admin/room/{hashid} | Update |
| DELETE | /admin/room/{hashid} | Hapus |
| GET | /admin/room/tree | Pohon rumah (komunitas→gedung→unit→rumah) |

#### Manajemen Pemilik

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/owner | Daftar (?keyword=&status=) |
| POST | /admin/owner | Buat |
| GET | /admin/owner/{hashid} | Detail (termasuk properti terikat) |
| PUT | /admin/owner/{hashid} | Update |
| DELETE | /admin/owner/{hashid} | Hapus (perlu kata sandi) |
| POST | /admin/owner/batch/import | Impor massal Excel |
| POST | /admin/owner/batch/destroy | Hapus massal |

#### Manajemen Penyewa

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/tenant | Daftar (?room_id=&status=) |
| POST | /admin/tenant | Buat |
| GET | /admin/tenant/{hashid} | Detail |
| PUT | /admin/tenant/{hashid} | Update |
| DELETE | /admin/tenant/{hashid} | Hapus |

#### Tipe Biaya

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/fee-type | Daftar |
| POST | /admin/fee-type | Buat |
| GET | /admin/fee-type/{hashid} | Detail |
| PUT | /admin/fee-type/{hashid} | Update |
| DELETE | /admin/fee-type/{hashid} | Hapus |

#### Manajemen Tagihan

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/fee-bill | Daftar (?community_id=&status=&due_date_start=&due_date_end=) |
| POST | /admin/fee-bill | Buat tagihan |
| GET | /admin/fee-bill/{hashid} | Detail |
| PUT | /admin/fee-bill/{hashid} | Update |
| DELETE | /admin/fee-bill/{hashid} | Hapus |
| POST | /admin/fee-bill/batch/generate | Generate tagihan massal |

#### Rekaman Pembayaran

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/fee-payment | Daftar (?bill_id=&payment_method=&date_start=&date_end=) |
| POST | /admin/fee-payment/offline | Registrasi penerimaan offline |

#### Manajemen Perbaikan

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/repair | Daftar (?status=&category=) |
| POST | /admin/repair | Buat |
| GET | /admin/repair/{hashid} | Detail (termasuk rekaman progres) |
| PUT | /admin/repair/{hashid} | Update |
| DELETE | /admin/repair/{hashid} | Hapus |
| PUT | /admin/repair/{id}/assign | Dispatch ({ staff_id }) |
| POST | /admin/repair/{id}/progress | Update progres ({ status_to, remark }) |

#### Manajemen Pengumuman

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/announcement | Daftar (?community_id=&category=&is_published=) |
| POST | /admin/announcement | Buat |
| GET | /admin/announcement/{hashid} | Detail |
| PUT | /admin/announcement/{hashid} | Update |
| DELETE | /admin/announcement/{hashid} | Hapus |

#### Manajemen Parkir

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/parking-space | Daftar (?community_id=) |
| POST | /admin/parking-space | Buat tempat parkir |
| PUT | /admin/parking-space/{hashid} | Update |
| DELETE | /admin/parking-space/{hashid} | Hapus |
| GET | /admin/parking-vehicle | Daftar (?owner_id=&space_id=) |
| POST | /admin/parking-vehicle | Buat kendaraan |
| PUT | /admin/parking-vehicle/{hashid} | Update |
| DELETE | /admin/parking-vehicle/{hashid} | Hapus |
| GET | /admin/parking-record | Rekaman parkir (?vehicle_id=&date_start=&date_end=) |

#### Manajemen Peralatan

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/equipment | Daftar (?community_id=&category=&status=) |
| POST | /admin/equipment | Buat |
| PUT | /admin/equipment/{hashid} | Update |
| DELETE | /admin/equipment/{hashid} | Hapus |
| GET | /admin/equipment-maintenance | Rekaman perawatan (?equipment_id=) |
| POST | /admin/equipment-maintenance | Buat perawatan |

#### Penanganan Keluhan

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/complaint | Daftar (?type=&status=) |
| GET | /admin/complaint/{hashid} | Detail |
| PUT | /admin/complaint/{id}/handle | Tangani ({ handler_remark }) |
| POST | /admin/complaint/{id}/visit | Kunjungan balik ({ visitor_remark }) |

#### Persetujuan Tamu

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/visitor | Daftar (?status=) |
| PUT | /admin/visitor/{id}/approve | Setujui |

#### Manajemen Kontrak

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/contract | Daftar (?contract_type=&status=) |
| POST | /admin/contract | Buat |
| PUT | /admin/contract/{hashid} | Update |
| DELETE | /admin/contract/{hashid} | Hapus |

#### Manajemen Keuangan

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/finance-income | Daftar pemasukan (?income_type=&date_start=&date_end=) |
| POST | /admin/finance-income | Registrasi pemasukan |
| GET | /admin/finance-expense | Daftar pengeluaran |
| POST | /admin/finance-expense | Registrasi pengeluaran |
| GET | /admin/finance/statistics | Statistik pemasukan-pengeluaran bulanan (?year=) |

#### Panel Properti

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/dashboard/property | Statistik properti (piutang/rasio hunian/perbaikan/keluhan/trend pemasukan-pengeluaran) |
| POST | /admin/export/property-excel | Ekspor Excel data properti ({ type: owners|bills }) |

#### Patroli Keamanan

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/security-patrol | Daftar (?community_id=) |
| POST | /admin/security-patrol | Buat rute |
| GET | /admin/patrol-record | Rekaman (?patrol_id=&staff_id=) |
| POST | /admin/patrol-record | Buat rekaman |

#### Manajemen Kebersihan

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/cleaning-area | Daftar area |
| POST | /admin/cleaning-area | Buat area |
| GET | /admin/cleaning-record | Rekaman (?area_id=) |
| POST | /admin/cleaning-record | Buat rekaman |

#### Manajemen Penghijauan

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/green-area | Daftar area |
| POST | /admin/green-area | Buat area |
| GET | /admin/green-maintenance | Rekaman perawatan (?area_id=) |
| POST | /admin/green-maintenance | Buat rekaman |

#### Aktivitas Komunitas

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/activity | Daftar (?status=) |
| POST | /admin/activity | Buat aktivitas |
| PUT | /admin/activity/{hashid} | Update |
| DELETE | /admin/activity/{hashid} | Hapus |
| GET | /admin/activity-signup | Daftar pendaftaran (?activity_id=) |
| PUT | /admin/activity-signup/{id}/checkin | Check-in |

#### Manajemen Energi

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/energy-meter | Daftar meter (?room_id=&meter_type=) |
| POST | /admin/energy-meter | Buat meter |
| GET | /admin/energy-record | Rekaman pencatatan meter (?meter_id=&date_start=&date_end=) |
| POST | /admin/energy-record | Buat rekaman |

#### Manajemen Karyawan

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/staff | Daftar (?community_id=&status=) |
| POST | /admin/staff | Buat |
| PUT | /admin/staff/{hashid} | Update |
| DELETE | /admin/staff/{hashid} | Hapus |
| POST | /admin/staff/batch/status | Aktif/nonaktif massal |

#### Notifikasi Pesan

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/notification-template | Daftar template |
| POST | /admin/notification-template | Buat template |
| PUT | /admin/notification-template/{hashid} | Update template |
| DELETE | /admin/notification-template/{hashid} | Hapus template |
| GET | /admin/notification | Daftar pesan (?type=&is_read=) |
| POST | /admin/notification/send | Kirim notifikasi manual |

#### Alur Persetujuan

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/approval-type | Daftar tipe persetujuan |
| POST | /admin/approval-type | Buat tipe persetujuan |
| GET | /admin/approval | Daftar persetujuan (?status=) |
| GET | /admin/approval/{hashid} | Detail persetujuan |
| POST | /admin/approval | Submit persetujuan |
| PUT | /admin/approval/{hashid}/approve | Persetujuan (lulus/tolak) |

#### Manajemen Pembayaran

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/payment-order | Daftar order |
| GET | /admin/payment-order/{hashid} | Detail order |
| POST | /admin/payment-order/{hashid}/refund | Refund |
| GET | /admin/payment/statistics | Statistik pembayaran |

#### Voting Pemilik

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /admin/vote | Daftar voting (?status=) |
| POST | /admin/vote | Buat voting |
| GET | /admin/vote/{hashid}/statistics | Statistik penghitungan suara |
| PUT | /admin/vote/{hashid}/publish | Terbitkan voting |
| PUT | /admin/vote/{hashid}/end | Akhiri voting |

#### Manajemen SLA · Penagihan Cerdas · Pemeliharaan · Toko · Face · Grup · Knowledge Base

（Endpoint lengkap lihat file `docs/API.md`）

---

## API Portal Pemilik (service :8788)

### Endpoint Publik — tanpa autentikasi

#### POST /api/captcha/generate
Mendapatkan captcha klik。（sama dengan panel admin）

#### POST /api/captcha/verify
Memvalidasi captcha klik。（request/respons sama dengan panel admin）

#### POST /api/auth/login
Login pemilik.

Parameter request:
| Parameter | Tipe | Deskripsi |
|------|------|------|
| phone | string | Nomor ponsel |
| password | string | Kata sandi |
| captcha_key | string | Key captcha |
| clicks | array | Koordinat klik |

Respons:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "owner": { "id": "xB9k...", "name": "张三", "phone": "138****1234" }
  }
}
```

#### POST /api/auth/register
Registrasi pemilik.

Parameter request:
| Parameter | Tipe | Deskripsi |
|------|------|------|
| phone | string | Nomor ponsel |
| password | string | Kata sandi (minimal 6 karakter) |
| name | string | Nama |
| captcha_key | string | Key captcha |
| clicks | array | Koordinat klik |
| room_id | string | （opsional）hashid properti yang di-bind |
| id_card_last4 | string | （opsional）4 digit terakhir KTP |

#### POST /api/auth/refresh
Menyegarkan Token.

---

### Endpoint Portal Pemilik — perlu autentikasi (Bearer Token)

Semua endpoint berprefiks `/service`, perlu membawa `Authorization: Bearer {access_token}`.

#### Beranda

**GET /service/home**

Respons:
```json
{
  "code": 0,
  "data": {
    "room_count": 2,
    "pending_amount": "1250.00",
    "pending_bill_count": 3,
    "repairing_count": 1,
    "announcements": [{ "id": "xB9k...", "title": "停水通知", "published_at": "2026-05-20 09:00" }]
  }
}
```

#### Properti Saya

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /service/rooms | Daftar properti saya |
| GET | /service/room/{hashid} | Detail properti (termasuk luas、orientasi、kepemilikan、informasi komunitas) |

#### Manajemen Biaya

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /service/fees/bills | Daftar tagihan (?status=0 belum bayar/1 sebagian/2 sudah bayar/3 terlambat) |
| GET | /service/fees/bill/{hashid} | Detail tagihan (termasuk tipe biaya、rekaman pembayaran) |
| GET | /service/fees/payments | Rekaman pembayaran |
| POST | /service/fees/pay | Bayar online（{ bill_id, payment_method, password }） |
| GET | /service/fees/statistics | Statistik biaya (?year=2026) |

#### Perbaikan

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /service/repairs | Daftar perbaikan (?status=) |
| GET | /service/repair/{hashid} | Detail perbaikan (termasuk timeline progres) |
| POST | /service/repair | Submit perbaikan（{ room_id, category, urgency, description, images[], scheduled_at }） |
| DELETE | /service/repair/{hashid} | Batalkan (perlu kata sandi, { password }) |
| POST | /service/repair/{hashid}/rate | Penilaian（{ rating: 1-5, feedback }） |

#### Keluhan dan Saran

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /service/complaints | Daftar keluhan |
| GET | /service/complaint/{hashid} | Detail keluhan (termasuk progres penanganan) |
| POST | /service/complaint | Submit keluhan（{ type, category, title, content, is_anonymous, images[] }） |
| POST | /service/complaint/{hashid}/satisfaction | Penilaian kepuasan（{ satisfaction: 1-5 }） |

#### Pengumuman

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /service/announcements | Daftar pengumuman (?category=) |
| GET | /service/announcement/{hashid} | Detail pengumuman |

#### Parkir

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /service/parking/vehicles | Kendaraan saya |
| GET | /service/parking/spaces | Tempat parkir saya |
| GET | /service/parking/records | Rekaman parkir |

#### Tamu

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /service/visitors | Reservasi tamu saya |
| POST | /service/visitor | Buat reservasi (generate kode akses) |
| PUT | /service/visitor/{hashid} | Ubah reservasi |
| DELETE | /service/visitor/{hashid} | Batalkan reservasi |

#### Aktivitas Komunitas

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /service/activities | Daftar aktivitas (?status=) |
| GET | /service/activity/{hashid} | Detail aktivitas |
| POST | /service/activity/{hashid}/signup | Daftar ikut |
| POST | /service/activity/{hashid}/cancel | Batalkan pendaftaran |

#### Informasi Pribadi

| Metode | Path | Deskripsi |
|------|------|------|
| GET | /service/profile | Informasi pribadi |
| PUT | /service/profile | Ubah（{ name, email, gender, birthday }） |
| PUT | /service/profile/password | Ubah kata sandi（{ old_password, new_password }） |
| POST | /service/profile/logout | Logout |

---

## Open API — Autentikasi API Key

Endpoint read-only inbound eksternal, untuk dipanggil sistem pihak ketiga (integrasi platform properti、data besar dll.). Berprefiks `/open`, semuanya read-only.

### Cara Autentikasi

Setiap request perlu membawa header `X-API-Key`, nilainya Key yang dibuat `scripts/gen_api_key.php` (hex 64 bit, database hanya menyimpan digest SHA-256):

```bash
curl -H "X-API-Key: <KeyAnda>" http://localhost:8788/open/announcements
```

- Key hilang atau salah mengembalikan `401`（`{"code":401,"message":"无效的API Key","data":[]}`）
- Manajemen Key: `php scripts/gen_api_key.php [--name=用途]` membuat; nonaktifkan/hapus langsung operasi tabel `erik_api_key`（`status=0` berarti nonaktif, Key langsung tidak berlaku）

### Endpoint

#### GET /open/announcements — Daftar pengumuman

Parameter：`page`（default 1）、`category`（opsional）. Struktur respons konsisten dengan `/service/announcements`.

```bash
curl -H "X-API-Key: <KeyAnda>" "http://localhost:8788/open/announcements?page=1"
```

#### GET /open/bills — Cek tagihan

Parameter：`bill_number`（wajib, nomor tagihan）. Mengembalikan detail satu tagihan (termasuk tipe biaya、nomor kamar、jumlah tunggakan). Tidak ada mengembalikan 404.

```bash
curl -H "X-API-Key: <KeyAnda>" "http://localhost:8788/open/bills?bill_number=B202608160001"
```

#### GET /open/repairs — Cek status perbaikan

Parameter：`order_number`（wajib, nomor tiket perbaikan）. Mengembalikan status saat ini tiket perbaikan dan timeline progres（array `progress`）. Tidak ada mengembalikan 404.

```bash
curl -H "X-API-Key: <KeyAnda>" "http://localhost:8788/open/repairs?order_number=R202608160001"
```

---

## Kode Error

| code | Makna | Deskripsi |
|------|------|------|
| 0 | Sukses | Respons normal |
| 400 | Kesalahan request | Format parameter tidak benar |
| 401 | Belum autentikasi | Token hilang/kedaluwarsa/tidak valid/masuk blacklist |
| 403 | Tanpa izin | Peran user tidak berisi izin yang dibutuhkan / akun dinonaktifkan |
| 404 | Tidak ada | Resource tidak ditemukan |
| 405 | Metode tidak diizinkan | Metode HTTP selain GET/POST/PUT/DELETE/OPTIONS |
| 413 | Request body terlalu besar | Melebihi 10MB |
| 415 | Tipe media tidak didukung | Content-Type bukan JSON atau form-urlencoded |
| 422 | Validasi gagal | Parameter form tidak sesuai aturan / konfirmasi kata sandi gagal / captcha salah |
| 429 | Terlalu banyak request | Memicu rate limit / penguncian akun |
| 500 | Kesalahan server | Pengecualian tidak terduga |

## Header Respons Rate Limit

Saat memicu rate limit mengembalikan 429, header respons berisi:

| Header respons | Deskripsi |
|--------|------|
| X-RateLimit-Limit | Jumlah batas |
| X-RateLimit-Remaining | Jumlah tersisa |
| X-RateLimit-Reset | Waktu reset (timestamp Unix) |
| Retry-After | Detik tunggu yang disarankan |
