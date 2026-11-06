import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/icon_catalog.dart';
import '../widgets/nested_card.dart';
import '../widgets/standard_screen_header.dart';
import '../widgets/app_snackbar.dart';

class EditCategoryScreen extends StatefulWidget {
  final TransactionType initialType;
  final CategoryModel? categoryToEdit;
  final bool isSheet;

  const EditCategoryScreen({
    super.key,
    this.initialType = TransactionType.expense,
    this.categoryToEdit,
    this.isSheet = false,
  });

  static Route<void> route({
    TransactionType initialType = TransactionType.expense,
    CategoryModel? categoryToEdit,
  }) {
    return MaterialPageRoute(
      builder: (_) => EditCategoryScreen(
        initialType: initialType,
        categoryToEdit: categoryToEdit,
        isSheet: false,
      ),
    );
  }

  static Future<void> showAsModalSheet(
    BuildContext context, {
    TransactionType initialType = TransactionType.expense,
    CategoryModel? categoryToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditCategoryScreen(
        initialType: initialType,
        categoryToEdit: categoryToEdit,
        isSheet: true,
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
  String _selectedEmojiCategory = 'Semua';

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
    _nameController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      (_selectedEmoji != null && _selectedEmoji!.trim().isNotEmpty);

  @override
  void dispose() {
    _nameController.removeListener(_onFormChanged);
    _nameController.dispose();
    _emojiCustomController.dispose();
    _searchIconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.categoryToEdit != null;

    final body = ListView(
      key: const Key('edit_category_scroll_view'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
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
                // Nama Kategori Label
                Text(
                  'Nama Kategori',
                  style: GoogleFonts.manrope(
                    color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Icon preview + Name TextField Row (perfectly centered & equal height)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color(_selectedColor).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(_selectedColor).withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _selectedEmoji ?? '🍔',
                        style: const TextStyle(fontSize: 24, height: 1.1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _nameController,
                          textAlignVertical: TextAlignVertical.center,
                          style: GoogleFonts.manrope(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Contoh: Belanja Bulanan',
                            hintStyle: GoogleFonts.manrope(
                              color: isDark ? const Color(0xFF5A667A) : const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: isDark ? _surfaceDark : const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Type Segment (Pengeluaran vs Pemasukan)
                Text(
                  'Jenis Transaksi',
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
                    color: isDark ? _surfaceDark : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
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

                // Color Palette
                Text(
                  'Aksen Warna',
                  style: GoogleFonts.manrope(
                    color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _colorPalette.map((colVal) {
                    final isSelected = _selectedColor == colVal;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colVal),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Color(colVal),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.black.withOpacity(0.4) : const Color(0xFFCBD5E1)),
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Color(colVal).withOpacity(0.55),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Card 2: Pilihan Emoji (Grouped by Category)
        NestedCard(
          title: 'Pilihan Emoji',
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search box
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
                    hintText: 'Cari emoji (kopi, mobil, rumah, gaji)...',
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
                const SizedBox(height: 10),

                // Horizontal Category Filter Chips
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: IconCatalog.emojiCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (ctx, i) {
                      final cat = IconCatalog.emojiCategories[i];
                      final isSelected = _selectedEmojiCategory == cat;
                      return ChoiceChip(
                        label: Text(
                          cat,
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B)),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF02539A),
                        backgroundColor: isDark ? _surfaceDark : const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF55C7FF).withOpacity(0.5)
                                : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedEmojiCategory = cat);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Grouped / Filtered Emoji List Container
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: isDark ? _surfaceDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: _buildEmojiContent(isDark),
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
      ],
    );

    if (widget.isSheet) {
      return Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.94,
          decoration: BoxDecoration(
            color: isDark ? _bgCanvas : const Color(0xFFF4F5F7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(child: body),
              _buildFixedSubmitButton(isDark, isEditing),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? _bgCanvas : const Color(0xFFF4F5F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: body),
            _buildFixedSubmitButton(isDark, isEditing),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedSubmitButton(bool isDark, bool isEditing) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + (bottomInset > 0 ? bottomInset : MediaQuery.of(context).padding.bottom),
      ),
      decoration: BoxDecoration(
        color: isDark ? _surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          key: const Key('save_category_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF02539A),
            foregroundColor: Colors.white,
            disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isFormValid ? _saveCategory : null,
          child: Text(
            isEditing ? 'Simpan Perubahan' : 'Simpan Kategori',
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiContent(bool isDark) {
    final query = _emojiSearchQuery.trim().toLowerCase();

    // 1. If searching, show direct search results
    if (query.isNotEmpty) {
      final results = IconCatalog.emojis.where((item) {
        return item.label.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query) ||
            item.char.contains(query);
      }).toList();

      if (results.isEmpty) {
        return Center(
          child: Text(
            'Tidak ada emoji yang cocok',
            style: GoogleFonts.manrope(
              color: isDark ? const Color(0xFF708398) : const Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        );
      }

      return _buildEmojiGrid(results, isDark);
    }

    // 2. If a specific category is selected (not 'Semua')
    if (_selectedEmojiCategory != 'Semua') {
      final categoryEmojis = IconCatalog.emojis
          .where((item) => item.category == _selectedEmojiCategory)
          .toList();
      return _buildEmojiGrid(categoryEmojis, isDark);
    }

    // 3. 'Semua' selected: show grouped sections by category
    final categories = IconCatalog.emojiCategories.where((c) => c != 'Semua').toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: categories.length,
      itemBuilder: (ctx, idx) {
        final cat = categories[idx];
        final groupEmojis = IconCatalog.emojis.where((item) => item.category == cat).toList();
        if (groupEmojis.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 6),
              child: Text(
                cat,
                style: GoogleFonts.interTight(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF0284C7),
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemCount: groupEmojis.length,
              itemBuilder: (ctx, i) => _buildEmojiTile(groupEmojis[i], isDark),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildEmojiGrid(List<EmojiItem> list, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: list.length,
      itemBuilder: (ctx, idx) => _buildEmojiTile(list[idx], isDark),
    );
  }

  Widget _buildEmojiTile(EmojiItem item, bool isDark) {
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
  }

  void _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.show(
        context,
        'Nama kategori tidak boleh kosong',
        type: SnackBarType.danger,
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
