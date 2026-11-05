import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/icon_catalog.dart';
import '../widgets/nested_card.dart';
import '../widgets/standard_screen_header.dart';

class EditCategoryScreen extends StatefulWidget {
  final TransactionType initialType;
  final CategoryModel? categoryToEdit;

  const EditCategoryScreen({
    super.key,
    this.initialType = TransactionType.expense,
    this.categoryToEdit,
  });

  static Route<void> route({
    TransactionType initialType = TransactionType.expense,
    CategoryModel? categoryToEdit,
  }) {
    return MaterialPageRoute(
      builder: (_) => EditCategoryScreen(
        initialType: initialType,
        categoryToEdit: categoryToEdit,
      ),
    );
  }

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  static const Color _bgCanvas = Color(0xFF1C2229);
  static const Color _surfaceDark = Color(0xFF0C131D);
  static const Color _accentOceanic = Color(0xFF02539A);
  static const Color _cyan = Color(0xFF55C7FF);

  static const List<int> _colorPalette = [
    0xFFFFC857, // Amber
    0xFF55C7FF, // Cyan
    0xFFFF6B7A, // Rose
    0xFF939CFE, // Lavender
    0xFFB996FF, // Purple
    0xFF39D98A, // Emerald Green
    0xFFEC4899, // Pink
    0xFF38BDF8, // Sky Blue
    0xFF8CA7C5, // Slate
  ];

  late TextEditingController _nameController;
  late TextEditingController _emojiCustomController;
  late TextEditingController _searchIconController;

  late TransactionType _type;
  late int _selectedColor;

  String? _selectedEmoji;
  String _emojiSearchQuery = '';

  @override
  void initState() {
    super.initState();
    final edit = widget.categoryToEdit;
    _nameController = TextEditingController(text: edit?.name ?? '');
    _type = edit?.type ?? widget.initialType;
    _selectedColor = edit?.colorValue ?? _colorPalette.first;

    if (edit != null) {
      _selectedEmoji = edit.emoji ?? CategoryModel.fallbackEmojiFor(edit.name);
    } else {
      _selectedEmoji = '🍔';
    }

    _emojiCustomController = TextEditingController();
    _searchIconController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiCustomController.dispose();
    _searchIconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.categoryToEdit != null;
    final filteredEmojis = _emojiSearchQuery.trim().isEmpty
        ? IconCatalog.emojis
        : IconCatalog.emojis.where((item) {
            final q = _emojiSearchQuery.toLowerCase();
            return item.label.toLowerCase().contains(q) ||
                item.category.toLowerCase().contains(q) ||
                item.char.contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: isDark ? _bgCanvas : const Color(0xFFF4F5F7),
      body: SafeArea(
        child: ListView(
          key: const Key('edit_category_scroll_view'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
          children: [
            StandardScreenHeader(
              title: isEditing ? 'Ubah Kategori' : 'Tambah Kategori Baru',
              showBackButton: true,
              onBack: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            // Card 1: Informasi Kategori
            NestedCard(
              title: 'Informasi Kategori',
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon preview + Name
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color(_selectedColor).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Color(_selectedColor).withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            _selectedEmoji ?? '🍔',
                            style: const TextStyle(fontSize: 26, height: 1.1),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama Kategori',
                                style: GoogleFonts.manrope(
                                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _nameController,
                                style: GoogleFonts.manrope(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Contoh: Belanja Bulanan',
                                  hintStyle: GoogleFonts.manrope(
                                    color: isDark ? const Color(0xFF5A667A) : const Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: isDark ? _surfaceDark : const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isDark ? _cyan : const Color(0xFF0284C7)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tipe Transaksi
                    Text(
                      'Tipe Transaksi',
                      style: GoogleFonts.manrope(
                        color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? _surfaceDark : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSegmentButton(
                              title: 'Pengeluaran',
                              isSelected: _type == TransactionType.expense,
                              isDark: isDark,
                              onTap: () => setState(() => _type = TransactionType.expense),
                            ),
                          ),
                          Expanded(
                            child: _buildSegmentButton(
                              title: 'Pemasukan',
                              isSelected: _type == TransactionType.income,
                              isDark: isDark,
                              onTap: () => setState(() => _type = TransactionType.income),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Warna Aksen
                    Text(
                      'Warna Aksen',
                      style: GoogleFonts.manrope(
                        color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _colorPalette.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, idx) {
                          final colorVal = _colorPalette[idx];
                          final isSelected = colorVal == _selectedColor;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = colorVal),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(colorVal),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.black, size: 16)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Card 2: Pilihan Emoji
            NestedCard(
              title: 'Pilihan Emoji',
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar for emoji
                    TextField(
                      controller: _searchIconController,
                      onChanged: (val) => setState(() => _emojiSearchQuery = val),
                      style: GoogleFonts.manrope(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                          size: 18,
                        ),
                        suffixIcon: _emojiSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                  size: 16,
                                ),
                                onPressed: () {
                                  _searchIconController.clear();
                                  setState(() => _emojiSearchQuery = '');
                                },
                              )
                            : null,
                        hintText: 'Cari emoji (makanan, kopi, mobil, rumah)...',
                        hintStyle: GoogleFonts.manrope(
                          color: isDark ? const Color(0xFF5A667A) : const Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: isDark ? _surfaceDark : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? _cyan : const Color(0xFF0284C7)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Curated Grid of Emojis
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: isDark ? _surfaceDark : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: filteredEmojis.isEmpty
                          ? Center(
                              child: Text(
                                'Tidak ada emoji yang cocok',
                                style: GoogleFonts.manrope(
                                  color: isDark ? const Color(0xFF708398) : const Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: filteredEmojis.length,
                              itemBuilder: (ctx, idx) {
                                final item = filteredEmojis[idx];
                                final isSelected = _selectedEmoji == item.char;
                                return Tooltip(
                                  message: item.label,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedEmoji = item.char;
                                        _emojiCustomController.text = item.char;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (isDark ? _cyan.withOpacity(0.2) : const Color(0xFFE0F2FE))
                                            : (isDark ? Colors.white.withOpacity(0.04) : Colors.white),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? (isDark ? _cyan : const Color(0xFF0284C7))
                                              : (isDark ? Colors.transparent : const Color(0xFFE2E8F0)),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        item.char,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),

                    // Custom Emoji Input from Keyboard
                    TextField(
                      controller: _emojiCustomController,
                      onChanged: (val) {
                        final trimmed = val.trim();
                        if (trimmed.isNotEmpty) {
                          setState(() {
                            _selectedEmoji = trimmed.characters.last;
                          });
                        }
                      },
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.emoji_emotions_outlined,
                          color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                          size: 18,
                        ),
                        hintText: 'Atau ketik emoji dari keyboard...',
                        hintStyle: GoogleFonts.manrope(
                          color: isDark ? const Color(0xFF5A667A) : const Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: isDark ? _surfaceDark : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? _cyan : const Color(0xFF0284C7)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit CTA Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? _accentOceanic : const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? 'Perbarui Kategori' : 'Simpan Kategori',
                  style: GoogleFonts.manrope(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama kategori tidak boleh kosong'),
          backgroundColor: Color(0xFFF43F5E),
        ),
      );
      return;
    }

    final provider = context.read<TransactionProvider>();
    final edit = widget.categoryToEdit;
    final emoji = _selectedEmoji ?? CategoryModel.fallbackEmojiFor(name);

    if (edit == null) {
      await provider.addCategory(
        name: name,
        type: _type,
        emoji: emoji,
        colorValue: _selectedColor,
      );
    } else {
      await provider.updateCategory(
        id: edit.id,
        name: name,
        type: _type,
        emoji: emoji,
        colorValue: _selectedColor,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? _accentOceanic : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: isDark ? _cyan.withOpacity(0.35) : const Color(0xFFCBD5E1),
                )
              : null,
          boxShadow: (isSelected && !isDark)
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.manrope(
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B)),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

