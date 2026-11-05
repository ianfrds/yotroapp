import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/nested_card.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/standard_screen_header.dart';
import 'edit_category_screen.dart';

class ManageCategoriesScreen extends StatefulWidget {
  final TransactionType initialType;

  const ManageCategoriesScreen({
    super.key,
    this.initialType = TransactionType.expense,
  });

  static Route<void> route({TransactionType initialType = TransactionType.expense}) {
    return MaterialPageRoute(
      builder: (_) => ManageCategoriesScreen(initialType: initialType),
    );
  }

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  static const Color _bgCanvas = Color(0xFF1C2229);
  static const Color _surfaceDark = Color(0xFF0C131D);
  static const Color _accentOceanic = Color(0xFF02539A);
  static const Color _cyan = Color(0xFF55C7FF);
  static const Color _danger = Color(0xFFF43F5E);

  late TransactionType _selectedTab;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialType;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();
    final expenseCategories = provider.getCategories(TransactionType.expense);
    final incomeCategories = provider.getCategories(TransactionType.income);
    final activeCategories = _selectedTab == TransactionType.expense ? expenseCategories : incomeCategories;

    return Scaffold(
      backgroundColor: isDark ? _bgCanvas : const Color(0xFFF4F5F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: StandardScreenHeader(
                title: 'Kelola Kategori',
                showBackButton: true,
                onBack: () => Navigator.pop(context),
                actionWidget: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      EditCategoryScreen.route(initialType: _selectedTab),
                    ).then((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(0.0);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark ? _accentOceanic.withOpacity(0.25) : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? _cyan.withOpacity(0.35) : const Color(0xFF0284C7).withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: isDark ? _cyan : const Color(0xFF0284C7)),
                        const SizedBox(width: 4),
                        Text(
                          'Tambah',
                          style: GoogleFonts.manrope(
                            color: isDark ? _cyan : const Color(0xFF0284C7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
                children: [
                  // Segmented Tab Selector (Pengeluaran vs Pemasukan)
                  _buildTypeSegmentedTabs(expenseCategories.length, incomeCategories.length, isDark),
                  const SizedBox(height: 14),

                  // Category List inside NestedCard
                  NestedCard(
                    title: _selectedTab == TransactionType.expense
                        ? 'Kategori Pengeluaran (${expenseCategories.length})'
                        : 'Kategori Pemasukan (${incomeCategories.length})',
                    child: activeCategories.isEmpty
                        ? _buildEmptyState(isDark)
                        : Column(
                            children: List.generate(activeCategories.length, (index) {
                              final cat = activeCategories[index];
                              final isLast = index == activeCategories.length - 1;
                              return _buildCategoryTile(context, provider, cat, isLast, isDark);
                            }),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSegmentedTabs(int expenseCount, int incomeCount, bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? _surfaceDark : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Pengeluaran ($expenseCount)',
              isSelected: _selectedTab == TransactionType.expense,
              isDark: isDark,
              onTap: () => setState(() => _selectedTab = TransactionType.expense),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTabButton(
              title: 'Pemasukan ($incomeCount)',
              isSelected: _selectedTab == TransactionType.income,
              isDark: isDark,
              onTap: () => setState(() => _selectedTab = TransactionType.income),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? _accentOceanic : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: isDark ? _cyan.withOpacity(0.4) : const Color(0xFFCBD5E1),
                  width: 1,
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
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    TransactionProvider provider,
    CategoryModel cat,
    bool isLast,
    bool isDark,
  ) {
    final catColor = Color(cat.colorValue ?? 0xFF8CA7C5);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              // Category Icon Container
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: catColor.withOpacity(0.28)),
                ),
                child: cat.buildIconWidget(size: 21, color: catColor),
              ),
              const SizedBox(width: 14),

              // Name & Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cat.name,
                      style: GoogleFonts.manrope(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: cat.isDefault
                                ? (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0))
                                : (isDark ? _cyan.withOpacity(0.14) : const Color(0xFFE0F2FE)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cat.isDefault ? 'Bawaan' : 'Kustom',
                            style: GoogleFonts.manrope(
                              color: cat.isDefault
                                  ? (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B))
                                  : (isDark ? _cyan : const Color(0xFF0284C7)),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.isEmoji ? 'Emoji' : 'Icon',
                          style: GoogleFonts.manrope(
                            color: isDark ? const Color(0xFF708398) : const Color(0xFF94A3B8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit Action -> Navigates to EditCategoryScreen
              IconButton(
                tooltip: 'Ubah kategori',
                onPressed: () {
                  Navigator.push(
                    context,
                    EditCategoryScreen.route(
                      initialType: cat.type,
                      categoryToEdit: cat,
                    ),
                  ).then((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0.0);
                    }
                  });
                },
                icon: Icon(
                  Icons.edit_outlined,
                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                  size: 19,
                ),
                constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                padding: EdgeInsets.zero,
              ),

              // Delete Action
              IconButton(
                tooltip: 'Hapus kategori',
                onPressed: () => _confirmDeleteCategory(context, provider, cat),
                icon: const Icon(Icons.delete_outline_rounded, color: _danger, size: 19),
                constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            indent: 68,
            endIndent: 14,
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
          ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.category_outlined,
              color: isDark ? Colors.white.withOpacity(0.3) : const Color(0xFF94A3B8),
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada kategori',
              style: GoogleFonts.manrope(
                color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CRUD BOTTOM SHEET (NESTED CARD STYLE) ---

  void _confirmDeleteCategory(
    BuildContext context,
    TransactionProvider provider,
    CategoryModel category,
  ) {
    showModalCardSheet(
      context: context,
      title: 'Hapus Kategori',
      titleIcon: Icons.delete_outline_rounded,
      titleIconColor: _danger,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: _danger, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hapus "${category.name}"?',
                  style: GoogleFonts.interTight(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Transaksi yang terhubung dengan kategori ini akan dialihkan otomatis ke kategori "Others / Lainnya".',
            style: GoogleFonts.manrope(
              color: const Color(0xFF8EA4BE),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF8EA4BE),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await provider.deleteCategory(category.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Hapus Kategori',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
