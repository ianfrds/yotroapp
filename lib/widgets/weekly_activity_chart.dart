import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import 'nested_card.dart';

class WeeklyActivityChart extends StatefulWidget {
  final VoidCallback? onDetailTap;
  final TransactionType type;
  final String title;
  final bool showCard;
  final DateTime? selectedMonth;
  final bool enableWeekFilter;
  final bool isDualBar;

  const WeeklyActivityChart({
    super.key,
    this.onDetailTap,
    this.type = TransactionType.expense,
    this.title = 'Aktivitas Pengeluaran',
    this.showCard = true,
    this.selectedMonth,
    this.enableWeekFilter = false,
    this.isDualBar = false,
  });

  @override
  State<WeeklyActivityChart> createState() => _WeeklyActivityChartState();
}

class _WeekRange {
  final DateTime start;
  final DateTime end;

  const _WeekRange({required this.start, required this.end});
}

class _WeeklyActivityChartState extends State<WeeklyActivityChart> {
  int? _selectedDayIndex;
  int _selectedWeekIndex = 0;
  List<_WeekRange> _weeks = [];

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agt',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  void initState() {
    super.initState();
    _initWeeks();
  }

  @override
  void didUpdateWidget(covariant WeeklyActivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth?.year != widget.selectedMonth?.year ||
        oldWidget.selectedMonth?.month != widget.selectedMonth?.month) {
      _initWeeks();
    }
  }

  void _initWeeks() {
    _weeks = _calculateWeeks(widget.selectedMonth ?? DateTime.now());
    _selectedWeekIndex = _findInitialWeekIndex(_weeks);
    _selectedDayIndex = null;
  }

  List<_WeekRange> _calculateWeeks(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    final leadingDays = firstDay.weekday - 1; // 0..6
    var currentMonday = DateTime(
      firstDay.year,
      firstDay.month,
      firstDay.day,
    ).subtract(Duration(days: leadingDays));

    final List<_WeekRange> weeks = [];
    while (currentMonday.isBefore(lastDay) ||
        (currentMonday.year == lastDay.year &&
            currentMonday.month == lastDay.month &&
            currentMonday.day == lastDay.day)) {
      final sunday = currentMonday.add(const Duration(days: 6));
      weeks.add(_WeekRange(start: currentMonday, end: sunday));
      currentMonday = currentMonday.add(const Duration(days: 7));
    }
    return weeks.isEmpty
        ? [
            _WeekRange(
              start: firstDay,
              end: firstDay.add(const Duration(days: 6)),
            ),
          ]
        : weeks;
  }

  int _findInitialWeekIndex(List<_WeekRange> weeks) {
    final now = DateTime.now();
    for (int i = 0; i < weeks.length; i++) {
      final start = DateTime(
        weeks[i].start.year,
        weeks[i].start.month,
        weeks[i].start.day,
      );
      final end = DateTime(
        weeks[i].end.year,
        weeks[i].end.month,
        weeks[i].end.day,
        23,
        59,
        59,
      );
      if ((now.isAfter(start) || now.isAtSameMomentAs(start)) &&
          (now.isBefore(end) || now.isAtSameMomentAs(end))) {
        return i;
      }
    }
    return 0;
  }

  String _formatDateRange(DateTime start, DateTime end) {
    if (start.month == end.month) {
      return '${start.day} – ${end.day} ${_shortMonths[start.month - 1]}';
    }
    return '${start.day} ${_shortMonths[start.month - 1]} – ${end.day} ${_shortMonths[end.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final safeWeekIndex = _selectedWeekIndex
        .clamp(
          0,
          math.max(0, _weeks.length - 1),
        )
        .toInt();
    final currentWeek = _weeks.isNotEmpty
        ? _weeks[safeWeekIndex]
        : _WeekRange(
            start: DateTime(now.year, now.month, now.day).subtract(
              Duration(days: now.weekday - 1),
            ),
            end: DateTime(now.year, now.month, now.day).add(
              Duration(days: 7 - now.weekday),
            ),
          );

    final startOfWeek = currentWeek.start;

    // Check if currentWeek contains today
    int? todayIndexInWeek;
    for (int i = 0; i < 7; i++) {
      final d = startOfWeek.add(Duration(days: i));
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        todayIndexInWeek = i;
        break;
      }
    }

    final selectedIndex = _selectedDayIndex ?? todayIndexInWeek;

    // Compute daily totals for Mon (0) to Sun (6) of THIS active week
    final dailyTotals = List<double>.generate(7, (i) {
      final targetDate = startOfWeek.add(Duration(days: i));
      return provider.transactions
          .where(
            (t) =>
                t.type == widget.type &&
                t.timestamp.year == targetDate.year &&
                t.timestamp.month == targetDate.month &&
                t.timestamp.day == targetDate.day,
          )
          .fold<double>(0.0, (sum, t) => sum + t.amount);
    });

    final dailyIncome = widget.isDualBar
        ? List<double>.generate(7, (i) {
            final targetDate = startOfWeek.add(Duration(days: i));
            return provider.transactions
                .where(
                  (t) =>
                      t.type == TransactionType.income &&
                      t.timestamp.year == targetDate.year &&
                      t.timestamp.month == targetDate.month &&
                      t.timestamp.day == targetDate.day,
                )
                .fold<double>(0.0, (sum, t) => sum + t.amount);
          })
        : const <double>[];

    final dailyExpense = widget.isDualBar
        ? List<double>.generate(7, (i) {
            final targetDate = startOfWeek.add(Duration(days: i));
            return provider.transactions
                .where(
                  (t) =>
                      t.type == TransactionType.expense &&
                      t.timestamp.year == targetDate.year &&
                      t.timestamp.month == targetDate.month &&
                      t.timestamp.day == targetDate.day,
                )
                .fold<double>(0.0, (sum, t) => sum + t.amount);
          })
        : const <double>[];

    // User requirement: When empty state or no transactions this week, do NOT show the chart card
    if (widget.isDualBar) {
      final hasAnyTx = dailyIncome.any((v) => v > 0) || dailyExpense.any((v) => v > 0);
      if (!hasAnyTx) {
        return const SizedBox.shrink();
      }
    }

    final double maxDaily = widget.isDualBar
        ? math.max(
            dailyIncome.fold<double>(0.0, math.max),
            dailyExpense.fold<double>(0.0, math.max),
          )
        : dailyTotals.fold<double>(0.0, math.max);

    final canGoPrev = safeWeekIndex > 0;
    final canGoNext = safeWeekIndex < _weeks.length - 1;

    final chartContent = Padding(
      padding: EdgeInsets.fromLTRB(
        widget.showCard ? 14 : 0,
        widget.showCard ? 12 : 0,
        widget.showCard ? 14 : 0,
        widget.showCard ? 14 : 2,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: widget.enableWeekFilter
            ? (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -120 && canGoNext) {
                    setState(() {
                      _selectedWeekIndex++;
                      _selectedDayIndex = null;
                    });
                  } else if (details.primaryVelocity! > 120 && canGoPrev) {
                    setState(() {
                      _selectedWeekIndex--;
                      _selectedDayIndex = null;
                    });
                  }
                }
              }
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Clean Minimalist Week Navigator (No pill/badge container, elevated to top)
            if (widget.enableWeekFilter && _weeks.length > 1) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: canGoPrev
                          ? () => setState(() {
                                _selectedWeekIndex--;
                                _selectedDayIndex = null;
                              })
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 20,
                          color: canGoPrev
                              ? (isDark ? const Color(0xFF8CA7C5) : const Color(0xFF475569))
                              : (isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                    Text(
                      'Minggu ${safeWeekIndex + 1} (${_formatDateRange(currentWeek.start, currentWeek.end)})',
                      style: GoogleFonts.manrope(
                        color: isDark ? const Color(0xFF8CA7C5) : const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                    InkWell(
                      onTap: canGoNext
                          ? () => setState(() {
                                _selectedWeekIndex++;
                                _selectedDayIndex = null;
                              })
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: canGoNext
                              ? (isDark ? const Color(0xFF8CA7C5) : const Color(0xFF475569))
                              : (isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Taller 195px Bar Chart Area
            SizedBox(
              height: 195,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final double barWidth = widget.isDualBar ? 26.0 : 32.0;
                  final totalBarsWidth = barWidth * 7;
                  final gap = (totalWidth - totalBarsWidth) / 6;

                  final double badgeWidth = widget.isDualBar ? 128.0 : 88.0;
                  final double badgeLeft;
                  if (selectedIndex != null) {
                    final barCenterX =
                        selectedIndex * (barWidth + gap) + (barWidth / 2);
                    badgeLeft = (barCenterX - (badgeWidth / 2))
                        .clamp(
                          0.0,
                          math.max(0.0, totalWidth - badgeWidth),
                        )
                        .toDouble();
                  } else {
                    badgeLeft = 0.0;
                  }

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Floating Tooltip Badge above active bar (only when tapped)
                      if (selectedIndex != null)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          left: badgeLeft,
                          top: 0,
                          child: Container(
                          width: badgeWidth,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: widget.isDualBar
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Masuk',
                                              style: GoogleFonts.manrope(
                                                color: const Color(0xFF475569),
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              provider.formatCurrency(
                                                dailyIncome[selectedIndex],
                                              ),
                                              style: GoogleFonts.interTight(
                                                color: const Color(0xFF047857),
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Color(0xFFEF4444),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Keluar',
                                              style: GoogleFonts.manrope(
                                                color: const Color(0xFF475569),
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              provider.formatCurrency(
                                                dailyExpense[selectedIndex],
                                              ),
                                              style: GoogleFonts.interTight(
                                                color: const Color(0xFFB91C1C),
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        provider.formatCurrency(
                                          dailyTotals[selectedIndex],
                                        ),
                                        style: GoogleFonts.interTight(
                                          color: Colors.black,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // 7 Activity Bars & Labels
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(7, (i) {
                            final isSelected = selectedIndex != null && i == selectedIndex;
                            final isToday = todayIndexInWeek == i;

                            Widget barsWidget;
                            if (widget.isDualBar) {
                              final double normInc = maxDaily > 0 ? (dailyIncome[i] / maxDaily) : 0.0;
                              final double normExp = maxDaily > 0 ? (dailyExpense[i] / maxDaily) : 0.0;
                              final double incHeight = (normInc * 122.0).clamp(6.0, 122.0);
                              final double expHeight = (normExp * 122.0).clamp(6.0, 122.0);

                              barsWidget = Container(
                                width: barWidth,
                                decoration: isToday && !isSelected
                                    ? BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFF55C7FF).withOpacity(0.5),
                                          width: 1,
                                        ),
                                      )
                                    : null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Income Bar
                                    Expanded(
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeOutCubic,
                                        height: incHeight,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF34D399)
                                              : (isDark
                                                  ? const Color(0xFF104A3A)
                                                  : const Color(0xFFA7F3D0)),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    // Expense Bar
                                    Expanded(
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeOutCubic,
                                        height: expHeight,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFFF6B7A)
                                              : (isDark
                                                  ? const Color(0xFF4A1E26)
                                                  : const Color(0xFFFECDD3)),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              final dayAmount = dailyTotals[i];
                              final double normalized = maxDaily > 0 ? (dayAmount / maxDaily) : 0.0;
                              final double barHeight = (normalized * 122.0).clamp(10.0, 122.0);

                              barsWidget = AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                width: barWidth,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF8CA7C5) : const Color(0xFF334155))
                                      : (isDark ? const Color(0xFF202A38) : const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(9),
                                  border: isToday && !isSelected
                                      ? Border.all(
                                          color: const Color(0xFF55C7FF).withOpacity(0.5),
                                          width: 1,
                                        )
                                      : null,
                                ),
                              );
                            }

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDayIndex = i;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  barsWidget,
                                  const SizedBox(height: 8),
                                  Text(
                                    _dayLabels[i],
                                    style: GoogleFonts.manrope(
                                      color: isSelected
                                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                          : (isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B)),
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  // Indicator dot for today
                                  Container(
                                    width: 3.5,
                                    height: 3.5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isToday
                                          ? const Color(0xFF55C7FF)
                                          : Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.showCard) {
      return chartContent;
    }

    return NestedCard(
      title: widget.title,
      actionWidget: widget.isDualBar
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF34D399),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Masuk',
                  style: GoogleFonts.manrope(
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFF8CA7C5) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF6B7A),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Keluar',
                  style: GoogleFonts.manrope(
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFF8CA7C5) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : null,
      child: chartContent,
    );
  }
}
