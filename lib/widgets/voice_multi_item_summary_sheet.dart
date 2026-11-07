import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/category_model.dart';
import '../models/voice_transaction_item.dart';

/// Modal bottom sheet displaying multi-item extracted from voice speech.
/// Allows inline item inspection, editing, deletion, and batch saving.
class VoiceMultiItemSummarySheet extends StatefulWidget {
  final List<VoiceTransactionItem> initialItems;
  final VoidCallback onRetryRecording;
  final void Function(List<VoiceTransactionItem> confirmedItems) onSaveAll;

  const VoiceMultiItemSummarySheet({
    super.key,
    required this.initialItems,
    required this.onRetryRecording,
    required this.onSaveAll,
  });

  static Future<void> show({
    required BuildContext context,
    required List<VoiceTransactionItem> items,
    required VoidCallback onRetryRecording,
    required void Function(List<VoiceTransactionItem> confirmedItems) onSaveAll,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceMultiItemSummarySheet(
        initialItems: items,
        onRetryRecording: onRetryRecording,
        onSaveAll: onSaveAll,
      ),
    );
  }

  @override
  State<VoiceMultiItemSummarySheet> createState() => _VoiceMultiItemSummarySheetState();
}

class _VoiceMultiItemSummarySheetState extends State<VoiceMultiItemSummarySheet> {
  late List<VoiceTransactionItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  double get _totalAmount => _items.fold(0.0, (sum, it) => sum + it.amount);

  String _formatCurrency(double val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }

  void _editItem(int index) async {
    final item = _items[index];
    final updated = await _showEditItemDialog(context, item);
    if (updated != null && mounted) {
      setState(() {
        _items[index] = updated;
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    if (_items.isEmpty && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<VoiceTransactionItem?> _showEditItemDialog(
    BuildContext context,
    VoiceTransactionItem item,
  ) async {
    final titleController = TextEditingController(text: item.title);
    final amountController = TextEditingController(text: item.amount.toInt().toString());
    String selectedCategory = item.suggestedCategory;

    const availableCategories = [
      'Makanan & Minuman',
      'Belanja',
      'Transportasi',
      'Tagihan & Utilitas',
      'Hiburan',
      'Kesehatan',
      'Pendidikan',
      'Lainnya',
    ];

    return showModalBottomSheet<VoiceTransactionItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return SafeArea(
              top: false,
              child: Container(
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
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(dialogCtx).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle pill
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit_note_rounded,
                              size: 19,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Koreksi Transaksi',
                              style: GoogleFonts.interTight(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Inner Form Card (Design System style)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131A26) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title input
                            Text(
                              'Nama Barang / Keterangan',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: titleController,
                              style: GoogleFonts.manrope(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0C131D) : const Color(0xFFF8FAFC),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                                    width: 1.2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Amount input
                            Text(
                              'Nominal Transaksi',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.interTight(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                prefixText: 'Rp ',
                                prefixStyle: GoogleFonts.interTight(
                                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0C131D) : const Color(0xFFF8FAFC),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                                    width: 1.2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Category selector
                            Text(
                              'Kategori',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: availableCategories.map((cat) {
                                final isSelected = selectedCategory == cat;
                                return ChoiceChip(
                                  label: Text(
                                    cat,
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark ? const Color(0xFF0C131D) : Colors.white)
                                          : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF475569)),
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                  backgroundColor: isDark ? const Color(0xFF0C131D) : const Color(0xFFF1F5F9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isSelected
                                          ? Colors.transparent
                                          : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  onSelected: (val) {
                                    if (val) {
                                      setDialogState(() {
                                        selectedCategory = cat;
                                      });
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Save Edit Button (Anti-Slop High Contrast)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                            foregroundColor: isDark ? const Color(0xFF0C131D) : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            final parsedAmount = double.tryParse(amountController.text.replaceAll('.', '')) ?? item.amount;
                            Navigator.of(dialogCtx).pop(
                              item.copyWith(
                                title: titleController.text.trim().isNotEmpty ? titleController.text.trim() : item.title,
                                amount: parsedAmount > 0 ? parsedAmount : item.amount,
                                suggestedCategory: selectedCategory,
                              ),
                            );
                          },
                          child: Text(
                            'Simpan Perubahan',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          bottomInset > 0 ? bottomInset + 12 : (bottomPadding > 0 ? bottomPadding + 8 : 16),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle pill
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.playlist_add_check_rounded,
                  color: Color(0xFF38BDF8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Transaksi Suara',
                      style: GoogleFonts.interTight(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${_items.length} item terdeteksi • Total: ${_formatCurrency(_totalAmount)}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Highlight Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF090E17) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Total Akumulasi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatCurrency(_totalAmount),
                  style: GoogleFonts.interTight(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Instruction Pill
          Text(
            'Ketuk salah satu item untuk mengoreksi nama, nominal, atau kategori.',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: isDark ? const Color(0xFF627D98) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 10),

          // Vertical list of items
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.42,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final it = _items[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('item_card_$index'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _editItem(index),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131A26) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Number Index
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF090E17) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.interTight(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Title and Category
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.title,
                                  style: GoogleFonts.interTight(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0066FF).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    it.suggestedCategory,
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF38BDF8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Amount & Edit Icon
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(it.amount),
                                style: GoogleFonts.interTight(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 13,
                                    color: isDark ? const Color(0xFF627D98) : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Edit',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      color: isDark ? const Color(0xFF627D98) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),

                          // Delete button
                          GestureDetector(
                            onTap: () => _removeItem(index),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: isDark ? const Color(0xFF627D98) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Two Action Buttons: Bicara Ulang & Catat Semua
          Row(
            children: [
              // Bicara Ulang (Outlined)
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    key: const Key('btn_retry_speech'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      side: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.18) : const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onRetryRecording();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      'Ulangi',
                      maxLines: 1,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Catat Semua (Primary)
              Expanded(
                flex: 6,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    key: const Key('btn_save_all_speech'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      foregroundColor: isDark ? const Color(0xFF0C131D) : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _items.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            widget.onSaveAll(_items);
                          },
                    child: Text(
                      'Catat Semua (${_items.length})',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
          ),
        ),
      ),
    );
  }
}
