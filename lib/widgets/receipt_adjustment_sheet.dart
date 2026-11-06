import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/receipt_data_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/thousands_separator_formatter.dart';
import 'app_snackbar.dart';
import 'nested_card.dart';

class ReceiptAdjustmentSheet extends StatefulWidget {
  final ReceiptDataModel receiptData;
  final Function(ReceiptDataModel adjustedData, String walletId) onApproveAndSave;
  final Function(ReceiptDataModel adjustedData, String walletId) onApplyToForm;

  const ReceiptAdjustmentSheet({
    super.key,
    required this.receiptData,
    required this.onApproveAndSave,
    required this.onApplyToForm,
  });

  static Future<void> show(
    BuildContext context, {
    required ReceiptDataModel receiptData,
    required Function(ReceiptDataModel adjustedData, String walletId) onApproveAndSave,
    required Function(ReceiptDataModel adjustedData, String walletId) onApplyToForm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReceiptAdjustmentSheet(
        receiptData: receiptData,
        onApproveAndSave: onApproveAndSave,
        onApplyToForm: onApplyToForm,
      ),
    );
  }

  @override
  State<ReceiptAdjustmentSheet> createState() => _ReceiptAdjustmentSheetState();
}

class _ReceiptAdjustmentSheetState extends State<ReceiptAdjustmentSheet> {
  static const Color _bgCanvas = Color(0xFF1C2229);
  static const Color _surfaceDark = Color(0xFF0C131D);
  static const Color _accentSapphire = Color(0xFF02539A);
  static const Color _cyan = Color(0xFF55C7FF);

  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  late String _selectedCategory;
  late String _selectedWalletId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final data = widget.receiptData;
    final initialFormatted = data.totalAmount > 0
        ? ThousandsSeparatorInputFormatter.formatNumber(data.totalAmount.toStringAsFixed(0))
        : '0';

    _amountController = TextEditingController(text: initialFormatted);
    _merchantController = TextEditingController(text: data.merchantName);
    _selectedCategory = CategoryModel.normalizeCategoryName(data.suggestedCategory);
    _selectedDate = data.date;

    final provider = context.read<TransactionProvider>();
    _selectedWalletId = provider.wallets.isNotEmpty ? provider.wallets.first.id : 'w_bank';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  ReceiptDataModel _getAdjustedData() {
    final rawNumber = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final parsedAmount = double.tryParse(rawNumber) ?? 0.0;
    final merchant = _merchantController.text.trim().isNotEmpty
        ? _merchantController.text.trim()
        : 'Struk Belanja';

    return widget.receiptData.copyWith(
      totalAmount: parsedAmount,
      merchantName: merchant,
      suggestedCategory: _selectedCategory,
      date: _selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: isDark ? _bgCanvas : const Color(0xFFF4F5F7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131A26) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      size: 20,
                      color: _cyan,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hasil Pindai Struk',
                          style: GoogleFonts.interTight(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Verifikasi dan sesuaikan data sebelum dicatat',
                          style: GoogleFonts.manrope(
                            color: textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
            ),

            // Body content
            Expanded(
              child: ListView(
                key: const Key('receipt_adjustment_scroll_view'),
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                children: [
                  // Card 1: Nominal & Alternatif
                  NestedCard(
                    title: 'Total Pembayaran',
                    action: 'IDR',
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Rp ',
                                style: GoogleFonts.interTight(
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  key: const Key('receipt_amount_field'),
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: const [
                                    ThousandsSeparatorInputFormatter(),
                                  ],
                                  style: GoogleFonts.interTight(
                                    color: textColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      color: isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),

                          // Alternative amount chips if detected
                          if (widget.receiptData.alternativeAmounts.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Pilihan nominal lain dari struk:',
                              style: GoogleFonts.manrope(
                                color: textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: widget.receiptData.alternativeAmounts.map((amt) {
                                final formatted = ThousandsSeparatorInputFormatter.formatNumber(
                                  amt.toStringAsFixed(0),
                                );
                                final isCurrent = _amountController.text == formatted;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _amountController.text = formatted;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? _accentSapphire.withOpacity(0.2)
                                          : (isDark ? const Color(0xFF182230) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCurrent
                                            ? _accentSapphire
                                            : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFCBD5E1)),
                                      ),
                                    ),
                                    child: Text(
                                      'Rp $formatted',
                                      style: GoogleFonts.interTight(
                                        color: isCurrent ? (isDark ? _cyan : _accentSapphire) : textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Card 2: Toko / Merchant & Tanggal
                  NestedCard(
                    title: 'Informasi Struk',
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nama Toko / Merchant',
                            style: GoogleFonts.manrope(
                              color: textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF131A26) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.storefront_outlined,
                                  size: 18,
                                  color: textMuted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    key: const Key('receipt_merchant_field'),
                                    controller: _merchantController,
                                    style: GoogleFonts.manrope(
                                      color: textColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      hintText: 'Contoh: Indomaret Point',
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Tanggal Transaksi',
                            style: GoogleFonts.manrope(
                              color: textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 1)),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF131A26) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 16, color: textMuted),
                                  const SizedBox(width: 10),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(_selectedDate),
                                    style: GoogleFonts.manrope(
                                      color: textColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.edit_calendar_rounded, size: 16, color: textMuted),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Card 3: Kategori & Dompet Pembayaran
                  NestedCard(
                    title: 'Kategori & Dompet',
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kategori Pengeluaran',
                            style: GoogleFonts.manrope(
                              color: textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF131A26) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: provider.getCategories(TransactionType.expense).any((c) => c.name == _selectedCategory)
                                    ? _selectedCategory
                                    : (provider.getCategories(TransactionType.expense).isNotEmpty
                                        ? provider.getCategories(TransactionType.expense).first.name
                                        : _selectedCategory),
                                dropdownColor: isDark ? _surfaceDark : Colors.white,
                                items: provider.getCategories(TransactionType.expense).map((cat) {
                                  return DropdownMenuItem<String>(
                                    value: cat.name,
                                    child: Row(
                                      children: [
                                        Text(cat.emoji ?? '🏷️', style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Text(
                                          cat.name,
                                          style: GoogleFonts.manrope(
                                            color: textColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCategory = val);
                                  }
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Sumber Dana / Dompet',
                            style: GoogleFonts.manrope(
                              color: textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF131A26) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: provider.wallets.any((w) => w.id == _selectedWalletId)
                                    ? _selectedWalletId
                                    : (provider.wallets.isNotEmpty ? provider.wallets.first.id : null),
                                dropdownColor: isDark ? _surfaceDark : Colors.white,
                                items: provider.wallets.map((wallet) {
                                  return DropdownMenuItem<String>(
                                    value: wallet.id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          wallet.type == 'bank'
                                              ? Icons.account_balance_rounded
                                              : (wallet.type == 'ewallet'
                                                  ? Icons.smartphone_rounded
                                                  : Icons.wallet_rounded),
                                          size: 16,
                                          color: isDark ? _cyan : _accentSapphire,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            wallet.name,
                                            style: GoogleFonts.manrope(
                                              color: textColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          provider.formatCurrency(wallet.balance),
                                          style: GoogleFonts.interTight(
                                            color: textMuted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedWalletId = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Fixed Bottom Action Row
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + (bottomInset > 0 ? bottomInset : MediaQuery.of(context).padding.bottom),
              ),
              decoration: BoxDecoration(
                color: isDark ? _surfaceDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Secondary: Buka di Form
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        key: const Key('btn_receipt_apply_form'),
                        onPressed: () {
                          final adjusted = _getAdjustedData();
                          Navigator.pop(context);
                          widget.onApplyToForm(adjusted, _selectedWalletId);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Buka di Form',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Primary: Setujui & Simpan
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        key: const Key('btn_receipt_approve_save'),
                        onPressed: () {
                          final adjusted = _getAdjustedData();
                          if (adjusted.totalAmount <= 0) {
                            AppSnackBar.show(
                              context,
                              'Nominal transaksi harus lebih dari 0',
                              type: SnackBarType.danger,
                            );
                            return;
                          }
                          Navigator.pop(context);
                          widget.onApproveAndSave(adjusted, _selectedWalletId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentSapphire,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Setujui & Simpan',
                          style: GoogleFonts.manrope(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
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
  }
}
