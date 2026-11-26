import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/nested_card.dart';
import '../widgets/standard_screen_header.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'wallets_screen.dart';

enum _WalletTxFilter { all, income, expense, transfer }

class WalletDetailScreen extends StatefulWidget {
  final String walletId;

  const WalletDetailScreen({
    super.key,
    required this.walletId,
  });

  static Route<void> route(String walletId) {
    return MaterialPageRoute(
      builder: (_) => WalletDetailScreen(walletId: walletId),
    );
  }

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  _WalletTxFilter _filter = _WalletTxFilter.all;

  static const Color _cyan = Color(0xFF55C7FF);
  static const Color _accentOceanic = Color(0xFF02539A);
  static const Color _incomeGreen = Color(0xFF39D98A);
  static const Color _expenseRed = Color(0xFFF43F5E);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();
    final WalletModel? wallet = provider.wallets.cast<WalletModel?>().firstWhere(
          (w) => w?.id == widget.walletId,
          orElse: () => null,
        );

    if (wallet == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1C2229) : const Color(0xFFF4F5F7),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: StandardScreenHeader(
                  title: 'Detail Dompet',
                  showBackButton: true,
                  onBack: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Dompet tidak ditemukan atau telah dihapus.',
                    style: GoogleFonts.manrope(
                      color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final allWalletTxs = provider.getTransactionsForWallet(wallet.id);

    double totalIn = 0.0;
    double totalOut = 0.0;
    for (final tx in allWalletTxs) {
      if (tx.type == TransactionType.income) {
        totalIn += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalOut += tx.amount;
      } else if (tx.type == TransactionType.transfer) {
        if (tx.toWalletId == wallet.id) totalIn += tx.amount;
        if (tx.fromWalletId == wallet.id) totalOut += tx.amount;
      }
    }

    final filteredTxs = allWalletTxs.where((tx) {
      switch (_filter) {
        case _WalletTxFilter.all:
          return true;
        case _WalletTxFilter.income:
          return tx.type == TransactionType.income;
        case _WalletTxFilter.expense:
          return tx.type == TransactionType.expense;
        case _WalletTxFilter.transfer:
          return tx.type == TransactionType.transfer;
      }
    }).toList();

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final accentColor = isDark ? _cyan : _accentOceanic;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C2229) : const Color(0xFFF4F5F7),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: [
            StandardScreenHeader(
              title: wallet.name,
              showBackButton: true,
              onBack: () => Navigator.pop(context),
              actionWidget: InkWell(
                key: const Key('btn_edit_wallet'),
                onTap: () => WalletsScreen.showAddOrEditWalletSheet(
                  context,
                  provider,
                  walletToEdit: wallet,
                  onDeleted: () {
                    if (mounted) Navigator.pop(context);
                  },
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? _accentOceanic.withOpacity(0.25)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? _cyan.withOpacity(0.35)
                          : _accentOceanic.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 15, color: accentColor),
                      const SizedBox(width: 5),
                      Text(
                        'Edit',
                        style: GoogleFonts.manrope(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Wallet Summary Card
            NestedCard(
              title: 'Informasi Dompet',
              action: '${allWalletTxs.length} Transaksi',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF131A26)
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            WalletsScreen.getWalletIcon(wallet.type),
                            color: accentColor,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wallet.name,
                                style: GoogleFonts.interTight(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                wallet.type,
                                style: GoogleFonts.manrope(
                                  color: mutedColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Saldo Saat Ini',
                      style: GoogleFonts.manrope(
                        color: mutedColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.formatCurrency(wallet.balance),
                      style: GoogleFonts.interTight(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0C131D)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Masuk',
                                  style: GoogleFonts.manrope(
                                    color: mutedColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '+ ${provider.formatCurrency(totalIn)}',
                                  style: GoogleFonts.interTight(
                                    color: _incomeGreen,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFE2E8F0),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Keluar',
                                  style: GoogleFonts.manrope(
                                    color: mutedColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '- ${provider.formatCurrency(totalOut)}',
                                  style: GoogleFonts.interTight(
                                    color: _expenseRed,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  AddTransactionScreen.route(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentOceanic,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 17),
                              label: Text(
                                'Catat Transaksi',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  AddTransactionScreen.route(
                                    initialType: TransactionType.transfer,
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.14)
                                      : const Color(0xFFCBD5E1),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(
                                Icons.swap_horiz_rounded,
                                size: 17,
                                color: accentColor,
                              ),
                              label: Text(
                                'Transfer',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
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
            const SizedBox(height: 12),

            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Semua (${allWalletTxs.length})',
                    selected: _filter == _WalletTxFilter.all,
                    isDark: isDark,
                    accentColor: accentColor,
                    onTap: () => setState(() => _filter = _WalletTxFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Pemasukan',
                    selected: _filter == _WalletTxFilter.income,
                    isDark: isDark,
                    accentColor: accentColor,
                    onTap: () =>
                        setState(() => _filter = _WalletTxFilter.income),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Pengeluaran',
                    selected: _filter == _WalletTxFilter.expense,
                    isDark: isDark,
                    accentColor: accentColor,
                    onTap: () =>
                        setState(() => _filter = _WalletTxFilter.expense),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Transfer',
                    selected: _filter == _WalletTxFilter.transfer,
                    isDark: isDark,
                    accentColor: accentColor,
                    onTap: () =>
                        setState(() => _filter = _WalletTxFilter.transfer),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Transactions List
            NestedCard(
              title: 'Riwayat Transaksi Dompet',
              action: '${filteredTxs.length} Item',
              child: filteredTxs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 32,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 36,
                            color: mutedColor.withOpacity(0.65),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Belum ada transaksi pada dompet ini',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              color: textColor,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Transaksi pemasukan, pengeluaran, maupun transfer di ${wallet.name} akan tampil di sini.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              color: mutedColor,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTxs.length,
                      separatorBuilder: (_, __) => Divider(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : const Color(0xFFE2E8F0),
                        height: 1,
                        indent: 68,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final tx = filteredTxs[index];
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
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required bool isDark,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                  ? _accentOceanic.withOpacity(0.35)
                  : const Color(0xFFE0F2FE))
              : (isDark ? const Color(0xFF131A26) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? accentColor
                : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            color: selected
                ? accentColor
                : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF475569)),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
