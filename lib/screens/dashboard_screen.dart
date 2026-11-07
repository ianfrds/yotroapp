import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/nested_card.dart';
import '../widgets/weekly_activity_chart.dart';
import '../widgets/spending_calendar_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/ambient_top_glow.dart';
import 'add_transaction_screen.dart';
import 'budget_screen.dart';
import 'wallets_screen.dart';
import 'financial_analysis_screen.dart';
import 'split_bill_screen.dart';
import 'notifications_center_screen.dart';
import 'onboarding_profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;
  final ScrollController? scrollController;

  const DashboardScreen({
    super.key,
    this.onNavigateTab,
    this.scrollController,
  });

  static const _background = Color(0xFF1C2229);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final transactions = provider.transactions;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? _background : const Color(0xFFF4F5F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Ambient Sapphire Radial Glow behind Header & Balance Card
          if (isDark) const AmbientTopGlow(),
          SafeArea(
            bottom: false,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 124),
              children: [
                _buildHeader(context, provider),
                const SizedBox(height: 14),
                _buildBalancePanel(context, provider),
                if (provider.shouldShowDailyReminder) ...[
                  const SizedBox(height: 12),
                  _buildDailyReminderCard(context, provider),
                ],
                if (provider.pendingNotifications.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildPendingNotificationsCard(context, provider),
                ],
                const SizedBox(height: 12),
                NestedCard(
                  title: 'Transaksi Terbaru',
                  action: 'Lihat semua',
                  onActionTap: () => onNavigateTab?.call(1),
                  child: _buildTransactions(context, provider, transactions),
                ),
                Builder(
                  builder: (ctx) {
                    final now = DateTime.now();
                    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
                    final endOfWeek = startOfWeek.add(const Duration(days: 7));
                    final hasTxThisWeek = provider.transactions.any(
                      (t) => (t.type == TransactionType.income || t.type == TransactionType.expense) &&
                             !t.timestamp.isBefore(startOfWeek) &&
                             t.timestamp.isBefore(endOfWeek),
                    );
                    if (!hasTxThisWeek) return const SizedBox.shrink();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        WeeklyActivityChart(
                          isDualBar: true,
                          title: 'Aktivitas Transaksi',
                          onDetailTap: () => FinancialAnalysisScreen.showAsModalSheet(context),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                const SpendingCalendarCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TransactionProvider provider) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Selamat pagi'
        : hour < 15
            ? 'Selamat siang'
            : hour < 19
                ? 'Selamat sore'
                : 'Selamat malam';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.manrope(
                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      provider.userName.isNotEmpty ? provider.userName : 'Pengguna Yotro',
                      style: GoogleFonts.interTight(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('👋', style: TextStyle(fontSize: 15)),
                ],
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: isDark ? Colors.white.withOpacity(.06) : const Color(0xFFE2E8F0),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () {
                  Navigator.push(context, NotificationsCenterScreen.route());
                },
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    size: 19,
                  ),
                ),
              ),
            ),
            if (provider.pendingNotificationsCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalancePanel(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C131D).withOpacity(0.92) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF034A8C).withOpacity(0.18),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Inner Sapphire Radial Gradient Card ("Card inside Card")
          Container(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment(0.0, 1.0),
                radius: 1.08,
                colors: [
                  Color(0xFF041735),
                  Color(0xFF001732),
                  Color(0xFF00498C),
                ],
                stops: [0.0, 0.3606, 1.0],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Period Pill & Visibility Eye Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMonthFilterPill(context, provider),
                      IconButton(
                        tooltip: provider.isBalanceVisible
                            ? 'Sembunyikan nominal'
                            : 'Tampilkan nominal',
                        onPressed: provider.toggleBalanceVisibility,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        icon: Icon(
                          provider.isBalanceVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                if (provider.dashboardViewMode == DashboardViewMode.complete ||
                    provider.dashboardViewMode == DashboardViewMode.expenseOnly) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.dashboardViewMode == DashboardViewMode.expenseOnly
                              ? 'Total Pengeluaran'
                              : 'Saldo saat ini',
                          style: GoogleFonts.manrope(
                            color: Colors.white.withOpacity(.85),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            provider.isBalanceVisible
                                ? provider.formatCurrency(
                                    provider.dashboardViewMode == DashboardViewMode.expenseOnly
                                        ? provider.dashboardMonthExpense
                                        : provider.totalBalance,
                                  )
                                : 'Rp ••••••••',
                            style: GoogleFonts.interTight(
                              color: Colors.white,
                              fontSize: 34,
                              height: 1.1,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                        if (provider.dashboardViewMode == DashboardViewMode.expenseOnly)
                          const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ],
                // Sub-Cards: only when NOT expenseOnly
                if (provider.dashboardViewMode != DashboardViewMode.expenseOnly) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSubCard(
                          isExpense: true,
                          label: 'Pengeluaran',
                          value: provider.isBalanceVisible
                              ? provider.formatCurrency(provider.dashboardMonthExpense)
                              : 'Rp ••••••',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildSubCard(
                          isExpense: false,
                          label: 'Pemasukan',
                          value: provider.isBalanceVisible
                              ? provider.formatCurrency(provider.dashboardMonthIncome)
                              : 'Rp ••••••',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Row 4: 4 Quick Actions with Dividers (Dompet, Budget, Analisis, Split Bill)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickActionItem(
                    context: context,
                    svgAsset: 'assets/icon/Dompet.svg',
                    label: 'Dompet',
                    onTap: () {
                      Navigator.push(context, WalletsScreen.route());
                    },
                  ),
                ),
                _buildActionDivider(context),
                Expanded(
                  child: _buildQuickActionItem(
                    context: context,
                    svgAsset: 'assets/icon/Budget.svg',
                    label: 'Budget',
                    onTap: () {
                      Navigator.push(context, BudgetScreen.route());
                    },
                  ),
                ),
                _buildActionDivider(context),
                Expanded(
                  child: _buildQuickActionItem(
                    context: context,
                    svgAsset: 'assets/icon/Analisis.svg',
                    label: 'Analisis',
                    onTap: () {
                      FinancialAnalysisScreen.showAsModalSheet(context);
                    },
                  ),
                ),
                _buildActionDivider(context),
                Expanded(
                  child: _buildQuickActionItem(
                    context: context,
                    svgAsset: 'assets/icon/Split Bill.svg',
                    label: 'Split Bill',
                    onTap: () {
                      Navigator.push(context, SplitBillScreen.route());
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthFilterPill(BuildContext context, TransactionProvider provider) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final selectedDate = provider.selectedDashboardMonth;
    final label = '${monthNames[selectedDate.month - 1]} ${selectedDate.year}';

    return InkWell(
      onTap: () => _showMonthFilterSheet(context, provider),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 12, right: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthFilterSheet(BuildContext context, TransactionProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int tempYear = provider.selectedDashboardMonth.year;
    int tempMonth = provider.selectedDashboardMonth.month;

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr',
      'Mei', 'Jun', 'Jul', 'Agu',
      'Sep', 'Okt', 'Nov', 'Des',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return SafeArea(
              top: false,
              bottom: false,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetCtx).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0C131D) : const Color(0xFFF4F5F7),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.55 : 0.15),
                      blurRadius: 28,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    // Handle Pill
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Header Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Filter Bulanan',
                        style: GoogleFonts.interTight(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Inner Month Grid Card (Matches Image 2)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131A26) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Year selector row (Centered with chevron left & chevron right, year is clickable)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () => setSheetState(() => tempYear--),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.chevron_left_rounded,
                                    color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () async {
                                  final pickedYear = await showDialog<int>(
                                    context: ctx,
                                    builder: (dlgCtx) {
                                      return AlertDialog(
                                        backgroundColor: isDark ? const Color(0xFF131A26) : Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: Text(
                                          'Pilih Tahun',
                                          style: GoogleFonts.interTight(
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        content: SizedBox(
                                          width: 280,
                                          height: 280,
                                          child: Theme(
                                            data: Theme.of(dlgCtx).copyWith(
                                              colorScheme: isDark
                                                  ? const ColorScheme.dark(
                                                      primary: Color(0xFF2563EB),
                                                      onPrimary: Colors.white,
                                                      surface: Color(0xFF131A26),
                                                      onSurface: Colors.white,
                                                    )
                                                  : const ColorScheme.light(
                                                      primary: Color(0xFF02539A),
                                                      onPrimary: Colors.white,
                                                      surface: Colors.white,
                                                      onSurface: Color(0xFF0F172A),
                                                    ),
                                            ),
                                            child: YearPicker(
                                              firstDate: DateTime(2020),
                                              lastDate: DateTime(2035),
                                              selectedDate: DateTime(tempYear, 1),
                                              onChanged: (DateTime dateTime) {
                                                Navigator.pop(dlgCtx, dateTime.year);
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                  if (pickedYear != null) {
                                    setSheetState(() => tempYear = pickedYear);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$tempYear',
                                        style: GoogleFonts.interTight(
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.arrow_drop_down_rounded,
                                        color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () => setSheetState(() => tempYear++),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 12 Months: 3 rows of 4 columns
                          for (int r = 0; r < 3; r++) ...[
                            Row(
                              children: [
                                for (int c = 0; c < 4; c++) ...[
                                  Expanded(
                                    child: Builder(
                                      builder: (_) {
                                        final mIndex = r * 4 + c;
                                        final monthNum = mIndex + 1;
                                        final isSelected = tempMonth == monthNum;

                                        return InkWell(
                                          onTap: () {
                                            setSheetState(() => tempMonth = monthNum);
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: Container(
                                            height: 42,
                                            alignment: Alignment.center,
                                            decoration: isSelected
                                                ? BoxDecoration(
                                                    color: const Color(0xFF2563EB),
                                                    borderRadius: BorderRadius.circular(20),
                                                  )
                                                : null,
                                            child: Text(
                                              months[mIndex],
                                              style: GoogleFonts.manrope(
                                                color: isSelected
                                                    ? Colors.white
                                                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                                fontSize: 14,
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (c < 3) const SizedBox(width: 8),
                                ],
                              ],
                            ),
                            if (r < 2) const SizedBox(height: 16),
                          ],
                          const SizedBox(height: 16),

                          // Centered "Bulan Ini" Button (Harmonious & balanced below month grid)
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final now = DateTime.now();
                                setSheetState(() {
                                  tempYear = now.year;
                                  tempMonth = now.month;
                                });
                              },
                              icon: Icon(
                                Icons.restore_rounded,
                                size: 15,
                                color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
                              ),
                              label: Text(
                                'Bulan Ini',
                                style: GoogleFonts.manrope(
                                  color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                side: BorderSide(
                                  color: isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bottom Action Buttons (Full width: Batal on left, Simpan on right)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetCtx),
                              style: OutlinedButton.styleFrom(
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                  color: isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Text(
                                'Batal',
                                style: GoogleFonts.manrope(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                provider.setSelectedDashboardMonth(DateTime(tempYear, tempMonth, 1));
                                Navigator.pop(sheetCtx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF02539A),
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                              child: Text(
                                'Simpan',
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
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
          },
        );
      },
    );
  }

  Widget _buildSubCard({
    required bool isExpense,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF23374D).withOpacity(.55),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isExpense ? Icons.remove_rounded : Icons.add_rounded,
              color: isExpense ? const Color(0xFFE53935) : const Color(0xFF00B074),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    color: Colors.white.withOpacity(.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.interTight(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 36,
      color: isDark ? Colors.white.withOpacity(.08) : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildQuickActionItem({
    required BuildContext context,
    String? svgAsset,
    IconData? icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(
                svgAsset,
                width: 36,
                height: 36,
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white : const Color(0xFF0F172A),
                  BlendMode.srcIn,
                ),
              )
            else if (icon != null)
              Icon(
                icon,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                size: 36,
              ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: isDark ? Colors.white.withOpacity(.8) : const Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactions(
    BuildContext context,
    TransactionProvider provider,
    List<TransactionModel> transactions,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: isDark ? const Color(0xFF6F8197) : const Color(0xFF94A3B8),
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada transaksi',
              style: GoogleFonts.manrope(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: math.min(3, transactions.length),
        separatorBuilder: (_, __) => Divider(
          color: isDark ? Colors.white.withOpacity(.06) : const Color(0xFFE2E8F0),
          height: 1,
          indent: 68,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return TransactionTile(
            transaction: transaction,
            onTap: () => Navigator.push(
              context,
              AddTransactionScreen.route(initialTransaction: transaction),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyReminderCard(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NestedCard(
      title: 'Pengingat Transaksi Harian',
      innerPadding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE58B29).withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.alarm_rounded,
              color: Color(0xFFE58B29),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belum ada transaksi hari ini',
                  style: GoogleFonts.interTight(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Catat pengeluaran atau pemasukan untuk menjaga keuangan tetap rapi.',
                  style: GoogleFonts.manrope(
                    color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF02539A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.push(context, AddTransactionScreen.route());
            },
            child: Text(
              'Catat',
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingNotificationsCard(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final pending = provider.pendingNotifications;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NestedCard(
      title: 'Persetujuan Notifikasi',
      action: '${pending.length} Menunggu',
      innerPadding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF55C7FF).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF55C7FF),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transaksi otomatis terdeteksi dari notifikasi perangkat. Setujui untuk membukukan pengeluaran ke saldo.',
                  style: GoogleFonts.manrope(
                    color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pending.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = pending[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1522) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF02539A).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF55C7FF).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            item.sourceApp,
                            style: GoogleFonts.interTight(
                              color: const Color(0xFF55C7FF),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.interTight(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          provider.formatCurrency(item.amount),
                          style: GoogleFonts.interTight(
                            color: const Color(0xFFFF6B7A),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        item.rawMessage,
                        style: GoogleFonts.manrope(
                          color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                          fontSize: 11,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        InkWell(
                          onTap: () => provider.rejectNotification(item.id),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              'Abaikan',
                              style: GoogleFonts.manrope(
                                color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            await provider.approveNotification(item.id);
                            if (context.mounted) {
                              AppSnackBar.show(
                                context,
                                'Transaksi ${provider.formatCurrency(item.amount)} disetujui & dicatat ke saldo!',
                                type: SnackBarType.success,
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF02539A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Setujui & Catat',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
