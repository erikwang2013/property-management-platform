# Laporan Uji Beban Performa dan Penanganan Slow Query（2026-08-16）

Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. Lingkungan dan Metode Pengujian

| Item | Nilai |
|---|---|
| Aplikasi | webman v2 (PHP 8.3, 32 worker), dua aplikasi admin + service |
| Instance yang diuji | admin port independen 8790 (`SERVER_LISTEN=http://0.0.0.0:8790`) |
| Alat | k6 v0.51.0 (tidak ada wrk/ab/hey di mesin lokal), skrip lihat `scripts/loadtest/` |
| Target uji beban | login (/api/auth/login), dashboard (/admin/dashboard), daftar pembayaran biaya (/admin/fee-payment) |
| Autentikasi | dashboard/fee menggunakan `scripts/loadtest/mint-token.php` untuk menerbitkan JWT (melewati captcha, `sub=21000000000000100`); skrip login menggunakan captcha tidak valid untuk memeriksa jalur |
| Data | koneksi langsung single-host 127.0.0.1, tidak melalui gateway/CDN; MySQL/Redis di mesin yang sama dengan aplikasi |

Entry skrip: `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]` (k6 harus ada di PATH).
Penjelasan skrip login: login memiliki perlindungan ganda captcha + rate limit (10 kali/menit/IP), ini desain keamanan, tidak dapat dan tidak boleh diuji beban dengan konkurensi tinggi; login.js menggunakan 1 VU / 8 request dengan kecepatan rendah untuk memeriksa latensi jalur, diharapkan mengembalikan 422 (captcha salah) atau 429 (rate limit), keduanya adalah pertahanan yang berfungsi normal.

## 2. Hasil Uji Beban

### 20 VU / 30s (Beban Dasar)

| Endpoint | Jumlah request | Throughput | avg | p90 | p95 | max | Tingkat kegagalan |
|---|---|---|---|---|---|---|---|
| login (1 VU × 8 kali) | 8 | 14.4/s | 68.6ms | 154ms | 207.8ms | 261ms | 0% |
| dashboard | 6863 | 227.9/s | 86.0ms | 151ms | 189.5ms | 1.37s | 0% |
| fee-payment | 5944 | 197.2/s | 99.3ms | 178ms | 220.0ms | 704ms | 0% |

### 50 VU / 30s (Tekanan)

| Endpoint | Jumlah request | Throughput | avg | p95 | max | Tingkat kegagalan |
|---|---|---|---|---|---|---|
| login (1 VU × 8 kali) | 8 | 18.7/s | 52.1ms | 173ms | 243.8ms | 0% |
| dashboard | 6902 | 226.9/s | 212.7ms | 544.0ms | 1.99s | 0% |
| fee-payment | 7525 | 247.4/s | 195.7ms | 514.2ms | 2.0s | 0% |

(Pada 50 VU, p95 > ambang 500ms, k6 menentukan ambang terlampaui lalu keluar, tetapi 0% request gagal, 0 non-200.)

### Kesimpulan

- Semua endpoint pada 20 VU memiliki 0 kegagalan, p95 < 220ms, sehat.
- **Bottleneck throughput sekitar 230–250 rps**: 20 VU → 50 VU throughput tidak naik justru datar (dashboard 227.9 → 226.9, fee 197 → 247), sedangkan latensi p95 berlipat ganda (~190ms → ~540ms). Pada single-host 32 worker, setiap worker sekitar 7–8 rps, ini karakteristik batas pemrosesan single-core rantai penuh PHP (termasuk query MySQL, round-trip cache Redis), bukan kehabisan koneksi (tidak ada request gagal).
- Saran: skala single-host sudah cukup untuk kebutuhan ini (sekitar 20 juta request/hari); jika ingin throughput lebih tinggi, prioritaskan penambahan instance horizontal, lalu periksa SQL dan cache hit setiap endpoint (lihat di bawah).

## 3. Tinjauan Slow Query

- Tabel biaya `erik_fee_bill` / `erik_fee_payment` memiliki indeks lengkap (paid_at, bill_id, owner_id, payment_number, dst.), query inti semua punya indeks yang tersedia.
- Temuan: pencarian fuzzy daftar biaya berdasarkan `payment_number like %kw%` (wildcard awalan), tidak bisa memakai indeks, saat data besar kondisi ini akan menurun menjadi full table scan. Ini pencarian panel admin frekuensi rendah, tidak ditangani untuk saat ini; setelah data bertambah bisa diubah menjadi inverted index atau prefix index.
- **MySQL slow_query_log dalam keadaan OFF**: disarankan mengaktifkan dan set `long_query_time=1`, terus amati SQL lambat yang sebenarnya (bukan mengandalkan inferensi uji beban). Eksekusi produksi:
  ```sql
  SET GLOBAL slow_query_log = ON;
  SET GLOBAL long_query_time = 1;
  ```
- Agregasi dashboard: setiap kali cache dibangun ulang mengeksekusi sekitar 8 agregasi COUNT + statistik grup 30 hari, biaya sekali rebuild dalam hitungan detik, diserap cache Redis 5 menit (lihat di bawah), bukan jalur panas.

## 4. Pemeriksaan Ulang Cache Redis

- Cache dashboard `dashboard:data`: `setex 300`, saat hit ~10ms, miss rebuild dalam hitungan detik. **Masalah: tidak ada logika invalidasi operasi tulis**, setelah data berubah paling lama 5 menit basi. Disarankan menghapus key ini di endpoint tulis biaya/properti (satu baris `del dashboard:data`).
- **Tidak ada proteksi cache breakdown**: saat key kedaluwarsa, 32 worker sekaligus membangun ulang (mengulang 8 query agregasi). Setelah data besar disarankan menambah mutual exclusion sederhana (misal lock `set nx ex` + double check).
- Cache permission `perm:{adminId}` 60s, perilaku normal.
- Item investigasi tersisa: di Redis mesin lokal tidak pernah teramati key `dashboard:data` (beberapa db tidak ada), tetapi respons endpoint normal dan latensi hit jelas lebih rendah. Saat uji beban sesekali muncul 403 "akses tanpa izin" (muncul 2 kali lalu stabil 200). Diduga konfigurasi multi-instance Redis lokal/variabel lingkungan berbeda dengan produksi, perlu diverifikasi ulang di lingkungan target, tidak memengaruhi kesimpulan uji beban (segmen stabil 0 kegagalan).

## 5. Deliverable

- `scripts/loadtest/mint-token.php` — menerbitkan JWT uji beban (`php mint-token.php --file=/tmp/pmp-token`)
- `scripts/loadtest/login.js` / `dashboard.js` / `fee.js` — skrip k6
- `scripts/loadtest/run.sh` — run satu klik (mint token + tiga skrip, parameter: BASE_URL VUS DURATION)
- Laporan ini

Perintah reproduksi: `PATH=/home/erik/bin:$PATH bash scripts/loadtest/run.sh http://127.0.0.1:8790 20 30s`
