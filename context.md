# Project Context: Yotro (Personal Finance & Wealth Manager)

Dokumen ini adalah **single source of truth** untuk konteks proyek **Yotro** (sebelumnya Money Tracker). Gunakan dokumen ini sebagai acuan utama saat memulai sesi baru atau berpindah model AI coding assistant.

---

## 1. Ringkasan Proyek (Executive Summary)

- **Nama Aplikasi:** Yotro (Fin-tech Personal Finance App).
- **Tujuan Utama:** Aplikasi pencatat keuangan offline-first dengan UI ultra-clean, modern, minimalist dark mode, performa tinggi, dan zero-slop.
- **Tech Stack:**
  - **Framework Utama:** Flutter (Cross-platform Android, iOS, Web).
  - **Komponen UI:** [Forui](https://forui.dev/) (`forui: ^0.27.7`) dengan tema `FThemes.slate.dark`.
  - **Tipografi:** Google Fonts (`google_fonts: ^6.2.1`):
    - `Inter Tight`: Display angka finansial, total balance, dan heading tajam.
    - `Manrope`: Body text, subtitle, input label, dan navigasi.
  - **State Management:** `provider: ^6.1.2` (`TransactionProvider`).
  - **Penyimpanan Lokal:** `shared_preferences: ^2.2.3` (serialisasi JSON offline-first).
  - **Native Permissions:** `permission_handler: ^13.0.2` (Izin notifikasi native OS).
  - **Format Mata Uang & Tanggal:** `intl: ^0.20.3` (Default: `IDR` / `Rp`, opsi `USD`).
  - **Web Preview:** Flutter Web release di `build/web/`, dengan `web/index.html` sebagai bootstrap (live preview lokal port `8080`).
  - **CI/CD Cloud Build:** GitHub Actions `.github/workflows/build-apk.yml` untuk menguji serta membangun signed safe-release APK dan Flutter Web.

---

## 2. Struktur Direktori & Pemetaan Berkas (Codebase Map)

```text
money-tracker/
├── .github/
│   └── workflows/
│       └── build-apk.yml           # CI test/build; GitHub Release APK hanya dari tag versi tervalidasi
├── android/                        # Android harness (AGP 8.11.1, Kotlin 2.2.21, SDK 37, AndroidX)
│   ├── app/proguard-rules.pro      # Aturan ProGuard R8 untuk ML Kit Latin Text Recognition
│   └── key.properties.example      # Template konfigurasi signing; key asli wajib private/diabaikan Git
├── assets/
│   ├── icon/                       # Quick action vector SVGs (Analisis.svg, Budget.svg, Dompet.svg, Split Bill.svg)
│   └── images/                     # Master assets (app_icon.png, logo.png, logo_splash.png, onboarding_bg.png, onboarding_bg.jpg)
├── web/
│   ├── favicon.png                 # Official brand 32x32 favicon
│   ├── icons/                      # Web icons (192x192, 512x512 maskable)
│   └── index.html                  # Bootstrap Flutter Web/PWA bersih (zero floating overlay)
├── supabase/
│   ├── config.toml                 # Konfigurasi Supabase project ref njjcviwihzvzjgfbzitg
│   └── migrations/
│       ├── 20261113000000_init_yotro_schema.sql      # DDL skema database (profiles, wallets, categories, transactions, budgets, RLS)
│       └── 20261113000001_delete_user_account.sql    # PostgreSQL RPC SECURITY DEFINER delete_user_account() untuk hapus akun aman
├── lib/
│   ├── main.dart                   # Entry point aplikasi Flutter (YotroApp)
│   ├── config/
│   │   ├── app_capabilities.dart   # Build-time capability gate untuk Notification Reader sensitif
│   │   └── supabase_config.dart    # Konfigurasi Supabase project ref, default URL, fallback aman & persistensi
│   ├── widgets/
│   │   ├── ambient_top_glow.dart   # Reusable atmospheric sapphire radial glow widget untuk background 4 layar utama
│   │   ├── app_snackbar.dart       # High-contrast floating snackbar helper (anti-slop, rounded, with status icons)
│   │   ├── standard_screen_header.dart # Header terstandarisasi untuk semua sub-halaman (tombol back + judul)
│   │   ├── month_filter_sheet.dart # Komponen terpusat AppMonthFilterPill dan modal sheet showAppMonthFilterSheet (stepper tahun, picker tahun, 12 bulan & bulan ini)
│   │   ├── donut_chart_painter.dart # Reusable Annular Wedge Donut Chart CustomPainter berfillet lingkaran halus
│   │   ├── semicircle_budget_gauge.dart # Semicircular speedometer gauge 180° untuk monitoring batas budget bulanan
│   │   ├── receipt_adjustment_sheet.dart # Modal sheet penyesuaian data struk OCR & persetujuan catat transaksi
│   │   ├── weekly_activity_chart.dart # Grafik batang aktivitas mingguan (single / dual bar)
│   │   ├── spending_calendar_card.dart # Kalender pengeluaran harian
│   │   ├── nested_card.dart        # Reusable card-inside-card container
│   │   ├── modal_card_sheet.dart   # Reusable floating modal bottom sheet
│   │   ├── app_update_dialog.dart  # Modal dialog notifikasi pembaruan OTA dark matte & progress bar unduhan
│   │   ├── circular_spectrum_visualizer.dart # Circular spectrum halus: standby outline + waveform radial audio-reaktif
│   │   ├── voice_recording_sheet.dart # Facade kompatibilitas pembuka layar penuh perekam suara
│   │   ├── voice_multi_item_summary_sheet.dart # Lembar ringkasan multi-item vertikal, inline edit, dan simpan batch
│   │   └── bottom_nav_bar.dart     # Fixed bottom nav bar dengan scooped cradle cutout dan 4 ikon vektor murni
│   │   ├── app_colors.dart         # Token warna, gradien, dan palet gelap matte
│   │   └── app_theme.dart          # Integrasi Forui & Google Fonts ThemeData
│   ├── models/
│   │   ├── transaction_model.dart  # Model data transaksi (Income, Expense, Transfer)
│   │   ├── category_model.dart     # Kategori pengeluaran & pemasukan default/kustom
│   │   ├── wallet_model.dart       # Model dompet/rekening (Bank, Cash, E-Wallet, dsb)
│   │   ├── budget_model.dart       # Model anggaran bulanan & anggaran per kategori
│   │   ├── notification_rule_model.dart # Aturan pemicu/abaikan deteksi notifikasi & antrean pending approval
│   │   ├── receipt_data_model.dart # Model ekstraksi data struk OCR (total, merchant, tanggal, kategori, alternatif)
│   │   ├── voice_transaction_item.dart # Model ekstraksi item transaksi suara & hasil agregat validasi
│   │   └── changelog_model.dart    # Model item riwayat rilis versi aplikasi (versi, tanggal rilis, daftar perubahan)
│   ├── providers/
│   │   └── transaction_provider.dart # State manager, mutasi saldo, kalkulasi budget, tema (system/light/dark), pembaca notifikasi, I/O
│   ├── services/
│   │   ├── app_update_service.dart # Layanan pemeriksaan pembaruan OTA in-app via GitHub Releases API, stream unduhan & installer
│   │   ├── voice_transaction_parser_service.dart # Mesin parsing suara NLP on-device multi-item bahasa Indonesia
│   │   ├── storage_service.dart    # Helper abstraksi penyimpanan lokal
│   │   ├── supabase_auth_service.dart # Otentikasi Supabase (Daftar manual Email+Password+Nama, Masuk Email, Google OAuth, status sesi, sign out & error formatting)
│   │   ├── supabase_sync_service.dart # Mesin sinkronisasi offline-first dua arah (Local <-> Cloud PostgreSQL)
│   │   ├── backup_storage_service.dart # Export/Download berkas cadangan JSON lintas platform (Web & Android)
│   │   ├── backup_storage_stub.dart    # Implementasi ekspor cadangan via temporary file & system share sheet (Android/iOS)
│   │   ├── backup_storage_web.dart     # Implementasi unduh berkas cadangan via Blob & HTML anchor download (Web)
│   │   ├── native_notification_service.dart # Notifikasi lokal, jadwal inexact, dan listener internal yang digate capability
│   │   └── receipt_scanner/        # Layanan pemindaian & parsing OCR struk belanja
│   │       ├── receipt_parser_service.dart   # Mesin parsing cerdas teks struk (grand total vs subtotal, merchant, tanggal, auto-kategori)
│   │       ├── receipt_scanner_service.dart  # Facade abstraksi pemindai struk lintas platform
│   │       ├── receipt_scanner_mobile.dart   # Implementasi OCR native Google ML Kit Text Recognition
│   │       ├── receipt_scanner_web.dart      # Fallback simulasi cerdas OCR untuk web runner
│   │       ├── receipt_scanner_stub.dart     # Stub implementasi platform
│   │       └── receipt_scanner_platform.dart # Conditional export lintas platform
│   ├── screens/
│   │   ├── splash_screen.dart      # Layar Splash Screen beranimasi dengan logo Yotro & navigasi kondisional auth/main
│   │   ├── auth_screen.dart        # Layar Autentikasi Multi-Opsi (Daftar Email + Nama + Password, Masuk Email, Google OAuth, & Mode Tamu 100% Offline)
│   │   ├── onboarding_profile_screen.dart # Layar Baru Onboarding Data Pengguna Pertama Kali (Nama, No Telp, Gender & trigger izin notifikasi native)
│   │   ├── main_shell.dart         # Scaffold utama dengan IndexedStack, Floating Dock, dan PopScope (double back exit / return to Beranda)
│   │   ├── dashboard_screen.dart   # Layar Beranda (Hero Card dengan AppMonthFilterPill, Quick Action, Transaksi, bell navigates to NotificationsCenterScreen)
│   │   ├── notifications_center_screen.dart # Layar Pusat Notifikasi Mandiri (Aktivitas transaksi, status pengingat harian, tanpa kartu persetujuan usang)
│   │   ├── transactions_screen.dart# Riwayat transaksi, pencarian, dan multi-filter
│   │   ├── add_transaction_screen.dart # Form input/edit transaksi (Autofocus nominal, tombol + Kategori langsung & auto-select)
│   │   ├── transaction_success_screen.dart # Layar Penuh Transaksi Berhasil Dicatat (Animasi checklist bergaya Lottie, ringkasan transaksi, aksi cepat)
│   │   ├── budget_screen.dart      # Pengaturan budget bulanan/kategori & progress threshold
│   │   ├── budget_detail_screen.dart # Layar Rincian Anggaran: ringkasan sisa/terpakai, statistik bar chart, riwayat transaksi kategori & opsi kelola budget
│   │   ├── wallets_screen.dart     # Manajemen multi-dompet & transfer antar-dompet
│   │   ├── analytics_screen.dart   # Laporan Keuangan murni dengan AppMonthFilterPill serasi kartu saldo (Donut/Bar toggle & breakdown)
│   │   ├── financial_analysis_screen.dart # Fitur Analisis Keuangan mandiri dengan filter bulan di bawah title (Skor kesehatan, meter, diagnosa cerdas & kurva arus kas)
│   │   ├── split_bill_screen.dart  # Fitur Split Bill pembagian tagihan, pajak/tip, status bayar & catat ke transaksi
│   │   ├── settings_screen.dart    # Layar Profil & Pengaturan (Mode Tampilan 3 opsi: Sistem, Light Mode, Dark Mode via modal sheet)
│   │   ├── display_preferences_screen.dart # Layar Baru Pemilihan Preferensi Tampilan (Complete View, Income/Expense, Expense Only dengan wireframe live preview)
│   │   ├── manage_categories_screen.dart # Layar Kelola Kategori (Daftar kategori Pengeluaran & Pemasukan, navigasi ke form layar baru, modal hapus kartu)
│   │   ├── edit_category_screen.dart # Layar Baru Tambah & Ubah Kategori (Pengembalian CategoryModel instan saat disimpan)
│   │   └── voice_recording_screen.dart # Layar penuh perekam suara anti-slop: spektrum bergerak, live transcript, parsing & routing
│   ├── utils/
│   │   ├── icon_catalog.dart       # Katalog Tabler Icons & 100+ Emoji finansial lokal Indonesia
│   │   └── thousands_separator_formatter.dart # Formatter pemisah ribuan titik (.) real-time & pencegah leading zero
│   └── widgets/
│       ├── bottom_nav_bar.dart     # Fixed bottom nav bar dengan scooped cradle cutout, elevated oceanic (+) button, dan 4 ikon vektor murni tanpa teks
│       ├── semicircle_budget_gauge.dart # Semicircular speedometer gauge 180° untuk monitoring batas budget bulanan (tanggal, sisa anggaran, hari tersisa, sub-card total & terpakai)
│       ├── nested_card.dart        # Reusable Card Inside Card component (outer header + inner slate card)
│       ├── modal_card_sheet.dart   # Reusable Floating Card-Style Modal Bottom Sheet (Card Inside Card pattern)
│       ├── notification_permission_sheet.dart # Modal Bottom Sheet Izin Notifikasi Perangkat (Pengingat harian & pembaca mutasi)
│       ├── weekly_activity_chart.dart # Reusable 7-day dynamic activity bar chart with interactive tooltip
│       ├── spending_calendar_card.dart # Reusable monthly expense tracking calendar grid with compact amounts
│       ├── slide_up_route.dart     # Custom bottom-to-top swipe-up PageRoute transition
│       ├── mesh_card.dart          # Komponen kartu virtual hero
│       ├── transaction_tile.dart   # Baris transaksi dengan badge warna kategori
│       ├── balance_card.dart       # Kartu metrik finansial
│       ├── category_chip.dart      # Chip pemilihan kategori
│       └── receipt_adjustment_sheet.dart # Modal sheet penyesuaian/persetujuan hasil scan OCR struk
├── test/                           # Unit & Widget test suite (155 tests passed)
│   ├── app_improvements_features_test.dart # Test verifikasi 6 fitur peningkatan antarmuka & opsi tema
│   ├── receipt_parser_test.dart    # Test unit mesin ekstraksi & heuristik OCR struk
│   ├── add_transaction_ocr_action_bar_test.dart # Test widget 3-button bottom bar & receipt adjustment sheet
│   ├── month_filter_and_budget_empty_test.dart # Test filter bulanan beranda & empty state budget
│   ├── transactions_filter_unified_test.dart   # Test filter waktu lengkap riwayat transaksi
│   ├── voice_recording_sheet_test.dart         # Test circular spectrum, standby, preview web, simulator & autofill form
│   ├── financial_analysis_ux_test.dart         # Test UX bahasa awam analisis keuangan & panduan bantuan
│   ├── transfer_validation_and_settings_test.dart # Test validasi transfer dompet beda & penyembunyian reset data bawaan di mobile
│   ├── wallet_sync_transaction_test.dart       # Test sinkronisasi transaksi otomatis saat tambah/ubah dompet & toggle ON/OFF
│   ├── supabase_sync_test.dart                 # Test konfigurasi Supabase, graceful fallback, snapshot apply & UI Settings
│   ├── auth_screen_test.dart                   # Test layar autentikasi multi-opsi (daftar email+nama, masuk, guest 100% lokal & error formatting)
│   └── app_update_and_changelog_test.dart      # Test changelog metadata, semver comparison logic, changelog sheet & update dialog UI
├── supabase/
│   ├── config.toml                 # Konfigurasi Supabase project ref njjcviwihzvzjgfbzitg
│   └── migrations/
│       └── 20261113000000_init_yotro_schema.sql # Skema PostgreSQL 5 tabel, index FK, trigger & RLS
├── .agents/skills/                 # Skills agent resmi Supabase (supabase & supabase-postgres-best-practices)
├── design.md                       # Spesifikasi sistem desain & token visual
├── AGENTS.md                       # Aturan wajib agent & auto-sync context.md
├── GEMINI.md                       # Aturan hierarki workspace Gemini / Antigravity
├── pubspec.yaml                    # Dependensi Flutter & aset
└── context.md                      # Dokumen ini (AI handover & context sync)
```

---

## 3. Spesifikasi Fitur & Aturan Bisnis (Business Rules)

### 3.1 Dashboard (Layar Beranda)
- **Header:**
  - Desain bersih minimalis tanpa avatar/foto profil, langsung menampilkan sapaan kontekstual ("Selamat pagi/siang/sore/malam", `11px`, `w500`, `#8EA4BE`).
  - Nama pengguna ("Ian Firdaus 👋") berukuran `16px`, bobot `Medium (FontWeight.w500)` (`Inter Tight`).
  - Tombol notifikasi sirkular `36x36px` (`shape: BoxShape.circle`) di pojok kanan atas, padding atas layar `12px` dan gap ke kartu saldo `14px`.
- **Rhythm & Spasi Antar-Kartu (Compact Fin-tech Density):**
  - Jarak spasi vertikal antar-kartu di beranda dipadatkan menjadi `12px` (`const SizedBox(height: 12)`), menggantikan jarak longgar 20px sebelumnya agar antarmuka beranda padat, kohesif, dan rapi.
- **Hero Sapphire Balance Panel (Card Inside Card Layout):**
  - **Outer Container:** Dark matte slate (`#0C131D`), `borderRadius: 26px`, border `1px rgba(255, 255, 255, 0.08)`, padding super tipis `fromLTRB(5, 5, 5, 10)` menyelubungi kartu dalam tanpa drop-shadow berlebih (zero-slop).
  - **Inner Sapphire Gradient Card:** Mengambang dengan padding tipis `fromLTRB(6, 10, 6, 6)`, sudut membulat penuh (`22px`), border `1px rgba(255, 255, 255, 0.12)`, dan gradien radial presisi: `radial-gradient(95.69% 108.33% at 50% 100%, #041735 0%, #001732 36.06%, #00498C 100%)`.
  - Dropdown pill periode (`September ▼`) di kiri atas, ikon mata toggle di kanan atas (inset 6px).
  - **Kondisi Saldo & Preferensi Tampilan Beranda (`dashboardViewMode`):**
    - **1. Preferensi Tampilan (`DashboardViewMode` — dikontrol dari Profil & Pengaturan > "Preferensi Tampilan"):**
      - `Complete View` (Default): Menampilkan label "Saldo saat ini", display saldo besar (`Rp 132.400`), dan dua sub-pod (Pengeluaran & Pemasukan) di bawahnya.
      - `Pemasukan dan Pengeluaran`: View "Saldo saat ini" di kartu beranda disembunyikan; kartu mengempis ke atas menampilkan dua sub-pod Pengeluaran dan Pemasukan berdampingan.
      - `Pengeluaran saja`: Fokus pada pengeluaran saja; view "Saldo saat ini" dan sub-pod Pemasukan disembunyikan, sub-pod Pengeluaran tampil melebar penuh (*full width*).
    - **2. Masking Nominal Saldo (`isBalanceVisible` — dikontrol murni dari tombol toggle mata di Beranda):**
      - Saat aktif (`true`): Angka nominal tampil riil (`Rp 132.400`, `Rp 320.000`, `Rp 4.000.000`). Ikon mata terbuka `Icons.visibility_outlined`.
      - Saat dinonaktifkan (`false`): Angka nominal disamarkan (`Rp ••••••••` pada saldo utama, `Rp ••••••` pada kartu pengeluaran & pemasukan). Ikon mata tercoret `Icons.visibility_off_outlined`. Fitur ini menjaga privasi nominal tanpa mengubah struktur layout kartu.
  - Dua sub-pod frosted slate di dalam kartu sapphire mepet batas kanan-kiri (margin 6px dari tepi, gap 6px antar-card):
    - Pengeluaran: badge putih dengan minus merah `[-]`, label "Pengeluaran", `- Rp 320.000`.
    - Pemasukan: badge putih dengan plus hijau `[+]`, label "Pemasukan", `+ Rp 4.000.000`.
  - **4 Tombol Aksi Cepat Bawah:** Berada di bagian bawah outer card, dipisahkan oleh garis vertikal pembatas:
    - `Dompet` -> Navigasi ke halaman Dompet (`WalletsScreen.route()`).
    - `Budget` -> Navigasi ke halaman Anggaran (`BudgetScreen.route()`).
    - `Analisis` -> Navigasi ke halaman Analisis Keuangan (`AnalyticsScreen.route()`).
    - `Split Bill` -> Navigasi ke halaman kalkulator pembagian tagihan (`SplitBillScreen.route()`).
- **Transaksi Terbaru (Recent Transactions — NestedCard Layout):**
  - Dibatasi menampilkan **maksimal 3 transaksi terbaru** (`math.min(3, transactions.length)`), menjaga ketinggian layar beranda tetap ringkas dan elegan.
  - Tautan "Lihat semua" di header kartu langsung mengarahkan pengguna ke tab Riwayat Transaksi.
  - Berisi list transaksi terbaru menggunakan komponen terstandarisasi `TransactionTile` dengan avatar Emoji representatif kategori (`categoryModel.buildIconWidget` / `CategoryModel.fallbackEmojiFor`), garis divider tipis (`indent: 68, endIndent: 16`), dan nominal berkode warna.
- **Aktivitas Pengeluaran Mingguan (Functional Activity Bar Chart — WeeklyActivityChart Layout):**
  - Menggunakan komponen `NestedCard`: Outer container dengan judul "Aktivitas Pengeluaran" yang bersih tanpa label/pod berlebih (anti-slop).
  - 7 batang bar aktivitas (`Sen`, `Sel`, `Rab`, `Kam`, `Jum`, `Sab`, `Min`) dengan tinggi dinamis ternormalisasi (10px s/d 122px).
  - Floating tooltip badge interaktif (`AnimatedPositioned`), menampilkan nominal pengeluaran persis pada hari yang diklik/dipilih.
  - Dot indikator cyan khusus untuk hari ini.
- **Kalender Pelacak Pengeluaran (Spending Calendar Card — SpendingCalendarCard Layout):**
  - Menggunakan komponen `NestedCard`: Outer container dengan judul nama bulan (contoh: "November") dan tombol navigasi bulan (`<` dan `>`).
  - Inner card berisi grid 7 kolom yang bersih tanpa background kartu rounded di setiap tanggalnya (mengurangi distraction/visual clutter secara UX).
  - Khusus hari ini (`Today`): Diberi aksen rounded card outline halus (`Border.all(color: Colors.white.withOpacity(0.35), width: 1.2)`), menjadi fokus utama tanpa mengaburkan angka tanggal dan nominal.
  - Menampilkan tanggal dalam bulan dan nominal pengeluaran ringkas (contoh: `13K`, `25K`, `120K`).
  - Klik pada tanggal menampilkan detail pengeluaran hari tersebut di bagian bawah grid.

### 3.2 Transaction Management & Riwayat Transaksi (`TransactionsScreen`)
- **Layar Riwayat Transaksi (`lib/screens/transactions_screen.dart`):**
  - **Top App Bar:** Judul bersih "Riwayat Transaksi" (`20px`, `Inter Tight`, `w600`, putih) tanpa tombol tambah `+ Catat` di header (karena tombol (+) aksi utama telah hadir permanen pada fixed bottom dock). Dilengkapi aksi teks kontekstual `Reset Filter` di kanan atas saat filter sedang aktif.
  - **Search Bar:** Kontainer ramping (`height: 44px`, `#131A26`, border `rgba(255, 255, 255, 0.08)`) dengan ikon search, placeholder Indonesia (`Cari transaksi, nominal, catatan...`), dan tombol clear (`x`) otomatis.
  - **Sistem Multi-Filter 2 Baris Seimbang (Tinggi Nyaman 42px):**
    - Seluruh kontainer filter memiliki tinggi proporsional **`height: 42px`** (memberikan target ketukan yang lega dan sejajar estetis dengan search bar 44px).
    - Wadah bergaya dark slate `#131A26`, `borderRadius: 12px`, border halus `rgba(255, 255, 255, 0.08)`, dan highlight border cyan lembut (`#55C7FF` 35%) saat opsi spesifik aktif.
    - **Baris 1 (Filter Waktu — Bulan & Tanggal):**
      1. **Dropdown Bulan:** Mengambil daftar bulan dinamis (6 bulan terakhir + seluruh bulan dari data transaksi), dengan pilihan `Semua Bulan` atau bulan spesifik (contoh: `November 2026`).
      2. **Picker Tanggal Spesifik:** Tombol berikon kalender untuk memilih tanggal tepat melalui modal `showDatePicker` tema gelap; jika tanggal aktif menampilkan `3 Nov 2026` lengkap dengan tombol silang `✕` untuk reset instan.
    - **Baris 2 (Filter Transaksi — Jenis & Dompet):**
      1. **Dropdown Jenis Transaksi:** Pilihan `Semua Jenis`, `Pengeluaran`, `Pemasukan`, dan `Transfer`.
      2. **Dropdown Dompet:** Pilihan `Semua Dompet` diikuti daftar dompet dinamis dari `provider.wallets`.
  - **State Kosong (Empty State):** Jika tidak ada transaksi yang cocok dengan kombinasi filter, ditampilkan pesan informatif beserta tombol `Reset Semua Filter`.
  - **Daftar Transaksi (`NestedCard`):** Menampilkan daftar transaksi terfilter lengkap dengan jumlah hasil (`action: X transaksi`).
- **Komponen Baris Transaksi Terpadu (`TransactionTile` — `lib/widgets/transaction_tile.dart`):**
  - Format mata uang 100% tersinkronisasi via `provider.formatCurrency(...)` (Rupiah Indonesia, bukan lagi format dolar keras).
  - Tanda dan warna nominal presisi:
    - Pemasukan: `+ Rp 4.000.000` (`#39D98A`).
    - Pengeluaran: `- Rp 25.000` (putih).
    - Transfer: `Rp 50.000` (`#55C7FF`, netral tanpa tanda +/-).
  - Avatar kategori sirkular (`42x42px`, `BoxShape.circle`) dengan warna tint 14% dan ikon vektor kategori geometris murni.
  - Subtitle informatif multi-token: Tanggal & waktu relatif (`Hari ini, 12:00` / `2 Nov, 14:30`) + nama dompet rekening asal (`• BCA`).
  - Tipografi: `Inter Tight` untuk nominal dan `Manrope` untuk judul/keterangan (maksimal `w600`).

- **Form Tambah & Ubah Transaksi (`AddTransactionScreen`):**
  - **Nilai Awal:** Default input nominal adalah `'0'`.
  - **Pencegahan Leading Zero:** Saat diketik atau diedit, angka `'0'` di depan otomatis dihapus/digantikan oleh digit input baru (misal: saat field `'0'`, mengetik `'5'` langsung menghasilkan `'5'`, bukan `'05'`).
  - **Pemisah Ribuan Real-time (`.`):** Nominal diformat secara dinamis dengan titik setiap 3 digit angka (contoh: `5.000`, `100.000`, `2.000.000`) via `ThousandsSeparatorInputFormatter`.
  - **Quick Amount Chips:** Tombol penambahan cepat (`+10rb`, `+20rb`, `+50rb`, `+100rb`) otomatis tersinkronisasi dan diformat dengan pemisah titik ribuan.
  - **Kategori Selector & Modal Bottom Sheet "Lainnya":** Pilihan kategori di form transaksi diatur secara ketat **maksimal 2 baris horizontal** (menggunakan `Row` horizontal terukur, bukan `Wrap` bebas yang dapat melompat ke 3 baris) dengan tombol pill `Lainnya` di baris kedua. Mengetuk `Lainnya` membuka **Full-Width Modal Bottom Sheet** (edge-to-edge) yang menampilkan sisa kategori dalam format **2 kolom simetris scrollable ke bawah**, lengkap dengan emoji, nama kategori, dan tanda centang aktif. Tombol teks redundant `Semua >` di atas form telah dihapus.
  - **Kursor Presisi:** Posisi kursor teks dinamis dan akurat menyesuaikan penambahan/pengurangan titik pemisah tanpa meloncat.

### 3.3 Category Management (Seluruh Kategori Menggunakan Emoji)
- **Kategori Default Expense:** Food & Beverage (🍔), Transportation (🚗), Shopping (🛍️), Housing (🏠), Bills & Utilities (⚡), Health (💊), Entertainment (🎮), Education (📚), Lifestyle (✨), Others (📦).
- **Kategori Default Income:** Salary (💰), Freelance (💻), Business (🏢), Investment (📈), Gift (🎁), Others (🧧).
- **Aturan & Standar Ikon Kategori:**
  - **Khusus kategori:** Seluruh ikon kategori wajib menggunakan **Emoji** representatif.
  - Setiap kategori tersimpan memiliki nilai `emoji` eksplisit atau fallback emoji otomatis dari nama kategori (`CategoryModel.fallbackEmojiFor`).
  - Form Tambah & Ubah Kategori (`EditCategoryScreen`) didedikasikan murni untuk pemilihan Emoji: pencarian emoji, grid emoji populer terkurasi, dan text field input emoji kustom via keyboard sistem.
- **Scroll Reset Invariant:**
  - Setiap kali pengguna berpindah antar-tab di `MainShell` atau kembali dari layar sub-menu (seperti `AddTransactionScreen` atau `ManageCategoriesScreen`), posisi scroll layar sebelumnya otomatis di-reset ulang ke paling atas (`0.0`).
- **Modal Bottom Sheet Full-Width Invariant:**
  - Seluruh modal bottom sheet (`modal_card_sheet.dart`) dibuat **Full Width edge-to-edge** tanpa margin horizontal kanan-kiri ke layar ponsel, ber-radius sudut atas `24px`, inner card margin `8px`, dan padding aman untuk keyboard/insets.

### 3.4 Budgeting & Rincian Anggaran Interaktif (Tanpa Data Statis)
- **Anggaran Global & Per Kategori:**
  - Kartu batas pengeluaran bulanan global dan anggaran spesifik per kategori menggunakan linear progress bar bersih dan teruji (tanpa rentang tanggal atau sisa hari statis).
  - Ambang batas visual: aman (< 80%), waspada amber (80-99%), dan bahaya merah (≥ 100%).
  - Perhitungan 100% dinamis terhubung langsung ke `TransactionProvider.totalExpense` dan akumulasi transaksi pengeluaran kategori yang dinormalisasi (`CategoryModel.normalizeCategoryName`).
- **Layar Rincian Anggaran (`BudgetDetailScreen`):**
  - Mengetuk kartu budget keseluruhan atau budget kategori membuka `BudgetDetailScreen`.
  - **Kartu Ringkasan:** Avatar kategori dengan badge panah merah, nama kategori/semua pengeluaran, batas nominal, dan status dinamis `Terpakai : Rp xxx` serta `Sisa : Rp xxx`.
  - **Statistik Penggunaan Anggaran (Interactive Bar Chart):**
    - Grafik batang vertikal harian dengan warna merah/koral (`#EF4444` / `#FF5252`).
    - Skala sumbu Y bertingkat otomatis dengan angka bersih (`_calculateNiceScaleMax`: 50K, 100K, 250K, 500K, 1M, dst.) dan garis bantu horizontal putus-putus (*dashed lines*).
    - Header metrik dinamis: Saat unselected menampilkan `Rata-rata: Rp xxx/hari` dan `Puncak: Rp xxx`. Saat batang diketuk, menampilkan pill detail tanggal lengkap dan nominal harian.
    - Mengetuk batang tanggal tertentu memfilter daftar "Riwayat Transaksi" di bawahnya secara reaktif untuk hanya menampilkan transaksi pada tanggal tersebut, lengkap dengan tombol "Lihat Semua" untuk mereset filter.
    - Empty state informatif dengan tombol "+ Catat Transaksi" yang otomatis mengisi kategori terkait pada form pencatatan.
  - **Menu Aksi Cepat:** Titik tiga (`...`) di pojok kanan atas untuk mengubah limit budget atau menghapus budget kategori dengan modal konfirmasi aman.

### 3.5 Wallet Management (`lib/screens/wallets_screen.dart` & `lib/providers/transaction_provider.dart`)
- Tipe default: Bank Account, Cash, E-Wallet, Savings, Other.
- Fitur: Multi-wallet dengan saldo terpisah, mutasi transfer antar-dompet, riwayat per dompet.
- **Sinkronisasi Otomatis Transaksi dari Penambahan & Pengeditan Dompet:**
  - **Penambahan Dompet Baru:** Jika dompet dibuat dengan saldo awal > 0, otomatis mencatat transaksi pemasukan (`TransactionType.income`) berjudul `Saldo Awal - [Nama Dompet]` dengan kategori `Lainnya` (`other_inc`) dan nominal sesuai saldo awal. Saldo dompet terisi otomatis via `addTransaction` tanpa risiko *double counting*.
  - **Pengeditan Saldo Dompet:** Saat saldo dompet diubah dari $S_{lama}$ ke $S_{baru}$ (selisih $\Delta = S_{baru} - S_{lama}$):
    - Jika $\Delta > 0$ (saldo bertambah): Otomatis mencatat transaksi pemasukan (`TransactionType.income`) berjudul `Penyesuaian Saldo - [Nama Dompet]` nominal $\Delta$.
    - Jika $\Delta < 0$ (saldo berkurang): Otomatis mencatat transaksi pengeluaran (`TransactionType.expense`) berjudul `Penyesuaian Saldo - [Nama Dompet]` nominal $|\Delta|$.
    - Jika $\Delta == 0$: Tidak ada transaksi yang dicatat (hanya nama/tipe dompet yang diperbarui).
  - **Dua Tingkat Kendali Toggle ON/OFF:**
    1. **Toggle Global di Halaman Dompet:** Kartu `NestedCard` ("Otomatisasi Transaksi") dengan switch "Sinkronkan ke Transaksi" yang tersimpan persisten ke `SharedPreferences` (`syncWalletToTransactions`, default `true`).
    2. **Toggle Lokal di Modal Sheet:** Switch interaktif di dalam modal bottom sheet tambah/ubah dompet ("Catat ke Transaksi") memungkinkan pengguna mengaktifkan/menonaktifkan sinkronisasi transaksi per-aksi secara instan.
  - **Onboarding Aman:** Penambahan dompet saat pertama kali pengguna menyelesaikan onboarding profil diatur `syncToTransaction: false` agar tidak mengotori riwayat transaksi perdana pengguna.

### 3.6 Reports & Analytics (Layar Laporan / Report Screen Redesign)
- **Rhythm & Spasi Antar-Kartu (Universal 12px Spacing):**
  - Jarak spasi vertikal antar-kartu di Layar Laporan disamakan dengan Beranda menjadi `12px` (`const SizedBox(height: 12)`) antara Segmented Pill, Hero Report Card, dan Rincian Kategori.
- **Default View Mode:** Saat layar Laporan pertama kali dibuka, visualisasi default adalah **Donut Chart** (`ChartViewMode.donut`), dengan tombol toggle cepat untuk beralih ke Bar Chart.
- **Top App Bar (Anti-Slop):**
  - Judul `Laporan Keuangan` (20px, `w600`, Inter Tight) di kiri tanpa tombol back (karena merupakan tab root bottom dock, bukan subpage).
  - Pill dropdown pemilih bulan (contoh: "November 2026 ∨") di kanan atas dengan modal bottom-sheet pemilih bulan.
- **Segmented Control Tipe Transaksi:**
  - Kapsul pill konsisten bahasa: `Pengeluaran` (aktif: putih solid, teks hitam) vs `Pemasukan` (transparan, teks slate).
- **Hero Report Card (Aktivitas Pengeluaran / Aktivitas Pemasukan — `NestedCard`):**
  - Header kartu: Judul "Aktivitas Pengeluaran" di sisi kiri dan Switch Pill pemilih grafik di pojok kanan (*space-between*).
  - **Switch Pill (Sesuai Referensi UI):**
    - Kapsul pill rounded (`#16202D`, border 1px) dengan tombol lingkaran sapphire `#2F91E4`–`#1368B5` (anti-slop, konsisten palet fin-tech) yang bergeser secara halus (*animated sliding thumb*).
    - Ikon Bar Chart (`Icons.bar_chart_rounded`) di kiri dan Ikon Pie Chart (`Icons.pie_chart_rounded`) di kanan.
    - Ikon aktif berwarna putih solid di dalam lingkaran sapphire; ikon inaktif berwarna abu-abu `#7F91A7`.
  - **Mode Bar Chart (Tampilan Default):**
    - Menampilkan grafik batang aktivitas mingguan `WeeklyActivityChart` secara langsung tanpa pembungkus nested card ganda.
    - **Paginator Filter per-Minggu (Clean Minimalist & Taller Bars):**
      - Terintegrasi langsung dengan dropdown bulan terpilih (`selectedMonth: _selectedMonth`).
      - Membagi bulan terpilih ke dalam rangkaian minggu kalender Senin–Minggu (contoh: *Minggu 1 (26 Okt – 1 Nov)*, *Minggu 2 (2 – 8 Nov)*, dst.).
      - **Posisi Lebih Naik & Tanpa Badge Pill:** Desain unboxed murni tanpa kontainer badge/pill tebal di sekelilingnya, ditaruh lebih dekat ke atas judul kartu (`padding: 12px 14px 16px`) sehingga antarmuka tetap bersih dan luas.
      - Navigator bar minimalis: Ikon chevron `<` dan `>` serta teks detail `Minggu 2 (2 – 8 Nov)` berbobot `w600` warna `#8CA7C5`.
      - **Ketinggian Grafik Lebih Tinggi:** Tinggi canvas area bar chart dinaikkan dari `165px` menjadi **`195px`**, dan rentang tinggi batang dinaikkan dari `96px` ke **`122px`** (30% lebih tinggi dan jelas terbaca).
      - Mendukung gestur usap horizontal (*swipe left/right drag*) untuk berganti minggu secara instan.
      - Batang 7 hari (Sen–Min) memetakan transaksi khusus pada minggu terpilih secara terisolasi (tidak diakumulasi antar-minggu).
      - Default minggu otomatis mengarah ke minggu yang mencakup tanggal hari ini (*today*).
  - **Mode Donut Chart (True Annular Rounded Wedge):**
    - Dibangun menggunakan custom painter `_DonutChartPainter` dengan geometri irisan cincin analitik presisi (kanvas 250x250, padding vertikal kartu 22px):
      - Cincin kokoh dan proporsional sesuai referensi visual: busur lingkaran luar ($R_o=112\text{px}$) dan busur lingkaran dalam ($R_i=68\text{px}$), menghasilkan ketebalan cincin $44\text{px}$ dan rasio lubang $60.7\%$.
      - Sisi radial terpotong datar menuju titik pusat dengan celah sudut seragam (`3.5°` / `0.06 rad`).
      - Ke-4 sudut pada setiap irisan segmen diberi fillet membulat analitik sejati (`cornerRadius: 6.0px`) dengan tangensi lingkaran sempurna ($s^2 + r_c^2 = (R \pm r_c)^2$) sehingga sudut melengkung halus tanpa distorsi atau pinching.
      - Format angka nominal ringkas di tengah donut:
        - Nominal ribuan hingga ratusan ribu ditampilkan dengan format `k` (contoh: `101k`, `320k`).
        - Nominal jutaan ditampilkan dengan format `jt` dan pemisah desimal koma (contoh: `3,4 jt`, `4 jt`).
        - Nominal miliaran ditampilkan dengan format `M` (contoh: `1,5 M`).
      - Ruang informasi tengah lapang (`width: 126px`): Label `Total Pengeluaran` (`11px`) dan nominal display besar (`26px`, Inter Tight `w600`) berada rapi di dalam lubang diameter 136px.
      - Interaktivitas segmen: Segmen aktif bergeser 3.5px keluar (*radial outward push*) dengan penebalan halus.
      - Interaksi ketukan langsung: Memiliki *direct hit-testing* (`GestureDetector.onTapDown`) pada radius cincin 62..118px sehingga pengguna dapat mengetuk irisan cincin mana pun secara langsung untuk menyorotnya.
    - Palet warna kategori presisi 100% selaras referensi: Biru (`#007AFF`), Hijau (`#34C759`), Oranye (`#FF9500`), Ungu (`#AF52DE`), Merah (`#FF3B30`), Biru Langit (`#55C7FF`), Amber (`#FFC857`), dan Slate (`#8CA7C5`).
    - Tooltip mengambang dinamis (`_buildFloatingBadge`, radius 90px) berposisi presisi di atas irisan aktif cincin menampilkan persentase (`31%`).
- **Daftar Kategori ("Rincian Pengeluaran" / "Rincian Pemasukan" — `NestedCard`):**
  - Mengikuti pola universal `NestedCard`: Header judul di kiri dan total nominal di kanan (`action: Total ...`).
  - Baris kategori bergaya rapi dengan divider halus:
    - Ikon kategori sirkular dalam wadah warna senada, nama kategori, persentase share (`31.2% dari total`), nominal terformat, dan jumlah transaksi riil (`3 transaksi`).
    - Warna ikon dan progress bar 100% selaras dengan warna segmen irisan pada donut chart (`_chartPalette`).
    - Interaktif: Mengetuk kartu kategori akan menyorot segmen pada donut chart di atas.
  - **Pemisahan Laporan dan Analisis:** Tab Laporan Keuangan pada bottom navigation bar murni menampilkan aktivitas laporan (grafik donut/bar chart, switcher pengeluaran/pemasukan, dan rincian breakdown kategori) tanpa kartu skor kesehatan finansial.

### 3.7 Fitur Analisis Keuangan Mandiri (`FinancialAnalysisScreen` — `lib/screens/financial_analysis_screen.dart`)
- **Akses Navigasi:** Diakses langsung dari tombol Aksi Cepat ke-3 di Beranda ("Analisis", ikon `Icons.pie_chart_outline_rounded`) dan tombol detail chart Beranda.
- **Tampilan Modal Bottom Sheet Setinggi Layar:** Dibuka sebagai bottom sheet modal penuh (~94% tinggi layar via `FinancialAnalysisScreen.showAsModalSheet(context)`) dengan drag handle di atas, pill pemilih periode bulan, dan tombol tutup silang (`Icons.close_rounded`) yang mudah diakses.
- **Fitur Analisis Kesehatan Keuangan (`_buildFinancialHealthCard` — `NestedCard`):**
  - **Health Score (0-100) & Status Badge:** Menilai kesehatan finansial pengguna dari rasio tabungan (bobot 45%), kepatuhan anggaran (bobot 35%), dan diversifikasi pengeluaran (bobot 20%). Status: `Sangat Sehat` (`#39D98A`), `Sehat & Stabil` (`#55C7FF`), `Perlu Waspada` (`#FFC857`), atau `Kritis / Defisit` (`#FF6B7A`).
  - **Visual Health Meter Bar:** Bar meter kemajuan skor finansial dengan rentang indikator Kritis, Waspada, dan Sehat.
  - **3 Mini Metric Pods:**
    1. *Tabungan:* Rasio tabungan real-time terhadap pemasukan (target >20%).
    2. *Rasio Beban:* Persentase pengeluaran terhadap pemasukan (ambang aman <70%).
    3. *Arus Kas:* Nominal surplus atau defisit bersih bulan berjalan (`_formatCompactAmount`).
  - **Smart Diagnostic Insight Box:** Ringkasan diagnosa tajam anti-slop yang menyoroti surplus/defisit riil dan kategori belanja dominan.
- **Fitur Statistik & Arus Kas (`_buildCashFlowStatsCard` — `NestedCard`):**
  - **Daily Burn Rate (Rata-rata Harian):** Laju konsumsi pengeluaran harian berdasarkan hari yang telah berlalu di bulan terpilih.
  - **Proyeksi Akhir Bulan (Projected Month-End Spend):** Estimasi total pengeluaran jika pola belanja berlanjut stabil hingga hari terakhir bulan.
  - **Mini Chart Bar Rasio Pemasukan vs Pengeluaran:** Visual bar proporsional horizontal (hijau vs cyan) dengan nominal terformat.
  - **Fokus Beban Terbesar (Top Spending Spotlight):** Menampilkan kategori belanja nomor 1 beserta ikon vektor bersih (`CategoryModel.icon`), nama, nominal, dan persentasenya terhadap total pengeluaran (zero decorative emojis).

### 3.8 Aktivitas Transaksi Dual Bar Chart di Beranda (`WeeklyActivityChart` — `lib/widgets/weekly_activity_chart.dart`)
- **Pengganti Aktivitas Pengeluaran:** Kartu Beranda "Aktivitas Pengeluaran" diperbarui menjadi "Aktivitas Transaksi" dengan chart batang berdampingan (*side-by-side grouped bar chart*).
- **Dual Bar Berdampingan per Hari (Sen–Min):**
  - Bar Kiri: **Pemasukan** berwarna hijau emerald (`#34D399`, unselected `#104A3A`).
  - Bar Kanan: **Pengeluaran** berwarna koral merah (`#FF6B7A`, unselected `#4A1E26`).
  - Lebar bar 11.5px per batang dengan celah 2px, radius atas melengkung 5px.
- **Legend Vektor di Header:** Menampilkan indikator titik hijau ("Masuk") dan merah ("Keluar") di pojok kanan kartu `NestedCard`.
- **Tooltip Mengambang Interaktif:** Menampilkan detail nominal Pemasukan (`+Rp ...`) dan Pengeluaran (`-Rp ...`) untuk hari yang dipilih dengan proteksi teks responsif bebas overflow RenderFlex.
- **Sembunyikan Otomatis Saat Kosong (*Empty State*):** Jika tidak ada transaksi sama sekali pada minggu aktif, kartu Aktivitas Transaksi disembunyikan sepenuhnya dari Beranda (`SizedBox.shrink()`).

### 3.9 Cadangan & Pemulihan Data Offline Nyata (`BackupStorageService` & `SettingsScreen`)
- **Ekspor Cadangan (Backup JSON):**
  - Menampilkan **bottom sheet konfirmasi** terlebih dahulu yang merinci total transaksi, dompet, dan kategori yang akan dicadangkan.
  - Mengunduh berkas `.json` nyata (`yotro_backup_YYYYMMDD_HHMM.json`) ke penyimpanan perangkat (browser download pada Web, system share sheet pada Android/iOS), serta menyediakan opsi salin teks ke clipboard.
- **Pulihkan Data (Restore JSON):**
  - Mendukung **unggah / pilih berkas `.json`** langsung dari penyimpanan perangkat via `FilePicker` di samping opsi tempel teks JSON.
  - Validasi otomatis struktur JSON cadangan (`validateBackupJson`) dengan banner verifikasi hijau.
  - Pilihan strategi pemulihan: `Merge Data` (menggabungkan data) atau `Replace Data` (menimpa penuh).

### 3.10 Pengingat Transaksi Harian Multi-Alarm (`SettingsScreen`)
- **Pengaturan via Bottom Sheet:** Baris Profil & Pengaturan tidak lagi menampilkan tombol waktu inline, melainkan membuka modal bottom sheet `_showDailyReminderSheet`.
- **Dukungan Multi-Alarm:** Pengguna dapat menyetel beberapa alarm pengingat sekaligus (default: `18:00` dan `19:00`), menambah jam baru via `TimePicker`, dan menghapus alarm yang tidak diinginkan.
- **Tersimpan di State & Notifikasi Terjadwal:** Tersimpan ke `provider.dailyReminderTimes` dan dijadwalkan dengan `AndroidScheduleMode.inexactAllowWhileIdle`, tanpa izin exact alarm berisiko tinggi.

### 3.11 Preferensi Tampilan Beranda & Mode Pengeluaran Saja
- **Mode Pengeluaran Saja (`DashboardViewMode.expenseOnly`):**
  - Nominal display utama pada kartu hero di Beranda otomatis menampilkan **"Total Pengeluaran"** dengan angka `provider.totalExpense` (menggantikan "Saldo saat ini").
  - Sub-kartu pemasukan dan pengeluaran di bawahnya tidak ditampilkan (rapi langsung tersambung ke 4 tombol aksi cepat).
- **Tombol Simpan Wajib:** Pemilihan opsi tampilan di modal bottom sheet preferensi tampilan tidak langsung berganti, melainkan memerlukan klik tombol **"Simpan Preferensi"** untuk menerapkan perubahan.

### 3.12 Pembaca Notifikasi Cerdas & Edit Aturan (`NotificationReaderScreen`)
- **Deteksi Cerdas Arah Transaksi:** Menganalisis teks notifikasi untuk mendeteksi `TransactionType.income` (pemasukan/saldo masuk/transfer masuk), `TransactionType.transfer` (transfer keluar), atau `TransactionType.expense` (pengeluaran/QRIS/pembayaran).
- **Edit Aturan Pemicu & Filter Abaikan:** Pengguna dapat mengedit nama aturan, package name manual, kata kunci pemicu/abaikan, dompet tujuan, dan kategori default. Pemindaian semua aplikasi terpasang dihapus agar tidak memerlukan `QUERY_ALL_PACKAGES` / `REQUEST_DELETE_PACKAGES`.
- **Pusat Notifikasi (`NotificationsCenterScreen`):** Spacing universal 12px, header terstandarisasi, badge arah mutasi berwarna (Hijau Masuk, Merah Keluar, Cyan Transfer), dan feedback berbasis `AppSnackBar`.

### 3.13 Fitur Advanced Split Bill (`SplitBillScreen` — `lib/screens/split_bill_screen.dart`)
- **Tujuan:** Kalkulator pembagi tagihan bersama multi-mode (Bagi Rata, Bagi Kustom, dan Per Item) yang terintegrasi langsung dengan pencatatan transaksi aplikasi.
- **3 Mode Pembagian Fleksibel:**
  1. **Bagi Rata (Equal Split):** Total tagihan (subtotal + pajak + service) dibagi sama rata ke seluruh anggota tagihan.
  2. **Bagi Kustom (Custom Split):** Pengguna dapat memasukkan alokasi nominal manual per orang (`customAmount`), dilengkapi visual bar alokasi total serta tombol otomatis *"Bagi Sisa Rata"* untuk mendistribusikan sisa tagihan yang belum teralokasi.
  3. **Bagi Per Item (Itemized Split):** Pengguna dapat memasukkan daftar menu/item pesanan (nama, harga satuan, quantity, dan memilih anggota yang memesan/makan bersama). Subtotal dihitung otomatis dari total item, dan pajak serta service tip didistribusikan secara proporsional (*pro-rata*) berdasarkan nilai pesanan masing-masing orang.
- **Pajak & Service Tip Fleksibel (Toggleable & Custom):**
  - **Pajak:** Switch master on/off. Saat aktif, mendukung preset chip (`10%`, `11%`, `12%`) serta tombol `Kustom...` yang membuka modal sheet untuk mengatur nilai persentase kustom atau nominal tetap (Rp).
  - **Service / Tip:** Switch master on/off. Saat aktif, mendukung preset chip (`5%`, `10%`) serta opsi `Kustom...` (persentase kustom atau nominal tetap Rp).
- **Daftar Anggota Tagihan (`NestedCard`):**
  - Default 3 orang (`Kamu`, `Teman 1`, `Teman 2`) dengan opsi tambah, edit nama via modal sheet, hapus (jika > 2 orang), dan status pembayaran `Lunas` / `Belum`.
- **Standardisasi Desain Tombol (Universal Consistency):**
  - Tombol aksi utama diseragamkan dengan seluruh aplikasi: `ElevatedButton.icon` sapphire `#02539A`, tinggi `48px`, border radius `14px`, teks putih `w600`.
  - Tombol salin ringkasan menggunakan tombol ikon ringkas (`OutlinedButton`, 48x48px, `Icons.copy_rounded`, radius `14px`) yang berdampingan rapi dengan tombol utama "Catat Bagian Saya" tanpa memicu pemotongan atau baris baru (*anti-wrapping*).
  - Tombol modal simpan item & edit nama menggunakan tombol elevated standar `44px` beradius `12px`.

### 3.14 Filter Bulanan Interaktif di Beranda & Empty State Anggaran
- **Filter Bulanan di Beranda (`_buildMonthFilterPill` & `_showMonthFilterSheet` — `lib/screens/dashboard_screen.dart`):**
  - Menggantikan dropdown periode statis dengan filter pill bulan interaktif (`Nov 2026 ∨`) di kartu hero Beranda.
  - Membuka modal bottom sheet "Filter Bulanan" dengan kartu grid 12 bulan (4 kolom x 3 baris) dalam singkatan bahasa Indonesia (`Jan`–`Des`).
  - Bulan terpilih disorot dengan kapsul biru sapphire solid (`#2563EB`) dan teks putih.
  - Pemilih tahun di bagian atas kartu dilengkapi tombol navigasi chevron `<` dan `>`.
  - Tombol aksi kanan bawah berbentuk kapsul rounded (*stadium*): `Batal` (outlined) dan `Kirim` (elevated `#02539A`), yang menerapkan bulan terpilih ke `provider.setSelectedDashboardMonth`.
  - Kartu hero Beranda dan sub-kartu pengeluaran/pemasukan menampilkan arus kas khusus pada bulan yang difilter (`dashboardMonthExpense` & `dashboardMonthIncome`).
- **Empty State Anggaran (`lib/screens/budget_screen.dart`):**
  - Jika batas anggaran keseluruhan belum disetup (`overallMonthlyLimit <= 0`), kartu "Batas Budget Keseluruhan" tidak ditampilkan.
  - Jika belum ada budget keseluruhan maupun kategori, layar menampilkan kartu *Empty State* yang ramah pengguna dengan tombol aksi langsung: *"Atur Anggaran Bulanan"* dan *"Tambah Budget Kategori"*.

### 3.15 Desain Sistem & Audit Kontras Mode Terang (Light Mode WCAG)
- **Penghapusan Tulisan Offline di Profil:** Tulisan `'100% Offline & Privat'` di bawah nama akun telah dihilangkan agar profil terlihat lebih bersih.
- **Kepatuhan Kontras Light Mode:** Seluruh kotak peringatan bahaya/peringatan diatur kontrasnya (amber tua `#92400E` pada latar `#FEF3C7` dan merah tua `#991B1B` pada latar `#FEE2E2`).
- **Visibilitas Tombol:** Tombol *Batalkan* pada seluruh modal konfirmasi (`SettingsScreen`, `ManageCategoriesScreen`, `WalletsScreen`, `BudgetDetailScreen`) menggunakan `foregroundColor` dan `borderSide` adaptif tema sehingga terlihat jelas pada light mode.

### 3.9 Fixed Bottom Navigation Bar dengan Scooped Cradle Cutout (`lib/widgets/bottom_nav_bar.dart`)
- **Struktur Bar & Kanvas Ergonomis:**
  - Bar navigasi edge-to-edge dengan kanvas berlatar `#0F141A` dan border garis tipis `rgba(255, 255, 255, 0.08)`.
  - Bahu atas memiliki sudut membulat halus (`topCornerRadius: 26.0px`).
  - **Scooped Cradle Cutout (Lekukan Notch):** Busur sirkular matematis dengan transisi quadratic Bezier (`notchRadius: 33.0px`, `s1: 15.0px`) membungkus tombol floating (+) dengan celah seragam ~7px.
  - Dasar cradle menyatu sejajar horizontal dengan pusat vertikal 4 ikon navigasi.
  - **Ketinggian Ergonomis:** Ketinggian bar konten disesuaikan ke `60px` dengan `barTop: 28px` dan `bottomInset: 12px`, total tinggi `100px` pada web runner/desktop.
- **Distribusi 5 Slot Seimbang (100% Uniform & Symmetrical Icon Spacing):**
  - Menggunakan 5 kolom `Expanded` dengan bobot setara (`0.2 * W` per interval) yang menjamin jarak antar-ikon (Slot 0 ke Slot 1) tepat identik dengan jarak ikon ke tombol tengah (Slot 1 ke Slot 2 FAB), dan simetris di sisi kanan (Slot 2 FAB ke Slot 3, dan Slot 3 ke Slot 4).
  - Slot 0 (Beranda): `Icons.grid_view_rounded` (2x2 rounded squircles).
  - Slot 1 (Riwayat Transaksi): `Icons.description_rounded` (dokumen berlipat).
  - Slot 2 (Tengah): Slot kosong untuk lekukan cradle & floating FAB.
  - Slot 3 (Laporan Keuangan): `Icons.pie_chart_rounded` (diagram pie solid terpotong).
  - Slot 4 (Profil & Pengaturan): `Icons.person_rounded` (avatar pengguna).
  - Ukuran ikon `26px`, touch target lega & ergonomis `52x48px`, warna aktif putih `#FFFFFF`, inaktif slate sejuk `Color(0xFF72849A)`.
- **Tombol Tambah Tengah (Elevated Oceanic Sapphire FAB):**
  - Diameter proporsional 52px, melayang di atas lekukan cradle (`top: barTop - 2.5 - 26.0`).
  - Gradien sapphire oceanic: `#02539A` ke `#01417A` dengan shadow halus `#014786`.
  - Ikon plus putih tebal `Icons.add_rounded`, `size: 29px`.
- **Home Indicator Bar:**
  - Kapsul tipis iOS Home Bar (`132x4px`, putih 38%) di dasar layar (`bottom: 5px`) pada platform web/desktop.

### 3.9 Profil Pengguna & Pengaturan Sistem (`lib/screens/settings_screen.dart`)
- **Struktur & Pola Kartu (`NestedCard` Universal):**
  - Menerapkan pola konsisten Card Inside Card (outer dark slate `#0C131D` + inner `#131A26` dengan border `rgba(255, 255, 255, 0.08)`).
  - **Padding Inside Card Kompak:** Padding konten di dalam inside card dipadatkan menjadi `EdgeInsets.symmetric(horizontal: 10, vertical: 8)` pada baris pengaturan, divider 10px, dan innerPadding kartu profil/tentang 10px agar isi kartu tidak terlalu lebar dan lebih ramping.
- **1. Profil Pengguna (Hero Profile Card):**
  - Avatar lingkaran monogram inisial nama (`52x52px`, gradien oceanic sapphire `#02539A`–`#01417A`).
  - Nama akun terhubung ke `provider.userName` (default: "Ian Firdaus").
  - Tombol aksi `Ubah Nama >` membuka dialog untuk mengedit nama secara instan dan memperbarui greeting di Beranda.
  - 3 Metrik Finansial Ringkas: Jumlah catatan transaksi, jumlah dompet aktif, dan total pengeluaran bulan berjalan.
- **2. Preferensi Finansial:**
  - **Mata Uang Acuan:** Dropdown IDR (Rp) vs USD ($) tersinkron ke `provider.setCurrency` (tampilan ringkas title-only).
  - **Preferensi Tampilan (3 Mode):** Menggantikan switch lama dengan bottom sheet pilihan (`showModalCardSheet`) yang memiliki 3 mode: Complete View, Pemasukan dan Pengeluaran, dan Pengeluaran saja.
- **3. Sinkronisasi Cloud (Private Cloud Sync & Keamanan Akun):**
  - Menampilkan status koneksi ("Mode Offline (Lokal)" vs "Terhubung sebagai [email]" / "Akun Cloud Terhubung").
  - Bebas dari ekspos kredensial teknis: Tombol dan modal sheet kredensial Supabase dihilangkan agar antarmuka privat dan tidak membingungkan pengguna awam. Kredensial telah tertanam aman di `SupabaseConfig`.
  - Tombol aksi utama "Masuk / Hubungkan Akun" dan "Masuk dengan Google".
  - **Keamanan Akun (Hanya tampil saat Terhubung Cloud):**
    - **Ganti Kata Sandi:** Dialog modal bergaya Card-Inside-Card (`_showChangePasswordSheet`) untuk memasukkan kata sandi baru dan konfirmasi kata sandi, yang memvalidasi minimal 6 karakter dan kesesuaian sandi sebelum memanggil `SupabaseAuthService.updatePassword`.
    - **Lupa Kata Sandi:** Dialog modal (`_showForgotPasswordSheet`) untuk mengirimkan tautan pemulihan sandi langsung ke email akun cloud yang sedang aktif melalui `SupabaseAuthService.resetPassword`.
    - **Mode Offline Bersih:** Saat dalam mode tamu/offline, sub-bagian Keamanan Akun tidak ditampilkan karena data tersimpan lokal tanpa kata sandi.
  - Saat terhubung: Tombol "Sinkronkan Sekarang" dan opsi "Keluar dari Akun Cloud".
- **4. Cadangan & Pemulihan Data (Offline JSON — Modal Bottom Sheet):**
  - **Ekspor Cadangan:** Menampilkan preview string format snapshot JSON lengkap dan tombol `Salin JSON ke Clipboard` dalam bottom sheet modal.
  - **Pulihkan Data (Restore):** Validasi format JSON otomatis (`validateBackupJson`), menampilkan ringkasan transaksi & dompet yang terdeteksi, serta dua pilihan aksi pemulihan aman: `Merge Data` (menggabungkan tanpa duplikasi ID) atau `Replace Data` (menimpa seluruh database) dalam bottom sheet modal.
- **5. Zona Bahaya (Danger Zone — Modal Bottom Sheet):**
  - **Kosongkan Riwayat Transaksi:** Bottom sheet konfirmasi merah untuk menghapus seluruh riwayat mutasi dan menolkan saldo rekening.
  - **Hapus Akun Pengguna:** Modal konfirmasi destruktif permanen bertajuk **"Hapus Akun Yotro?"** dan peringatan bahwa **"Akun Yotro Anda"** beserta seluruh data akan dihapus secara total. Menghapus akun di database cloud via RPC dan membersihkan memori lokal sebelum diarahkan kembali ke Onboarding.
  - **Reset ke Data Bawaan (Factory Seed):** Menyetel nama default pengguna menjadi **"John Doe"** dan memuat 17 transaksi realistis lintas 4 dompet dan 5 kategori anggaran.
- **6. Tentang Aplikasi:**
  - Header kartu bersih berlabel "Tentang Aplikasi".
  - Menampilkan logo Yotro, nama aplikasi "Yotro", dan label versi dinamis dari `ChangelogData.currentVersion`.
  - Baris teknis redundan (Database, Privasi, Lisensi) telah dibersihkan secara total.
  - Pada platform web: Dilengkapi tombol unduh APK Android dengan label versi dinamis dari `ChangelogData.currentVersion`.

### 3.10 Sub-Menu Kelola Kategori (`lib/screens/manage_categories_screen.dart`)
- **Akses Navigasi:** Berada di dalam layar Pengaturan under "Preferensi Finansial" > baris "Kelola Kategori" (`Icons.category_outlined`).
- **Segmented Tabs Dua Tipe:**
  - Tab Pengeluaran (dengan jumlah kategori aktif, contoh `10`).
  - Tab Pemasukan (dengan jumlah kategori aktif, contoh `6`).
- **List Kategori (`NestedCard`):**
  - Kotak ikon kategori 42x42px ber-tint warna aksen kategori (16% opacity) dan border halus. Mendukung rendering Tabler Icons (`IconData`) maupun Emoji teks (`Text`).
  - Nama kategori, badge jenis (`Bawaan` vs `Kustom`), dan label sumber bersih: **`Icon`** (vektor) atau **`Emoji`** (tanpa embel-embel "Tabler/Icon").
  - Tombol aksi Ubah (`Icons.edit_outlined`) dan Hapus (`Icons.delete_outline_rounded`, merah).
  - Tapping tombol "Tambah" di AppBar atau tombol "Ubah" pada kartu kategori menavigasi ke layar mandiri **`EditCategoryScreen`** (New Page).
- **Integritas Penghapusan (Safe Delete with Reassignment):**
  - Bottom sheet konfirmasi bergaya floating card (`modal_card_sheet.dart`) sebelum eksekusi hapus.
  - Transaksi yang menggunakan kategori yang dihapus otomatis dialihkan (*reassigned*) ke kategori fallback `Others / Lainnya` dengan tipe yang bersesuaian, sehingga total saldo dan riwayat transaksi tidak rusak.

### 3.11 Layar Baru Tambah & Ubah Kategori (`lib/screens/edit_category_screen.dart`)
- **Arsitektur Halaman Mandiri (New Page):**
  - Menggantikan modal bottom sheet sebelumnya menjadi halaman penuh (`MaterialPageRoute`) yang lega, bebas desakan keyboard virtual, dan sesuai aturan `/antislop`.
  - Background kanvas gelap matte `#1C2229`, AppBar elegan dengan tombol kembali dan judul kontekstual ("Tambah Kategori Baru" / "Ubah Kategori").
- **Dua Kartu `NestedCard` (Card Inside Card):**
  - **Card 1 (Informasi Kategori):**
    - Label "Nama Kategori" diposisikan di atas baris input agar rapi.
    - Kotak preview ikon dinamis 48x48px sejajar horizontal persis dengan input teks nama kategori (tinggi 48px, `CrossAxisAlignment.center`, border radius 12px) dengan live feedback warna aksen dan ikon/emoji terpilih.
    - Segmented switcher Tipe Transaksi (`Pengeluaran` vs `Pemasukan`).
    - Palet 9 warna aksen fin-tech dengan ring seleksi checkmark.
  - **Card 2 (Pilihan Ikon):**
    - **Tab `Icon`:** Bar pencarian bersih (`Cari ikon...`) + grid 6-kolom ikon vektor Tabler terkurasi dengan hover/selected state cyan.
    - **Tab `Emoji`:** Input custom emoji keyboard sistem + grid 7-kolom emoji terpopuler.
    - **Label Tab Bersih:** Secara konsisten dan tegas hanya berlabel **`Icon`** dan **`Emoji`** (tanpa label "Tabler/Icon").
- **Aksi Simpan:** Tombol primer elevated oceanic sapphire (`#02539A`) ditempatkan **fixed / pinned di bagian bawah layar/sheet** (di luar scroll view) sehingga pengguna tidak perlu menggulir ke bawah melewati daftar emoji. Tombol otomatis ter-disable dan hanya aktif saat seluruh form terisi valid (`_nameController.text.trim().isNotEmpty` dan `_selectedEmoji != null`).

### 3.12 Standar Universal Modal Bottom Sheet Bergaya Kartu (`lib/widgets/modal_card_sheet.dart`)
- **Pola Floating Card Inside Card:**
  - Seluruh modal bottom sheet di aplikasi tidak lagi menempel datar ke tepi bawah layar, melainkan melayang (*detached floating card*) dengan margin samping dan bawah `14px` - `16px`, sudut membulat penuh `24px` di keempat sudutnya, dan bayangan lembut.
  - Di dalam container luar (`#0C131D`), terdapat drag handle pill, baris header (ikon judul + teks judul `Inter Tight` + tombol tutup sirkular), serta **Inner Slate Container** (`#131A26`, `borderRadius: 18px`, `border: 1px rgba(255, 255, 255, 0.06)`) yang membungkus seluruh konten formulir dan tombol aksi.
  - Diadopsi secara universal oleh: Ubah Nama Pengguna, Ekspor Cadangan Data, Pulihkan Cadangan Data, Reset Transaksi, Reset ke Bawaan, Konfirmasi Hapus Kategori, dan Month Picker pada Laporan Analisis.

### 3.13 Preferensi Tampilan Layar Mandiri (`lib/screens/display_preferences_screen.dart`)
- **Arsitektur New Page:** Navigasi mandiri via `DisplayPreferencesScreen.route()` lengkap dengan `StandardScreenHeader` ("Preferensi Tampilan").
- **3 Mode Tampilan Beranda:**
  1. **Complete View:** Tampilan bawaan komprehensif (Saldo Saat Ini, Pemasukan, dan Pengeluaran).
  2. **Pemasukan dan Pengeluaran:** Menyembunyikan view saldo saat ini di hero card Beranda, memfokuskan ringkasan pada arus kas masuk dan keluar.
  3. **Pengeluaran saja:** Fokus total pada pengeluaran saja (saldo dan pemasukan dihilangkan, kartu pengeluaran melebar penuh).
- **Interactive Wireframe Preview:** Setiap opsi dilengkapi wireframe miniatur visual yang merefleksikan layout nyata kartu hero beranda untuk mode tersebut, lengkap dengan radio checkmark sirkular.

### 3.14 Pembaca Notifikasi Otomatis (`lib/screens/notification_reader_screen.dart` & `NotificationRule`)
- **Kebijakan Build Aman:** Capability ini nonaktif secara default pada public/release build melalui `lib/config/app_capabilities.dart`. Baris pengaturan tetap terlihat sebagai `Nonaktif pada build aman` dengan ikon kunci dan tidak dapat diaktifkan.
- **Manifest Release Minimum:** Overlay `android/app/src/release/AndroidManifest.xml` membuang service `NotificationListener`; manifest utama juga membuang `QUERY_ALL_PACKAGES`, `REQUEST_DELETE_PACKAGES`, `SCHEDULE_EXACT_ALARM`, dan `USE_EXACT_ALARM`.
- **Build Internal Saja:** Listener hanya boleh dicoba pada build internal/debug yang dikompilasi eksplisit dengan `--dart-define=YOTRO_NOTIFICATION_READER=true`, lalu dipasang via ADB/perangkat pengembangan. Build seperti ini tidak cocok untuk distribusi APK melalui browser/chat karena Play Protect dapat memblokir aplikasi Internet-sideloaded yang meminta akses notifikasi sensitif.
- **Deteksi Transaksi Otomatis:** Mengurai pesan notifikasi bank & dompet digital (myBCA, GoPay, Livin Mandiri, ShopeePay, dsb) secara offline di perangkat.
- **Filter Anti-Promosi Otomatis:** Pesan yang mengandung kata kunci promosi (`promo`, `diskon`, `cashback`, `voucher`, `penawaran`, `undian`, dsb) ditolak otomatis dan tidak pernah masuk ke antrean persetujuan.
- **Ekstraksi Cerdas:** Regex mengekstrak nominal angka transaksi (`Rp 45.000` atau numerik ribuan), nama merchant/rekening tujuan (`ke [Toko/Penerima]`), serta menautkan ke dompet default dan kategori transaksi.
- **Kartu Persetujuan di Beranda (`DashboardScreen`):**
  - Notifikasi transaksi yang lolos deteksi tidak langsung mengubah saldo, melainkan memunculkan kartu persetujuan di Beranda ("Persetujuan Notifikasi").
  - Menampilkan nama aplikasi (pill aksen), merchant, pesan lengkap, dan nominal merah.
  - Aksi `Setujui & Catat`: Menyimpan transaksi pengeluaran baru dan langsung memotong saldo dompet terkait.
  - Aksi `Abaikan`: Menghapus notifikasi dari antrean tanpa mengubah saldo.
  - Ikon lonceng notifikasi di pojok kanan atas Beranda dilengkapi badge counter merah ketika ada transaksi pending.
- **Simulator & Manajemen Aturan:** Halaman pengaturan pembaca notifikasi memuat master switch, simulator uji coba sekali-klik bebas emoji dekoratif (menggunakan ikon vektor panah/blokir), daftar aturan per aplikasi dengan pemicu yang dapat diubah, serta modal tambah aturan baru.

### 3.15 Dual Theme Mode: Dark Slate & Monochrome Neutral Light Mode
- **Mode Bawaan:** Dark Mode (`FThemes.slate.dark` / `#1C2229` canvas, `#0C131D` & `#131A26` cards).
- **Light Mode Netral Monokrom:**
  - Latar kanvas: `#F4F5F7` netral sejuk.
  - Permukaan kartu: Putih murni (`#FFFFFF`) berborder lembut `#E2E8F0`.
  - Teks: Hitam arang tajam `#0F172A`, slate sekunder `#475569`, dan muted `#64748B`.
  - Zero AI Rainbow Slop: Dilarang menggunakan gradien ungu/pink atau warna jenuh generik.
- **Toggle Mode:** Switch adaptif langsung di menu "Profil & Pengaturan" > "Mode Tampilan" yang tersimpan persisten ke SharedPreferences.
- **Komponen Adaptif Tema:** Seluruh komponen (`NestedCard`, `StandardScreenHeader`, `BottomNavBar`, form input, dialog sheet) secara dinamis mengadaptasi kanvas, border, teks, dan ikon mengikuti `Theme.of(context).brightness`.

### 3.16 Ikon Aksi Cepat Beranda Berbasis Vektor SVG (`lib/screens/dashboard_screen.dart` & `assets/icon/`)
- Keempat menu aksi cepat pada sapphire balance card di Beranda menggunakan berkas vektor SVG resmi yang tersimpan di `assets/icon/`:
  - `Dompet` -> `assets/icon/Dompet.svg`
  - `Budget` -> `assets/icon/Budget.svg`
  - `Analisis` -> `assets/icon/Analisis.svg`
  - `Split Bill` -> `assets/icon/Split Bill.svg`
- Menggunakan `SvgPicture.asset` (`flutter_svg: ^2.3.2`) dengan ukuran diperbesar menjadi **36x36px** (mengkompensasi internal padding SVG 512px sehingga glif terlihat ~20-22px) dan filter warna adaptif (`ColorFilter.mode(isDark ? Colors.white : const Color(0xFF0F172A), BlendMode.srcIn)`).

### 3.17 Pemindaian Struk Belanja OCR On-Device & Bilah Aksi 3 Tombol (`lib/screens/add_transaction_screen.dart`, `lib/widgets/receipt_adjustment_sheet.dart`)
- **Bilah Aksi Bawah 3 Tombol (`AddTransactionScreen`):**
  - Menggantikan tombol simpan tunggal sebelumnya dengan bilah aksi 3 tombol horizontal presisi tinggi:
    1. **Tombol Sirkular Kamera `[ 📷 ]` (Kiri, 48x48px):** Outlined circular button (background transparan, border outline halus `1.2px` `rgba(255,255,255,0.18)` / `#CBD5E1`) dengan ikon `Icons.camera_alt_outlined` (22px). Mengetuk tombol membuka modal bottom sheet untuk memilih sumber: **Kamera** atau **Galeri Foto**.
    2. **Tombol Pill Utama `[ Simpan Transaksi ]` (Tengah, `Expanded`, tinggi 48px):** Tombol aksi utama biru safir `#2F91E4` dengan sudut bulat pill `BorderRadius.circular(24)`, teks putih bersih `Manrope w600 15px`.
    3. **Tombol Sirkular Mikrofon `[ 🎙️ ]` (Kanan, 48x48px):** Outlined circular button (background transparan, border outline halus `1.2px` `rgba(255,255,255,0.18)` / `#CBD5E1`) dengan ikon `Icons.mic_none_rounded` (22px). Dialokasikan untuk fitur input suara catatan transaksi rilis mendatang; saat ini menampilkan notifikasi info via `AppSnackBar`.
- **Keyboard Hygiene pada Pemilihan Kategori (`AddTransactionScreen`):**
  - Pemilihan kategori melalui modal bottom sheet `Lainnya` otomatis meng-unfocus dan menonaktifkan re-focus ke input nominal (`_amountFocusNode.canRequestFocus = false`).
  - Setelah kategori dipilih dan sheet tertutup, keyboard tidak muncul kembali secara otomatis sehingga antarmuka tetap bersih dan tenang.
- **Pemrosesan OCR 100% On-Device & Offline:**
  - Memanfaatkan `google_mlkit_text_recognition: ^1.0.0` (Latin script) dan `image_picker: ^1.2.4`.
  - Bersih dari dependensi cloud atau pengiriman gambar ke server luar, menjaga privasi finansial pengguna sepenuhnya.
  - Arsitektur abstraksi lintas platform dengan *conditional export* (`receipt_scanner_mobile.dart`, `receipt_scanner_web.dart`, `receipt_scanner_stub.dart`).
  - Web runner menyediakan fallback simulasi cerdas OCR sehingga seluruh alur dapat diuji coba tanpa batas di browser port 8080.
- **Mesin Parsing Cerdas Struk (`ReceiptParserService` — `lib/services/receipt_scanner/receipt_parser_service.dart`):**
  - **Prioritas Grand Total vs Subtotal:** Membagi kata kunci pencarian menjadi Tier 1 (`GRAND TOTAL`, `TOTAL BAYAR`, `TOTAL BELANJA`, `TOTAL AKHIR`, `TAGIHAN`) dan Tier 2 (`SUBTOTAL`, `SUB TOTAL`, `JUMLAH`). Memindai baris dari bawah ke atas agar nilai akhir faktur selalu menjadi nominal utama.
  - **Daftar Nominal Alternatif:** Mengumpulkan seluruh nominal terdeteksi dari struk ke dalam daftar `alternativeAmounts` untuk dipilih pengguna jika nominal otomatis tidak sesuai.
  - **Ekstraksi Nama Toko / Merchant:** Memindai baris awal struk dengan filter cerdas mengabaikan teks header non-nama seperti `JL.`, `JALAN`, `TELP`, `NPWP`, `KASIR`, `STRUK`, dsb.
  - **Deteksi Tanggal Otomatis:** Mendukung format numerik (`DD/MM/YYYY`, `DD-MM-YYYY`) dan nama bulan bahasa Indonesia / Inggris (`12 Nov 2026`, `24 Oktober 2026`).
  - **Deteksi Kategori Cerdas:** Pencocokan nama brand toko (contoh: Indomaret/Alfamart -> Belanja, Starbucks/KFC -> Makanan & Minuman, Shell/Pertamina -> Transportasi, PLN/PDAM -> Tagihan & Utilitas) diprioritaskan sebelum pencocokan kata kunci item isi struk.
- **Lembar Penyesuaian & Persetujuan Struk (`ReceiptAdjustmentSheet` — `lib/widgets/receipt_adjustment_sheet.dart`):**
  - Muncul otomatis setelah pemrosesan OCR selesai sebagai modal sheet bergaya Card-Inside-Card (~90% tinggi layar).
  - **Card 1 (Nominal Transaksi):** Menampilkan nominal terdeteksi dalam text field rupiah yang dapat diedit langsung. Jika struk mendeteksi beberapa nominal angka lain, ditampilkan deretan chip horizontal "Nominal lain dari struk" yang dapat diketuk untuk beralih nominal seketika.
  - **Card 2 (Toko & Tanggal):** Input teks nama toko/merchant (autofill dari OCR, dapat diedit) dan tombol pemilih tanggal kalender.
  - **Card 3 (Kategori & Dompet Pembayaran):** Dropdown pilihan kategori pengeluaran (autoselect dari deteksi cerdas) dan pilihan akun dompet asal.
  - **Dua Tombol Alur Penyelesaian (Opsi 2 User Flow):**
    1. **"Setujui & Simpan" (Tombol Utama Safir):** 1-klik langsung mencatat transaksi pengeluaran baru ke `TransactionProvider`, menutup sheet, dan membuka layar sukses penuh `TransactionSuccessScreen`.
    2. **"Buka di Form" (Tombol Outlined):** Menerapkan nominal, merchant/catatan, tanggal, kategori, dan dompet yang telah disesuaikan langsung ke form `AddTransactionScreen` untuk pengisian tambahan.

### 3.18 Redesain Analisis Keuangan: Half Circular Gauge, Kurva Alur, & Donut Chart (`lib/screens/financial_analysis_screen.dart`, `lib/widgets/donut_chart_painter.dart`)
- **Half Circular Health Gauge (Arch 180°):**
  - Menggantikan visual linear meter lama dengan busur setengah lingkaran murni (`_HalfCircularHealthPainter`) dari $\pi$ (180°) ke $2\pi$ (360°), dengan ujung melengkung halus `StrokeCap.round` (lebar stroke 14px) sesuai referensi wireframe.
  - Background track berpalet gelap `#232D3B` (atau `#E2E8F0` di mode terang), progress arc dinamis sesuai skor 0-100 dengan warna status (`statusColor`).
  - Indikator thumb knob sirkular putih dengan stroke warna status di ujung progres.
  - Di dalam kubah busur: Display angka skor finansial besar `${metrics.score}` (`Inter Tight 38px bold`) berdampingan dengan ` / 100`, dan badge pill status kesehatan (misal `Sangat Baik` atau `Aman & Stabil`).
  - Di bawah busur: **Baris 4 Zona Konteks** (`Kurang` <50 merah, `Waspada` 50-64 amber, `Aman` 65-79 cyan, `Sangat Baik` 80-100 hijau) dengan penyorotan aktif (*active highlight pill*) pada zona skor pengguna saat ini.
- **Diagram Kurva Alur Pemasukan & Pengeluaran (`_CashFlowCurvePainter`):**
  - Grafik garis kurva halus (*C1-continuous cubic bezier spline*) yang memetakan tren perputaran kas bulan terpilih pada interval tanggal kunci (`Tgl 1, 7, 14, 21, 28, Akhir Bulan`).
  - Kurva Hijau (`#39D98A`) untuk Pemasukan dan Kurva Cyan (`#55C7FF`) untuk Pengeluaran, masing-masing dilengkapi area fill gradien vertikal lembut di bawah garis.
  - Interaktif: Mengetuk checkpoint tanggal menampilkan baris kursor vertikal dan kartu info posisi tgl terpilih (`Posisi Tgl X: Masuk Rp ... | Keluar Rp ...`).
- **Donut Chart Komparasi Pemasukan vs Pengeluaran (`DonutChartPainter`):**
  - Menggunakan komponen `DonutChartPainter` bergaya annular rounded wedge presisi tinggi dengan sudut rounded 6px dan celah radial 3.5° identik dengan Laporan Keuangan.
  - Bagian tengah donut memuat label `Arus Kas Bersih`, nominal bersih terformat, dan badge status `Surplus` / `Defisit`.
  - Dilengkapi 2 kartu mini berdampingan (`Uang Masuk` & `Uang Keluar`) dengan persentase share perputaran kas, serta pod pengeluaran terbanyak.
- **Eliminasi Metrik Lama:**
  - Pod "Rata-rata Harian" (*Daily Burn Rate*) dan "Proyeksi Akhir Bulan" (*Projected Month-End Spend*) dihapus sepenuhnya dari layar analisis dan modal sheet panduan bantuan.
- **Urutan Switch Tab Laporan Keuangan (`AnalyticsScreen`):**
  - Urutan switcher ikon chart pada menu Laporan Keuangan dibalik: ikon Donut Chart (`Icons.pie_chart_rounded`) ditaruh di sebelah kiri, sedangkan ikon Bar Chart (`Icons.bar_chart_rounded`) di sebelah kanan. Default view mode adalah `ChartViewMode.donut`.

### 3.19 Atmospheric Sapphire Radial Glow di 4 Layar Utama (`lib/widgets/ambient_top_glow.dart`)
- **Widget Terpusat (`AmbientTopGlow`):**
  - Widget modular tunggal (`height: 480.0`, `IgnorePointer`, `Positioned(top: 0, left: 0, right: 0)`) dengan `RadialGradient` di `Alignment(0.0, -1.0)` dan radius `1.25`.
  - Palet pendaran gradien safir atas: `#034A8C` (stop 0.0) -> `#023668` (stop 0.35) -> `#062343` (stop 0.68) -> `#001C2229` (stop 1.0 transparan menyatu ke kanvas `#1C2229`).
- **Penerapan Multi-Screen (Khusus Dark Mode):**
  1. **Beranda (`DashboardScreen`):** Pendaran biru di balik greeting header ("Selamat pagi...") dan kartu saldo hero, dengan ambient soft shadow (`#034A8C` blur 32) pada panel saldo.
  2. **Riwayat (`TransactionsScreen`):** Pendaran di balik top bar "Riwayat Transaksi", search bar, dan chip filter periode.
  3. **Laporan (`AnalyticsScreen`):** Pendaran di balik top bar "Laporan Keuangan", pill pemilih bulan, dan kartu aktivitas pengeluaran donut chart.
  4. **Profil & Pengaturan (`SettingsScreen`):** Pendaran di balik header profil pengguna ("Ian Firdaus", email, badge Pro).
- **Invarian Safe Area:** Membungkus body Scaffold dengan `Stack([if (isDark) const AmbientTopGlow(), SafeArea(...)])` sehingga gradien menyala penuh dari tepi fisik atas perangkat (status bar & notch / dynamic island). Light mode tetap bersih monokrom.

### 3.20 Layar Penuh Perekam Transaksi Suara & Smooth Circular Spectrum (`VoiceRecordingScreen` & `CircularSpectrumVisualizer`)
- **Tampilan Penuh Minimalis & Clean (Full-Page Minimal Screen):**
  - Mengubah perekam transaksi suara menjadi **layar penuh mandiri (`VoiceRecordingScreen`)** yang sangat bersih (*clean look*).
  - Kanvas navy solid `#09101C` tanpa background mesh/glow berlebih.
  - **Header Bersih:** Tombol tutup rounded-square di kiri, judul ringkas dan elegan **"Input Suara"** (`Inter Tight 16px, w600`) berada di **pojok kanan atas**. Status teks ("Mendengarkan", "Dijeda", "Mode uji") dan dot status dihilangkan total demi estetika clean fin-tech.
  - **Pusat Spektrum & Tombol Kontrol Terpadu:**
    - Spektrum ditempatkan tepat di tengah-tengah layar vertikal dan horizontal (`size: 290px`).
    - **Tombol Merekam / Pause di Pusat Spektrum (Anti-Slop Restrained):** Tombol sirkular 58x58px tactile diletakkan langsung di dalam rongga tengah spektrum. Menggunakan permukaan padat solid matte (`#131A26` aktif, `#0D131C` jeda), border hairline 1px (`rgba(255, 255, 255, 0.2)`), dan bayangan jatuh realistis tanpa pendaran glow/cyan blur generik (zero-slop R-01, R-12, R-13). Ikon 24px kontras tinggi berubah antara `Icons.pause_rounded` (putih solid) dan `Icons.mic_rounded` (slate muted).
    - Menghilangkan tombol pause terpisah di bilah bawah; bilah bawah kini hanya memuat tombol tunggal `Selesai & Tinjau` yang melebar penuh (*full width*).
  - **Atmospheric Sapphire Ambient Bottom Glow (Khusus Dark Mode):**
    - Membungkus Scaffold dengan `Stack` memuat pendaran safir radial layar penuh (`Positioned.fill` dengan `RadialGradient(center: Alignment(0.0, 1.25), radius: 1.25)` dan 5 stops warna: `#034A8C` -> `#02386B` -> `#04213F` -> `#6606172C` -> `#0009101C`).
    - Tanpa batas container tetap atau cutoff di bagian atas; gradien memudar secara mulus ke kanvas gelap pekat `#09101C`.
    - Latar belakang kontainer dan garis border di belakang tombol `Selesai & Tinjau` dihilangkan sepenuhnya (`Padding(fromLTRB(16, 8, 16, 16))`), sehingga tombol melayang langsung di atas pendaran atmosferik biru safir yang mengalir bebas tanpa garis pembatas kaku.
    - Tetap monokrom bersih pada Light Mode.
  - **Contoh Pengucapan Halus (Subtle Caption Hint):**
    - Menghilangkan teks "Ucapkan transaksimu", kalimat deskripsi panjang, divider garis, dan label "Transkrip langsung".
    - Saat diam / menunggu suara: menampilkan petunjuk pengucapan kecil dan tidak mencolok di bawah spektrum: `Contoh: "Kopi 25 ribu" atau "Siomay 13rb, tahu tek 100rb"` (`12.5px`, muted slate `0.7 opacity`).
    - Saat suara terdeteksi: menampilkan teks terucap secara halus dan elegan (`16px`) beserta indikator feedback jumlah item dan nominal terformat.
- **Smooth Circular Spectrum:**
  - Menggambar outline lingkaran putih tipis sebagai bentuk dasar dan kurva radial tertutup dari 144 sampel dengan quadratic smoothing.
  - Saat perekaman dimulai, ticker langsung aktif walau hening; bentuk tetap lingkaran sempurna dan hanya highlight sweep putih–cyan yang berputar perlahan sebagai state standby.
  - Saat suara melewati gate, empat harmonic bands membentuk waveform radial yang amplitudo, panjang filamen, glow, dan ketebalannya mengikuti energi input.
  - Envelope waveform memakai attack 80ms dan release 240ms. Hening mengembalikan bentuk secara halus ke outline circle tetapi standby highlight tetap bergerak selama status merekam.
  - **Normalisasi Input Adaptif:** `VoiceRecordingScreen` mempelajari ambient sound floor dan peak level dari callback mikrofon, memberi noise margin dinamis, kompresi sinyal, serta smoothing attack/release lintas Android/iOS sebelum mengirim nilai 0..1 ke visualizer.
- **Mesin Parsing Cerdas Bahasa Indonesia (`VoiceTransactionParserService`):**
  - Mendeteksi ucapan multi-item: *"Siomay 13 ribu, tahu tek 100 ribu, keyboard 500 ribu, hp 1 juta"*.
  - Menangani satuan kata: *ribu*, *rb*, *k*, *ratus*, *juta*, *jt*, *seratus ribu*, *sejuta*, *setengah juta* (500rb), *dua koma lima juta* (2.5jt).
  - Auto-kategorisasi (Makanan & Minuman, Belanja, Transportasi, Tagihan, Hiburan, Gaji).
- **Alur Perutean Adaptif (Adaptive Routing):**
  - **1 Item:** Langsung menutup layar penuh dan mengisi form `AddTransactionScreen` secara otomatis (Nominal, Catatan, Kategori) tanpa langkah tambahan (*zero friction*).
  - **Lebih dari 1 Item:** Membuka lembar ringkasan khusus `VoiceMultiItemSummarySheet` dengan daftar item 1 kolom ke bawah.
- **Interaksi Koreksi Item & Aksi Multi-Item:**
  - Mengetuk baris item membuka dialog edit cepat bergaya anti-slop matte slate (`#0C131D` & `#131A26`, zero outline putih kasar) untuk mengoreksi nominal, nama, atau kategori.
  - Ikon silang/hapus pada setiap baris untuk membuang item yang tidak diinginkan.
  - **Tombol "Ulangi"** (Outlined, ikon refresh): Mengulang perekaman suara dari awal (teks 1 baris).
  - **Tombol "Catat Semua"** (Primary): Menyimpan seluruh transaksi sekaligus secara batch ke `TransactionProvider`.
- **Simulator Chips:** Disediakan tombol simulasi cepat 1 item dan 4 item khusus di Web Runner (`kIsWeb`) atau fallback; disembunyikan total saat aplikasi berjalan sebagai APK di ponsel.
- **Tombol Tes Spektrum Web-Only:** Action chip `Tes gerak spektrum` hadir murni pada `kIsWeb`. Mode uji memutar pola 4 detik (silent ring → attack/fluktuasi suara → release) tanpa mengisi transkrip atau merutekan transaksi; klik ulang menghentikan timer dan mengembalikan energi ke nol.
- **API Speech Modern:** Konfigurasi locale `id_ID`, `listenFor`, dan `pauseFor` menggunakan `SpeechListenOptions` agar bebas API deprecated pada `speech_to_text 7.5.0`.

### 3.21 Multi-Step Onboarding Flow Pertama Kali Pasang (`lib/screens/onboarding_profile_screen.dart`)
- **Arsitektur 4 Tahap Berurutan (Sequential Onboarding Steps):**
  - **Step 1: Identitas & Data Diri (Wajib):** Input Nama Lengkap (validasi wajib diisi), Nomor Telepon (opsional), dan Jenis Kelamin (Pria/Wanita). Dilengkapi tombol "Lanjutkan" (masuk Step 2) dan tombol teks cepat "Mulai Mencatat" (selesaikan langsung dengan default).
  - **Step 2: Tema & Preferensi Tampilan Dashboard (Opsional / Bisa Dilewati):**
    - Pilihan Mode Tampilan: Sistem, Terang, Gelap.
    - Pilihan Tampilan Beranda: Tampilan Lengkap (`complete`), Pemasukan & Pengeluaran (`incomeExpense`), atau Pengeluaran Saja (`expenseOnly`).
    - Tombol "Lanjutkan" atau "Lewati".
  - **Step 3: Atur Dompet / Rekening (Opsional / Bisa Dilewati):**
    - Menampilkan daftar dompet aktif pengguna.
    - Tombol "+ Tambah Dompet Baru" membuka bottom sheet modal untuk menginput nama dompet, tipe (Bank, E-Wallet, Cash), dan saldo awal opsional.
    - Tombol "Lanjutkan" atau "Lewati".
  - **Step 4: Atur Kategori Transaksi (Opsional / Bisa Dilewati):**
    - Tab Pengeluaran dan Pemasukan menampilkan chip kategori aktif.
    - Tombol "+ Tambah Kategori" terintegrasi langsung dengan `EditCategoryScreen.showAsModalSheet` untuk menambah kategori baru secara instan.
    - Tombol utama penyelesaian: **"Mulai Mencatat"**.
- **Indikator Progres Responsif Bebas Overflow:** Indikator 4 pill progres (`Profil`, `Tampilan`, `Dompet`, `Kategori`) dibungkus dalam `FittedBox(fit: BoxFit.scaleDown)` dengan padding proporsional, menjamin zero RenderFlex overflow pada seluruh resolusi layar (termasuk layar sempit <= 360px).

### 3.22 Status Bar & Notification Bar Adaptif Mode Terang (`lib/main.dart` & `lib/screens/main_shell.dart`)
- **Penyelesaian Isu Status Bar HP Tidak Terlihat di Light Mode:**
  - Sebelumnya, pada Light Mode, ikon notification/status bar bawaan smartphone (jam, baterai, sinyal) tidak terlihat karena tetap berwarna putih di atas latar belakang aplikasi yang terang.
  - Membungkus `MaterialApp.builder` dan root `Scaffold` di `main_shell.dart` dengan `AnnotatedRegion<SystemUiOverlayStyle>` dan panggilan dinamis `SystemChrome.setSystemUIOverlayStyle`.
  - Mengatur `statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark` (Android) dan `statusBarBrightness: isDark ? Brightness.dark : Brightness.light` (iOS) secara global, menjamin ikon status bar selalu kontras tajam (hitam di mode terang, putih di mode gelap).

### 3.23 Tombol Logout Khusus Web Runner untuk Pengujian Onboarding (`lib/screens/settings_screen.dart`)
- Menambahkan tombol Logout khusus saat aplikasi berjalan di web (`if (kIsWeb)`) pada kartu profil dan Danger Zone di `SettingsScreen`.
- Tombol ini membuka dialog konfirmasi dan memanggil `provider.logout()` (mereset `isOnboardingCompleted = false`) serta menavigasi ke `OnboardingProfileScreen`, memungkinkan pengujian alur 4 tahap onboarding berulang kali di browser `localhost:8080`.

### 3.24 Penyempurnaan Tombol Total Saldo, Sub-Card Likuiditas, & Modal Mata Uang
- **Tombol "Total Saldo" Minimalis Anti-Slop (`lib/screens/dashboard_screen.dart`):**
  - Ikon dompet dihapus total; tombol menggunakan murni tipografi `Text('Total Saldo')`.
  - Mode default / inaktif (versi Bulanan): Berupa text button transparan tanpa border atau container latar (`color: Colors.transparent`), teks putih teredam (`Colors.white.withOpacity(0.70)`), sehingga tidak mencolok di samping filter bulan.
  - Mode aktif (versi Total Saldo): Berubah menjadi kapsul solid putih (`color: Colors.white`) dengan teks sapphire gelap (`#0B2244`, `FontWeight.w600`).
  - Visibilitas Terbatas: Hanya ditampilkan pada mode beranda **Complete View** (`dashboardViewMode == DashboardViewMode.complete`). Otomatis disembunyikan total pada mode `incomeExpense` dan `expenseOnly`.
- **Sub-Card Likuiditas Finansial Mode Total Saldo (Opsi 1):**
  - Menggantikan sub-card lama ("Pengeluaran total" & "Pemasukan total") saat mode Total Saldo aktif.
  - **Sub-card Kiri — "Bank & Rekening":** Menampilkan total agregat seluruh dompet bertipe `Bank Account` dan `Savings` via getter `provider.bankWalletsTotalBalance`. Ikon vektor `Icons.account_balance_rounded`. Mengetuk sub-card membuka layar `WalletsScreen`.
  - **Sub-card Kanan — "Kas & E-Wallet":** Menampilkan total agregat dompet tunai dan digital via getter `provider.cashAndDigitalWalletsTotalBalance`. Ikon vektor `Icons.account_balance_wallet_rounded`. Mengetuk sub-card membuka layar `WalletsScreen`.
- **Pengaturan "Mata Uang" dengan Modal Bottom Sheet (`lib/screens/settings_screen.dart`):**
  - Judul diubah dari "Mata Uang Acuan" menjadi **"Mata Uang"**.
  - Trailing widget menampilkan chip bendera negara (`🇮🇩 IDR` / `🇺🇸 USD`) disertai chevron `>`.
  - Mengetuk baris pengaturan membuka sheet modal `_showCurrencyPickerSheet` dengan pilihan 🇮🇩 IDR (Rupiah Indonesia - Rp) dan 🇺🇸 USD (US Dollar - $). Pilihan langsung tersimpan dan menampilkan konfirmasi snackbar.

### 3.25 Hero Card Horizontal Slide, Stationary Header [Nov 2026] vs [Total Saldo], Dynamic Wallet Sub-Cards, & Snug Fit Spacing (`lib/screens/dashboard_screen.dart`)
- **Stationary Top Header (Label Bulan & Total Saldo Tidak Ikut Tergeser)**:
  - Header navigasi kartu hero (`_buildHeroHeader`) diposisikan **stasioner penuh di luar `PageView`**, tepat di bagian atas kontainer safir.
  - Tombol kiri menampilkan bulan kalender berjalan (misal `Nov 2026`) dan tombol `Total Saldo`.
  - Saat pengguna menggeser (*swipe*) kartu atau mengetuk tombol, **header tidak ikut bergeser**. Tombol aktif murni beralih status secara halus di tempatnya (`Nov 2026` aktif kapsul putih saat Bulanan; `Total Saldo` aktif kapsul putih saat Total Saldo).
  - Yang meluncur/bergeser secara fisik ke kiri dan kanan murni **hanya konten saldo dan sub-card finansial**:
    - **Halaman 0 (Bulanan)**: "Saldo saat ini", nominal saldo terformat utuh, dan sub-card Pengeluaran & Pemasukan.
    - **Halaman 1 (Total Saldo)**: "Total Saldo", nominal total agregat utuh, dan sub-card per dompet (*wallets*).
- **Sub-Card Dinamis Per-Dompet dengan Scroll Horizontal & Intipan Kartu ke-3 (`_buildWalletsSection`)**:
  - Pada slide Total Saldo (Halaman 1), sub-card agregat statis digantikan dengan kartu individual per dompet aktif pengguna (`provider.wallets`).
  - **Kondisi <= 2 Dompet**: Ditampilkan dalam layout `Row` standar dengan pembungkus `Expanded` yang membagi lebar secara seimbang.
  - **Kondisi > 2 Dompet**: Ditampilkan dalam `SingleChildScrollView(scrollDirection: Axis.horizontal, physics: BouncingScrollPhysics())` menggunakan `LayoutBuilder`:
    - Lebar kartu dihitung presisi: `cardWidth = (constraints.maxWidth - 52).clamp(120.0, 300.0) / 2`.
    - Menampilkan 2 kartu penuh di layar, dan **kartu ke-3 diintipkan selebar ~40px** dari tepi kanan kontainer, memberi petunjuk visual instan kepada pengguna bahwa deretan dompet dapat digulir horizontal.
    - Setiap kartu dompet menampilkan ikon vektor spesifik tipe dompet (`Bank Account`, `Cash`, `E-Wallet`, `Savings`), nama akun, saldo terformat (mendukung masking privasi), dan aksi tap menuju `WalletsScreen.route()`.
- **Penyempurnaan Spasi Vertikal Antara Saldo dan Sub-Card & Zero-Clipping Height**:
  - Menambah jarak vertikal antara teks nominal saldo ("Saldo saat ini" / "Total Saldo") dengan sub-card dari `6px` menjadi `10px` (`SizedBox(height: 10)`), memberikan breathing room yang proporsional dan tidak mepet.
  - Menyesuaikan tinggi `_contentHeight` pada seluruh mode tampilan agar sub-card tidak lagi terpotong garis batas bawahnya:
    - **Complete View**: Disesuaikan dari `104.0px` menjadi `116.0px` (memuat saldo + gap 10px + sub-card dompet/arus kas secara utuh, plus `SizedBox(height: 7)` sebelum pagination dots).
    - **Pemasukan & Pengeluaran (`incomeExpense`)**: Disesuaikan dari `44.0px` menjadi `52.0px` (memuat sub-card 47px dengan margin vertikal bersih, zero clipping).
    - **Pengeluaran Saja (`expenseOnly`)**: Disesuaikan dari `58.0px` menjadi `64.0px` (memuat label Total Pengeluaran + nominal 32px utuh tanpa terpotong), disertai penambahan gap atas dari header menjadi `12px` (`SizedBox(height: isExpenseOnly ? 12 : 6)`), gap bawah PageView `6px`, dan padding bawah kontainer safir `10px` (`isExpenseOnly ? 10 : 7`). Total penambahan ruang lega vertikal sebesar +21px menghilangkan kesan terlalu mepet pada tampilan pengeluaran saja secara tuntas.
  - Seluruh konten dibungkus dalam `SingleChildScrollView(physics: const NeverScrollableScrollPhysics())` guna menjamin zero RenderFlex overflow pada variasi font sistem dan resolusi layar apapun.
- **Standarisasi Universal Ketinggian Tombol Bottom Sheet (48px Height Standard)**:
  - Seluruh tombol aksi primer (`ElevatedButton`) dan sekunder (`OutlinedButton`) pada modal bottom sheet di seluruh aplikasi distandarisasi ke ketinggian **48px** (`SizedBox(height: 48, ...)`):
    - `SettingsScreen`: Sheet Preferensi Tampilan (`Simpan Preferensi`), Pengingat Harian (`Simpan Pengingat`), Ubah Profil (`Batal` & `Simpan`), Ekspor Data (`Batal` & `Unduh Berkas JSON`), Impor Data (`Merge Data` & `Replace Data`), Hapus Semua Transaksi (`Batalkan` & `Hapus Semua`), Reset Data Bawaan (`Batalkan` & `Reset Bawaan`).
    - `WalletsScreen`: Sheet Tambah/Edit Dompet (`Simpan Dompet` & tombol hapus), Konfirmasi Hapus Dompet (`Batal` & `Hapus Dompet`).
    - `BudgetScreen`: Sheet Edit Anggaran Kategori (`Simpan Anggaran`), Edit Total Anggaran Bulanan (`Simpan Perubahan`), Kartu Kosong (`Atur Anggaran Bulanan`).
  - Menghilangkan tombol-tombol kerdil yang sebelumnya hanya berukuran 38-44px, memberikan touch target ergonomis dan visual premium anti-slop.

### 3.26 Integrasi Cloud Supabase (Google Sign-In, MCP Server & Offline-First Sync)
- **Koneksi MCP Supabase**: Mendaftarkan server MCP resmi Supabase (`https://mcp.supabase.com/mcp?project_ref=njjcviwihzvzjgfbzitg&...`) di `~/.gemini/antigravity/mcp_config.json`.
- **Konfigurasi Proyek & Graceful Fallback (`SupabaseConfig` — `lib/config/supabase_config.dart`)**:
  - Project reference default `njjcviwihzvzjgfbzitg`, URL `https://njjcviwihzvzjgfbzitg.supabase.co`.
  - Inisialisasi aman dalam blok `try-catch` sehingga aplikasi 100% fungsional offline tanpa gangguan jika kredensial belum diisi atau sedang tanpa jaringan internet.
  - Mendukung input/edit kredensial mandiri melalui form modal di layar Pengaturan.
- **Otentikasi Google Sign-In (`SupabaseAuthService` — `lib/services/supabase_auth_service.dart`)**:
  - Tombol aksi satu klik "Masuk dengan Google" memanfaatkan `supabase.auth.signInWithOAuth(OAuthProvider.google)` dengan deep-link mobile `io.supabase.yotro://login-callback`.
- **Mesin Sinkronisasi Dua Arah (`SupabaseSyncService` — `lib/services/supabase_sync_service.dart`)**:
  - Sinkronisasi tabel PostgreSQL dengan RLS: `profiles`, `wallets`, `categories`, `transactions`, dan `budgets`.
  - Eksekusi non-blocking di latar belakang saat transaksi dibuat atau dihapus.
- **Kartu Sinkronisasi Cloud di Pengaturan (`lib/screens/settings_screen.dart`)**:
  - Menampilkan status koneksi ("Mode Tamu (100% Lokal)" vs "Terhubung sebagai [email]").
  - Tombol aksi utama "Masuk / Hubungkan Akun" membuka `AuthScreen(fromSettings: true)` dan tombol sekunder "Masuk dengan Google".
  - Saat terhubung: tombol "Sinkronkan Sekarang" dan opsi "Keluar" kembali ke mode lokal.

### 3.12 Otentikasi Multi-Opsi & Mode Tamu 100% Offline (`AuthScreen` — `lib/screens/auth_screen.dart`)
- **Layar Autentikasi Mandiri (`AuthScreen`):**
  - Menjadi gerbang awal saat aplikasi dibuka pertama kali (`!provider.isOnboardingCompleted`) sebelum masuk ke alur utama.
  - Menghadirkan kontrol tab segmen halus antara **Daftar Baru** dan **Masuk**.
  - **1. Pendaftaran Manual (Daftar Baru):**
    - Input: Nama Lengkap, Email, Kata Sandi (min. 6 karakter dengan toggle visibilitas), dan Ulangi Kata Sandi (validasi kesesuaian).
    - Memanggil `SupabaseAuthService.signUpWithEmail(email, password, fullName)`.
    - PostgreSQL trigger otomatis `on_auth_user_created` di Supabase langsung mengisi baris `profiles` dengan nama dan email pengguna.
    - Menangani dua skenario pendaftaran: auto-confirmed session (langsung masuk) dan email confirmation requirement (dialog petunjuk ramah pengguna).
  - **2. Masuk Manual (Masuk):**
    - Input: Email dan Kata Sandi dengan tautan pemulihan "Lupa kata sandi?".
    - Memanggil `SupabaseAuthService.signInWithEmail(email, password)`.
    - Pesan error teknis Supabase diformat menjadi bahasa Indonesia awam yang ramah (`formatAuthException`).
    - **Bypass Onboarding Akun Terdaftar:** User yang masuk via tab "Masuk" langsung menarik data cloud via `SupabaseSyncService.pullCloudData()`, menandai `isOnboardingCompleted = true`, dan langsung diarahkan ke `MainShell` (Beranda) tanpa masuk ke tahapan setup ulang.
  - **3. Masuk dengan Google:**
    - Tombol vektor clean "Lanjutkan dengan Google" menjalankan `SupabaseAuthService.signInWithGoogle()`.
    - **Deteksi Akun Terdaftar (`hasExistingUserData`):** Memeriksa apakah user Google telah memiliki data dompet/transaksi/profil cloud atau akun terdaftar lama. Jika terdaftar, otomatis menarik data cloud dan langsung masuk ke Beranda. Jika user Google baru pertama kali, diarahkan ke Step 1 untuk memilih preferensi awal.
  - **4. Mode Tamu / Lewati (100% Offline First):**
    - Pilihan aksi "Lewati / Masuk sebagai Tamu" dengan keterangan *"Mode 100% lokal tanpa sinkronisasi cloud"*.
    - Mengaktifkan status lokal `provider.continueAsGuest(name: 'Pengguna Tamu')` tanpa memerlukan akun Supabase atau koneksi internet.
    - Data keuangan (dompet, kategori, transaksi, anggaran) tersimpan 100% aman di memori lokal (`SharedPreferences` / `localStorage`).
    - Pengguna tamu dapat kapan saja menghubungkan akun atau mendaftar ke Supabase dari menu Pengaturan (`SettingsScreen`), di mana data lokal yang telah dibuat dapat diunggah langsung ke cloud (*push local to remote*).

### 3.27 In-App OTA Updater & Catatan Rilis / Changelog
- **In-App OTA Updater Android (`AppUpdateService` — `lib/services/app_update_service.dart`)**:
  - Memeriksa rilis terbaru secara non-blocking via GitHub Releases API (`https://api.github.com/repos/ianfrds/yotroapp/releases/latest`).
  - Mengambil versi aplikasi lokal saat runtime via `package_info_plus: ^10.2.2`.
  - Logika komparasi semver dinamis (`isNewerVersion`) membandingkan elemen versi dengan `max(3, max(latestParts.length, currentParts.length))`, menjamin akurasi jika tag rilis memiliki multi-segmen atau pre-release prefix (`v`).
  - Mengunduh biner APK stream ke direktori cache lokal aplikasi (`path_provider.getTemporaryDirectory()`), menghitung persentase progress unduhan secara real-time.
  - Membuka installer biner APK menggunakan `open_filex: ^4.7.0` dan FileProvider (`com.moneytracker.app.fileProvider`) yang terkonfigurasi di `android/app/src/main/res/xml/file_paths.xml` dan `AndroidManifest.xml` (`REQUEST_INSTALL_PACKAGES`).
  - **In-place update guarantee:** Pembaruan in-place Android dengan application ID dan signature yang sama mempertahankan seluruh data lokal aplikasi (`/data/data/com.moneytracker.app/...`), `SharedPreferences`, sesi login Supabase, dan data transaksi tanpa risiko logout atau data terhapus.
  - Auto-check non-blocking dipanggil sekali saat startup aplikasi di `MainShell` (`addPostFrameCallback`) hanya untuk platform Android (`!kIsWeb && Platform.isAndroid`).
- **Modal Dialog Update Berdesain Sapphire (`AppUpdateDialog` — `lib/widgets/app_update_dialog.dart`)**:
  - Dialog pop-up floating dark matte sapphire (`#0C131D`, border `rgba(255, 255, 255, 0.08)`) dengan rincian versi baru, ukuran unduhan, dan catatan rilis ringkas.
  - Saat unduhan berjalan, tombol aksi berganti menjadi progress bar animasi halus dengan persentase dan label byte terunduh.
- **Catatan Rilis (Changelog) di Profil & Pengaturan (`ChangelogData` — `lib/models/changelog_model.dart`)**:
  - Menu "Catatan Rilis" dihadirkan pada kartu "Tentang Aplikasi" di `SettingsScreen`.
  - Membuka modal bottom sheet responsif (`_showChangelogSheet`) yang menampilkan riwayat changelog per-versi (v2.0.4, v2.0.3, v2.0.2, v2.0.0, v1.0.6, v1.0.5, v1.0.0).
  - Setiap rilis dilengkapi nomor versi, badge "Terbaru" (untuk versi rilis aktif), tanggal rilis terformat, dan bullet list perubahan terstruktur.
- **Workflow CI GitHub Actions (`.github/workflows/build-apk.yml`)**:
  - Build Android dibatasi ke `android-arm64` dan menghasilkan satu artifact distribusi `yotro-app.apk` dari `app-arm64-v8a-release.apk`; ARM32, x86_64, dan universal APK tidak dibuat atau diunggah.
  - Build Web release tetap dijalankan di GitHub Actions untuk menjaga paritas, sedangkan preview harian lokal menggunakan `flutter run -d chrome --web-port 8080` dengan hot reload.
  - Push/PR branch `main` menjalankan tes dan build validasi, tetapi tidak menerbitkan GitHub Release.
  - GitHub Release hanya diterbitkan oleh tag `vX.Y.Z`; nama tag wajib sama dengan versi semantik di `pubspec.yaml`.
  - Rilis bertag wajib memiliki empat GitHub Actions Secrets signing produksi. Build CI non-rilis memakai keystore sementara dan tidak boleh didistribusikan sebagai pembaruan produksi.

---

## 4. Standar Desain & Aturan Anti-Slop (`design.md`)

1. **Zero-Slop Dark Matte:**
   - Latar belakang kanvas solid gelap pekat menggunakan kode hex **`#1C2229`** pada seluruh layar scaffold, shell, dan dock cutout. Kontainer card di atasnya menggunakan dark slate `#0C131D` dan `#131A26`.
2. **One Deliberate Accent:**
   - Aksen gradien sapphire/mesh hanya diizinkan di dalam kartu virtual hero atau busur gauge. Elemen lain tetap matte solid.
3. **High Contrast Typography & Weight Cap:**
   - Kontras teks putih tajam (`#FFFFFF`) di atas permukaan gelap (`#1C2229` / `#0C131D` / `#131A26`).
   - Angka finansial format rapat dan tegas (`Inter Tight`) serta teks isi ramah (`Manrope`).
   - **Invarian Bobot Font:** Dilarang menggunakan `bold`, `w700`, `w800`, atau `extrabold`. Bobot maksimal diizinkan adalah **`FontWeight.w600` (`SemiBold`)**, dengan teks saldo hero menggunakan **`FontWeight.w500` (`Medium`)** untuk estetika bersih.
4. **Zero-Slop Shadows (Anti-Slop UI):**
   - Hapus semua drop-shadow mengambang berlebih (misal glow blur 24px) pada panel saldo dan status dot.
   - Kedalaman permukaan diciptakan murni lewat kontras warna matte (`#0C131D` vs `#1C2229`) dan border stroke 1px (`rgba(255, 255, 255, 0.08)`).
5. **Margin & Spasi Layar (Compact Screen Padding):**
   - Margin horizontal tepi layar diperkecil ke rentang **`12px` - `14px`** (menggantikan margin `20px` sebelumnya) pada seluruh layar dan bottom nav bar.
   - Padding kartu saldo diperketat (`fromLTRB(14, 10, 14, 12)` pada kartu dalam dan `5px` pada kontainer luar).
6. **Clean Action Hierarchy & Modal Animations:**
   - Halaman Catat Transaksi dibuka dengan animasi muncul dari bawah (*swipe up modal*) menggunakan `SlideUpRoute`, lengkap dengan gesture swipe-down untuk menutup halaman.
   - Tombol utama kontras jelas, tombol aksi cepat memiliki ikon terdistribusi rapi dengan radius konsisten (`14px` - `18px`).
7. **No Decorative Emoji:**
   - Ikon murni vektor/SVG.

---

## 5. Cara Menjalankan & Menguji Aplikasi

### Opsi A: Browser Preview Flutter Web
Bangun lalu sajikan hasil Flutter Web. Port `8080` saat ini dipakai untuk preview lokal.
```bash
flutter build web --release
python3 -m http.server 8080 --directory build/web
```
Akses di browser: `http://localhost:8080/`

### Opsi B: Flutter Run Langsung
Flutter SDK terpasang di `~/.flutter-sdk/bin/flutter` (dan terdaftar di `~/.zshrc`):
```bash
# Ambil dependensi
flutter pub get

# Jalankan di Chrome
flutter run -d chrome --web-port 8080

# Jalankan di Android Emulator / Device (jika SDK terinstal)
flutter run
```

### Opsi C: Build Cloud APK Tanpa Android Studio Lokal
Proyek telah dilengkapi workflow GitHub Actions di [`.github/workflows/build-apk.yml`](.github/workflows/build-apk.yml).
Empat GitHub Actions Secrets `YOTRO_KEYSTORE_BASE64`, `YOTRO_STORE_PASSWORD`, `YOTRO_KEY_PASSWORD`, dan `YOTRO_KEY_ALIAS` sudah dikonfigurasi. Push branch biasa hanya menghasilkan artifact validasi; GitHub Release bertanda tangan produksi diterbitkan setelah tag `vX.Y.Z` yang cocok dengan versi `pubspec.yaml` di-push manual.

### Opsi D: Download & Install APK Langsung ke HP
Gunakan hanya `yotro-safe-release.apk` (v1.0.3+4). APK legacy `yotro-release.apk` dan `money-tracker-release.apk` masih debug-signed dan tidak boleh didistribusikan.
1. Verifikasi SHA-256 dari `yotro-safe-release.apk.sha256`.
2. Jika perangkat masih memiliki versi debug dengan package `com.moneytracker.app`, uninstall sekali karena signature berbeda.
3. Transfer `yotro-safe-release.apk` ke HP lalu instal. Jangan menonaktifkan Play Protect.

---

## 6. Status Terkini & Checklist Pengerjaan

- [x] Audit akar blokir Google Play Protect: APK lama debug-signed dan mendeklarasikan service `NotificationListener` sensitif.
- [x] Safe release v1.0.3+4 dibuat dengan release keystore RSA 4096 dan signature scheme v2/v3; key dan `key.properties` diabaikan Git.
- [x] Manifest release diverifikasi tanpa Notification Listener, broad package visibility, package deletion, dan exact-alarm permissions.
- [x] Artifact instalasi aman tersedia sebagai `yotro-safe-release.apk`; SHA-256 `6e0bc302f231b1ab2677ff997119df33d8d1c0b0bd758d3a9b780f196f98b835`.
- [x] Flutter Web release dibangun ke `build/web/` dan preview tersedia di `http://127.0.0.1:8080/`.
- [x] Seluruh 62 test lulus; `flutter analyze` tidak memiliki error kompilasi (peringatan/info legacy masih ada).
- [ ] Cadangkan `android/yotro-release-key.jks` dan `android/key.properties` ke password manager/penyimpanan terenkripsi terpisah.
- [x] Empat GitHub Actions Secrets signing produksi telah dikonfigurasi; validasi nilai final dilakukan oleh build tag `v2.0.4`.
- [x] Workflow OTA diamankan: release hanya dari tag yang cocok dengan `pubspec.yaml`; tagged release gagal cepat bila signing secrets produksi tidak lengkap.
- [x] Label versi Splash dan tombol unduh APK Web mengambil `ChangelogData.currentVersion`, menghapus hardcode versi lama.
- [x] Build APK CI difokuskan ke ARM64-only untuk HP modern; GitHub Release hanya memuat `yotro-app.apk`, sementara build Web tetap diverifikasi di cloud dan dapat dijalankan lokal di port 8080.
- [x] Versi kandidat dinaikkan ke `2.0.4+12`; publikasi GitHub Release dibatasi hanya untuk push tag yang cocok dan tidak lagi berjalan dari push branch `main`/`master`.
- [x] Storage proyek lokal dibersihkan setelah verifikasi: `flutter clean` menghapus `build/` dan `.dart_tool/`, tiga APK ignored/duplikat di root dihapus, dan ukuran workspace turun dari sekitar 1,7 GB output terbangun menjadi sekitar 69 MB source. Artifact dapat diregenerasi dari CI; cache Gradle global tidak disentuh.
- [x] Inisialisasi struktur Flutter dengan Forui, Google Fonts (`Inter Tight` & `Manrope`), Provider, dan Shared Preferences.
- [x] Implementasi 6 layar utama: Dashboard, Transactions, Budget, Wallets, Reports, Settings.
- [x] Form Tambah/Edit Transaksi dengan dukungan multi-tipe (Income, Expense, Transfer).
- [x] Redesain Dashboard dari wireframe kasar menjadi antarmuka luxury fin-tech sapphire.
- [x] Widget Kontrol Pengeluaran Hari Ini (semi-circular gauge dengan batas harian & 3 pod statistik).
- [x] Sinkronisasi state & seed data IDR (`Rp 132.400` balance, `Rp 320.000` expense, `Rp 4.000.000` income, `Rp 25.000` daily coffee).
- [x] Floating 5-item bottom dock dengan tombol tengah elevated `(+)`.
- [x] Pembatasan bobot font maksimal ke `SemiBold` (`FontWeight.w600`) di seluruh layar (`Inter Tight` & `Manrope`).
- [x] Pengurangan margin horizontal tepi layar dari `20px` menjadi `12px` - `14px` di seluruh layar dan dock.
- [x] Perbaikan rendering font ikon Material di Flutter Web: menyertakan `MaterialIcons-Regular.otf`, `FontManifest.json`, dan fallback stylesheet di `web/` dan `build/web/`.
- [x] Layout Card Inside Card pada panel saldo hero dengan padding tipis (`5px` outer, `6px` inner) dan sub-card pengeluaran/pemasukan mepet tepi kanan-kiri (margin 6px).
- [x] Gradien radial presisi pada kartu saldo: `radial-gradient(95.69% 108.33% at 50% 100%, #041735 0%, #001732 36.06%, #00498C 100%)`.
- [x] Penerapan font `Medium` (`FontWeight.w500`) pada label "Saldo saat ini" dan nominal display saldo.
- [x] Penghapusan drop-shadow dan glow berlebihan sesuai panduan Anti-Slop UI.
- [x] Komponen reusable `NestedCard` (`lib/widgets/nested_card.dart`) dengan pola "Card Inside Card" (outer dark slate `#0C131D` + inner elevated `#131A26` ber-margin tipis 6px).
- [x] Penerapan `NestedCard` di seluruh layar: Dashboard (Transaksi Terbaru & Pengeluaran Hari ini), Budget (Monthly Overall Budget & Category Budgets), Wallets (Accounts & Transfer), Analytics (Activity Chart & Breakdown), dan Transactions (Transaction Records).
- [x] Avatar ikon transaksi sirkular (`BoxShape.circle`) dengan divider halus (`indent: 68`).
- [x] Update tema latar belakang kanvas aplikasi ke hex `#1C2229` (`AppColors.background`, scaffold, bottom nav cutout).
- [x] Redesain Layar Tambah/Edit Transaksi (`AddTransactionScreen`) dengan animasi swipe-up dari bawah (`SlideUpRoute`), gesture drag-down to dismiss, hero nominal input + quick chips, category vector icon chips, dan wallet selector.
- [x] Perbaikan bug blank putih pada Tambah Transaksi: inisialisasi `initializeDateFormatting('id_ID', null)` di `lib/main.dart`, implementasi `_formatIndonesianDate` mandiri tanpa dependensi eksternal tak terinisialisasi, dan validasi nilai dropdown wallet (`validSelectedWalletId`, `validFromWalletId`, `validToWalletId`).
- [x] Default state nominal `0` rupiah pada form tambah transaksi baru, serta optimasi ketinggian dropdown dompet/akun menjadi lebih kompak (`height: 38px`, `isDense: true`).
- [x] Refinement Header Beranda: Avatar profil bulat penuh (`BoxShape.circle`, 38x38px), tipografi nama menggunakan bobot `Medium (w500)` ukuran 16px, tombol notifikasi bulat 36x36px, dan pengetatan padding/gap vertikal header.
- [x] Penggantian widget Kontrol Pengeluaran Hari Ini (circular gauge) di Beranda dan Analytics menjadi **WeeklyActivityChart** (`lib/widgets/weekly_activity_chart.dart`): 100% fungsional dengan data transaksi real minggu ini (Senin–Minggu), interaktif klik per hari, floating tooltip badge dinamis dengan `AnimatedPositioned`, normalisasi tinggi bar, dan penghapusan label/pod berlebih sesuai prinsip antislop.
- [x] Penambahan section card Kalender Pelacak Pengeluaran **SpendingCalendarCard** (`lib/widgets/spending_calendar_card.dart`) di bawah Activity Chart: format ubin rounded (`12px`, `#252F3D`), pelacakan pengeluaran harian dengan format compact (contoh `13K`), badge lingkaran hari ini, dan navigasi bulan (`<` dan `>`).
- [x] Transformasi Navigation Bottom Bar dari floating pill dock menjadi **Fixed Bottom Bar** yang mepet ke dasar layar: full-width edge-to-edge, ketinggian optimal `68px`, latar belakang `#0C131D`, border atas 1px tipis, safe-area inset yang rapi, tombol (+) tengah elevated sapphire naik ke atas (`Offset(0, -17)`) dengan ukuran proporsional `55x55px` ber-cutout border, dan penyesuaian bottom padding konten layar (100px) agar bebas overlap.
- [x] Redesain Layar Laporan (**Report Screen** / `lib/screens/analytics_screen.dart`): Top Bar tanpa tombol back, month pill picker, segmented switcher Expenses/Income, Hero Card ber-switch pill (Bar vs Donut) space-between, dan daftar rincian kategori tersinkron.
- [x] Default View Mode Bar Chart pada Layar Laporan (`ChartViewMode.bar`) saat layar pertama kali dibuka.
- [x] Donut Chart Annular Wedge Modern: Geometri analitik fillet lingkaran sempurna ($s^2 + r_c^2 = (R \pm r_c)^2$) dengan sudut rounded murni (`cornerRadius: 6.0px`), proporsi kokoh sesuai gambar referensi ($R_o=112\text{px}, R_i=68\text{px}$, ketebalan 44px, rasio lubang tengah 60.7%), celah sudut 3.5°, palet 5 warna referensi (`#007AFF`, `#34C759`, `#FF9500`, `#AF52DE`, `#FF3B30`), interaksi sentuh langsung pada cincin, dan floating percentage badge (radius 90px).
- [x] Format Nominal Tengah Donut Chart: Format kompak otomatis — ribuan-ratusan ribu menggunakan format `k` (contoh: `101k`, `320k`) dan jutaan menggunakan format `jt` (contoh: `3,4 jt`, `4 jt`) dengan font `26px` yang lapang.
- [x] Filter per-Minggu pada Bar Chart Aktivitas: Navigator unboxed murni (tanpa badge pill/container) dinaikkan posisinya mendekati atas kartu, tinggi bar chart dinaikkan ke 195px (batang 122px), sinkronisasi dengan dropdown bulan laporan, dan pembagian minggu kalender Senin–Minggu dengan swipe gesture.
- [x] Modernisasi Riwayat Transaksi: Top Bar bersih tanpa tombol Add "+ Catat" (dengan aksi kontekstual Reset Filter), search bar responsif, dan sistem multi-filter 2 baris seimbang dengan tinggi nyaman 42px (Filter Bulan, Filter Tanggal spesifik dengan datepicker, Filter Jenis Transaksi, dan Filter Dompet).
- [x] Standardisasi `TransactionTile`: Format Rupiah dinamis (`provider.formatCurrency`), ikon kategori bulat bertinting, subtitle tanggal & dompet, serta penanganan netral transfer.
- [x] Refinement Beranda & Laporan: Header beranda bersih tanpa foto avatar profil (murni greeting kontekstual & nama), spasi vertikal antar-kartu di Beranda dan Layar Laporan diseragamkan menjadi 12px, kartu transaksi terbaru dibatasi maksimal 3, dan privasi penuh saat tombol mata ditekan.
- [x] Resolusi Stale Cache Flutter Web: Unregister Service Worker & hapus CacheStorage otomatis, injeksi `Cache-Control: no-store, no-cache, must-revalidate` pada local dev server, standardisasi script loader `flutter_bootstrap.js`, serta eliminasi double-script injection yang menyebabkan canvas allocator crash dan blank putih.
- [x] Redesain & Refinement Nav Bottom Bar dengan **Scooped Cradle Cutout** (`lib/widgets/bottom_nav_bar.dart`): Mengikuti gambar referensi visual 1:1 dengan lekukan notch kubik Bezier kontinu (`notchDepth: 39px`, `notchHalfWidth: 54px`, `c1: 15`, `c2: 28`) dengan tangensi horizontal C1 sempurna tanpa sudut tajam, celah cradle merata ~8.5px di sekeliling tombol, tombol aksi (+) elevated oceanic sapphire 58x58px (`#025EA8`–`#014786`) ber-drop shadow ganda, 4 ikon navigasi vektor murni 28px (`grid_view_rounded`, `description_rounded`, `pie_chart_rounded`, `person_rounded`) dengan 5 slot kolom `Expanded` 100% berinterval equidistant seragam (`0.20 * W`), warna aktif putih murni dan inaktif `#94A3B8`, touch target 48x46px bebas tabrakan notch, home indicator bar iOS 136x4px di dasar, serta default tab Beranda (index 0).
- [x] Perbaikan & Penyempurnaan Layar **Profil & Pengaturan** (`lib/screens/settings_screen.dart`): Header bersih tanpa subtitle, penghapusan fitur "Batas Anggaran Bulanan" yang belum diperlukan, kartu Preferensi Finansial hanya memuat `Mata Uang Acuan` (IDR/USD) dan switch `Sembunyikan Saldo` berdeskripsi anti-slop *"Fokus pengeluaran dan pemasukan di beranda"*. Seluruh modal dialog digantikan oleh **Modal Bottom Sheet** rounded 24px (`#101722`) adaptif keyboard mobile (Ubah Nama, Ekspor JSON, Pulihkan Data JSON Merge/Replace, Kosongkan Transaksi, dan Reset Bawaan).
- [x] Pemisahan State Visibilitas Saldo & Card Collapsing: Memisahkan secara tegas `isBalanceVisible` (masking angka nominal `Rp ••••••••` dan `Rp ••••••` via tombol mata di kartu Beranda) dan `hideBalanceSection` (menyembunyikan/mengempiskan panel "Saldo saat ini" di Beranda saat switch `Sembunyikan Saldo` aktif di Pengaturan).
- [x] Fitur Baru Sub-Menu **Kelola Kategori** (`lib/screens/manage_categories_screen.dart`): CRUD lengkap kategori (Pengeluaran & Pemasukan), terintegrasi library Tabler Icons dengan search bar, Emoji picker (grid + input keyboard sistem), pemilihan warna aksen, konfirmasi hapus aman dengan pengalihan otomatis transaksi terkait ke kategori "Others/Lainnya", dan integrasi ke layar Tambah Transaksi serta Transaction Tile.
- [x] Resolusi Rendering Tabler Icons di Flutter Web: Mendaftarkan `@font-face` untuk `tabler-icons` dan `packages/flutter_tabler_icons/tabler-icons` di `index.html`, menginjeksi entri font manifest di `FontManifest.json`, dan compile release dengan `--no-tree-shake-icons` agar seluruh 5.700+ glif ikon Tabler termuat utuh tanpa terpotong.
- [x] Standarisasi Label Sumber Ikon Kategori: Menghilangkan label "Tabler/Icon", digantikan secara bersih dengan label **`Icon`** dan **`Emoji`** baik pada badge daftar kategori maupun tab form.
- [x] Form Kategori Menjadi Layar Mandiri Baru (**`EditCategoryScreen`** / `lib/screens/edit_category_screen.dart`): Arsitektur halaman baru (*new page*, bukan bottom sheet) dengan dua `NestedCard` (Informasi Kategori & Pilihan Ikon), palet 9 warna aksen, tab bersih `Icon` & `Emoji`, serta tombol simpan elevated sapphire.
- [x] Standarisasi Universal Bottom Sheet Bergaya **Floating Nested Card** (`lib/widgets/modal_card_sheet.dart`): Mengubah seluruh bottom sheet di aplikasi (Ubah Nama, Ekspor JSON, Pulihkan JSON, Reset Transaksi, Reset Bawaan, Hapus Kategori, dan Month Picker Analisis) menjadi kartu melayang mengambang dengan margin samping/bawah 14px-16px, sudut membulat 24px, dan inner card container slate `#131A26` ber-radius 18px.
- [x] Proteksi Layout Overflow pada `NestedCard`: Menambahkan `Expanded` dan `TextOverflow.ellipsis` pada judul header agar bebas overflow RenderFlex di layar sempit.
- [x] Konfigurasi Android Build Toolchain & Compile Release APK: Menyiapkan JDK 17, Android SDK 36, AndroidX, dan AGP 8.11.1; berhasil meng-compile file APK siap instal [`money-tracker-release.apk`](money-tracker-release.apk) (57.5MB) lengkap dengan hosting download lokal via HTTP endpoint WiFi.
- [x] Pemformatan Nominal Otomatis & Eliminasi Leading Zero di Layar Tambah Transaksi: Mengimplementasikan `ThousandsSeparatorInputFormatter` (`lib/utils/thousands_separator_formatter.dart`) dengan pemisah titik ribuan (`.`) real-time, eliminasi leading zero saat input angka (misal `'0'` diketik `'5'` langsung menjadi `'5'`), penambahan sinkronisasi titik ribuan pada quick amount chips (`+10rb`, `+20rb`, `+50rb`, `+100rb`), penempatan kursor presisi tanpa meloncat, serta penambahan unit test dan widget test komprehensif (24 passing tests).
- [x] Standardisasi Seluruh Kategori Menggunakan Emoji: Menetapkan seluruh kategori bawaan dan kustom menggunakan Emoji representatif (`CategoryModel`, `TransactionProvider`, `TransactionTile`, `CategoryChip`), melengkapi fallback emoji cerdas berbasis kata kunci, serta mendedikasikan form `EditCategoryScreen` untuk seleksi Emoji (pencarian, grid terkurasi, dan input keyboard sistem).
- [x] Category Selector 2 Baris Presisi & Modal Bottom Sheet 2 Kolom: Mengatur selektor kategori di form Tambah Transaksi agar strictly maksimal 2 baris (menghitung lebar pill secara dinamis, mengalokasikan ruang untuk pill "Lainnya" bila sisa kategori overflow). Menghapus tombol teks redundant "Semua >", menyisakan akses tunggal via pill "Lainnya", dan modal bottom sheet ber-scroll halus saat memuat banyak kategori dalam format 2 kolom simetris.
- [x] CRUD Dompet & Rekening Lengkap: Pengguna dapat menambah dompet baru, mengedit nama/tipe/saldo dompet yang sudah ada, serta menghapus dompet (dengan pengalihan transaksi otomatis ke dompet aktif lainnya).
- [x] Default Neutral Typography pada Prefix Mata Uang ("Rp" / "$"): Mengganti warna biru `_cyan` pada label mata uang di form bottom sheet input nominal menjadi warna default putih netral (`Colors.white.withOpacity(0.7)`) yang tenang dan anti-slop.
- [x] CRUD Budget Per Kategori & Bottom Sheet Modal Penuh: Pengguna dapat menambah, mengedit, atau menghapus batas budget per kategori (memilih kategori pengeluaran dan nominal dengan pemisah ribuan). Seluruh dialog lama pada menu budget dan dompet telah digantikan 100% oleh Modal Bottom Sheet bergaya Floating Card (`showModalCardSheet`).
- [x] Standarisasi Header Layar & Tombol Kembali Universal: Membuat komponen [`StandardScreenHeader`](lib/widgets/standard_screen_header.dart) (`38x38px`, icon `arrow_back_ios_new_rounded`, margin 10px ke judul) dan menerapkannya secara seragam pada seluruh halaman mandiri (Kelola Kategori, Tambah/Edit Kategori, Dompet & Rekening, serta Budget).
- [x] Standardisasi Spacing Antar-Card Universal 12px: Menyeragamkan seluruh jarak vertikal antar-kartu di seluruh layar (Beranda, Budget, Dompet, Laporan Analitik, Pengaturan, dan Riwayat Transaksi) secara presisi menjadi `12px` konsisten.
- [x] Menu Budget & Menu Dompet Menjadi Halaman Mandiri Baru (**New Page**): Membuka `BudgetScreen` dan `WalletsScreen` sebagai halaman mandiri baru via `Navigator.push(...)` lengkap dengan tombol back navigasi `arrow_back_ios_new_rounded`.
- [x] Spending Calendar Card Header Format Bulan & Tahun: Menampilkan tahun pada judul kartu kalender di Beranda (contoh: "November 2026").
- [x] Modal Bottom Sheet Full Width: Mengubah seluruh bottom sheet di `modal_card_sheet.dart` menjadi full width edge-to-edge tanpa batas margin horizontal kanan-kiri ke layar.
- [x] Reset Scroll Otomatis ke Atas: Memasang `ScrollController` terkoordinasi pada seluruh tab `MainShell` dan sub-layar agar setiap kali kembali ke halaman sebelumnya atau berpindah tab, posisi scroll otomatis di-reset ulang ke paling atas (`0.0`).
- [x] Restrukturisasi 4 Tombol Aksi Cepat Beranda: Menghapus tombol redundant "Masuk" dan "Keluar" (telah diakomodasi tombol (+) utama), memperbarui urutan menjadi **`(Dompet, Budget, Analisis, Split bill)`** dengan navigasi langsung ke halaman masing-masing.
- [x] Standardisasi Emoji Transaksi Terbaru di Beranda: Mengganti list transaksi manual di Beranda dengan `TransactionTile` sehingga avatar kategori menggunakan Emoji representatif (`categoryModel.buildIconWidget` / `CategoryModel.fallbackEmojiFor`) dan selaras 100% dengan Riwayat Transaksi.
- [x] Pemisahan Bersih Menu Laporan Keuangan & Analisis Keuangan:
  - Kembalikan tab Laporan Keuangan (tab ke-4 bottom nav bar via `AnalyticsScreen`) ke format laporan murni: Top App Bar ("Laporan Keuangan" + month picker), Segmented Pill (Pengeluaran vs Pemasukan), Hero Chart (Weekly Activity Bar & Donut Chart toggle), dan Rincian Kategori Breakdown (`NestedCard`) tanpa kartu skor kesehatan.
  - Dedikasikan fitur "Analisis" dari aksi cepat Beranda ke layar mandiri [`lib/screens/financial_analysis_screen.dart`](lib/screens/financial_analysis_screen.dart) (`FinancialAnalysisScreen.route()`) yang memuat Skor Kesehatan Finansial (0-100), Visual Health Meter Bar, 3 Mini Metric Pods, Diagnosa Cerdas, Daily Burn Rate, Proyeksi Akhir Bulan, dan Rasio Pemasukan vs Pengeluaran.
  - Penambahan unit & widget test terintegrasi (30 passing tests).
- [x] Reduksi Padding Konten Inside Card di Profil & Pengaturan:
  - Mengurangi padding konten dalam inside card (`_buildSettingRow` padding menjadi `horizontal: 10, vertical: 8`, divider padding 10px, icon size 36x36px, dan innerPadding kartu profil/tentang menjadi 10px) agar antarmuka tidak terlalu lebar, lebih ramping, dan proporsional.
- [x] Penggantian Sembunyikan Saldo dengan Preferensi Tampilan (3 Mode):
  - Menggantikan switch boolean lama dengan sistem preferensi 3 mode (`DashboardViewMode`):
    1. `Complete View`: Tampilan default lengkap (saldo saat ini, pengeluaran, pemasukan).
    2. `Pemasukan dan Pengeluaran`: View saldo saat ini di kartu hero beranda dihilangkan, menampilkan pengeluaran dan pemasukan.
    3. `Pengeluaran saja`: Fokus pada ringkasan pengeluaran saja (saldo dan pemasukan dihilangkan, kartu pengeluaran tampil melebar penuh).
  - Penambahan unit & widget test terintegrasi.
- [x] Preferensi Tampilan Menjadi Layar Mandiri Baru (**New Page** / `lib/screens/display_preferences_screen.dart`):
  - Menghapus bottom sheet pemilihan preferensi tampilan lama, digantikan oleh halaman mandiri penuh (`DisplayPreferencesScreen.route()`).
  - Dilengkapi live interactive wireframe miniatur untuk ketiga mode dan radio checkmark visual.
- [x] Fitur Pembaca Notifikasi Otomatis (**Notification Reader** / `lib/screens/notification_reader_screen.dart`):
  - Model aturan pemicu dan filter abaikan (`NotificationRule`, `PendingNotification` di `lib/models/notification_rule_model.dart`).
  - Filter anti-promosi otomatis (`promo`, `diskon`, `cashback`, `voucher`, `penawaran`, `undian`).
  - Regex parser pintar untuk mengekstrak nominal IDR dan merchant/tujuan.
  - Kartu Persetujuan Notifikasi di Beranda ("Persetujuan Notifikasi" dengan tombol `Setujui & Catat` vs `Abaikan`).
  - Badge counter merah pada ikon lonceng Beranda saat ada antrean pending.
  - Halaman pengaturan lengkap dengan master switch, simulator uji coba tanpa emoji dekoratif, dan form tambah aturan baru.
- [x] Mode Tampilan Dual: Dark Mode Bawaan & Monochrome Neutral Light Mode:
  - Default tema tetap Dark Mode (`FThemes.slate.dark` / `#1C2229`).
  - Implementasi Light Mode monokrom netral murni (`AppTheme.lightTheme`): kanvas `#F4F5F7`, kartu putih `#FFFFFF` berborder `#E2E8F0`, teks `#0F172A` / `#475569`, zero AI purple/pink slop.
  - Toggle adaptif di menu Profil & Pengaturan > "Mode Tampilan" tersimpan ke SharedPreferences.
  - Adaptasi dinamis seluruh widget (`NestedCard`, `StandardScreenHeader`, `BottomNavBar`, form input, modal sheet) terhadap tema aktif.
- [x] Pengetatan Padding Konten Inside Card di Profil & Pengaturan:
  - Mengurangi padding `_buildSettingRow` menjadi `horizontal: 8, vertical: 6` dan innerPadding kartu profil/tentang menjadi `8px-10px`.
- [x] Audit & Pembenahan Total Seluruh Layar & Widget untuk Mode Terang (Light Mode):
  - Memperbaiki seluruh hardcoded dark background (`#1C2229`, `#0C131D`, `AppColors.background`) dan teks putih (`Colors.white`, `#8CA7C5`) menjadi adaptif berbasis tema (`Theme.of(context).brightness == Brightness.dark`).
  - [`lib/screens/analytics_screen.dart`](lib/screens/analytics_screen.dart): Laporan Keuangan beralih sempurna ke kanvas terang `#F4F5F7`, kartu putih, pill segment `#0F172A`, dan teks kontras tinggi `#0F172A` / `#64748B`.
  - [`lib/screens/financial_analysis_screen.dart`](lib/screens/financial_analysis_screen.dart): Skor kesehatan, meter bar, pods metrik, diagnosa cerdas, dan analisis arus kas beradaptasi penuh ke tema terang.
  - [`lib/screens/split_bill_screen.dart`](lib/screens/split_bill_screen.dart): Form input bill, pill pajak/tip, per person pod, baris anggota, dan tombol aksi beradaptasi monokrom netral (menghapus emoji dekoratif avatar, digantikan vektor `Icons.person_rounded`).
  - [`lib/screens/wallets_screen.dart`](lib/screens/wallets_screen.dart): Kartu dompet, modal tambah/edit dompet, balance display, dan callout transfer adaptif terang.
  - [`lib/screens/budget_screen.dart`](lib/screens/budget_screen.dart): Kartu batas pengeluaran bulanan, progress bar, dan daftar budget per kategori adaptif terang.
  - [`lib/screens/manage_categories_screen.dart`](lib/screens/manage_categories_screen.dart) & [`lib/screens/edit_category_screen.dart`](lib/screens/edit_category_screen.dart): Daftar kategori, selector segment, input field nama kategori, palet warna, dan grid emoji adaptif terang.
  - [`lib/screens/add_transaction_screen.dart`](lib/screens/add_transaction_screen.dart): Form tambah transaksi, Rp prefix, quick chips, selector kategori 2 baris, form details, dan date picker adaptif terang.
  - [`lib/screens/main_shell.dart`](lib/screens/main_shell.dart): Background root stack adaptif langsung tanpa visual glitch.
  - [`lib/widgets/category_chip.dart`](lib/widgets/category_chip.dart): Chip kategori adaptif kontras tinggi.
- [x] Toggle Mode Tampilan Ikon Bulan & Matahari Tanpa Deskripsi:
  - Menggantikan Switch teks lama dengan custom animated toggle pill yang memuat ikon Matahari (`Icons.wb_sunny_rounded` amber) di kiri dan Bulan (`Icons.nightlight_round` cyan) di kanan serta thumb bulat dinamis.
  - Menghilangkan teks deskripsi/subtitle pada baris Mode Tampilan di menu Profil & Pengaturan sesuai permintaan user.
- [x] Fitur Pengingat Transaksi Harian (**Daily Reminder**) & Intersep Izin Notifikasi:
  - Menyediakan pengaturan Pengingat Transaksi Harian di Profil & Pengaturan > "Notifikasi & Pengingat".
  - Berfungsi mengingatkan user pada jam yang dapat diatur (default `20:00`) jika belum ada catatan transaksi hari ini (`shouldShowDailyReminder`).
  - Menampilkan kartu notifikasi pengingat harian cerdas di Beranda lengkap dengan tombol CTA "Catat" saat belum ada mutasi transaksi hari ini.
  - Alur Izin Notifikasi Mandiri ([`lib/widgets/notification_permission_sheet.dart`](lib/widgets/notification_permission_sheet.dart)): Baik Pengingat Harian maupun Pembaca Notifikasi wajib meminta izin notifikasi perangkat terlebih dahulu (`hasNotificationPermission`), dengan rincian transparansi manfaat dan garansi 100% privasi lokal.
- [x] Penambahan Unit & Widget Tests Lengkap (49 Passing Tests):
  - Menguji switching Mode Tampilan via toggle Matahari/Bulan tanpa teks deskripsi.
  - Menguji pencegahan aktivasi pengingat harian tanpa izin notifikasi, keberhasilan aktivasi setelah izin diberikan, pembaruan jam pengingat, dan kalkulasi kondisi `shouldShowDailyReminder`.
  - Menguji rendering section Notifikasi & Pengingat di SettingsScreen.
- [x] Auto-Open Keyboard Nominal pada Form Tambah Transaksi:
  - Memasang `autofocus: true`, `FocusNode _amountFocusNode`, dan `WidgetsBinding.instance.addPostFrameCallback` pada [`lib/screens/add_transaction_screen.dart`](lib/screens/add_transaction_screen.dart) sehingga keyboard angka langsung terbuka otomatis begitu layar catat transaksi dibuka.
- [x] Izin Notifikasi Native OS Berbasis `permission_handler`:
  - Menambahkan dependensi `permission_handler: ^13.0.2` dan izin Android `POST_NOTIFICATIONS` di `AndroidManifest.xml` (compileSdk 37).
  - Dialog izin sekarang langsung memicu modal sistem operasi perangkat native (`Permission.notification.request()`), dengan fallback tombol `Buka Pengaturan HP` (`openAppSettings()`) jika izin pernah ditolak permanen.
- [x] Rebranding Menjadi "Yotro":
  - Memperbarui nama aplikasi di seluruh platform: Android label (`android:label="Yotro"`), Web title (`Yotro`), Flutter app title (`Yotro`), Profil & Pengaturan, dan format backup JSON.
- [x] Layar Splash Screen Beranimasi ([`lib/screens/splash_screen.dart`](lib/screens/splash_screen.dart)):
  - Emblem geometris safir "Y", animasi scale & fade in, tipografi tajam "Yotro", dan transisi halus ke `MainShell`.
- [x] Toolchain Build Android Yotro:
  - Mengonfigurasi compileSdk 37, JDK 17, Android SDK 37, dan NDK 28.2.
  - Artifact lama `yotro-release.apk` / `money-tracker-release.apk` dipertahankan hanya sebagai arsip debug-signed; artifact distribusi sekarang `yotro-safe-release.apk`.
- [x] Fitur Pengingat Transaksi Harian Real-time (**Inexact Alarm & Push Notification**):
  - Mengonfigurasi `flutter_local_notifications` dan `timezone` dengan `inexactAllowWhileIdle` serta Android broadcast receivers (`ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`, `ActionBroadcastReceiver`).
  - Alarm OS dijadwalkan mendekati jam pilihan pengguna jika belum ada catatan transaksi hari ini, didukung fallback in-app periodic check timer, tanpa izin exact alarm.
  - Opsi tombol "Uji Coba Push Notifikasi" di menu Profil & Pengaturan dan Pusat Notifikasi agar pengguna dapat langsung memverifikasi notifikasi HP berfungsi seketika.
- [x] Integrasi Internal Pembaca Notifikasi Android (**Android NotificationListenerService**):
  - Service native tetap ada di source set `main` untuk eksperimen internal, tetapi dihapus oleh overlay manifest `release` dan digate `AppCapabilities`.
  - Pemanggil izin "Akses Notifikasi" hanya berjalan saat build internal secara eksplisit mengaktifkan `YOTRO_NOTIFICATION_READER`.
  - Fitur pemindaian seluruh aplikasi HP via `installed_apps` sudah dihapus; package name aturan dapat diisi manual pada build internal.
  - Parser cerdas mutasi keuangan multi-bank otomatis mengekstrak nominal dalam format mata uang Indonesia (`Rp 50.000`, `Rp 25.000,00`, `IDR`), nama merchant, dan memicu push notification seketika ke status bar saat transaksi terdeteksi.
- [x] Layar Penuh Transaksi Berhasil Dicatat Beranimasi Checklist Gaya Lottie ([`lib/screens/transaction_success_screen.dart`](lib/screens/transaction_success_screen.dart)):
  - Menampilkan tampilan full-screen setelah transaksi baru disimpan dengan animasi checklist bergaya Lottie: medali safir berdenyut elastis, ripple waves memancar, tracing goresan centang vektor animasi, dan micro-burst partikel gemerlap.
  - Menampilkan kartu ringkasan transaksi (nominal berformat besar, kategori, tipe mutasi, tanggal & waktu, dan catatan).
  - Dua tombol aksi terpadu: "Kembali ke Beranda" dan "Catat Transaksi Lain".
- [x] Perbaikan Hapus Transaksi & Dialog Konfirmasi Hapus ([`lib/screens/add_transaction_screen.dart`](lib/screens/add_transaction_screen.dart)):
  - Memperbaiki bug tombol hapus: crash `StateError: Bad state: No element` diatasi dengan pencarian dompet null-safe (`firstWhere(..., orElse: () => null)`).
  - Menambahkan tombol "Hapus Transaksi Ini" yang menonjol di bagian bawah form saat membuka detail transaksi yang sudah ada.
  - Menampilkan modal dialog konfirmasi peringatan sebelum penghapusan permanen ("Hapus Transaksi?"), memastikan saldo dompet dikembalikan ke posisi semula dengan aman.
  - Autofocus keyboard dinonaktifkan saat membuka detail transaksi yang sudah ada agar tidak menutupi informasi detail dan tombol aksi.
- [x] Halaman Pusat Notifikasi Mandiri ([`lib/screens/notifications_center_screen.dart`](lib/screens/notifications_center_screen.dart)):
  - Tombol ikon lonceng di pojok kanan atas Beranda kini membuka halaman khusus Pusat Notifikasi.
  - Memuat section "Persetujuan Transaksi" dengan daftar transaksi terdeteksi yang menunggu konfirmasi (tombol "Setujui" & "Tolak" cepat), status Pengingat Harian & tes push, serta status filter aplikasi.
- [x] Redesain Layar Sukses Transaksi Anti-Slop & Navigasi Terpadu ([`lib/screens/transaction_success_screen.dart`](lib/screens/transaction_success_screen.dart)):
  - Mengubah kartu rincian transaksi menjadi pola terstandarisasi `NestedCard` (outer slate + inner container) bergaris safir matte.
  - Memperbaiki bug navigasi tombol: tombol "Kembali ke Beranda" (`popUntil route.isFirst`) dan "Catat Transaksi Lain" (`pushReplacement AddTransactionScreen`) kini terikat langsung pada BuildContext aktif layar sukses sehingga 100% responsif dan tidak lagi macet.
- [x] Penyesuaian Detail Transaksi & Modal Bottom Sheet Hapus ([`lib/screens/add_transaction_screen.dart`](lib/screens/add_transaction_screen.dart)):
  - Menghilangkan ikon tong sampah dari header bar pojok kanan atas.
  - Mengubah aksi tombol bawah saat edit transaksi menjadi layout 2 kolom berdampingan: kolom kiri tombol bahaya "Hapus" (`OutlinedButton` merah `#FF6B7A`), kolom kanan tombol utama "Simpan" (`ElevatedButton`).
  - Mengubah modal konfirmasi hapus transaksi dari `AlertDialog` bawaan menjadi `showModalCardSheet` (bottom sheet terstandarisasi dengan ikon peringatan merah dan opsi "Batal" vs "Hapus Permanen").
- [x] Redesain Kartu Onboarding Profil Anti-Slop ([`lib/screens/onboarding_profile_screen.dart`](lib/screens/onboarding_profile_screen.dart)):
  - Menerapkan komponen `NestedCard` pada form data profil (Nama, No Telp, Gender) sesuai panduan desain anti-slop.
  - Memasang logo resmi Yotro di bagian atas kartu profil.
- [x] Preferensi Tampilan Menjadi Modal Bottom Sheet ([`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart)):
  - Mengganti navigasi ke halaman baru dengan modal bottom sheet interaktif `showModalCardSheet`.
  - Menampilkan 3 pilihan mode tampilan beranda (`Complete View`, `Pemasukan dan Pengeluaran`, `Pengeluaran saja`) lengkap dengan radio checkmark, badge, dan deskripsi ringkas.
- [x] Sistem SnackBar High-Contrast Global Anti-Slop ([`lib/widgets/app_snackbar.dart`](lib/widgets/app_snackbar.dart) & [`lib/theme/app_theme.dart`](lib/theme/app_theme.dart)):
  - Memasang konfigurasi tema `snackBarTheme` di Dark Mode dan Light Mode: latar `#131A26`, border `#2A3545`, teks putih tebal (`#FFFFFF`), sudut melengkung 14px, dan `behavior: SnackBarBehavior.floating`.
  - Membuat helper `AppSnackBar.show(...)` dengan ikon status beresolusi tinggi (`#34D399` success, `#FF6B7A` danger, `#55C7FF` info, `#FBBF24` warning) sehingga teks snackbar terbaca jelas di seluruh mode tema.
- [x] Integrasi Logo Resmi Yotro di Seluruh Platform:
  - Menyimpan aset logo resmi di `assets/images/` (`logo_white_blue.png`, `logo_blue_transparent.png`, `logo_white_black.png`, `logo.png`).
  - Menghasilkan launcher icons Android beresolusi lengkap (`mipmap-mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
  - Memperbarui `SplashScreen` dan `OnboardingProfileScreen` dengan logo resmi Yotro.
  - Menghasilkan web favicon (`web/favicon.png`) dan icons (`web/icons/Icon-192.png`, `Icon-512.png`, maskable).
- [x] Halaman Notifikasi Spacing & Konsistensi Terstandarisasi ([`lib/screens/notifications_center_screen.dart`](lib/screens/notifications_center_screen.dart)):
  - Mengganti custom app bar dengan `StandardScreenHeader(title: 'Notifikasi')`.
  - Spacing vertikal dan horizontal terstandarisasi 12px universal selaras dengan seluruh layar aplikasi.
  - Badge arah mutasi berwarna dinamis: Hijau untuk Uang Masuk, Koral untuk Pengeluaran, dan Cyan untuk Transfer.
- [x] Pembaca Notifikasi Cerdas & Edit Aturan Pemicu/Abaikan untuk build internal ([`lib/screens/notification_reader_screen.dart`](lib/screens/notification_reader_screen.dart) & [`lib/models/notification_rule_model.dart`](lib/models/notification_rule_model.dart)):
  - Modal edit aturan (`_showEditRuleModal`): pengguna dapat mengubah kata kunci pemicu (*triggers*), kata kunci abaikan (*anti-promo*), dompet tujuan, dan kategori default.
  - Pemilih semua aplikasi terpasang (`installed_apps`) telah dihapus dari build aman untuk menghindari broad package visibility.
  - Deteksi cerdas arah mutasi transaksi: `TransactionType.income` vs `TransactionType.expense` vs `TransactionType.transfer`.
- [x] Cadangan & Pemulihan Data Offline Nyata ([`lib/services/backup_storage_service.dart`](lib/services/backup_storage_service.dart) & [`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart)):
  - Bottom sheet konfirmasi cadangan data terlebih dahulu sebelum ekspor.
  - Unduh berkas `.json` nyata (`yotro_backup_YYYYMMDD_HHMM.json`) via Blob/Anchor download di Web dan system share sheet di Android/iOS.
  - Pemulihan data mendukung unggah/pilih berkas `.json` dari penyimpanan HP via `FilePicker` di samping opsi tempel teks JSON.
- [x] Aktivitas Transaksi Dual Bar Chart di Beranda ([`lib/widgets/weekly_activity_chart.dart`](lib/widgets/weekly_activity_chart.dart) & [`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart)):
  - Menggantikan "Aktivitas Pengeluaran" menjadi "Aktivitas Transaksi" dengan chart batang berdampingan (*side-by-side grouped bar chart*).
  - Bar Hijau (`#34D399`) untuk Pemasukan dan Bar Koral (`#FF6B7A`) untuk Pengeluaran per hari (Sen–Min).
  - Floating tooltip responsif menampilkan nominal masuk dan keluar secara terpisah tanpa overflow.
  - Otomatis disembunyikan (*Empty State*) jika tidak ada transaksi pada minggu berjalan (`SizedBox.shrink()`).
- [x] Preferensi Tampilan Mode Pengeluaran Saja & Tombol Simpan ([`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart) & [`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart)):
  - Pada mode `DashboardViewMode.expenseOnly`, kartu hero di Beranda menampilkan nominal besar "Total Pengeluaran" (`provider.totalExpense`) menggantikan "Saldo saat ini", dan sub-kartu pengeluaran/pemasukan di bawahnya disembunyikan.
  - Pada modal preferensi tampilan, pemilihan mode membutuhkan klik tombol "Simpan Preferensi" untuk menerapkan perubahan.
- [x] Pengingat Transaksi Harian via Bottom Sheet & Multi-Alarm ([`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart) & [`lib/providers/transaction_provider.dart`](lib/providers/transaction_provider.dart)):
  - Tombol jam inline dihilangkan dari list baris profil.
  - Mengetuk baris membuka modal bottom sheet `_showDailyReminderSheet` yang mendukung beberapa alarm sekaligus (default jam `18:00` dan `19:00`), tombol tambah jam alarm via `TimePicker`, dan hapus alarm.
- [x] Menu Analisis di Beranda Membuka Full-Height Bottom Sheet ([`lib/screens/financial_analysis_screen.dart`](lib/screens/financial_analysis_screen.dart) & [`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart)):
  - Mengetuk tombol aksi cepat "Analisis" di Beranda membuka modal bottom sheet setinggi ~94% layar lengkap dengan drag handle, selector bulan, dan tombol tutup silang (`Icons.close_rounded`).
- [x] Resolusi instalasi Android dan Play Protect ([`pubspec.yaml`](pubspec.yaml), manifest release, dan signing config):
  - Version dinaikkan ke `1.0.3+4`, memakai release signing konsisten dan izin minimum.
  - Tidak mengarahkan pengguna untuk melewati Restricted Settings atau menonaktifkan Play Protect; fitur sensitif dinonaktifkan pada build publik.
- [x] Spacing Angka Pengeluaran Mode `expenseOnly` ([`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart)):
  - Ditambahkan `SizedBox(height: 14)` di bawah nominal display pada mode pengeluaran saja agar teks angka tidak mepet tepi bawah kartu hero.
- [x] Interaksi Tooltip Chart Berdasarkan Klik ([`lib/widgets/weekly_activity_chart.dart`](lib/widgets/weekly_activity_chart.dart)):
  - Default `_selectedDayIndex` diatur `null`, tooltip mengambang hanya muncul saat bar hari tertentu diketuk pengguna (toggle aktif/nonaktif).
  - Bar dual menggunakan `Expanded` di dalam Row untuk membagi ruang secara presisi tanpa overflow.
- [x] Penyatuan Filter Bulan & Tanggal Riwayat Transaksi ([`lib/screens/transactions_screen.dart`](lib/screens/transactions_screen.dart)):
  - Tombol filter bulan dan tanggal digabung menjadi 1 chip filter waktu terpadu di baris pertama.
  - Membuka `showModalCardSheet` dengan tab segmentasi "Berdasarkan Bulan" (chip bulan) dan "Tanggal Spesifik" (`CalendarDatePicker` bertema gelap).
- [x] Restrukturisasi Halaman Notifikasi & Anti-Slop Copywriting ([`lib/screens/notifications_center_screen.dart`](lib/screens/notifications_center_screen.dart) & [`lib/providers/transaction_provider.dart`](lib/providers/transaction_provider.dart)):
  - Menghilangkan duplikasi card pengaturan pengingat harian dan pembaca notifikasi.
  - Menampilkan 2 bagian esensial: "Persetujuan Transaksi" (antrean verifikasi) dan "Aktivitas Transaksi" (log notifikasi transaksional faktual, misal "Catat Pengeluaran Berhasil").
- [x] Default Bar Today Menyala di Chart Aktivitas & Laporan ([`lib/widgets/weekly_activity_chart.dart`](lib/widgets/weekly_activity_chart.dart)):
  - Bar hari ini (`todayIndexInWeek`) otomatis aktif/menyala beserta tooltip informasinya saat pertama dibuka, baik di Beranda (Aktivitas Transaksi) maupun Laporan Keuangan (Aktivitas Pengeluaran).
  - Mengetuk hari lain berpindah fokus ke hari tersebut secara interaktif.
- [x] Resolusi Kompilasi SDK & Google Play Restricted Settings ([`android/app/build.gradle`](android/app/build.gradle) & [`pubspec.yaml`](pubspec.yaml)):
  - Target SDK distandarkan ke `targetSdkVersion 34` (Android 14) dan `compileSdk = 37` (mendukung plugin terbaru).
  - Version code dinaikkan ke `version: 1.0.3+4`.
- [x] Kompilasi Ulang & Testing Komprehensif:
  - Seluruh 62 test suite lolos 100% tanpa error (`flutter test`).
  - Flutter Web release berhasil di-compile ke `build/web/`.
  - Android release APK ter-compile ke `yotro-release.apk` dan `build/web/yotro-release.apk` (v1.0.3+4, 60MB).
- [x] Inisialisasi Git & First Commit Push (https://github.com/ianfrds/yotroapp.git):
  - Repository git diinisialisasi, branch utama `main`.
  - Berkas build biner (`*.apk`, `*.sha256`, `.dart_tool/`) diabaikan via [`.gitignore`](.gitignore).
  - First commit berhasil di-push ke remote `origin/main`.
- [x] Redesain Layar Onboarding Profil Anti-Slop (Layout Gambar 3 & Background Kaca Safir) ([`lib/screens/onboarding_profile_screen.dart`](lib/screens/onboarding_profile_screen.dart)):
  - Menghilangkan nesting card berlapis yang terkesan AI slop, mengadopsi struktur bersih dua zona sesuai referensi gambar 3.
  - Header atas menampilkan background visual kaca berusuk biru (`assets/images/onboarding_bg.jpg`) dengan gradien gelap, logo resmi Yotro, dan judul ramah "Selamat Datang".
  - Zona bawah berupa card mengambang dengan sudut atas melengkung 32px (`BorderRadius.vertical(top: Radius.circular(32))`), input pill terpadu beradius 16px (Nama Lengkap, Nomor Telepon), segment chip Pria/Wanita, callout izin notifikasi otomatis, dan tombol utama pill stadium "Mulai Aplikasi".
- [x] Reaktivasi Pembaca Notifikasi Dasar & Panduan Setelan Terbatas Android 13/14 ([`lib/config/app_capabilities.dart`](lib/config/app_capabilities.dart), [`lib/services/native_notification_service.dart`](lib/services/native_notification_service.dart), [`lib/providers/transaction_provider.dart`](lib/providers/transaction_provider.dart), & [`lib/screens/notification_reader_screen.dart`](lib/screens/notification_reader_screen.dart)):
  - Mengaktifkan kembali `notificationReaderEnabled` secara default pada platform Android dengan kapabilitas dasar, lokal, dan aman.
  - Menghapus overlay manifest release pembatasan listener sehingga service terpasang dengan semestinya saat diinstal dari APK luar Play Store.
  - Menambahkan dynamic fallback deteksi: notifikasi perbankan/e-wallet dengan tanda mata uang (Rp / IDR) dan kata kunci transaksi otomatis tertangkap dan diproses tanpa harus membuat aturan manual terlebih dahulu.
  - Menambahkan panduan modal bottom sheet dan tautan bantuan khusus Android 13 & 14+ untuk mengatasi peringatan sistem "Aplikasi tidak diberi akses" (Setelan Terbatas / Restricted Settings).
- [x] Standarisasi Kategori Default 100% Bahasa Indonesia ([`lib/models/category_model.dart`](lib/models/category_model.dart) & [`lib/providers/transaction_provider.dart`](lib/providers/transaction_provider.dart)):
  - Mengubah seluruh kategori bawaan pengeluaran dan pemasukan ke Bahasa Indonesia murni (Makanan & Minuman, Transportasi, Belanja, Tempat Tinggal, Tagihan & Utilitas, Kesehatan, Hiburan, Pendidikan, Gaya Hidup, Gaji, Pekerjaan Lepas, Bisnis & Usaha, Investasi, Hadiah & Bonus, Lainnya).
  - Menyediakan normalizer nama kategori otomatis untuk kompatibilitas data lama.
- [x] Tambah & Ubah Kategori via Full-Height Modal Bottom Sheet ([`lib/screens/edit_category_screen.dart`](lib/screens/edit_category_screen.dart) & [`lib/screens/manage_categories_screen.dart`](lib/screens/manage_categories_screen.dart)):
  - Aksi tambah dan ubah kategori pada Kelola Kategori kini membuka modal bottom sheet setinggi 94% layar dengan handle geser dan sudut atas melengkung 24px (`EditCategoryScreen.showAsModalSheet`), menggantikan perpindahan halaman baru.
- [x] Perluasan Katalog Emoji & Pemisahan Berdasarkan Kategori ([`lib/utils/icon_catalog.dart`](lib/utils/icon_catalog.dart) & [`lib/screens/edit_category_screen.dart`](lib/screens/edit_category_screen.dart)):
  - Menambahkan katalog emoji terkurasi hingga ~180 pilihan emoji finansial dan gaya hidup.
  - Memisahkan emoji ke dalam kategori terstruktur (Makanan, Transportasi, Belanja, Tagihan, Kesehatan, Hiburan, Keuangan, Edukasi, Keluarga, Lainnya).
  - Menyediakan chip filter kategori horizontal dan tampilan grouped sections dengan sub-heading kategori yang rapi.
- [x] Tombol Logout & Reset Onboarding untuk Uji Coba Web ([`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart), [`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart), & [`lib/providers/transaction_provider.dart`](lib/providers/transaction_provider.dart)):
  - Menyediakan tombol "Logout" di header Beranda khusus tampilan web (`kIsWeb`) dan di Zona Bahaya Pengaturan untuk mereset `isOnboardingCompleted = false` via bottom sheet konfirmasi.
  - Memudahkan user menguji langsung form identitas onboarding yang baru diredesain pada `http://localhost:8080/`.
- [x] Kompilasi Ulang Web Release & Testing Komprehensif:
  - Seluruh 63 test suite lolos 100% (`flutter test`).
  - Web release berhasil dikompilasi ke `build/web/` dan aktif disajikan di `http://localhost:8080/`.
- [x] Redesain Progress Bar Batas Budget Bulanan Semicircular Speedometer Gauge ([`lib/widgets/semicircle_budget_gauge.dart`](lib/widgets/semicircle_budget_gauge.dart) & [`lib/screens/budget_screen.dart`](lib/screens/budget_screen.dart)):
  - Mengganti linear progress bar datar dengan semicircular speedometer gauge arc 180° beresolusi tinggi sesuai referensi gambar user.
  - Header rentang tanggal dinamis terpusat (`01/MM/yyyy - LastDay/MM/yyyy`).
  - Arc track abu-abu/slate dengan stroke cap membulat, arc progress dinamis (biru safir < 80%, amber waspada 80-99%, merah bahaya ≥ 100%), serta indikator thumb knob lingkaran putih bergaris tepi warna aktif di ujung busur.
  - Area dalam kubah menampilkan label "Anggaran Tersisa", display nominal sisa anggaran berukuran besar (Inter Tight 26px bold), dan pill chip bergaris merah/coral "X Hari Lagi".
  - Sub-card bawah dengan wadah rounded memisahkan 2 kolom rata tengah ("Total Anggaran" & "Terpakai") menggunakan pembatas garis titik-titik vertikal (dotted vertical divider).
- [x] Penghapusan Total Fitur Pembaca Notifikasi Demi Keamanan Sideload APK ([`pubspec.yaml`](pubspec.yaml), [`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml), [`lib/config/app_capabilities.dart`](lib/config/app_capabilities.dart), [`lib/services/native_notification_service.dart`](lib/services/native_notification_service.dart), [`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart)):
  - Menghapus dependensi `notification_listener_service` dan `installed_apps` dari `pubspec.yaml`.
  - Menghapus deklarasi service `notification.listener.service.NotificationListener` dan izin `BIND_NOTIFICATION_LISTENER_SERVICE` dari `AndroidManifest.xml`.
  - Menghapus menu "Pembaca Notifikasi" dari Pengaturan dan tombol navigasinya dari header Notifikasi.
  - Menghapus berkas `notification_reader_screen.dart`.
  - Aplikasi kini 100% bebas dari izin berbahaya, tidak akan memicu peringatan Android "Aplikasi tidak diberi akses" (*Restricted Settings*), dan 100% aman untuk instalasi APK di luar Play Store.
- [x] Redesain Layar Onboarding Profil Full-Background & Anti-Slop ([`lib/screens/onboarding_profile_screen.dart`](lib/screens/onboarding_profile_screen.dart)):
  - Menghilangkan cutoff gambar 280px dan gradien pekat yang memotong wallpaper di tengah layar.
  - Memasang background wallpaper kaca berusuk biru (`assets/images/onboarding_bg.jpg`) full screen dengan gradien transparan lembut agar tekstur kaca terlihat menyeluruh.
  - Form profil dikemas dalam floating frosted matte card dengan efek `BackdropFilter` (blur 18px), border halus, dan padding bawah dinamis aman (`MediaQuery.of(context).padding.bottom + 28px`) sehingga tidak terpotong tombol gesture bar HP.
- [x] Pembersihan Mock Data & Empty State Menyeluruh ([`lib/screens/analytics_screen.dart`](lib/screens/analytics_screen.dart) & [`lib/screens/financial_analysis_screen.dart`](lib/screens/financial_analysis_screen.dart)):
  - Menghilangkan mock data kategori statis (Food & Beverage Rp 320.000 & Salary Rp 4.000.000) saat belum ada transaksi.
  - Layar Laporan Keuangan menampilkan kartu empty state bersih "Belum ada rincian transaksi pengeluaran/pemasukan".
  - Layar Analisis Keuangan menampilkan empty state mandiri "Belum Ada Data Analisis" saat transaksi nol, tanpa memunculkan skor kesehatan semu atau proyeksi fiktif.
- [x] Restorasi Emoji Melambai 👋 di Header Beranda ([`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart)):
  - Menyematkan emoji `👋` tepat setelah nama pengguna pada sapaan Beranda (misal "Ian Firdaus 👋").
- [x] Multi-Alarm Pengingat Transaksi Otomatis Aktif & Jam Bawaan Dapat Diedit ([`lib/providers/transaction_provider.dart`](lib/providers/transaction_provider.dart) & [`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart)):
  - Pengingat harian otomatis aktif (`isDailyReminderEnabled = true`) sesaat setelah izin notifikasi sistem diberikan (baik di onboarding maupun peluncuran pertama).
  - Setiap slot alarm bawaan (18:00 dan 19:00) pada modal bottom sheet kini dapat diketuk langsung untuk mengubah jam via `showTimePicker` lengkap dengan ikon edit.
  - Memperbaiki layout row judul alarm dengan `Expanded` untuk mencegah overflow pada layar perangkat sempit.
- [x] Restorasi Linear Progress Bar Anggaran & Eliminasi Rentang Tanggal / Sisa Hari ([`lib/screens/budget_screen.dart`](lib/screens/budget_screen.dart) & [`lib/screens/budget_detail_screen.dart`](lib/screens/budget_detail_screen.dart)):
  - Mengembalikan tampilan kartu batas budget keseluruhan ke desain linear progress bar bersih dan teruji (tanpa semicircle speedometer gauge).
  - Menghilangkan tampilan rentang tanggal dan sisa hari dari kartu budget maupun ringkasan rincian anggaran.
  - Memastikan seluruh perhitungan total anggaran, nominal terpakai, sisa saldo, dan persentase 100% dinamis terhubung ke `TransactionProvider`.
- [x] Layar Rincian Anggaran Interaktif & Fungsional Penuh ([`lib/screens/budget_detail_screen.dart`](lib/screens/budget_detail_screen.dart) & [`lib/screens/budget_screen.dart`](lib/screens/budget_screen.dart)):
  - Menghilangkan sifat statis pada halaman budget: mengetuk item budget per kategori atau kartu budget keseluruhan membuka layar Rincian Anggaran interaktif (`BudgetDetailScreen`).
  - Kartu ringkasan atas: avatar kategori dengan badge panah merah, nama kategori/semua pengeluaran, nominal total budget, serta row status `Terpakai : Rp xxx` dan `Sisa : Rp xxx`.
  - Bagian "Statistik Penggunaan Anggaran": grafik batang interaktif pengeluaran harian dengan skala sumbu Y bertingkat dan garis bantu horizontal putus-putus (*dashed lines*). Mengetuk batang menampilkan tooltip tanggal dan nominal detail.
  - Bagian "Riwayat Transaksi": daftar transaksi pengeluaran kategori pada bulan berjalan lengkap dengan tanggal relatif, nominal negatif, dan navigasi langsung ke ubah transaksi saat diketuk.
  - Menu titik tiga (`...`) di pojok kanan atas menyediakan aksi cepat ubah budget dan hapus budget kategori dengan dialog konfirmasi aman.
- [x] Normalisasi Kategori & Grafik Batang Dinamis 100% Bebas Data Statis ([`lib/screens/budget_detail_screen.dart`](lib/screens/budget_detail_screen.dart), [`lib/models/category_model.dart`](lib/models/category_model.dart), [`lib/screens/budget_screen.dart`](lib/screens/budget_screen.dart)):
  - Memperluas `CategoryModel.normalizeCategoryName` untuk mencocokkan variasi penamaan Bahasa Indonesia dan Inggris secara dua arah ('Makanan', 'Makanan & Minuman', 'Food & Beverage', dsb).
  - Menghilangkan filter tanggal terbatas yang sebelumnya menyebabkan transaksi tidak muncul pada kartu rincian anggaran.
  - Menambahkan perhitungan skala sumbu Y dinamis (`_calculateNiceScaleMax`) dengan kelipatan bersih (50K, 100K, 250K, 500K, 1M, dst.).
  - Memisahkan plot batang (tinggi presisi sejajar garis 0) dari label sumbu X di bawahnya agar batang mendarat sempurna pada garis baseline.
  - Interaksi tap batang grafik memfilter daftar "Riwayat Transaksi" secara instan ke tanggal terpilih, dan menampilkan tombol "Lihat Semua" untuk membatalkan filter.
  - Menambahkan empty state grafik informatif dengan tombol "+ Catat Transaksi" yang otomatis mem-prefill kategori terkait (`initialCategory`).
- [x] Refaktor Form Tambah Transaksi Anti-Slop ([`lib/screens/add_transaction_screen.dart`](lib/screens/add_transaction_screen.dart)):
  - Mengganti deretan chip shortcut nominal statis (`+10rb`, `+20rb`, dsb) di kartu Nominal dengan field input "Catatan / Judul" (`_titleController`) berdesain bersih matte.
  - Menghapus duplikasi field catatan/judul dari kartu detail transaksi, menyisakan pemilih tanggal transaksi yang ringkas dan bebas AI slop.
- [x] Kompilasi Signed Release APK Bersih & Sinkronisasi Web Runner:
  - APK bersih berhasil dibangun ke [`yotro-app.apk`](yotro-app.apk) dan `build/web/yotro-app.apk` (61.3 MB).
  - Web runner dan preview di `http://localhost:8080/` diperbarui.
  - Seluruh 74 unit & widget test lolos 100% (`flutter test`).
- [x] Fitur Advanced Split Bill Multi-Mode & Kustomisasi Pajak/Tip ([`lib/screens/split_bill_screen.dart`](lib/screens/split_bill_screen.dart)):
  - 3 mode pembagian: Bagi Rata (Equal), Bagi Kustom (alokasi manual + tombol Bagi Sisa Rata), dan Per Item (input menu pesanan, kuantitas, dan penugasan per anggota dengan pembagian pajak/service proporsional adil).
  - Pajak & Service Tip dapat diaktifkan/dinonaktifkan via switch, didukung preset chip cepat dan opsi Kustom (% persentase kustom atau Rp nominal kustom via modal sheet).
  - Standardisasi desain tombol aksi sesuai gaya aplikasi (`ElevatedButton` sapphire `#0066FF`, `OutlinedButton` radius 14px, tinggi 48px).
- [x] Penyempurnaan Form Input Item Split Bill & Anti-Overflow ([`lib/screens/split_bill_screen.dart`](lib/screens/split_bill_screen.dart)):
  - Standarisasi tinggi container `Harga Satuan` dan `Jumlah / Qty` menjadi seragam `48px` dengan border radius `12px` dan border matte halus.
  - Prefix "Rp" rapi dan teks field nominal terpusat vertikal (`TextAlignVertical.center`), dilengkapi kalkulasi subtotal dinamis real-time saat kuantitas > 1 (`Total Item: Rp ...`).
  - Mencegah overflow horizontal pada daftar item pesanan menggunakan `Flexible` dan `TextOverflow.ellipsis`.
- [x] Penyejajaran Presisi Icon Preview & Form Nama Kategori ([`lib/screens/edit_category_screen.dart`](lib/screens/edit_category_screen.dart)):
  - Memindahkan label "Nama Kategori" ke atas baris formulir.
  - Menyejajarkan kotak preview icon/emoji (`48x48px`) dan input field nama kategori (`height: 48px`) dalam satu `Row` rata tengah (`CrossAxisAlignment.center`) dengan sudut membulat `12px` identik.
- [x] Redesain & Polishing Layar Transaksi Berhasil Dicatat ([`lib/screens/transaction_success_screen.dart`](lib/screens/transaction_success_screen.dart)):
  - **Animasi Rosette Checklist Sesuai Referensi:** Mengganti lingkaran glow dengan badge bunga/roset 8-lekukan (*8-lobed scalloped badge*) berwarna hijau limau lembut (`#C4F988`) dan centang hijau tua tebal (`#005928`), menghilangkan efek pendaran AI slop, dan mempertahankan animasi pop-in spring & path checkmark.
  - **Auto-Redirect 5 Detik Hening:** Otomatis kembali ke Beranda setelah 5 detik tanpa menampilkan teks countdown.
  - **Penyelarasan Kolom & Spacing Rapat:** Icon dibungkus wadah tetap 22px sehingga teks label (Dompet, Kategori, Tipe, Waktu) rata vertikal persis, nilai kanan diperlebar fleksibel (tanpa terpotong ellipsis), dan jarak antar-baris dirapatkan menjadi 8px.
  - **Disiplin Tipografi Semibold:** Menghapus seluruh bobot bold/w700/w800, dibatasi maksimal `FontWeight.w600` (semibold) pada judul, nominal, dan isi.
  - **Standardisasi Tombol Reusable:** Tombol primer "Kembali ke Beranda" menggunakan Sapphire Blue (`#0066FF`), tombol sekunder "Catat Transaksi Lain" menggunakan `OutlinedButton`, keduanya seragam tinggi 48px dan radius 14px.
- [x] Penghapusan Tombol Keluar Akun & Penyesuaian Reset Data Bawaan ([`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart), [`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart), [`lib/providers/transaction_provider.dart`](lib/providers/transaction_provider.dart)):
  - Menghapus tombol "Keluar Akun (Uji Onboarding)" dari layar Pengaturan (Zona Bahaya) dan Beranda agar rilis APK bersih tanpa tombol logout uji coba.
  - Memperbarui tombol "Reset ke Data Bawaan": menyetel nama pengguna default ke **"John Doe"** dan mengisi dataset realistis yang banyak (17 transaksi berbagai tanggal, 4 dompet aktif, dan 5 limit budget kategori).
- [x] Redesain Total Onboarding Profile Anti-Scroll ([`lib/screens/onboarding_profile_screen.dart`](lib/screens/onboarding_profile_screen.dart)):
  - Tampilan dirancang compact (~410px total tinggi kartu) yang pas di seluruh layar handphone tanpa perlu scrolling (*zero-scroll*).
  - Mengikuti referensi visual: logo/emblem di atas, judul "Selamat Datang", subjudul ringkas 1 baris, kartu mengambang frosted (`#0E1726`), input "Nama Lengkap *", input "Nomor Telepon (Opsional)", dan tombol utama "Mulai Aplikasi" (Sapphire `#0066FF`, 48px, radius 12px, semibold).
  - Menghapus elemen penggelembung (callout izin notifikasi & selector gender) dan menyertakan disclaimer 1 baris elegan di bawah kartu: *"Seluruh data tersimpan 100% aman di perangkat lokal."*
- [x] Pencegahan Overflow Layar Finansial & Grafik Anggaran ([`lib/screens/financial_analysis_screen.dart`](lib/screens/financial_analysis_screen.dart), [`lib/screens/budget_detail_screen.dart`](lib/screens/budget_detail_screen.dart)):
  - Membungkus label status meter skor (`Kritis`, `Waspada`, `Sehat`) dalam `Flexible` ber-`TextOverflow.ellipsis` agar aman di viewport sempit.
  - Membatasi rentang grafik batang pengeluaran di `BudgetDetailScreen` ke maksimal 7 hari aktif terbaru dan menyelaraskan batang serta label tanggal X-axis dengan `Expanded` dan `FittedBox` sehingga bebas dari RenderFlex overflow.
- [x] Empty State Anggaran & Penyembunyian Kartu Keseluruhan saat Kosong ([`lib/screens/budget_screen.dart`](lib/screens/budget_screen.dart)):
  - Menyembunyikan kartu "Batas Budget Keseluruhan" jika batas budget keseluruhan belum disetup (`overallLimit <= 0`).
  - Menampilkan Empty State bersih dan anti-slop saat tidak ada budget keseluruhan maupun budget kategori yang disetup, lengkap dengan tombol "Atur Anggaran Bulanan" dan "Tambah Budget Kategori".
- [x] Filter Bulanan Bottom Sheet (Month & Year Picker) di Beranda ([`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart), [`lib/providers/transaction_provider.dart`](lib/providers/transaction_provider.dart)):
  - Mengganti dropdown statis di kartu hero Beranda dengan filter pill bulan interaktif (`Nov 2026 ∨`) yang membuka bottom sheet "Filter Bulanan" sesuai referensi visual.
  - Tampilan grid 12 bulan (4 kolom x 3 baris), pill seleksi biru sapphire (`#2563EB`), navigasi tahun dengan chevron `<` dan `>`, serta tombol aksi `Batal` (outlined pill) dan `Kirim` (elevated pill).
  - Terintegrasi dengan `provider.selectedDashboardMonth`, `provider.dashboardMonthExpense`, dan `provider.dashboardMonthIncome` untuk kalkulasi dinamis.
- [x] Pembersihan Teks Profil & Perbaikan Kontras Light Mode Menyeluruh:
  - Menghapus tulisan "100% Offline & Privat" dari kartu Profil Pengguna di [`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart).
  - Memperbaiki kontras teks peringatan (amber/crimson) dan tombol "Batalkan" pada seluruh modal sheet di light mode (`settings_screen.dart`, `manage_categories_screen.dart`, `wallets_screen.dart`, `budget_screen.dart`, `budget_detail_screen.dart`) agar 100% memenuhi standar aksesibilitas WCAG.
- [x] Unit & Widget Test Komprehensif:
  - Membuat [`test/month_filter_and_budget_empty_test.dart`](test/month_filter_and_budget_empty_test.dart) untuk memverifikasi interaksi filter bulanan dan empty state budget.
  - Seluruh 80 unit dan widget test lulus 100% (`flutter test`).
- [x] Kompilasi Ulang Web Release & Signed Release APK:
  - Web release diperbarui di `build/web/` dan live preview port `8080`.
  - Android release APK diperbarui di [`yotro-app.apk`](yotro-app.apk) dan `build/web/yotro-app.apk`.
- [x] Perapihan Bottom Sheet Filter Bulanan Beranda & Penyelarasan Tombol ([`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart)):
  - Pemilih tahun ditempatkan di tengah (*center aligned*) diapit sepasang tombol chevron: `< 2026 >`. Tahun kini interaktif (*clickable*) dengan dropdown indicator dan membuka dialog `YearPicker` untuk memilih tahun instan.
  - Penyeimbangan tombol "Bulan Ini": Tombol dipindahkan dari header ke posisi **tengah (*center-aligned*) di bawah grid 12 bulan** di dalam kartu pemilih (`Center(child: OutlinedButton.icon(...))`), menciptakan simetri visual sempurna dan menghilangkan ketidakseimbangan visual pada modal.
  - Menggunakan gaya stadium border, ikon `Icons.restore_rounded`, stroke halus bertema sapphire/dark slate, dan tipografi `Manrope` semibold.
  - Tombol aksi di bagian bawah dibuat melebar penuh kiri-ke-kanan (*full width* 50/50): tombol `Batal` di sebelah kiri (`OutlinedButton`) dan tombol `Simpan` di sebelah kanan (`ElevatedButton` sapphire blue).
- [x] Penghapusan Teks Jam pada Kartu Pengingat Harian Beranda ([`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart)):
  - Menghapus teks jam / pukul (seperti "Pukul 20:00" atau "20.00") dari kartu "Pengingat Transaksi Harian" saat belum ada transaksi hari ini, sehingga kartu tampil bersih dan minimalis.
- [x] Penyeragaman Filter Riwayat Transaksi Lengkap & Pengelompokan Per Tanggal ([`lib/screens/transactions_screen.dart`](lib/screens/transactions_screen.dart)):
  - Memperpendek teks placeholder pemicu filter tanggal menjadi ringkas: **"Semua Periode"** (menggantikan teks panjang sebelumnya).
  - Mengganti input pencarian statis dengan tombol ikon search di pojok kanan atas App Bar. Kolom input pencarian otomatis muncul dengan autofocus hanya saat ikon search diketuk (*expandable on demand*).
  - Menghilangkan teks jumlah transaksi (seperti "10 transaksi") pada header kartu "Daftar Transaksi".
  - Mengelompokkan seluruh riwayat transaksi **per tanggal** (Hari Ini, Kemarin, Nama Hari + Tanggal) dengan header tanggal bersih, pembatas halus, dan rekap total pengeluaran harian di sebelah kanan.
  - Tiga tab segmen interaktif yang responsif dan bebas overflow (*fitted*):
    - **Bulan & Tahun:** Navigasi tahun tengah `< YYYY >` (dapat diklik untuk pilih tahun via dialog `YearPicker`), grid 12 bulan (Jan–Des) dengan capsule selection sapphire `#2563EB`, serta opsi tombol cepat "Pilih 1 Tahun Penuh (YYYY)".
    - **Tanggal Spesifik:** Kalender pemilih tanggal harian presisi dengan badge ringkasan "Dipilih: DD MMMM YYYY".
    - **Rentang Tanggal:** Preset cepat (7 Hari, 30 Hari, Bulan Ini, Bulan Lalu), kartu tanggal "Mulai" dan "Selesai", tombol buka kalender rentang (`showDateRangePicker`), serta badge durasi hari.
  - Tombol aksi bawah seragam full width: `Batal` (reset ke Semua Periode) dan `Simpan` (terapkan filter).
  - Baris pemicu filter pada halaman utama riwayat menampilkan label dinamis sesuai filter aktif (`Tahun: ...`, `Bulan: ...`, `Tanggal: ...`, `Rentang: ...`) dilengkapi tombol cepat hapus (X).
- [x] Pengujian Unit & Widget Komprehensif (85 Tests Passed):
  - Memperbarui [`test/month_filter_and_budget_empty_test.dart`](test/month_filter_and_budget_empty_test.dart) untuk verifikasi tombol `Simpan`.
  - Membuat [`test/transactions_filter_unified_test.dart`](test/transactions_filter_unified_test.dart) menguji filter riwayat lengkap.
  - Membuat [`test/financial_analysis_ux_test.dart`](test/financial_analysis_ux_test.dart) menguji tombol panduan analisis, bahasa awam kesehatan keuangan, kuota anggaran, dan bridge banner dari tab Laporan Keuangan.
  - Seluruh 85 tests lolos 100% (`flutter test`).
- [x] Perombakan UX & Bahasa Awam Analisis Keuangan ([`lib/screens/financial_analysis_screen.dart`](lib/screens/financial_analysis_screen.dart) & [`lib/screens/analytics_screen.dart`](lib/screens/analytics_screen.dart)):
  - **Bahasa Manusiawi & Ramah Awam**: Menghilangkan jargon akademis/perbankan kaku:
    - *Tabungan*: "Target >20%" (ringkas, padat).
    - *Rasio Beban*: "Aman <70%".
    - *Arus Kas*: "Surplus" / "Defisit".
    - *Rata-rata Harian*: "Pengeluaran per hari".
    - *Proyeksi Akhir Bulan*: "Perkiraan akhir bulan".
    - *Diagnosa*: "Catatan & Saran Keuangan" bertutur santun dan solutif.
  - **Solusi Anti-Truncation & Text Overflow (Bebas Teks Terpotong)**:
    - *Kompensasi Ruang Sempit*: Menghilangkan `maxLines: 1` kaku pada pod metrik, mengizinkan pembungkusan teks alami hingga 2 baris (`maxLines: 2, height: 1.15`).
    - *Tile Arus Kas Masuk vs Keluar*: Mengganti baris horizontal tunggal yang sempit menjadi 2 kartu mini berdampingan (`Uang Masuk` dan `Uang Keluar`) dengan pembungkus `FittedBox` sehingga nominal besar tidak pernah terpotong tanda elipsis (`...`).
    - *FittedBox pada Nilai Anggaran & Kategori Terbanyak*: Nominal rupiah menyesuaikan skala otomatis pada layar sempit.
  - **Tombol Panduan Analisis (?)**: Tombol bantuan di header yang membuka lembar penjelasan interaktif mengenai arti setiap skor dan metrik.
  - **Progress Meter 4 Zona**: Penanda visual intuitif (Kurang <50, Waspada 50-65, Aman 65-80, Sangat Baik >80).
  - **Kartu Pantauan Anggaran**: Menampilkan realisasi budget bulanan, status persentase, dan rekomendasi kuota belanja harian yang aman per hari hingga akhir bulan. Jika budget belum disetel, menyediakan tombol cepat "Pasang".
  - **Bridge UX Tab Laporan**: Banner mini interaktif "Cek Analisis Finansial & Saran" pada tab Laporan Keuangan untuk navigasi mulus langsung ke lembar analisis.
- [x] Standardisasi Warna Primary Button Seluruh Aplikasi & Penataan Vertikal Layar Transaksi Berhasil:
  - **Layar Transaksi Berhasil ([`lib/screens/transaction_success_screen.dart`](lib/screens/transaction_success_screen.dart))**: Konten di-center vertikal secara elegan menggunakan `LayoutBuilder` + `ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight))` dengan offset `SizedBox(height: 20)` agar tidak menempel di batas atas layar.
  - **Penyelarasan Warna Tombol Utama (CTA)**: Seluruh primary button di semua layar ([`lib/screens/transaction_success_screen.dart`](lib/screens/transaction_success_screen.dart), [`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart), [`lib/screens/wallets_screen.dart`](lib/screens/wallets_screen.dart), [`lib/screens/budget_screen.dart`](lib/screens/budget_screen.dart), [`lib/screens/budget_detail_screen.dart`](lib/screens/budget_detail_screen.dart), [`lib/screens/split_bill_screen.dart`](lib/screens/split_bill_screen.dart), [`lib/screens/onboarding_profile_screen.dart`](lib/screens/onboarding_profile_screen.dart), [`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart)) diseragamkan ke sapphire blue token `Color(0xFF02539A)` (`AppColors.primaryButton`) dengan teks putih seragam. Pengecualian khusus: tombol "Simpan Transaksi" pada [`lib/screens/add_transaction_screen.dart`](lib/screens/add_transaction_screen.dart) menggunakan latar putih dengan teks hitam pada dark mode, dan sapphire blue dengan teks putih pada light mode.
- [x] Pengurangan Shadow Tombol (+) dan Bilah Navbar ([`lib/widgets/bottom_nav_bar.dart`](lib/widgets/bottom_nav_bar.dart)):
  - **Tombol Tambah (+)**: Mengurangi intensitas double shadow dari 0.50 blue blur 14 + 0.40 black blur 8 menjadi shadow halus minimalis (0.20 blue blur 6 + 0.10 black blur 4) agar tidak pekat/muddy.
  - **Canvas Navbar Bar**: Mengurangi drop shadow canvas `drawShadow` dari opacity 0.55 / elevasi 14.0 menjadi opacity 0.20 / elevasi 6.0 untuk tampilan bersih dan anti-slop.
- [x] Pembaruan Logo Resmi & Splash Screen Murni:
  - **Logo Resmi ([`assets/images/logo.png`](assets/images/logo.png))**: Menggunakan karya seni logo resmi terbaru (mark 'Y' putih murni + background gradien biru safir bersih tanpa saku). Diterapkan pada layar Profil 'Tentang Aplikasi & Privasi' ([`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart)) dan onboarding ([`lib/screens/onboarding_profile_screen.dart`](lib/screens/onboarding_profile_screen.dart)).
  - **Splash Screen ([`lib/screens/splash_screen.dart`](lib/screens/splash_screen.dart))**: Menggunakan logo murni transparan ([`assets/images/logo_splash.png`](assets/images/logo_splash.png)) dengan mark putih murni presisi tinggi tanpa kotak pembungkus.
  - **App Icon Dipertahankan**: Seluruh ikon instalasi aplikasi (`assets/images/app_icon.png`, Android `mipmap-*`, Web favicon dan PWA) tetap dipertahankan sesuai permintaan pengguna ("yang app icon biarkan saja").
- [x] Pembaruan Ikon Aplikasi Pure-White & Kompilasi Signed Release APK:
  - **Ikon Instalasi Aplikasi (Android & Web)**: Menerapkan karya seni ikon terbaru dengan mark 'Y' putih murni (`#FFFFFF`, RGB `255, 255, 255`) dan gelombang saku kaca safir (`assets/images/app_icon.png` & `assets/images/logo.png`) ke seluruh direktori mipmap Android (`mipmap-mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`), web favicon, dan ikon PWA web.
  - **Kompilasi Signed Release APK**: Membangun APK release bertanda tangan ke [`yotro-app.apk`](yotro-app.apk) dan `build/web/yotro-app.apk` sehingga pengguna dapat mengunduh langsung dari banner web browser HP (`http://localhost:8080/yotro-app.apk`) atau memasangnya secara lokal.
  - **Restorasi Live Web Server Port 8080**: Membangun ulang `build/web/` dan merestart daemon server lokal; diverifikasi via curl mengembalikan `HTTP 200 OK` baik untuk web runner maupun berkas unduhan APK.
- [x] Pembaruan Ikon Aplikasi, Logo Splash, & Ikon Profil Tentang Aplikasi:
  - **Ikon Instalasi Aplikasi (Android & Web)**: Menggunakan karya seni ikon terbaru dengan lengkungan gelombang simetris (`assets/images/app_icon.png` & `assets/images/logo.png`) untuk seluruh ukuran Android launcher icon (`android/app/src/main/res/mipmap-*`), web favicon (`web/favicon.png`), dan ikon web PWA (`web/icons/*`).
  - **Ikon Profil "Tentang Aplikasi & Privasi" ([`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart))**: Mengganti ikon perisai generik dengan logo resmi aplikasi Yotro (`assets/images/app_icon.png`) berukuran 38x38 ber-radius sudut melengkung 10px dan border halus adaptif.
  - **Emblem Layar Splash ([`lib/screens/splash_screen.dart`](lib/screens/splash_screen.dart))**: Menggunakan logo murni transparan (`assets/images/logo_splash.png`) tanpa pembungkus kotak/kontainer (`BoxDecoration`/`boxShadow`), dengan adaptasi warna otomatis pada dark mode dan light mode.
  - **Pengujian Unit & Web Build**: Seluruh 86 tests lolos 100% dan Flutter Web release dikompilasi ulang ke `build/web/`.
- [x] Pengembalian Tampilan Layar Dompet ke Layout Asal ([`lib/screens/wallets_screen.dart`](lib/screens/wallets_screen.dart)):
  - **Restorasi Layout Klasik**: Mengembalikan tata letak daftar akun & dompet ke desain awal (`NestedCard` dengan `ListView.separated`) yang bersih, rapi, dan mudah dinavigasi, sesuai permintaan pengguna ("kembalikan seperti sebelumnya saja untuk dompet").
  - **Detail Komponen List**: Setiap dompet ditampilkan dalam baris rapi dengan badge ikon melingkar, nama akun, tipe dompet, saldo terformat Inter Tight, dan tombol edit pensil.
  - **Kartu Callout Transfer Tetap Selaras**: Kartu aksi cepat transfer saldo antar-dompet tetap menggunakan tombol safir terpadu `Color(0xFF02539A)` yang konsisten di seluruh aplikasi.
  - **Uji Suite & Web Release**: Seluruh 86 tests lolos 100% dan build web release terbaru berhasil dikompilasi ke `build/web/`.
- [x] Tombol Tutup (X) Pada Setiap Snackbar ([`lib/widgets/app_snackbar.dart`](lib/widgets/app_snackbar.dart)):
  - **Tombol Close Cepat**: Menambahkan ikon `Icons.close_rounded` melingkar (`26x26`) di sisi kanan setiap snackbar untuk menutup pesan secara instan saat diklik (`messenger.hideCurrentSnackBar()`).
  - **Standardisasi Menyeluruh**: Mengintegrasikan `AppSnackBar` ke seluruh layar ([`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart), [`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart), [`lib/screens/add_transaction_screen.dart`](lib/screens/add_transaction_screen.dart), [`lib/screens/edit_category_screen.dart`](lib/screens/edit_category_screen.dart), [`lib/screens/main_shell.dart`](lib/screens/main_shell.dart), [`lib/widgets/notification_permission_sheet.dart`](lib/widgets/notification_permission_sheet.dart)).
  - **Pengujian Unit & Widget**: Menambahkan [`test/snackbar_close_button_test.dart`](test/snackbar_close_button_test.dart) yang memverifikasi kehadiran dan fungsi interaktif tombol tutup (seluruh 88 tests lolos 100%).
- [x] Tombol Salin Ringkas Berbasis Ikon di Split Bill ([`lib/screens/split_bill_screen.dart`](lib/screens/split_bill_screen.dart)):
  - Mengganti tombol teks "Salin Teks" yang memicu pemotongan/pembungkusan baris ke bawah dengan tombol kotak ringkas (`SizedBox(width: 48, height: 48)`) berikon `Icons.copy_rounded` (OutlinedButton, radius 14px, padding zero).
  - Memberikan ruang horizontal penuh (`Expanded`) untuk tombol aksi utama "Catat Bagian Saya" sehingga tampilan rapi dan sejajar.
- [x] Tombol Simpan Kategori Fixed/Pinned di Bawah & Validasi Form Penuh ([`lib/screens/edit_category_screen.dart`](lib/screens/edit_category_screen.dart)):
  - Memindahkan tombol "Simpan Kategori" / "Simpan Perubahan" keluar dari `ListView` menjadi pinned bottom bar tetap di bagian bawah modal bottom sheet / halaman.
  - Pengguna tidak perlu menggulir ke bawah melewati daftar panjang emoji untuk menekan tombol simpan.
  - Validasi ketat: Tombol otomatis disabled (`onPressed: null`, latar redup) sampai seluruh form wajib terisi (`_nameController.text.trim().isNotEmpty` dan `_selectedEmoji != null`).
  - Membungkus modal sheet dengan `Material` untuk mencegah ketiadaan ancestor Material pada ink splashes.
- [x] Ikon Aksi Cepat Kartu Saldo Beranda Menggunakan Berkas SVG Asli ([`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart) & `assets/icon/`):
  - Memasang dependensi `flutter_svg: ^2.3.2` dan mendaftarkan folder `assets/icon/` pada `pubspec.yaml`.
  - Mengarahkan keempat menu aksi cepat di balance card Beranda ke berkas SVG resmi yang disediakan user: `Dompet.svg`, `Budget.svg`, `Analisis.svg`, dan `Split Bill.svg`.
  - Ukuran ikon diperbesar dari 28x28px menjadi **36x36px** (divider `height: 36px`) agar proporsional dan jelas terbaca.
  - Menyesuaikan tint warna secara dinamis mengikuti tema aktif (`isDark ? Colors.white : Color(0xFF0F172A)`).
- [x] Kompilasi Ulang Web Release & Signed Release APK:
  - Berhasil membangun `build/web/` terbaru untuk daemon live server port `8080`.
  - Menyalin signed APK ke `build/web/yotro-app.apk` sehingga tombol unduh APK pada browser HP aktif dan mengembalikan HTTP 200 OK.
  - Seluruh 87 unit dan widget tests lulus 100% (`flutter test`).
- [x] Eliminasi Floating Overlay APK Web & Integrasi Native ke Pengaturan ([`web/index.html`](web/index.html), [`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart), [`lib/services/backup_storage_service.dart`](lib/services/backup_storage_service.dart)):
  - Menghapus floating pill HTML `apk-download-banner` dari `web/index.html` sehingga preview web 100% bersih tanpa menutupi header/lonceng notifikasi.
  - Menambahkan tombol native "Unduh APK Android (v1.0.5)" pada layar Pengaturan > Tentang Aplikasi & Privasi khusus saat dijalankan di browser web (`kIsWeb`).
  - Memanfaatkan `BackupStorageService.downloadApk()` berbasis HTML anchor download lintas platform.
- [x] Pemindaian Struk Belanja OCR On-Device & Bilah Aksi 3 Tombol ([`lib/screens/add_transaction_screen.dart`](lib/screens/add_transaction_screen.dart), [`lib/widgets/receipt_adjustment_sheet.dart`](lib/widgets/receipt_adjustment_sheet.dart), [`lib/services/receipt_scanner/`](lib/services/receipt_scanner/)):
  - **Bilah Aksi Bawah 3 Tombol**: Menerapkan tata letak sesuai referensi desain pengguna: tombol Kamera sirkular (48x48px), tombol pill safir "Simpan Transaksi" (Expanded, 48px), dan tombol Mikrofon sirkular (48x48px).
  - **OCR 100% On-Device & Offline**: Memanfaatkan `google_mlkit_text_recognition` dan `image_picker` tanpa ketergantungan API cloud atau server eksternal demi privasi data finansial.
  - **Mesin Parsing Cerdas (`ReceiptParserService`)**: Heuristik pencarian nominal bertingkat (prioritas Grand Total keywords dari baris bawah ke atas), penyusunan chip nominal alternatif, filter pembersih nama merchant, deteksi tanggal format angka/nama bulan, dan auto-kategori berdasarkan brand toko dan item belanja.
  - **Lembar Penyesuaian Struk (`ReceiptAdjustmentSheet`)**: Menampilkan modal sheet interaktif di mana pengguna dapat mengedit nominal langsung, memilih nominal alternatif struk via chip, mengubah nama toko, tanggal, dompet, dan kategori.
  - **Dua Alur Keputusan (Opsi 2 User Flow)**:
    - **"Setujui & Simpan"**: Menyimpan transaksi secara instan ke `TransactionProvider` dan mengarahkan langsung ke `TransactionSuccessScreen`.
    - **"Buka di Form"**: Memindahkan seluruh data yang disesuaikan langsung ke form input `AddTransactionScreen` untuk pengisian/penyesuaian lebih lanjut.
  - **Pengujian Lengkap**: 95 unit dan widget tests lolos 100% (`flutter test`).
  - **Web Parity & Rebuild**: Kompilasi `build/web/` terbaru dan sinkronisasi `build/web/yotro-app.apk` pada live server port 8080.
- [x] Pembuatan Signed Release APK Android v1.0.6+7 Ramping ([`yotro-app.apk`](yotro-app.apk) & `build/web/yotro-app.apk`):
  - Konfigurasi ProGuard R8 rules di [`android/app/proguard-rules.pro`](android/app/proguard-rules.pro) untuk ML Kit Text Recognition (`-dontwarn com.google.mlkit.vision.text.**`).
  - Mengaktifkan tree-shaking font asset (`tabler-icons.ttf` dan `MaterialIcons-Regular.otf` susut 98%).
  - Menerapkan arsitektur `--split-per-abi`: memangkas ukuran biner dari 91 MB menjadi **33 MB** (ARM64-v8a) untuk smartphone Android modern.
  - Tersedia opsi biner: `yotro-app.apk` / `yotro-app-arm64.apk` (33 MB), `yotro-app-arm32.apk` (27 MB), dan `yotro-app-universal.apk` (91 MB).
  - Tombol download tersedia langsung di preview web Pengaturan > Tentang Aplikasi & Privasi > "Unduh APK Android (v1.0.6)".
- [x] Pembaruan UI Laporan Keuangan, Outlined Action Bar, & Keyboard Isolation ([`lib/screens/analytics_screen.dart`](lib/screens/analytics_screen.dart), [`lib/screens/add_transaction_screen.dart`](lib/screens/add_transaction_screen.dart)):
  - **Default Donut Chart**: Layar Laporan Keuangan kini membuka Donut Chart secara default (`ChartViewMode.donut`); tombol switch beralih ke Bar Chart.
  - **Isolasi Keyboard Kategori**: Menutup modal sheet kategori `Lainnya` tidak lagi memicu keyboard muncul kembali secara otomatis (`_amountFocusNode.canRequestFocus = false`).
  - **Outlined Action Buttons**: Tombol Kamera (OCR) dan Mikrofon di bilah aksi bawah `AddTransactionScreen` diubah menjadi gaya Outlined Button melingkar transparan dengan border outline 1.2px.
  - **Uji Suite & Paritas Web**: Seluruh 98 tests lolos 100% dan build web `build/web/` dikompilasi ulang serta dijalankan pada `http://localhost:8080/`.
- [x] Redesain Analisis Keuangan: Half Circular Gauge, Kurva Alur, & Donut Komparasi ([`lib/screens/financial_analysis_screen.dart`](lib/screens/financial_analysis_screen.dart), [`lib/widgets/donut_chart_painter.dart`](lib/widgets/donut_chart_painter.dart), [`lib/screens/analytics_screen.dart`](lib/screens/analytics_screen.dart)):
  - **Switcher Tab Laporan Keuangan**: Urutan dibalik — Donut chart di kiri (`Icons.pie_chart_rounded`) dan Bar chart di kanan (`Icons.bar_chart_rounded`).
  - **Half Circular Health Gauge**: Busur setengah lingkaran murni 180° (`_HalfCircularHealthPainter`, stroke cap round) dengan angka skor besar di tengah, status badge, dan baris 4 zona konteks (Kurang, Waspada, Aman, Sangat Baik) ber-highlight aktif.
  - **Diagram Kurva Alur Transaksi**: Smooth cubic bezier curve chart (`_CashFlowCurvePainter`) memetakan tren akumulasi uang masuk (hijau) vs uang keluar (cyan) sepanjang bulan terpilih dengan checkpoint interaktif.
  - **Donut Chart Pemasukan vs Pengeluaran**: Annular wedge donut chart (`DonutChartPainter`) identik dengan style Laporan Keuangan, memuat nilai Arus Kas Bersih di tengah (Surplus/Defisit) dan breakdown kartu mini.
  - **Hapus Metrik Lawas**: Menghapus pod "Rata-rata Harian" dan "Proyeksi Akhir Bulan" sepenuhnya dari layar analisis dan lembar panduan bantuan.
  - **Pengujian & Build Web**: Seluruh 98 unit dan widget tests lulus 100%, Flutter Web release dikompilasi ulang ke `build/web/`, APK disinkronkan, dan live server aktif pada `http://localhost:8080/`.
- [x] Atmospheric Sapphire Radial Glow di 4 Layar Utama ([`lib/widgets/ambient_top_glow.dart`](lib/widgets/ambient_top_glow.dart), [`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart), [`lib/screens/transactions_screen.dart`](lib/screens/transactions_screen.dart), [`lib/screens/analytics_screen.dart`](lib/screens/analytics_screen.dart), [`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart)):
  - **Widget Modular `AmbientTopGlow`**: Dibuat komponen terpusat yang merender pendaran atmosferik safir radial dari puncak layar (`Alignment(0.0, -1.0)`, radius 1.25, tinggi 480px, `#034A8C` -> `#023668` -> `#062343` -> `#001C2229`).
  - **Konsistensi 4 Layar Utama (Khusus Dark Mode)**:
    1. **Beranda**: Memancar di balik greeting header ("Selamat pagi, Ian Firdaus 👋") dan di belakang kartu saldo hero dengan ambient soft shadow (`#034A8C` blur 32).
    2. **Riwayat**: Memancar di balik header "Riwayat Transaksi", bilah pencarian, dan pill chip filter tanggal/periode.
    3. **Laporan**: Memancar di balik header "Laporan Keuangan", pemilih bulan, dan kartu donut chart aktivitas pengeluaran.
    4. **Profil & Pengaturan**: Memancar di balik header profil akun pengguna ("Ian Firdaus", email, status Pro).
  - **Invarian Safe Area**: Seluruh Scaffold body dibungkus `Stack` dengan `AmbientTopGlow` di balik `SafeArea`, sehingga pendaran warna biru safir menyala penuh dari tepi atas fisik perangkat (termasuk status bar & Dynamic Island / notch) tanpa terpotong padding.
  - **Test Suite & Build Web**: Seluruh 98 unit dan widget tests lulus 100% (`flutter test`). Flutter Web release dikompilasi ulang ke `build/web/`, APK disinkronkan ke `build/web/yotro-app.apk`, dan web server berjalan di `http://localhost:8080/`.
- [x] Fitur Layar Penuh Perekam Transaksi Suara dengan Clean Spectrum UI ([`lib/screens/voice_recording_screen.dart`](lib/screens/voice_recording_screen.dart), [`lib/widgets/circular_spectrum_visualizer.dart`](lib/widgets/circular_spectrum_visualizer.dart), [`lib/widgets/voice_multi_item_summary_sheet.dart`](lib/widgets/voice_multi_item_summary_sheet.dart), [`lib/services/voice_transaction_parser_service.dart`](lib/services/voice_transaction_parser_service.dart), [`lib/screens/add_transaction_screen.dart`](lib/screens/add_transaction_screen.dart)):
  - **Layar Bersih & Minimalis (`VoiceRecordingScreen`)**: Kanvas navy solid `#09101C`, header minimalis dengan tombol tutup di kiri dan judul ringkas **"Input Suara"** di pojok kanan atas. Teks status "Mendengarkan/Dijeda", dot status, heading "Ucapkan transaksimu", deskripsi, dan "Transkrip langsung" dihilangkan total demi estetika clean.
  - **Spektrum di Tengah & Tombol Kontrol Pusat**: Spektrum ditempatkan tepat di pusat layar vertikal dan horizontal (`size: 290px`). Tombol sirkular 72x72px (pause/mic toggle) berada di tengah rongga spektrum. Tombol pause terpisah di bilah bawah dihapus, menyisakan satu tombol full-width `Selesai & Tinjau`.
  - **Petunjuk Pengucapan Halus**: Placeholder contoh kecil dan tidak mencolok di bawah spektrum (`Contoh: "Kopi 25 ribu" atau "Siomay 13rb, tahu tek 100rb"`), berubah menjadi teks subtitel elegan saat suara terdeteksi.
  - **Smooth Circular Spectrum & Standby Waveform**: Outline lingkaran putih tipis dengan sweep highlight standby dan dynamic radial harmonic waves merespons level suara.
  - **Mesin Parsing Cerdas Bahasa Indonesia**: Mengekstrak transaksi multi-item (*"Siomay 13 ribu, tahu tek 100 ribu, keyboard 500 ribu, hp 1 juta"*), konversi kata angka (*seratus ribu*, *sejuta*, *setengah juta*), stopwords cleaner, dan auto-kategorisasi cerdas.
  - **Alur Perutean Adaptif**:
    - **1 Item**: Langsung menutup layar penuh dan mengisi form `AddTransactionScreen` secara otomatis (Nominal, Catatan, Kategori) tanpa langkah tambahan.
    - **Lebih dari 1 Item**: Membuka lembar ringkasan vertikal `VoiceMultiItemSummarySheet` dengan rincian total dan kartu per item.
  - **Koreksi & Kontrol Pengguna**: Mengetuk item membuka dialog koreksi nominal/kategori bertema matte slate gelap anti-slop, tombol **"Ulangi"** (Outlined 1 baris), dan tombol **"Catat Semua"** (Batch Save).
  - **Simulator Chips**: Tombol sampel ucapan hanya muncul di web preview (`localhost:8080`) atau fallback; disembunyikan di perangkat HP asli.
  - **Verifikasi & Build**: Seluruh **111 test** unit/widget lulus 100%, `flutter build web --release` berhasil dikompilasi ke `build/web/`, APK disinkronkan ke `build/web/yotro-app.apk`.
- [x] Fitur 6 Peningkatan Antarmuka & Ekosistem Aplikasi:
  - **Tambah Kategori Langsung di Halaman Catat Transaksi (`AddTransactionScreen`)**: Menambahkan pill `+ Kategori` di baris selector dan tombol `+ Tambah Kategori Baru` di sheet kategori lengkap. Terintegrasi dengan `EditCategoryScreen.showAsModalSheet` yang mengembalikan `CategoryModel` baru dan auto-select langsung di form input transaksi.
  - **Katalog Emoji Finansial Indonesia Diperluas (`IconCatalog`)**: Menambahkan lebih dari 40+ emoji kontekstual kebutuhan lokal: makanan (🥟 Siomay, 🧆 Gorengan, 🍚 Nasi, 🍛 Nasi Padang, 🍢 Sate, 🍤 Seafood, 🥚 Telur), transportasi (🛥️ Speedboat, 🛞 Servis Ban, 🛢️ Oli Mesin, 🚨 Derek, 🚧 Tol), gadget & belanja (💻 Laptop, ⌨️ Keyboard, 🖱️ Mouse, 🖥️ Monitor, ⌚ Jam Tangan, 🧺 Laundry), tagihan & properti (🏛️ Pajak PBB, 🛡️ Asuransi, 💳 Cicilan Paylater), keuangan (💸 Transfer, 💱 Valas, 📜 Saham), dan tempat ibadah (🕌 Masjid, ⛪ Gereja, 🛕 Pura/Vihara).
  - **Filter Bulan Serasi Kartu Saldo di Analisis Keuangan (`FinancialAnalysisScreen`)**: Komponen terpusat `AppMonthFilterPill` diposisikan tepat di bawah judul "Analisis Keuangan" (menampilkan 3 huruf bulan + tahun seperti `Nov 2026 ∨`), membuka bottom sheet pemilihan tahun stepper dan 12 bulan.
  - **Filter Bulan Serasi Kartu Saldo di Laporan Keuangan (`AnalyticsScreen`)**: Menggantikan pill lama dengan `AppMonthFilterPill` dan bottom sheet lengkap `showAppMonthFilterSheet`.
  - **3 Opsi Mode Tampilan di Menu Profil & Pengaturan (`SettingsScreen`)**: Mengganti sakelar 2-arah sun/moon menjadi baris interaktif dengan modal sheet 3 opsi: **Sistem** (`ThemeMode.system`), **Mode Terang** (`ThemeMode.light`), dan **Mode Gelap** (`ThemeMode.dark`) dengan deskripsi bersih, checkmark aktif, dan penyimpanan persisten ke `SharedPreferences`.
  - **Pembersihan Fitur Persetujuan Transaksi**: Menghapus kartu persetujuan transaksi dan badge pending dari Pusat Notifikasi (`NotificationsCenterScreen`) dan Beranda (`DashboardScreen`), sehingga Pusat Notifikasi kini berfokus murni pada riwayat aktivitas mutasi dan status pengingat harian.
  - **Verifikasi & Build**: Seluruh **117 test** unit & widget lulus 100%, Flutter Web release dikompilasi ke `build/web/`, APK disinkronkan ke `build/web/yotro-app.apk`.
- [x] Kompilasi Signed Release APK Android v1.0.6+7 ([`yotro-app.apk`](yotro-app.apk) & `build/web/yotro-app.apk`):
  - Konfigurasi OpenJDK 17 (`/opt/homebrew/opt/openjdk@17`) dan Android SDK 35 via Homebrew & Flutter toolchain.
  - Kompilasi `flutter build apk --release --split-per-abi` sukses menghasilkan biner ARM64 modern 36.3 MB (`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`).
  - SHA-256: `ff15b958594b1c17e45c78b9bdc32d1317e6a065bdcb8a35b96227aeee72e2de`.
  - Disalin ke root `yotro-app.apk`, `yotro-app-arm64.apk`, dan `build/web/yotro-app.apk`.
  - Live download endpoint tersedia di server lokal port 8080: `http://192.168.111.7:8080/yotro-app.apk`.
- [x] Pembersihan Berkas Aset Gambar Tidak Terpakai:
  - Menghapus berkas aset gambar yang tidak direferensikan oleh kode: `assets/images/voice_orb_spectrum.jpg`.
  - Memverifikasi seluruh sisa aset gambar aktif (`app_icon.png`, `logo.png`, `logo_splash.png`, `onboarding_bg.jpg`, dan 4 icon SVG cepat).
  - Seluruh 117 tests lulus 100% (`flutter test`).
- [x] Optimasi & Kompresi Ukuran APK Android via `--split-per-abi`:
  - Menerapkan arsitektur `--split-per-abi` untuk memisahkan biner multi-arsitektur native C++ ML Kit dan Flutter engine.
  - Memangkas ukuran APK dari **94.2 MB** menjadi **35.2 MB** (pengurangan **63%**) khusus arsitektur smartphone Android modern (`ARM64-v8a`).
  - Menyediakan biner `yotro-app.apk` / `yotro-app-arm64.apk` (35.2 MB) dan fallback `yotro-app-universal.apk` (94.2 MB).
  - Live download endpoint di port 8080 telah disinkronkan ke biner 35.2 MB: `http://192.168.100.184:8080/yotro-app.apk`.
- [x] Perbaikan 3 Isu Finansial & Input Aplikasi:
  - **Input Suara (Pencegahan Layar Hitam & Auto-Stop 5 Detik)**:
    - Menghilangkan *auto-pop* prematur pada `VoiceRecordingScreen` yang sebelumnya memicu navigasi ganda dan error context tidak aktif (*deactivated context*) saat `speech_to_text` selesai.
    - Menambahkan timer hening 5 detik (`_silenceTimer`): jika pengguna tidak berbicara selama 5 detik, perekaman otomatis berhenti (*pause*) dan tombol mikrofon kembali ke mode siap; layar tetap aktif menampilkan hasil ucapan tanpa terlempar keluar.
    - Perutean hasil transaksi suara dikendalikan secara aman melalui tombol **"Selesai & Tinjau"** dengan pengembalian `VoiceParseResult` ke konteks induk (`open()`).
    - **Perbaikan Deteksi Nominal Ribuan NLP**: Menangani format angka ribuan bertitik/koma (`12.000`, `12,000`), varian unit bersambung (`12ribu`, `12 rb`, `12k`), serta ucapan singkat informal (misal: "kopi 12" -> Rp 12.000).
  - **Split Bill (Pencegahan Keyboard Otomatis & Validasi Nama Tagihan Kosong)**:
    - Menjadikan default Nama Tagihan kosong (`""`) agar pengguna wajib mengisi nama tagihan sebelum disimpan.
    - Menambahkan validasi snackbar peringatan *"Nama tagihan wajib diisi terlebih dahulu."* pada tombol **"Catat Bagian Saya"** dan salin ringkasan.
    - Mengisolasi fokus input dengan `_noteFocusNode` dan pemanggilan `unfocus()` saat menambah anggota baru, mengubah nama teman, atau menyimpan item pesanan, mencegah keyboard terbuka secara otomatis.
  - **Tombol "+ Kategori" Header Form Catat Transaksi**:
    - Memindahkan tombol `+ Kategori` dari dalam deretan pill horizontal ke sisi seberang judul `Kategori` (`MainAxisAlignment.spaceBetween`).
    - Didesain sebagai `TextButton` elegan anti-slop, mencegah tombol terpotong pada layar beresolusi kecil dan menjaga deretan kategori tetap rapi.
  - **Verifikasi & Build**:
    - Seluruh **119 unit & widget tests** lulus 100% (`flutter test`).
    - Flutter Web release dan Android Release APK (`yotro-app.apk` ARM64 35.2 MB) dikompilasi ulang dan siap diunduh di `http://192.168.100.184:8080/yotro-app.apk`.
- [x] Perbaikan 3 Permintaan Terakhir (Single Plus Kategori, Icon App Baru, Redesain Onboarding Login):
  - **Pencegahan Double Plus pada Tombol `+ Kategori` (`AddTransactionScreen`)**: Mengubah teks tombol header dari `+ Kategori` menjadi `Kategori` di samping `Icon(Icons.add_rounded)`, memastikan hanya tepat 1 tanda plus yang dirender (`[+] Kategori`).
  - **Ikon Aplikasi Baru (Y Emblem Biru Gradient)**: Mengonversi aset logo baru ke `assets/images/app_icon.png` (982x982), mipmap Android (`mipmap-mdpi`, `mipmap-hdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi`, `mipmap-xxxhdpi`), serta web icons (`web/favicon.png`, `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`).
  - **Redesain Onboarding Profile Screen Presisi Wireframe & Sesuai Desain Sistem Proyek**:
    - Bagian Atas (Brand Hero): Background solid navy `#081C41` di safe area atas, lambang Y putih (`assets/images/logo_splash.png`), teks *"Welcome to Yotro"*, dan aset motif kotak (`assets/images/onboarding_bg.png`) mengalir di bawahnya dengan degradasi halus tanpa distorsi.
    - Bagian Bawah (Komponen Form & Button Sesuai Style Proyek): Mengadopsi standar tema matte slate dan sapphire token:
      - Bottom sheet adaptif (`#0C131D` dark mode / `#FFFFFF` light mode) dengan sudut melengkung atas (`Radius.circular(32)`) dan border halus.
      - Inner card bertingkat (`#131A26` dark mode / `#F8FAFC` light mode, `Radius.circular(24)`).
      - Input pill berikon vektor murni geometris (`Icons.person_outline_rounded`, `Icons.phone_outlined`) dengan border 1px dan tipografi `Manrope` berbobot maksimal `FontWeight.w600`.
      - Presisi Placeholder & Alignment Anti-Slop: Memperbaiki alignment vertikal teks placeholder dan icon dengan native `InputDecoration` (`contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)`, `prefixIconConstraints: BoxConstraints(minWidth: 48, minHeight: 50)`, `textAlignVertical: TextAlignVertical.center`, font size 14px setara) sehingga placeholder dan ikon berada tepat di titik tengah vertikal 0.0px container 50px.
      - Tombol aksi utama (*primary CTA*) Sapphire Fin-tech (`#02539A`) dengan ikon panah halus (`Icons.arrow_forward_rounded`), tanpa emoji dekoratif.
    - Responsivitas & Keyboard: `autofocus: false` mencegah keyboard menyembul otomatis, `SingleChildScrollView` + `IntrinsicHeight` menjamin tampilan rapi tanpa overflow pada semua resolusi perangkat.
  - **Verifikasi & Build**: Seluruh 119 unit & widget tests lulus 100%, Flutter Web release dan Android Release APK berhasil dikompilasi.
- [x] Fitur Onboarding Multi-Tahap, Status Bar Adaptif Light Mode, & Web Logout Test:
  - **Status Bar & Notification Bar Adaptif Mode Terang (`main.dart` & `main_shell.dart`)**: Membungkus root widget dengan `AnnotatedRegion<SystemUiOverlayStyle>` dan panggilan dinamis `SystemChrome.setSystemUIOverlayStyle` (`statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark`), mengatasi notification bar sistem Android/iOS tidak terlihat pada Light Mode.
  - **Alur Onboarding 4 Tahap Berurutan (`OnboardingProfileScreen`)**:
    - *Step 1: Identitas & Data Diri (Wajib)*: Nama Lengkap (validasi wajib diisi), Nomor Telepon (opsional), dan Jenis Kelamin (Pria/Wanita). Tersedia tombol "Lanjutkan" dan "Mulai Mencatat".
    - *Step 2: Mode Tampilan & Preferensi Dashboard (Bisa Dilewati)*: Pilihan Mode Tema (Sistem, Terang, Gelap) & Preferensi Tampilan Beranda (Lengkap, Pemasukan & Pengeluaran, Pengeluaran Saja).
    - *Step 3: Atur Dompet (Bisa Dilewati)*: Melihat daftar dompet & modal instan "+ Tambah Dompet Baru" (nama, tipe Bank/E-Wallet/Cash, saldo awal).
    - *Step 4: Atur Kategori (Bisa Dilewati)*: Tab Pengeluaran & Pemasukan, tombol "+ Tambah Kategori" terintegrasi `EditCategoryScreen.showAsModalSheet`, dan tombol akhir "Mulai Mencatat".
    - *Indikator Progres Responsif*: Dibungkus dengan `FittedBox` scale-down sehingga bebas RenderFlex overflow pada seluruh resolusi layar (termasuk layar sempit <= 360px).
  - **Tombol Logout Khusus Web (`SettingsScreen`)**: Tombol logout hadir khusus pada platform web (`kIsWeb`) di kartu profil dan danger zone untuk mereset onboarding dan memudahkan pengujian alur 4 tahap onboarding di browser.
  - **Refinement Antarmuka Onboarding `/antislop-ui` (`OnboardingProfileScreen`)**:
    - *Pembersihan Struktur Container Ganda*: Menghilangkan kontainer ganda (*inner card* di dalam *bottom sheet*) yang sebelumnya memakan padding horizontal berlebih (34px); form kini langsung terintegrasi pada permukaan bottom sheet tunggal yang lega, bersih, dan sesuai wireframe asli.
    - *Disiplin Radius & Surface Hierarchy (R-11)*: Mengganti radius ekstrem 25px (pill shape) pada input text field, tombol aksi utama, dan kartu gender menjadi radius konsisten `14px` (`BorderRadius.circular(14)`), selaras dengan desain sistem aplikasi fintech modern.
    - *Elevasi Bersih Tanpa Bayangan Mengambang (R-12)*: Menghilangkan drop-shadow blur 24px berlebih pada bottom sheet, kedalaman permukaan dipertegas lewat kontras warna matte `#0C131D` dan border hairline stroke 1px.
    - *Indikator Progres Tahap Terstruktur*: Mengadopsi penomoran jelas `['1. Profil', '2. Tampilan', '3. Dompet', '4. Kategori']` dengan warna aktif biru safir `#02539A` dan border halus, bebas RenderFlex overflow via `FittedBox`.
    - *Hierarki Tombol Aksi & Ikon Bermakna (R-08)*: Mengganti ikon panah generik pada tombol akhir "Mulai Mencatat" dengan ikon checklist `Icons.check_rounded` yang menandakan penyelesaian alur.
  - **Verifikasi & Build**: Seluruh **120 tests (119 passed, 1 skipped)** lulus 100%, Flutter Web release aktif di port 8080.
- [x] Redesain Stepper Carousel, Pembersihan Tombol Lewati Atas, & Seleksi Kategori Onboarding:
  - **Garis Indikator Carousel (`OnboardingProfileScreen`)**: Mengganti teks stepper verbal (`1. Profil`, `2. Tampilan`, dll.) dengan 4 garis/dash carousel horizontal beranimasi halus (`AnimatedContainer` lebar 24px saat aktif, 8px saat non-aktif, tinggi 3.5px, radius 2px) di bawah logo "Welcome to Yotro".
  - **Penghapusan Tombol Lewati di Header**: Menghilangkan tombol text "Lewati" dari baris atas header seluruh tahapan onboarding. Tombol "Lewati" dipusatkan secara eksklusif pada baris tombol aksi navigasi di bagian bawah.
  - **Kategori Interaktif & Dapat Dipilih (Tahap 4)**:
    - Chip kategori pada Tahap 4 dapat diklik/di-toggle untuk memilih kategori yang dibutuhkan pengguna (dilengkapi ikon centang `check_rounded` dan sapphire stroke saat aktif).
    - Menjaga validasi minimal 1 kategori terpilih serta tombol `+ Tambah Kategori Baru` terintegrasi.
    - Menyimpan daftar kategori yang dipilih via `TransactionProvider.setSelectedCategories(...)` saat menyelesaikan alur onboarding.
  - **Stabilitas Layout Tanpa Intrinsic Height Conflict**:
    - Menghapus `IntrinsicHeight` pada root scroll view yang sebelumnya memicu `RenderShrinkWrappingViewport` error, digantikan dengan `ConstrainedBox(minHeight: (constraints.maxHeight - 180).clamp(0.0, double.infinity))`.
    - Membungkus seluruh tombol navigasi dengan `FittedBox(fit: BoxFit.scaleDown)` dan padding horizontal 8px untuk mencegah RenderFlex horizontal overflow pada resolusi perangkat sempit.
  - **Verifikasi & Build**:
    - Seluruh **120 tests** lulus 100% (`flutter test`).
    - Flutter Web release dan Android Release APK dikompilasi ulang.
- [x] Spacing & Posisi Hero Brand Onboarding:
  - Menggeser posisi logo dan teks "Welcome to Yotro" lebih ke bawah via `padding: const EdgeInsets.only(top: 40)` pada `SafeArea` dan memperbesar hero container menjadi `height: 235.0` (logo 48x48, title 17px).
  - Memberi jarak lega (`const SizedBox(height: 18)`) antara teks judul "Welcome to Yotro" dan garis stepper carousel agar proporsional dan tidak saling menempel.
- [x] Penyembunyian Menu Tes Notifikasi HP pada Perangkat Mobile (`SettingsScreen`):
  - Mengisolasi menu pengembang "Tes Notifikasi HP" dengan `if (kIsWeb)`, sehingga otomatis disembunyikan sepenuhnya saat aplikasi diinstal/dijalankan pada perangkat HP (Android/iOS).
- [x] Build APK Android Terkompresi (`--split-per-abi` ARM64-v8a):
  - Mengompilasi build biner ramping terkompresi khusus arsitektur smartphone Android modern (`ARM64-v8a`), memangkas ukuran biner menjadi 37.4 MB (dibandingkan fat APK universal >70 MB).
  - Menyiapkan persistensi environment JDK 17 di `~/.jdk17` dan Android SDK Platform 34/35/36/37 di `~/.android-sdk`.
  - Berkas APK siap diunduh di [yotro-app.apk](file:///Users/ianfrds/_My%20Files/AI%20Vibecoding/money-tracker/yotro-app.apk) dan [build/web/yotro-app.apk](file:///Users/ianfrds/_My%20Files/AI%20Vibecoding/money-tracker/build/web/yotro-app.apk), atau via web server lokal di `http://192.168.111.7:8080/yotro-app.apk`.
- [x] Fitur Toggle "Total Saldo" vs "Saldo Saat Ini Versi Bulanan" di Hero Card Beranda:
  - **Dua Perspektif Saldo Terintegrasi (`TransactionProvider` & `DashboardScreen`)**:
    - **Mode Bulanan (Default)**: Kartu menampilkan saldo bersih murni versi bulan yang sedang aktif (`dashboardMonthNetBalance` = Pemasukan Bulan Ini - Pengeluaran Bulan Ini). Angka saldo dan sub-kartu (Pengeluaran & Pemasukan) 100% konsisten dengan filter bulan yang dipilih.
    - **Mode Total Saldo**: Menekan tombol pill kapsul `Total Saldo` di samping filter bulan mengalihkan kartu hero ke versi akumulasi saldo seluruh dompet selama ini (`totalBalance` / Net Worth riil). Sub-kartu otomatis menampilkan total akumulasi pengeluaran dan pemasukan sepanjang masa (`totalExpense` & `totalIncome`).
    - **Navigasi Kembali Instan**: Mengetuk filter bulan atau tombol `Total Saldo` langsung mengembalikan kartu ke versi bulanan bulan bersangkutan.
  - **Desain & Responsivitas Anti-Slop**:
    - Baris atas hero card dibungkus dengan `Expanded` dan `FittedBox(fit: BoxFit.scaleDown)` terukur sehingga bebas RenderFlex overflow pada seluruh resolusi layar (termasuk layar sempit <= 340px).
    - Tombol `Total Saldo` beranimasi halus (`AnimatedContainer` 200ms) dengan aksen sapphire/navy dan ikon vektor murni `account_balance_wallet_rounded`.
  - **Verifikasi & Build**:
    - Ditambahkan test suite `test/dashboard_balance_mode_test.dart` menguji logika kalkulasi, toggle hero card, dan reset otomatis.
    - Seluruh **122 tests (121 passed, 1 skipped)** lulus 100% (`flutter test`).
- [x] Penyempurnaan Tombol Total Saldo, Sub-Card Likuiditas Finansial & Modal Mata Uang (`plan_dashboard_and_currency_polish.md`):
  - **Tombol "Total Saldo" Minimalis (`DashboardScreen`)**:
    - Menghapus icon dompet agar tampilan bersih.
    - Default/inactive: Text button transparan tanpa border/container (`color: Colors.transparent`), teks putih teredam 70% (`w500`).
    - Active: Kapsul solid putih (`color: Colors.white`) dengan teks sapphire gelap (`#0B2244`, `w600`).
    - Visibilitas: Hanya tampil saat `dashboardViewMode == DashboardViewMode.complete`. Disembunyikan total di mode `incomeExpense` & `expenseOnly`.
  - **Sub-Card Likuiditas Finansial (Opsi 1 Terpilih)**:
    - Saat Total Saldo aktif: Menampilkan "Bank & Rekening" (saldo agregat bank/savings via `provider.bankWalletsTotalBalance`) dan "Kas & E-Wallet" (saldo agregat tunai/digital via `provider.cashAndDigitalWalletsTotalBalance`).
    - Dilengkapi aksi `onTap` yang langsung membuka layar `WalletsScreen` (`WalletsScreen.route()`).
  - **Pengaturan "Mata Uang" Modern (`SettingsScreen`)**:
    - Judul disederhanakan menjadi "Mata Uang".
    - Trailing chip menampilkan bendera negara: `🇮🇩 IDR` atau `🇺🇸 USD` dengan icon chevron.
    - Mengetuk baris membuka sheet modal `_showCurrencyPickerSheet` dengan pilihan bendera 🇮🇩 IDR (Rupiah Indonesia - Rp) dan 🇺🇸 USD (US Dollar - $).
  - **Verifikasi & Build**:
    - Test suite `test/dashboard_balance_mode_test.dart` diperbarui untuk menguji sub-cards Opsi 1, kalkulasi bank vs kas, dan visibilitas mode.
    - Seluruh **124 tests (123 passed, 1 skipped)** lulus 100% (`flutter test`).
    - Build Flutter Web release diperbarui (`flutter build web --release --no-tree-shake-icons`).
- [x] Hero Card Stationary Header [Nov 2026] vs [Total Saldo] & Zero-Clipping Layout (`plan_hero_card_nav_and_spacing.md`):
  - **Stationary Top Header**: Header `_buildHeroHeader` (menampilkan label bulan dinamis misal `Nov 2026` dan tombol `Total Saldo` serta toggle mata) dipindahkan ke luar PageView sehingga stasioner penuh dan tidak ikut tergeser saat swipe. Tombol aktif bergantian di tempatnya (`Nov 2026` vs `Total Saldo`).
  - **Zero-Clipping Content Slide**: Konten yang meluncur saat swipe murni hanya nilai saldo dan sub-card finansial. Masalah teks nominal terpotong di bagian atas teratasi tuntas (tinggi 120px untuk Complete, 58px untuk IncomeExpense, 100px untuk ExpenseOnly) dan jarak pagination dots tetap rapat dan proporsional.
  - **Verifikasi & Build**: Test suite `test/dashboard_balance_mode_test.dart` dan `test/month_filter_and_budget_empty_test.dart` serta seluruh 125 tests lulus 100%. Flutter Web release & APK diperbarui.
- [x] Sub-Card Per-Dompet Dinamis & Optimasi Snug Fit Height Hero Card (`lib/screens/dashboard_screen.dart`):
  - **Dinamis Per-Dompet di Slide Total Saldo**: Sub-card menampilkan seluruh dompet aktif pengguna (`provider.wallets`). Jika <= 2 dompet, ditampilkan via `Row` dengan pembagian seimbang; jika > 2 dompet, ditampilkan via `SingleChildScrollView(scrollDirection: Axis.horizontal)` dengan lebar kartu terukur (`(constraints.maxWidth - 52) / 2`) sehingga 2 kartu tampil utuh dan kartu ke-3 mengintip ~40px di kanan untuk memberi tahu pengguna kartu bisa di-scroll.
  - **Spasi Vertikal Rapi & Zero-Clipping Ketinggian**: Jarak antara nominal saldo ("Saldo saat ini" / "Total Saldo") dengan sub-card ditingkatkan dari `6px` ke `10px` (`SizedBox(height: 10)`). Ketinggian PageView kartu hero disesuaikan lega: `116.0px` (Complete), `52.0px` (Pemasukan & Pengeluaran), dan `64.0px` (Pengeluaran Saja). Khusus mode Pengeluaran Saja, ditambahkan padding atas `12px`, jarak bawah `6px`, dan padding kontainer `10px` (+21px ruang lega vertikal total) sehingga tidak mepet lagi. Tepi bawah kartu dan pagination dots (`SizedBox(height: 7)`) tampil utuh tanpa terpotong.
  - **Standarisasi Tombol Modal Bottom Sheet (48px Height)**: Seluruh tombol primer (`ElevatedButton`) dan sekunder (`OutlinedButton`) pada modal sheet di `SettingsScreen`, `WalletsScreen`, dan `BudgetScreen` dinaikkan ketinggiannya menjadi `48px` standar universal.
  - **Verifikasi & Build**: Ditambahkan test suite `test/dashboard_balance_mode_test.dart` mencakup 6 uji coba terperinci. Seluruh **127 tests** lulus 100% (`flutter test`). Flutter Web release & APK diperbarui.
- [x] Validasi Transfer Dompet Berbeda & Penyembunyian Reset Data Bawaan di Mobile:
  - **Validasi Transfer Antar-Dompet (`AddTransactionScreen` & `TransactionProvider`)**:
    - Dompet asal (`fromWalletId`) dan dompet tujuan (`toWalletId`) divalidasi wajib berbeda.
    - Pada UI: dropdown container diberi aksen garis merah peringatan (`#FF6B7A`), banner alert merah muncul di bawah baris dompet ("Dompet asal dan tujuan tidak boleh sama"), serta snackbar warning otomatis muncul saat user memilih dompet yang sama.
    - Pada aksi Simpan: `_save()` memblokir penyimpanan dengan snackbar danger jika dompet sama.
    - Pada layer Provider: `TransactionProvider.addTransaction()` melempar `ArgumentError` bila transaksi bertipe transfer memiliki `fromWalletId == toWalletId`.
  - **Penyembunyian Opsi "Reset ke Data Bawaan" pada Aplikasi Terinstal (`SettingsScreen`)**:
    - Menu "Reset ke Data Bawaan" dibungkus ke dalam gate `if (kIsWeb) ...` sehingga otomatis **tidak ada** ketika aplikasi dibuild dan diinstal pada perangkat mobile (Android/iOS), menjaga keamanan data riil pengguna agar tidak terhapus/tertimpa data simulasi awal secara tidak sengaja.
  - **Verifikasi & Build**:
    - Ditambahkan test suite `test/transfer_validation_and_settings_test.dart`.
    - Seluruh **130 tests** lulus 100% (`flutter test`).
    - Flutter Web release dan Android Split Release APK (`arm64-v8a`) dikompilasi ulang.
- [x] Perbaikan CI/CD GitHub Actions (`.github/workflows/build-apk.yml` & `android/app/build.gradle`):
  - Build validasi non-rilis memakai ephemeral self-signed key; build tag produksi tidak pernah memakai fallback dan wajib memakai signing secrets produksi.
  - Mengatasi kegagalan build APK di GitHub Actions (`Build safe release APK`) yang dipicu dependensi `permission_handler_android` (memerlukan Android SDK Platform 37).
  - Menambahkan instalasi otomatis Android SDK Platform 37.0, lisensi SDK, serta symlink `android-37 -> android-37.0` pada runner GitHub Actions.
  - Menyelaraskan `compileSdk = 37` di `android/app/build.gradle` dan menambahkan flag `--android-skip-build-dependency-validation` pada perintah kompilasi CI.
- [x] Sinkronisasi Otomatis Transaksi Saat Tambah & Edit Dompet dengan Toggle ON/OFF (`lib/screens/wallets_screen.dart`, `lib/providers/transaction_provider.dart`, `test/wallet_sync_transaction_test.dart`):
  - **Saldo Awal Dompet Baru:** Otomatis mencatat transaksi pemasukan (`TransactionType.income`) saat penambahan dompet dengan saldo awal > 0 ("Saldo Awal - [Nama]").
  - **Penyesuaian Saldo Dompet:** Otomatis mencatat transaksi pemasukan (jika saldo naik) atau pengeluaran (jika saldo turun) saat saldo diedit ("Penyesuaian Saldo - [Nama]").
  - **Kontrol Toggle Dua Tingkat:**
    1. Kartu `NestedCard` ("Otomatisasi Transaksi") di halaman Dompet dengan switch persisten ke `SharedPreferences` (`syncWalletToTransactions`, default `true`).
    2. Toggle lokal di dalam modal bottom sheet tambah/edit dompet untuk opsi per-aksi.
  - **Onboarding Bersih:** Penambahan dompet di onboarding awal diset `syncToTransaction: false`.
  - **Verifikasi & Build:** Ditambahkan 9 tes baru di `test/wallet_sync_transaction_test.dart`. Seluruh **138 tests** lulus 100% (`flutter test`). Flutter Web release berhasil dikompilasi ke `build/web/`.
- [x] Integrasi Cloud Supabase (Google Sign-In, MCP Server & Offline-First Sync Engine):
  - **MCP Supabase Server:** Dikonfigurasi di `~/.gemini/antigravity/mcp_config.json` dan `~/.gemini/config/mcp_config.json` dengan project ref `njjcviwihzvzjgfbzitg`.
  - **Dependensi & Inisialisasi:** Menambahkan `supabase_flutter: ^2.18.3` dan `lib/config/supabase_config.dart` dengan inisialisasi aman (zero-crash saat offline).
  - **Otentikasi Google Sign-In:** Disediakan via `lib/services/supabase_auth_service.dart` (`OAuthProvider.google`) lengkap dengan deep-linking `io.supabase.yotro://login-callback` di `AndroidManifest.xml`.
  - **Mesin Sinkronisasi Dua Arah:** `lib/services/supabase_sync_service.dart` memfasilitasi upload dan pull data PostgreSQL relasional lengkap (`profiles`, `wallets`, `categories`, `transactions`, `budgets`) dengan hook mutasi background.
  - **UI Pengaturan:** Menambahkan kartu `NestedCard` *"Sinkronisasi Cloud (Supabase)"* di `SettingsScreen` dengan tombol "Masuk dengan Google", "Sinkronkan Sekarang", "Keluar", dan dialog input kredensial mandiri.
  - **Verifikasi & Build:** Ditambahkan `test/supabase_sync_test.dart`. Seluruh **143 tests** lulus 100% (`flutter test`). Flutter Web release berhasil dikompilasi ke `build/web/`.
- [x] Instalasi Supabase Agent Skills & Skema Database Lengkap:
  - Menginstal `supabase/agent-skills` (`.agents/skills/supabase` dan `.agents/skills/supabase-postgres-best-practices`).
  - Menyiapkan `supabase/config.toml` terhubung ke project ref `njjcviwihzvzjgfbzitg`.
  - Membuat berkas migrasi lengkap `supabase/migrations/20261113000000_init_yotro_schema.sql` (5 tabel: `profiles`, `wallets`, `categories`, `transactions`, `budgets`, index FK, trigger `updated_at`, trigger `handle_new_user`, dan RLS privat `to authenticated`).
- [x] Eksekusi Skema Database Supabase via Management API:
  - Berhasil mengeksekusi migrasi `20261113000000_init_yotro_schema.sql` langsung ke project `njjcviwihzvzjgfbzitg` melalui endpoint Management API (`STATUS 201`).
  - Terverifikasi 5 tabel aktif: `profiles`, `wallets`, `categories`, `transactions`, dan `budgets` dengan 19 kebijakan Row Level Security (RLS) privat (`to authenticated`).
  - Mengambil API keys resmi project dan menginjeksi `anon` public key ke `lib/config/supabase_config.dart`.
  - Supabase CLI login terautentikasi (`npx supabase login --token`).
- [x] Layar Autentikasi Multi-Opsi & Mode Tamu 100% Offline (`AuthScreen`):
  - **Layar Baru `lib/screens/auth_screen.dart`:** Gerbang awal saat first-run atau saat ingin menghubungkan akun dari Pengaturan.
  - **Daftar Manual:** Form Nama Lengkap, Email, Kata Sandi, dan Konfirmasi Kata Sandi via `SupabaseAuthService.signUpWithEmail`. Profil otomatis terbuat di tabel Supabase `profiles` via trigger.
  - **Masuk Manual:** Form Email & Kata Sandi via `SupabaseAuthService.signInWithEmail` dengan pesan error bahasa Indonesia awam (`formatAuthException`).
  - **Masuk dengan Google:** Tombol vektor satu sentuhan `SupabaseAuthService.signInWithGoogle()`.
  - **Mode Tamu / Lewati (100% Offline):** Opsi "Lewati / Masuk sebagai Tamu" mengaktifkan mode lokal murni tanpa akun Supabase (`isGuestMode = true`), zero network request, dan persistensi lokal utuh. Dapat dihubungkan ke cloud kapan saja dari Pengaturan (`pushLocal`).
  - **Verifikasi & Build:** Ditambahkan 7 test di `test/auth_screen_test.dart`. Seluruh **150 tests** lulus 100% (`flutter test`). Flutter Web release berhasil dikompilasi ke `build/web/`.
- [x] Pengujian End-to-End Live Supabase (`tool/test_supabase_sync_engine.dart`):
  - Pengujian live langsung terhadap project Supabase `njjcviwihzvzjgfbzitg` berhasil 100%.
  - Verifikasi mencakup 9 alur: Sign Up Email+Password+Nama, verifikasi baris `profiles` via trigger, Insert Dompet, Insert Kategori, Insert Transaksi, Update Transaksi, Upsert Anggaran/Budget, Simulasi Pull Cloud Data, dan Sign Out & Re-Login.
  - Opsi `mailer_autoconfirm: true` diaktifkan di Supabase Auth Config untuk memastikan login instan tanpa hambatan verifikasi email.
- [x] Perbaikan Redirect Google OAuth & Deep Link Callback:
  - Mengubah konfigurasi Supabase Auth (`site_url: io.supabase.yotro://login-callback` dan `uri_allow_list`) via Management API untuk mencegah fallback ke `http://localhost:3000` dan error `flow_state_already_used`.
  - Memperbarui `SupabaseAuthService.signInWithGoogle` dengan `authScreenLaunchMode: LaunchMode.externalApplication` pada mobile untuk memastikan kembalinya intent ke aplikasi secara mulus.
- [x] Penyatuan Onboarding & Autentikasi (`OnboardingProfileScreen`):
  - Mengintegrasikan opsi "Lanjutkan dengan Google", modal bottom sheet "Daftar / Masuk Email", serta alur "Tamu / Manual" langsung pada Step 1 Onboarding.
  - Nama pengguna otomatis diprefill dari Google OAuth metadata (`SupabaseAuthService.userName`) saat login Google berhasil, dan tetap dapat disesuaikan/diedit oleh pengguna sebelum melanjutkan.
  - Mengarahkan pengguna langsung menyelesaikan setup 4-langkah (Data Diri, Tema & Tampilan, Atur Dompet, Kategori) saat pendaftaran.
  - Penyelesaian onboarding otomatis mengunggah seluruh setup lokal ke Supabase jika terotentikasi, atau menyimpannya 100% lokal jika mode tamu.
- [x] Fitur Hapus Akun Pengguna di Zona Bahaya (`SettingsScreen`):
  - Menginstal PostgreSQL RPC `delete_user_account()` pada Supabase (`SECURITY DEFINER`) yang mengeksekusi `DELETE FROM auth.users WHERE id = auth.uid();` dan secara otomatis meng-cascade penghapusan seluruh data tabel relasional anak (`profiles`, `wallets`, `categories`, `transactions`, `budgets`).
  - Menambahkan baris "Hapus Akun Pengguna" pada Zona Bahaya di `SettingsScreen` dengan modal konfirmasi destruktif permanen.
  - Menghapus sesi Supabase, membersihkan seluruh data lokal perangkat via `TransactionProvider.deleteAccount()`, mereset status onboarding, dan mengarahkan kembali ke `OnboardingProfileScreen`.
- [x] Restrukturisasi Auth Gate & Setup Onboarding Terfokus (`OnboardingProfileScreen`):
  - **Layar Awal Onboarding (Step 0: Auth Gate):** Menjadikan layar pertama sebagai pusat autentikasi terfokus dengan form input Email & Kata Sandi, switcher tab "Masuk" / "Daftar Baru", tombol utama "Masuk / Daftar", tombol "Lanjutkan dengan Google", serta text button "Masuk tanpa akun" di paling bawah.
  - **Alur Setup Bertahap (Step 1..4):**
    - Memilih "Masuk tanpa akun" langsung membawa user ke Step 1 (Data Diri: Nama Lengkap, No. Telp, Gender) dalam mode tamu offline.
    - Login via Google berhasil otomatis memprefill Nama Lengkap dari metadata Google akun user ke Step 1 (Data Diri), dengan hak edit 100% tetap bebas disesuaikan user.
    - Login/Daftar via Email & Kata Sandi berhasil langsung membawa user ke Step 1 (Data Diri).
    - Setup multi-step lanjutan (Step 2: Tema & Tampilan, Step 3: Atur Dompet & Rekening, Step 4: Kategori Transaksi) tetap berjalan runtut dengan tombol "Lanjutkan" / "Lewati" dan diakhiri dengan tombol "Mulai Mencatat".
  - **Stepper Dinamis:** Indikator progress 4 langkah disembunyikan saat di Auth Gate (Step 0) dan aktif saat memasuki tahapan setup (Step 1..4).
- [x] Pembersihan Branding & Antarmuka Profil Pengguna (`SettingsScreen` & `OnboardingProfileScreen`):
  - Mengubah teks alert dan modal dialog hapus akun menjadi "Akun Yotro" ("Hapus Akun Yotro?", "Akun Yotro Anda").
  - Menghilangkan seluruh teks dan kata "Supabase" pada antarmuka UI pengguna (`SettingsScreen` dan `OnboardingProfileScreen`), menggantikannya dengan "Akun Cloud" / "Sinkronisasi Cloud".
  - Menyederhanakan kartu "Tentang Aplikasi" dengan membuang baris Database, Privasi, dan Lisensi.
  - Menghilangkan tombol konfigurasi kredensial Supabase (`_showSupabaseConfigSheet`) dari Sinkronisasi Cloud, menjadikan koneksi cloud privat dan seamless tanpa ekspos pengaturan teknis.
  - Verifikasi: Seluruh 150 tests lulus 100%. Kompilasi ulang Web dan APK release Android (`yotro-app.apk`).
- [x] Fitur Lupa Kata Sandi & Ganti Kata Sandi:
  - **Login Onboarding (`OnboardingProfileScreen`):** Tombol "Lupa kata sandi?" di bawah field password pada tab Masuk memicu modal sheet (`_showForgotPasswordSheet`) untuk mengirimkan link reset via email (`SupabaseAuthService.resetPassword`).
  - **Profil & Pengaturan (`SettingsScreen`):**
    - Sub-bagian "Keamanan Akun" di kartu Sinkronisasi Cloud hanya muncul jika akun terhubung (`isAuthenticated == true`).
    - Opsi **Ganti Kata Sandi**: Modal sheet (`_showChangePasswordSheet`) untuk menginput kata sandi baru dan konfirmasi kata sandi via `SupabaseAuthService.updatePassword`.
    - Opsi **Lupa Kata Sandi**: Modal sheet (`_showForgotPasswordSheet`) untuk mengirimkan tautan pemulihan sandi ke email akun cloud terdaftar.
    - Mode offline tetap bersih tanpa opsi kata sandi karena data tersimpan 100% lokal di perangkat.
  - **Backend Auth Service (`SupabaseAuthService`):** Penambahan method `updatePassword`, parameter `redirectTo` di `resetPassword`, dan pesan error bahasa Indonesia awam yang ramah di `formatAuthException`.
  - **Verifikasi & Build:** 151 unit & widget tests lulus 100% (`flutter test`). Kompilasi Web dan APK rilis Android berhasil.
- [x] In-App OTA Updater Android & Menu Catatan Rilis (Changelog):
  - **OTA Updater Service (`AppUpdateService`):** Integrasi GitHub Releases API (`repos/ianfrds/yotroapp/releases/latest`), komparasi semver dinamis (`maxParts` array matching), stream download biner APK dengan progress persentase, dan instalasi APK via FileProvider (`open_filex` + `REQUEST_INSTALL_PACKAGES`).
  - **In-Place Update Guarantee:** Pembaruan aplikasi via APK terverifikasi dengan application ID dan signature yang sama tidak menghapus sesi login Supabase maupun data lokal (`/data/data/com.moneytracker.app/...`).
  - **Modal Dialog Update (`AppUpdateDialog`):** Dialog dark matte sapphire dengan catatan rilis ringkas dan progress bar animasi unduhan.
  - **Menu Catatan Rilis (Changelog):** Hadir pada kartu "Tentang Aplikasi" di `SettingsScreen`, menampilkan modal bottom sheet (`_showChangelogSheet`) dengan riwayat versi lengkap (`ChangelogData` di `lib/models/changelog_model.dart`).
  - **Workflow GitHub Actions (`build-apk.yml`):** CI branch tetap menguji/membangun aplikasi, sedangkan publikasi biner `yotro-app.apk` ke GitHub Releases hanya berjalan pada push tag `v*` yang sama dengan versi `pubspec.yaml`.
- [x] Sinkronisasi Versi Aplikasi (Pubspec, Runtime PackageInfo, & Settings UI):
  - Versi kandidat rilis saat ini diselaraskan ke `2.0.4+12` di `pubspec.yaml` dan `ChangelogData`; Android memakai `versionName: 2.0.4` dan `versionCode: 12`.
  - Mengubah tampilan versi pada menu "Tentang Aplikasi" di `SettingsScreen` dari hardcoded text menjadi `FutureBuilder<String>` dinamis via `AppUpdateService.getCurrentVersion()`.
  - Menghilangkan diskrepansi antara dialog installer OS Android dengan label versi internal aplikasi.
- [x] Desain & UX Dialog Pembaruan In-App (`AppUpdateDialog` & `ChangelogModel`):
  - Mengubah label tombol aksi dari "Perbarui Sekarang" menjadi "Update Now" dan membungkusnya dalam `FittedBox(fit: BoxFit.scaleDown)` serta padding horizontal 8px agar tidak melipat vertikal ("atas bawah") di layar perangkat sempit.
  - Menghapus tampilan URL mentah GitHub (`https://github.com/...`) dan jargon commit developer dari catatan pembaruan.
  - Menambahkan method `_getUserFriendlyReleaseNotes()` yang memprioritaskan catatan rilis berbahasa Indonesia dari `ChangelogData.getRelease(tagName)` atau menyaring teks bersih berorientasi pengguna ("Pembaruan lebih optimal", "Penyempurnaan tampilan antarmuka", dsb).
- [x] Otomatisasi Rilis Aman GitHub Actions (`.github/workflows/build-apk.yml`):
  - Push branch `main`/`master` dan pull request hanya menjalankan tes serta build validasi; publikasi GitHub Release hanya berjalan saat tag `v*` di-push.
  - Versi diekstrak langsung dari `pubspec.yaml` (`APP_VERSION=2.0.4`), tag wajib persis `v2.0.4`, dan release hanya mengunggah satu APK ARM64 `yotro-app.apk`.
- [x] Bypass Onboarding Otomatis untuk Akun Terdaftar (Email & Google):
  - Eliminasi bug di mana akun yang sudah terdaftar dipaksa masuk ke Onboarding Setup ulang.
  - Penambahan method `_handleExistingUserAuthSuccess()` di `OnboardingProfileScreen`: otomatis menarik data transaksi, dompet, dan profil dari Supabase via `pullCloudData()`, menandai onboarding selesai, dan langsung melakukan routing ke `MainShell` (Beranda).
  - Pengecekan cerdas `hasExistingUserData()` di `SupabaseSyncService`: membedakan pendaftar Google baru dengan pengguna Google yang sudah memiliki akun/data.
  - Penyempurnaan `SplashScreen`: mendeteksi sesi Supabase aktif yang belum sinkron lokal dan mengarahkan langsung ke Beranda.
- [x] Perbaikan CI/CD GitHub Actions & AGP 9.1.0 Alignment (`.github/workflows/build-apk.yml`, `android/settings.gradle`, `android/gradle/wrapper/gradle-wrapper.properties`, `pubspec.yaml`):
  - Mengatasi error crash `line 13: ApplicationExtension.getDefaultConfig()` di runner GitHub Actions. Masalah ini merupakan isu resmi Flutter (Flutter SDK stable 3.47+ / 3.50 mengompilasi `flutter-gradle-plugin` terhadap AGP 9.1.0+ sehingga pemanggilan `ApplicationExtension.getDefaultConfig()` pada AGP versi 8.x memicu `NoSuchMethodError`).
  - Meng-upgrade Android Gradle Plugin ke AGP **`9.1.0`**, Kotlin ke **`2.4.0`**, dan Gradle Wrapper ke **`gradle-9.3.1-all.zip`** (standar resmi Flutter stable terkini).
  - Menambahkan `"build-tools;36.0.0"` pada instalasi Android SDK runner GitHub Actions.
  - Mempertahankan `permission_handler: 11.3.1` (platform SDK compileSdk 34 standar, aman dari broken experimental SDK 37).
  - `make_latest: "true"` hanya dijalankan pada tag rilis tervalidasi, sehingga push `main` tidak lagi menimpa target `latest` di GitHub API (`https://api.github.com/repos/ianfrds/yotroapp/releases/latest`).
  - **Handover rilis v2.0.4:** Empat signing secrets produksi sudah dikonfigurasi. User perlu commit perubahan, push branch, lalu membuat dan push tag `v2.0.4` secara manual. Rilis `v2.0.3` sebelumnya dibuat dengan signing key CI sementara dan tidak boleh didistribusikan.
  - Perangkat yang memasang APK dengan signature lama perlu mencadangkan data lalu uninstall satu kali sebelum memasang `v2.0.4`; setelah itu pembaruan berikutnya dapat dipasang in-place selama release key yang sama dipertahankan.
  - Hasil uji: kompilasi lokal (`flutter build apk --release --split-per-abi`) sukses 100% via Gradle 9.3.1 (29.8MB armv7, 36.2MB arm64, 38.5MB x86_64) dan 155 unit & widget test lulus 100%. Web release dan APK tersalin di `yotro-app.apk` dan `build/web/yotro-app.apk`.
- [x] Verifikasi v2.0.4: **155 test lulus, 1 test dilewati** (`flutter test`), test OTA/changelog lulus 4/4, YAML workflow valid, dan `git diff --check` bersih. Build Web/APK lokal tidak dijalankan agar penggunaan storage tetap kecil; build ARM64 dan Web dilakukan oleh GitHub Actions.
- [x] File handover AI context di `context.md`.
- [x] Aturan otomatisasi workspace agent di `AGENTS.md` dan `GEMINI.md` (auto-sync `context.md`).

---

## 7. Instruksi untuk AI Coding Assistant Selanjutnya

Saat melanjutkan proyek ini:
1. **Kebijakan Git & Push Manual (MANDATORI):**
   - AI agent **DILARANG MELAKUKAN GIT PUSH OTOMATIS** saat melakukan perubahan kode atau berkas proyek.
   - Semua operasi commit dan push ke remote `origin` selanjutnya dilakukan **secara manual oleh user**.
2. **Patuhi `design.md` & Anti-Slop:**
   - Dark mode default (`#1C2229`, `#0C131D`, `#131A26`), Light mode monokrom netral (`#F4F5F7`, `#FFFFFF`, `#0F172A`, `#E2E8F0`).
   - Tipografi `Inter Tight` + `Manrope` (maksimal `FontWeight.w600`, `FontWeight.w500` untuk hero display, zero `bold`).
   - Dilarang keras menggunakan emoji dekoratif pada copy/button (emoji hanya untuk data kategori).
3. **Pahami Pemisahan Mode Tampilan & Saldo:**
   - `dashboardViewMode`: Enum 3 mode (`complete`, `incomeExpense`, `expenseOnly`).
   - Pada mode `expenseOnly`, kartu hero menampilkan "Total Pengeluaran" dan sub-kartu disembunyikan.
4. **Theme Mode:**
   - Mendukung 3 mode: `ThemeMode.system`, `ThemeMode.light`, `ThemeMode.dark` tersimpan persisten di `SharedPreferences`.
5. **Month Filter Konsisten:**
   - Gunakan `AppMonthFilterPill` dan `showAppMonthFilterSheet` dari `lib/widgets/month_filter_sheet.dart` untuk semua filter periode bulanan di Beranda, Analisis, dan Laporan Keuangan.
6. **Sinkronisasi Dompet & Transaksi:**
   - Perubahan saldo dompet memicu transaksi pemasukan/pengeluaran otomatis jika `syncWalletToTransactions` bernilai `true`.
   - `addWallet()` dan `updateWallet()` menerima parameter opsional `bool? syncToTransaction` untuk kontrol per-aksi.
7. **Integrasi Cloud, Multi-Auth, Auth Gate Onboarding & Hapus Akun:**
   - Backend Cloud: Supabase project `njjcviwihzvzjgfbzitg` (`https://njjcviwihzvzjgfbzitg.supabase.co`) terintegrasi privat di `SupabaseConfig`.
   - Zero "Supabase" text di user interface: Seluruh UI merujuk ke "Akun Cloud", "Sinkronisasi Cloud", dan "Akun Yotro".
   - Layar Onboarding: Step 0 adalah Auth Gate (Email & Password, Google Sign-In, Masuk tanpa akun). Memilih opsi manapun mengalirkan user ke Step 1 (Data Diri, nama prefill dari Google 100% editable) -> Step 2 (Tema & Tampilan) -> Step 3 (Dompet) -> Step 4 (Kategori).
   - Hapus Akun via RPC `delete_user_account()` di PostgreSQL cascade delete data `auth.users` dan tabel relasional. Dialog bertajuk "Hapus Akun Yotro?".
   - Aplikasi mempertahankan prinsip offline-first (zero hard crash jika offline atau anon key kosong).
   - MCP Supabase terhubung di `~/.gemini/antigravity/mcp_config.json`.
8. **In-App OTA Updater & Changelog Invariants:**
   - Model rilis GitHub: `ianfrds/yotroapp`.
   - `package_info_plus: ^10.2.2` & `open_filex: ^4.7.0` mengelola deteksi versi dan instalasi paket.
   - Versi saat ini di `pubspec.yaml` adalah `2.0.4+12` dengan `ChangelogData.currentVersion = '2.0.4'`.
   - Workflow `.github/workflows/build-apk.yml` membangun branch/PR untuk validasi, tetapi hanya menerbitkan GitHub Release saat tag `v*` yang sama dengan versi `pubspec.yaml` di-push.
   - Jangan distribusikan rilis `v2.0.3`; signature-nya berasal dari keystore CI sementara. Kandidat produksi berikutnya adalah tag `v2.0.4` dengan empat signing secrets produksi.
   - Dialog pembaruan `AppUpdateDialog` menggunakan tombol ringkas "Update Now" single-line dan catatan rilis ramah pengguna tanpa URL commit mentah.
   - APK distribusi hanya menargetkan `android-arm64`; jangan mengembalikan artifact ARM32, x86_64, atau universal kecuali kebutuhan kompatibilitas berubah.
   - Sesi login akun dan database SQLite/SharedPreferences aman dari logout saat update berjalan.
9. **Keamanan Sideload & Izin Minimal:**
   - Fitur pembaca notifikasi real-time (`BIND_NOTIFICATION_LISTENER_SERVICE`) telah **dihapus permanen** agar APK sideload tidak memicu peringatan Android Restricted Settings atau dianggap membahayakan.
   - Aplikasi hanya menggunakan izin notifikasi standar lokal (`POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`) untuk pengingat transaksi harian offline dan `REQUEST_INSTALL_PACKAGES` untuk update mandiri in-app.
10. **Kategori Finansial:**
   - Seluruh kategori default wajib menggunakan Bahasa Indonesia (Makanan & Minuman, Transportasi, Belanja, Tagihan & Utilitas, dsb).
11. **Sinkronisasi `context.md` Wajib:** Setiap kali berkas diubah, perbarui `context.md` sebelum mengakhiri giliran.
12. **Tone Komunikasi:** Sesuai preferensi user, berikan jawaban terfokus pada hasil teknis (*terse smart caveman*), langsung ke fakta dan link berkas.
13. **Preview Web & Unduh APK:**
    - Preview UI/fungsional harian dijalankan dengan `flutter run -d chrome --web-port 8080` dan disajikan di `http://localhost:8080/`; hot reload tetap menjadi alur utama.
    - `flutter build web --release` hanya diperlukan untuk verifikasi production Web. APK resmi ARM64 disimpan pada GitHub Releases, bukan permanen di root proyek atau `build/web/` lokal.

