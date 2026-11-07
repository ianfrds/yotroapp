import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/nested_card.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/month_filter_sheet.dart';
import '../widgets/standard_screen_header.dart';
import '../widgets/donut_chart_painter.dart';
import 'budget_screen.dart';

class FinancialHealthMetrics {
  final int score;
  final String status;
  final Color statusColor;
  final double monthIncome;
  final double monthExpense;
  final double netCashFlow;
  final double savingsRate;
  final double expenseRatio;
  final String topCategoryName;
  final double topCategoryAmount;
  final double topCategoryPct;
  final int txCount;
  final String diagnosis;
  final double monthlyBudgetLimit;
  final double budgetUsagePct;
  final double dailySafeSpend;

  const FinancialHealthMetrics({
    required this.score,
    required this.status,
    required this.statusColor,
    required this.monthIncome,
    required this.monthExpense,
    required this.netCashFlow,
    required this.savingsRate,
    required this.expenseRatio,
    required this.topCategoryName,
    required this.topCategoryAmount,
    required this.topCategoryPct,
    required this.txCount,
    required this.diagnosis,
    required this.monthlyBudgetLimit,
    required this.budgetUsagePct,
    required this.dailySafeSpend,
  });
}

class FinancialAnalysisScreen extends StatefulWidget {
  final bool isSheet;

  const FinancialAnalysisScreen({super.key, this.isSheet = false});

  static MaterialPageRoute route() {
    return MaterialPageRoute(
      builder: (_) => const FinancialAnalysisScreen(),
    );
  }

  static Future<void> showAsModalSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FinancialAnalysisScreen(isSheet: true),
    );
  }

  @override
  State<FinancialAnalysisScreen> createState() => _FinancialAnalysisScreenState();
}

class _FinancialAnalysisScreenState extends State<FinancialAnalysisScreen> {
  DateTime _selectedMonth = DateTime.now();
  int? _selectedCurvePoint;
  int? _selectedDonutIndex;

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

  void _showHelpGuideSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalCardSheet(
      context: context,
      title: 'Panduan Membaca Analisis',
      titleIcon: Icons.lightbulb_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHelpGuideItem(
            icon: Icons.insights_rounded,
            iconColor: const Color(0xFF55C7FF),
            title: 'Skor Keuangan (0 - 100)',
            description:
                'Menilai seberapa sehat dompet Anda dari perbandingan uang masuk, belanja, dan sisa simpanan. Skor 65 ke atas menandakan kondisi keuangan aman dan stabil.',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildHelpGuideItem(
            icon: Icons.savings_outlined,
            iconColor: const Color(0xFF39D98A),
            title: 'Tabungan (Uang Tersimpan)',
            description:
                'Persentase sisa uang yang berhasil Anda simpan dari total uang masuk bulan ini. Rekomendasi umum yang baik adalah minimal menyisihkan 20% pemasukan.',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildHelpGuideItem(
            icon: Icons.shopping_bag_outlined,
            iconColor: const Color(0xFFFFC857),
            title: 'Rasio Beban (Porsi Belanja)',
            description:
                'Berapa persen pemasukan Anda yang terpakai untuk berbelanja. Usahakan di bawah 70% agar Anda memiliki ruang aman untuk tabungan dan dana darurat.',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildHelpGuideItem(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFF2563EB),
            title: 'Arus Kas (Sisa Uang Bersih)',
            description:
                'Selisih riil antara uang masuk dan belanja. Plus (Surplus) berarti ada sisa lebih yang bisa ditabung, minus (Defisit) berarti belanja lebih besar dari pemasukan.',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildHelpGuideItem(
            icon: Icons.show_chart_rounded,
            iconColor: const Color(0xFF38BDF8),
            title: 'Kurva Alur & Donut Arus Kas',
            description:
                'Diagram kurva menunjukkan alur akumulasi uang masuk vs pengeluaran sepanjang bulan, sedangkan donut chart memperlihatkan proporsi perbandingan keduanya.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpGuideItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  FinancialHealthMetrics _computeHealthMetrics(
    TransactionProvider provider,
    DateTime selectedMonth,
  ) {
    final monthTxs = provider.transactions.where((t) {
      return t.timestamp.year == selectedMonth.year &&
          t.timestamp.month == selectedMonth.month;
    }).toList();

    double income = 0.0;
    double expense = 0.0;
    final categoryTotals = <String, double>{};

    for (final tx in monthTxs) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        expense += tx.amount;
        categoryTotals[tx.categoryName] =
            (categoryTotals[tx.categoryName] ?? 0.0) + tx.amount;
      }
    }

    final hasData = monthTxs.isNotEmpty;
    if (!hasData) {
      return const FinancialHealthMetrics(
        score: 0,
        status: 'Belum Ada Data',
        statusColor: Color(0xFF8CA7C5),
        monthIncome: 0.0,
        monthExpense: 0.0,
        netCashFlow: 0.0,
        savingsRate: 0.0,
        expenseRatio: 0.0,
        topCategoryName: '-',
        topCategoryAmount: 0.0,
        topCategoryPct: 0.0,
        txCount: 0,
        diagnosis: 'Belum ada transaksi tercatat pada periode ini.',
        monthlyBudgetLimit: 0.0,
        budgetUsagePct: 0.0,
        dailySafeSpend: 0.0,
      );
    }

    final netCashFlow = income - expense;
    final savingsRate = income > 0 ? (netCashFlow / income) : 0.0;
    final expenseRatio = income > 0 ? (expense / income) : (expense > 0 ? 1.0 : 0.0);

    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final daysPassed = isCurrentMonth ? math.max(1, now.day) : daysInMonth;
    final remainingDays = math.max(1, daysInMonth - daysPassed);

    String topCat = 'Lainnya';
    double topCatAmount = 0.0;
    double topCatPct = 0.0;
    if (categoryTotals.isNotEmpty) {
      final sortedCats = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCat = sortedCats.first.key;
      topCatAmount = sortedCats.first.value;
      topCatPct = expense > 0 ? (topCatAmount / expense) : 0.0;
    }

    final monthlyBudget = provider.budget.overallMonthlyLimit;
    double budgetUsagePct = 0.0;
    double dailySafeSpend = 0.0;
    if (monthlyBudget > 0) {
      budgetUsagePct = expense / monthlyBudget;
      final remainingBudget = math.max(0.0, monthlyBudget - expense);
      dailySafeSpend = remainingDays > 0 ? (remainingBudget / remainingDays) : 0.0;
    }

    int score = 70;
    if (income > 0 || expense > 0) {
      double savingsScore;
      if (savingsRate >= 0.40) {
        savingsScore = 45.0;
      } else if (savingsRate >= 0.20) {
        savingsScore = 35.0 + ((savingsRate - 0.20) / 0.20) * 10.0;
      } else if (savingsRate >= 0.10) {
        savingsScore = 25.0 + ((savingsRate - 0.10) / 0.10) * 10.0;
      } else if (savingsRate >= 0.0) {
        savingsScore = 15.0 + (savingsRate / 0.10) * 10.0;
      } else {
        savingsScore = math.max(0.0, 15.0 + savingsRate * 30.0);
      }

      double budgetScore = 30.0;
      if (monthlyBudget > 0) {
        if (budgetUsagePct <= 0.70) {
          budgetScore = 35.0;
        } else if (budgetUsagePct <= 0.85) {
          budgetScore = 26.0;
        } else if (budgetUsagePct <= 1.0) {
          budgetScore = 16.0;
        } else {
          budgetScore = math.max(0.0, 16.0 - (budgetUsagePct - 1.0) * 35.0);
        }
      }

      double concentrationScore;
      if (topCatPct > 0.65) {
        concentrationScore = 8.0;
      } else if (topCatPct > 0.45) {
        concentrationScore = 14.0;
      } else {
        concentrationScore = 20.0;
      }

      score = (savingsScore + budgetScore + concentrationScore).round().clamp(0, 100);
    }

    String status;
    Color statusColor;
    if (score >= 80) {
      status = 'Sangat Baik';
      statusColor = const Color(0xFF39D98A);
    } else if (score >= 65) {
      status = 'Aman & Stabil';
      statusColor = const Color(0xFF55C7FF);
    } else if (score >= 50) {
      status = 'Perlu Waspada';
      statusColor = const Color(0xFFFFC857);
    } else {
      status = 'Defisit / Boros';
      statusColor = const Color(0xFFFF6B7A);
    }

    String diagnosis;
    if (income == 0 && expense == 0) {
      diagnosis = 'Belum ada transaksi tercatat pada bulan ini.';
    } else if (income == 0 && expense > 0) {
      diagnosis =
          'Belum ada uang masuk yang dicatat bulan ini. Total belanja saat ini ${provider.formatCurrency(expense)}, dengan pengeluaran terbesar di kategori $topCat.';
    } else if (netCashFlow < 0) {
      final deficitStr = provider.formatCurrency(expense - income);
      diagnosis =
          'Pengeluaran bulan ini melebihi uang masuk sebesar $deficitStr. Kategori $topCat menyerap ${(topCatPct * 100).round()}% dari seluruh belanja Anda. Coba batasi belanja non-pokok agar dompet kembali seimbang.';
    } else if (savingsRate >= 0.40) {
      final surplusStr = provider.formatCurrency(netCashFlow);
      diagnosis =
          'Bagus sekali! Anda berhasil menyisihkan $surplusStr (${(savingsRate * 100).round()}% dari uang masuk). Alokasi dana sangat efisien, tabungan Anda bertambah aman.';
    } else if (savingsRate >= 0.20) {
      final surplusStr = provider.formatCurrency(netCashFlow);
      diagnosis =
          'Kondisi keuangan bulan ini sehat dengan sisa uang $surplusStr (${(savingsRate * 100).round()}% tersimpan). Porsi simpanan Anda sudah memenuhi target ideal finansial.';
    } else {
      final surplusStr = provider.formatCurrency(netCashFlow);
      diagnosis =
          'Uang masuk dan belanja hampir sama rata (tersisa $surplusStr atau ${(savingsRate * 100).round()}%). Sebaiknya perhatikan belanja kategori $topCat agar sisa tabungan dapat meningkat.';
    }

    return FinancialHealthMetrics(
      score: score,
      status: status,
      statusColor: statusColor,
      monthIncome: income,
      monthExpense: expense,
      netCashFlow: netCashFlow,
      savingsRate: savingsRate,
      expenseRatio: expenseRatio,
      topCategoryName: topCat,
      topCategoryAmount: topCatAmount,
      topCategoryPct: topCatPct,
      txCount: monthTxs.length,
      diagnosis: diagnosis,
      monthlyBudgetLimit: monthlyBudget,
      budgetUsagePct: budgetUsagePct,
      dailySafeSpend: dailySafeSpend,
    );
  }

  static String _formatCompactAmount(double amount) {
    final absAmount = amount.abs();
    if (absAmount >= 1000000000) {
      final b = absAmount / 1000000000;
      return '${b.toStringAsFixed(1).replaceAll('.0', '')}M';
    }
    if (absAmount >= 1000000) {
      final m = absAmount / 1000000;
      return '${m.toStringAsFixed(1).replaceAll('.0', '')}jt';
    }
    if (absAmount >= 1000) {
      final k = absAmount / 1000;
      return '${k.toStringAsFixed(0)}k';
    }
    return absAmount.round().toString();
  }

  // 1. Half Circular Financial Health Card
  Widget _buildFinancialHealthCard(
    TransactionProvider provider,
    FinancialHealthMetrics metrics,
    bool isDark,
  ) {
    return NestedCard(
      title: 'Kesehatan Keuangan',
      actionWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: metrics.statusColor.withOpacity(0.16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: metrics.statusColor.withOpacity(0.35)),
        ),
        child: Text(
          metrics.status,
          style: GoogleFonts.manrope(
            color: metrics.statusColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 4),
            // Half Circular Chart with Score in the center
            SizedBox(
              width: 250,
              height: 136,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  CustomPaint(
                    size: const Size(250, 136),
                    painter: _HalfCircularHealthPainter(
                      score: metrics.score,
                      statusColor: metrics.statusColor,
                      trackColor: isDark
                          ? const Color(0xFF232D3B)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${metrics.score}',
                                style: GoogleFonts.interTight(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 38,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              TextSpan(
                                text: ' / 100',
                                style: GoogleFonts.manrope(
                                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: metrics.statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: metrics.statusColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            metrics.status,
                            style: GoogleFonts.manrope(
                              color: metrics.statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4-Zone Context Row: Kurang (<50), Waspada (50-64), Aman (65-79), Sangat Baik (80-100)
            _buildZoneContextRow(metrics.score, isDark),
            const SizedBox(height: 14),
            Divider(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 12),

            // 3 Mini Metric Pods: Tabungan, Rasio Beban, Arus Kas
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetricPod(
                    icon: Icons.savings_outlined,
                    label: 'Tabungan',
                    value: '${metrics.savingsRate >= 0 ? '+' : ''}${(metrics.savingsRate * 100).round()}%',
                    sublabel: 'Target >20%',
                    valueColor: metrics.savingsRate >= 0.20 ? const Color(0xFF39D98A) : const Color(0xFFFFC857),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildHealthMetricPod(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Rasio Beban',
                    value: '${(metrics.expenseRatio * 100).round()}%',
                    sublabel: 'Aman <70%',
                    valueColor: metrics.expenseRatio <= 0.70 ? (isDark ? Colors.white : const Color(0xFF0F172A)) : const Color(0xFFFF6B7A),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildHealthMetricPod(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Arus Kas',
                    value: '${metrics.netCashFlow >= 0 ? '+' : '-'}${_formatCompactAmount(metrics.netCashFlow)}',
                    sublabel: metrics.netCashFlow >= 0 ? 'Surplus' : 'Defisit',
                    valueColor: metrics.netCashFlow >= 0 ? const Color(0xFF39D98A) : const Color(0xFFFF6B7A),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Smart Diagnostic Insight Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: Color(0xFF55C7FF),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan & Saran Keuangan',
                          style: GoogleFonts.manrope(
                            color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          metrics.diagnosis,
                          style: GoogleFonts.manrope(
                            color: isDark ? Colors.white.withOpacity(0.88) : const Color(0xFF334155),
                            fontSize: 11.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildZoneContextRow(int score, bool isDark) {
    final zones = [
      _HealthZoneData('Kurang', '<50', const Color(0xFFFF6B7A), score < 50),
      _HealthZoneData('Waspada', '50-64', const Color(0xFFFFC857), score >= 50 && score < 65),
      _HealthZoneData('Aman', '65-79', const Color(0xFF55C7FF), score >= 65 && score < 80),
      _HealthZoneData('Sangat Baik', '80-100', const Color(0xFF39D98A), score >= 80),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: zones.map((zone) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
              decoration: BoxDecoration(
                color: zone.isActive
                    ? zone.color.withOpacity(isDark ? 0.16 : 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: zone.isActive
                      ? zone.color.withOpacity(0.45)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 5.5,
                        height: 5.5,
                        decoration: BoxDecoration(
                          color: zone.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          zone.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            color: zone.isActive
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8)),
                            fontSize: 10,
                            fontWeight: zone.isActive ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    zone.range,
                    style: GoogleFonts.manrope(
                      color: zone.isActive
                          ? zone.color
                          : (isDark ? const Color(0xFF4B5D73) : const Color(0xFF94A3B8)),
                      fontSize: 8.5,
                      fontWeight: zone.isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHealthMetricPod({
    required IconData icon,
    required String label,
    required String value,
    required String sublabel,
    required Color valueColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.interTight(
                color: valueColor,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            maxLines: 2,
            style: GoogleFonts.manrope(
              color: isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8),
              fontSize: 9.5,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Diagram Kurva Alur Pengeluaran & Pemasukan (Cash Flow Curve Chart)
  Widget _buildCashFlowCurveCard(
    TransactionProvider provider,
    FinancialHealthMetrics metrics,
    bool isDark,
  ) {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final checkpoints = <int>[
      1,
      math.min(7, daysInMonth),
      math.min(14, daysInMonth),
      math.min(21, daysInMonth),
      math.min(28, daysInMonth),
      daysInMonth,
    ].toSet().toList()..sort();

    final monthTxs = provider.transactions.where((t) {
      return t.timestamp.year == _selectedMonth.year &&
          t.timestamp.month == _selectedMonth.month;
    }).toList();

    final incomePoints = <double>[];
    final expensePoints = <double>[];

    for (final day in checkpoints) {
      double cumIncome = 0.0;
      double cumExpense = 0.0;
      for (final tx in monthTxs) {
        if (tx.timestamp.day <= day) {
          if (tx.type == TransactionType.income) {
            cumIncome += tx.amount;
          } else if (tx.type == TransactionType.expense) {
            cumExpense += tx.amount;
          }
        }
      }
      incomePoints.add(cumIncome);
      expensePoints.add(cumExpense);
    }

    final selectedIdx = _selectedCurvePoint;
    final selectedDay = (selectedIdx != null && selectedIdx >= 0 && selectedIdx < checkpoints.length)
        ? checkpoints[selectedIdx]
        : null;
    final selectedIncome = (selectedIdx != null && selectedIdx >= 0 && selectedIdx < incomePoints.length)
        ? incomePoints[selectedIdx]
        : null;
    final selectedExpense = (selectedIdx != null && selectedIdx >= 0 && selectedIdx < expensePoints.length)
        ? expensePoints[selectedIdx]
        : null;

    return NestedCard(
      title: 'Alur Pemasukan & Pengeluaran',
      action: '${metrics.txCount} Transaksi',
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Legend Row
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF39D98A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Pemasukan: ${_formatCompactAmount(metrics.monthIncome)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF55C7FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Pengeluaran: ${_formatCompactAmount(metrics.monthExpense)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.manrope(
                            color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Active Checkpoint Info Badge when tapped
            if (selectedDay != null && selectedIncome != null && selectedExpense != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Posisi Tgl $selectedDay',
                      style: GoogleFonts.manrope(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Masuk: ${_formatCompactAmount(selectedIncome)}  |  Keluar: ${_formatCompactAmount(selectedExpense)}',
                      style: GoogleFonts.interTight(
                        color: const Color(0xFF55C7FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Curve Chart CustomPaint with Gesture Listener
            SizedBox(
              height: 160,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapUp: (details) {
                      final boxWidth = constraints.maxWidth;
                      final tapX = details.localPosition.dx;
                      final count = checkpoints.length;
                      if (count > 0 && boxWidth > 0) {
                        final step = boxWidth / (count - 1);
                        final nearestIdx = (tapX / step).round().clamp(0, count - 1);
                        setState(() {
                          _selectedCurvePoint = _selectedCurvePoint == nearestIdx ? null : nearestIdx;
                        });
                      }
                    },
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, 160),
                      painter: _CashFlowCurvePainter(
                        incomePoints: incomePoints,
                        expensePoints: expensePoints,
                        selectedIndex: _selectedCurvePoint,
                        isDark: isDark,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Checkpoints Label Row (Tgl 1, 7, 14, ...)
            Row(
              children: List.generate(checkpoints.length, (idx) {
                final day = checkpoints[idx];
                final isSelected = _selectedCurvePoint == idx;
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCurvePoint = isSelected ? null : idx;
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? const Color(0xFF55C7FF).withOpacity(0.18)
                                : const Color(0xFF0F172A).withOpacity(0.1))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Tgl $day',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: isSelected
                              ? (isDark ? const Color(0xFF55C7FF) : const Color(0xFF0F172A))
                              : (isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8)),
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Donut Chart Pemasukan vs Pengeluaran Card (Matching Laporan Keuangan Style)
  Widget _buildCashFlowDonutCard(
    TransactionProvider provider,
    FinancialHealthMetrics metrics,
    bool isDark,
  ) {
    final income = metrics.monthIncome;
    final expense = metrics.monthExpense;
    final totalFlow = income + expense;

    final incomeShare = totalFlow > 0 ? (income / totalFlow) : 0.5;
    final expenseShare = totalFlow > 0 ? (expense / totalFlow) : 0.5;

    final values = totalFlow > 0 ? [income, expense] : <double>[];
    final colors = [const Color(0xFF39D98A), const Color(0xFF55C7FF)];

    return NestedCard(
      title: 'Pemasukan vs Pengeluaran',
      action: 'Rasio Arus Kas',
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Center Donut Chart with Annular Rounded Wedge Painter
            Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTapUp: (details) {
                        final center = const Offset(120, 120);
                        final dx = details.localPosition.dx - center.dx;
                        final dy = details.localPosition.dy - center.dy;
                        final dist = math.sqrt(dx * dx + dy * dy);
                        if (dist >= 50 && dist <= 125) {
                          // Angle in radians (-pi to pi)
                          final angle = math.atan2(dy, dx);
                          // Slices start at -pi/2
                          var normAngle = angle + math.pi / 2;
                          if (normAngle < 0) normAngle += 2 * math.pi;
                          final incomeSweep = incomeShare * 2 * math.pi;
                          setState(() {
                            if (normAngle <= incomeSweep) {
                              _selectedDonutIndex = _selectedDonutIndex == 0 ? null : 0;
                            } else {
                              _selectedDonutIndex = _selectedDonutIndex == 1 ? null : 1;
                            }
                          });
                        }
                      },
                      child: CustomPaint(
                        size: const Size(240, 240),
                        painter: DonutChartPainter(
                          values: values,
                          colors: colors,
                          selectedIndex: _selectedDonutIndex,
                          baseRo: 106.0,
                          baseRi: 64.0,
                          emptyTrackColor: isDark
                              ? const Color(0xFF202A38)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    // Center Info: Arus Kas Bersih (Surplus / Defisit)
                    IgnorePointer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedDonutIndex == 0
                                ? 'Total Masuk'
                                : (_selectedDonutIndex == 1 ? 'Total Keluar' : 'Arus Kas Bersih'),
                            style: GoogleFonts.manrope(
                              color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _selectedDonutIndex == 0
                                ? provider.formatCurrency(income)
                                : (_selectedDonutIndex == 1
                                    ? provider.formatCurrency(expense)
                                    : '${metrics.netCashFlow >= 0 ? '+' : '-'}${_formatCompactAmount(metrics.netCashFlow)}'),
                            style: GoogleFonts.interTight(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: (_selectedDonutIndex == 0 || (_selectedDonutIndex == null && metrics.netCashFlow >= 0))
                                  ? const Color(0xFF39D98A).withOpacity(0.14)
                                  : const Color(0xFFFF6B7A).withOpacity(0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _selectedDonutIndex == 0
                                  ? '${(incomeShare * 100).round()}% dari Alur'
                                  : (_selectedDonutIndex == 1
                                      ? '${(expenseShare * 100).round()}% dari Alur'
                                      : (metrics.netCashFlow >= 0 ? 'Surplus' : 'Defisit')),
                              style: GoogleFonts.manrope(
                                color: (_selectedDonutIndex == 0 || (_selectedDonutIndex == null && metrics.netCashFlow >= 0))
                                    ? const Color(0xFF39D98A)
                                    : const Color(0xFFFF6B7A),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2-Column Breakdown Cards (Uang Masuk vs Uang Keluar)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDonutIndex = _selectedDonutIndex == 0 ? null : 0;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedDonutIndex == 0
                            ? const Color(0xFF39D98A).withOpacity(isDark ? 0.14 : 0.08)
                            : (isDark ? Colors.white.withOpacity(0.025) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedDonutIndex == 0
                              ? const Color(0xFF39D98A).withOpacity(0.5)
                              : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF39D98A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Uang Masuk',
                                style: GoogleFonts.manrope(
                                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              provider.formatCurrency(metrics.monthIncome),
                              style: GoogleFonts.interTight(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(incomeShare * 100).round()}% total flow',
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF39D98A),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDonutIndex = _selectedDonutIndex == 1 ? null : 1;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedDonutIndex == 1
                            ? const Color(0xFF55C7FF).withOpacity(isDark ? 0.14 : 0.08)
                            : (isDark ? Colors.white.withOpacity(0.025) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedDonutIndex == 1
                              ? const Color(0xFF55C7FF).withOpacity(0.5)
                              : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF55C7FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Uang Keluar',
                                style: GoogleFonts.manrope(
                                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              provider.formatCurrency(metrics.monthExpense),
                              style: GoogleFonts.interTight(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(expenseShare * 100).round()}% total flow',
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF55C7FF),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Top Expense Category Pod
            if (metrics.topCategoryAmount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        provider.categories
                            .cast<CategoryModel?>()
                            .firstWhere(
                              (c) => c?.name.toLowerCase() == metrics.topCategoryName.toLowerCase(),
                              orElse: () => null,
                            )?.icon ?? Icons.category_rounded,
                        size: 16,
                        color: const Color(0xFF55C7FF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengeluaran Terbanyak',
                            style: GoogleFonts.manrope(
                              color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            metrics.topCategoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            provider.formatCurrency(metrics.topCategoryAmount),
                            style: GoogleFonts.interTight(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(metrics.topCategoryPct * 100).round()}% total belanja',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF55C7FF),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 4. Budget Guidance Card
  Widget _buildBudgetGuidanceCard(
    BuildContext context,
    TransactionProvider provider,
    FinancialHealthMetrics metrics,
    bool isDark,
  ) {
    if (metrics.monthlyBudgetLimit > 0) {
      final usagePct = (metrics.budgetUsagePct * 100).round();
      final isOverBudget = metrics.budgetUsagePct > 1.0;
      final isWarning = metrics.budgetUsagePct >= 0.80 && !isOverBudget;
      final statusColor = isOverBudget
          ? const Color(0xFFFF6B7A)
          : isWarning
              ? const Color(0xFFFFC857)
              : const Color(0xFF39D98A);

      final remainingBudget = math.max(0.0, metrics.monthlyBudgetLimit - metrics.monthExpense);

      return NestedCard(
        title: 'Pantauan Anggaran Bulanan',
        action: '$usagePct% Terpakai',
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Terpakai ${provider.formatCurrency(metrics.monthExpense)}',
                        style: GoogleFonts.manrope(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Batas: ${provider.formatCurrency(metrics.monthlyBudgetLimit)}',
                      style: GoogleFonts.manrope(
                        color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  height: 7,
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: metrics.budgetUsagePct.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        isOverBudget
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 16,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOverBudget
                            ? 'Anggaran terlampaui ${provider.formatCurrency(metrics.monthExpense - metrics.monthlyBudgetLimit)}. Harap batasi belanja non-pokok.'
                            : 'Sisa anggaran aman ${provider.formatCurrency(remainingBudget)}. Kuota aman belanja: ${provider.formatCurrency(metrics.dailySafeSpend)} / hari.',
                        style: GoogleFonts.manrope(
                          color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF334155),
                          fontSize: 11,
                          height: 1.35,
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

    return NestedCard(
      title: 'Target & Anggaran Belanja',
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF02539A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.track_changes_rounded,
                color: Color(0xFF55C7FF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingin belanja lebih terarah?',
                    style: GoogleFonts.manrope(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pasang batas anggaran bulanan agar pengeluaran harian tidak membengkak.',
                    style: GoogleFonts.manrope(
                      color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                if (widget.isSheet) Navigator.pop(context);
                Navigator.push(context, BudgetScreen.route());
              },
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                side: BorderSide(
                  color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
                ),
              ),
              child: Text(
                'Pasang',
                style: GoogleFonts.manrope(
                  color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAnalysisState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.insights_rounded,
                size: 26,
                color: isDark ? const Color(0xFF6F8197) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Belum Ada Data Analisis',
              style: GoogleFonts.interTight(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Catat transaksi pengeluaran atau pemasukan pertama Anda untuk melihat skor kesehatan finansial, proyeksi arus kas, dan diagnosa otomatis.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: isDark ? const Color(0xFF8CA7C5) : const Color(0xFF64748B),
                fontSize: 12.5,
                height: 1.45,
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
    final provider = context.watch<TransactionProvider>();
    final healthMetrics = _computeHealthMetrics(provider, _selectedMonth);

    final monthFilterPill = AppMonthFilterPill(
      selectedDate: _selectedMonth,
      onTap: () => showAppMonthFilterSheet(
        context: context,
        initialDate: _selectedMonth,
        onSelected: (date) {
          setState(() {
            _selectedMonth = date;
            _selectedCurvePoint = null;
            _selectedDonutIndex = null;
          });
        },
      ),
    );

    final helpButtonWidget = IconButton(
      tooltip: 'Panduan Analisis',
      onPressed: () => _showHelpGuideSheet(context),
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.help_outline_rounded,
        size: 19,
        color: isDark ? const Color(0xFF8CA7C5) : const Color(0xFF64748B),
      ),
    );

    final contentCards = healthMetrics.txCount == 0 &&
            healthMetrics.monthIncome == 0 &&
            healthMetrics.monthExpense == 0
        ? [
            _buildEmptyAnalysisState(isDark),
          ]
        : [
            _buildFinancialHealthCard(provider, healthMetrics, isDark),
            const SizedBox(height: 12),
            _buildCashFlowCurveCard(provider, healthMetrics, isDark),
            const SizedBox(height: 12),
            _buildCashFlowDonutCard(provider, healthMetrics, isDark),
            const SizedBox(height: 12),
            _buildBudgetGuidanceCard(context, provider, healthMetrics, isDark),
          ];

    if (widget.isSheet) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.94,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2229) : const Color(0xFFF4F5F7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Analisis Keuangan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.interTight(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      helpButtonWidget,
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? const Color(0xFF8CA7C5) : const Color(0xFF64748B),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  monthFilterPill,
                ],
              ),
            ),
            Divider(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
              height: 1,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: contentCards,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C2229) : const Color(0xFFF4F5F7),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            StandardScreenHeader(
              title: 'Analisis Keuangan',
              actionWidget: helpButtonWidget,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: monthFilterPill,
            ),
            const SizedBox(height: 12),
            ...contentCards,
          ],
        ),
      ),
    );
  }
}

class _HealthZoneData {
  final String name;
  final String range;
  final Color color;
  final bool isActive;

  const _HealthZoneData(this.name, this.range, this.color, this.isActive);
}

// -------------------------------------------------------------
// Custom Painter: Half Circular Financial Health Chart (Arch 180°)
// -------------------------------------------------------------
class _HalfCircularHealthPainter extends CustomPainter {
  final int score;
  final Color statusColor;
  final Color trackColor;
  final double strokeWidth;

  const _HalfCircularHealthPainter({
    required this.score,
    required this.statusColor,
    required this.trackColor,
    this.strokeWidth = 14.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Semicircle center at bottom center with stroke padding
    final center = Offset(size.width / 2, size.height - 12);
    final radius = (size.width / 2) - strokeWidth - 4;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Draw 180-degree background track arch (from math.pi to 2 * math.pi)
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    // 2. Draw active progress arch proportional to score / 100
    final sweepAngle = math.pi * (score / 100.0).clamp(0.0, 1.0);
    if (sweepAngle > 0.005) {
      canvas.drawArc(rect, math.pi, sweepAngle, false, progressPaint);

      // Indicator thumb knob at current progress angle
      final currentAngle = math.pi + sweepAngle;
      final thumbX = center.dx + radius * math.cos(currentAngle);
      final thumbY = center.dy + radius * math.sin(currentAngle);
      final thumbCenter = Offset(thumbX, thumbY);

      // White fill circle
      final thumbFillPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(thumbCenter, 7.5, thumbFillPaint);

      // Accent border circle
      final thumbBorderPaint = Paint()
        ..color = statusColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(thumbCenter, 7.5, thumbBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HalfCircularHealthPainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.statusColor != statusColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// -------------------------------------------------------------
// Custom Painter: Cash Flow Curve Chart (Smooth Bezier Line Chart)
// -------------------------------------------------------------
class _CashFlowCurvePainter extends CustomPainter {
  final List<double> incomePoints;
  final List<double> expensePoints;
  final int? selectedIndex;
  final bool isDark;

  const _CashFlowCurvePainter({
    required this.incomePoints,
    required this.expensePoints,
    required this.selectedIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (incomePoints.isEmpty || expensePoints.isEmpty) return;

    const topPadding = 14.0;
    const bottomPadding = 20.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final chartWidth = size.width;

    double maxVal = 0.0;
    for (final v in incomePoints) {
      if (v > maxVal) maxVal = v;
    }
    for (final v in expensePoints) {
      if (v > maxVal) maxVal = v;
    }
    if (maxVal <= 0) maxVal = 100000.0;
    // Add 10% headroom
    maxVal *= 1.1;

    // 1. Draw 3 subtle horizontal gridlines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final y = topPadding + (chartHeight / 2) * i;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final count = incomePoints.length;
    final stepX = count > 1 ? chartWidth / (count - 1) : chartWidth;

    List<Offset> computeOffsets(List<double> values) {
      final offsets = <Offset>[];
      for (int i = 0; i < values.length; i++) {
        final x = count > 1 ? i * stepX : chartWidth / 2;
        final norm = (values[i] / maxVal).clamp(0.0, 1.0);
        final y = topPadding + chartHeight - (norm * chartHeight);
        offsets.add(Offset(x, y));
      }
      return offsets;
    }

    final incOffsets = computeOffsets(incomePoints);
    final expOffsets = computeOffsets(expensePoints);

    // 2. Draw Income Curve (Green)
    _drawCurve(
      canvas: canvas,
      size: size,
      offsets: incOffsets,
      lineColor: const Color(0xFF39D98A),
      topPadding: topPadding,
      chartHeight: chartHeight,
    );

    // 3. Draw Expense Curve (Cyan)
    _drawCurve(
      canvas: canvas,
      size: size,
      offsets: expOffsets,
      lineColor: const Color(0xFF55C7FF),
      topPadding: topPadding,
      chartHeight: chartHeight,
    );

    // 4. Draw Selected Checkpoint Cursor Line & Highlight Dots
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < count) {
      final selX = incOffsets[selectedIndex!].dx;

      final cursorPaint = Paint()
        ..color = isDark ? Colors.white.withOpacity(0.25) : const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawLine(
        Offset(selX, topPadding - 4),
        Offset(selX, topPadding + chartHeight + 6),
        cursorPaint,
      );

      // Income point highlight
      final incPt = incOffsets[selectedIndex!];
      canvas.drawCircle(
        incPt,
        6.0,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        incPt,
        6.0,
        Paint()
          ..color = const Color(0xFF39D98A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );

      // Expense point highlight
      final expPt = expOffsets[selectedIndex!];
      canvas.drawCircle(
        expPt,
        6.0,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        expPt,
        6.0,
        Paint()
          ..color = const Color(0xFF55C7FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }
  }

  void _drawCurve({
    required Canvas canvas,
    required Size size,
    required List<Offset> offsets,
    required Color lineColor,
    required double topPadding,
    required double chartHeight,
  }) {
    if (offsets.isEmpty) return;

    final path = Path();
    path.moveTo(offsets[0].dx, offsets[0].dy);

    if (offsets.length == 1) {
      path.lineTo(size.width, offsets[0].dy);
    } else {
      for (int i = 0; i < offsets.length - 1; i++) {
        final p0 = i > 0 ? offsets[i - 1] : offsets[i];
        final p1 = offsets[i];
        final p2 = offsets[i + 1];
        final p3 = i < offsets.length - 2 ? offsets[i + 2] : p2;

        final cp1x = p1.dx + (p2.dx - p0.dx) / 6.0;
        final cp1y = p1.dy + (p2.dy - p0.dy) / 6.0;
        final cp2x = p2.dx - (p3.dx - p1.dx) / 6.0;
        final cp2y = p2.dy - (p3.dy - p1.dy) / 6.0;

        path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }
    }

    // Area Fill Gradient below the curve
    final fillPath = Path.from(path)
      ..lineTo(offsets.last.dx, topPadding + chartHeight)
      ..lineTo(offsets.first.dx, topPadding + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.18),
          lineColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawPath(path, strokePaint);

    // Dots at each checkpoint
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF131A26) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final pt in offsets) {
      canvas.drawCircle(pt, 3.5, dotPaint);
      canvas.drawCircle(pt, 3.5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CashFlowCurvePainter oldDelegate) {
    return oldDelegate.incomePoints != incomePoints ||
        oldDelegate.expensePoints != expensePoints ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.isDark != isDark;
  }
}
