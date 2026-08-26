# Rencana Penskalaan (Scaling Plan)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

Deployment saat ini adalah docker-compose single-host (MySQL/Redis/Elasticsearch di mesin yang sama dengan aplikasi, lihat `admin/docker-compose.yml`), tanpa HA. Dokumen ini menjelaskan risiko dan mitigasi yang ada, memberikan jalur penskalaan horizontal, titik pemicu pertumbuhan data, dan saran latihan. Baseline operasional (backup/pemulihan, monitoring alert, rotasi log) lihat [OPS_RUNBOOK.md](OPS_RUNBOOK.md).

---

## 1. Deployment Saat Ini dan Risiko

### 1.1 Status Saat Ini

| Komponen | Versi | Deskripsi |
|------|------|------|
| MySQL | 8.0.36 | Instance tunggal, data dipersist di volume host |
| Redis | 7.2-alpine | Instance tunggal, cache/antrian/lock |
| Elasticsearch | 8.12.0 | Node tunggal, pencarian teks lengkap scout |
| nginx + webman | — | admin (8787) dan service (8788) multi-proses di mesin yang sama |
| Prometheus + Grafana | — | Monitoring alert, di mesin yang sama |

### 1.2 Daftar Risiko

| Risiko | Dampak | Probabilitas | Konsekuensi |
|------|------|------|------|
| Single point of failure (middleware mana pun down) | Seluruh situs tidak tersedia | Rendah | Tinggi |
| Perebutan disk/memori/CPU host | Slow query, ES lambat, OOM | Sedang (naik setelah data bertambah) | Sedang |
| MySQL single instance rusak tak terpulihkan | Kehilangan data | Sangat rendah | Sangat tinggi |
| Tanpa data center cadangan | Kehilangan total kegagalan level data center | Sangat rendah | Sangat tinggi |
| Backup/pemulihan belum dilatih | Pemulihan timeout atau gagal | Sedang | Tinggi |

## 2. Mitigasi yang Ada (sudah diimplementasikan)

- **Backup**: skrip backup entry tunggal `scripts/backup.sh` (membaca koneksi dari `admin/.env`, default mysqldump di dalam container), backup penuh harian via crontab, default simpan 7 hari (`--keep-days=30` dapat dikonfigurasi); alur latihan pemulihan dan penjelasan RPO/RTO lihat OPS_RUNBOOK §1 dan RECOVERY_RUNBOOK.
- **Monitoring alert**: Prometheus + Grafana + `deploy/monitoring/alerts.yml`, mencakup AppDown / MysqlDown / RedisDown / ElasticsearchDown / QueueBacklog, lihat OPS_RUNBOOK §3.
- **Rotasi log**: log container `max-size 10m`, log host logrotate harian simpan 30 hari, lihat OPS_RUNBOOK §4.
- **Lapisan aplikasi**: webman multi-proses resident, tugas antrian mendekoupl operasi yang memakan waktu, health check `/health`.

Kesimpulan: mitigasi di atas mencakup "kegagalan dapat dipulihkan", **tidak mencakup "kegagalan tanpa interupsi"**. Jika bisnis tidak menerima interupsi, perlu masuk ke §3 penskalaan horizontal.

## 3. Jalur Penskalaan Horizontal (sesuai prioritas)

Prinsip umum penskalaan: pertama vertikal (tambah CPU/memori/disk) lalu horizontal (pisahkan komponen), pertama middleware lalu aplikasi, setiap langkah dapat rollback independen.

### 3.1 MySQL Master-Slave + Semi-Sync (Prioritas Pertama)

- Arsitektur: master (instance yang ada) → slave (mesin baru), aktifkan replikasi semi-sync (`rpl_semi_sync_master_enabled=1`).
- Perluasan baca: aplikasi konfigurasi pemisahan master-slave (aktifkan jika `config/database.php` mendukung read-write split; jika tidak, awalnya hanya lakukan master-slave HA).
- Migrasi backup: skrip backup diubah menunjuk ke slave, hindari backup membebani master.
- Versi: slave harus sama versi mayor dengan master (saat ini 8.0.36).
- Kondisi upgrade: CPU master terus >70%, koneksi mendekati max_connections, jumlah baris yang dipindai di slow query log melonjak.

### 3.2 Redis Sentinel atau Cluster (Prioritas Kedua)

- Sentinel (3 node): jika kebutuhan kapasitas tidak tinggi pilih sentinel, failover dalam hitungan detik, client harus mendukung mode `sentinel`.
- Cluster (≥3 master 3 slave): jika jumlah cache > memori single-host, atau konkurensi tulis naik, pilih Cluster.
- Catatan: antrian dan distributed lock bergantung pada Redis, saat mengganti topologi perlu sinkron mengubah `config/redis.php` dan memverifikasi perilaku lock/antrian di bawah failover.

### 3.3 Node Independen Elasticsearch

- ES single node tanpa replika, jika indeks rusak maka pencarian tidak tersedia. Minimal migrasi ke mesin independen + 1 replika.
- Setelah data bertambah, pecah berdasarkan indeks (sesuai domain bisnis), matikan replika indeks yang tidak perlu untuk mengontrol resource.
- Kondisi upgrade: heap memory >70% terus-menerus, penolakan tulis (`es_rejected_executions` naik), P95 query melebihi 1s.

### 3.4 Multi-Replika Aplikasi + Load Balancing (Terakhir)

- admin/service masing-masing jalankan 2+ replika, depan nginx load balancing (round robin atau least_conn).
- Prasyarat: stateless (session di Redis, tanpa dependensi penulisan file lokal; sistem ini JWT + Redis session, pada dasarnya terpenuhi).
- Setelah itu kapasitas pemrosesan berlipat ganda sesuai jumlah replika, lalu kembali ke bottleneck middleware §3.1-3.3.

## 4. Titik Pemicu Pertumbuhan Data dan Saran

| Titik pemicu | Ambang yang disarankan | Tindakan wajib |
|--------|----------|----------|
| Total database | > 50GB atau satu tabel > 50 juta baris | Pemisahan master-slave + arsip tagihan/log historis |
| Slow query | Rata-rata harian > 10 atau satu > 2s | Tambah indeks, partisi tabel, periksa N+1 |
| Koneksi MySQL | Terus > 80% max_connections | Connection pool + master-slave |
| Memori Redis | > 70% dan terus tumbuh | Bersihkan key kedaluwarsa → Sentinel → Cluster |
| Heap memory ES | > 70% atau penolakan tulis | Node independen + replika + pecah indeks |
| CPU | Single-core terus > 80% dan antrian menumpuk | Multi-replika aplikasi → pisahkan middleware |
| Disk | > 80% | Bersihkan backup/log, arsipkan data dingin |

Saran: periksa tabel di atas sebulan sekali (data bisa dari panel Grafana), jika item mana pun melewati ambang dua minggu berturut-turut, mulai penskalaan yang sesuai.

## 5. Saran Latihan Penskalaan

- **Setiap kuartal sekali**: latihan pemulihan (lihat OPS_RUNBOOK §1.3), verifikasi RPO/RTO tercapai.
- **Setiap tahun sekali**: latihan failover master-slave (latihan di mesin baru, jangan sentuh master produksi): buat slave → kejar ketertinggalan → switch → verifikasi baca/tulis kedua sisi → switch kembali.
- **Setelah penskalaan pertama**: gunakan `scripts/loadtest` uji beban tiga jalur (login/daftar/pencarian) konfirmasi P95 tercapai (referensi `docs/PERFORMANCE_REPORT_2026-08-16.md`).
- **Catatan latihan**: setiap latihan dicatat di changelog (CHANGELOG.md), termasuk: waktu, item latihan, hasil, masalah tersisa.

## 6. Referensi Cepat Jalur Upgrade

```
Single-host (status saat ini)
  ├─ MySQL master-slave semi-sync  ← Prioritas pertama
  ├─ Redis Sentinel/Cluster        ← Prioritas kedua
  ├─ ES node independen+replika     ← Prioritas ketiga
  └─ Multi-replika aplikasi+LB       ← Terakhir
        ↓
Deploy multi-mesin (tanpa SPOF, menerima interupsi kegagalan → menerima interupsi menit → failover detik)
```

> Volume bisnis saat ini tidak memerlukan penskalaan, dokumen ini untuk "saat kebutuhan data/kegagalan berubah" langsung diikuti, hindari keputusan dadakan.
