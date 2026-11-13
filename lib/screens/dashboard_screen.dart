import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/wallet_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/nested_card.dart';
import '../widgets/weekly_activity_chart.dart';
import '../widgets/spending_calendar_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/ambient_top_glow.dart';
import '../widgets/month_filter_sheet.dart';
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
                _HeroBalancePanel(provider: provider),
                if (provider.shouldShowDailyReminder) ...[
                  const SizedBox(height: 12),
                  _buildDailyReminderCard(context, provider),
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
          ],
        ),
      ],
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
}

class _HeroBalancePanel extends StatefulWidget {
  final TransactionProvider provider;

  const _HeroBalancePanel({required this.provider});

  @override
  State<_HeroBalancePanel> createState() => _HeroBalancePanelState();
}

class _HeroBalancePanelState extends State<_HeroBalancePanel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage =
        widget.provider.dashboardBalanceMode == DashboardBalanceMode.total ? 1 : 0;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void didUpdateWidget(covariant _HeroBalancePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetPage =
        widget.provider.dashboardBalanceMode == DashboardBalanceMode.total ? 1 : 0;
    if (_currentPage != targetPage) {
      _currentPage = targetPage;
      if (_pageController.hasClients && _pageController.page?.round() != targetPage) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double get _contentHeight {
    switch (widget.provider.dashboardViewMode) {
      case DashboardViewMode.complete:
        return 116.0;
      case DashboardViewMode.incomeExpense:
        return 52.0;
      case DashboardViewMode.expenseOnly:
        return 64.0;
    }
  }

  BoxDecoration _buildSapphireDecoration() {
    return BoxDecoration(
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
    );
  }

  Widget _buildVisibilityToggle(TransactionProvider provider) {
    return IconButton(
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
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final provider = widget.provider;
    final isCompleteView =
        provider.dashboardViewMode == DashboardViewMode.complete;
    final date = provider.selectedDashboardMonth;
    final monthLabel =
        '${AppMonthFilterPill.shortMonthNames[date.month - 1]} ${date.year}';
    final isMonthlyActive = _currentPage == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Month Button (e.g. "Nov 2026")
                  InkWell(
                    key: const ValueKey('hero_month_button'),
                    onTap: () {
                      if (_currentPage != 0) {
                        _pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      height: 30,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMonthlyActive ? 10 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: isMonthlyActive
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        monthLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: isMonthlyActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isMonthlyActive
                              ? const Color(0xFF0B2244)
                              : Colors.white.withOpacity(0.70),
                        ),
                      ),
                    ),
                  ),
                  if (isCompleteView) ...[
                    const SizedBox(width: 8),
                    // Total Saldo Button
                    InkWell(
                      key: const ValueKey('hero_total_saldo_button'),
                      onTap: () {
                        if (_currentPage != 1) {
                          _pageController.animateToPage(
                            1,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        height: 30,
                        padding: EdgeInsets.symmetric(
                          horizontal: !isMonthlyActive ? 10 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: !isMonthlyActive
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Total Saldo',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: !isMonthlyActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: !isMonthlyActive
                                ? const Color(0xFF0B2244)
                                : Colors.white.withOpacity(0.70),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildVisibilityToggle(provider),
        ],
      ),
    );
  }

  Widget _buildMonthlyContent(BuildContext context) {
    final provider = widget.provider;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.dashboardViewMode == DashboardViewMode.complete ||
              provider.dashboardViewMode == DashboardViewMode.expenseOnly) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.dashboardViewMode == DashboardViewMode.expenseOnly
                        ? 'Total Pengeluaran'
                        : 'Saldo saat ini',
                    style: GoogleFonts.manrope(
                      color: Colors.white.withOpacity(.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      provider.isBalanceVisible
                          ? provider.formatCurrency(
                              provider.dashboardViewMode ==
                                      DashboardViewMode.expenseOnly
                                  ? provider.dashboardMonthExpense
                                  : provider.dashboardMonthNetBalance,
                            )
                          : 'Rp ••••••••',
                      style: GoogleFonts.interTight(
                        color: Colors.white,
                        fontSize: 32,
                        height: 1.1,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Sub-Cards: only when NOT expenseOnly
          if (provider.dashboardViewMode != DashboardViewMode.expenseOnly) ...[
            if (provider.dashboardViewMode == DashboardViewMode.complete)
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
    );
  }

  Widget _buildTotalContent(BuildContext context) {
    final provider = widget.provider;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Saldo',
                  style: GoogleFonts.manrope(
                    color: Colors.white.withOpacity(.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    provider.isBalanceVisible
                        ? provider.formatCurrency(provider.totalBalance)
                        : 'Rp ••••••••',
                    style: GoogleFonts.interTight(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1.1,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildWalletsSection(context, provider),
        ],
      ),
    );
  }

  IconData _getWalletIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bank account':
        return Icons.account_balance_rounded;
      case 'cash':
        return Icons.payments_rounded;
      case 'e-wallet':
        return Icons.phone_android_rounded;
      case 'savings':
        return Icons.savings_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  Color _getWalletColor(String type) {
    switch (type.toLowerCase()) {
      case 'bank account':
        return const Color(0xFF02539A);
      case 'cash':
      case 'e-wallet':
        return const Color(0xFF00B074);
      case 'savings':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  Widget _buildWalletCard({
    required WalletModel wallet,
    required TransactionProvider provider,
    double? width,
    VoidCallback? onTap,
  }) {
    return _buildSubCard(
      isExpense: false,
      customIcon: _getWalletIcon(wallet.type),
      customIconColor: _getWalletColor(wallet.type),
      label: wallet.name,
      value: provider.isBalanceVisible
          ? provider.formatCurrency(wallet.balance)
          : 'Rp ••••••',
      width: width,
      onTap: onTap,
    );
  }

  Widget _buildWalletsSection(BuildContext context, TransactionProvider provider) {
    final wallets = provider.wallets;
    if (wallets.isEmpty) {
      return _buildSubCard(
        isExpense: false,
        customIcon: Icons.account_balance_wallet_outlined,
        customIconColor: const Color(0xFF02539A),
        label: 'Belum Ada Akun',
        value: 'Tambah Dompet',
        onTap: () {
          Navigator.push(context, WalletsScreen.route());
        },
      );
    }

    if (wallets.length <= 2) {
      return Row(
        children: [
          for (int i = 0; i < wallets.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _buildWalletCard(
                wallet: wallets[i],
                provider: provider,
                onTap: () {
                  Navigator.push(context, WalletsScreen.route());
                },
              ),
            ),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 420
            ? 180.0
            : (constraints.maxWidth - 52).clamp(120.0, 300.0) / 2;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < wallets.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                _buildWalletCard(
                  wallet: wallets[i],
                  provider: provider,
                  width: cardWidth,
                  onTap: () {
                    Navigator.push(context, WalletsScreen.route());
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        final isActive = _currentPage == index;
        return GestureDetector(
          key: ValueKey('hero_pagination_dot_$index'),
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: isActive ? 22.0 : 6.0,
              height: 4.5,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.32),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSubCard({
    required bool isExpense,
    required String label,
    required String value,
    IconData? customIcon,
    Color? customIconColor,
    VoidCallback? onTap,
    double? width,
  }) {
    final cardContent = Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF23374D).withOpacity(.55),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(.14)),
      ),
      child: Row(
        mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              customIcon ??
                  (isExpense ? Icons.remove_rounded : Icons.add_rounded),
              color: customIconColor ??
                  (isExpense
                      ? const Color(0xFFE53935)
                      : const Color(0xFF00B074)),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: cardContent,
      );
    }

    return cardContent;
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
                color: isDark
                    ? Colors.white.withOpacity(.8)
                    : const Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleteView =
        widget.provider.dashboardViewMode == DashboardViewMode.complete;
    final isExpenseOnly =
        widget.provider.dashboardViewMode == DashboardViewMode.expenseOnly;

    return Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 8),
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
          // Stationary Sapphire Hero Container
          Container(
            padding: EdgeInsets.fromLTRB(
              6,
              7,
              6,
              isExpenseOnly ? 10 : 7,
            ),
            decoration: _buildSapphireDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stationary Hero Header (Month Label & Total Saldo Switcher)
                _buildHeroHeader(context),
                SizedBox(height: isExpenseOnly ? 12 : 6),
                // Inner Content slides horizontally
                SizedBox(
                  height: _contentHeight,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      widget.provider.setDashboardBalanceMode(
                        index == 0
                            ? DashboardBalanceMode.monthly
                            : DashboardBalanceMode.total,
                      );
                    },
                    physics: isCompleteView
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    children: isCompleteView
                        ? [
                            _buildMonthlyContent(context),
                            _buildTotalContent(context),
                          ]
                        : [
                            _buildMonthlyContent(context),
                          ],
                  ),
                ),
                if (isCompleteView) ...[
                  const SizedBox(height: 7),
                  _buildPaginationDots(),
                  const SizedBox(height: 1),
                ] else if (isExpenseOnly) ...[
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Row 4: 4 Quick Actions with Dividers (Dompet, Budget, Analisis, Split Bill)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2),
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
}
