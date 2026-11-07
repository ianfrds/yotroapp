import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/nested_card.dart';
import '../widgets/standard_screen_header.dart';
import '../utils/thousands_separator_formatter.dart';

enum SplitMode {
  equal,   // Bagi Rata
  custom,  // Bagi Kustom
  itemized // Bagi Per Item
}

class SplitBillItem {
  String id;
  String name;
  double price;
  int quantity;
  Set<int> assignedMemberIndices;

  SplitBillItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    Set<int>? assignedMemberIndices,
  }) : assignedMemberIndices = assignedMemberIndices ?? {};

  double get totalPrice => price * quantity;
}

class SplitBillMember {
  String name;
  bool isMe;
  bool isPaid;
  double customAmount;
  TextEditingController? customController;

  SplitBillMember({
    required this.name,
    this.isMe = false,
    this.isPaid = false,
    this.customAmount = 0.0,
  }) {
    customController = TextEditingController(
      text: customAmount > 0
          ? ThousandsSeparatorInputFormatter.formatNumber(customAmount.round().toString())
          : '',
    );
  }

  void dispose() {
    customController?.dispose();
  }
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
  SplitMode _splitMode = SplitMode.equal;

  final TextEditingController _billController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();

  // Tax configuration
  bool _isTaxEnabled = true;
  double _taxPercent = 10.0;
  bool _isTaxCustom = false;
  bool _taxIsPercent = true;
  double _customTaxAmount = 0.0;

  // Service / Tip configuration
  bool _isServiceEnabled = false;
  double _servicePercent = 5.0;
  bool _isServiceCustom = false;
  bool _serviceIsPercent = true;
  double _customServiceAmount = 0.0;

  String _selectedCategory = 'Makanan & Minuman';
  String? _selectedWalletId;

  late List<SplitBillMember> _members;
  final List<SplitBillItem> _items = [];

  static const Color _bg = Color(0xFF1C2229);
  static const Color _cyan = Color(0xFF55C7FF);
  static const Color _green = Color(0xFF39D98A);
  static const Color _bluePrimary = Color(0xFF02539A);

  @override
  void initState() {
    super.initState();
    _members = [
      SplitBillMember(name: 'Kamu', isMe: true, isPaid: true),
      SplitBillMember(name: 'Teman 1', isMe: false, isPaid: false),
      SplitBillMember(name: 'Teman 2', isMe: false, isPaid: false),
    ];
  }

  @override
  void dispose() {
    _billController.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    _discountController.dispose();
    for (final m in _members) {
      m.dispose();
    }
    super.dispose();
  }

  double get _subtotal {
    if (_splitMode == SplitMode.itemized) {
      return _items.fold(0.0, (sum, it) => sum + it.totalPrice);
    }
    return ThousandsSeparatorInputFormatter.parseNumber(_billController.text);
  }

  double get _discount =>
      ThousandsSeparatorInputFormatter.parseNumber(_discountController.text);

  double get _taxableAmount => math.max(0.0, _subtotal - _discount);

  double get _taxAmount {
    if (!_isTaxEnabled) return 0.0;
    if (_taxIsPercent) {
      return _taxableAmount * (_taxPercent / 100.0);
    }
    return _customTaxAmount;
  }

  double get _serviceAmount {
    if (!_isServiceEnabled) return 0.0;
    if (_serviceIsPercent) {
      return _taxableAmount * (_servicePercent / 100.0);
    }
    return _customServiceAmount;
  }

  double get _totalBill => math.max(0.0, _taxableAmount + _taxAmount + _serviceAmount);

  double get _allocatedCustomTotal =>
      _members.fold(0.0, (sum, m) => sum + m.customAmount);

  double get _unallocatedAmount => math.max(0.0, _totalBill - _allocatedCustomTotal);

  /// Calculate share for each member
  double _calculateMemberShare(int index) {
    if (_totalBill <= 0 || _members.isEmpty) return 0.0;

    switch (_splitMode) {
      case SplitMode.equal:
        return _totalBill / _members.length;

      case SplitMode.custom:
        return _members[index].customAmount;

      case SplitMode.itemized:
        if (_items.isEmpty || _subtotal <= 0) {
          return _totalBill / _members.length;
        }
        // Sum items ordered by this member
        double memberItemSubtotal = 0.0;
        for (final item in _items) {
          if (item.assignedMemberIndices.contains(index)) {
            final shareCount = item.assignedMemberIndices.length;
            if (shareCount > 0) {
              memberItemSubtotal += item.totalPrice / shareCount;
            }
          }
        }
        // Add proportional tax and service
        final ratio = _subtotal > 0 ? (memberItemSubtotal / _subtotal) : 0.0;
        final memberTax = _taxAmount * ratio;
        final memberService = _serviceAmount * ratio;
        return memberItemSubtotal + memberTax + memberService;
    }
  }

  double get _myShare {
    final meIndex = _members.indexWhere((m) => m.isMe);
    if (meIndex == -1) return 0.0;
    return _calculateMemberShare(meIndex);
  }

  void _addMember() {
    FocusScope.of(context).unfocus();
    _noteFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
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
      final removed = _members.removeAt(index);
      removed.dispose();
      // Also update item assignments in itemized mode
      for (final item in _items) {
        item.assignedMemberIndices.remove(index);
        // Shift higher indices
        final updated = <int>{};
        for (final idx in item.assignedMemberIndices) {
          if (idx > index) {
            updated.add(idx - 1);
          } else {
            updated.add(idx);
          }
        }
        item.assignedMemberIndices = updated;
      }
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
                borderSide: const BorderSide(color: _bluePrimary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  setState(() {
                    _members[index].name = newName;
                  });
                }
                FocusScope.of(context).unfocus();
                _noteFocusNode.unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _bluePrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Simpan',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _distributeRemainderEqually() {
    if (_totalBill <= 0) return;
    final unallocated = _unallocatedAmount;
    if (unallocated <= 0) return;

    final perPerson = unallocated / _members.length;
    setState(() {
      for (final m in _members) {
        m.customAmount += perPerson;
        m.customController?.text =
            ThousandsSeparatorInputFormatter.formatNumber(m.customAmount.round().toString());
      }
    });
  }

  void _showAddOrEditItemSheet({SplitBillItem? itemToEdit, int? editIndex}) {
    final isEditing = itemToEdit != null;
    final nameCtrl = TextEditingController(text: itemToEdit?.name ?? '');
    final priceCtrl = TextEditingController(
      text: itemToEdit != null
          ? ThousandsSeparatorInputFormatter.formatNumber(itemToEdit.price.round().toString())
          : '',
    );
    int qty = itemToEdit?.quantity ?? 1;
    final Set<int> selectedMembers = itemToEdit != null
        ? Set<int>.from(itemToEdit.assignedMemberIndices)
        : Set<int>.from(List.generate(_members.length, (i) => i));

    showModalCardSheet(
      context: context,
      title: isEditing ? 'Ubah Item Pesanan' : 'Tambah Item Pesanan',
      titleIcon: Icons.restaurant_menu_rounded,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nama Item / Menu',
                style: GoogleFonts.manrope(
                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: nameCtrl,
                  autofocus: !isEditing,
                  textAlignVertical: TextAlignVertical.center,
                  style: GoogleFonts.manrope(color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Misal: Nasi Goreng Spesial',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: _bluePrimary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Harga Satuan',
                          style: GoogleFonts.manrope(
                            color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Rp',
                                style: GoogleFonts.interTight(
                                  color: const Color(0xFF8EA4BE),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: priceCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                                  textAlignVertical: TextAlignVertical.center,
                                  onChanged: (_) => setSheetState(() {}),
                                  style: GoogleFonts.interTight(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: '0',
                                    hintStyle: GoogleFonts.interTight(
                                      color: Colors.white.withOpacity(0.25),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
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
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jumlah / Qty',
                          style: GoogleFonts.manrope(
                            color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () {
                                  if (qty > 1) {
                                    setSheetState(() => qty--);
                                  }
                                },
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                child: Container(
                                  width: 40,
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.remove_rounded,
                                    color: qty > 1 ? Colors.white : Colors.white24,
                                    size: 18,
                                  ),
                                ),
                              ),
                              Text(
                                '$qty',
                                style: GoogleFonts.interTight(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              InkWell(
                                onTap: () => setSheetState(() => qty++),
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                                child: Container(
                                  width: 40,
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
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
              Builder(
                builder: (_) {
                  final unitPrice = ThousandsSeparatorInputFormatter.parseNumber(priceCtrl.text);
                  if (qty > 1 && unitPrice > 0) {
                    final subtotal = unitPrice * qty;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total Item: Rp ${ThousandsSeparatorInputFormatter.formatNumber(subtotal.round().toString())}',
                          style: GoogleFonts.interTight(
                            color: _cyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 14),

              // Member assignment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dipesan Oleh:',
                    style: GoogleFonts.manrope(
                      color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setSheetState(() {
                        if (selectedMembers.length == _members.length) {
                          selectedMembers.clear();
                        } else {
                          selectedMembers.addAll(List.generate(_members.length, (i) => i));
                        }
                      });
                    },
                    child: Text(
                      selectedMembers.length == _members.length ? 'Hapus Semua' : 'Pilih Semua',
                      style: GoogleFonts.manrope(
                        color: _cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(_members.length, (idx) {
                  final m = _members[idx];
                  final isAssigned = selectedMembers.contains(idx);
                  return FilterChip(
                    label: Text(m.name),
                    selected: isAssigned,
                    onSelected: (val) {
                      setSheetState(() {
                        if (val) {
                          selectedMembers.add(idx);
                        } else {
                          selectedMembers.remove(idx);
                        }
                      });
                    },
                    selectedColor: _bluePrimary.withOpacity(0.25),
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    labelStyle: GoogleFonts.manrope(
                      color: isAssigned ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: isAssigned ? FontWeight.w600 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isAssigned ? _bluePrimary : Colors.white.withOpacity(0.1),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),

              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final price = ThousandsSeparatorInputFormatter.parseNumber(priceCtrl.text);
                    if (name.isEmpty || price <= 0 || selectedMembers.isEmpty) {
                      AppSnackBar.show(ctx, 'Isi nama item, harga, dan pilih minimal 1 anggota', type: SnackBarType.warning);
                      return;
                    }

                    setState(() {
                      if (isEditing && editIndex != null) {
                        _items[editIndex] = SplitBillItem(
                          id: itemToEdit.id,
                          name: name,
                          price: price,
                          quantity: qty,
                          assignedMemberIndices: selectedMembers,
                        );
                      } else {
                        _items.add(
                          SplitBillItem(
                            id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            price: price,
                            quantity: qty,
                            assignedMemberIndices: selectedMembers,
                          ),
                        );
                      }
                    });
                    FocusScope.of(ctx).unfocus();
                    _noteFocusNode.unfocus();
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _bluePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    isEditing ? 'Perbarui Item' : 'Simpan Item',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCustomTaxOrTipSheet({required bool isTax}) {
    final title = isTax ? 'Atur Pajak Kustom' : 'Atur Service / Tip Kustom';
    bool isPercent = isTax ? _taxIsPercent : _serviceIsPercent;
    final currentVal = isTax
        ? (isPercent ? _taxPercent : _customTaxAmount)
        : (isPercent ? _servicePercent : _customServiceAmount);

    final ctrl = TextEditingController(
      text: isPercent
          ? (currentVal % 1 == 0 ? currentVal.toInt().toString() : currentVal.toString())
          : ThousandsSeparatorInputFormatter.formatNumber(currentVal.round().toString()),
    );

    showModalCardSheet(
      context: context,
      title: title,
      titleIcon: Icons.tune_rounded,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segment: Persen vs Nominal
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setSheetState(() {
                          isPercent = true;
                          ctrl.text = '10';
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isPercent
                              ? (isDark ? _bluePrimary : const Color(0xFF0F172A))
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Persentase (%)',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: isPercent ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setSheetState(() {
                          isPercent = false;
                          ctrl.text = '10.000';
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !isPercent
                              ? (isDark ? _bluePrimary : const Color(0xFF0F172A))
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Nominal Tetap (Rp)',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: !isPercent ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                isPercent ? 'Nilai Persentase (%)' : 'Nominal Biaya (Rp)',
                style: GoogleFonts.manrope(
                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Text(
                      isPercent ? '% ' : 'Rp ',
                      style: GoogleFonts.interTight(color: Colors.white70, fontSize: 16),
                    ),
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: isPercent
                            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                            : [ThousandsSeparatorInputFormatter()],
                        style: GoogleFonts.interTight(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    final clean = ctrl.text.replaceAll('.', '').trim();
                    final parsed = double.tryParse(clean) ?? 0.0;
                    setState(() {
                      if (isTax) {
                        _isTaxEnabled = true;
                        _isTaxCustom = true;
                        _taxIsPercent = isPercent;
                        if (isPercent) {
                          _taxPercent = parsed;
                        } else {
                          _customTaxAmount = parsed;
                        }
                      } else {
                        _isServiceEnabled = true;
                        _isServiceCustom = true;
                        _serviceIsPercent = isPercent;
                        if (isPercent) {
                          _servicePercent = parsed;
                        } else {
                          _customServiceAmount = parsed;
                        }
                      }
                    });
                    FocusScope.of(ctx).unfocus();
                    _noteFocusNode.unfocus();
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _bluePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Terapkan',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _copySummary() {
    if (_noteController.text.trim().isEmpty) {
      AppSnackBar.show(context, 'Nama tagihan wajib diisi terlebih dahulu.', type: SnackBarType.warning);
      return;
    }
    if (_totalBill <= 0) {
      AppSnackBar.show(context, 'Masukkan total tagihan terlebih dahulu.', type: SnackBarType.warning);
      return;
    }

    final provider = context.read<TransactionProvider>();
    final buffer = StringBuffer();
    final note = _noteController.text.trim().isEmpty ? 'Split Bill' : _noteController.text.trim();

    buffer.writeln('📋 $note');
    buffer.writeln('Mode: ${_splitMode == SplitMode.equal ? "Bagi Rata" : (_splitMode == SplitMode.itemized ? "Per Item" : "Bagi Kustom")}');
    buffer.writeln('Total Tagihan: ${provider.formatCurrency(_totalBill)} (${_members.length} orang)');
    if (_discount > 0) buffer.writeln('Diskon: -${provider.formatCurrency(_discount)}');
    if (_isTaxEnabled && _taxAmount > 0) {
      buffer.writeln('Pajak (${_taxIsPercent ? "$_taxPercent%" : "Kustom"}): +${provider.formatCurrency(_taxAmount)}');
    }
    if (_isServiceEnabled && _serviceAmount > 0) {
      buffer.writeln('Service (${_serviceIsPercent ? "$_servicePercent%" : "Kustom"}): +${provider.formatCurrency(_serviceAmount)}');
    }

    if (_splitMode == SplitMode.itemized && _items.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Item Pesanan:');
      for (final it in _items) {
        final names = it.assignedMemberIndices.map((i) => _members[i].name).join(', ');
        buffer.writeln('• ${it.name} (x${it.quantity}) - ${provider.formatCurrency(it.totalPrice)} ($names)');
      }
    }

    buffer.writeln('');
    buffer.writeln('Rincian Pembagian:');
    for (int i = 0; i < _members.length; i++) {
      final m = _members[i];
      final share = _calculateMemberShare(i);
      final status = m.isMe ? '(Bagian Saya)' : (m.isPaid ? '✓ Lunas' : 'Belum Bayar');
      buffer.writeln('• ${m.name}: ${provider.formatCurrency(share)} $status');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    AppSnackBar.show(context, 'Ringkasan tagihan disalin ke clipboard!', type: SnackBarType.success);
  }

  void _saveExpenseToTracker() {
    if (_noteController.text.trim().isEmpty) {
      AppSnackBar.show(context, 'Nama tagihan wajib diisi terlebih dahulu.', type: SnackBarType.warning);
      return;
    }
    final myShare = _myShare;
    if (myShare <= 0) {
      AppSnackBar.show(context, 'Nominal pengeluaran masih Rp 0.', type: SnackBarType.warning);
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
      amount: myShare,
      type: TransactionType.expense,
      categoryName: _selectedCategory,
      categoryId: categoryId,
      walletId: walletId,
      date: DateTime.now(),
      note: 'Total tagihan ${provider.formatCurrency(_totalBill)} (${_splitMode == SplitMode.equal ? "Bagi Rata" : (_splitMode == SplitMode.itemized ? "Per Item" : "Kustom")})',
    );

    AppSnackBar.show(
      context,
      'Bagian kamu (${provider.formatCurrency(myShare)}) berhasil dicatat ke transaksi!',
      type: SnackBarType.success,
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

            // Mode Selector Pill
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131A26) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  _buildModeTab('Bagi Rata', SplitMode.equal, isDark),
                  _buildModeTab('Bagi Kustom', SplitMode.custom, isDark),
                  _buildModeTab('Per Item', SplitMode.itemized, isDark),
                ],
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
                      focusNode: _noteFocusNode,
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

                    // Subtotal input (Hidden or auto-computed in itemized mode)
                    if (_splitMode != SplitMode.itemized) ...[
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
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
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
                                    'Subtotal Pesanan',
                                    style: GoogleFonts.manrope(
                                      color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                      fontSize: 11.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${_items.length} item dimasukkan',
                                    style: GoogleFonts.manrope(
                                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                                      fontSize: 10.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                provider.formatCurrency(_subtotal),
                                style: GoogleFonts.interTight(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Card 2: Pajak & Service Tip (Toggleable & Custom)
            NestedCard(
              title: 'Pajak & Service Tip',
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    // Pajak Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.receipt_rounded, size: 16, color: isDark ? _cyan : const Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Text(
                                'Pajak',
                                style: GoogleFonts.manrope(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_isTaxEnabled && _taxAmount > 0) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '+${provider.formatCurrency(_taxAmount)}',
                                    style: GoogleFonts.interTight(
                                      color: const Color(0xFFEF4444),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _isTaxEnabled,
                            onChanged: (val) => setState(() => _isTaxEnabled = val),
                            activeColor: _bluePrimary,
                          ),
                        ),
                      ],
                    ),

                    if (_isTaxEnabled) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTaxChip(label: '10%', isSelected: !_isTaxCustom && _taxIsPercent && _taxPercent == 10, onTap: () {
                            setState(() {
                              _isTaxCustom = false;
                              _taxIsPercent = true;
                              _taxPercent = 10;
                            });
                          }, isDark: isDark),
                          const SizedBox(width: 6),
                          _buildTaxChip(label: '11%', isSelected: !_isTaxCustom && _taxIsPercent && _taxPercent == 11, onTap: () {
                            setState(() {
                              _isTaxCustom = false;
                              _taxIsPercent = true;
                              _taxPercent = 11;
                            });
                          }, isDark: isDark),
                          const SizedBox(width: 6),
                          _buildTaxChip(label: '12%', isSelected: !_isTaxCustom && _taxIsPercent && _taxPercent == 12, onTap: () {
                            setState(() {
                              _isTaxCustom = false;
                              _taxIsPercent = true;
                              _taxPercent = 12;
                            });
                          }, isDark: isDark),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildTaxChip(
                              label: _isTaxCustom
                                  ? (_taxIsPercent ? '${_taxPercent}%' : provider.formatCurrency(_customTaxAmount))
                                  : 'Kustom...',
                              isSelected: _isTaxCustom,
                              onTap: () => _showCustomTaxOrTipSheet(isTax: true),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],

                    Divider(
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                      height: 24,
                    ),

                    // Service / Tip Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.room_service_rounded, size: 16, color: isDark ? _green : const Color(0xFF16A34A)),
                              const SizedBox(width: 8),
                              Text(
                                'Service / Tip',
                                style: GoogleFonts.manrope(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_isServiceEnabled && _serviceAmount > 0) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '+${provider.formatCurrency(_serviceAmount)}',
                                    style: GoogleFonts.interTight(
                                      color: isDark ? _cyan : const Color(0xFF0284C7),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _isServiceEnabled,
                            onChanged: (val) => setState(() => _isServiceEnabled = val),
                            activeColor: _bluePrimary,
                          ),
                        ),
                      ],
                    ),

                    if (_isServiceEnabled) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTaxChip(label: '5%', isSelected: !_isServiceCustom && _serviceIsPercent && _servicePercent == 5, onTap: () {
                            setState(() {
                              _isServiceCustom = false;
                              _serviceIsPercent = true;
                              _servicePercent = 5;
                            });
                          }, isDark: isDark),
                          const SizedBox(width: 6),
                          _buildTaxChip(label: '10%', isSelected: !_isServiceCustom && _serviceIsPercent && _servicePercent == 10, onTap: () {
                            setState(() {
                              _isServiceCustom = false;
                              _serviceIsPercent = true;
                              _servicePercent = 10;
                            });
                          }, isDark: isDark),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildTaxChip(
                              label: _isServiceCustom
                                  ? (_serviceIsPercent ? '${_servicePercent}%' : provider.formatCurrency(_customServiceAmount))
                                  : 'Kustom...',
                              isSelected: _isServiceCustom,
                              onTap: () => _showCustomTaxOrTipSheet(isTax: false),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Card 3: Daftar Item Pesanan (Itemized mode only)
            if (_splitMode == SplitMode.itemized) ...[
              NestedCard(
                title: 'Item Pesanan (${_items.length})',
                actionWidget: InkWell(
                  onTap: () => _showAddOrEditItemSheet(),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 15, color: isDark ? _cyan : const Color(0xFF0284C7)),
                        const SizedBox(width: 4),
                        Text(
                          'Tambah Item',
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
                  child: _items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.fastfood_outlined, size: 32, color: isDark ? const Color(0xFF6F8197) : const Color(0xFF94A3B8)),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada item pesanan',
                                  style: GoogleFonts.manrope(color: isDark ? Colors.white70 : const Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Masukkan menu yang dipesan untuk membagi per orang.',
                                  style: GoogleFonts.manrope(color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B), fontSize: 11),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddOrEditItemSheet(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _bluePrimary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 15),
                                  label: Text('Tambah Item Pertama', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => Divider(
                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                            height: 16,
                          ),
                          itemBuilder: (ctx, i) {
                            final it = _items[i];
                            final assignedNames = it.assignedMemberIndices.map((idx) => _members[idx].name).join(', ');
                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              it.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.manrope(
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (it.quantity > 1) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'x${it.quantity}',
                                                style: GoogleFonts.interTight(fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Oleh: $assignedNames',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.manrope(
                                          color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  provider.formatCurrency(it.totalPrice),
                                  style: GoogleFonts.interTight(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 15),
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  onPressed: () => _showAddOrEditItemSheet(itemToEdit: it, editIndex: i),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                  color: const Color(0xFFEF4444),
                                  onPressed: () => setState(() => _items.removeAt(i)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Card 4: Anggota Split Bill
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
                    if (_splitMode == SplitMode.custom && _totalBill > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _unallocatedAmount > 0
                              ? const Color(0xFFF59E0B).withOpacity(0.12)
                              : _green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _unallocatedAmount > 0
                                ? const Color(0xFFF59E0B).withOpacity(0.3)
                                : _green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _unallocatedAmount > 0
                                    ? 'Sisa belum dialokasikan: ${provider.formatCurrency(_unallocatedAmount)}'
                                    : 'Semua tagihan sudah teralokasi pas!',
                                style: GoogleFonts.manrope(
                                  color: _unallocatedAmount > 0 ? const Color(0xFFF59E0B) : _green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_unallocatedAmount > 0)
                              InkWell(
                                onTap: _distributeRemainderEqually,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Bagi Sisa Rata',
                                    style: GoogleFonts.manrope(
                                      color: Colors.black,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

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

            // Card 5: Ringkasan Biaya
            NestedCard(
              title: 'Ringkasan Biaya',
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal', provider.formatCurrency(_subtotal), isDark: isDark),
                    if (_discount > 0)
                      _buildSummaryRow('Diskon', '-${provider.formatCurrency(_discount)}', isDark: isDark),
                    if (_isTaxEnabled && _taxAmount > 0)
                      _buildSummaryRow(
                        'Pajak (${_taxIsPercent ? "$_taxPercent%" : "Kustom"})',
                        '+${provider.formatCurrency(_taxAmount)}',
                        isDark: isDark,
                      ),
                    if (_isServiceEnabled && _serviceAmount > 0)
                      _buildSummaryRow(
                        'Service / Tip (${_serviceIsPercent ? "$_servicePercent%" : "Kustom"})',
                        '+${provider.formatCurrency(_serviceAmount)}',
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

                    // Bagian Per Orang Pod
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? _bluePrimary.withOpacity(0.1) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? _bluePrimary.withOpacity(0.25) : const Color(0xFFCBD5E1),
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
                                  _splitMode == SplitMode.equal ? 'Bagian per Orang' : 'Bagian Kamu',
                                  style: GoogleFonts.manrope(
                                    color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF475569),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _splitMode == SplitMode.equal
                                      ? '${_members.length} Orang (Bagi Rata)'
                                      : (_splitMode == SplitMode.itemized ? 'Berdasarkan Item Pesanan' : 'Alokasi Kustom'),
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
                              provider.formatCurrency(_myShare),
                              style: GoogleFonts.interTight(
                                color: isDark ? _cyan : const Color(0xFF0066FF),
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
            const SizedBox(height: 18),

            // Standardized Action Buttons
            Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _copySummary,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      side: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.copy_rounded, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saveExpenseToTracker,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: Text(
                        'Catat Bagian Saya',
                        style: GoogleFonts.manrope(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _bluePrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
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

  Widget _buildModeTab(String label, SplitMode mode, bool isDark) {
    final isSelected = _splitMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _splitMode = mode),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? _bluePrimary : const Color(0xFF0F172A))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B)),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaxChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? _bluePrimary.withOpacity(0.25) : const Color(0xFF0F172A))
              : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? _bluePrimary : const Color(0xFF0F172A))
                : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1)),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.manrope(
            color: isSelected
                ? (isDark ? _cyan : Colors.white)
                : (isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF64748B)),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildMemberRow(TransactionProvider provider, int index, bool isDark) {
    final member = _members[index];
    final isMe = member.isMe;
    final share = _calculateMemberShare(index);

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
                  ? (isDark ? _bluePrimary.withOpacity(0.2) : const Color(0xFFE0F2FE))
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

          // Share Display or Custom Input
          if (_splitMode == SplitMode.custom) ...[
            SizedBox(
              width: 100,
              height: 34,
              child: TextField(
                controller: member.customController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                style: GoogleFonts.interTight(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B), fontSize: 11),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _bluePrimary),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    member.customAmount = ThousandsSeparatorInputFormatter.parseNumber(val);
                  });
                },
              ),
            ),
          ] else ...[
            Text(
              provider.formatCurrency(share),
              style: GoogleFonts.interTight(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
