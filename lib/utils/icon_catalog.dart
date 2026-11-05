import 'package:flutter/widgets.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class TablerIconItem {
  final String key;
  final String label;
  final String category;
  final IconData icon;

  const TablerIconItem({
    required this.key,
    required this.label,
    required this.category,
    required this.icon,
  });
}

class EmojiItem {
  final String char;
  final String label;
  final String category;

  const EmojiItem({
    required this.char,
    required this.label,
    required this.category,
  });
}

class IconCatalog {
  static const List<TablerIconItem> tablerIcons = [
    // Keuangan & Bisnis
    TablerIconItem(key: 'wallet', label: 'Dompet', category: 'Keuangan', icon: TablerIcons.wallet),
    TablerIconItem(key: 'cash', label: 'Uang Tunai', category: 'Keuangan', icon: TablerIcons.cash),
    TablerIconItem(key: 'coin', label: 'Koin', category: 'Keuangan', icon: TablerIcons.coin),
    TablerIconItem(key: 'credit_card', label: 'Kartu Kredit', category: 'Keuangan', icon: TablerIcons.credit_card),
    TablerIconItem(key: 'building_bank', label: 'Bank', category: 'Keuangan', icon: TablerIcons.building_bank),
    TablerIconItem(key: 'pig_money', label: 'Tabungan', category: 'Keuangan', icon: TablerIcons.pig_money),
    TablerIconItem(key: 'moneybag', label: 'Kantong Uang', category: 'Keuangan', icon: TablerIcons.moneybag),
    TablerIconItem(key: 'receipt', label: 'Struk Belanja', category: 'Keuangan', icon: TablerIcons.receipt),
    TablerIconItem(key: 'receipt_2', label: 'Tagihan Kasir', category: 'Keuangan', icon: TablerIcons.receipt_2),
    TablerIconItem(key: 'receipt_tax', label: 'Pajak', category: 'Keuangan', icon: TablerIcons.receipt_tax),
    TablerIconItem(key: 'trending_up', label: 'Investasi Naik', category: 'Keuangan', icon: TablerIcons.trending_up),
    TablerIconItem(key: 'chart_pie', label: 'Grafik Donat / Pie', category: 'Keuangan', icon: TablerIcons.chart_pie),
    TablerIconItem(key: 'chart_bar', label: 'Grafik Batang', category: 'Keuangan', icon: TablerIcons.chart_bar),
    TablerIconItem(key: 'chart_donut', label: 'Grafik Donut', category: 'Keuangan', icon: TablerIcons.chart_donut),
    TablerIconItem(key: 'briefcase', label: 'Kerja / Kantor', category: 'Keuangan', icon: TablerIcons.briefcase),
    TablerIconItem(key: 'building_store', label: 'Toko / Usaha', category: 'Keuangan', icon: TablerIcons.building_store),
    TablerIconItem(key: 'calculator', label: 'Kalkulator', category: 'Keuangan', icon: TablerIcons.calculator),
    TablerIconItem(key: 'percentage', label: 'Bunga / Persen', category: 'Keuangan', icon: TablerIcons.percentage),
    TablerIconItem(key: 'discount', label: 'Potongan Harga', category: 'Keuangan', icon: TablerIcons.discount),
    TablerIconItem(key: 'tag', label: 'Label Harga', category: 'Keuangan', icon: TablerIcons.tag),
    TablerIconItem(key: 'currency_dollar', label: 'Dolar', category: 'Keuangan', icon: TablerIcons.currency_dollar),
    TablerIconItem(key: 'currency_euro', label: 'Euro', category: 'Keuangan', icon: TablerIcons.currency_euro),
    TablerIconItem(key: 'diamond', label: 'Aset Berharga', category: 'Keuangan', icon: TablerIcons.diamond),
    TablerIconItem(key: 'shield_lock', label: 'Brankas Aman', category: 'Keuangan', icon: TablerIcons.shield_lock),
    TablerIconItem(key: 'scale', label: 'Neraca Keuangan', category: 'Keuangan', icon: TablerIcons.scale),

    // Makanan & Minuman
    TablerIconItem(key: 'coffee', label: 'Kopi', category: 'Makanan', icon: TablerIcons.coffee),
    TablerIconItem(key: 'cup', label: 'Minuman / Teh', category: 'Makanan', icon: TablerIcons.cup),
    TablerIconItem(key: 'beer', label: 'Bir / Bar', category: 'Makanan', icon: TablerIcons.beer),
    TablerIconItem(key: 'glass', label: 'Gelas Kaca', category: 'Makanan', icon: TablerIcons.glass),
    TablerIconItem(key: 'glass_full', label: 'Minuman Penuh', category: 'Makanan', icon: TablerIcons.glass_full),
    TablerIconItem(key: 'cake', label: 'Kue / Tart', category: 'Makanan', icon: TablerIcons.cake),
    TablerIconItem(key: 'cookie', label: 'Kue Kering', category: 'Makanan', icon: TablerIcons.cookie),
    TablerIconItem(key: 'meat', label: 'Daging', category: 'Makanan', icon: TablerIcons.meat),
    TablerIconItem(key: 'salad', label: 'Sayuran / Salad', category: 'Makanan', icon: TablerIcons.salad),
    TablerIconItem(key: 'soup', label: 'Sup / Kuah', category: 'Makanan', icon: TablerIcons.soup),
    TablerIconItem(key: 'pizza', label: 'Pizza', category: 'Makanan', icon: TablerIcons.pizza),
    TablerIconItem(key: 'burger', label: 'Burger / Makanan Cepat Saji', category: 'Makanan', icon: TablerIcons.burger),
    TablerIconItem(key: 'bottle', label: 'Botol Minum', category: 'Makanan', icon: TablerIcons.bottle),
    TablerIconItem(key: 'tools_kitchen', label: 'Restoran / Masak', category: 'Makanan', icon: TablerIcons.tools_kitchen),
    TablerIconItem(key: 'tools_kitchen_2', label: 'Alat Makan', category: 'Makanan', icon: TablerIcons.tools_kitchen_2),
    TablerIconItem(key: 'apple', label: 'Buah-buahan', category: 'Makanan', icon: TablerIcons.apple),
    TablerIconItem(key: 'carrot', label: 'Wortel / Bahan Makanan', category: 'Makanan', icon: TablerIcons.carrot),
    TablerIconItem(key: 'fish', label: 'Ikan / Seafood', category: 'Makanan', icon: TablerIcons.fish),

    // Transportasi
    TablerIconItem(key: 'car', label: 'Mobil Pribadi', category: 'Transportasi', icon: TablerIcons.car),
    TablerIconItem(key: 'bus', label: 'Bus / Angkutan Umum', category: 'Transportasi', icon: TablerIcons.bus),
    TablerIconItem(key: 'train', label: 'Kereta / KRL / MRT', category: 'Transportasi', icon: TablerIcons.train),
    TablerIconItem(key: 'plane', label: 'Pesawat Terbang', category: 'Transportasi', icon: TablerIcons.plane),
    TablerIconItem(key: 'plane_departure', label: 'Penerbangan Berangkat', category: 'Transportasi', icon: TablerIcons.plane_departure),
    TablerIconItem(key: 'plane_arrival', label: 'Penerbangan Tiba', category: 'Transportasi', icon: TablerIcons.plane_arrival),
    TablerIconItem(key: 'bike', label: 'Sepeda Gowes', category: 'Transportasi', icon: TablerIcons.bike),
    TablerIconItem(key: 'motorbike', label: 'Sepeda Motor / Ojol', category: 'Transportasi', icon: TablerIcons.motorbike),
    TablerIconItem(key: 'scooter', label: 'Skuter Listrik', category: 'Transportasi', icon: TablerIcons.scooter),
    TablerIconItem(key: 'gas_station', label: 'BBM / Bensin SPBU', category: 'Transportasi', icon: TablerIcons.gas_station),
    TablerIconItem(key: 'charging_pile', label: 'Pengisian Daya EV', category: 'Transportasi', icon: TablerIcons.charging_pile),
    TablerIconItem(key: 'steering_wheel', label: 'Sewa Mobil / Nyetir', category: 'Transportasi', icon: TablerIcons.steering_wheel),
    TablerIconItem(key: 'truck', label: 'Pengiriman / Truk Logistik', category: 'Transportasi', icon: TablerIcons.truck),
    TablerIconItem(key: 'ship', label: 'Kapal Feri / Laut', category: 'Transportasi', icon: TablerIcons.ship),
    TablerIconItem(key: 'map_pin', label: 'Tujuan Wisata / Rute', category: 'Transportasi', icon: TablerIcons.map_pin),
    TablerIconItem(key: 'route', label: 'Tarif Tol / Jalur', category: 'Transportasi', icon: TablerIcons.route),
    TablerIconItem(key: 'navigation', label: 'Navigasi Peta', category: 'Transportasi', icon: TablerIcons.navigation),

    // Belanja & Kebutuhan
    TablerIconItem(key: 'shopping_cart', label: 'Keranjang Belanja', category: 'Belanja', icon: TablerIcons.shopping_cart),
    TablerIconItem(key: 'shopping_bag', label: 'Kantong Belanja', category: 'Belanja', icon: TablerIcons.shopping_bag),
    TablerIconItem(key: 'basket', label: 'Keranjang Pasar', category: 'Belanja', icon: TablerIcons.basket),
    TablerIconItem(key: 'gift', label: 'Kado / Hadiah', category: 'Belanja', icon: TablerIcons.gift),
    TablerIconItem(key: 'shirt', label: 'Pakaian / Fashion', category: 'Belanja', icon: TablerIcons.shirt),
    TablerIconItem(key: 'hanger', label: 'Gantungan Pakaian', category: 'Belanja', icon: TablerIcons.hanger),
    TablerIconItem(key: 'shoe', label: 'Sepatu / Alas Kaki', category: 'Belanja', icon: TablerIcons.shoe),
    TablerIconItem(key: 'device_watch', label: 'Jam Tangan / Arloji', category: 'Belanja', icon: TablerIcons.device_watch),
    TablerIconItem(key: 'camera', label: 'Kamera / Lensa', category: 'Belanja', icon: TablerIcons.camera),
    TablerIconItem(key: 'device_mobile', label: 'Handphone / Ponsel', category: 'Belanja', icon: TablerIcons.device_mobile),
    TablerIconItem(key: 'device_tablet', label: 'Tablet / iPad', category: 'Belanja', icon: TablerIcons.device_tablet),
    TablerIconItem(key: 'device_laptop', label: 'Laptop / Komputer', category: 'Belanja', icon: TablerIcons.device_laptop),
    TablerIconItem(key: 'package', label: 'Paket Kurir / Olshop', category: 'Belanja', icon: TablerIcons.package),

    // Tagihan & Rumah
    TablerIconItem(key: 'home', label: 'Rumah Tinggal', category: 'Tagihan', icon: TablerIcons.home),
    TablerIconItem(key: 'home_2', label: 'Kos / Kontrakan', category: 'Tagihan', icon: TablerIcons.home_2),
    TablerIconItem(key: 'building', label: 'Apartemen / Gedung', category: 'Tagihan', icon: TablerIcons.building),
    TablerIconItem(key: 'bulb', label: 'Listrik PLN', category: 'Tagihan', icon: TablerIcons.bulb),
    TablerIconItem(key: 'flame', label: 'Gas LPG', category: 'Tagihan', icon: TablerIcons.flame),
    TablerIconItem(key: 'bolt', label: 'Energi Listrik', category: 'Tagihan', icon: TablerIcons.bolt),
    TablerIconItem(key: 'plug', label: 'Elektronik / Stopkontak', category: 'Tagihan', icon: TablerIcons.plug),
    TablerIconItem(key: 'wifi', label: 'Internet / Wi-Fi', category: 'Tagihan', icon: TablerIcons.wifi),
    TablerIconItem(key: 'device_tv', label: 'TV / Langganan Streaming', category: 'Tagihan', icon: TablerIcons.device_tv),
    TablerIconItem(key: 'phone', label: 'Pulsa / Paket Data', category: 'Tagihan', icon: TablerIcons.phone),
    TablerIconItem(key: 'droplet', label: 'Air PDAM', category: 'Tagihan', icon: TablerIcons.droplet),
    TablerIconItem(key: 'trash', label: 'Iuran Sampah / Kebersihan', category: 'Tagihan', icon: TablerIcons.trash),
    TablerIconItem(key: 'key', label: 'Kunci / Properti', category: 'Tagihan', icon: TablerIcons.key),
    TablerIconItem(key: 'lock', label: 'Gembok Keamanan', category: 'Tagihan', icon: TablerIcons.lock),
    TablerIconItem(key: 'shield', label: 'Asuransi Jiwa / Unit Link', category: 'Tagihan', icon: TablerIcons.shield),

    // Kesehatan & Kebugaran
    TablerIconItem(key: 'heart', label: 'Kesehatan / Medis', category: 'Kesehatan', icon: TablerIcons.heart),
    TablerIconItem(key: 'heartbeat', label: 'Denyut Jantung', category: 'Kesehatan', icon: TablerIcons.heartbeat),
    TablerIconItem(key: 'heart_rate_monitor', label: 'Cek Kesehatan / Lab', category: 'Kesehatan', icon: TablerIcons.heart_rate_monitor),
    TablerIconItem(key: 'stethoscope', label: 'Dokter Spesialis', category: 'Kesehatan', icon: TablerIcons.stethoscope),
    TablerIconItem(key: 'pill', label: 'Obat / Apotek', category: 'Kesehatan', icon: TablerIcons.pill),
    TablerIconItem(key: 'first_aid_kit', label: 'Kotak P3K / Darurat', category: 'Kesehatan', icon: TablerIcons.first_aid_kit),
    TablerIconItem(key: 'vaccine', label: 'Vaksin / Imunisasi', category: 'Kesehatan', icon: TablerIcons.vaccine),
    TablerIconItem(key: 'dental', label: 'Dokter Gigi', category: 'Kesehatan', icon: TablerIcons.dental),
    TablerIconItem(key: 'barbell', label: 'Gym / Fitness', category: 'Kesehatan', icon: TablerIcons.barbell),
    TablerIconItem(key: 'run', label: 'Jogging / Lari', category: 'Kesehatan', icon: TablerIcons.run),
    TablerIconItem(key: 'walk', label: 'Jalan Santai', category: 'Kesehatan', icon: TablerIcons.walk),
    TablerIconItem(key: 'activity', label: 'Olahraga Harian', category: 'Kesehatan', icon: TablerIcons.activity),
    TablerIconItem(key: 'bed', label: 'Rawat Inap / Hotel', category: 'Kesehatan', icon: TablerIcons.bed),

    // Hiburan & Hobi
    TablerIconItem(key: 'movie', label: 'Bioskop / Film', category: 'Hiburan', icon: TablerIcons.movie),
    TablerIconItem(key: 'ticket', label: 'Tiket Konser / Wahana', category: 'Hiburan', icon: TablerIcons.ticket),
    TablerIconItem(key: 'music', label: 'Musik / Spotify', category: 'Hiburan', icon: TablerIcons.music),
    TablerIconItem(key: 'headphones', label: 'Headphone / Audio', category: 'Hiburan', icon: TablerIcons.headphones),
    TablerIconItem(key: 'device_gamepad', label: 'Game Console / PS / Xbox', category: 'Hiburan', icon: TablerIcons.device_gamepad),
    TablerIconItem(key: 'device_gamepad_2', label: 'Game Online / Steam', category: 'Hiburan', icon: TablerIcons.device_gamepad_2),
    TablerIconItem(key: 'dice', label: 'Boardgame / Mainan', category: 'Hiburan', icon: TablerIcons.dice),
    TablerIconItem(key: 'ball_football', label: 'Sepak Bola / Futsal', category: 'Hiburan', icon: TablerIcons.ball_football),
    TablerIconItem(key: 'ball_basketball', label: 'Basket', category: 'Hiburan', icon: TablerIcons.ball_basketball),
    TablerIconItem(key: 'ball_tennis', label: 'Tenis / Bulutangkis', category: 'Hiburan', icon: TablerIcons.ball_tennis),
    TablerIconItem(key: 'palette', label: 'Desain / Seni Lukis', category: 'Hiburan', icon: TablerIcons.palette),
    TablerIconItem(key: 'paint', label: 'Cat Tembok / Hobi', category: 'Hiburan', icon: TablerIcons.paint),
    TablerIconItem(key: 'brush', label: 'Kuas / Perlengkapan Seni', category: 'Hiburan', icon: TablerIcons.brush),
    TablerIconItem(key: 'photo', label: 'Fotografi / Studio', category: 'Hiburan', icon: TablerIcons.photo),
    TablerIconItem(key: 'video', label: 'Video Shooting / YouTube', category: 'Hiburan', icon: TablerIcons.video),
    TablerIconItem(key: 'microphone', label: 'Karaoke / Podcast', category: 'Hiburan', icon: TablerIcons.microphone),

    // Pendidikan & Keluarga
    TablerIconItem(key: 'book', label: 'Buku / Majalah', category: 'Edukasi', icon: TablerIcons.book),
    TablerIconItem(key: 'books', label: 'Perpustakaan / E-Book', category: 'Edukasi', icon: TablerIcons.books),
    TablerIconItem(key: 'school', label: 'Sekolah / SPP', category: 'Edukasi', icon: TablerIcons.school),
    TablerIconItem(key: 'certificate', label: 'Kursus Online / Sertifikasi', category: 'Edukasi', icon: TablerIcons.certificate),
    TablerIconItem(key: 'backpack', label: 'Tas / Perlengkapan Kuliah', category: 'Edukasi', icon: TablerIcons.backpack),
    TablerIconItem(key: 'pencil', label: 'Alat Tulis / ATK', category: 'Edukasi', icon: TablerIcons.pencil),
    TablerIconItem(key: 'notes', label: 'Buku Catatan', category: 'Edukasi', icon: TablerIcons.notes),
    TablerIconItem(key: 'baby_carriage', label: 'Bayi / Perlengkapan Anak', category: 'Keluarga', icon: TablerIcons.baby_carriage),
    TablerIconItem(key: 'paw', label: 'Hewan Peliharaan / Kucing', category: 'Keluarga', icon: TablerIcons.paw),
    TablerIconItem(key: 'friends', label: 'Nongkrong Bersama Teman', category: 'Keluarga', icon: TablerIcons.friends),
    TablerIconItem(key: 'users', label: 'Komunitas / Arisan', category: 'Keluarga', icon: TablerIcons.users),
    TablerIconItem(key: 'user', label: 'Kebutuhan Pribadi', category: 'Keluarga', icon: TablerIcons.user),
    TablerIconItem(key: 'calendar', label: 'Langganan Bulanan', category: 'Lainnya', icon: TablerIcons.calendar),
    TablerIconItem(key: 'clock', label: 'Tarif Per Jam / Parkir', category: 'Lainnya', icon: TablerIcons.clock),
    TablerIconItem(key: 'star', label: 'Favorit / Prioritas', category: 'Lainnya', icon: TablerIcons.star),
  ];

  static const List<EmojiItem> emojis = [
    // Makanan & Minuman
    EmojiItem(char: '🍔', label: 'Burger', category: 'Makanan'),
    EmojiItem(char: '🍕', label: 'Pizza', category: 'Makanan'),
    EmojiItem(char: '🍜', label: 'Mie / Ramen', category: 'Makanan'),
    EmojiItem(char: '🍱', label: 'Bento / Nasi', category: 'Makanan'),
    EmojiItem(char: '☕', label: 'Kopi', category: 'Makanan'),
    EmojiItem(char: '🧋', label: 'Boba / Minuman Dingin', category: 'Makanan'),
    EmojiItem(char: '🍺', label: 'Minuman Kaleng', category: 'Makanan'),
    EmojiItem(char: '🍰', label: 'Kue Manis', category: 'Makanan'),
    EmojiItem(char: '🍦', label: 'Es Krim', category: 'Makanan'),
    EmojiItem(char: '🍎', label: 'Buah Segar', category: 'Makanan'),
    EmojiItem(char: '🥗', label: 'Salad / Sayur', category: 'Makanan'),
    EmojiItem(char: '🥩', label: 'Daging / BBQ', category: 'Makanan'),

    // Transportasi
    EmojiItem(char: '🚗', label: 'Mobil', category: 'Transportasi'),
    EmojiItem(char: '🚕', label: 'Taksi / Gocar', category: 'Transportasi'),
    EmojiItem(char: '🚌', label: 'Bus / Transjakarta', category: 'Transportasi'),
    EmojiItem(char: '🚇', label: 'Kereta / MRT', category: 'Transportasi'),
    EmojiItem(char: '✈️', label: 'Pesawat', category: 'Transportasi'),
    EmojiItem(char: '🛵', label: 'Motor / Goride', category: 'Transportasi'),
    EmojiItem(char: '🚲', label: 'Sepeda', category: 'Transportasi'),
    EmojiItem(char: '⛽', label: 'SPBU Bensin', category: 'Transportasi'),

    // Belanja
    EmojiItem(char: '🛒', label: 'Supermarket', category: 'Belanja'),
    EmojiItem(char: '🛍️', label: 'Mall / Belanja', category: 'Belanja'),
    EmojiItem(char: '👕', label: 'Baju Kaos', category: 'Belanja'),
    EmojiItem(char: '👗', label: 'Gaun / Dress', category: 'Belanja'),
    EmojiItem(char: '👟', label: 'Sepatu', category: 'Belanja'),
    EmojiItem(char: '👜', label: 'Tas Belanja', category: 'Belanja'),
    EmojiItem(char: '💄', label: 'Kosmetik / Skincare', category: 'Belanja'),
    EmojiItem(char: '📦', label: 'Paket Belanja Online', category: 'Belanja'),

    // Tagihan & Rumah
    EmojiItem(char: '🏠', label: 'Rumah', category: 'Tagihan'),
    EmojiItem(char: '🏢', label: 'Kantor / Sewa', category: 'Tagihan'),
    EmojiItem(char: '💡', label: 'Listrik', category: 'Tagihan'),
    EmojiItem(char: '⚡', label: 'Token Listrik', category: 'Tagihan'),
    EmojiItem(char: '💧', label: 'Air PDAM', category: 'Tagihan'),
    EmojiItem(char: '📶', label: 'Internet / WiFi', category: 'Tagihan'),
    EmojiItem(char: '📱', label: 'Pulsa / HP', category: 'Tagihan'),
    EmojiItem(char: '💻', label: 'Langganan Software', category: 'Tagihan'),
    EmojiItem(char: '📺', label: 'Netflix / TV', category: 'Tagihan'),

    // Kesehatan & Olahraga
    EmojiItem(char: '💊', label: 'Obat', category: 'Kesehatan'),
    EmojiItem(char: '🏥', label: 'Rumah Sakit', category: 'Kesehatan'),
    EmojiItem(char: '🩺', label: 'Pemeriksaan Dokter', category: 'Kesehatan'),
    EmojiItem(char: '🏋️', label: 'Fitness / Gym', category: 'Kesehatan'),
    EmojiItem(char: '⚽', label: 'Sepak Bola', category: 'Kesehatan'),
    EmojiItem(char: '🏸', label: 'Badminton', category: 'Kesehatan'),
    EmojiItem(char: '🧘', label: 'Yoga / Meditasi', category: 'Kesehatan'),

    // Hiburan & Hobi
    EmojiItem(char: '🎬', label: 'Nonton Bioskop', category: 'Hiburan'),
    EmojiItem(char: '🎮', label: 'Video Game', category: 'Hiburan'),
    EmojiItem(char: '🎧', label: 'Headphone', category: 'Hiburan'),
    EmojiItem(char: '🎵', label: 'Musik', category: 'Hiburan'),
    EmojiItem(char: '🎨', label: 'Seni / Melukis', category: 'Hiburan'),
    EmojiItem(char: '🎟️', label: 'Tiket Event', category: 'Hiburan'),

    // Pekerjaan & Finansial
    EmojiItem(char: '💼', label: 'Gaji / Pekerjaan', category: 'Keuangan'),
    EmojiItem(char: '💰', label: 'Bonus / Dividen', category: 'Keuangan'),
    EmojiItem(char: '💵', label: 'Uang Kertas', category: 'Keuangan'),
    EmojiItem(char: '💳', label: 'Kartu Bank', category: 'Keuangan'),
    EmojiItem(char: '📈', label: 'Trading / Saham', category: 'Keuangan'),
    EmojiItem(char: '🏦', label: 'Tabungan Bank', category: 'Keuangan'),
    EmojiItem(char: '🎁', label: 'Hadiah / THR', category: 'Keuangan'),

    // Edukasi & Lainnya
    EmojiItem(char: '📚', label: 'Buku / Modul', category: 'Edukasi'),
    EmojiItem(char: '🎓', label: 'Wisuda / Kuliah', category: 'Edukasi'),
    EmojiItem(char: '🐶', label: 'Kebutuhan Anjing', category: 'Lainnya'),
    EmojiItem(char: '🐱', label: 'Kebutuhan Kucing', category: 'Lainnya'),
    EmojiItem(char: '⭐', label: 'Bintang / Utama', category: 'Lainnya'),
  ];

  static IconData? findTablerIcon(String key) {
    for (final item in tablerIcons) {
      if (item.key == key) return item.icon;
    }
    return null;
  }
}

