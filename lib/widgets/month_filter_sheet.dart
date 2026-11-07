import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppMonthFilterPill extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;
  final bool isHeroCard;

  const AppMonthFilterPill({
    super.key,
    required this.selectedDate,
    required this.onTap,
    this.isHeroCard = false,
  });

  static const List<String> shortMonthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = '${shortMonthNames[selectedDate.month - 1]} ${selectedDate.year}';

    if (isHeroCard) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 32,
          padding: const EdgeInsets.only(left: 12, right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
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

    final bgColor = isDark ? const Color(0xFF131A26) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 12, right: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: textColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

Future<DateTime?> showAppMonthFilterSheet({
  required BuildContext context,
  required DateTime initialDate,
  required ValueChanged<DateTime> onSelected,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  int tempYear = initialDate.year;
  int tempMonth = initialDate.month;

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr',
    'Mei', 'Jun', 'Jul', 'Agu',
    'Sep', 'Okt', 'Nov', 'Des',
  ];

  return showModalBottomSheet<DateTime>(
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

                  // Inner Month Grid Card
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
                        // Year selector row
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

                        // Centered "Bulan Ini" Button
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

                  // Bottom Action Buttons
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
                              final result = DateTime(tempYear, tempMonth, 1);
                              onSelected(result);
                              Navigator.pop(sheetCtx, result);
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

