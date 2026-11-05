import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/nested_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const TransactionsScreen({super.key, this.scrollController});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'ALL';
  String _selectedWallet = 'ALL';
  String _selectedMonth = 'ALL';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<({String value, String label})> _getAvailableMonths(
    TransactionProvider provider,
  ) {
    final Map<String, String> map = {};
    final now = DateTime.now();

    for (int i = 0; i < 6; i++) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      final label = '${_monthNames[d.month - 1]} ${d.year}';
      map[key] = label;
    }

    for (final t in provider.transactions) {
      final key =
          '${t.timestamp.year}-${t.timestamp.month.toString().padLeft(2, '0')}';
      final label =
          '${_monthNames[t.timestamp.month - 1]} ${t.timestamp.year}';
      map[key] = label;
    }

    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      (value: 'ALL', label: 'Semua Bulan'),
      ...sortedKeys.map((k) => (value: k, label: map[k]!)),
    ];
  }

  void _showDateFilterBottomSheet(
    BuildContext context,
    List<({String value, String label})> availableMonths,
  ) {
    String tempMonth = _selectedMonth;
    DateTime? tempDate = _selectedDate;
    int activeTab = tempDate != null ? 1 : 0; // 0: Per Bulan, 1: Per Tanggal

    showModalCardSheet(
      context: context,
      title: 'Filter Waktu Transaksi',
      titleIcon: Icons.calendar_today_rounded,
      titleIconColor: const Color(0xFF55C7FF),
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
          final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
          final cardBg = isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9);
          final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented Tab: Per Bulan | Per Tanggal
              Container(
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setSheetState(() => activeTab = 0),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: activeTab == 0 ? const Color(0xFF02539A) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Berdasarkan Bulan',
                            style: GoogleFonts.manrope(
                              color: activeTab == 0 ? Colors.white : mutedColor,
                              fontSize: 12,
                              fontWeight: activeTab == 0 ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () => setSheetState(() => activeTab = 1),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: activeTab == 1 ? const Color(0xFF02539A) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Tanggal Spesifik',
                            style: GoogleFonts.manrope(
                              color: activeTab == 1 ? Colors.white : mutedColor,
                              fontSize: 12,
                              fontWeight: activeTab == 1 ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (activeTab == 0) ...[
                // Month choices chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableMonths.map((m) {
                    final isSelected = tempDate == null && tempMonth == m.value;
                    return InkWell(
                      onTap: () {
                        setSheetState(() {
                          tempMonth = m.value;
                          tempDate = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF55C7FF).withOpacity(0.18)
                              : cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF55C7FF)
                                : borderColor,
                          ),
                        ),
                        child: Text(
                          m.label,
                          style: GoogleFonts.manrope(
                            color: isSelected ? const Color(0xFF55C7FF) : textColor,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                // Inline Calendar Date Picker
                Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: isDark
                        ? const ColorScheme.dark(
                            primary: Color(0xFF2F91E4),
                            onPrimary: Colors.white,
                            surface: Color(0xFF0C131D),
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
                    initialDate: tempDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    onDateChanged: (d) {
                      setSheetState(() {
                        tempDate = d;
                        tempMonth = 'ALL';
                      });
                    },
                  ),
                ),
                if (tempDate != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Dipilih: ${tempDate!.day} ${_monthNames[tempDate!.month - 1]} ${tempDate!.year}',
                        style: GoogleFonts.interTight(
                          color: const Color(0xFF55C7FF),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 18),

              // Action buttons: Reset & Terapkan
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = 'ALL';
                          _selectedDate = null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Reset Waktu',
                        style: GoogleFonts.manrope(
                          color: mutedColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF02539A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = tempMonth;
                          _selectedDate = tempDate;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Terapkan Filter',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final query = _searchController.text.toLowerCase().trim();
    final availableMonths = _getAvailableMonths(provider);

    final hasActiveFilter = _selectedType != 'ALL' ||
        _selectedWallet != 'ALL' ||
        _selectedMonth != 'ALL' ||
        _selectedDate != null ||
        query.isNotEmpty;

    final filtered = provider.transactions.where((t) {
      if (_selectedType != 'ALL' && t.type.name != _selectedType) return false;
      if (_selectedWallet != 'ALL' && t.walletId != _selectedWallet) return false;

      // Filter Bulan (YYYY-MM)
      if (_selectedMonth != 'ALL') {
        final txMonthKey =
            '${t.timestamp.year}-${t.timestamp.month.toString().padLeft(2, '0')}';
        if (txMonthKey != _selectedMonth) return false;
      }

      // Filter Tanggal Spesifik
      if (_selectedDate != null) {
        if (t.timestamp.year != _selectedDate!.year ||
            t.timestamp.month != _selectedDate!.month ||
            t.timestamp.day != _selectedDate!.day) {
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
      body: SafeArea(
        bottom: false,
        child: ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
          children: [
            // Top App Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riwayat Transaksi',
                  style: GoogleFonts.interTight(
                    color: textTitleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasActiveFilter)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedType = 'ALL';
                        _selectedWallet = 'ALL';
                        _selectedMonth = 'ALL';
                        _selectedDate = null;
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
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar
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

            // Row 1 Filter: Unified Time Filter Button (Bulan / Tanggal)
            InkWell(
              onTap: () => _showDateFilterBottomSheet(context, availableMonths),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_selectedDate != null || _selectedMonth != 'ALL')
                        ? const Color(0xFF55C7FF).withOpacity(0.5)
                        : borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedDate != null
                          ? Icons.event_available_rounded
                          : Icons.calendar_month_outlined,
                      color: (_selectedDate != null || _selectedMonth != 'ALL')
                          ? const Color(0xFF55C7FF)
                          : textMuted,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? 'Tanggal: ${_selectedDate!.day} ${_monthNames[_selectedDate!.month - 1].substring(0, 3)} ${_selectedDate!.year}'
                            : (_selectedMonth != 'ALL'
                                ? 'Bulan: ${availableMonths.firstWhere((m) => m.value == _selectedMonth, orElse: () => (value: '', label: _selectedMonth)).label}'
                                : 'Semua Periode (Bulan / Tanggal)'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: (_selectedDate != null || _selectedMonth != 'ALL')
                              ? textTitleColor
                              : textMuted,
                          fontSize: 12,
                          fontWeight: (_selectedDate != null || _selectedMonth != 'ALL')
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_selectedDate != null || _selectedMonth != 'ALL')
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = null;
                            _selectedMonth = 'ALL';
                          });
                        },
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

            // Transaction Records Card
            NestedCard(
              title: 'Daftar Transaksi',
              action: '${filtered.length} transaksi',
              child: filtered.isEmpty
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
                                    _selectedMonth = 'ALL';
                                    _selectedDate = null;
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
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(
                          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                          height: 1,
                          indent: 68,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final tx = filtered[index];
                          return TransactionTile(
                            transaction: tx,
                            onTap: () {
                              Navigator.push(
                                context,
                                AddTransactionScreen.route(
                                  initialTransaction: tx,
                                ),
                              );
                            },
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


}

