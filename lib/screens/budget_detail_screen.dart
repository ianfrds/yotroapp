import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/thousands_separator_formatter.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/slide_up_route.dart';
import 'add_transaction_screen.dart';

class BudgetDetailScreen extends StatefulWidget {
  final String? categoryName; // null means overall budget
  final double? customLimit;

  const BudgetDetailScreen({
    super.key,
    this.categoryName,
    this.customLimit,
  });

  static Route<void> route({String? categoryName, double? customLimit}) {
    return SlideUpRoute(
      page: BudgetDetailScreen(
        categoryName: categoryName,
        customLimit: customLimit,
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    String? categoryName,
    double? customLimit,
  }) {
    return Navigator.of(context).push(
      route(categoryName: categoryName, customLimit: customLimit),
    );
  }

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  DateTime? _selectedChartDate;

  bool get _isOverall => widget.categoryName == null || widget.categoryName == 'Semua Pengeluaran';

  String _formatK(double amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return m % 1 == 0 ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      final k = amount / 1000;
      return k % 1 == 0 ? '${k.toInt()}K' : '${k.toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  double _calculateNiceScaleMax(double maxSpent) {
    if (maxSpent <= 0) return 500000.0;
    if (maxSpent <= 50000) return 50000.0;
    if (maxSpent <= 100000) return 100000.0;
    if (maxSpent <= 250000) return 250000.0;
    if (maxSpent <= 500000) return 500000.0;
    if (maxSpent <= 1000000) return 1000000.0;
    if (maxSpent <= 2000000) return 2000000.0;
    if (maxSpent <= 5000000) return 5000000.0;

    final magnitude = math.pow(10, (math.log(maxSpent) / math.ln10).floor()).toDouble();
    final normalized = maxSpent / magnitude;
    double niceNormalized;
    if (normalized <= 1.0) {
      niceNormalized = 1.0;
    } else if (normalized <= 2.0) {
      niceNormalized = 2.0;
    } else if (normalized <= 5.0) {
      niceNormalized = 5.0;
    } else {
      niceNormalized = 10.0;
    }
    return niceNormalized * magnitude;
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'Hari ini';
    if (target == today.subtract(const Duration(days: 1))) return 'Kemarin';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _showEditSheet(BuildContext context, TransactionProvider provider, double currentLimit) {
    final initialFormatted = ThousandsSeparatorInputFormatter.formatNumber(
      currentLimit.round().toString(),
    );
    final controller = TextEditingController(text: initialFormatted);

    showModalCardSheet(
      context: context,
      title: _isOverall ? 'Ubah Batas Keseluruhan' : 'Ubah Budget ${widget.categoryName}',
      titleIcon: Icons.edit_note_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isOverall
                ? 'Target batas pengeluaran bulanan global.'
                : 'Batas nominal maksimal pengeluaran untuk kategori ini.',
            style: GoogleFonts.manrope(
              color: const Color(0xFF8EA4BE),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Text(
                  provider.currency == 'IDR' ? 'Rp ' : '\$ ',
                  style: GoogleFonts.interTight(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    style: GoogleFonts.interTight(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: GoogleFonts.interTight(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () async {
                final cleanStr = controller.text.replaceAll('.', '').trim();
                final val = double.tryParse(cleanStr) ?? currentLimit;
                if (_isOverall) {
                  await provider.updateOverallBudget(val);
                } else {
                  await provider.updateCategoryBudget(widget.categoryName!, val);
                }
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Simpan Perubahan',
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBudget(BuildContext context, TransactionProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Budget Kategori?',
          style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Target budget untuk "${widget.categoryName}" akan dihapus. Transaksi tidak akan terpengaruh.',
          style: GoogleFonts.manrope(color: const Color(0xFF8EA4BE), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.manrope(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteCategoryBudget(widget.categoryName!);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text('Hapus', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();

    // 1. Data Calculation with category normalization
    final String? targetNorm = widget.categoryName != null
        ? CategoryModel.normalizeCategoryName(widget.categoryName!)
        : null;

    final double budgetLimit = _isOverall
        ? provider.budget.overallMonthlyLimit
        : (provider.budget.categoryBudgets[widget.categoryName] ??
            (targetNorm != null ? provider.budget.categoryBudgets[targetNorm] : null) ??
            widget.customLimit ??
            0.0);

    // Matching expense transactions
    final matchingTransactions = provider.transactions.where((t) {
      if (t.type != TransactionType.expense) return false;
      if (!_isOverall && targetNorm != null) {
        if (CategoryModel.normalizeCategoryName(t.categoryName) != targetNorm) {
          return false;
        }
      }
      return true;
    }).toList();

    matchingTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final double totalSpent = _isOverall
        ? provider.totalExpense
        : matchingTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final double remaining = math.max(0.0, budgetLimit - totalSpent);

    // Group daily expenses for chart
    final Map<DateTime, double> dailyExpenses = {};
    for (final t in matchingTransactions) {
      final dayKey = DateTime(t.timestamp.year, t.timestamp.month, t.timestamp.day);
      dailyExpenses[dayKey] = (dailyExpenses[dayKey] ?? 0.0) + t.amount;
    }

    // Sorted active days
    final activeDays = dailyExpenses.keys.toList()..sort();

    // Transactions filtered by selected chart date if applicable
    final displayedTransactions = _selectedChartDate == null
        ? matchingTransactions
        : matchingTransactions.where((t) {
            return t.timestamp.year == _selectedChartDate!.year &&
                t.timestamp.month == _selectedChartDate!.month &&
                t.timestamp.day == _selectedChartDate!.day;
          }).toList();

    final catObj = _isOverall
        ? null
        : provider.categories.cast<CategoryModel?>().firstWhere(
              (c) =>
                  c != null &&
                  CategoryModel.normalizeCategoryName(c.name) ==
                      (targetNorm ?? CategoryModel.normalizeCategoryName(widget.categoryName!)),
              orElse: () => null,
            );

    final String displayName = _isOverall ? 'Semua Pengeluaran' : (widget.categoryName ?? 'Anggaran');

    final bgColor = isDark ? const Color(0xFF0F141C) : const Color(0xFFF4F5F7);
    final cardBg = isDark ? const Color(0xFF141C28) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: [X] - [Rincian Anggaran] - [...]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: textPrimary,
                      size: 22,
                    ),
                    tooltip: 'Tutup',
                  ),
                  Text(
                    'Rincian Anggaran',
                    style: GoogleFonts.interTight(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: textPrimary,
                      size: 24,
                    ),
                    color: isDark ? const Color(0xFF131A26) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showEditSheet(context, provider, budgetLimit);
                      } else if (val == 'delete' && !_isOverall) {
                        _confirmDeleteBudget(context, provider);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF55C7FF)),
                            const SizedBox(width: 10),
                            Text(
                              'Ubah Budget',
                              style: GoogleFonts.manrope(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isOverall)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                              const SizedBox(width: 10),
                              Text(
                                'Hapus Budget',
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFFEF4444),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                children: [
                  // 1. Top Summary Card (matches uploaded layout)
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Row 1: Category avatar + Name, Right: Total Limit
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Circular Category Icon Avatar with red badge
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: catObj != null
                                      ? catObj.buildIconWidget(size: 22)
                                      : Icon(
                                          _isOverall
                                              ? Icons.account_balance_wallet_rounded
                                              : Icons.label_rounded,
                                          color: const Color(0xFF55C7FF),
                                          size: 22,
                                        ),
                                ),
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: cardBg, width: 1.5),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 9,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: GoogleFonts.interTight(
                                      color: textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isOverall ? 'Anggaran Keseluruhan' : 'Anggaran Kategori',
                                    style: GoogleFonts.manrope(
                                      color: textMuted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              provider.formatCurrency(budgetLimit),
                              style: GoogleFonts.interTight(
                                color: textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(height: 1, color: borderColor),
                        const SizedBox(height: 12),
                        // Row 2: Terpakai vs Sisa
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  text: 'Terpakai : ',
                                  style: GoogleFonts.manrope(
                                    color: const Color(0xFFEF4444),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: provider.formatCurrency(totalSpent),
                                      style: GoogleFonts.interTight(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  text: 'Sisa : ',
                                  style: GoogleFonts.manrope(
                                    color: textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: provider.formatCurrency(remaining),
                                      style: GoogleFonts.interTight(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 2. Section: Statistik Penggunaan Anggaran
                  Text(
                    'Statistik Penggunaan Anggaran',
                    style: GoogleFonts.interTight(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bar Chart Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                    child: _buildUsageBarChart(
                      activeDays: activeDays,
                      dailyExpenses: dailyExpenses,
                      totalSpent: totalSpent,
                      isDark: isDark,
                      provider: provider,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Section: Riwayat Transaksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedChartDate != null
                              ? 'Transaksi ${DateFormat("dd/MM/yyyy").format(_selectedChartDate!)}'
                              : 'Riwayat Transaksi',
                          style: GoogleFonts.interTight(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_selectedChartDate != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => setState(() => _selectedChartDate = null),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Lihat Semua',
                              style: GoogleFonts.manrope(
                                color: const Color(0xFF55C7FF),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ] else if (matchingTransactions.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${matchingTransactions.length} transaksi',
                          style: GoogleFonts.manrope(
                            color: textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Transaction List or Empty State
                  if (displayedTransactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 34,
                            color: textMuted.withOpacity(0.6),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _selectedChartDate != null
                                ? 'Tidak ada transaksi pada tanggal ini'
                                : 'Belum ada transaksi di kategori ini',
                            style: GoogleFonts.manrope(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedChartDate != null
                                ? 'Pilih tanggal lain pada grafik di atas.'
                                : 'Catat pengeluaran baru untuk mulai memonitor sisa budget Anda.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              color: textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_selectedChartDate != null)
                            ElevatedButton(
                              onPressed: () => setState(() => _selectedChartDate = null),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0066FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Text(
                                'Tampilkan Semua Transaksi',
                                style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  AddTransactionScreen.route(
                                    initialType: TransactionType.expense,
                                    initialCategory: widget.categoryName,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0066FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                'Catat Transaksi',
                                style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayedTransactions.length,
                        separatorBuilder: (_, __) => Divider(
                          color: borderColor,
                          height: 1,
                          indent: 62,
                          endIndent: 14,
                        ),
                        itemBuilder: (context, index) {
                          final tx = displayedTransactions[index];
                          final itemCat = provider.getCategoryByName(tx.categoryName);

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                AddTransactionScreen.route(initialTransaction: tx),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  // Category Avatar with red up-arrow badge
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: itemCat != null
                                            ? itemCat.buildIconWidget(size: 19)
                                            : const Icon(
                                                Icons.arrow_upward_rounded,
                                                color: Color(0xFFEF4444),
                                                size: 18,
                                              ),
                                      ),
                                      Positioned(
                                        bottom: -2,
                                        right: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: cardBg, width: 1.5),
                                          ),
                                          child: const Icon(
                                            Icons.arrow_upward_rounded,
                                            size: 8,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.title.isNotEmpty ? tx.title : tx.categoryName,
                                          style: GoogleFonts.manrope(
                                            color: textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatRelativeDate(tx.timestamp),
                                          style: GoogleFonts.manrope(
                                            color: textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '-${provider.formatCurrency(tx.amount)}',
                                    style: GoogleFonts.interTight(
                                      color: textPrimary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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

  Widget _buildUsageBarChart({
    required List<DateTime> activeDays,
    required Map<DateTime, double> dailyExpenses,
    required double totalSpent,
    required bool isDark,
    required TransactionProvider provider,
  }) {
    final textMuted = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final dashedColor = isDark ? Colors.white.withOpacity(0.09) : const Color(0xFFE2E8F0);

    if (activeDays.isEmpty || totalSpent == 0) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 34,
                color: textMuted.withOpacity(0.4),
              ),
              const SizedBox(height: 8),
              Text(
                'Belum ada transaksi pengeluaran',
                style: GoogleFonts.manrope(
                  color: textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Catat transaksi untuk melihat grafik harian di sini.',
                style: GoogleFonts.manrope(color: textMuted, fontSize: 11),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    AddTransactionScreen.route(
                      initialType: TransactionType.expense,
                      initialCategory: widget.categoryName,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: Text(
                  'Catat Transaksi',
                  style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Determine scale ticks based on max single day spending
    final double maxSpent = dailyExpenses.values.fold(0.0, (m, v) => math.max(m, v));
    final double scaleMax = _calculateNiceScaleMax(maxSpent);

    // Generate 5 friendly Y-ticks
    final List<double> yTicks = [
      scaleMax,
      scaleMax * 0.8,
      scaleMax * 0.6,
      scaleMax * 0.4,
      scaleMax * 0.2,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Interactive Info Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _selectedChartDate != null && dailyExpenses.containsKey(_selectedChartDate)
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFFEF4444)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${DateFormat("dd MMMM yyyy").format(_selectedChartDate!)} : ${provider.formatCurrency(dailyExpenses[_selectedChartDate]!)}',
                                style: GoogleFonts.interTight(
                                  color: const Color(0xFFEF4444),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => setState(() => _selectedChartDate = null),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Rata-rata: ${provider.formatCurrency(totalSpent / math.max(1, activeDays.length))}/hari',
                        style: GoogleFonts.manrope(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Puncak: ${provider.formatCurrency(maxSpent)}',
                        style: GoogleFonts.interTight(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),

        // Chart with exact plot height and separate X-axis
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Y-Axis Labels
              SizedBox(
                width: 42,
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final tick in yTicks)
                            Text(
                              _formatK(tick),
                              style: GoogleFonts.manrope(
                                color: textMuted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          Text(
                            '0',
                            style: GoogleFonts.manrope(
                              color: textMuted,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20), // Height offset for X-axis labels
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Bars & Dashed Lines Plot
              Expanded(
                child: Column(
                  children: [
                    // Plot area with dashed lines and bars
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Dashed Horizontal Grid Lines
                          Positioned.fill(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                yTicks.length + 1,
                                (index) => CustomPaint(
                                  size: const Size(double.infinity, 1),
                                  painter: _DashedLinePainter(color: dashedColor),
                                ),
                              ),
                            ),
                          ),

                          // Bars Layer
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (ctx, constraints) {
                                final plotHeight = constraints.maxHeight;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: activeDays.map((day) {
                                    final spent = dailyExpenses[day] ?? 0.0;
                                    final ratio = (spent / scaleMax).clamp(0.04, 1.0);
                                    final barHeight = (plotHeight * ratio).clamp(6.0, plotHeight);
                                    final isSelected = _selectedChartDate != null &&
                                        _selectedChartDate!.year == day.year &&
                                        _selectedChartDate!.month == day.month &&
                                        _selectedChartDate!.day == day.day;

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedChartDate = isSelected ? null : day;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Container(
                                          width: 14,
                                          height: barHeight,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFFFF5252)
                                                : const Color(0xFFEF4444),
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(5),
                                              bottom: Radius.circular(2),
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFFEF4444).withOpacity(0.6),
                                                      blurRadius: 8,
                                                      spreadRadius: 1,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // X-Axis Date Labels Row
                    SizedBox(
                      height: 14,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: activeDays.map((day) {
                          final isSelected = _selectedChartDate != null &&
                              _selectedChartDate!.year == day.year &&
                              _selectedChartDate!.month == day.month &&
                              _selectedChartDate!.day == day.day;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedChartDate = isSelected ? null : day;
                              });
                            },
                            child: Text(
                              DateFormat('dd/MM').format(day),
                              style: GoogleFonts.manrope(
                                color: isSelected
                                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                    : textMuted,
                                fontSize: 9.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
