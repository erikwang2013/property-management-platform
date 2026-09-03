# Panduan Instalasi

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

Dokumen ini memandu Anda men-deploy Sistem Manajemen Properti dari nol.

---

## Daftar Isi

1. [Wizard Instalasi Web (disarankan)](#wizard-instalasi-web-disarankan)
2. [Instalasi Manual](#instalasi-manual)
3. [Deployment Docker](#deployment-docker)
4. [Akun Default](#akun-default)
5. [Verifikasi Instalasi](#verifikasi-instalasi)
6. [FAQ](#faq)

---

## Wizard Instalasi Web (disarankan)

Proyek sudah menyertakan wizard instalasi Web, setelah panel admin dijalankan semua konfigurasi dapat diselesaikan melalui browser.

### Langkah Penggunaan

```bash
# 1. Masuk direktori panel admin
cd admin

# 2. Buat file variabel lingkungan (salin dari template)
cp .env.example .env

# 3. Install dependensi
composer install --no-dev --optimize-autoloader

# 4. Jalankan layanan
php start.php start -d
```

### 5. Buka wizard instalasi

Browser akses **`http://localhost:8787/install`**, selesaikan konfigurasi tiga langkah sesuai petunjuk:

| Langkah | Konten | Deskripsi |
|------|------|------|
| Langkah 1 | Konfigurasi database | Isi host, port, nama database, username, kata sandi |
| Langkah 2 | Akun admin | Set username dan kata sandi login backoffice (minimal 6 karakter) |
| Langkah 3 | Konfirmasi instalasi | Periksa informasi konfigurasi, klik konfirmasi lalu otomatis eksekusi instalasi |

Proses instalasi otomatis menyelesaikan:
1. Test koneksi database
2. Tulis file konfigurasi `.env`
3. Impor semua 65 tabel data + seed permission
4. Buat akun admin dan beri peran super admin
5. Buat file kunci instalasi `public/.installed`

### Setelah Instalasi Selesai

- Alamat backoffice: `http://localhost:8787/admin`
- Wizard instalasi akan menampilkan alamat login dan informasi akun
- Disarankan restart layanan agar konfigurasi berlaku: `php start.php restart -d`
- Jika perlu install ulang, hapus file `public/.installed` saja

---

## Instalasi Manual

### Persyaratan Lingkungan

| Komponen | Versi yang dibutuhkan | Deskripsi |
|------|---------|------|
| PHP | 8.1+（disarankan 8.3） | Perlu ekstensi pcntl、pdo_mysql、redis、gd、mbstring |
| MySQL | 8.0+ | Charset utf8mb4 |
| Redis | 6.0+ | Cache、rate limit、Session |
| Composer | 2.x | Manajemen dependensi PHP |
| Elasticsearch | 8.x | Pencarian teks lengkap (opsional, jika dinonaktifkan pakai query database) |
| Flutter SDK | 3.x | Hanya untuk pengembangan frontend |

### Pemeriksaan Ekstensi PHP

```bash
php -m | grep -E "pcntl|pdo_mysql|redis|gd|mbstring|curl|json|xml|dom"
```

---

## Inisialisasi Database

### 1. Buat Database

```bash
mysql -u root -p <<SQL
CREATE DATABASE IF NOT EXISTS management
  DEFAULT CHARSET utf8mb4
  COLLATE utf8mb4_unicode_ci;
SQL
```

### 2. Impor Skrip Instalasi Gabungan

```bash
mysql -u root -p management < docs/install.sql
```

`docs/install.sql` berisi semua 65 tabel + data seed permission RBAC, menggunakan `CREATE TABLE IF NOT EXISTS` untuk memastikan dapat dieksekusi berulang.

Setelah eksekusi verifikasi:

```bash
mysql -u root -p management -e "SHOW TABLES;" | wc -l
# Harus output: 66（65 tabel + 1 baris header）
```

---

## Deployment Panel Admin

Panel admin berjalan di `http://localhost:8787`, menyediakan API backoffice admin.

```bash
cd admin

# 1. Konfigurasi variabel lingkungan
cp .env.example .env
# Edit .env, ubah kata sandi database, kunci JWT dll.

# 2. Install dependensi
composer install --no-dev --optimize-autoloader

# 3. Jalankan layanan
php start.php start -d
# -d berarti berjalan di background, tanpa -d bisa berjalan di foreground melihat log

# 4. Verifikasi
curl http://localhost:8787/health
```

### Item Konfigurasi Kunci (admin/.env)

| Item konfigurasi | Deskripsi | Kebutuhan lingkungan produksi |
|--------|------|-------------|
| `JWT_SECRET_KEY` | Kunci signature JWT | String acak 64 karakter ke atas |
| `HASHIDS_SALT` | Salt enkripsi ID | String acak, konsisten dengan service |
| `SNOWFLAKE_DATACENTER_ID` | ID data center (0-31) | Perlu dibedakan saat deployment multi-data center |
| `SNOWFLAKE_WORKER_ID` | ID worker node (0-31) | Setiap mesin di data center yang sama berbeda |
| `ENCRYPTION_KEY` | Kunci enkripsi transfer API | String acak 32 byte |
| `ENCRYPTABLE_KEY` | Kunci enkripsi field database | String acak 32 byte |
| `DB_PASSWORD` | Kata sandi database | Kata sandi kuat |

---

## Deployment Portal Pemilik

Portal pemilik berjalan di `http://localhost:8788`, menyediakan API portal pemilik.

```bash
cd service

# 1. Konfigurasi variabel lingkungan
cp .env.example .env
# Edit .env, ubah kata sandi database, kunci JWT dll.

# 2. Install dependensi
composer install --no-dev --optimize-autoloader

# 3. Jalankan layanan
php start.php start -d

# 4. Verifikasi
curl http://localhost:8788/health
```

> **Catatan:** admin dan service berbagi database yang sama. `HASHIDS_SALT` wajib konsisten dengan admin, jika tidak ID terenkripsi yang dibuat admin tidak dapat didekripsi di sisi service.

---

## Deployment Docker

### Panel Admin

```bash
cd admin
cp .env.docker .env
# Edit .env ubah kunci produksi

docker compose up -d
# Berisi: Nginx + PHP + MySQL + Redis + Elasticsearch
```

### Portal Pemilik

```bash
cd service
cp .env.docker .env
# Edit .env ubah kunci produksi

docker compose up -d
```

### Perencanaan Port Layanan

| Layanan | admin | service | Deskripsi |
|------|-------|---------|------|
| Aplikasi | 8787 | 8788 | HTTP webman |
| MySQL | 3306 | 3307 | Mapping port container |
| Redis | 6379 | 6380 | Mapping port container |
| Elasticsearch | 9200 | 9201 | Mapping port container |
| Nginx | 80/443 | 80/443 | Perlu deployment terpisah |

> Saat men-deploy dua docker-compose di host yang sama, port service sudah di-preset offset untuk menghindari konflik.

---

## Akun Default

| Username | Kata sandi | Peran | Deskripsi |
|--------|------|------|------|
| admin | admin123 | Super admin | Memiliki semua permission |

> **Segera ubah kata sandi default di lingkungan produksi.**

---

## Verifikasi Instalasi

### 1. Health Check

```bash
# Panel admin
curl http://localhost:8787/health

# Portal pemilik
curl http://localhost:8788/health
```

### 2. Dokumentasi API

Semua endpoint API dan deskripsi parameter lihat dokumen terpisah [API.md](API.md). Setelah layanan berjalan juga dapat mengakses dokumentasi antarmuka interaktif yang dibuat otomatis:

| Sisi | Alamat |
|----|------|
| Panel admin | http://localhost:8787/apidoc |
| Portal pemilik | http://localhost:8788/apidoc |

### 3. Test Login

```bash
curl -X POST http://localhost:8787/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### 4. Jalankan Pengujian

```bash
# Panel admin
cd admin && php vendor/bin/phpunit

# Portal pemilik
cd service && php vendor/bin/phpunit
```

---

## FAQ

### Q: Error startup `Call to undefined function pcntl_fork()`

PHP kurang ekstensi pcntl.

```bash
# Ubuntu/Debian
apt install php-pcntl

# Docker
docker-php-ext-install pcntl
```

### Q: Setelah login muncul Token tidak valid

Periksa apakah konfigurasi berikut di `.env` admin dan service konsisten:
- `JWT_SECRET_KEY`
- `JWT_ALGORITHM`

### Q: ID terenkripsi tidak konsisten di dua sisi

Pastikan nilai `HASHIDS_SALT` admin dan service benar-benar sama.

### Q: Jaringan antar container Docker tidak terhubung

Gunakan nama container daripada IP untuk koneksi (misal `DB_HOST=mysql`).

### Q: Cara reset database

```bash
mysql -u root -p -e "DROP DATABASE IF EXISTS management;"
mysql -u root -p -e "CREATE DATABASE management DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p management < docs/install.sql
```

### Q: Cara konfigurasi HTTPS

Lingkungan produksi disarankan menggunakan reverse proxy Nginx untuk TLS termination. Konfigurasi referensi lihat `admin/docs/nginx-security.conf`.

---

## Langkah Berikutnya

- [Dokumen desain arsitektur](ARCHITECTURE_DESIGN.md) — arsitektur berlapis sistem dan rantai eksekusi middleware
- [Dokumentasi API](API.md) — referensi antarmuka lengkap
- [Dokumen desain fitur](FEATURE_DESIGN.md) — spesifikasi fungsi 34 modul
- [Perbandingan versi](EDITIONS.md) — perbedaan versi Lite / Standard / Full
