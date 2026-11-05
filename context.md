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
│       └── build-apk.yml           # CI test + signed safe-release APK + Flutter Web
├── android/                        # Android harness (AGP 8.11.1, Kotlin 2.2.21, SDK 37, AndroidX)
│   └── key.properties.example      # Template konfigurasi signing; key asli wajib private/diabaikan Git
├── assets/
│   └── images/                     # Official brand logos (logo_blue_transparent, logo_white_black, logo_white_blue, logo.png) + onboarding_bg.jpg (fluted blue glass artwork)
├── yotro-app.apk                   # Signed release APK v1.0.4+5 (siap diunduh langsung via web runner atau disalin ke HP)
├── yotro-safe-release.apk          # Legacy APK v1.0.3+4
├── yotro-safe-release.apk.sha256   # Checksum integritas APK aman
├── yotro-release.apk               # Legacy debug-signed APK; jangan didistribusikan
├── money-tracker-release.apk       # Legacy debug-signed APK; jangan didistribusikan
├── web/
│   ├── favicon.png                 # Official brand 32x32 favicon
│   ├── icons/                      # Web icons (192x192, 512x512 maskable)
│   └── index.html                  # Bootstrap Flutter Web/PWA + Floating Unduh APK pill
├── lib/
│   ├── main.dart                   # Entry point aplikasi Flutter (YotroApp)
│   ├── config/
│   │   └── app_capabilities.dart   # Build-time capability gate untuk Notification Reader sensitif
│   ├── widgets/
│   │   ├── app_snackbar.dart       # High-contrast floating snackbar helper (anti-slop, rounded, with status icons)
│   │   ├── standard_screen_header.dart # Header terstandarisasi untuk semua sub-halaman (tombol back + judul)
│   ├── theme/
│   │   ├── app_colors.dart         # Token warna, gradien, dan palet gelap matte
│   │   └── app_theme.dart          # Integrasi Forui & Google Fonts ThemeData
│   ├── models/
│   │   ├── transaction_model.dart  # Model data transaksi (Income, Expense, Transfer)
│   │   ├── category_model.dart     # Kategori pengeluaran & pemasukan default/kustom
│   │   ├── wallet_model.dart       # Model dompet/rekening (Bank, Cash, E-Wallet, dsb)
│   │   ├── budget_model.dart       # Model anggaran bulanan & anggaran per kategori
│   │   └── notification_rule_model.dart # Aturan pemicu/abaikan deteksi notifikasi & antrean pending approval
│   ├── providers/
│   │   └── transaction_provider.dart # State manager, mutasi saldo, kalkulasi budget, tema, pembaca notifikasi, I/O
│   ├── services/
│   │   ├── storage_service.dart    # Helper abstraksi penyimpanan lokal
│   │   ├── backup_storage_service.dart # Export/Download berkas cadangan JSON lintas platform (Web & Android)
│   │   ├── backup_storage_stub.dart    # Implementasi ekspor cadangan via temporary file & system share sheet (Android/iOS)
│   │   ├── backup_storage_web.dart     # Implementasi unduh berkas cadangan via Blob & HTML anchor download (Web)
│   │   └── native_notification_service.dart # Notifikasi lokal, jadwal inexact, dan listener internal yang digate capability
│   ├── screens/
│   │   ├── splash_screen.dart      # Layar Splash Screen beranimasi dengan logo Yotro & navigasi kondisional onboarding/main
│   │   ├── onboarding_profile_screen.dart # Layar Baru Onboarding Data Pengguna Pertama Kali (Nama, No Telp, Gender & trigger izin notifikasi native)
│   │   ├── main_shell.dart         # Scaffold utama dengan IndexedStack, Floating Dock, dan PopScope (double back exit / return to Beranda)
│   │   ├── dashboard_screen.dart   # Layar Beranda (Hero Card, Kartu Persetujuan Notifikasi Anti-Slop, Quick Action, Transaksi, bell navigates to NotificationsCenterScreen)
│   │   ├── notifications_center_screen.dart # Layar Pusat Notifikasi Mandiri (Persetujuan mutasi perbankan/e-wallet, status pengingat harian, uji coba push notifikasi)
│   │   ├── transactions_screen.dart# Riwayat transaksi, pencarian, dan multi-filter
│   │   ├── add_transaction_screen.dart # Form input/edit transaksi (Autofocus nominal keyboard instan, dialog konfirmasi hapus permanen)
│   │   ├── transaction_success_screen.dart # Layar Penuh Transaksi Berhasil Dicatat (Animasi checklist bergaya Lottie, ringkasan transaksi, aksi cepat)
│   │   ├── budget_screen.dart      # Pengaturan budget bulanan/kategori & progress threshold
│   │   ├── budget_detail_screen.dart # Layar Rincian Anggaran: ringkasan sisa/terpakai, statistik bar chart, riwayat transaksi kategori & opsi kelola budget
│   │   ├── wallets_screen.dart     # Manajemen multi-dompet & transfer antar-dompet
│   │   ├── analytics_screen.dart   # Laporan Keuangan murni di tab bottom nav bar (Donut/Bar toggle & breakdown)
│   │   ├── financial_analysis_screen.dart # Fitur Analisis Keuangan mandiri dari aksi cepat Beranda (Skor kesehatan, meter, diagnosa cerdas & statistik arus kas)
│   │   ├── split_bill_screen.dart  # Fitur Split Bill pembagian tagihan, pajak/tip, status bayar & catat ke transaksi
│   │   ├── settings_screen.dart    # Layar Profil & Pengaturan (Akun, preferensi tema, mata uang, navigasi halaman mandiri, backup/restore JSON, zona bahaya)
│   │   ├── display_preferences_screen.dart # Layar Baru Pemilihan Preferensi Tampilan (Complete View, Income/Expense, Expense Only dengan wireframe live preview)
│   │   ├── manage_categories_screen.dart # Layar Kelola Kategori (Daftar kategori Pengeluaran & Pemasukan, navigasi ke form layar baru, modal hapus kartu)
│   │   └── edit_category_screen.dart # Layar Baru Tambah & Ubah Kategori (NestedCard, palet warna, tab Icon & Emoji murni)
│   ├── utils/
│   │   ├── icon_catalog.dart       # Katalog terverifikasi Tabler Icons & Emoji populer finansial
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
│       └── category_chip.dart      # Chip pemilihan kategori
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

### 3.5 Wallet Management
- Tipe default: Bank Account, Cash, E-Wallet, Savings, Other.
- Fitur: Multi-wallet dengan saldo terpisah, mutasi transfer antar-dompet, riwayat per dompet.

### 3.6 Reports & Analytics (Layar Laporan / Report Screen Redesign)
- **Rhythm & Spasi Antar-Kartu (Universal 12px Spacing):**
  - Jarak spasi vertikal antar-kartu di Layar Laporan disamakan dengan Beranda menjadi `12px` (`const SizedBox(height: 12)`) antara Segmented Pill, Hero Report Card, dan Rincian Kategori.
- **Default View Mode:** Saat layar Laporan pertama kali dibuka, visualisasi default adalah **Bar Chart** (`WeeklyActivityChart`), dengan tombol toggle cepat untuk beralih ke Donut Chart.
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
  - Tombol aksi utama diseragamkan dengan seluruh aplikasi: `ElevatedButton.icon` sapphire `#0066FF`, tinggi `48px`, border radius `14px`, teks putih `w600` (zero cyan-black slop).
  - Tombol sekunder `OutlinedButton.icon` ("Salin Teks") dengan tinggi `48px`, radius `14px`, dan border halus `0.12`.
  - Tombol modal simpan item & edit nama menggunakan tombol elevated standar `44px` beradius `12px`.

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
  - **Mata Uang Acuan:** Dropdown IDR (Rp) vs USD (\$) tersinkron ke `provider.setCurrency` (tampilan ringkas title-only).
  - **Preferensi Tampilan (3 Mode):** Menggantikan switch lama dengan bottom sheet pilihan (`showModalCardSheet`) yang memiliki 3 mode:
    1. `Complete View`: Tampilan default lengkap (saldo, pengeluaran, pemasukan).
    2. `Pemasukan dan Pengeluaran`: Sembunyikan view saldo saat ini di kartu beranda.
    3. `Pengeluaran saja`: Fokus pada tampilan pengeluaran saja (tanpa saldo & pemasukan).
- **3. Cadangan & Pemulihan Data (Offline JSON — Modal Bottom Sheet):**
  - **Ekspor Cadangan:** Menampilkan preview string format snapshot JSON lengkap dan tombol `Salin JSON ke Clipboard` dalam bottom sheet modal.
  - **Pulihkan Data (Restore):** Validasi format JSON otomatis (`validateBackupJson`), menampilkan ringkasan transaksi & dompet yang terdeteksi, serta dua pilihan aksi pemulihan aman: `Merge Data` (menggabungkan tanpa duplikasi ID) atau `Replace Data` (menimpa seluruh database) dalam bottom sheet modal.
- **4. Zona Bahaya (Danger Zone — Modal Bottom Sheet):**
  - **Kosongkan Riwayat Transaksi:** Bottom sheet konfirmasi merah untuk menghapus seluruh riwayat mutasi dan menolkan saldo rekening.
  - **Reset ke Data Bawaan (Factory Seed):** Menyetel nama default pengguna menjadi **"John Doe"** dan memuat 17 transaksi realistis lintas 4 dompet dan 5 kategori anggaran.
  - **Catatan Pembersihan:** Tombol "Keluar Akun (Uji Onboarding)" telah dihapus permanen dari zona bahaya dan beranda agar APK rilis bersih tanpa opsi logout pengujian.
- **5. Tentang Aplikasi & Keamanan:**
  - Badge `Offline-First` hijau pada header.
  - Keterangan status database lokal (`SharedPreferences`), nihil pelacakan cloud, dan arsitektur anti-slop.

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
- **Aksi Simpan:** Tombol primer elevated oceanic sapphire (`#02539A`) dengan validasi nama tidak kosong.

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
Sebelum menjalankan workflow, isi GitHub Actions Secrets `YOTRO_KEYSTORE_BASE64`, `YOTRO_STORE_PASSWORD`, `YOTRO_KEY_PASSWORD`, dan `YOTRO_KEY_ALIAS`. Artifact yang dihasilkan adalah APK release bertanda tangan dan Flutter Web.

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
- [ ] Konfigurasikan empat GitHub Actions Secrets signing sebelum memakai cloud release workflow.
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
- [x] Kompilasi Ulang Web Release & Signed Release APK:
  - Seluruh 78 unit dan widget test lolos 100% (`flutter test`).
  - Web release diperbarui di `build/web/` dan live preview port `8080`.
  - Android release APK diperbarui di [`yotro-app.apk`](yotro-app.apk) dan `build/web/yotro-app.apk`.
- [x] Dokumentasi desain komprehensif di `design.md`.
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
   - Dilarang keras menggunakan emoji dekoratif pada copy/button (emoji hanya untuk ikon kategori).
3. **Pahami Pemisahan Mode Tampilan & Saldo:**
   - `dashboardViewMode`: Enum 3 mode (`complete`, `incomeExpense`, `expenseOnly`).
   - Pada mode `expenseOnly`, kartu hero menampilkan "Total Pengeluaran" dan sub-kartu disembunyikan.
4. **Keamanan Sideload & Izin Minimal:**
   - Fitur pembaca notifikasi real-time (`BIND_NOTIFICATION_LISTENER_SERVICE`) telah **dihapus permanen** agar APK sideload tidak memicu peringatan Android Restricted Settings atau dianggap membahayakan.
   - Aplikasi hanya menggunakan izin notifikasi standar lokal (`POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`) untuk pengingat transaksi harian offline.
   - Jangan pernah menambahkan kembali service pembaca notifikasi tanpa persetujuan eksplisit user.
5. **Kategori Finansial:**
   - Seluruh kategori default wajib menggunakan Bahasa Indonesia (Makanan & Minuman, Transportasi, Belanja, Tagihan & Utilitas, dsb).
   - Layar tambah/edit kategori dibuka via modal bottom sheet setinggi 94% layar (`EditCategoryScreen.showAsModalSheet`).
6. **Cadangan & Pemulihan:**
   - Ekspor menggunakan `BackupStorageService` yang menghasilkan berkas `.json` nyata.
   - Pulihkan mendukung pilih berkas `.json` via `FilePicker` atau tempel teks.
7. **Aktivitas Transaksi Dual Bar:**
   - Gunakan `WeeklyActivityChart(isDualBar: true, title: 'Aktivitas Transaksi')` di Beranda. Auto-hide saat minggu kosong.
8. **Sinkronisasi `context.md` Wajib:** Setiap kali berkas diubah, perbarui `context.md` sebelum mengakhiri giliran.
9. **Tone Komunikasi:** Sesuai preferensi user, berikan jawaban terfokus pada hasil teknis (*terse smart caveman*), langsung ke fakta dan link berkas.
10. **Preview Web:** Build Flutter Web adalah sumber preview yang setara dengan kode `lib/`; disajikan di `http://localhost:8080/`.

