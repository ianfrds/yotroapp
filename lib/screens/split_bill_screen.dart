import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/nested_card.dart';
import '../widgets/standard_screen_header.dart';
import '../utils/thousands_separator_formatter.dart';

class SplitBillMember {
  String name;
  bool isMe;
  bool isPaid;

  SplitBillMember({
    required this.name,
    this.isMe = false,
    this.isPaid = false,
  });
}

class SplitBillScreen extends StatefulWidget {
  const SplitBillScreen({super.key});

  static MaterialPageRoute route() {
    return MaterialPageRoute(builder: (_) => const SplitBillScreen());
  }

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  final TextEditingController _billController = TextEditingController();
  final TextEditingController _noteController = TextEditingController(text: 'Makan Bersama');
  final TextEditingController _discountController = TextEditingController();

  int _taxPercent = 10;
  int _tipPercent = 0;
  String _selectedCategory = 'Food & Beverage';
  String? _selectedWalletId;

  final List<SplitBillMember> _members = [
    SplitBillMember(name: 'Kamu', isMe: true, isPaid: true),
    SplitBillMember(name: 'Teman 1', isMe: false, isPaid: false),
    SplitBillMember(name: 'Teman 2', isMe: false, isPaid: false),
  ];

  static const Color _bg = Color(0xFF1C2229);
  static const Color _cyan = Color(0xFF55C7FF);
  static const Color _green = Color(0xFF39D98A);

  @override
  void dispose() {
    _billController.dispose();
    _noteController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  double get _subtotal =>
      ThousandsSeparatorInputFormatter.parseNumber(_billController.text);

  double get _discount =>
      ThousandsSeparatorInputFormatter.parseNumber(_discountController.text);

  double get _taxableAmount => math.max(0.0, _subtotal - _discount);

  double get _taxAmount => _taxableAmount * (_taxPercent / 100.0);

  double get _tipAmount => _taxableAmount * (_tipPercent / 100.0);

  double get _totalBill => math.max(0.0, _taxableAmount + _taxAmount + _tipAmount);

  double get _perPersonShare =>
      _members.isNotEmpty ? (_totalBill / _members.length) : 0.0;

  void _addMember() {
    setState(() {
      _members.add(
        SplitBillMember(
          name: 'Teman ${_members.length}',
          isMe: false,
          isPaid: false,
        ),
      );
    });
  }

  void _removeMember(int index) {
    if (_members.length <= 2) return;
    setState(() {
      _members.removeAt(index);
    });
  }

  void _editMemberName(int index) {
    final controller = TextEditingController(text: _members[index].name);
    showModalCardSheet(
      context: context,
      title: 'Ubah Nama Teman',
      titleIcon: Icons.edit_outlined,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Nama',
              labelStyle: GoogleFonts.manrope(color: const Color(0xFF8EA4BE)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _cyan),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _members[index].name = newName;
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Simpan',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _copySummary() {
    if (_totalBill <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan total tagihan terlebih dahulu.')),
      );
      return;
    }

    final provider = context.read<TransactionProvider>();
    final buffer = StringBuffer();
    final note = _noteController.text.trim().isEmpty ? 'Split Bill' : _noteController.text.trim();

    buffer.writeln('📋 $note');
    buffer.writeln('Total Tagihan: ${provider.formatCurrency(_totalBill)} (${_members.length} orang)');
    if (_discount > 0) buffer.writeln('Diskon: -${provider.formatCurrency(_discount)}');
    if (_taxAmount > 0) buffer.writeln('Pajak ($_taxPercent%): +${provider.formatCurrency(_taxAmount)}');
    if (_tipAmount > 0) buffer.writeln('Service ($_tipPercent%): +${provider.formatCurrency(_tipAmount)}');
    buffer.writeln('Per Orang: ${provider.formatCurrency(_perPersonShare)}');
    buffer.writeln('');
    buffer.writeln('Rincian Pembagian:');
    for (final m in _members) {
      final status = m.isMe ? '(Bagian Saya)' : (m.isPaid ? '✓ Lunas' : 'Belum Bayar');
      buffer.writeln('• ${m.name}: ${provider.formatCurrency(_perPersonShare)} $status');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF131A26),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        content: Text(
          'Ringkasan tagihan disalin ke clipboard!',
          style: GoogleFonts.manrope(color: Colors.white),
        ),
      ),
    );
  }

  void _saveExpenseToTracker() {
    if (_perPersonShare <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal pengeluaran masih Rp 0.')),
      );
      return;
    }

    final provider = context.read<TransactionProvider>();
    final wallets = provider.wallets;
    final walletId = _selectedWalletId ?? (wallets.isNotEmpty ? wallets.first.id : 'w_main');
    final note = _noteController.text.trim().isEmpty ? 'Split Bill' : 'Split Bill: ${_noteController.text.trim()}';

    final category = provider.categories.cast<CategoryModel?>().firstWhere(
          (c) => c?.name == _selectedCategory && c?.type == TransactionType.expense,
          orElse: () => null,
        );
    final categoryId = category?.id ?? 'food';

    provider.addTransaction(
      title: note,
      amount: _perPersonShare,
      type: TransactionType.expense,
      categoryName: _selectedCategory,
      categoryId: categoryId,
      walletId: walletId,
      date: DateTime.now(),
      note: 'Total tagihan ${provider.formatCurrency(_totalBill)} dibagi ${_members.length} orang',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF131A26),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        content: Text(
          'Bagian kamu (${provider.formatCurrency(_perPersonShare)}) berhasil dicatat ke transaksi!',
          style: GoogleFonts.manrope(color: _green, fontWeight: FontWeight.w600),
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();
    final wallets = provider.wallets;
    if (_selectedWalletId == null && wallets.isNotEmpty) {
      _selectedWalletId = wallets.first.id;
    }

    return Scaffold(
      backgroundColor: isDark ? _bg : const Color(0xFFF4F5F7),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
          children: [
            StandardScreenHeader(
              title: 'Split Bill',
              actionWidget: IconButton(
                onPressed: _copySummary,
                icon: Icon(Icons.share_outlined, color: isDark ? _cyan : const Color(0xFF0284C7), size: 20),
                tooltip: 'Salin Ringkasan Tagihan',
              ),
            ),
            const SizedBox(height: 12),

            // Card 1: Detail Tagihan
            NestedCard(
              title: 'Detail Tagihan',
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Catatan / Deskripsi Bill
                    Text(
                      'Nama Tagihan',
                      style: GoogleFonts.manrope(
                        color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _noteController,
                      style: GoogleFonts.manrope(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Misal: Makan Siang Resto A',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white.withOpacity(0.24) : const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? _cyan : const Color(0xFF0284C7)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Total Tagihan Input
                    Text(
                      'Total Tagihan (Subtotal)',
                      style: GoogleFonts.manrope(
                        color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Rp ',
                            style: GoogleFonts.interTight(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _billController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                ThousandsSeparatorInputFormatter(),
                              ],
                              style: GoogleFonts.interTight(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Pajak & Service selector
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pajak',
                                style: GoogleFonts.manrope(
                                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [0, 10, 11].map((pct) {
                                  final isSel = _taxPercent == pct;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: InkWell(
                                        onTap: () => setState(() => _taxPercent = pct),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isSel
                                                ? (isDark ? _cyan.withOpacity(0.2) : const Color(0xFF0F172A))
                                                : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSel
                                                  ? (isDark ? _cyan : const Color(0xFF0F172A))
                                                  : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1)),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$pct%',
                                            style: GoogleFonts.manrope(
                                              color: isSel
                                                  ? (isDark ? _cyan : Colors.white)
                                                  : (isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF64748B)),
                                              fontSize: 11,
                                              fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Service / Tip',
                                style: GoogleFonts.manrope(
                                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [0, 5, 10].map((pct) {
                                  final isSel = _tipPercent == pct;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: InkWell(
                                        onTap: () => setState(() => _tipPercent = pct),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isSel
                                                ? (isDark ? _cyan.withOpacity(0.2) : const Color(0xFF0F172A))
                                                : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSel
                                                  ? (isDark ? _cyan : const Color(0xFF0F172A))
                                                  : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1)),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$pct%',
                                            style: GoogleFonts.manrope(
                                              color: isSel
                                                  ? (isDark ? _cyan : Colors.white)
                                                  : (isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF64748B)),
                                              fontSize: 11,
                                              fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Card 2: Anggota Split Bill
            NestedCard(
              title: 'Anggota Tagihan (${_members.length} Orang)',
              actionWidget: InkWell(
                onTap: _addMember,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, size: 14, color: isDark ? _cyan : const Color(0xFF0284C7)),
                      const SizedBox(width: 4),
                      Text(
                        'Tambah',
                        style: GoogleFonts.manrope(
                          color: isDark ? _cyan : const Color(0xFF0284C7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    for (int i = 0; i < _members.length; i++) ...[
                      if (i > 0)
                        Divider(
                          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                          height: 1,
                          indent: 48,
                        ),
                      _buildMemberRow(provider, i, isDark),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Card 3: Ringkasan Perhitungan
            NestedCard(
              title: 'Ringkasan Biaya',
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal', provider.formatCurrency(_subtotal), isDark: isDark),
                    if (_taxAmount > 0)
                      _buildSummaryRow(
                        'Pajak ($_taxPercent%)',
                        '+${provider.formatCurrency(_taxAmount)}',
                        isDark: isDark,
                      ),
                    if (_tipAmount > 0)
                      _buildSummaryRow(
                        'Service ($_tipPercent%)',
                        '+${provider.formatCurrency(_tipAmount)}',
                        isDark: isDark,
                      ),
                    Divider(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0), height: 16),
                    _buildSummaryRow(
                      'Total Tagihan',
                      provider.formatCurrency(_totalBill),
                      isHighlight: true,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    // Per Orang Pod
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? _cyan.withOpacity(0.08) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? _cyan.withOpacity(0.2) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bagian per Orang',
                                  style: GoogleFonts.manrope(
                                    color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF475569),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_members.length} Orang (Bagi Rata)',
                                  style: GoogleFonts.manrope(
                                    color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              provider.formatCurrency(_perPersonShare),
                              style: GoogleFonts.interTight(
                                color: isDark ? _cyan : const Color(0xFF0284C7),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
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
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copySummary,
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(
                      'Salin Teks',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      side: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _saveExpenseToTracker,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: Text(
                      'Catat Bagian Saya',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? _cyan : const Color(0xFF0F172A),
                      foregroundColor: isDark ? const Color(0xFF09101C) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _buildMemberRow(TransactionProvider provider, int index, bool isDark) {
    final member = _members[index];
    final isMe = member.isMe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isMe
                  ? (isDark ? _cyan.withOpacity(0.18) : const Color(0xFFE0F2FE))
                  : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9)),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isMe
                ? Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: isDark ? _cyan : const Color(0xFF0284C7),
                  )
                : Text(
                    index <= 9 ? '$index' : '#',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 10),

          // Name
          Expanded(
            child: InkWell(
              onTap: () => _editMemberName(index),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit_outlined,
                      size: 13,
                      color: isDark ? Colors.white.withOpacity(0.3) : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Share Amount
          Text(
            provider.formatCurrency(_perPersonShare),
            style: GoogleFonts.interTight(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),

          // Paid Toggle Chip
          if (!isMe)
            InkWell(
              onTap: () {
                setState(() {
                  member.isPaid = !member.isPaid;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: member.isPaid
                      ? _green.withOpacity(0.15)
                      : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: member.isPaid
                        ? _green
                        : (isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFCBD5E1)),
                  ),
                ),
                child: Text(
                  member.isPaid ? 'Lunas' : 'Belum',
                  style: GoogleFonts.manrope(
                    color: member.isPaid ? _green : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B)),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Delete Member (only if not me and > 2 members)
          if (!isMe && _members.length > 2)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 16,
                color: isDark ? Colors.white.withOpacity(0.35) : const Color(0xFF94A3B8),
              ),
              padding: const EdgeInsets.only(left: 6),
              constraints: const BoxConstraints(),
              onPressed: () => _removeMember(index),
              tooltip: 'Hapus Teman',
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false, bool isDark = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              color: isHighlight
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B)),
              fontSize: isHighlight ? 13 : 12,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.interTight(
              color: isHighlight
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF334155)),
              fontSize: isHighlight ? 14 : 12.5,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
