# Manual Operasional (OPS Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Berlaku: property-management-platform (sisi admin + sisi service, PHP 8.3 webman)

## 1. Backup dan Pemulihan Database

Sisi admin dan sisi service berbagi instance dan database MySQL yang sama `property_management`, backup sekali cukup. Entry terpadu:

| Nama database | Skrip backup | Deskripsi |
|---|---|---|
| `property_management` | `scripts/backup.sh` | Membaca koneksi dari `admin/.env` (dapat ganti nama container dengan `--container=`), default mysqldump di dalam container |

Output `backups/backup_YYYYMMDD_HHMMSS.sql.gz`, default simpan 7 hari terakhir (`--keep-days=` dapat diatur).

### 1.1 Backup Penuh

```bash
cd /path/to/property-management-platform
bash scripts/backup.sh
```

### 1.2 Tugas Terjadwal (crontab)

```cron
# Backup penuh setiap hari 02:00
0 2 * * * cd /path/to/property-management-platform && bash scripts/backup.sh >> /var/log/pmp-backup.log 2>&1
```

Saran produksi: mount direktori backup ke disk independen/penyimpanan remote, dan periksa integritas file backup secara berkala (validasi `gzip -t`).

### 1.3 Alur Latihan Pemulihan (minimal sekali per kuartal)

1. Pilih satu backup terbaru: `ls -t backups/backup_*.sql.gz`
2. Di **lingkungan independen** (atau database sementara) eksekusi pemulihan: lihat [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) skenario A (pemulihan database kosong) dan skenario B (pemulihan titik waktu).
3. Verifikasi:
   - Perbandingan jumlah baris: `SELECT COUNT(*) FROM erik_user;` konsisten dengan catatan sebelum backup
   - Field terenkripsi dapat didekripsi normal: cek satu rekaman berisi field encryptable, nilai benar, log tanpa error decrypt
   - Smoke bisnis: login、tarik daftar endpoint normal
4. Catat durasi dan hasil latihan (untuk evaluasi RTO).

> Manual latihan lengkap (pemulihan database kosong / pemulihan titik waktu / verifikasi konsistensi / jadwal latihan 30 menit) lihat [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md).

### 1.4 Penjelasan RPO / RTO

- **RPO (jumlah data yang dapat hilang)**: ditentukan frekuensi backup. Backup penuh harian → RPO ≤ 24 jam, yaitu paling banyak kehilangan data satu hari terakhir. Perlu RPO lebih kecil bisa tambah frekuensi backup (misal 2 kali sehari) atau aktifkan backup inkremental binlog.
- **RTO (waktu yang dibutuhkan untuk pemulihan)**: bergantung ukuran database dan kecepatan pemulihan, target ≤ 1 jam (pemulihan + validasi + restart layanan). Setiap selesai latihan perbarui nilai terukur aktual.
- Darurat gagal pemulihan: dulu rollback kode aplikasi, lalu coba ulang dengan backup terbaru yang tersedia; jika backup rusak, gunakan backup yang lebih lama dan terima RPO lebih besar.

## 2. Manajemen Kunci

Proyek bergantung pada 5 kunci, semuanya di `.env` (admin dan service masing-masing independen, jangan pakai satu set bersama):

| Variabel | Panjang | Fungsi |
|---|---|---|
| `ENCRYPTION_KEY` | 32 byte | Enkripsi transfer API (config/encryption.php) |
| `ENCRYPTABLE_KEY` | 32 byte | Enkripsi field sensitif database (plugin encryptable, **jangan dipakai bersama ENCRYPTION_KEY**) |
| `JWT_SECRET_KEY` | 64 bit ke atas | Signature JWT |
| `HASHIDS_SALT` | — | Enkripsi/dekripsi ID |
| `HASHIDS_ALT_SALT` | — | Cadangan enkripsi/dekripsi ID |

### 2.1 Membuat Kunci

```bash
# Output 5 KEY=VALUE ke stdout, dapat langsung ditambahkan ke .env
php scripts/gen_env_keys.php

# Langsung tulis ke .env: kunci yang sudah ada tidak ditimpa, hanya menambah yang hilang
php scripts/gen_env_keys.php --file=.env
```

> Jika salah satu kunci di .env masih placeholder `change-me`, hapus baris itu dulu lalu jalankan (placeholder dianggap "sudah ada", tidak akan ditimpa).

### 2.2 Rotasi Kunci (encryptable)

```bash
bash scripts/rotate_keys.sh            # default operasi .env direktori saat ini
bash scripts/rotate_keys.sh /path/to/service/.env
```

Skrip otomatis menyelesaikan: backup .env → generate `ENCRYPTABLE_KEY` baru → key lama ditambahkan ke `ENCRYPTION_PREVIOUS_KEYS` (dipisah koma, yang terbaru dirotasi di depan) → tulis key baru. Lalu manual sesuai petunjuk: restart layanan → verifikasi dekripsi → konfirmasi lalu hapus backup.

**Penjelasan `ENCRYPTION_PREVIOUS_KEYS`**: saat dekripsi encryptable dulu pakai `ENCRYPTABLE_KEY` saat ini, jika gagal coba satu per satu key historis sesuai urutan daftar. Karena itu **saat rotasi key lama wajib masuk daftar ini sebelum key baru berlaku**, jika tidak data lama tidak dapat didekripsi setelah restart (data tidak hilang, rollback .env dapat memulihkan). Daftar hanya bertambah tidak berkurang, sebelum menghapus key historis wajib konfirmasi semua data lama sudah selesai dienkripsi ulang.

**Tidak melakukan migrasi data otomatis**: setelah rotasi data lama tetap terenkripsi dengan key lama、dapat dibaca tulis normal. Jika perlu menulis ulang data yang ada dengan key baru, jalankan tugas migrasi data terpisah (baca per tabel → tulis memicu enkripsi ulang).

### 2.3 Validasi Startup Fail-fast

Konfigurasi berikut divalidasi saat layanan startup, jika kunci **hilang atau masih placeholder `change-me`** langsung throw `RuntimeException` menolak startup (mencegah go-live dengan kunci placeholder):

| Konfigurasi | Kunci yang divalidasi |
|---|---|
| `service/config/encryption.php` | `ENCRYPTION_KEY` |
| `service/config/encryptable.php`、`service/config/plugin/erikwang2013/encryptable/app.php` | `ENCRYPTABLE_KEY` |
| `service/config/jwt.php`、`service/config/plugin/erikwang2013/jwt/jwt.php` | `JWT_SECRET_KEY` |

Contoh error startup: `ENCRYPTABLE_KEY 未配置或仍为占位符，请在 .env 中配置 32 字节随机密钥`。

**Daftar operasi harian**:

1. Deploy lingkungan baru: `cp .env.example .env` → hapus baris placeholder `change-me` → `php scripts/gen_env_keys.php --file=.env` → start layanan konfirmasi tanpa error kunci.
2. Rotasi rutin: jalankan sesuai 2.2, sekali per kuartal cukup (tanpa periode wajib, jika bocor segera rotasi).
3. `.env.bak.*` hasil backup berisi kunci teks polos, perlakukan setara backup database (izin 600、simpan di lokasi remote).

## 3. Monitoring Alert (Prometheus + Grafana)

Orkestrasi di `admin/docker-compose.yml` (tambah tiga layanan prometheus / grafana / redis-exporter), konfigurasi semua di `admin/deploy/monitoring/`:

```bash
cd admin
docker compose up -d prometheus grafana redis-exporter
# Prometheus: http://host:9090   Grafana: http://host:3000
# Login pertama Grafana: admin / ${GRAFANA_ADMIN_PASSWORD}（default change-me-grafana-password）
```

- **Data source**: Grafana otomatis konfigurasi data source Prometheus saat startup (provisioning), panel dibuat di UI.
- **Aturan alert**: `deploy/monitoring/alerts.yml`, mencakup:
  - `AppDown` (aplikasi tidak dapat dijangkau, setara 5xx seluruh situs) — critical
  - `MysqlDown` / `RedisDown` (probe gagal sisi aplikasi) — critical
  - `ElasticsearchDown` (gagal scrape `/_prometheus/metrics` native ES) + `ElasticsearchHealthYellow` (cluster bukan hijau) — critical/warning
  - `QueueBacklog` (antrian pencarian scout `queues:scout_*` menumpuk >100 terus 10 menit) — warning
- **Injeksi password ES**: prometheus melalui `secrets` compose membaca `ELASTIC_PASSWORD` (perlu Docker Compose ≥ 2.24), file konfigurasi tidak menulis mati password; jika tidak diset pakai placeholder change-me, scrape ES 401 akan memicu ElasticsearchDown.
- **Reload aturan**: setelah ubah alerts.yml `curl -X POST localhost:9090/-/reload` (prometheus perlu tambah `--web.enable-lifecycle`, jika default tidak ditambah maka restart container).
- **Verifikasi lokal**: `bash scripts/verify_monitoring.sh` — memvalidasi sintaks YAML aturan alert dua sisi admin/service、curl `/metrics` dua sisi (admin:8787 / service:8788) output metrik、muat aturan Prometheus (9090/9091); saat aplikasi/Prometheus tidak berjalan item terkait menampilkan SKIP dan exit 0.

**Status**: admin dan service sama-sama sudah punya endpoint `/metrics` (MetricsController, tanpa autentikasi). Middleware MetricsCollector sudah menghitung kumulatif nyata sesuai `code="all"|"5xx"` (admin output `open_admin_http_requests_total`, service output `property_service_http_requests_total`), aturan `Http5xxRatio` kedua sisi alerts.yml (rasio 5xx >5% terus 10 menit) dapat berlaku langsung. **Uji nyata alert menunggu deployment**: aturan sudah siap tetapi belum dipicu diverifikasi di lingkungan deployment nyata (bergantung `verify_monitoring.sh` dan go-live Prometheus).

## 4. Rotasi Log

- **Log container**: semua layanan compose sudah dikonfigurasi `json-file` + `max-size 10m / max-file 3`, tanpa penanganan tambahan.
- **Log aplikasi host** (`runtime/*.log`、`service/workerman.log`): gunakan `admin/deploy/logrotate/pmp-app`:

```bash
sudo cp admin/deploy/logrotate/pmp-app /etc/logrotate.d/pmp-app
# Ubah path di dalam file sesuai path deployment aktual lalu berlaku; copytruncate membuat webman rotasi tanpa restart
sudo logrotate -d /etc/logrotate.d/pmp-app   # dry-run cek
```

Default rotasi harian、simpan 30 hari、kompresi gzip.

## 5. Smoke Uji Beban Setelah Deployment

Setelah deployment selesai gunakan k6 smoke untuk memverifikasi jalur login dan endpoint bisnis kunci dapat dijangkau (kecepatan rendah, bukan uji beban performa). Skrip: `scripts/loadtest/smoke.js` (default 2 VU、30s、login + dashboard, semua mendukung override variabel lingkungan `BASE_URL`/`VUS`/`DURATION`/`TOKEN`)。

### 5.1 Smoke Lokal

```bash
cd /path/to/property-management-platform/scripts/loadtest

# Hanya probe jalur login (tanpa token; 422 captcha salah/429 rate limit keduanya pertahanan berlaku, dianggap dapat dijangkau)
k6 run -e BASE_URL=http://127.0.0.1:8790 smoke.js

# Termasuk endpoint bisnis berautentikasi: terbitkan JWT uji beban di server deployment (bergantung admin/.env dan vendor) lalu teruskan
TOKEN=$(php mint-token.php)
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" smoke.js

# Kustom konkurensi/durasi
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" -e VUS=5 -e DURATION=60s smoke.js
```

Uji beban penuh (tiga skrip login + dashboard + fee) tetap pakai `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]`。

### 5.2 Smoke CI (pemicuan manual GitHub Actions)

Halaman Actions repositori → **Loadtest Smoke** → **Run workflow**:

| Input | Wajib | Deskripsi |
|---|---|---|
| `target_url` | Ya | Alamat lingkungan yang diuji, misal `https://admin.example.com` |
| `duration` | Tidak | Durasi smoke, default `30s` |
| `token` | Tidak | JWT uji beban; kosongkan maka hanya probe jalur login |

Mendapatkan token (dieksekusi di root repositori server deployment, perlu `admin/.env` dan `admin/vendor/`):

```bash
php scripts/loadtest/mint-token.php
```

> Catatan: token adalah JWT khusus uji beban (default akun admin erik), akan muncul teks polos di log workflow, mohon terbitkan dengan akun khusus uji beban; jika produksi tidak nyaman diekspos, ganti smoke lokal 5.1.
