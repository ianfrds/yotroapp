import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/nested_card.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/weekly_activity_chart.dart';

enum ChartViewMode { donut, bar }

class AnalyticsScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final ScrollController? scrollController;

  const AnalyticsScreen({
    super.key,
    this.onNavigateTab,
    this.scrollController,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  ChartViewMode _chartMode = ChartViewMode.bar;
  int? _selectedCategoryIndex;
  DateTime _selectedMonth = DateTime.now();

  static const List<Color> _chartPalette = [
    Color(0xFF007AFF), // Blue
    Color(0xFF34C759), // Green
    Color(0xFFFF9500), // Orange
    Color(0xFFAF52DE), // Purple
    Color(0xFFFF3B30), // Red
    Color(0xFF55C7FF), // Sky Blue
    Color(0xFFFFC857), // Amber
    Color(0xFF8CA7C5), // Slate
  ];

  static const _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  void _showMonthPicker(BuildContext context) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalCardSheet(
      context: context,
      title: 'Pilih Periode Bulan',
      titleIcon: Icons.calendar_month_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(12, (index) {
          final monthNum = index + 1;
          final isSelected = _selectedMonth.month == monthNum;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedMonth = DateTime(now.year, monthNum, 1);
              });
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF55C7FF) : const Color(0xFF0F172A))
                    : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Text(
                _monthNames[index],
                style: GoogleFonts.manrope(
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  fontSize: 12.5,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildChartSwitch(bool isDark) {
    final isBar = _chartMode == ChartViewMode.bar;
    return GestureDetector(
      onTap: () {
        setState(() {
          _chartMode = isBar ? ChartViewMode.donut : ChartViewMode.bar;
        });
      },
      child: Container(
        width: 66,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16202D) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Sliding Sapphire/Cyan Thumb (anti-slop, no generic AI purple)
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: isBar ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF2F91E4), Color(0xFF1368B5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF334155)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0xFF1368B5).withOpacity(0.4)
                          : Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            // Icons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Center(
                    child: Icon(
                      Icons.bar_chart_rounded,
                      size: 17,
                      color: isBar ? Colors.white : (isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Center(
                    child: Icon(
                      Icons.pie_chart_rounded,
                      size: 17,
                      color: !isBar ? Colors.white : (isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();
    final isExpense = provider.analyticsTab == TransactionType.expense;
    final breakdownRaw = provider.getCategoryBreakdown();

    // Sort categories descending by amount
    final sortedBreakdown = breakdownRaw.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Category breakdown list
    final breakdownList = sortedBreakdown;

    final totalAmount =
        breakdownList.fold<double>(0.0, (sum, item) => sum + item.value);

    // Active category for highlight tooltip
    final activeIndex = (_selectedCategoryIndex ?? 0)
        .clamp(0, math.max(0, breakdownList.length - 1))
        .toInt();

    final monthLabel =
        '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C2229) : const Color(0xFFF4F5F7),
      body: SafeArea(
        child: ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          children: [
            // 1. Top App Bar (Title + Month Selector Pill)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Laporan Keuangan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.interTight(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showMonthPicker(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131A26) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          monthLabel,
                          style: GoogleFonts.manrope(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Segmented Pill Control (Pengeluaran vs Pemasukan)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0C131D) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        provider.setAnalyticsTab(TransactionType.expense);
                        setState(() => _selectedCategoryIndex = 0);
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isExpense
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Pengeluaran',
                          style: GoogleFonts.manrope(
                            color: isExpense
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B)),
                            fontSize: 13,
                            fontWeight: isExpense
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        provider.setAnalyticsTab(TransactionType.income);
                        setState(() => _selectedCategoryIndex = 0);
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: !isExpense
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Pemasukan',
                          style: GoogleFonts.manrope(
                            color: !isExpense
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B)),
                            fontSize: 13,
                            fontWeight: !isExpense
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Hero Report Card with Donut / Bar Toggle (Sejajar space-between)
            NestedCard(
              title: isExpense ? 'Aktivitas Pengeluaran' : 'Aktivitas Pemasukan',
              actionWidget: breakdownList.isNotEmpty ? _buildChartSwitch(isDark) : null,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  _chartMode == ChartViewMode.bar ? 12 : 22,
                  14,
                  _chartMode == ChartViewMode.bar ? 16 : 22,
                ),
                child: breakdownList.isEmpty
                    ? _buildEmptyChartSection(isDark, isExpense)
                    : (_chartMode == ChartViewMode.donut
                        ? _buildDonutChartSection(
                            breakdownList: breakdownList,
                            totalAmount: totalAmount,
                            activeIndex: activeIndex,
                            isExpense: isExpense,
                            provider: provider,
                            isDark: isDark,
                          )
                        : WeeklyActivityChart(
                            type: provider.analyticsTab,
                            showCard: false,
                            selectedMonth: _selectedMonth,
                            enableWeekFilter: true,
                          )),
              ),
            ),
            const SizedBox(height: 12),

            // 4. Category Breakdown Section (NestedCard Pattern)
            NestedCard(
              title: isExpense ? 'Rincian Pengeluaran' : 'Rincian Pemasukan',
              action: breakdownList.isNotEmpty
                  ? 'Total: ${provider.formatCurrency(totalAmount)}'
                  : null,
              child: breakdownList.isEmpty
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
                              'Belum ada rincian transaksi ${isExpense ? "pengeluaran" : "pemasukan"}.',
                              style: GoogleFonts.manrope(
                                color: isDark ? const Color(0xFF8CA7C5) : const Color(0xFF64748B),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: breakdownList.length,
                  separatorBuilder: (_, __) => Divider(
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                    height: 1,
                    indent: 64,
                    endIndent: 14,
                  ),
                  itemBuilder: (context, index) {
                    final item = breakdownList[index];
                    final itemColor = _chartPalette[index % _chartPalette.length];
                    final categoryModel = provider.categories.cast<CategoryModel?>().firstWhere(
                          (c) => c != null && c.name == item.key && c.type == provider.analyticsTab,
                          orElse: () => null,
                        );
                    final catPct = totalAmount > 0
                        ? (item.value / totalAmount) * 100
                        : 0.0;
                    final isSelected = index == activeIndex;

                    final txCount = provider.transactions
                        .where(
                          (t) =>
                              t.type == provider.analyticsTab &&
                              t.categoryName == item.key,
                        )
                        .length;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Row 1: Icon, Title, Share %, Amount, Tx Count
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: itemColor.withOpacity(0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: categoryModel != null
                                      ? categoryModel.buildIconWidget(size: 20)
                                      : Text(
                                          CategoryModel.fallbackEmojiFor(item.key),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.key,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.manrope(
                                          color: isSelected
                                              ? (isDark ? const Color(0xFF55C7FF) : const Color(0xFF0284C7))
                                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${catPct.toStringAsFixed(1)}% dari total',
                                        style: GoogleFonts.manrope(
                                          color: isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      provider.formatCurrency(item.value),
                                      style: GoogleFonts.interTight(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$txCount transaksi',
                                      style: GoogleFonts.manrope(
                                        color: isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B),
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Row 2: Category Share Progress Bar
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor:
                                      (catPct / 100).clamp(0.02, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: itemColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
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
        ),
      ),
    );
  }

  Widget _buildEmptyChartSection(bool isDark, bool isExpense) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pie_chart_outline_rounded,
                size: 24,
                color: isDark ? const Color(0xFF6F8197) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum Ada Transaksi',
              style: GoogleFonts.interTight(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Belum ada data ${isExpense ? 'pengeluaran' : 'pemasukan'} pada periode ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: isDark ? const Color(0xFF8CA7C5) : const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDonutAmount(double amount) {
    if (amount <= 0) return '0';
    if (amount >= 1000000000) {
      final m = amount / 1000000000;
      final isInt = (m - m.roundToDouble()).abs() < 0.05;
      final valStr =
          isInt ? m.toInt().toString() : m.toStringAsFixed(1).replaceAll('.', ',');
      return '$valStr M';
    }
    if (amount >= 1000000) {
      final jt = amount / 1000000;
      final isInt = (jt - jt.roundToDouble()).abs() < 0.05;
      final valStr =
          isInt ? jt.toInt().toString() : jt.toStringAsFixed(1).replaceAll('.', ',');
      return '$valStr jt';
    }
    if (amount >= 1000) {
      final k = amount / 1000;
      final isInt = (k - k.roundToDouble()).abs() < 0.05;
      final valStr =
          isInt ? k.toInt().toString() : k.toStringAsFixed(1).replaceAll('.', ',');
      return '${valStr}k';
    }
    return amount.toInt().toString();
  }

  Widget _buildDonutChartSection({
    required List<MapEntry<String, double>> breakdownList,
    required double totalAmount,
    required int activeIndex,
    required bool isExpense,
    required TransactionProvider provider,
    required bool isDark,
  }) {
    final values = breakdownList.map((e) => e.value).toList();
    final colors = List.generate(
      breakdownList.length,
      (i) => _chartPalette[i % _chartPalette.length],
    );

    final activeItem = breakdownList[activeIndex];
    final activePct =
        totalAmount > 0 ? (activeItem.value / totalAmount) * 100 : 0.0;

    return Center(
      child: SizedBox(
        width: 250,
        height: 250,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Donut Ring Canvas with Direct Tap Hit-Testing
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                if (values.isEmpty || totalAmount <= 0) return;
                final pos = details.localPosition;
                final dx = pos.dx - 125.0;
                final dy = pos.dy - 125.0;
                final dist = math.sqrt(dx * dx + dy * dy);

                // Check if tap is within donut ring band (radius 62..118)
                if (dist >= 62.0 && dist <= 118.0) {
                  double tapAngle = math.atan2(dy, dx);
                  // Normalize so 12 o'clock (-pi/2) is angle 0
                  tapAngle = (tapAngle + (math.pi / 2)) % (2 * math.pi);
                  if (tapAngle < 0) tapAngle += 2 * math.pi;

                  final total = values.fold<double>(0.0, (s, v) => s + v);
                  double accumulated = 0.0;
                  for (int i = 0; i < values.length; i++) {
                    final segSweep = (values[i] / total) * 2 * math.pi;
                    if (tapAngle >= accumulated &&
                        tapAngle < accumulated + segSweep) {
                      setState(() {
                        _selectedCategoryIndex = i;
                      });
                      break;
                    }
                    accumulated += segSweep;
                  }
                }
              },
              child: CustomPaint(
                size: const Size(250, 250),
                painter: _DonutChartPainter(
                  values: values,
                  colors: colors,
                  selectedIndex: activeIndex,
                ),
              ),
            ),

            // Center Info Pod (Total & Amount) with Generous Width Constraint
            IgnorePointer(
              child: SizedBox(
                width: 126,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExpense ? 'Total Pengeluaran' : 'Total Pemasukan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: isDark ? const Color(0xFF8CA7C5) : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatDonutAmount(totalAmount),
                        style: GoogleFonts.interTight(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating Percentage Badge for Active Segment
            _buildFloatingBadge(
              values: values,
              activeIndex: activeIndex,
              activePct: activePct,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBadge({
    required List<double> values,
    required int activeIndex,
    required double activePct,
    required bool isDark,
  }) {
    if (values.isEmpty) return const SizedBox.shrink();

    final total = values.fold<double>(0.0, (sum, v) => sum + v);
    if (total <= 0) return const SizedBox.shrink();

    // Compute midpoint angle of the active segment
    double currentAngle = -math.pi / 2;
    for (int i = 0; i < activeIndex; i++) {
      currentAngle += (values[i] / total) * 2 * math.pi;
    }
    final segmentSweep = (values[activeIndex] / total) * 2 * math.pi;
    final midAngle = currentAngle + (segmentSweep / 2);

    // Center of the annular band (midway between 68 and 112 radius => 90.0)
    const radius = 90.0;
    const centerOffset = 125.0;
    final badgeX = centerOffset + (radius * math.cos(midAngle));
    final badgeY = centerOffset + (radius * math.sin(midAngle));

    return Positioned(
      left: (badgeX - 18).clamp(8.0, 206.0),
      top: (badgeY - 11).clamp(8.0, 220.0),
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C131D) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.28) : const Color(0xFFCBD5E1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.55) : Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '${activePct.toStringAsFixed(0)}%',
            style: GoogleFonts.interTight(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final int? selectedIndex;

  const _DonutChartPainter({
    required this.values,
    required this.colors,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final total = values.fold<double>(0.0, (sum, v) => sum + v);

    // Sturdy, refined donut thickness matching reference proportions
    // Ro = 112, Ri = 68 (Thickness: 44px, Inner/Outer ratio: 0.607)
    const baseRo = 112.0;
    const baseRi = 68.0;
    const cornerRadius = 6.0;

    if (total <= 0) {
      // Empty placeholder ring
      final bgPaint = Paint()
        ..color = const Color(0xFF202A38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (baseRo - baseRi);
      canvas.drawCircle(center, (baseRo + baseRi) / 2, bgPaint);
      return;
    }

    final count = values.length;

    // Single segment: full annular circle
    if (count == 1) {
      final path = Path()
        ..addOval(Rect.fromCircle(center: center, radius: baseRo))
        ..addOval(Rect.fromCircle(center: center, radius: baseRi));
      path.fillType = PathFillType.evenOdd;
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[0]
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      return;
    }

    // Angular gap between wedges (approx 3.5 degrees)
    const gap = 3.5 * math.pi / 180.0;
    double currentAngle = -math.pi / 2;

    for (int i = 0; i < count; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      final isSelected = i == selectedIndex;

      // When selected, give subtle outward push and slight expansion
      final push = isSelected ? 3.5 : 0.0;
      final rO = isSelected ? (baseRo + 2.5) : baseRo;
      final rI = isSelected ? (baseRi - 1.5) : baseRi;

      final effGap = math.min(gap, sweep * 0.35);
      final startAngle = currentAngle + (effGap / 2);
      final endAngle = currentAngle + sweep - (effGap / 2);
      final span = endAngle - startAngle;

      if (span > 0.04) {
        final midAngle = (startAngle + endAngle) / 2;
        final segCenter = push > 0
            ? center +
                Offset(push * math.cos(midAngle), push * math.sin(midAngle))
            : center;

        final path = _buildAnnularWedge(
          center: segCenter,
          rO: rO,
          rI: rI,
          startAngle: startAngle,
          endAngle: endAngle,
          cornerRadius: cornerRadius,
        );

        final paint = Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        canvas.drawPath(path, paint);
      }

      currentAngle += sweep;
    }
  }

  Path _buildAnnularWedge({
    required Offset center,
    required double rO,
    required double rI,
    required double startAngle,
    required double endAngle,
    required double cornerRadius,
  }) {
    final span = endAngle - startAngle;
    final effRc = math.min(
      cornerRadius,
      math.min((rO - rI) / 3.0, (rI * span) / 3.0),
    );

    final so = math.sqrt(
      math.max(0.0, math.pow(rO - effRc, 2) - math.pow(effRc, 2)),
    );
    final si = math.sqrt(
      math.max(0.0, math.pow(rI + effRc, 2) - math.pow(effRc, 2)),
    );

    final u0 = Offset(math.cos(startAngle), math.sin(startAngle));
    final n0 = Offset(-math.sin(startAngle), math.cos(startAngle));
    final u1 = Offset(math.cos(endAngle), math.sin(endAngle));
    final n1 = Offset(math.sin(endAngle), -math.cos(endAngle));

    final Cf_os = center +
        Offset(so * u0.dx + effRc * n0.dx, so * u0.dy + effRc * n0.dy);
    final Cf_oe = center +
        Offset(so * u1.dx + effRc * n1.dx, so * u1.dy + effRc * n1.dy);
    final Cf_is = center +
        Offset(si * u0.dx + effRc * n0.dx, si * u0.dy + effRc * n0.dy);
    final Cf_ie = center +
        Offset(si * u1.dx + effRc * n1.dx, si * u1.dy + effRc * n1.dy);

    final path = Path();

    // 1. Straight line along start ray from inner to outer
    final T_ray_is = center + Offset(si * u0.dx, si * u0.dy);
    final T_ray_os = center + Offset(so * u0.dx, so * u0.dy);
    path.moveTo(T_ray_is.dx, T_ray_is.dy);
    path.lineTo(T_ray_os.dx, T_ray_os.dy);

    // 2. Fillet 1 (outer start): from start ray to outer circular arc
    final a_f1_start = math.atan2(-n0.dy, -n0.dx);
    final a_f1_end = math.atan2(Cf_os.dy - center.dy, Cf_os.dx - center.dx);
    final sw_f1 = (a_f1_end - a_f1_start) % (2 * math.pi);
    path.arcTo(
      Rect.fromCircle(center: Cf_os, radius: effRc),
      a_f1_start,
      sw_f1,
      false,
    );

    // 3. Outer circular arc from Fillet 1 to Fillet 2
    final a_f2_start_outer =
        math.atan2(Cf_oe.dy - center.dy, Cf_oe.dx - center.dx);
    final sw_outer = (a_f2_start_outer - a_f1_end) % (2 * math.pi);
    path.arcTo(
      Rect.fromCircle(center: center, radius: rO),
      a_f1_end,
      sw_outer,
      false,
    );

    // 4. Fillet 2 (outer end): from outer circular arc to end ray
    final a_f2_end = math.atan2(-n1.dy, -n1.dx);
    final sw_f2 = (a_f2_end - a_f2_start_outer) % (2 * math.pi);
    path.arcTo(
      Rect.fromCircle(center: Cf_oe, radius: effRc),
      a_f2_start_outer,
      sw_f2,
      false,
    );

    // 5. Straight line along end ray from outer to inner
    final T_ray_ie = center + Offset(si * u1.dx, si * u1.dy);
    path.lineTo(T_ray_ie.dx, T_ray_ie.dy);

    // 6. Fillet 3 (inner end): from end ray to inner circular arc
    final a_f3_start = math.atan2(-n1.dy, -n1.dx);
    final a_f3_end =
        math.atan2(-(Cf_ie.dy - center.dy), -(Cf_ie.dx - center.dx));
    final sw_f3 = (a_f3_end - a_f3_start) % (2 * math.pi);
    path.arcTo(
      Rect.fromCircle(center: Cf_ie, radius: effRc),
      a_f3_start,
      sw_f3,
      false,
    );

    // 7. Inner circular arc from Fillet 3 to Fillet 4 (runs counter-clockwise)
    final a_inner_start =
        math.atan2(Cf_ie.dy - center.dy, Cf_ie.dx - center.dx);
    final a_inner_end =
        math.atan2(Cf_is.dy - center.dy, Cf_is.dx - center.dx);
    var sw_inner = a_inner_end - a_inner_start;
    if (sw_inner > 0) sw_inner -= 2 * math.pi;
    path.arcTo(
      Rect.fromCircle(center: center, radius: rI),
      a_inner_start,
      sw_inner,
      false,
    );

    // 8. Fillet 4 (inner start): from inner circular arc to start ray
    final a_f4_start =
        math.atan2(-(Cf_is.dy - center.dy), -(Cf_is.dx - center.dx));
    final a_f4_end = math.atan2(-n0.dy, -n0.dx);
    final sw_f4 = (a_f4_end - a_f4_start) % (2 * math.pi);
    path.arcTo(
      Rect.fromCircle(center: Cf_is, radius: effRc),
      a_f4_start,
      sw_f4,
      false,
    );

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.values != values ||
        oldDelegate.colors != colors;
  }
}
