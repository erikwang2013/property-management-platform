# Manual Latihan Pemulihan Database (Recovery Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Berlaku: property-management-platform (sisi admin + sisi service, MySQL 8.0)
> Baca bersama bagian 1 [OPS_RUNBOOK.md](OPS_RUNBOOK.md): pembuatan backup、crontab、RPO/RTO lihat OPS_RUNBOOK, dokumen ini hanya membahas "cara memulihkan、cara memverifikasi".

## 0. Tujuan

- **Tujuan latihan: selesaikan satu latihan pemulihan lengkap dalam 30 menit** (pemulihan + verifikasi), minimal sekali per kuartal.
- Kapan pun mendapat backup terbaru, dapat memulihkan ke database kosong atau titik waktu tertentu sesuai dokumen ini.

Prasyarat:

- File backup tersedia: `scripts/backup.sh` sudah berjalan sesuai cron (lihat OPS_RUNBOOK 1.2).
- Lingkungan target pemulihan (mesin latihan atau mesin produksi) isomorfik dengan produksi: docker-compose yang sama, versi MySQL 8.0 yang sama.
- Konfirmasi sebelum pemulihan: `gzip -t file backup` lulus; ruang disk tersisa ≥ 2 kali volume backup.

## 1. Skenario A: Pemulihan ke Database Kosong (paling umum, skenario default latihan)

Tujuan: impor backup ke database kosong yang benar-benar baru, verifikasi data dapat digunakan.

```bash
cd /path/to/property-management-platform

# 1) Pilih satu backup terbaru
ls -lt backups/backup_*.sql.gz | head

# 2) Pemeriksaan integritas (jika tidak lulus ganti backup yang lebih lama)
gzip -t backups/backup_20260816_020000.sql.gz && echo OK

# 3) Konfirmasi container target berjalan
docker compose -f admin/docker-compose.yml ps mysql

# 4) Buat database kosong (nama database latihan tambah sufiks _drill, hindari menimpa data produksi secara tidak sengaja)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "CREATE DATABASE IF NOT EXISTS management_drill DEFAULT CHARACTER SET utf8mb4;"'

# 5) Impor (-T menonaktifkan TTY, pastikan non-interaktif; terukur sekitar 1-5 menit)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot --default-character-set=utf8mb4 management_drill' \
  < backups/backup_20260816_020000.sql.gz
```

> Petunjuk kredensial: `MYSQL_PWD` diambil dari `DB_PASSWORD` di `admin/.env`; di produksi dilarang muncul teks polos di shell history, disarankan ganti dengan `--env-file admin/.env` atau injeksi variabel lingkungan. Contoh manual ini adalah nilai konvensi lingkungan latihan.

## 2. Skenario B: Pemulihan ke Titik Waktu Tertentu (replay binlog)

Prasyarat: MySQL 8 secara default mengaktifkan binlog (`log_bin=ON`), inkremental setelah waktu backup semuanya ada di binlog. Kehilangan data ≤ backup terbaru + masa retensi binlog (default `binlog_expire_logs_seconds=2592000`, 30 hari).

Ide: pemulihan penuh → cari titik awal binlog → replay `mysqlbinlog` ke titik waktu target.

```bash
# 1) Konfirmasi binlog aktif, daftar file log
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "SHOW VARIABLES LIKE \"log_bin\"; SHOW BINARY LOGS;"'

# 2) Pemulihan penuh (sama dengan langkah 4-5 skenario A, pulihkan ke database kosong)

# 3) Cari titik awal binlog sesuai backup: posisi yang tercatat di file backup (saat --master-data=2)
#    Skrip ini tidak membawa --master-data, titik awal pakai "waktu mulai backup", selisihnya dalam durasi backup.
#    Replay binlog ke titik waktu target (contoh: pulihkan ke 2026-08-16 10:30:00)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysqlbinlog --stop-datetime="2026-08-16 10:30:00" /var/lib/mysql/binlog.000012 | mysql -uroot management_drill'
```

Poin penting:

- binlog berada di path container `/var/lib/mysql/binlog.0000NN`, cocokkan dari output `SHOW BINARY LOGS`.
- Hanya replay binlog "setelah waktu mulai backup"; segera verifikasi setelah replay (lihat bagian 3), konfirmasi `max(updated_at)` sesuai ekspektasi.
- Pemulihan operasi salah presisi detik: dulu lokasi pernyataan operasi salah `mysqlbinlog /var/lib/mysql/binlog.0000NN | grep -n "kata kunci operasi salah"`, lalu tentukan `--stop-datetime` atau `--stop-position`.

## 3. Verifikasi Konsistensi Data (wajib setelah pemulihan)

| Item pemeriksaan | Perintah | Standar kelulusan |
|---|---|---|
| Integritas file backup | `gzip -t <backup>` | Tanpa error |
| Jumlah baris tabel kunci | `SELECT COUNT(*) FROM management_admin_user;` | Konsisten dengan jumlah baris yang dicatat sebelum backup |
| Pemeriksaan acak tabel bisnis | `SELECT COUNT(*) FROM management_owner;`、`management_tenant`、`management_fee_bill`、`management_repair_order` | Tiga tabel atau lebih besaran wajar (bukan 0 dan konsisten dengan sebelum backup) |
| Field terenkripsi dapat didekripsi | Cek satu rekaman berisi field encryptable (misal `management_owner` KTP/nomor ponsel) | Nilai benar, log aplikasi tanpa error decrypt |
| Smoke bisnis | Login、tarik daftar endpoint masing-masing 1 kali | 200 / normal |

Contoh skrip pemeriksaan acak (lingkungan latihan):

```bash
docker compose -f admin/docker-compose.yml exec -T -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot management_drill -e "
    SELECT (SELECT COUNT(*) FROM management_admin_user) AS users,
           (SELECT COUNT(*) FROM management_owner) AS owners,
           (SELECT COUNT(*) FROM management_tenant) AS tenants,
           (SELECT COUNT(*) FROM management_fee_bill) AS fee_bills,
           (SELECT COUNT(*) FROM management_repair_order) AS repair_orders;"'
```

> Konsistensi jumlah baris: sebelum backup catat baseline dengan SQL yang sama, bandingkan setelah pemulihan; saat latihan tulis baseline ke catatan latihan.

## 4. Jadwal Latihan 30 Menit

| Waktu | Tindakan | Penanggung jawab |
|---|---|---|
| 0-5 min | Pilih backup、`gzip -t`、buat database kosong、catat jumlah baris baseline | Operasional |
| 5-15 min | Impor pemulihan skenario A | Operasional |
| 15-25 min | Verifikasi konsistensi bagian 3 + smoke bisnis | Operasional + bisnis |
| 25-30 min | Catat hasil、bersihkan database latihan (`DROP DATABASE management_drill`)、perbarui RTO terukur OPS_RUNBOOK 1.4 | Operasional |

## 5. Penanganan Kegagalan

| Gejala | Penanganan |
|---|---|
| `gzip -t` gagal | Backup rusak, ganti backup yang lebih lama, terima RPO lebih besar, dan periksa apakah cron backup normal |
| Error impor (charset/izin) | Konfirmasi `--default-character-set=utf8mb4` konsisten dengan charset database kosong; konfirmasi user punya izin buat tabel |
| Jumlah baris tidak sesuai baseline | Segera hentikan latihan, periksa apakah impor ke database/file yang salah; skenario pemulihan produksi lanjutkan investigasi dan rollback aplikasi |
| Data tetap kurang setelah replay binlog | Periksa apakah `--stop-datetime` lebih lambat dari waktu mulai backup; konfirmasi replay dimulai dari binlog pertama setelah backup |

## 6. Template Catatan Latihan

```text
Tanggal: 2026-08-16
Target pemulihan: database kosong (skenario A) / titik waktu (skenario B)
File backup: backups/backup_20260816_020000.sql.gz
Baseline jumlah baris: management_admin_user=1, management_owner=42, management_fee_bill=128
Durasi pemulihan: XX menit    Durasi verifikasi: XX menit    Total: XX menit (target ≤ 30)
Hasil: Lulus / Gagal (sertakan alasan kegagalan dan penanganan)
```
