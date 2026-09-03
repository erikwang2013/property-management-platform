# Daftar Kesenjangan Pelengkapan Mobile

> Tanggal dibuat: 2026-08-16 · Sumber: pmp-team ci-agent (P3-③ inventaris status, read-only)
> Roadmap terkait: docs/PROJECT_PLAN.md P3 — "Perluas 7 halaman HarmonyOS ke jalur inti (pembayaran/perbaikan/pengumuman/tamu/parkir), adaptasi mobile Flutter portal pemilik"

## 一、Status Saat Ini Portal Pemilik HarmonyOS（apps/harmonyos，7 halaman）

| Halaman | Route (terdaftar di main_pages.json) | API yang dipanggil |
|------|------------------------------|---------|
| LoginPage | pages/LoginPage | login (AuthService) |
| HomePage | pages/HomePage | GET /service/v1/home (dashboard: tagihan tertunda/tiket/properti + daftar pengumuman) |
| FeeBillsPage | pages/FeeBillsPage | GET /service/v1/fees/bills?page=1&per_page=50 |
| RepairListPage | pages/RepairListPage | GET /service/v1/repairs |
| RepairSubmitPage | pages/RepairSubmitPage | POST /service/v1/repair |
| AnnouncementPage | pages/AnnouncementPage | GET /service/v1/announcements?page=1&per_page=50 |
| ProfilePage | pages/ProfilePage | GET /service/v1/profile、POST /service/v1/profile/logout |

**Status navigasi saat ini** (hanya 4 transisi di seluruh aplikasi): Login→Home、Home→Login (keluar)、Profile→Login、RepairList→RepairSubmit。HomePage hanya kartu statistik + daftar pengumuman, tanpa grid entry fungsi; halaman FeeBills/Announcement/Profile ada tetapi **tanpa entry, tidak dapat diakses**。

## 二、Perbandingan Jalur Inti HarmonyOS

| Jalur inti | Status | Jenis kesenjangan |
|---------|------|---------|
| Pembayaran | halaman ada, API terhubung | Murni frontend: Home tanpa entry (tidak dapat diakses) |
| Perbaikan | halaman daftar+submit ada, API terhubung | Murni frontend: Home tanpa entry (tidak dapat diakses) |
| Pengumuman | halaman ada, API terhubung | Murni frontend: Home tanpa entry (tidak dapat diakses) |
| Tamu | halaman tidak ada | Perlu buat halaman baru (API sudah ada: GET/POST/PUT/DELETE /visitor*) |
| Parkir | halaman tidak ada | Perlu buat halaman baru (API sudah ada: /parking/vehicles、/parking/spaces、/parking/records) |

Backend tanpa kesenjangan: API service 5 jalur inti semuanya siap (fees/repairs/announcements route permanen; parking/visitors di dalam gating versi standard). ApiService.ets sudah punya get/post/put/delete umum, halaman baru bisa langsung reuse.

## 三、Status Saat Ini Flutter Portal Pemilik（apps/flutter，13 modul）

**Daftar halaman**: login、home、fee、repair、parking×3、visitor×2、activity、notification、vote、mall×3、chat、face、profile — semuanya sudah terdaftar route (getPages di app.dart), 5 jalur inti semuanya sudah diimplementasikan.

**Masalah adaptasi mobile**: hanya home_page / login_page yang menggunakan LayoutBuilder/MediaQuery responsive breakpoint; **10 halaman hardcode lebar desktop**, pada lebar ponsel (<400px) pasti RenderFlex overflow:

| Halaman | Hardcode |
|------|--------|
| chat_page | SizedBox(width: 600) |
| mall_products_page | width: 800 |
| mall_product_detail / mall_orders | SizedBox(width: 600) |
| notification_list | width: 480 + SizedBox(width: 600) |
| vote_list / vote_detail | SizedBox(width: 600) |
| activity_detail、parking_records/vehicles、visitor_list、face_register | tanpa penanganan breakpoint (diduga masalah serupa, belum diverifikasi baris per baris) |

Selain itu: tidak ada bottom navigation bar (BottomNavigationBar), entry hanya mengandalkan AppBar + grid; padding halaman 24 cenderung gaya desktop. i18n dua bahasa sudah tersedia.

## 四、Daftar Kesenjangan（klasifikasi + beban kerja）

### Bergantung backend (tidak ada)

### Murni frontend

| # | Item | Beban kerja |
|---|----|--------|
| 1 | HomePage HarmonyOS tambah grid entry fungsi (bandingkan 12 entry versi Flutter), sambungkan pembayaran/perbaikan/pengumuman/tamu/parkir/pusat pribadi | M |
| 2 | HarmonyOS tambah VisitorPage (daftar + tambah, reuse VisitorController) | M |
| 3 | HarmonyOS tambah ParkingPage (kendaraan/tempat parkir/rekaman, reuse ParkingController) | M |
| 4 | Flutter portal pemilik hilangkan lebar hardcode (600/800/480 → batasi dalam maxWidth atau ganti ConstrainedBox) | S |
| 5 | Flutter portal pemilik tambah bottom navigation bar + padding ringkas (jika versi ponsel sebagai target penerimaan) | M |

### Perlu koordinasi integrasi

| # | Item | Beban kerja |
|---|----|--------|
| 6 | Verifikasi HarmonyOS di perangkat nyata/emulator jalur lengkap pembayaran→bayar、submit perbaikan、pendaftaran tamu | S (terbatas perangkat pengujian, PROJECT_PLAN sudah mencantumkan risiko ini) |

## 五、Saran Urutan Implementasi

1. Kesenjangan 1 (rasio biaya-manfaat tertinggi: reuse 3 halaman yang ada, nol halaman baru)
2. Kesenjangan 4 (overflow Flutter adalah masalah fatal, ponsel pasti crash)
3. Kesenjangan 2、3 (halaman baru)
4. Kesenjangan 5 (optimalisasi pengalaman)
5. Kesenjangan 6 (butuh perangkat, dikerjakan terpisah)
