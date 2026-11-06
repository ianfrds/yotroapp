import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
import '../utils/thousands_separator_formatter.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/nested_card.dart';
import '../widgets/slide_up_route.dart';
import '../widgets/receipt_adjustment_sheet.dart';
import '../services/receipt_scanner/receipt_scanner_service.dart';
import 'transaction_success_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? initialTransaction;
  final TransactionType? initialType;
  final String? initialCategory;

  const AddTransactionScreen({
    super.key,
    this.initialTransaction,
    this.initialType,
    this.initialCategory,
  });

  /// Static helper for smooth bottom-to-top swipe-up route transition
  static Route<T> route<T>({
    TransactionModel? initialTransaction,
    TransactionType? initialType,
    String? initialCategory,
  }) {
    return SlideUpRoute(
      page: AddTransactionScreen(
        initialTransaction: initialTransaction,
        initialType: initialType,
        initialCategory: initialCategory,
      ),
    );
  }

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TransactionType _type;
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  final FocusNode _amountFocusNode = FocusNode();
  late String _selectedCategory;
  late String _selectedWalletId;
  String? _fromWalletId;
  String? _toWalletId;
  late DateTime _selectedDate;

  bool get _isEdit => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.initialTransaction;
    _type = tx?.type ?? widget.initialType ?? TransactionType.expense;

    final initialAmount = tx != null
        ? ThousandsSeparatorInputFormatter.formatNumber(tx.amount.toStringAsFixed(0))
        : '0';
    _amountController = TextEditingController(text: initialAmount);
    _titleController = TextEditingController(text: tx?.title ?? '');
    _noteController = TextEditingController(text: tx?.note ?? '');
    _selectedCategory = tx != null
        ? CategoryModel.normalizeCategoryName(tx.categoryName)
        : (widget.initialCategory != null
            ? CategoryModel.normalizeCategoryName(widget.initialCategory!)
            : 'Makanan & Minuman');
    _selectedWalletId = tx?.walletId ?? 'w_bank';
    _fromWalletId = tx?.fromWalletId ?? 'w_bank';
    _toWalletId = tx?.toWalletId ?? 'w_cash';
    _selectedDate = tx?.timestamp ?? DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (!_isEdit) {
          _amountFocusNode.requestFocus();
          if (_amountController.text == '0') {
            _amountController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _amountController.text.length,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _currentAmount {
    return double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
  }

  String _formatIndonesianDate(DateTime date) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2B8DE0),
              surface: Color(0xFF0C131D),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final amount = _currentAmount;
    if (amount <= 0) {
      AppSnackBar.show(
        context,
        'Nominal transaksi harus lebih dari 0',
        type: SnackBarType.danger,
      );
      return;
    }

    final provider = context.read<TransactionProvider>();

    if (_isEdit) {
      await provider.deleteTransaction(widget.initialTransaction!.id);
    }

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : (_type == TransactionType.transfer ? 'Transfer' : _selectedCategory);

    final categoryId = _selectedCategory.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

    final newTx = await provider.addTransaction(
      title: title,
      amount: amount,
      type: _type,
      categoryName: _type == TransactionType.transfer ? 'Transfer' : _selectedCategory,
      categoryId: categoryId,
      walletId: _selectedWalletId,
      fromWalletId: _type == TransactionType.transfer ? _fromWalletId : null,
      toWalletId: _type == TransactionType.transfer ? _toWalletId : null,
      note: _noteController.text.trim(),
      date: _selectedDate,
    );

    if (!mounted) return;

    if (_isEdit) {
      AppSnackBar.show(
        context,
        'Perubahan transaksi berhasil disimpan',
        type: SnackBarType.success,
      );
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionSuccessScreen(
            transaction: newTx,
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    if (!_isEdit) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    showModalCardSheet(
      context: context,
      title: 'Hapus Transaksi',
      titleIcon: Icons.delete_outline_rounded,
      titleIconColor: const Color(0xFFFF6B7A),
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
                  color: const Color(0xFFFF6B7A).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B7A), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hapus transaksi ini?',
                  style: GoogleFonts.interTight(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Transaksi ini akan dihapus permanen dan saldo dompet akan dikembalikan ke posisi semula. Tindakan ini tidak dapat dibatalkan.',
            style: GoogleFonts.manrope(
              color: textMuted,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textMuted,
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  key: const Key('btn_confirm_delete_modal'),
                  onPressed: () async {
                    Navigator.pop(context); // close bottom sheet
                    await context.read<TransactionProvider>().deleteTransaction(widget.initialTransaction!.id);
                    if (mounted) {
                      AppSnackBar.show(context, 'Transaksi berhasil dihapus', type: SnackBarType.danger);
                      Navigator.pop(context); // exit edit screen
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B7A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Hapus',
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();
    final categories = provider.getCategories(_type);

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : const Color(0xFFF4F5F7),
      body: SafeArea(
        child: GestureDetector(
          // Swipe down to dismiss
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! > 320) {
              Navigator.pop(context);
            }
          },
          child: Column(
            children: [
              _buildTopBar(isDark),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                  children: [
                    _buildTypeSelector(isDark),
                    const SizedBox(height: 16),
                    _buildAmountCard(provider, isDark),
                    const SizedBox(height: 16),
                    _buildDetailsCard(provider, categories, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              _buildBottomAction(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.24) : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  size: 22,
                ),
                tooltip: 'Tutup',
              ),
              Text(
                _isEdit ? 'Ubah Transaksi' : 'Catat Transaksi',
                style: GoogleFonts.interTight(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C131D) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypePill(
              label: 'Pengeluaran',
              type: TransactionType.expense,
              activeColor: const Color(0xFFF43F5E),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildTypePill(
              label: 'Pemasukan',
              type: TransactionType.income,
              activeColor: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildTypePill(
              label: 'Transfer',
              type: TransactionType.transfer,
              activeColor: const Color(0xFF2B8DE0),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypePill({
    required String label,
    required TransactionType type,
    required Color activeColor,
    required bool isDark,
  }) {
    final isSelected = _type == type;
    return InkWell(
      onTap: () {
        setState(() {
          _type = type;
          if (type != TransactionType.transfer) {
            final available = context.read<TransactionProvider>().getCategories(type);
            if (!available.any((c) => c.name == _selectedCategory) && available.isNotEmpty) {
              _selectedCategory = available.first.name;
            }
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.manrope(
            color: isSelected ? Colors.white : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B)),
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard(TransactionProvider provider, bool isDark) {
    return NestedCard(
      title: 'Nominal & Keterangan',
      action: provider.currency,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  provider.currency == 'IDR' ? 'Rp ' : '\$ ',
                  style: GoogleFonts.interTight(
                    color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF475569),
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [
                      ThousandsSeparatorInputFormatter(),
                    ],
                    onTap: () {
                      if (_amountController.text == '0') {
                        _amountController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _amountController.text.length,
                        );
                      }
                    },
                    style: GoogleFonts.interTight(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.6,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
            ),
            const SizedBox(height: 10),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      style: GoogleFonts.manrope(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Catatan / judul transaksi (cth: Mie Goreng, Bensin)...',
                        hintStyle: GoogleFonts.manrope(
                          color: isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
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

  Widget _buildCategorySelector(BuildContext context, List<CategoryModel> categories, bool isDark) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const double spacing = 8;
        const double lainyaWidth = 100; // Width for "Lainnya" pill button

        // Calculate text width for a category pill
        double calcPillWidth(CategoryModel cat) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: cat.name,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();
          // horizontal padding (22) + emoji (22) + gap (6) + border/safety (14) = 64
          return textPainter.width + 64;
        }

        // Ordered categories: make sure selected category is prioritized
        final orderedCategories = <CategoryModel>[];
        final selectedCat = categories.cast<CategoryModel?>().firstWhere(
              (c) => c?.name == _selectedCategory,
              orElse: () => null,
            );
        if (selectedCat != null) {
          orderedCategories.add(selectedCat);
        }
        for (final cat in categories) {
          if (cat.name != _selectedCategory) {
            orderedCategories.add(cat);
          }
        }

        // Fit items into at most 2 rows, reserving space for "Lainnya" on row 2 if needed
        final row1 = <CategoryModel>[];
        final row2 = <CategoryModel>[];
        double row1Width = 0;
        double row2Width = 0;
        bool hasOverflow = false;

        for (final cat in orderedCategories) {
          final w = calcPillWidth(cat);
          final wWithSpacing1 = row1.isEmpty ? w : w + spacing;
          if (row1Width + wWithSpacing1 <= availableWidth) {
            row1.add(cat);
            row1Width += wWithSpacing1;
            continue;
          }

          // Row 1 full, test Row 2 reserving space for Lainnya
          final wWithSpacing2 = row2.isEmpty ? w : w + spacing;
          if (row2Width + wWithSpacing2 + spacing + lainyaWidth <= availableWidth) {
            row2.add(cat);
            row2Width += wWithSpacing2;
          } else {
            hasOverflow = true;
            break;
          }
        }

        // If not all categories fitted, hasOverflow is true
        if (row1.length + row2.length < categories.length) {
          hasOverflow = true;
        }

        Widget buildPill(CategoryModel cat) {
          final isSel = cat.name == _selectedCategory;
          final color = Color(cat.colorValue ?? 0xFF2B8DE0);
          return InkWell(
            onTap: () => setState(() => _selectedCategory = cat.name),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: isSel
                    ? color.withOpacity(0.22)
                    : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSel
                      ? color
                      : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1)),
                  width: isSel ? 1.4 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  cat.buildIconWidget(size: 15),
                  const SizedBox(width: 6),
                  Text(
                    cat.name,
                    style: GoogleFonts.manrope(
                      color: isSel
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF475569)),
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final lainyaButton = InkWell(
          onTap: () => _showCategoryPickerSheet(context, categories, isDark),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isDark ? const Color(0xFF55C7FF) : const Color(0xFF0284C7)).withOpacity(0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF0284C7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Lainnya',
                  style: GoogleFonts.manrope(
                    color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF0284C7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (row1.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < row1.length; i++) ...[
                      if (i > 0) const SizedBox(width: spacing),
                      buildPill(row1[i]),
                    ],
                  ],
                ),
              ),
            if (row2.isNotEmpty || hasOverflow) ...[
              const SizedBox(height: spacing),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < row2.length; i++) ...[
                      if (i > 0) const SizedBox(width: spacing),
                      buildPill(row2[i]),
                    ],
                    if (hasOverflow || categories.length > (row1.length + row2.length)) ...[
                      if (row2.isNotEmpty) const SizedBox(width: spacing),
                      lainyaButton,
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showCategoryPickerSheet(
    BuildContext context,
    List<CategoryModel> categories,
    bool isDark,
  ) {
    showModalCardSheet(
      context: context,
      title: _type == TransactionType.expense
          ? 'Pilih Kategori Pengeluaran'
          : 'Pilih Kategori Pemasukan',
      titleIcon: Icons.category_rounded,
      titleIconColor: isDark ? const Color(0xFF55C7FF) : const Color(0xFF0284C7),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double spacing = 10;
              final itemWidth = (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: 10,
                children: categories.map((cat) {
                  final isSel = cat.name == _selectedCategory;
                  final color = Color(cat.colorValue ?? 0xFF2B8DE0);
                  return SizedBox(
                    width: itemWidth,
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedCategory = cat.name);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel
                              ? color.withOpacity(0.24)
                              : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel
                                ? color
                                : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)),
                            width: isSel ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            cat.buildIconWidget(size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cat.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  color: isSel
                                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                      : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF475569)),
                                  fontSize: 13,
                                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isSel) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: color,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(TransactionProvider provider, List<CategoryModel> categories, bool isDark) {
    final wallets = provider.wallets;
    final validSelectedWalletId = wallets.any((w) => w.id == _selectedWalletId)
        ? _selectedWalletId
        : (wallets.isNotEmpty ? wallets.first.id : null);
    final validFromWalletId = wallets.any((w) => w.id == _fromWalletId)
        ? _fromWalletId
        : (wallets.isNotEmpty ? wallets.first.id : null);
    final validToWalletId = wallets.any((w) => w.id == _toWalletId)
        ? _toWalletId
        : (wallets.length > 1 ? wallets[1].id : (wallets.isNotEmpty ? wallets.first.id : null));

    return NestedCard(
      title: 'Detail Transaksi',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category selector (if not transfer)
            if (_type != TransactionType.transfer) ...[
              Text(
                'Kategori',
                style: GoogleFonts.manrope(
                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategorySelector(context, categories, isDark),
              const SizedBox(height: 14),
            ],

            // Wallet selection
            if (_type != TransactionType.transfer) ...[
              Text(
                'Dompet / Akun',
                style: GoogleFonts.manrope(
                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: validSelectedWalletId,
                    dropdownColor: isDark ? const Color(0xFF0C131D) : Colors.white,
                    isExpanded: true,
                    isDense: true,
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      size: 20,
                    ),
                    style: GoogleFonts.manrope(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                    items: wallets.map((w) {
                      return DropdownMenuItem(
                        value: w.id,
                        child: Text('${w.name} (${provider.formatCurrency(w.balance)})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedWalletId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dari Dompet',
                          style: GoogleFonts.manrope(
                            color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: validFromWalletId,
                              dropdownColor: isDark ? const Color(0xFF0C131D) : Colors.white,
                              isExpanded: true,
                              isDense: true,
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                size: 18,
                              ),
                              style: GoogleFonts.manrope(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 11.5,
                              ),
                              items: wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _fromWalletId = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ke Dompet',
                          style: GoogleFonts.manrope(
                            color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: validToWalletId,
                              dropdownColor: isDark ? const Color(0xFF0C131D) : Colors.white,
                              isExpanded: true,
                              isDense: true,
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                size: 18,
                              ),
                              style: GoogleFonts.manrope(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 11.5,
                              ),
                              items: wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _toWalletId = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Date picker
            Text(
              'Tanggal',
              style: GoogleFonts.manrope(
                color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatIndonesianDate(_selectedDate),
                      style: GoogleFonts.manrope(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_rounded,
                      color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                      size: 15,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.background : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: _isEdit
          ? Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      key: const Key('btn_delete_transaction'),
                      onPressed: _confirmDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF6B7A),
                        side: BorderSide(
                          color: const Color(0xFFFF6B7A).withOpacity(0.5),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFFF6B7A)),
                          const SizedBox(width: 6),
                          Text(
                            'Hapus',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF6B7A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('btn_save_transaction'),
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : const Color(0xFF02539A),
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Simpan',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                // Camera / OCR Button (Left)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Material(
                    color: isDark ? const Color(0xFF242D3D) : const Color(0xFFE2E8F0),
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('btn_scan_receipt'),
                      customBorder: const CircleBorder(),
                      onTap: _openReceiptScannerSheet,
                      child: Center(
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 22,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Primary Save Action (Pill Center)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('btn_save_transaction'),
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : const Color(0xFF02539A),
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Simpan Transaksi',
                        style: GoogleFonts.manrope(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Microphone / Voice Note Action (Right)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Material(
                    color: isDark ? const Color(0xFF242D3D) : const Color(0xFFE2E8F0),
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('btn_voice_input'),
                      customBorder: const CircleBorder(),
                      onTap: _onMicTapped,
                      child: Center(
                        child: Icon(
                          Icons.mic_none_rounded,
                          size: 22,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _onMicTapped() {
    AppSnackBar.show(
      context,
      'Fitur input suara akan hadir di pembaruan berikutnya',
      type: SnackBarType.info,
    );
  }

  void _openReceiptScannerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2229) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Pindai Struk Belanja (OCR)',
              style: GoogleFonts.interTight(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih sumber foto untuk membaca total, toko, dan kategori',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('btn_pick_camera'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _scanFromSource(ReceiptImageSource.camera);
                    },
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Kamera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      side: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('btn_pick_gallery'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _scanFromSource(ReceiptImageSource.gallery);
                    },
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Galeri'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      side: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanFromSource(ReceiptImageSource source) async {
    AppSnackBar.show(
      context,
      'Memindai struk belanja dengan OCR...',
      type: SnackBarType.info,
    );

    final data = await ReceiptScannerService.scanReceipt(context, source: source);
    if (!mounted) return;

    if (data == null) {
      AppSnackBar.show(
        context,
        'Pemindaian struk dibatalkan atau gambar tidak ditemukan',
        type: SnackBarType.warning,
      );
      return;
    }

    ReceiptAdjustmentSheet.show(
      context,
      receiptData: data,
      onApplyToForm: (adjusted, walletId) {
        setState(() {
          _amountController.text = ThousandsSeparatorInputFormatter.formatNumber(
            adjusted.totalAmount.toStringAsFixed(0),
          );
          _titleController.text = adjusted.merchantName;
          _selectedCategory = adjusted.suggestedCategory;
          _selectedDate = adjusted.date;
          _selectedWalletId = walletId;
        });
        AppSnackBar.show(
          context,
          'Data struk berhasil diterapkan ke formulir!',
          type: SnackBarType.success,
        );
      },
      onApproveAndSave: (adjusted, walletId) async {
        final provider = context.read<TransactionProvider>();
        final categoryId = adjusted.suggestedCategory.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

        final newTx = await provider.addTransaction(
          title: adjusted.merchantName.isNotEmpty ? adjusted.merchantName : 'Struk Belanja',
          amount: adjusted.totalAmount,
          type: TransactionType.expense,
          categoryName: adjusted.suggestedCategory,
          categoryId: categoryId,
          walletId: walletId,
          date: adjusted.date,
          note: 'Dicatat otomatis via OCR struk belanja',
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionSuccessScreen(
              transaction: newTx,
            ),
          ),
        );
      },
    );
  }

}
