import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/thousands_separator_formatter.dart';
import '../widgets/nested_card.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/standard_screen_header.dart';
import 'budget_detail_screen.dart';

class BudgetScreen extends StatelessWidget {
  final ScrollController? scrollController;
  final bool isStandalonePage;

  const BudgetScreen({
    super.key,
    this.scrollController,
    this.isStandalonePage = false,
  });

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => const BudgetScreen(isStandalonePage: true),
    );
  }

  static const Color _cyan = Color(0xFF55C7FF);
  static const Color _accentOceanic = Color(0xFF02539A);
  static const Color _positiveGreen = Color(0xFF22C55E);
  static const Color _warningAmber = Color(0xFFF59E0B);
  static const Color _negativeRed = Color(0xFFEF4444);

  void _showAddOrEditCategoryBudgetSheet(
    BuildContext context,
    TransactionProvider provider, {
    String? initialCategory,
    double? initialLimit,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = initialCategory != null;
    final expenseCategories = provider.getCategories(TransactionType.expense);
    final availableCategories = isEditing
        ? expenseCategories
        : expenseCategories
            .where((c) => !provider.budget.categoryBudgets.containsKey(c.name))
            .toList();

    String selectedCategory = initialCategory ??
        (availableCategories.isNotEmpty ? availableCategories.first.name : '');

    final initialFormatted = initialLimit != null
        ? ThousandsSeparatorInputFormatter.formatNumber(initialLimit.round().toString())
        : '';
    final amountController = TextEditingController(text: initialFormatted);

    final inputBg = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9);
    final inputBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    showModalCardSheet(
      context: context,
      title: isEditing ? 'Ubah Budget Kategori' : 'Tambah Budget Kategori',
      titleIcon: Icons.donut_small_rounded,
      titleIconColor: _cyan,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Pilih Kategori
              Text(
                'Kategori Pengeluaran',
                style: GoogleFonts.manrope(
                  color: labelColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              if (isEditing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: inputBorder),
                  ),
                  child: Row(
                    children: [
                      Builder(builder: (_) {
                        final catObj = expenseCategories.firstWhere(
                          (c) => c.name == selectedCategory,
                          orElse: () => CategoryModel(
                            id: 'temp',
                            name: selectedCategory,
                            type: TransactionType.expense,
                            emoji: '🏷️',
                          ),
                        );
                        return catObj.buildIconWidget(size: 18);
                      }),
                      const SizedBox(width: 8),
                      Text(
                        selectedCategory,
                        style: GoogleFonts.manrope(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (availableCategories.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Semua kategori pengeluaran sudah memiliki budget.',
                    style: GoogleFonts.manrope(
                      color: labelColor,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: inputBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory.isNotEmpty ? selectedCategory : null,
                      dropdownColor: isDark ? const Color(0xFF0C131D) : Colors.white,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: textColor, size: 22),
                      style: GoogleFonts.manrope(color: textColor, fontSize: 13),
                      items: availableCategories.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.name,
                          child: Row(
                            children: [
                              c.buildIconWidget(size: 16),
                              const SizedBox(width: 8),
                              Text(c.name, style: GoogleFonts.manrope(color: textColor)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setSheetState(() => selectedCategory = v);
                        }
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // 2. Input Nominal Limit Budget
              Text(
                'Batas Nominal Budget',
                style: GoogleFonts.manrope(
                  color: labelColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: inputBorder),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Text(
                      provider.currency == 'IDR' ? 'Rp ' : '\$ ',
                      style: GoogleFonts.interTight(
                        color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF475569),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                        style: GoogleFonts.interTight(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: GoogleFonts.interTight(
                            color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFF94A3B8),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Tombol Aksi Simpan & Hapus
              Row(
                children: [
                  if (isEditing) ...[
                    InkWell(
                      onTap: () async {
                        await provider.deleteCategoryBudget(selectedCategory);
                        if (context.mounted) Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _negativeRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _negativeRed.withOpacity(0.35)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: _negativeRed,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: selectedCategory.isEmpty
                            ? null
                            : () async {
                                final cleanStr = amountController.text.replaceAll('.', '').trim();
                                final limit = double.tryParse(cleanStr) ?? 0.0;
                                if (limit <= 0) return;

                                await provider.updateCategoryBudget(selectedCategory, limit);
                                if (context.mounted) Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentOceanic,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isEditing ? 'Perbarui Budget' : 'Simpan Budget',
                          style: GoogleFonts.manrope(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditOverallBudgetSheet(BuildContext context, TransactionProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initialFormatted = ThousandsSeparatorInputFormatter.formatNumber(
      provider.budget.overallMonthlyLimit.round().toString(),
    );
    final controller = TextEditingController(text: initialFormatted);

    final inputBg = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9);
    final inputBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    showModalCardSheet(
      context: context,
      title: 'Ubah Batas Budget Keseluruhan',
      titleIcon: Icons.account_balance_wallet_outlined,
      titleIconColor: _cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Target batas pengeluaran bulanan global untuk memonitor kesehatan finansial.',
            style: GoogleFonts.manrope(
              color: labelColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: inputBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Text(
                  provider.currency == 'IDR' ? 'Rp ' : '\$ ',
                  style: GoogleFonts.interTight(
                    color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF475569),
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
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: GoogleFonts.interTight(
                        color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFF94A3B8),
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
                final val = double.tryParse(cleanStr) ?? provider.budget.overallMonthlyLimit;
                await provider.updateOverallBudget(val);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentOceanic,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();
    final totalExpense = provider.totalExpense;
    final overallLimit = provider.budget.overallMonthlyLimit;
    final budgetPct = provider.budgetUsagePercentage;

    final isOver = budgetPct >= 100;
    final isWarn = budgetPct >= 80 && !isOver;

    final categoryBudgets = provider.budget.categoryBudgets;
    final hasCategoryBudgets = categoryBudgets.isNotEmpty;
    final hasOverallBudget = overallLimit > 0;
    final hasAnyBudget = hasOverallBudget || hasCategoryBudgets;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C2229) : const Color(0xFFF4F5F7),
      body: SafeArea(
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(12, 12, 12, isStandalonePage ? 40 : 124),
          children: [
            // Standard Header with back button
            StandardScreenHeader(
              title: 'Anggaran Bulanan',
              showBackButton: isStandalonePage,
              onBack: () => Navigator.pop(context),
              actionWidget: InkWell(
                onTap: () => _showAddOrEditCategoryBudgetSheet(context, provider),
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
            const SizedBox(height: 12),

            // Empty State when NO budget is setup at all
            if (!hasAnyBudget) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131A26) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDark ? _accentOceanic.withOpacity(0.2) : const Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? _cyan.withOpacity(0.25) : const Color(0xFF0284C7).withOpacity(0.25),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 28,
                        color: isDark ? _cyan : const Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum Ada Anggaran',
                      style: GoogleFonts.interTight(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Atur batas anggaran bulanan atau per kategori untuk memantau pengeluaran Anda.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _showEditOverallBudgetSheet(context, provider),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          'Atur Anggaran Bulanan',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentOceanic,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddOrEditCategoryBudgetSheet(context, provider),
                        icon: Icon(
                          Icons.donut_small_rounded,
                          size: 16,
                          color: isDark ? _cyan : const Color(0xFF0284C7),
                        ),
                        label: Text(
                          'Tambah Budget Kategori',
                          style: GoogleFonts.manrope(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 1. Overall Monthly Budget Card (Only shown if setup)
              if (hasOverallBudget) ...[
                NestedCard(
                  title: 'Batas Budget Keseluruhan',
                  action: 'Ubah',
                  onActionTap: () => _showEditOverallBudgetSheet(context, provider),
                  actionWidget: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOver
                          ? _negativeRed.withOpacity(0.18)
                          : (isWarn ? _warningAmber.withOpacity(0.18) : _positiveGreen.withOpacity(0.18)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isOver ? '100% Terlampaui' : (isWarn ? '80% Waspada' : 'Aman'),
                      style: GoogleFonts.manrope(
                        color: isOver ? _negativeRed : (isWarn ? _warningAmber : _positiveGreen),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => BudgetDetailScreen.show(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(
                                  provider.formatCurrency(totalExpense),
                                  style: GoogleFonts.interTight(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'dari ${provider.formatCurrency(overallLimit)}',
                                  style: GoogleFonts.manrope(
                                    color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: overallLimit > 0 ? (budgetPct / 100).clamp(0.0, 1.0) : 0.0,
                              backgroundColor: isDark ? const Color(0xFF0C0E14) : const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOver ? _negativeRed : (isWarn ? _warningAmber : _positiveGreen),
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Sisa: ${provider.formatCurrency(provider.remainingBudget)}',
                                  style: GoogleFonts.manrope(
                                    color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${budgetPct.toStringAsFixed(1)}%',
                                style: GoogleFonts.manrope(
                                  color: isOver
                                      ? _negativeRed
                                      : (isWarn ? _warningAmber : (isDark ? Colors.white : const Color(0xFF0F172A))),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

            // 2. Category Budgets Section (NestedCard)
            NestedCard(
              title: 'Budget Per Kategori',
              action: '${categoryBudgets.length} Kategori',
              child: !hasCategoryBudgets
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.donut_large_rounded,
                              size: 32,
                              color: isDark ? const Color(0xFF6F8197) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Belum ada budget per kategori.',
                              style: GoogleFonts.manrope(
                                color: isDark ? const Color(0xFF8CA7C5) : const Color(0xFF64748B),
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _showAddOrEditCategoryBudgetSheet(context, provider),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  '+ Tambah Budget Kategori',
                                  style: GoogleFonts.manrope(
                                    color: isDark ? _cyan : const Color(0xFF0284C7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categoryBudgets.length,
                        separatorBuilder: (_, __) => Divider(
                          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                          height: 1,
                          indent: 14,
                          endIndent: 14,
                        ),
                        itemBuilder: (context, index) {
                          final entry = categoryBudgets.entries.elementAt(index);
                          final catName = entry.key;
                          final limit = entry.value;
                          final normCat = CategoryModel.normalizeCategoryName(catName);
                          final spent = provider.transactions
                              .where((t) => t.type == TransactionType.expense && CategoryModel.normalizeCategoryName(t.categoryName) == normCat)
                              .fold(0.0, (sum, t) => sum + t.amount);
                          final pct = limit > 0 ? (spent / limit * 100).clamp(0.0, 100.0) : 0.0;
                          final catObj = provider.getCategoryByName(catName);

                          final catOver = pct >= 100;
                          final catWarn = pct >= 80 && !catOver;

                          return InkWell(
                            onTap: () => BudgetDetailScreen.show(
                              context,
                              categoryName: catName,
                              customLimit: limit,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (catObj != null) ...[
                                        catObj.buildIconWidget(size: 18),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Text(
                                          catName,
                                          style: GoogleFonts.manrope(
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${pct.toStringAsFixed(1)}%',
                                        style: GoogleFonts.manrope(
                                          color: catOver
                                              ? _negativeRed
                                              : (catWarn ? _warningAmber : (isDark ? Colors.white : const Color(0xFF0F172A))),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _showAddOrEditCategoryBudgetSheet(
                                          context,
                                          provider,
                                          initialCategory: catName,
                                          initialLimit: limit,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.edit_rounded,
                                            color: isDark ? const Color(0xFF6F8197) : const Color(0xFF94A3B8),
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (pct / 100).clamp(0.0, 1.0),
                                      backgroundColor: isDark ? const Color(0xFF0C0E14) : const Color(0xFFE2E8F0),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        catOver ? _negativeRed : (catWarn ? _warningAmber : _positiveGreen),
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${provider.formatCurrency(spent)} terpakai',
                                          style: GoogleFonts.manrope(
                                            color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                            fontSize: 10.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'dari batas ${provider.formatCurrency(limit)}',
                                          style: GoogleFonts.manrope(
                                            color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                            fontSize: 10.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            ],
          ],
        ),
      ),
    );
  }
}
