import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import 'nested_card.dart';

class SpendingCalendarCard extends StatefulWidget {
  final ValueChanged<DateTime>? onDateSelected;

  const SpendingCalendarCard({
    super.key,
    this.onDateSelected,
  });

  @override
  State<SpendingCalendarCard> createState() => _SpendingCalendarCardState();
}

class _SpendingCalendarCardState extends State<SpendingCalendarCard> {
  late DateTime _displayedMonth;
  DateTime? _selectedDate;

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

  static const _weekDayHeaders = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  String _formatCompactAmount(double amount) {
    if (amount <= 0) return '';
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return '${m == m.roundToDouble() ? m.toInt() : m.toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      final k = amount / 1000;
      return '${k == k.roundToDouble() ? k.toInt() : k.toStringAsFixed(1)}K';
    }
    return amount.toInt().toString();
  }

  void _prevMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final monthName = '${_monthNames[month - 1]} $year';

    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    // Monday is 1, Sunday is 7 in Dart
    final leadingDays = firstDayOfMonth.weekday - 1; // 0..6
    final prevMonthLastDay = DateTime(year, month, 0);

    // Build the list of all calendar date cells
    final List<DateTime> calendarDates = [];

    // 1. Previous month leading days
    for (int i = leadingDays - 1; i >= 0; i--) {
      calendarDates.add(
        DateTime(year, month - 1, prevMonthLastDay.day - i),
      );
    }

    // 2. Current month days
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      calendarDates.add(DateTime(year, month, day));
    }

    // 3. Next month trailing days to complete full weeks
    final totalCells = calendarDates.length;
    final trailingDays = (7 - (totalCells % 7)) % 7;
    for (int day = 1; day <= trailingDays; day++) {
      calendarDates.add(DateTime(year, month + 1, day));
    }

    // Calculate expense for each day
    final Map<String, double> dayExpenseMap = {};
    for (final tx in provider.transactions) {
      if (tx.type == TransactionType.expense) {
        final key = '${tx.timestamp.year}-${tx.timestamp.month}-${tx.timestamp.day}';
        dayExpenseMap[key] = (dayExpenseMap[key] ?? 0.0) + tx.amount;
      }
    }

    // Selected date details
    final selectedKey = _selectedDate != null
        ? '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}'
        : null;
    final selectedExpense = selectedKey != null ? (dayExpenseMap[selectedKey] ?? 0.0) : 0.0;

    return NestedCard(
      title: monthName,
      actionWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _prevMonth,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_left_rounded,
                color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF475569),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: _nextMonth,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF475569),
                size: 20,
              ),
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Minimal weekday headers
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _weekDayHeaders.map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: GoogleFonts.manrope(
                          color: isDark ? const Color(0xFF6F8197) : const Color(0xFF64748B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Calendar Tiles Grid (7 Columns)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: calendarDates.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final date = calendarDates[index];
                final isCurrentMonth = date.month == month;
                final isToday = date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;
                final isSelected = _selectedDate != null &&
                    date.year == _selectedDate!.year &&
                    date.month == _selectedDate!.month &&
                    date.day == _selectedDate!.day;

                final dateKey = '${date.year}-${date.month}-${date.day}';
                final dayExpense = dayExpenseMap[dateKey] ?? 0.0;
                final compactText = _formatCompactAmount(dayExpense);

                BoxDecoration? decoration;
                if (isToday) {
                  decoration = BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF55C7FF)
                          : (isDark ? Colors.white.withOpacity(0.35) : const Color(0xFF94A3B8)),
                      width: 1.2,
                    ),
                  );
                } else if (isSelected) {
                  decoration = BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF55C7FF).withOpacity(0.5) : const Color(0xFF0F172A),
                      width: 1,
                    ),
                  );
                }

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    widget.onDateSelected?.call(date);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: decoration,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${date.day}',
                            style: GoogleFonts.interTight(
                              color: isToday
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : isCurrentMonth
                                      ? (isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF0F172A))
                                      : (isDark ? Colors.white.withOpacity(0.28) : const Color(0xFFCBD5E1)),
                              fontSize: 12.5,
                              fontWeight: isToday || isCurrentMonth
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),

                        // Expense Amount (e.g. 13K)
                        if (compactText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              compactText,
                              style: GoogleFonts.interTight(
                                color: isCurrentMonth
                                    ? (isDark ? const Color(0xFF8CA7C5) : const Color(0xFF475569))
                                    : (isDark ? const Color(0xFF8CA7C5).withOpacity(0.35) : const Color(0xFF94A3B8)),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Selected Day Summary (if expense exists)
            if (_selectedDate != null && selectedExpense > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A222E) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate!.day} ${_monthNames[_selectedDate!.month - 1]}',
                        style: GoogleFonts.manrope(
                          color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF475569),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        provider.formatCurrency(selectedExpense),
                        style: GoogleFonts.interTight(
                          color: const Color(0xFF55C7FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
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
}

