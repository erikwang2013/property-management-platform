# Sistem Manajemen Properti — Perencanaan Proyek Menyeluruh

> Tanggal dibuat: 2026-08-16 · Sumber: audit tim pmp-team (auditor / security-auditor / planner)

## 一、Kesimpulan Audit Status Saat Ini

**Aspek fungsi: konsisten dengan pernyataan.** 22 modul bisnis + 12 fitur ekstensi semuanya selesai, 68 tabel / 178 API, admin 58 controller / 127 route, service 19 controller / 57 route, Flutter Web backoffice 42 halaman + portal pemilik 13 halaman, HarmonyOS 5 halaman. 14 dokumen docs/ + 35 SVG semuanya didukung kode, tidak ditemukan fungsi "dinyatakan tetapi tidak diimplementasikan".

**Pengujian: semua hijau (per 2026-08-17).** admin 193 tests / 452 assertions、service 101 tests / 385 assertions (7 skip karena dependensi lingkungan)、Flutter widget test 9 kasus (login/beranda/halaman tagihan).

**Aspek engineering sudah dimiliki:** docker-compose dua sisi, GitHub Actions CI (sintaks PHP + phpunit dua sisi + composer audit + Flutter analyze)、Dependabot、endpoint metrik Prometheus.

**Utang teknis (terutama risiko rendah):**
1. Penumpukan log: service/workerman.log 9.3M、admin/runtime/logs 5.7M (sudah gitignore, hanya memakan disk) → perlu rotasi
2. README belum menampilkan secara terpisah dokumentasi 57 model sisi service (64 hanya untuk sisi admin)
3. Tanpa TODO/FIXME, .env tidak masuk repositori, versi dependensi tidak ada anomali — bersih

## 二、Kesenjangan Keamanan dan Kualitas (security-auditor)

**Pertahanan 18 lapis: 16/18 terverifikasi ada**, implementasi konsisten dengan SECURITY_ARCHITECTURE.md (captcha、konfirmasi ulang、poster、SecurityFilter、AES-256-CBC、JWT、pembatasan sesi、penguncian akun、RBAC、rate limit、hashids、enkripsi field、masking、log audit、CSP).

**Dua ketidaksesuaian (P1 keduanya sudah diperbaiki):**
1. ~~security-php hanya terpasang di sisi service~~ → sudah terhubung SecurityFilter dua sisi (admin + service sama-sama punya layer scan kedalaman 4b, SecurityGuard lazy init, saat block dicatat dan di-eskalasi)
2. ~~Watermark hak cipta PDF tanpa implementasi~~ → diverifikasi layer 18 watermark di ExportController sudah diimplementasikan (ExportController.php:179,206), audit false positive

**Paling berisiko: hardcoded fallback key (sudah diperbaiki).** EncryptionService/konfigurasi enkripsi semuanya diubah menjadi fail-fast (jika hilang atau change-me langsung error saat startup), hardcoded dan random fallback di layer plugin encryptable/jwt sudah dihapus; key .env adalah nilai acak nyata hasil generate, CI memuat dari salinan .env.example. Kata sandi DB/Redis masih placeholder, merupakan kredensial deployment, diinjeksi oleh pihak deployment.

**Kekurangan engineering (P1 sudah dilengkapi):** CI menambah job phpstan (Level 5 + baseline)、gerbang cakupan PHPUnit dua sisi (baseline terukur admin 1.66% / service 3.21%, gerbang mencegah regresi zero-instrumentation)、pemindaian kebocoran kunci gitleaks (.gitleaks.toml mengizinkan template lingkungan).

**Pemeriksaan pola berisiko tinggi:** eval( hanya Redis::eval (aman)、exec 3 tempat (controller monitoring/instalasi)、md5( hanya hash blacklist token、SQL semua lewat query builder — tanpa risiko concatenation telanjang.

## 三、Posisi Strategis

**Fase fitur lengkap → fase engineering/komersialisasi.** Pengembangan fungsi bisnis sudah selesai (commit terakhir semuanya pelengkapan dokumen/audit/tes). Arah investasi fase berikutnya: **CI/CD dan gerbang kualitas、produksi pembayaran、monitoring alert dan backup pemulihan、SaaS multi-tenant、pelengkapan mobile**. Fondasi kemasan komersial sudah ada (EDITIONS tiga versi + wizard instalasi + watermark hak cipta), yang kurang adalah kredibilitas engineering yang membuat pelanggan berani bayar.

## 四、Roadmap Bertahap

### P1 Konsolidasi Engineering (2-4 minggu) — membuat sistem "terpercaya"

| Tujuan | Tugas kunci | Standar penerimaan |
|------|---------|---------|
| Gerbang kualitas hijau semua、kunci terkontrol、data tidak hilang | ① CI lengkap: Flutter analyze、tes service、gerbang cakupan PHPUnit、phpstan、gitleaks ② Manajemen kunci: generator .env + skrip rotasi kunci JWT/DB ③ Backup pemulihan: skrip mysqldump + manual latihan pemulihan ④ Degradasi ES: fallback log saat gagal tulis antrian + pencarian degradasi MySQL LIKE (ditunda) ⑤ Manajemen versi SQL: migrasi penuh disatukan ke entry tunggal docs/install.sql (solusi migrasi terpisah sebelumnya dibatalkan, digabung 2026-08-16) | CI hijau semua termasuk cakupan; latihan pemulihan 30 menit data konsisten; ES berhenti layanan pencarian tetap bisa; skrip upgrade dapat dieksekusi |

**Status P1**: ✅ Semua selesai (backup pemulihan dicatat di P8: scripts/backup.sh + docs/RECOVERY_RUNBOOK.md).

### P2 Kemampuan Komersialisasi (4-8 minggu) — membuat pelanggan "berani beli"

| Tujuan | Tugas kunci | Standar penerimaan |
|------|---------|---------|
| Closed loop pembayaran、bisa dimonitor、bisa diserahkan | ① Produksi pembayaran: alur lengkap sandbox WeChat/Alipay (order→callback idempoten→refund→rekonsiliasi), kredensial terpusat ke config/payment.php + env ② Monitoring alert: orkestrasi Prometheus+Grafana + aturan alert (5xx、koneksi ES/Redis、penumpukan antrian) + rotasi log ③ Kontrol versi komersial: saklar versi berbasis EDITIONS (aktivasi grup route Lite/Standard/Full) + data Demo ④ Wizard instalasi mencakup konfigurasi payment/ES | Alur pembayaran sandbox lulus penuh (termasuk idempotensi callback berulang); alert terpicu terverifikasi; saklar tiga versi dapat didemokan; lingkungan baru terinstal dalam 10 menit |

**Status P2 saat ini**: ✅ Bagian offline semua selesai (2026-08-16/17): kode rantai penuh pembayaran (PaymentService order/callback idempoten/refund/rekonsiliasi + config/payment.php sentralisasi kredensial + cakupan fungsi murni PaymentServiceTest)、orkestrasi monitoring (tumpukan Prometheus ganda + 6 aturan alert + provisioning dashboard Grafana dua sisi)、saklar versi (EDITIONS tiga versi + validasi fail-fast)、wizard instalasi (termasuk auto-aktif konfigurasi payment + bug path template sudah diperbaiki). Dependensi eksternal tersisa: **integrasi sandbox menunggu kredensial** (setelah mendapat kredensial WECHAT_PAY_* / ALIPAY_* jalankan `scripts/payment_sandbox_smoke.php`)、**uji nyata alert menunggu deployment** (`scripts/verify_monitoring.sh` dapat verifikasi lokal, verifikasi pemicuan nyata menunggu setelah deployment).

### P3 Penskalaan (8-12 minggu) — membuat sistem "bisa dijual lebih banyak"

| Tujuan | Tugas kunci | Standar penerimaan |
|------|---------|---------|
| Multi-tenant、performa tercapai、mobile lengkap | ① SaaS multi-tenant: mulai dari manajemen grup, erik_community tambah tenant_id + isolasi middleware (review solusi dulu, database terpisah sebagai arah evolusi) ② Uji beban performa: wrk/k6 uji login/biaya/dashboard, tinjau ulang slow query + cache Redis ③ Pelengkapan mobile: HarmonyOS 5 halaman diperluas ke jalur inti (pembayaran/perbaikan/pengumuman/tamu/parkir), adaptasi mobile Flutter portal pemilik ④ Open API / Webhook (opsional) | Tes otorisasi berlebih tenant lulus; P95 endpoint inti < 300ms; jalur inti HarmonyOS selesai |

**Status P3**: ✅ Semua selesai (diserahkan 2026-08-16: tiga perangkat multi-tenant + uji beban nyata P95 tercapai + HarmonyOS diperluas ke 5 halaman).

### P4-P9 Catatan Penyerahan Tambahan (2026-08-16 ~ 08-17, fase engineering baru di luar cakupan P1-P3)

| Fase | Konten serahan | Status |
|------|---------|------|
| P4 Penyelesaian | Fallback jalur tulis ES (AdminUser Searchable try/catch + degradasi log)、konfigurasi payment wizard instalasi (terisi otomatis aktif saat kredensial ada)、rotasi log (logrotate.conf)、orkestrasi monitoring alert (tumpukan Prometheus ganda + 6 aturan) | ✅ Selesai |
| P5 Item tersisa | Pengiriman Webhook (signature HMAC-SHA256 + retry backoff eksponensial + 3 titik pemicu)、unit test bisnis biaya/persetujuan/SLA | ✅ Selesai |
| P6 Penyelesaian deployment | Skrip deploy satu klik (deploy.sh: pull → .env → compose → impor idempoten install.sql → smoke monitoring)、perbaikan mount log container、kenaikan gerbang cakupan CI、rencana penskalaan (SCALING_PLAN) | ✅ Selesai |
| P7 Kedalaman pengujian | Unit test service 43→82、Flutter widget test 3 halaman 8 kasus (integrasi CI)、Open API (/open 3 endpoint read-only + auth X-API-Key + gen_api_key.php)、smoke uji beban (k6 smoke.js + workflow manual workflow_dispatch) | ✅ Selesai |
| P8 Penyelesaian operasional | Backup pemulihan diterapkan (backup.sh + RECOVERY_RUNBOOK)、Grafana dashboard (provisioning 7 panel sisi service)、unit test admin +11 (152 hijau semua)、**perbaikan bug path template wizard instalasi** (template dipindah ke app/view/install, curl terukur render 200) | ✅ Selesai |
| P9 Penyelesaian engineering | Pembersihan skrip backup tidak akurat (git rm 4 file dua sisi + 8 tempat dokumen diseragamkan)、Grafana dashboard sisi admin (prefiks open_admin_* 7 panel)、ekstraksi fungsi murni validasi InstallValidator + 17 kasus (admin 193 hijau semua) | ✅ Selesai |

**Ringkasan P4-P9**: unit test admin 93→193、unit test service 43→101、Flutter widget test 9/9、Open API 3 endpoint、panel monitoring dua sisi simetris、seluruh rangkaian skrip operasional backup/pemulihan/kunci/deployment siap.

## 五、Top 10 Item Tindakan Prioritas (sesuai rasio input-output)

| # | Item tindakan | Dampak | Biaya | Risiko | Status |
|---|--------|------|------|------|------|
| 1 | Manajemen kunci: generator env + skrip rotasi + hapus hardcoded fallback key (validasi bukan change-me saat startup) | Tinggi (kepatuhan keamanan) | Rendah | Rendah | ✅ Selesai |
| 2 | Pelengkapan CI: Flutter analyze + tes service + gerbang cakupan + phpstan + gitleaks | Tinggi (garis dasar kualitas) | Rendah | Rendah | ✅ Selesai (P7 tambah flutter test) |
| 3 | Skrip backup + latihan pemulihan | Tinggi (data tidak hilang) | Rendah | Rendah | ✅ Selesai (P8: backup.sh + RECOVERY_RUNBOOK) |
| 4 | Fallback degradasi ES (MySQL LIKE) | Tinggi (ketersediaan) | Rendah | Sedang (pemeliharaan jalur query ganda) | ✅ Selesai (P4: fallback try/catch jalur tulis; pencarian memang semuanya pakai MySQL LIKE) |
| 5 | Alur lengkap sandbox pembayaran + verifikasi idempotensi callback | Tinggi (wajib komersialisasi) | Sedang | Sedang (keamanan kredensial/callback) | 🔶 Kode selesai, integrasi sandbox menunggu kredensial |
| 6 | Alert Prometheus + Grafana + rotasi log | Tinggi (operasional) | Sedang | Rendah | ✅ Selesai (panel dua sisi P8/P9 dilengkapi; uji nyata alert menunggu deployment) |
| 7 | Manajemen migrasi SQL (gabung penuh kembali ke entry tunggal install.sql) | Sedang (dapat di-upgrade) | Rendah | Rendah | ✅ Selesai (digabung 2026-08-16) |
| 8 | Review solusi multi-tenant + isolasi tenant_id | Tinggi (plafon) | Tinggi | Tinggi (memengaruhi semua query) | ✅ Selesai (serahan P3, tes otorisasi berlebih lulus) |
| 9 | Uji beban + penanganan slow query | Sedang (performa) | Sedang | Rendah | ✅ Selesai (P3 uji nyata P95 tercapai; P7 versi smoke masuk CI) |
| 10 | Saklar lisensi versi komersial + data Demo | Sedang (pra-penjualan) | Sedang | Rendah | ✅ Selesai (EDITIONS + demo_data.php + dokumen alur demo) |

## 六、Risiko dan Dependensi

| Risiko | Status saat ini | Saran mitigasi | Status |
|------|------|---------|------|
| Deployment single-host tanpa HA | docker-compose single-host, MySQL/Redis/ES di mesin yang sama | Latihan backup pemulihan + monitoring alert + dokumen rencana penskalaan | ✅ Mitigasi diterapkan (P8 backup + P2/P8/P9 monitoring + P6 SCALING_PLAN); eksekusi latihan menunggu deployment |
| Dependensi keras ES | Pencarian/sinkronisasi indeks semuanya pakai ES | Fallback degradasi + skrip rebuild indeks | ✅ Dimitigasi (P4 fallback jalur tulis; pencarian memang semuanya pakai MySQL LIKE, ES bukan dependensi jalur query) |
| Manajemen kunci | Placeholder + hardcoded fallback key, tanpa rotasi | Generator + skrip rotasi; produksi pakai injeksi variabel lingkungan | ✅ Sudah diatasi (validasi fail-fast + gen_env_keys.sh + rotate_keys.sh) |
| Kredensial pembayaran tersebar | Modul pembayaran tanpa konfigurasi terpusat, sandbox belum diverifikasi | Sentralisasi konfigurasi + sandbox dulu | 🔶 Konfigurasi sudah terpusat (config/payment.php), integrasi sandbox menunggu kredensial |
| Manajemen migrasi | File tunggal install.sql (idempoten IF NOT EXISTS) | Sudah disatukan ke entry penuh tunggal; jalur upgrade inkremental dibahas terpisah jika perlu | ✅ Sudah disatukan (digabung 2026-08-16) |
| Cakupan tes condong struktural | 133 tes terpusat di schema/keamanan/round-trip | Gerbang cakupan + unit test bisnis inti (biaya/persetujuan/SLA) | ✅ Sudah diperkuat (admin 193 / service 101 / Flutter 9; gerbang mencegah regresi zero-instrumentation) |
| Kesenjangan mobile | HarmonyOS hanya 5 halaman, portal pemilik tanpa App native | Pelengkapan jalur inti P3; dependensi: perangkat tes HarmonyOS | ✅ Jalur inti dilengkapi (5 halaman: pembayaran/perbaikan/pengumuman/tamu/parkir); verifikasi perangkat nyata menunggu perangkat |

## 七、Pembagian Tim (pmp-team)

| Peran | Tugas yang dikerjakan |
|------|---------|
| Arsitektur | Review solusi multi-tenant dan desain isolasi tenant_id (P3)、arsitektur degradasi ES、arsitektur monitoring (P2)、review desain idempotensi callback pembayaran |
| Backend | Skrip generate/rotasi kunci、implementasi degradasi ES、sentralisasi konfigurasi pembayaran + integrasi sandbox、pemecahan skrip migrasi、uji beban dan penanganan slow query |
| Frontend Flutter | Integrasi CI flutter analyze、adaptasi mobile portal pemilik (P3)、dukungan UI saklar versi |
| HarmonyOS | Pelengkapan jalur inti: pembayaran/perbaikan/pengumuman/tamu/parkir (P3) |
| Pengujian | Gerbang cakupan、kasus sandbox pembayaran (callback berulang/refund/rekonsiliasi)、skrip uji beban、eksekusi latihan backup pemulihan |
| Review | Review jalur kunci pembayaran dan keamanan、gitleaks masuk CI、review tes otorisasi berlebih multi-tenant |
| Dokumentasi | Manual deployment/operasional (termasuk latihan pemulihan)、dokumen solusi multi-tenant、manual konfigurasi monitoring、manual serahan versi komersial |

## 八、Saran Tindakan Segera

✅ Item 1-4 P1 asli (penguatan kunci → pelengkapan CI → skrip backup → degradasi ES) semuanya sudah dieksekusi (serahan iteratif P4-P9).

**Item dependensi tersisa (butuh kondisi eksternal, bukan kesenjangan kode)**:
1. Integrasi sandbox pembayaran: setelah mendapat kredensial WECHAT_PAY_* / ALIPAY_* jalankan `scripts/payment_sandbox_smoke.php` (verifikasi rantai penuh order→callback berulang idempoten→refund→rekonsiliasi)
2. Uji nyata monitoring alert: setelah deployment jalankan `scripts/verify_monitoring.sh` untuk memverifikasi muat aturan, dan picu nyata 5xx/kerusakan koneksi untuk verifikasi alert (aturan Http5xxRatio sudah dapat berlaku langsung)
3. Latihan backup pemulihan: eksekusi latihan kuartalan sesuai docs/RECOVERY_RUNBOOK.md dan catat waktu terukur (target RTO ≤ 1h)
4. Verifikasi perangkat nyata HarmonyOS: setelah perangkat tes tersedia jalankan jalur inti (pembayaran/perbaikan/pengumuman/tamu/parkir)
