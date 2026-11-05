import 'package:flutter/material.dart';
import '../utils/icon_catalog.dart';

enum TransactionType { expense, income, transfer }

class CategoryModel {
  final String id;
  final String name;
  final TransactionType type;
  final IconData? icon;
  final String? emoji;
  final String? iconName;
  final int? colorValue;
  final bool isDefault;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.emoji,
    this.iconName,
    this.colorValue,
    this.isDefault = false,
  });

  bool get isEmoji => true;

  static String fallbackEmojiFor(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('makan') || lower.contains('food') || lower.contains('minum') || lower.contains('beverage') || lower.contains('kopi') || lower.contains('resto')) return '🍔';
    if (lower.contains('transpor') || lower.contains('kendaraan') || lower.contains('bensin') || lower.contains('ojek') || lower.contains('mobil') || lower.contains('motor')) return '🚗';
    if (lower.contains('belanja') || lower.contains('shop') || lower.contains('mall')) return '🛍️';
    if (lower.contains('rumah') || lower.contains('house') || lower.contains('housing') || lower.contains('kost') || lower.contains('tinggal')) return '🏠';
    if (lower.contains('tagihan') || lower.contains('bill') || lower.contains('utilit') || lower.contains('listrik') || lower.contains('air') || lower.contains('pulsa') || lower.contains('wifi')) return '⚡';
    if (lower.contains('sehat') || lower.contains('health') || lower.contains('obat') || lower.contains('dokter') || lower.contains('gym')) return '💊';
    if (lower.contains('hiburan') || lower.contains('entertain') || lower.contains('game') || lower.contains('film') || lower.contains('nonton')) return '🎮';
    if (lower.contains('edukasi') || lower.contains('education') || lower.contains('belajar') || lower.contains('buku') || lower.contains('kursus') || lower.contains('didik')) return '📚';
    if (lower.contains('gaya') || lower.contains('lifestyle') || lower.contains('hobi')) return '✨';
    if (lower.contains('gaji') || lower.contains('salar') || lower.contains('upah')) return '💰';
    if (lower.contains('proyek') || lower.contains('freelance') || lower.contains('kerja') || lower.contains('lepas')) return '💻';
    if (lower.contains('bisnis') || lower.contains('business') || lower.contains('usaha') || lower.contains('omset') || lower.contains('toko')) return '🏢';
    if (lower.contains('invest') || lower.contains('saham') || lower.contains('crypto') || lower.contains('reksa')) return '📈';
    if (lower.contains('hadiah') || lower.contains('gift') || lower.contains('bonus') || lower.contains('thr')) return '🎁';
    if (lower.contains('tabung') || lower.contains('saving')) return '🪙';
    return '📦';
  }

  static String normalizeCategoryName(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower == 'food & beverage' || lower == 'food' || lower == 'makanan' || lower == 'makanan & minuman' || lower.contains('makan')) {
      return 'Makanan & Minuman';
    }
    if (lower == 'transportation' || lower == 'transport' || lower == 'transportasi') {
      return 'Transportasi';
    }
    if (lower == 'shopping' || lower == 'belanja') {
      return 'Belanja';
    }
    if (lower == 'housing' || lower == 'tempat tinggal' || lower == 'rumah') {
      return 'Tempat Tinggal';
    }
    if (lower == 'bills & utilities' || lower == 'bills' || lower == 'tagihan' || lower == 'tagihan & utilitas' || lower == 'utilitas') {
      return 'Tagihan & Utilitas';
    }
    if (lower == 'health' || lower == 'kesehatan') {
      return 'Kesehatan';
    }
    if (lower == 'entertainment' || lower == 'hiburan') {
      return 'Hiburan';
    }
    if (lower == 'education' || lower == 'pendidikan') {
      return 'Pendidikan';
    }
    if (lower == 'lifestyle' || lower == 'gaya hidup') {
      return 'Gaya Hidup';
    }
    if (lower == 'others' || lower == 'other' || lower == 'lainnya' || lower == 'lain-lain') {
      return 'Lainnya';
    }
    if (lower == 'salary' || lower == 'gaji') {
      return 'Gaji';
    }
    if (lower == 'freelance' || lower == 'pekerjaan lepas') {
      return 'Pekerjaan Lepas';
    }
    if (lower == 'business' || lower == 'bisnis' || lower == 'bisnis & usaha' || lower == 'usaha') {
      return 'Bisnis & Usaha';
    }
    if (lower == 'investment' || lower == 'investasi') {
      return 'Investasi';
    }
    if (lower == 'gift' || lower == 'hadiah' || lower == 'hadiah & bonus' || lower == 'bonus') {
      return 'Hadiah & Bonus';
    }
    return raw.trim();
  }

  Widget buildIconWidget({double size = 20, Color? color}) {
    final emojiChar = (emoji != null && emoji!.trim().isNotEmpty)
        ? emoji!
        : fallbackEmojiFor(name);
    return Text(
      emojiChar,
      style: TextStyle(
        fontSize: size,
        height: 1.1,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'emoji': (emoji != null && emoji!.trim().isNotEmpty) ? emoji : fallbackEmojiFor(name),
      'iconName': iconName,
      'iconCodePoint': icon?.codePoint,
      'iconFontFamily': icon?.fontFamily,
      'iconFontPackage': icon?.fontPackage,
      'colorValue': colorValue,
      'isDefault': isDefault,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'expense';
    final type = TransactionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => TransactionType.expense,
    );

    final rawName = json['name'] as String? ?? 'Kategori';
    final parsedEmoji = (json['emoji'] as String?)?.trim();
    final effectiveEmoji = (parsedEmoji != null && parsedEmoji.isNotEmpty)
        ? parsedEmoji
        : fallbackEmojiFor(rawName);

    IconData? icon;
    final iconName = json['iconName'] as String?;
    if (iconName != null) {
      icon = IconCatalog.findTablerIcon(iconName);
      if (icon == null) {
        for (final def in [...defaultExpenseCategories, ...defaultIncomeCategories]) {
          if (def.iconName == iconName || def.id == json['id']) {
            icon = def.icon;
            break;
          }
        }
      }
    }

    return CategoryModel(
      id: json['id'] as String? ?? 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: rawName,
      type: type,
      icon: icon,
      emoji: effectiveEmoji,
      iconName: iconName,
      colorValue: json['colorValue'] as int?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  static const List<CategoryModel> defaultExpenseCategories = [
    CategoryModel(id: 'food', name: 'Makanan & Minuman', type: TransactionType.expense, emoji: '🍔', icon: Icons.restaurant_rounded, iconName: 'food', colorValue: 0xFFFFC857, isDefault: true),
    CategoryModel(id: 'transport', name: 'Transportasi', type: TransactionType.expense, emoji: '🚗', icon: Icons.directions_car_rounded, iconName: 'transport', colorValue: 0xFF55C7FF, isDefault: true),
    CategoryModel(id: 'shopping', name: 'Belanja', type: TransactionType.expense, emoji: '🛍️', icon: Icons.shopping_bag_rounded, iconName: 'shopping', colorValue: 0xFFFF6B7A, isDefault: true),
    CategoryModel(id: 'housing', name: 'Tempat Tinggal', type: TransactionType.expense, emoji: '🏠', icon: Icons.home_rounded, iconName: 'housing', colorValue: 0xFF939CFE, isDefault: true),
    CategoryModel(id: 'bills', name: 'Tagihan & Utilitas', type: TransactionType.expense, emoji: '⚡', icon: Icons.receipt_long_rounded, iconName: 'bills', colorValue: 0xFFB996FF, isDefault: true),
    CategoryModel(id: 'health', name: 'Kesehatan', type: TransactionType.expense, emoji: '💊', icon: Icons.favorite_rounded, iconName: 'health', colorValue: 0xFF39D98A, isDefault: true),
    CategoryModel(id: 'entertainment', name: 'Hiburan', type: TransactionType.expense, emoji: '🎮', icon: Icons.sports_esports_rounded, iconName: 'entertainment', colorValue: 0xFFEC4899, isDefault: true),
    CategoryModel(id: 'education', name: 'Pendidikan', type: TransactionType.expense, emoji: '📚', icon: Icons.school_rounded, iconName: 'education', colorValue: 0xFF38BDF8, isDefault: true),
    CategoryModel(id: 'lifestyle', name: 'Gaya Hidup', type: TransactionType.expense, emoji: '✨', icon: Icons.spa_rounded, iconName: 'lifestyle', colorValue: 0xFFF472B6, isDefault: true),
    CategoryModel(id: 'other_exp', name: 'Lainnya', type: TransactionType.expense, emoji: '📦', icon: Icons.more_horiz_rounded, iconName: 'other', colorValue: 0xFF8CA7C5, isDefault: true),
  ];

  static const List<CategoryModel> defaultIncomeCategories = [
    CategoryModel(id: 'salary', name: 'Gaji', type: TransactionType.income, emoji: '💰', icon: Icons.account_balance_wallet_rounded, iconName: 'salary', colorValue: 0xFF39D98A, isDefault: true),
    CategoryModel(id: 'freelance', name: 'Pekerjaan Lepas', type: TransactionType.income, emoji: '💻', icon: Icons.laptop_mac_rounded, iconName: 'freelance', colorValue: 0xFF2B8DE0, isDefault: true),
    CategoryModel(id: 'business', name: 'Bisnis & Usaha', type: TransactionType.income, emoji: '🏢', icon: Icons.storefront_rounded, iconName: 'business', colorValue: 0xFF55C7FF, isDefault: true),
    CategoryModel(id: 'investment', name: 'Investasi', type: TransactionType.income, emoji: '📈', icon: Icons.trending_up_rounded, iconName: 'investment', colorValue: 0xFF14B8A6, isDefault: true),
    CategoryModel(id: 'gift', name: 'Hadiah & Bonus', type: TransactionType.income, emoji: '🎁', icon: Icons.card_giftcard_rounded, iconName: 'gift', colorValue: 0xFFFFC857, isDefault: true),
    CategoryModel(id: 'other_inc', name: 'Lainnya', type: TransactionType.income, emoji: '🧧', icon: Icons.savings_rounded, iconName: 'other', colorValue: 0xFF8CA7C5, isDefault: true),
  ];

  static List<CategoryModel> getCategories(TransactionType type) {
    if (type == TransactionType.income) return defaultIncomeCategories;
    return defaultExpenseCategories;
  }
}
