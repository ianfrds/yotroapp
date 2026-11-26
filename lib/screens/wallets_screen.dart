import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/wallet_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/thousands_separator_formatter.dart';
import '../widgets/nested_card.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/standard_screen_header.dart';
import 'add_transaction_screen.dart';
import 'wallet_detail_screen.dart';

class WalletsScreen extends StatelessWidget {
  final ScrollController? scrollController;
  final bool isStandalonePage;

  const WalletsScreen({
    super.key,
    this.scrollController,
    this.isStandalonePage = false,
  });

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => const WalletsScreen(isStandalonePage: true),
    );
  }

  static const Color _cyan = Color(0xFF55C7FF);
  static const Color _accentOceanic = Color(0xFF02539A);
  static const Color _danger = Color(0xFFF43F5E);

  static void showAddOrEditWalletSheet(
    BuildContext context,
    TransactionProvider provider, {
    WalletModel? walletToEdit,
    VoidCallback? onDeleted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = walletToEdit != null;
    final nameController = TextEditingController(text: walletToEdit?.name ?? '');

    String normalizeWalletType(String? rawType) {
      if (rawType == null || rawType.trim().isEmpty) return 'Cash';
      final clean = rawType.trim().toLowerCase();
      if (clean == 'cash' || clean == 'tunai' || clean == 'dompet' || clean == 'cash / tunai') {
        return 'Cash';
      }
      if (clean == 'bank account' || clean == 'bank' || clean == 'rekening') {
        return 'Bank Account';
      }
      if (clean == 'e-wallet' || clean == 'ewallet' || clean == 'dompet digital') {
        return 'E-Wallet';
      }
      if (clean == 'savings' || clean == 'tabungan') {
        return 'Savings';
      }
      if (clean == 'other' || clean == 'lainnya') {
        return 'Other';
      }
      return 'Cash';
    }

    final initialFormatted = walletToEdit != null
        ? ThousandsSeparatorInputFormatter.formatNumber(walletToEdit.balance.round().toString())
        : '0';
    final balanceController = TextEditingController(text: initialFormatted);
    String selectedType = normalizeWalletType(walletToEdit?.type);
    bool isSaving = false;
    String? errorMessage;

    showModalCardSheet(
      context: context,
      title: isEditing ? 'Ubah Dompet / Akun' : 'Tambah Dompet / Akun',
      titleIcon: Icons.account_balance_wallet_outlined,
      titleIconColor: isDark ? _cyan : const Color(0xFF02539A),
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Nama Dompet
              Text(
                'Nama Dompet / Akun',
                style: GoogleFonts.manrope(
                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: nameController,
                  style: GoogleFonts.manrope(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Misal: BCA, Dompet Tunai, GoPay',
                    hintStyle: GoogleFonts.manrope(
                      color: isDark ? Colors.white.withOpacity(0.25) : const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Tipe Dompet
              Text(
                'Tipe Akun',
                style: GoogleFonts.manrope(
                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedType,
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF0C131D) : Colors.white,
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      size: 22,
                    ),
                    style: GoogleFonts.manrope(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash / Tunai')),
                      DropdownMenuItem(value: 'Bank Account', child: Text('Bank Account')),
                      DropdownMenuItem(value: 'E-Wallet', child: Text('E-Wallet')),
                      DropdownMenuItem(value: 'Savings', child: Text('Tabungan')),
                      DropdownMenuItem(value: 'Other', child: Text('Lainnya')),
                    ],
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedType = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Saldo Dompet (Default neutral white color for Rp)
              Text(
                isEditing ? 'Saldo Saat Ini' : 'Saldo Awal',
                style: GoogleFonts.manrope(
                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Text(
                      provider.currency == 'IDR' ? 'Rp ' : '\$ ',
                      style: GoogleFonts.interTight(
                        color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF475569),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: balanceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                        style: GoogleFonts.interTight(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: GoogleFonts.interTight(
                            color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFF94A3B8),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    errorMessage!,
                    style: GoogleFonts.manrope(
                      color: _danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              // 5. Tombol Aksi Simpan & Hapus
              Row(
                children: [
                  if (isEditing && provider.wallets.length > 1) ...[
                    InkWell(
                      onTap: isSaving
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _showConfirmDeleteWalletSheet(
                                context,
                                provider,
                                walletToEdit,
                                onDeleted: onDeleted,
                              );
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _danger.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _danger.withOpacity(0.35)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: _danger,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = nameController.text.trim();
                                if (name.isEmpty) {
                                  setSheetState(() => errorMessage = 'Nama dompet tidak boleh kosong');
                                  return;
                                }
                                final cleanBal = balanceController.text
                                    .replaceAll('.', '')
                                    .replaceAll(',', '')
                                    .trim();
                                final parsedBal = cleanBal.isEmpty ? 0.0 : double.tryParse(cleanBal);
                                if (parsedBal == null || parsedBal < 0) {
                                  setSheetState(() => errorMessage = 'Nominal saldo tidak valid');
                                  return;
                                }

                                setSheetState(() {
                                  errorMessage = null;
                                  isSaving = true;
                                });
                                try {
                                  if (isEditing) {
                                    await provider.updateWallet(
                                      id: walletToEdit.id,
                                      name: name,
                                      type: selectedType,
                                      balance: parsedBal,
                                      syncToTransaction: true,
                                    );
                                  } else {
                                    await provider.addWallet(
                                      name: name,
                                      type: selectedType,
                                      initialBalance: parsedBal,
                                      syncToTransaction: true,
                                    );
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } finally {
                                  if (ctx.mounted) setSheetState(() => isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentOceanic,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isEditing ? 'Perbarui Dompet' : 'Simpan Dompet',
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
            ],
          );
        },
      ),
    );
  }

  static void _showConfirmDeleteWalletSheet(
    BuildContext context,
    TransactionProvider provider,
    WalletModel wallet, {
    VoidCallback? onDeleted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    showModalCardSheet(
      context: context,
      title: 'Hapus Dompet',
      titleIcon: Icons.delete_outline_rounded,
      titleIconColor: _danger,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: _danger, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hapus "${wallet.name}"?',
                  style: GoogleFonts.interTight(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Seluruh riwayat transaksi yang terkait dengan dompet ini akan otomatis dialihkan ke dompet lain yang masih aktif.',
            style: GoogleFonts.manrope(
              color: mutedColor,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.manrope(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await provider.deleteWallet(wallet.id);
                      onDeleted?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _danger,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Hapus Dompet',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C2229) : const Color(0xFFF4F5F7),
      floatingActionButton: FloatingActionButton(
        key: const Key('fab_add_wallet'),
        heroTag: null,
        onPressed: () => showAddOrEditWalletSheet(context, provider),
        backgroundColor: _accentOceanic,
        foregroundColor: Colors.white,
        elevation: 3,
        tooltip: 'Tambah Dompet',
        child: const Icon(Icons.add_rounded, size: 26),
      ),
      body: SafeArea(
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(12, 12, 12, isStandalonePage ? 96 : 140),
          children: [
            // Standard Header with back button
            StandardScreenHeader(
              title: 'Dompet & Rekening',
              showBackButton: isStandalonePage,
              onBack: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),

            // 1. Wallets in NestedCard
            NestedCard(
              title: 'Daftar Akun & Dompet',
              action: '${provider.wallets.length} Aktif',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.wallets.length,
                  separatorBuilder: (_, __) => Divider(
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                    height: 1,
                    indent: 68,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final wallet = provider.wallets[index];
                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        WalletDetailScreen.route(wallet.id),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF131A26) : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                getWalletIcon(wallet.type),
                                color: isDark ? _cyan : const Color(0xFF02539A),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wallet.name,
                                    style: GoogleFonts.manrope(
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    wallet.type,
                                    style: GoogleFonts.manrope(
                                      color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              provider.formatCurrency(wallet.balance),
                              style: GoogleFonts.interTight(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: isDark ? const Color(0xFF6F8197) : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Transfer Callout Card (NestedCard)
            NestedCard(
              title: 'Transfer Antar Dompet',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pindahkan saldo antar-rekening',
                            style: GoogleFonts.manrope(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Transfer tidak memengaruhi kalkulasi pemasukan/pengeluaran.',
                            style: GoogleFonts.manrope(
                              color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          AddTransactionScreen.route(initialType: TransactionType.transfer),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentOceanic,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Transfer',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static IconData getWalletIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bank account':
      case 'bank':
        return Icons.account_balance_rounded;
      case 'cash':
      case 'tunai':
      case 'dompet':
        return Icons.payments_rounded;
      case 'e-wallet':
      case 'ewallet':
        return Icons.phone_android_rounded;
      case 'savings':
      case 'tabungan':
        return Icons.savings_rounded;
      default:
        return Icons.payments_rounded;
    }
  }
}
