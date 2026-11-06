import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/nested_card.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/standard_screen_header.dart';
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
  final double dailyAverageSpend;
  final double projectedMonthEnd;
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
    required this.dailyAverageSpend,
    required this.projectedMonthEnd,
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
            icon: Icons.speed_rounded,
            iconColor: const Color(0xFF38BDF8),
            title: 'Rata-rata Harian & Proyeksi Akhir Bulan',
            description:
                'Menghitung rata-rata uang yang Anda keluarkan setiap hari dan memproyeksikan estimasi total belanja sampai akhir bulan jika pola belanja Anda berlanjut.',
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
        dailyAverageSpend: 0.0,
        projectedMonthEnd: 0.0,
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

    final dailyAverageSpend = daysPassed > 0 ? (expense / daysPassed) : 0.0;
    final projectedMonthEnd = dailyAverageSpend * daysInMonth;

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
      status = 'Sehat & Stabil';
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
      dailyAverageSpend: dailyAverageSpend,
      projectedMonthEnd: projectedMonthEnd,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Skor & Progress Meter 4 Zona
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${metrics.score}',
                        style: GoogleFonts.interTight(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 34,
                          fontWeight: FontWeight.w600,
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          height: 8,
                          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: (metrics.score / 100.0).clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: metrics.statusColor,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Kurang',
                              style: GoogleFonts.manrope(
                                color: isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8),
                                fontSize: 9.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'Waspada',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                color: isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8),
                                fontSize: 9.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'Aman',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                color: isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8),
                                fontSize: 9.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'Sangat Baik',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.manrope(
                                color: isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8),
                                fontSize: 9.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 12),

            // Row 2: 3 Mini Metric Pods
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

            // Row 3: Smart Diagnostic Insight Box (Bahasa Ramah & Edukatif)
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

  Widget _buildCashFlowStatsCard(
    TransactionProvider provider,
    FinancialHealthMetrics metrics,
    bool isDark,
  ) {
    final totalFlow = metrics.monthIncome + metrics.monthExpense;
    final incomeFactor = totalFlow > 0 ? (metrics.monthIncome / totalFlow) : 0.5;
    final expenseFactor = totalFlow > 0 ? (metrics.monthExpense / totalFlow) : 0.5;

    return NestedCard(
      title: 'Statistik & Arus Kas',
      action: '${metrics.txCount} Transaksi',
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pod 1 & Pod 2: Rata-rata Harian vs Proyeksi Akhir Bulan
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.speed_rounded, size: 14, color: Color(0xFF55C7FF)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Rata-rata Harian',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            provider.formatCurrency(metrics.dailyAverageSpend),
                            style: GoogleFonts.interTight(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pengeluaran per hari',
                          maxLines: 2,
                          style: GoogleFonts.manrope(
                            color: isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8),
                            fontSize: 10,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFFFFC857)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Proyeksi Akhir Bulan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            provider.formatCurrency(metrics.projectedMonthEnd),
                            style: GoogleFonts.interTight(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Perkiraan akhir bulan',
                          maxLines: 2,
                          style: GoogleFonts.manrope(
                            color: isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8),
                            fontSize: 10,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Cash Flow Proportion Mini Chart Bar
            Text(
              'Rasio Pemasukan vs Pengeluaran',
              style: GoogleFonts.manrope(
                color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    Expanded(
                      flex: (incomeFactor * 100).round().clamp(1, 99),
                      child: Container(
                        color: const Color(0xFF39D98A),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: (expenseFactor * 100).round().clamp(1, 99),
                      child: Container(
                        color: const Color(0xFF55C7FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.025) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.025) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Top Expense Focus Pod
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
    final monthLabel =
        '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';

    final periodPickerWidget = InkWell(
      onTap: () => _showMonthPicker(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header with title, help button, period selector, and close button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 10),
              child: Row(
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
                  periodPickerWidget,
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
            ),
            Divider(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
              height: 1,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: healthMetrics.txCount == 0 &&
                        healthMetrics.monthIncome == 0 &&
                        healthMetrics.monthExpense == 0
                    ? [
                        _buildEmptyAnalysisState(isDark),
                      ]
                    : [
                        _buildFinancialHealthCard(provider, healthMetrics, isDark),
                        const SizedBox(height: 12),
                        _buildCashFlowStatsCard(provider, healthMetrics, isDark),
                        const SizedBox(height: 12),
                        _buildBudgetGuidanceCard(context, provider, healthMetrics, isDark),
                      ],
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
            // Top App Bar
            StandardScreenHeader(
              title: 'Analisis Keuangan',
              actionWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  helpButtonWidget,
                  const SizedBox(width: 4),
                  periodPickerWidget,
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (healthMetrics.txCount == 0 &&
                healthMetrics.monthIncome == 0 &&
                healthMetrics.monthExpense == 0)
              _buildEmptyAnalysisState(isDark)
            else ...[
              _buildFinancialHealthCard(provider, healthMetrics, isDark),
              const SizedBox(height: 12),
              _buildCashFlowStatsCard(provider, healthMetrics, isDark),
              const SizedBox(height: 12),
              _buildBudgetGuidanceCard(context, provider, healthMetrics, isDark),
            ],
          ],
        ),
      ),
    );
  }
}
