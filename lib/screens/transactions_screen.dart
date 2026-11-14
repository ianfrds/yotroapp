import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/nested_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/ambient_top_glow.dart';
import '../widgets/app_skeleton.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const TransactionsScreen({super.key, this.scrollController});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;
  String _selectedType = 'ALL';
  String _selectedWallet = 'ALL';
  int? _filterYear;
  int? _filterMonth;
  DateTime? _selectedDate;
  DateTimeRange? _selectedDateRange;

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

  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveTimeFilter =>
      _selectedDateRange != null || _selectedDate != null || _filterYear != null;

  String _getTimeFilterLabel() {
    if (_selectedDateRange != null) {
      final s = _selectedDateRange!.start;
      final e = _selectedDateRange!.end;
      return 'Rentang: ${s.day} ${_shortMonths[s.month - 1]} - ${e.day} ${_shortMonths[e.month - 1]} ${e.year}';
    }
    if (_selectedDate != null) {
      return 'Tanggal: ${_selectedDate!.day} ${_shortMonths[_selectedDate!.month - 1]} ${_selectedDate!.year}';
    }
    if (_filterYear != null) {
      if (_filterMonth != null) {
        return 'Bulan: ${_monthNames[_filterMonth! - 1]} $_filterYear';
      }
      return 'Tahun: $_filterYear';
    }
    return 'Semua Periode';
  }

  static const _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    final dayName = _dayNames[date.weekday - 1];
    final formattedDate = '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';

    if (target == today) {
      return 'Hari Ini • $formattedDate';
    } else if (target == yesterday) {
      return 'Kemarin • $formattedDate';
    } else {
      return '$dayName • $formattedDate';
    }
  }

  void _resetTimeFilter() {
    setState(() {
      _filterYear = null;
      _filterMonth = null;
      _selectedDate = null;
      _selectedDateRange = null;
    });
  }

  void _showDateFilterBottomSheet(BuildContext context) {
    int activeTab = 0;
    if (_selectedDateRange != null) {
      activeTab = 2;
    } else if (_selectedDate != null) {
      activeTab = 1;
    } else {
      activeTab = 0;
    }

    final now = DateTime.now();
    int tempYear = _filterYear ?? now.year;
    int? tempMonth = _filterMonth;
    bool isFullYear = _filterYear != null && _filterMonth == null;
    if (_filterYear == null && _selectedDate == null && _selectedDateRange == null) {
      tempMonth = now.month;
    }

    DateTime tempDate = _selectedDate ?? now;
    DateTimeRange tempRange = _selectedDateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
            final cardBg = isDark ? const Color(0xFF131A26) : Colors.white;
            final borderColor = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0);

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0C131D) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.55 : 0.15),
                    blurRadius: 28,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
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
                          'Filter Periode Transaksi',
                          style: GoogleFonts.interTight(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Segmented Tab Switcher (Bulan & Tahun | Tanggal | Rentang)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        height: 40,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131A26) : const Color(0xFFE2E8F0).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            _buildTabPill(
                              label: 'Bulan & Tahun',
                              isSelected: activeTab == 0,
                              onTap: () => setSheetState(() => activeTab = 0),
                              mutedColor: mutedColor,
                            ),
                            const SizedBox(width: 4),
                            _buildTabPill(
                              label: 'Tanggal',
                              isSelected: activeTab == 1,
                              onTap: () => setSheetState(() => activeTab = 1),
                              mutedColor: mutedColor,
                            ),
                            const SizedBox(width: 4),
                            _buildTabPill(
                              label: 'Rentang Tanggal',
                              isSelected: activeTab == 2,
                              onTap: () => setSheetState(() => activeTab = 2),
                              mutedColor: mutedColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Content Card according to activeTab
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: activeTab == 0
                            ? _buildMonthYearContent(
                                ctx: ctx,
                                isDark: isDark,
                                tempYear: tempYear,
                                tempMonth: tempMonth,
                                isFullYear: isFullYear,
                                onYearChanged: (newY) => setSheetState(() => tempYear = newY),
                                onMonthSelected: (m) => setSheetState(() {
                                  tempMonth = m;
                                  isFullYear = false;
                                }),
                                onFullYearToggled: () => setSheetState(() {
                                  isFullYear = !isFullYear;
                                  if (isFullYear) tempMonth = null;
                                }),
                              )
                            : activeTab == 1
                                ? _buildSingleDateContent(
                                    ctx: ctx,
                                    isDark: isDark,
                                    selectedDate: tempDate,
                                    onDateChanged: (d) => setSheetState(() => tempDate = d),
                                  )
                                : _buildDateRangeContent(
                                    ctx: ctx,
                                    isDark: isDark,
                                    selectedRange: tempRange,
                                    onRangeChanged: (r) => setSheetState(() => tempRange = r),
                                  ),
                      ),
                      const SizedBox(height: 20),

                      // Bottom Action Buttons (Full Width: Batal on left, Simpan on right)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _resetTimeFilter();
                                  Navigator.pop(sheetCtx);
                                },
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
                                    color: textColor,
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
                                  setState(() {
                                    if (activeTab == 0) {
                                      _filterYear = tempYear;
                                      _filterMonth = isFullYear ? null : tempMonth;
                                      _selectedDate = null;
                                      _selectedDateRange = null;
                                    } else if (activeTab == 1) {
                                      _selectedDate = tempDate;
                                      _filterYear = null;
                                      _filterMonth = null;
                                      _selectedDateRange = null;
                                    } else {
                                      _selectedDateRange = tempRange;
                                      _filterYear = null;
                                      _filterMonth = null;
                                      _selectedDate = null;
                                    }
                                  });
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color mutedColor,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF02539A) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: GoogleFonts.manrope(
                color: isSelected ? Colors.white : mutedColor,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthYearContent({
    required BuildContext ctx,
    required bool isDark,
    required int tempYear,
    required int? tempMonth,
    required bool isFullYear,
    required ValueChanged<int> onYearChanged,
    required ValueChanged<int> onMonthSelected,
    required VoidCallback onFullYearToggled,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);
    final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Year selector row (Centered with chevron left & chevron right, clickable year)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => onYearChanged(tempYear - 1),
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
                  onYearChanged(pickedYear);
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
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: mutedColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => onYearChanged(tempYear + 1),
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
        const SizedBox(height: 18),

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
                      final isSelected = !isFullYear && tempMonth == monthNum;

                      return InkWell(
                        onTap: () => onMonthSelected(monthNum),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(20),
                                )
                              : null,
                          child: Text(
                            _shortMonths[mIndex],
                            style: GoogleFonts.manrope(
                              color: isSelected ? Colors.white : textColor,
                              fontSize: 13.5,
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
          if (r < 2) const SizedBox(height: 14),
        ],
        const SizedBox(height: 16),

        // Full Year Selection Button
        InkWell(
          onTap: onFullYearToggled,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
            decoration: BoxDecoration(
              color: isFullYear
                  ? const Color(0xFF2563EB).withOpacity(0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFullYear ? const Color(0xFF2563EB) : borderColor,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFullYear ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isFullYear ? const Color(0xFF2563EB) : mutedColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Pilih 1 Tahun Penuh ($tempYear)',
                      maxLines: 1,
                      style: GoogleFonts.manrope(
                        color: isFullYear ? textColor : mutedColor,
                        fontSize: 12.5,
                        fontWeight: isFullYear ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleDateContent({
    required BuildContext ctx,
    required bool isDark,
    required DateTime selectedDate,
    required ValueChanged<DateTime> onDateChanged,
  }) {
    return Column(
      children: [
        Theme(
          data: Theme.of(ctx).copyWith(
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
          child: CalendarDatePicker(
            initialDate: selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
            onDateChanged: onDateChanged,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Dipilih: ${selectedDate.day} ${_monthNames[selectedDate.month - 1]} ${selectedDate.year}',
            style: GoogleFonts.interTight(
              color: const Color(0xFF55C7FF),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeContent({
    required BuildContext ctx,
    required bool isDark,
    required DateTimeRange selectedRange,
    required ValueChanged<DateTimeRange> onRangeChanged,
  }) {
    final now = DateTime.now();
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick Presets
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPresetChip(
                label: '7 Hari',
                onTap: () {
                  onRangeChanged(
                    DateTimeRange(
                      start: now.subtract(const Duration(days: 6)),
                      end: now,
                    ),
                  );
                },
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildPresetChip(
                label: '30 Hari',
                onTap: () {
                  onRangeChanged(
                    DateTimeRange(
                      start: now.subtract(const Duration(days: 29)),
                      end: now,
                    ),
                  );
                },
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildPresetChip(
                label: 'Bulan Ini',
                onTap: () {
                  onRangeChanged(
                    DateTimeRange(
                      start: DateTime(now.year, now.month, 1),
                      end: now,
                    ),
                  );
                },
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildPresetChip(
                label: 'Bulan Lalu',
                onTap: () {
                  final firstOfThisMonth = DateTime(now.year, now.month, 1);
                  final lastOfLastMonth = firstOfThisMonth.subtract(const Duration(days: 1));
                  final firstOfLastMonth = DateTime(lastOfLastMonth.year, lastOfLastMonth.month, 1);
                  onRangeChanged(
                    DateTimeRange(
                      start: firstOfLastMonth,
                      end: lastOfLastMonth,
                    ),
                  );
                },
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Visual Start and End Date cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mulai',
                      style: GoogleFonts.manrope(
                        color: mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${selectedRange.start.day} ${_shortMonths[selectedRange.start.month - 1]} ${selectedRange.start.year}',
                      style: GoogleFonts.interTight(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: mutedColor,
                size: 16,
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selesai',
                      style: GoogleFonts.manrope(
                        color: mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${selectedRange.end.day} ${_shortMonths[selectedRange.end.month - 1]} ${selectedRange.end.year}',
                      style: GoogleFonts.interTight(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Button to open interactive DateRangePicker dialog
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: ctx,
              initialDateRange: selectedRange,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              builder: (pickerCtx, child) {
                return Theme(
                  data: Theme.of(pickerCtx).copyWith(
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
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onRangeChanged(picked);
            }
          },
          icon: const Icon(Icons.date_range_rounded, size: 16),
          label: const Text('Buka Kalender Rentang'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 11),
            side: BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            foregroundColor: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Durasi: ${selectedRange.duration.inDays + 1} hari',
            style: GoogleFonts.manrope(
              color: mutedColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final query = _searchController.text.toLowerCase().trim();

    final hasActiveFilter = _selectedType != 'ALL' ||
        _selectedWallet != 'ALL' ||
        _hasActiveTimeFilter ||
        query.isNotEmpty;

    final filtered = provider.transactions.where((t) {
      if (_selectedType != 'ALL' && t.type.name != _selectedType) return false;
      if (_selectedWallet != 'ALL' && t.walletId != _selectedWallet) return false;

      // Filter Waktu / Periode:
      if (_selectedDateRange != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );
        if (t.timestamp.isBefore(start) || t.timestamp.isAfter(end)) return false;
      } else if (_selectedDate != null) {
        if (t.timestamp.year != _selectedDate!.year ||
            t.timestamp.month != _selectedDate!.month ||
            t.timestamp.day != _selectedDate!.day) {
          return false;
        }
      } else if (_filterYear != null) {
        if (t.timestamp.year != _filterYear) return false;
        if (_filterMonth != null && t.timestamp.month != _filterMonth) {
          return false;
        }
      }

      // Filter Pencarian Teks
      if (query.isNotEmpty) {
        final inTitle = t.title.toLowerCase().contains(query);
        final inNote = t.note.toLowerCase().contains(query);
        final inCat = t.categoryName.toLowerCase().contains(query);
        final inAmt = t.amount.toString().contains(query);
        if (!inTitle && !inNote && !inCat && !inAmt) return false;
      }
      return true;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131A26) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);
    final textTitleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF8CA7C5) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C2229) : const Color(0xFFF4F5F7),
      body: Stack(
        children: [
          if (isDark) const AmbientTopGlow(),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () => provider.refreshData(),
              color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
              backgroundColor: isDark ? const Color(0xFF131A26) : Colors.white,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
          children: [
            // Top App Bar
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Riwayat Transaksi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.interTight(
                      color: textTitleColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasActiveFilter) ...[
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedType = 'ALL';
                        _selectedWallet = 'ALL';
                        _resetTimeFilter();
                        _searchController.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        'Reset Filter',
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF55C7FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                InkWell(
                  onTap: () {
                    setState(() {
                      _isSearchOpen = !_isSearchOpen;
                      if (!_isSearchOpen) {
                        _searchController.clear();
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isSearchOpen
                          ? const Color(0xFF02539A).withOpacity(0.18)
                          : cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isSearchOpen
                            ? const Color(0xFF02539A)
                            : borderColor,
                      ),
                    ),
                    child: Icon(
                      _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                      color: _isSearchOpen ? const Color(0xFF55C7FF) : textMuted,
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar (Shown when search icon clicked)
            if (_isSearchOpen) ...[
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: GoogleFonts.manrope(
                          color: textTitleColor,
                          fontSize: 12.5,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Cari transaksi, nominal, catatan...',
                          hintStyle: GoogleFonts.manrope(
                            color: isDark ? const Color(0xFF6F8197) : const Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      InkWell(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            color: textMuted,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Row 1 Filter: Unified Time Filter Button (Bulan / Tahun / Tanggal / Rentang)
            InkWell(
              onTap: () => _showDateFilterBottomSheet(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasActiveTimeFilter
                        ? const Color(0xFF55C7FF).withOpacity(0.5)
                        : borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedDateRange != null
                          ? Icons.date_range_rounded
                          : _selectedDate != null
                              ? Icons.event_available_rounded
                              : Icons.calendar_month_outlined,
                      color: _hasActiveTimeFilter
                          ? const Color(0xFF55C7FF)
                          : textMuted,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getTimeFilterLabel(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: _hasActiveTimeFilter
                              ? textTitleColor
                              : textMuted,
                          fontSize: 12,
                          fontWeight: _hasActiveTimeFilter
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_hasActiveTimeFilter)
                      GestureDetector(
                        onTap: _resetTimeFilter,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            color: textMuted,
                            size: 16,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: textMuted,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Row 2 Filter: Jenis Transaksi & Dompet
            Row(
              children: [
                // Transaction Type Dropdown
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedType != 'ALL'
                            ? const Color(0xFF55C7FF).withOpacity(0.5)
                            : borderColor,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        dropdownColor: cardBg,
                        isDense: true,
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: textMuted,
                          size: 18,
                        ),
                        style: GoogleFonts.manrope(
                          color: textTitleColor,
                          fontSize: 12,
                          fontWeight: _selectedType != 'ALL'
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'ALL',
                            child: Text('Semua Jenis', style: TextStyle(color: textTitleColor)),
                          ),
                          DropdownMenuItem(
                            value: 'expense',
                            child: Text('Pengeluaran', style: TextStyle(color: textTitleColor)),
                          ),
                          DropdownMenuItem(
                            value: 'income',
                            child: Text('Pemasukan', style: TextStyle(color: textTitleColor)),
                          ),
                          DropdownMenuItem(
                            value: 'transfer',
                            child: Text('Transfer', style: TextStyle(color: textTitleColor)),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedType = v);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Wallet Dropdown
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedWallet != 'ALL'
                            ? const Color(0xFF55C7FF).withOpacity(0.5)
                            : borderColor,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWallet,
                        dropdownColor: cardBg,
                        isDense: true,
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: textMuted,
                          size: 18,
                        ),
                        style: GoogleFonts.manrope(
                          color: textTitleColor,
                          fontSize: 12,
                          fontWeight: _selectedWallet != 'ALL'
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'ALL',
                            child: Text('Semua Dompet', style: TextStyle(color: textTitleColor)),
                          ),
                          ...provider.wallets.map(
                            (w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(
                                w.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: textTitleColor),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedWallet = v);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transaction Records Card (No text "10 transaksi", grouped by date)
            NestedCard(
              title: 'Daftar Transaksi',
              innerPadding: EdgeInsets.zero,
              child: provider.isLoading
                  ? const SkeletonTransactionList(count: 6)
                  : (filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 42),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  color: textMuted,
                                  size: 32,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Tidak ada transaksi yang cocok.',
                                  style: GoogleFonts.manrope(
                                    color: textMuted,
                                    fontSize: 12.5,
                                  ),
                                ),
                                if (hasActiveFilter) ...[
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedType = 'ALL';
                                        _selectedWallet = 'ALL';
                                        _resetTimeFilter();
                                        _searchController.clear();
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1C2432) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: borderColor,
                                        ),
                                      ),
                                      child: Text(
                                        'Reset Semua Filter',
                                        style: GoogleFonts.manrope(
                                          color: const Color(0xFF55C7FF),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : _buildGroupedTransactionList(
                          context: context,
                          filtered: filtered,
                          isDark: isDark,
                          textMuted: textMuted,
                        )),
            ),
          ],
        ),
      ),
    ),
  ],
),
);
  }

  Widget _buildGroupedTransactionList({
    required BuildContext context,
    required List<TransactionModel> filtered,
    required bool isDark,
    required Color textMuted,
  }) {
    // Group transactions by date (Day)
    final Map<DateTime, List<TransactionModel>> grouped = {};
    for (final tx in filtered) {
      final key = DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final currencyFormatter = NumberFormat('#,###', 'id_ID');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < sortedDates.length; i++) ...[
          Builder(
            builder: (_) {
              final date = sortedDates[i];
              final txs = grouped[date]!;

              double dayExpense = 0;
              for (final t in txs) {
                if (t.type == TransactionType.expense) dayExpense += t.amount;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date Group Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF1F5F9),
                      border: Border(
                        top: i > 0
                            ? BorderSide(
                                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                              )
                            : BorderSide.none,
                        bottom: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatDateHeader(date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              color: textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (dayExpense > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '-Rp ${currencyFormatter.format(dayExpense.toInt())}',
                            style: GoogleFonts.interTight(
                              color: isDark ? const Color(0xFFFF7E7E) : const Color(0xFFDC2626),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Transaction items for this date
                  for (int j = 0; j < txs.length; j++) ...[
                    TransactionTile(
                      transaction: txs[j],
                      onTap: () {
                        Navigator.push(
                          context,
                          AddTransactionScreen.route(
                            initialTransaction: txs[j],
                          ),
                        );
                      },
                    ),
                    if (j < txs.length - 1)
                      Divider(
                        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                        height: 1,
                        indent: 68,
                        endIndent: 16,
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }


}

