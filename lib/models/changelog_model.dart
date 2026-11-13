class ChangelogItem {
  final String version;
  final String date;
  final String title;
  final bool isCurrent;
  final List<String> features;
  final List<String> improvements;

  const ChangelogItem({
    required this.version,
    required this.date,
    required this.title,
    this.isCurrent = false,
    required this.features,
    required this.improvements,
  });
}

class ChangelogData {
  static const String currentVersion = '2.0.3';

  static ChangelogItem? getRelease(String tagOrVersion) {
    final clean = tagOrVersion.replaceAll(RegExp(r'^[vV]'), '').split('+').first.trim();
    for (final item in history) {
      if (item.version == clean) return item;
    }
    return null;
  }

  static const List<ChangelogItem> history = [
    ChangelogItem(
      version: '2.0.3',
      date: '13 November 2026',
      title: 'Optimalisasi Tampilan & Pembaruan Sistem',
      isCurrent: true,
      features: [
        'Penyempurnaan tombol pembaruan menjadi lebih rapi dan responsif dalam satu baris.',
        'Catatan pembaruan otomatis menggunakan bahasa pengguna yang jelas tanpa tautan teknis.',
      ],
      improvements: [
        'Pembaruan performa dan efisiensi aplikasi yang lebih optimal.',
        'Peningkatan stabilitas pencatatan transaksi dan konsumsi memori.',
      ],
    ),
    ChangelogItem(
      version: '2.0.2',
      date: '13 November 2026',
      title: 'Peningkatan Stabilitas Rilis Otomatis',
      isCurrent: false,
      features: [
        'Pembaruan aplikasi diterbitkan langsung melalui otomatisasi rilis resmi yang aman.',
      ],
      improvements: [
        'Validasi versi rilis dan signing key produksi mencegah APK pembaruan yang tidak kompatibel.',
        'Peningkatan konsistensi deteksi versi terbaru di dalam aplikasi.',
      ],
    ),
    ChangelogItem(
      version: '2.0.0',
      date: '13 November 2026',
      title: 'Sinkronisasi Cloud, Auth Gate, & Manajemen Akun',
      isCurrent: false,
      features: [
        'Integrasi Cloud Supabase: Masuk dengan Google, Email & Password, dan sinkronisasi data transaksi dua arah otomatis.',
        'Mode Tamu 100% Offline: Pengguna dapat langsung menggunakan aplikasi secara lokal tanpa login dan tanpa internet.',
        'Auth Gate Onboarding Terfokus: Layar login mandiri sebelum rangkaian setup Data Diri, Tema, Dompet, dan Kategori.',
        'Fitur Lupa Kata Sandi & Ganti Kata Sandi pada form login dan profil pengguna terhubung cloud.',
        'Fitur Hapus Akun Yotro di Zona Bahaya dengan penghapusan permanen data cloud dan reset memori lokal.',
        'In-App OTA Updater: Deteksi dan pasang pembaruan APK langsung di dalam aplikasi.',
      ],
      improvements: [
        'Pembersihan branding antarmuka: Tanpa teks teknis, private cloud sync, zero slop.',
        'Kompensasi layout keyboard virtual dan scrollable onboarding setup.',
        'Validasi password minimum 6 karakter dan konfirmasi kecocokan sandi.',
      ],
    ),
    ChangelogItem(
      version: '1.0.6',
      date: '8 November 2026',
      title: 'Atmospheric Glow, OCR On-Device, & Voice Input',
      isCurrent: false,
      features: [
        'Atmospheric Sapphire Radial Glow di Beranda, Riwayat, Laporan, dan Profil.',
        'OCR Struk Belanja 100% On-Device & Offline via Google ML Kit.',
        'Visualizer Input Suara Circular Spectrum pada layar penuh.',
        'Redesain Analisis Keuangan: Half Circular Gauge, Kurva Alur Kas, dan Donut Chart.',
      ],
      improvements: [
        'Format desimal rapi (k, jt, M) pada display angka besar.',
        'Dukungan filter multi-transaksi dan reset filter cepat.',
      ],
    ),
    ChangelogItem(
      version: '1.0.5',
      date: '2 November 2026',
      title: 'Split Bill, Filter Bulanan, & Scooped Dock Cutout',
      isCurrent: false,
      features: [
        'Fitur Advanced Split Bill: Bagi Rata, Bagi Kustom, dan Per Item.',
        'Filter Bulanan interaktif dengan grid 12 bulan di Beranda dan Laporan.',
        'Fixed Bottom Dock Bar dengan Scooped Cradle Cutout & Floating FAB.',
        'Dual Theme Mode: Dark Slate Matte dan Monochrome Neutral Light Mode.',
      ],
      improvements: [
        'Sinkronisasi otomatis mutasi saat ubah saldo dompet.',
        'Komponen TransactionTile seragam dengan avatar kategori representatif.',
      ],
    ),
    ChangelogItem(
      version: '1.0.0',
      date: '25 Oktober 2026',
      title: 'Rilis Perdana Yotro Money Tracker',
      isCurrent: false,
      features: [
        'Pencatatan Pemasukan, Pengeluaran, dan Transfer Antar-Dompet.',
        'Multi-Wallet (Dompet Bank, E-Wallet, Tunai, Tabungan).',
        'Anggaran Bulanan (Budget) per Kategori dengan threshold peringatan 80% dan 100%.',
        'Ekspor & Impor Cadangan Data lokal format JSON.',
      ],
      improvements: [
        'Desain anti-slop dark matte palette (#0C131D, #131A26).',
        '100% offline-first architecture.',
      ],
    ),
  ];
}
