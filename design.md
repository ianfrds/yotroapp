# Design System - Money Tracker (Dark Minimalist)

Dokumen ini mendefinisikan seluruh standar desain, visual token, aturan anti-slop, dan spesifikasi komponen antarmuka aplikasi **Money Tracker**. Standar ini mengunci gaya antarmuka yang terverifikasi pada implementasi Flutter & Web.

---

## 1. Prinsip Utama (Core Principles)

1. **Zero-Slop Dark Matte:** Latar belakang solid hitam pekat dan slate gelap tanpa gradien generik biru-ungu di luar kartu hero.
2. **One Deliberate Accent (Fluid Mesh Gradient):** Efek *fluid mesh gradient* hanya diizinkan di dalam komponen kartu virtual debit (*hero card*).
3. **High Contrast Typography:** Angka finansial berukuran besar (30px - 38px), tajam, dan mudah dibaca secara instan.
4. **Clean Action Hierarchy:** Tombol aksi utama (*primary CTA*) berwarna putih solid dengan ikon/teks hitam pekat. Tombol sekunder menggunakan permukaan gelap matte.
5. **No Decorative Emoji:** Seluruh antarmuka dilarang menggunakan emoji dekoratif. Hanya gunakan ikon vektor geometris murni.
6. **Active Navigation:** Semua kontrol interaktif (tab bar, segmented pill, tombol aksi, filter) memiliki aksi nyata dan fungsi berpindah layar.

---

## 2. Palet Warna (Color Tokens)

### 2.1 Warna Dasar & Permukaan
| Token | Nilai Hex / RGBA | Kegunaan |
| :--- | :--- | :--- |
| `background-outer` | `#0E1217` | Canvas viewport browser terluar |
| `background-app` | `#1C2229` | Latar belakang kanvas aplikasi utama ponsel |
| `surface-default` | `#0C131D` | Kontainer luar kartu reusable (`NestedCard`), pill segment |
| `surface-card` | `#131A26` | Wadah kartu dalam ("Card Inside Card") |
| `surface-elevated`| `#182230` | Kontainer input isian form, chip cepat |
| `border-subtle` | `rgba(255, 255, 255, 0.06 - 0.08)` | Garis batas tipis 1px pada kontainer |

### 2.2 Tipografi
| Token | Nilai Hex | Kegunaan |
| :--- | :--- | :--- |
| `text-primary` | `#FFFFFF` | Judul, saldo hero, teks interaktif utama, angka nominal |
| `text-secondary`| `#8E95A5` | Label form, subtitle, tanggal, tombol non-aktif |
| `text-muted` | `#5A6275` | Sumbu hari grafik, hint teks, keterangan sekunder |

### 2.3 Aksen & Sorotan
| Token | Nilai Hex | Kegunaan |
| :--- | :--- | :--- |
| `accent-primary` | `#FFFFFF` | Tombol CTA utama (Top Up, Confirm Save), pill aktif |
| `accent-dark` | `#000000` | Ikon & teks di atas elemen putih solid |
| `highlight-lavender`| `#939CFE` | Batang grafik aktif (Saturday highlight) & tag |
| `indicator-green` | `#10B981` | Pemasukan / nilai positif (+), indikator sinkron |
| `indicator-red` | `#F43F5E` | Pengeluaran / nilai negatif (-) |

### 2.4 Luxury Sapphire Fin-tech Tokens & Components
- **Sapphire Fin-tech Hero Card (Radial Gradient):**
  - `radial-gradient(95.69% 108.33% at 50% 100%, #041735 0%, #001732 36.06%, #00498C 100%)`
  - Border halus: `rgba(255, 255, 255, 0.12)`
  - Zero-slop shadow: Menghilangkan drop-shadow berlebih pada hero card dan status dot glow (R-12, R-13). Elevasi murni dibangun lewat kontras latar matte `#0C131D` dan border 1px.
  - Sub-cards internal: frosted slate `rgba(35, 55, 77, 0.55)` dengan border tipis 1px `rgba(255, 255, 255, 0.14)`.
  - Privacy Masking (`isBalanceVisible`): Saat toggle mata ditekan, nominal finansial pada panel hero (Saldo utama, Pengeluaran, dan Pemasukan) disamarkan serentak menggunakan masking titik (`Rp ••••••••` dan `Rp ••••••`).
  - Collapsible Card View (`hideBalanceSection`): Dikontrol dari Pengaturan ("Sembunyikan Saldo"). Saat aktif (`true`), seluruh baris "Saldo saat ini" dihilangkan sehingga kartu mengempis ke atas dan sub-pod pengeluaran & pemasukan naik ke posisi atas.
- **Cash Flow Retention Metric:**
  - Retensi Arus Kas indikator (92% tersimpan, 8% pengeluaran).
- **Daily Spending Control Gauge (Semicircular Arc):**
  - Track dasar: `#0c1b30`
  - Arc gradien aktif: `linear-gradient(to right, #38BDF8, #FFFFFF)`
  - 3 pod metrik: Target Harian (`Rp 100.000`), Sisa Hari Ini (`Rp 75.000`), Sisa Bulanan (`Rp 1.680.000`).
- **Category Badge Tokens:**
  - Food & Beverage: Amber tint `#F59E0B`
  - Transportation: Sky Blue tint `#0284C7`
  - Bills & Utilities: Purple tint `#9333EA`
  - Shopping: Rose tint `#E11D48`
  - Salary: Emerald tint `#059669`

---

## 3. Tipografi & Skala Teks (Font Pairing: Inter Tight & Manrope)

Sistem tipografi menggunakan perpaduan dua jenis huruf sans-serif geometris modern:
- **Inter Tight:** Digunakan untuk judul (*headings*), display angka finansial hero, dan angka metrik karena karakternya yang tegas, rapat (*tight letterforms*), dan presisi tinggi.
- **Manrope:** Digunakan untuk teks isi (*body text*), label input form, subtitle, dan navigasi antarmuka karena bentuk geometrisnya yang bersahabat (*friendly geometric curves*) dengan keterbacaan optimal.

### Skala Tipografi:
> [!IMPORTANT]
> **Aturan Bobot Font (Weight Constraint):**
> Baik untuk `Inter Tight` maupun `Manrope`, **DILARANG** menggunakan bobot `bold`, `w700`, `w800`, atau `extrabold`. Bobot maksimal yang diizinkan di seluruh antarmuka adalah **`SemiBold` (`FontWeight.w600`)** untuk menjaga estetika editorial yang rapi, ramping, dan non-slop.

- **Display Hero Numbers (Inter Tight):** `30px` hingga `38px`, ketebalan maksimal `SemiBold (w600)`, letter-spacing `-0.6px`. Digunakan untuk Total Saldo dan Nominal Form.
- **Section Heading (Inter Tight):** `15px` - `18px`, ketebalan `SemiBold (w600)`. Contoh: "Recent Transactions", "Analytics", "Budget Management".
- **Card Subhead & Inputs (Inter Tight / Manrope):** `13px` - `14px`, ketebalan `SemiBold (w600)` atau `Medium (w500)`. Contoh: Nama merchant, opsi dropdown, judul transaksi.
- **Body & Subtitle (Manrope):** `12px` - `14px`, ketebalan `Regular (w400)` atau `Medium (w500)`, warna `text-secondary`. Contoh: "Welcome back,", label tanggal.
- **Micro Label / Badge (Manrope):** `10px` - `11px`, ketebalan `Medium (w500)` atau `SemiBold (w600)`. Contoh: "Main card **** 6510", label hari "Mon", badge tooltip `$231.87`.

---

## 3.1 Integrasi Komponen UI (Forui - forui.dev)

Aplikasi mengadopsi standar pustaka komponen **Forui** (`forui: ^0.27.7`), yang menghadirkan pola arsitektur minimalis modern bergaya *shadcn/ui* ke Flutter:
- **Tema Forui:** Menggunakan `FTheme` dengan varian `FThemes.slate.dark` sebagai kontainer tema global.
- **Ikonografi:** Ikon Lucide geometris (`forui_lucide` / SVG murni) tanpa emoji dekoratif, konsisten di seluruh aplikasi.
- **Prinsip Forui:** Struktur komponen bersih, modular, dan dapat dikustomisasi tanpa boilerplate berlebih.

---

## 4. Bentuk, Spasi & Elevasi

### 4.1 Border Radius
- **Frame Ponsel:** `44px` hingga `48px`.
- **Hero Virtual Card:** `28px`.
- **Form Input, Modal & Kartu Grid:** `16px` hingga `18px`.
- **Tombol Aksi Cepat (Send / Receive / Top Up):** `16px`.
- **Segmented Control & Floating Nav Dock:** `Pill-shaped` (radius maksimal `24px` - `32px`).
- **Badge & Ikon Container:** Lingkaran penuh (`circle`).

### 4.2 Elevasi (Shadow)
- Menghindari bayangan tebal melayang (*floating drop-shadow slop*).
- Hirarki elevasi dibangun dari perbedaan warna kontras (latar `#0C0E14` vs kartu `#181C26`) dipadukan dengan *border stroke* 1px opasitas rendah (`rgba(255, 255, 255, 0.08)`).
- Bayangan hanya digunakan pada floating dock bawah (`0 10px 25px rgba(0, 0, 0, 0.5)`) dan tombol putih primer.

### 4.3 Spasi & Margin Layar (Horizontal Margins)
> [!IMPORTANT]
> **Margin Horizontal Tepi Layar:**
> Seluruh padding horizontal layar dan kontainer utama diatur ketat pada rentang **`12px` - `14px`** (menggantikan margin lebar 20px sebelumnya). Hal ini memaksimalkan ruang guna pada viewport ponsel/tablet serta menghasilkan tampilan *fin-tech* yang padat, presisi, dan modern.
> - Padding layar: `EdgeInsets.symmetric(horizontal: 12, vertical: 12)` / `EdgeInsets.fromLTRB(12, 16, 12, 124)`.
> - Floating dock bottom nav: `minimum: EdgeInsets.fromLTRB(12, 0, 12, 12)`.
> - Padding dalam kartu: `EdgeInsets.symmetric(horizontal: 16, vertical: 18)` atau `EdgeInsets.all(12-16)`.

---

## 5. Komponen Inti Antarmuka

### 5.0 Header Beranda (Clean Editorial App Bar)
- **Struktur Header Minimalis:**
  - Tanpa foto/avatar profil, langsung menampilkan sapaan kontekstual dan nama pengguna.
- **Tipografi Sapaan & Nama:**
  - Sapaan kontekstual ("Selamat pagi/siang/sore/malam") berukuran `11px`, `FontWeight.w500`, warna `#8EA4BE`.
  - Nama pengguna ("Ian Firdaus 👋") berukuran kompak `16px`, menggunakan bobot **`Medium (FontWeight.w500)`** (`Inter Tight`, letter-spacing: `-0.2px`) untuk tampilan halus dan rapi.
- **Tombol Notifikasi:**
  - Tombol sirkular minimalis `36x36px` (`shape: BoxShape.circle`, warna `rgba(255, 255, 255, 0.06)`), ikon `19px`.
- **Spasi Vertikal:** Padding atas `12px`, jarak ke kartu saldo `14px`.

### 5.1 Hero Sapphire Balance Panel (Card Inside Card Layout)
- **Outer Container Card:**
  - Latar belakang dark charcoal `#0C131D`, border radius `26px`, border tipis `rgba(255, 255, 255, 0.08)`.
  - Zero-slop shadow: tidak ada drop-shadow mengambang berlebih (R-12).
  - Padding tipis menyelubungi kartu dalam: `fromLTRB(5, 5, 5, 10)`.
- **Inner Sapphire Radial Gradient Card ("Card Inside Card"):**
  - Mengambang di bagian atas kontainer dengan margin tipis dan sudut membulat penuh (`borderRadius: 22px`).
  - Gradien radial presisi: `radial-gradient(95.69% 108.33% at 50% 100%, #041735 0%, #001732 36.06%, #00498C 100%)`.
  - Padding tipis ringkas: `fromLTRB(6, 10, 6, 6)`.
  - Baris atas: Pill selector periode waktu transparan (`September ▼`) di kiri, tombol ikon mata sembunyikan saldo di kanan (inset horizontal `6px`).
  - **Collapsible Balance Behavior:**
    - Saat saldo aktif: Menampilkan label "Saldo saat ini" di atas angka display hero `Rp 132.400` menggunakan bobot **`Medium (FontWeight.w500)`** (`Inter Tight`, letterSpacing: `-0.6px`, inset horizontal `6px`).
    - Saat sembunyikan saldo aktif (mata tertutup): Seluruh konten "Saldo saat ini" dan nominal dihilangkan; kartu mengempis naik ke atas secara kompak sehingga sub-cards Pengeluaran dan Pemasukan langsung berada di bawah baris dropdown dan ikon mata (sesuai wireframe referensi).
  - Sub-Cards Internal Ganda (Mepet kanan-kiri dengan jarak 6px dari batas kartu sapphire, gap antar-subcard 6px):
    - Wadah frosted slate `rgba(35, 55, 77, 0.55)` dengan border tipis `rgba(255, 255, 255, 0.14)` dan radius `15px`.
    - Pengeluaran: Badge kotak putih dengan ikon minus merah `[-]`, label "Pengeluaran", dan nominal `- Rp 320.000` (tetap terlihat).
    - Pemasukan: Badge kotak putih dengan ikon plus hijau `[+]`, label "Pemasukan", dan nominal `+ Rp 4.000.000` (tetap terlihat).
- **Bottom 4-Action Dock (Di Bagian Bawah Outer Card):**
  - Berada di bawah kartu sapphire dalam wadah outer card yang sama.
  - 4 kolom aksi terbagi merata dengan pembatas garis vertikal tipis (`1px rgba(255, 255, 255, 0.08)`):
    1. **Masuk:** Ikon `↘` (`Icons.south_east_rounded`), label "Masuk".
    2. **Keluar:** Ikon `↗` (`Icons.north_east_rounded`), label "Keluar".
    3. **Budget:** Ikon `Icons.donut_small_rounded`, label "Budget".
    4. **Dompet:** Ikon `Icons.account_balance_wallet_outlined`, label "Dompet".

### 5.2 Sistem Kartu Reusable (Card Inside Card Layout — `NestedCard`)
- **Outer Container:**
  - Latar belakang dark slate `#0C131D`, border radius `26px`, border tipis `1px rgba(255, 255, 255, 0.08)`.
  - Header terintegrasi di dalam outer card:
    - Judul section (contoh: "Transaksi Terbaru", "Pengeluaran Hari ini", "Monthly Overall Budget") di kiri (`Inter Tight`, `16px`, `FontWeight.w600`, putih).
    - Tombol aksi kontekstual (contoh: "Lihat semua", "Detail", badge status) di kanan (`Manrope`, `12px`, `FontWeight.w500`, `#8EA4BE`).
    - Padding header: `fromLTRB(16, 14, 16, 12)`.
- **Inner Card ("Card Inside Card"):**
  - Mengambang di bagian bawah outer card dengan margin tipis: `fromLTRB(6, 0, 6, 6)`.
  - Latar belakang slightly elevated slate `#131A26`, border radius `20px`, border tipis `1px rgba(255, 255, 255, 0.06)`.
  - Menampung konten utama: list transaksi dengan divider tipis (`indent: 68, endIndent: 16`), circular category icon badge, kontrol pengeluaran hari ini, progress budget, atau list akun dompet.
- **Penerapan Universal:**
  - Komponen `NestedCard` (`lib/widgets/nested_card.dart`) diterapkan di seluruh section card aplikasi (Dashboard, Budget, Wallets, Analytics, Transactions), kecuali kartu saldo hero yang memiliki layout kustom (radial gradient & 4-dock).

### 5.3 Komponen List Item Transaksi (`TransactionTile` & `TransactionsScreen`)
- **Visual Avatar Kategori Sirkular:**
  - Bentuk bulat penuh (`42x42px`, `BoxShape.circle`) dengan warna tint 14% dari palet aksen kategori.
  - Ikon vektor geometris murni: Makanan (`local_cafe`), Transportasi (`directions_car`), Belanja (`shopping_bag`), Tagihan (`bolt`), Gaji (`payments`), Transfer (`swap_horiz`). Zero decorative emoji.
- **Hierarki Tipografi:**
  - Judul transaksi: `Inter Tight` / `Manrope` (`13.5px`, `FontWeight.w600`, putih pekat).
  - Subtitle keterangan: `Manrope` (`11px`, `FontWeight.w500`, `#7F91A7`) memuat tanggal/waktu relatif (`Hari ini, 12:00` / `2 Nov, 14:30`) dan nama rekening dompet (`• BCA`).
- **Nominal Finansial & Warna Indikator:**
  - Ditata tegas di sisi kanan menggunakan font `Inter Tight` (`14.5px`, `FontWeight.w600`).
  - Pemasukan: `+ Rp 4.000.000` (`#39D98A`).
  - Pengeluaran: `- Rp 25.000` (putih pekat).
  - Transfer: `Rp 50.000` (`#55C7FF`, netral tanpa tanda +/-).
- **Layar Riwayat Transaksi (`TransactionsScreen`):**
  - Top Bar: Judul `Riwayat Transaksi` (`20px`, `Inter Tight`, `w600`) tanpa tombol add di header, dilengkapi tombol aksi kontekstual `Reset Filter` saat filter aktif.
  - Search bar interaktif (`44px`, `#131A26`, border `0.08`) dengan placeholder Indonesia dan tombol clear (`x`).
  - Sistem multi-filter 2 baris seimbang dengan tinggi nyaman **`42px`**:
    - Baris 1: Filter Bulan (Dropdown) & Filter Tanggal Spesifik (DatePicker dengan tombol reset `✕`).
    - Baris 2: Filter Jenis Transaksi (Dropdown) & Filter Dompet (Dropdown).
  - Card daftar transaksi (`NestedCard`) ber-divider halus (`indent: 68`), dengan fallback empty state dan tombol `Reset Semua Filter`.

### 5.4 Layar Catat Transaksi (Add Transaction Modal Swipe-Up)
- **Animasi & Transisi:**
  - Muncul dari bawah dengan animasi swipe-up (`SlideUpRoute`, duration: `320ms`, curve: `Curves.easeOutCubic`).
  - Gesture swipe down untuk menutup halaman secara intuitif.
- **Top Drag Handle & App Bar:**
  - Drag handle pill di bagian paling atas (`40x4px`, radius 2px, opacity 24%).
  - Tombol tutup `✕` di kiri dan judul `Catat Transaksi` / `Ubah Transaksi` di tengah.
  - Tombol hapus merah (`Icons.delete_outline_rounded`) jika dalam mode edit transaksi.
- **Segmented Type Control:**
  - Tiga tab: `Pengeluaran` (merah `#F43F5E`), `Pemasukan` (hijau `#10B981`), dan `Transfer` (biru `#2B8DE0`).
- **Hero Amount Input Card (`NestedCard`):**
  - Default nominal baru dimulai dari `0` (nol rupiah).
  - Display nominal besar dalam format `Inter Tight` (`32px`, `FontWeight.w500`).
  - Tombol chip cepat tambah nominal: `+10rb`, `+20rb`, `+50rb`, `+100rb`.
- **Form Detail Transaksi (`NestedCard`):**
  - **Kategori:** horizontal scrolling chips dengan ikon vektor geometris murni dari `CategoryModel`.
  - **Dompet/Akun:** Dropdown rekening dibuat kompak (`height: 38px`, `isDense: true`, font `12.5px`, padding horizontal `10px`).
  - **Mode Transfer:** Pilihan dompet asal dan dompet tujuan side-by-side berukuran kompak (`38px`).
  - **Tanggal:** Pemilih tanggal dengan format tanggal Indonesia lengkap.
  - **Catatan / Judul:** Input teks keterangan ringkas.
- **Bottom CTA:**
  - Tombol full-width "Simpan Transaksi" (putih solid, teks hitam `w600`, radius 16px).

### 5.5 Layar Laporan (Report Screen — `AnalyticsScreen` — Anti-Slop)
- **Default View Mode:** Default saat membuka laporan adalah **Bar Chart** (`WeeklyActivityChart`), dengan opsi beralih ke Donut Chart via switch pill.
- **Top App Bar & Pemilih Periode:**
  - Judul `Laporan Keuangan` (`20px`, `w600`, Inter Tight) di kiri tanpa tombol back (karena tab root).
  - Pill dropdown bulan di kanan atas (contoh: "November 2026 ∨") dengan modal bottom-sheet pemilih bulan.
- **Segmented Type Switcher:**
  - Kapsul pill konsisten: `Pengeluaran` (aktif: putih solid, teks hitam) vs `Pemasukan` (transparan, teks slate).
- **Hero Report Card (`Aktivitas Pengeluaran` / `Aktivitas Pemasukan` — `NestedCard`):**
  - Header kartu: Judul "Aktivitas Pengeluaran" di kiri dan Switch Pill pemilih grafik di pojok kanan (*space-between*).
  - Switch Pill: Kapsul rounded (`#16202D`) dengan sliding sapphire thumb (`#2F91E4`–`#1368B5`, zero slop purple) beranimasi halus, ikon Bar Chart di kiri dan Pie Chart di kanan.
  - **Mode Bar Chart (Default View):**
    - Menampilkan grafik batang aktivitas mingguan `WeeklyActivityChart` langsung tanpa nested card ganda.
    - Dilengkapi **Paginator Filter per-Minggu Unboxed**: Posisi dinaikkan lebih ke atas mendekati judul kartu, tanpa badge pill container berlatar tebal (murni teks `Minggu 2 (2 – 8 Nov)` dan sepasang chevron `<` / `>`).
    - Area bar chart dibuat lebih tinggi (`height: 195px`), dengan ketinggian maksimal batang dinaikkan dari `96px` ke `122px` agar kontras visual lebih tegas.
    - Mendukung *horizontal drag/swipe* untuk beralih minggu secara intuitif. Batang 7 hari (Sen–Min) terisolasi menampilkan data minggu terpilih.
  - **Mode Donut Chart (True Annular Rounded Wedge):**
    - Kanvas 250x250 dengan padding vertikal kartu 22px.
    - Geometri irisan cincin analitik murni (*annular wedge sectors*) dengan sudut membulat fillet lingkaran sejati ($s^2 + r_c^2 = (R \pm r_c)^2$, `cornerRadius: 6.0px`), menghilangkan seluruh distorsi sudut dan pinching.
    - Sisi radial terpotong datar menuju titik pusat dengan celah sudut seragam `3.5°`.
    - Ketebalan irisan cincin dibuat kokoh dan proporsional sesuai referensi ($R_o = 112\text{px}$, $R_i = 68\text{px}$, ketebalan cincin $44\text{px}$, diameter lubang tengah $136\text{px}$, rasio lubang $60.7\%$).
    - Palet 5 warna kategori presisi selaras referensi: Biru (`#007AFF`), Hijau (`#34C759`), Oranye (`#FF9500`), Ungu (`#AF52DE`), Merah (`#FF3B30`), serta variasi palet extended Biru Langit (`#55C7FF`), Amber (`#FFC857`), dan Slate (`#8CA7C5`).
    - Format nominal di tengah donut: Menggunakan format ringkas kontekstual: ribuan s/d ratusan ribu berakhiran `k` (contoh: `101k`, `320k`) dan jutaan berakhiran `jt` dengan pemisah koma desimal (contoh: `3,4 jt`, `4 jt`).
    - Di tengah lingkaran: Wadah informasi berlebar 126px dengan label `Total Pengeluaran` (`11px`) dan nominal display besar (`26px`, Inter Tight `w600`).
    - Tooltip mengambang dinamis (`_buildFloatingBadge`, radius 90px) berposisi tepat di atas irisan cincin menampilkan persentase (`31%`).
    - Interaktif ganda: Mengetuk langsung pada irisan cincin (`onTapDown` radius 62..118px) atau mengetuk kartu kategori di bawah akan menyorot segmen dengan animasi outward push 3.5px.
- **Daftar Kategori ("Rincian Pengeluaran" / "Rincian Pemasukan" — `NestedCard`):**
  - Mengikuti pola universal `NestedCard` dengan baris kategori ber-divider halus.
  - Ikon kategori sirkular dalam wadah warna senada, nama kategori, persentase share (`31.2% dari total`), nominal terformat, dan jumlah transaksi riil (`3 transaksi`).
  - Progress bar horizontal 4px dengan warna selaras segmen irisan donut (`_chartPalette`).
  - Interaktif: Mengetuk baris kategori akan mengaktifkan sorotan segmen pada donut chart di atas.

### 5.6 Kalender Pelacak Pengeluaran (`SpendingCalendarCard`)
- **Pola Kartu (`NestedCard`):**
  - Outer header: Nama bulan terpilih ("November") dan tombol panah navigasi bulan (`<` dan `>`).
  - Inner card: Wadah gelap rounded (`20px`, `#131A26` / `#16202D`) dengan padding `12px`.
- **Struktur Grid Tanggal Minimalis (Calm & Focused UX):**
  - 7 kolom sejajar dengan hari dalam seminggu (`Sen`, `Sel`, `Rab`, `Kam`, `Jum`, `Sab`, `Min`).
  - Tanpa background card rounded di tiap tanggal: Tanggal dan nominal bernapas langsung di atas kanvas inner card yang tenang tanpa visual noise.
  - Tanggal hari ini (`Today`): Diberi aksen rounded card **outline murni** (`borderRadius: 10px`, `Border.all(color: Colors.white.withOpacity(0.35), width: 1.2)`), menjadi jangkar orientasi yang jelas tanpa mendominasi kontras.
  - Indikator nominal pengeluaran: Ditampilkan di bawah nomor tanggal dalam format kompak (`13K`, `25K`, `120K`, `1.2M`) menggunakan font `Inter Tight` (`10px`, `w600`, `#8CA7C5`). Tanggal tanpa pengeluaran tetap bersih tanpa teks nominal.
  - Tanggal di luar bulan berjalan memiliki opasitas teks lebih rendah (`0.28`).
  - Interaksi tap: Tanggal yang dipilih mendapatkan border halus `#55C7FF`, dan detail pengeluaran tanggal tersebut ditampilkan di panel bawah grid.

### 5.7 Fixed Bottom Navigation Bar dengan Scooped Cradle Cutout (Ergonomis & Seimbang)
- **Struktur Bar & Kanvas (`lib/widgets/bottom_nav_bar.dart`):**
  - Bar navigasi berlatar dark matte slate `#0F141A`, border atas tipis `1px rgba(255, 255, 255, 0.08)` dan drop shadow halus ke atas (`Colors.black.withOpacity(0.55)`, blur: `14px`).
  - **Rounded Top Corners:** Kedua sudut atas bar dibuat membulat halus (`topCornerRadius: 26.0px`).
  - **Scooped Cradle Cutout (Lekukan Notch Presisi):**
    - Lekukan kurva kubik Bezier kontinu (`notchDepth: 39px`, `notchHalfWidth: 56px`, `c1: 16px`, `c2: 28px`) melengkung mulus dari bahu bar horizontal (`barTop: 32.0px`) menuju dasar mangkuk cradle dengan tangensi horizontal C1 sempurna tanpa sudut patah.
    - Menyisakan celah/gap seragam ~8.5px di sekeliling tombol floating (+) aksi utama.
    - Sisi bawah cradle menyatu sejajar dengan garis horizontal pusat vertikal ikon navigasi.
  - **Ketinggian Ergonomis & Safe Area:**
    - Ketinggian bar konten ditinggikan nyaman ke **`68px`** (memenuhi standar target ketukan aksesibilitas dan ergonomi visual).
    - Inset bawah otomatis menyesuaikan perangkat (`bottomInset = math.max(systemBottomInset, 14.0)`).
    - Ketinggian total widget pada web/desktop: `114px` (`32px + 68px + 14px`).
    - Pada web runner/desktop: Dilengkapi kapsul tipis *iOS Home Indicator Bar* (`width: 136px`, `height: 4px`, `white 85%`, radius `2px`) di posisi `bottom: 6px`.
- **Distribusi Slot & Spacing Ikon (Equidistant 5-Slot Layout):**
  - Menggunakan 5 slot kolom `Expanded` dengan interval jarak sentral setara (`0.20 * W` per interval) ber-padding tepi `horizontal: 10px`, memastikan jarak antarpusat ikon (`Grid` ke `Doc`, `Doc` ke `FAB`, `FAB` ke `Pie`, dan `Pie` ke `Person`) tepat 100% identik dan simetris.
  - Menghilangkan label teks sepenuhnya sesuai referensi visual, menciptakan estetika fintech modern yang lapang dan bersih.
  - **Slot 0 (Beranda):** `Icons.grid_view_rounded` (2x2 rounded squircles).
  - **Slot 1 (Riwayat Transaksi):** `Icons.description_rounded` (dokumen bergaris dengan lipatan sudut).
  - **Slot 2 (Tengah):** Ruang lekukan cradle & floating FAB.
  - **Slot 3 (Laporan Keuangan):** `Icons.pie_chart_rounded` (diagram pie solid dengan irisan terpisah).
  - **Slot 4 (Profil & Pengaturan):** `Icons.person_rounded` (avatar pengguna minimalis).
  - **Ukuran & Pewarnaan:**
    - Ukuran ikon: `28px`.
    - Item aktif: Putih pekat `Colors.white` (`#FFFFFF`).
    - Item inaktif: Slate kebiruan terang `const Color(0xFF94A3B8)`.
    - Touch target ergonomis: `48x46px` dengan feedback ripple rounded (`borderRadius: 16px`).
- **Tombol Tambah Tengah (Elevated Oceanic Sapphire Action Button):**
  - Tombol sirkular proporsional **`58x58px`** mengambang anggun di tengah lekukan scoop notch (`top: barTop - 27.5px`, center `barTop + 1.5px`).
  - Gradien sapphire oceanic dalam: `LinearGradient(colors: [#025EA8, #014786])`.
  - Drop shadow ganda: `BoxShadow(color: Color(0xFF014786).withOpacity(0.50), blurRadius: 14, offset: Offset(0, 4))` dan `BoxShadow(color: Colors.black.withOpacity(0.40), blurRadius: 8, offset: Offset(0, 2))`.
  - Ikon plus putih tebal dan presisi: `Icons.add_rounded`, `size: 32px`, `color: Colors.white`.
- **Clearing Konten:**
  - Seluruh layar (`DashboardScreen`, `TransactionsScreen`, `BudgetScreen`, `WalletsScreen`, `AnalyticsScreen`, `SettingsScreen`) memiliki bottom padding `100px`–`124px` pada ListView agar konten terbawah tidak tertutup bar.

### 5.8 Layar Profil & Pengaturan Sistem (`SettingsScreen` — Anti-Slop & Modal Bottom Sheet)
- **Header:**
  - Bersih dan tegas: hanya judul `Profil & Pengaturan` (`20px`, `Inter Tight`, `w600`, `-0.3 letterSpacing`) tanpa subtitle/deskripsi redundan.
- **Preferensi Finansial (Title-Only):**
  - Opsi dalam kartu Preferensi Finansial tampil ringkas tanpa teks deskripsi dan tanpa fitur batas anggaran:
    - `Mata Uang Acuan` dengan dropdown selector `IDR (Rp)`.
    - `Sembunyikan Saldo` dengan switch adaptif (mengatur kartu hero di Beranda mengempis/naik ke atas).
- **Modal Card Bottom Sheet (Floating Nested Card Standard - `modal_card_sheet.dart`):**
  - Seluruh dialog modal dan sheet aplikasi distandarisasi menggunakan fungsi reusable `showModalCardSheet`:
    - Mengambang bebas (*floating card*) dengan margin samping dan bawah `14px` - `16px`.
    - Kontainer luar `borderRadius: 24px` di seluruh sudut, warna slate navy `#0C131D`, ber-border halus `rgba(255, 255, 255, 0.08)` dan drop shadow lembut.
    - Handle pill drag `38x4px` (`white 20%`) di bagian atas.
    - Header modal: Ikon kategori, judul `16.5px Inter Tight w600`, dan tombol tutup silang bulat `(X)`.
    - **Inner Slate Nested Card:** Kontainer dalam `#131A26` dengan `borderRadius: 18px` dan `border: 1px rgba(255, 255, 255, 0.06)` yang membungkus seluruh konten formulir dan tombol aksi ("Card Inside Card").
    - Form dan tombol otomatis naik menyesuaikan keyboard virtual perangkat (`viewInsets.bottom`).
    - Mencakup: Ubah Nama Pengguna, Ekspor Cadangan Data, Pulihkan Data JSON (Merge / Replace), Kosongkan Riwayat Transaksi (Danger Alert), Reset ke Data Bawaan (Warning Alert), Konfirmasi Hapus Kategori, dan Month Picker Analisis.
  - Teks nama akun (`Inter Tight`, `17px`, `w600`) dan label akun (`11.5px`, `Manrope`).
  - Aksi header `Ubah Nama >` membuka modal teks input nama pengguna; perubahan nama otomatis memperbarui greeting di layar Beranda.
  - Tiga pod statistik mini ber-divider vertikal halus: Total transaksi dicatat, jumlah dompet aktif, dan total pengeluaran bulan ini.
- **Preferensi Finansial (`NestedCard`):**
  - Mata Uang Acuan: Dropdown kompak dark slate untuk beralih antara `IDR (Rp)` dan `USD ($)`.
  - Sembunyikan Saldo: Switch adaptif yang mengatur privasi visibilitas nominal di Beranda (*"Fokus pengeluaran dan pemasukan di beranda"*).
- **Cadangan & Pemulihan Data (`NestedCard`):**
  - Ekspor Cadangan: Dialog preview JSON monospace dan tombol satu klik `Salin JSON` ke clipboard.
  - Pulihkan Data: Input JSON dengan validasi parser otomatis, badge preview deteksi jumlah data (`valid: true, txCount, walletCount`), dan tombol pemulihan aman wajib:
    - `Merge Data`: Menggabungkan mutasi baru tanpa menduplikasi ID yang sudah ada.
    - `Replace Data`: Menimpa seluruh database lokal secara menyeluruh.
- **Zona Bahaya (Danger Zone — `NestedCard`):**
  - Kosongkan Riwayat Transaksi: Dialog peringatan merah dengan konfirmasi tegas untuk menghapus seluruh mutasi dan menolkan saldo.
  - Reset Data Bawaan: Dialog konfirmasi oranye untuk mengembalikan state awal aplikasi (factory seed demo).
- **Tentang Aplikasi & Privasi:**
  - Kartu informasi berarsitektur bersih: Status database lokal `SharedPreferences`, zero cloud analytics, dan palet dark matte sapphire `#1C2229`.
- **State Capability Sensitif:**
  - Pada public/safe-release build, baris `Pembaca Notifikasi` tetap terlihat untuk transparansi tetapi nonaktif, memakai subtitle `Nonaktif pada build aman` dan ikon kunci Material/vektor.
  - State nonaktif menggunakan token slate/muted yang sudah ada; tidak menambah warna, gradien, emoji, atau CTA untuk melewati proteksi Android.

### 5.9 Layar Kelola Kategori (`ManageCategoriesScreen`) & Tambah Kategori (`EditCategoryScreen`)
- **Daftar Kategori (`ManageCategoriesScreen`):**
  - Segmented tab switcher Pengeluaran vs Pemasukan dengan hitungan item dinamis.
  - List kategori di dalam `NestedCard` dengan avatar 42x42px ber-tint warna aksen 16%.
  - Badging sumber ikon bersih: **`Icon`** (vektor) atau **`Emoji`** (tanpa embel-embel "Tabler/Icon").
  - Tombol aksi Tambah dan Ubah menavigasi ke layar mandiri **`EditCategoryScreen`**.
  - Modal konfirmasi hapus menggunakan floating card `modal_card_sheet.dart` dengan auto-reassignment transaksi ke kategori "Others/Lainnya".
- **Layar Tambah & Ubah Kategori (`EditCategoryScreen` - New Page Architecture):**
  - Halaman penuh Scaffold `#1C2229` dengan navigasi PageRoute mandiri bebas desakan keyboard virtual.
  - **Card 1 (Informasi Kategori):** Live preview ikon 52x52px, input Nama Kategori, segmented button Tipe Transaksi, dan palet 9 warna aksen.
  - **Card 2 (Pilihan Ikon):** Tab berlabel bersih **`Icon`** (pencarian teks + grid 6-kolom Tabler Icons) dan **`Emoji`** (input keyboard sistem + grid 7-kolom curated emojis).
  - Tombol simpan primer elevated oceanic sapphire `#02539A`.

---

## 6. Aturan Penegakan Anti-Slop (/antislop-ui)

- **R-01 & R-10 (No Slop Gradients):** Dilarang membungkus keseluruhan halaman atau kartu biasa dengan gradien ungu/biru. Gradien hanya milik kartu virtual debit.
- **R-04 (No Emojis as UI Decoration):** Dilarang menyematkan emoji dekoratif di headline atau tombol. Pengecualian resmi: Pemilihan emoji diperbolehkan khusus sebagai representasi ikon kategori kustom yang dipilih pengguna.
- **R-11 & R-12 (Restrained Elevation & Radius):** Radius elemen ditentukan oleh fungsinya (pill untuk kontrol status/navigasi, 16px untuk input/tombol, 28px untuk kartu besar).
- **R-19 (No Endless Loops/Pulses):** Tidak ada animasi pulsing tanpa henti atau elemen memantul otomatis yang mengganggu fokus membaca data angka.
- **R-24 & R-26 (Functional Controls):** Semua tombol dan tab bar harus memiliki routing aksi nyata dan memperbarui status/tampilan aplikasi.

