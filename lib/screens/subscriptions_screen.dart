import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/subscription_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/ambient_top_glow.dart';
import '../widgets/modal_card_sheet.dart';
import '../widgets/nested_card.dart';
import '../widgets/standard_screen_header.dart';
import '../widgets/add_subscription_sheet.dart';

enum SubscriptionFilterTab { all, unpaid, paid }

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const SubscriptionsScreen());
  }

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  SubscriptionFilterTab _currentTab = SubscriptionFilterTab.all;

  void _showPaymentConfirmationDialog(
    BuildContext context,
    SubscriptionModel sub,
    TransactionProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedWalletId = sub.walletId.isNotEmpty &&
            provider.wallets.any((w) => w.id == sub.walletId)
        ? sub.walletId
        : (provider.wallets.isNotEmpty ? provider.wallets.first.id : '');
    DateTime selectedDate = DateTime.now();
    bool isPaying = false;

    showModalCardSheet(
      context: context,
      title: 'Bayar Tagihan',
      titleIcon: Icons.payments_outlined,
      titleIconColor: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
      child: StatefulBuilder(
        builder: (ctx, setDialogState) {
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
          final labelColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
          final inputBg = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9);
          final inputBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary Pod
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131A26) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: inputBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF02539A).withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF02539A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub.name,
                            style: GoogleFonts.manrope(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub.categoryName,
                            style: GoogleFonts.manrope(
                              color: labelColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      provider.formatCurrency(sub.amount),
                      style: GoogleFonts.interTight(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Pilih Dompet Sumber Pembayaran
              Text(
                'Bayar Menggunakan Dompet',
                style: GoogleFonts.manrope(
                  color: labelColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: inputBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedWalletId.isNotEmpty ? selectedWalletId : null,
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF131A26) : Colors.white,
                    items: provider.wallets.map((w) {
                      return DropdownMenuItem<String>(
                        value: w.id,
                        child: Row(
                          children: [
                            Text(
                              w.name,
                              style: GoogleFonts.manrope(
                                color: textColor,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              provider.formatCurrency(w.balance),
                              style: GoogleFonts.interTight(
                                color: labelColor,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedWalletId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Tombol Konfirmasi Pembayaran
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02539A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isPaying
                      ? null
                      : () async {
                          if (selectedWalletId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pilih dompet pembayaran.')),
                            );
                            return;
                          }
                          setDialogState(() => isPaying = true);
                          try {
                            await provider.paySubscription(
                              sub.id,
                              walletId: selectedWalletId,
                              date: selectedDate,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Tagihan ${sub.name} berhasil dibayar & dicatat ke transaksi.'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          } finally {
                            if (ctx.mounted) setDialogState(() => isPaying = false);
                          }
                        },
                  child: Text(
                    'Konfirmasi Pembayaran',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionSheetRow({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    final defaultText = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedText = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      color: titleColor ?? defaultText,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        color: mutedText,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: mutedText,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDeleteSubscriptionSheet(
    BuildContext context,
    SubscriptionModel sub,
    TransactionProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    showModalCardSheet(
      context: context,
      title: 'Hapus Tagihan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFF43F5E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hapus "${sub.name}"?',
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
            'Tagihan ini akan dihapus dari daftar pengingat rutin. Riwayat transaksi masa lalu tidak akan terpengaruh.',
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
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.12)
                            : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                      await provider.deleteSubscription(sub.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF43F5E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Hapus Tagihan',
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

  void _showSubscriptionActionSheet(
    BuildContext context,
    SubscriptionModel sub,
    TransactionProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isPaid = sub.isPaidInMonth(now);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF131A26) : const Color(0xFFF8FAFC);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final accentColor =
        isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A);

    showModalCardSheet(
      context: context,
      title: sub.name,
      titleIcon: Icons.receipt_long_rounded,
      titleIconColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary Header Pod
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            provider.formatCurrency(sub.amount),
                            style: GoogleFonts.interTight(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sub.cycle.shortUnit,
                            style: GoogleFonts.manrope(
                              color: mutedColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sub.categoryName} · Jatuh tempo tgl ${sub.billingDay}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: mutedColor,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPaid
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE58B29))
                        .withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPaid ? 'Lunas' : 'Belum Bayar',
                    style: GoogleFonts.manrope(
                      color: isPaid
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE58B29),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action List Container
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPaid)
                  _buildActionSheetRow(
                    isDark: isDark,
                    icon: Icons.undo_rounded,
                    iconColor: const Color(0xFFE58B29),
                    title: 'Batalkan Status Lunas',
                    subtitle:
                        'Kembalikan ke belum bayar & hapus transaksi pembayaran',
                    onTap: () async {
                      await provider.unpaySubscription(sub.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  )
                else
                  _buildActionSheetRow(
                    isDark: isDark,
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Bayar & Catat Transaksi',
                    subtitle:
                        'Potong saldo dompet & tandai tagihan sudah dibayar',
                    onTap: () {
                      Navigator.pop(context);
                      _showPaymentConfirmationDialog(context, sub, provider);
                    },
                  ),
                Divider(
                  color: borderColor,
                  height: 1,
                  indent: 62,
                  endIndent: 14,
                ),
                _buildActionSheetRow(
                  isDark: isDark,
                  icon: Icons.edit_outlined,
                  iconColor: accentColor,
                  title: 'Ubah Data Tagihan',
                  subtitle: 'Edit nominal, tanggal jatuh tempo, atau dompet',
                  onTap: () {
                    Navigator.pop(context);
                    showAddOrEditSubscriptionSheet(
                      context: context,
                      existingSubscription: sub,
                    );
                  },
                ),
                Divider(
                  color: borderColor,
                  height: 1,
                  indent: 62,
                  endIndent: 14,
                ),
                _buildActionSheetRow(
                  isDark: isDark,
                  icon: Icons.delete_outline_rounded,
                  iconColor: const Color(0xFFF43F5E),
                  title: 'Hapus Tagihan',
                  titleColor: const Color(0xFFF43F5E),
                  onTap: () {
                    Navigator.pop(context);
                    _showConfirmDeleteSubscriptionSheet(
                      context,
                      sub,
                      provider,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();
    final subscriptions = provider.subscriptions;
    final now = DateTime.now();

    final totalMonthly = provider.totalMonthlySubscriptions;
    final totalPaid = provider.totalPaidSubscriptionsThisMonth;
    final totalUnpaid = provider.totalUnpaidSubscriptionsThisMonth;
    final pctPaid = totalMonthly > 0 ? (totalPaid / totalMonthly).clamp(0.0, 1.0) : 0.0;

    // Filter by tab
    final filteredSubscriptions = subscriptions.where((s) {
      final isPaid = s.isPaidInMonth(now);
      switch (_currentTab) {
        case SubscriptionFilterTab.all:
          return true;
        case SubscriptionFilterTab.unpaid:
          return !isPaid;
        case SubscriptionFilterTab.paid:
          return isPaid;
      }
    }).toList();

    // Sort by status: overdue & due soon first, then upcoming, then paid
    filteredSubscriptions.sort((a, b) {
      final aPaid = a.isPaidInMonth(now);
      final bPaid = b.isPaidInMonth(now);
      if (aPaid != bPaid) return aPaid ? 1 : -1;
      return a.daysUntilDue(now).compareTo(b.daysUntilDue(now));
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C2229) : const Color(0xFFF4F5F7),
      floatingActionButton: FloatingActionButton(
        key: const Key('fab_add_subscription'),
        heroTag: null,
        onPressed: () => showAddOrEditSubscriptionSheet(context: context),
        backgroundColor: const Color(0xFF02539A),
        foregroundColor: Colors.white,
        elevation: 3,
        tooltip: 'Tambah Tagihan',
        child: const Icon(Icons.add_rounded, size: 26),
      ),
      body: Stack(
        children: [
          if (isDark) const AmbientTopGlow(),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              children: [
                // 1. Standard Header
                const StandardScreenHeader(
                  title: 'Tagihan & Langganan',
                ),
                const SizedBox(height: 12),

                // 2. Hero Commitment Card
                NestedCard(
                  title: 'Komitmen Rutin Bulanan',
                  action: '${subscriptions.length} Tagihan',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Grand Total Monthly
                        Text(
                          'Total Komitmen Bulanan',
                          style: GoogleFonts.manrope(
                            color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                provider.formatCurrency(totalMonthly),
                                style: GoogleFonts.interTight(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '/ bulan',
                                style: GoogleFonts.manrope(
                                  color: isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Progress Bar Pelunasan
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 6,
                            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: pctPaid.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Sub-pods: Belum Bayar vs Sudah Dibayar
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE58B29),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Belum Dibayar',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.manrope(
                                              color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      alignment: Alignment.centerLeft,
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        provider.formatCurrency(totalUnpaid),
                                        style: GoogleFonts.interTight(
                                          color: const Color(0xFFE58B29),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Sudah Dibayar',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.manrope(
                                              color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      alignment: Alignment.centerLeft,
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        provider.formatCurrency(totalPaid),
                                        style: GoogleFonts.interTight(
                                          color: const Color(0xFF10B981),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
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

                // 3. Filter Segmented Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0C131D) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTabItem('Semua (${subscriptions.length})', SubscriptionFilterTab.all, isDark),
                      _buildTabItem('Belum Bayar (${provider.unpaidSubscriptionsCount})', SubscriptionFilterTab.unpaid, isDark),
                      _buildTabItem('Lunas (${subscriptions.length - provider.unpaidSubscriptionsCount})', SubscriptionFilterTab.paid, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 4. List Tagihan / Empty State
                if (filteredSubscriptions.isEmpty) ...[
                  NestedCard(
                    title: 'Daftar Tagihan',
                    action: '0 Item',
                    child: _buildEmptyState(context, isDark, subscriptions.isEmpty),
                  ),
                ] else ...[
                  NestedCard(
                    title: 'Daftar Tagihan',
                    action: '${filteredSubscriptions.length} Item',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredSubscriptions.length,
                        separatorBuilder: (_, __) => Divider(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : const Color(0xFFE2E8F0),
                          height: 1,
                          indent: 68,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final sub = filteredSubscriptions[index];
                          return _buildSubscriptionRow(
                            context,
                            sub,
                            provider,
                            isDark,
                            now,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, SubscriptionFilterTab tab, bool isDark) {
    final isSelected = _currentTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTab = tab),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B)),
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionRow(
    BuildContext context,
    SubscriptionModel sub,
    TransactionProvider provider,
    bool isDark,
    DateTime now,
  ) {
    final isPaid = sub.isPaidInMonth(now);
    final status = sub.getStatus(now);
    final daysUntil = sub.daysUntilDue(now);
    final accentColor = isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    Color statusColor;
    String statusText;

    if (isPaid) {
      statusColor = const Color(0xFF10B981);
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final paidDateStr = sub.lastPaidDate != null
          ? '${sub.lastPaidDate!.day} ${monthNames[sub.lastPaidDate!.month - 1]}'
          : 'Periode ini';
      statusText = 'Lunas · $paidDateStr';
    } else {
      switch (status) {
        case SubscriptionStatus.dueToday:
          statusColor = const Color(0xFFF43F5E);
          statusText = 'Jatuh tempo hari ini';
          break;
        case SubscriptionStatus.overdue:
          statusColor = const Color(0xFFF43F5E);
          statusText = 'Terlewat ${daysUntil.abs()} hari';
          break;
        case SubscriptionStatus.dueSoon:
          statusColor = const Color(0xFFE58B29);
          statusText = daysUntil == 1 ? 'Besok jatuh tempo' : '$daysUntil hari lagi';
          break;
        default:
          statusColor = mutedColor;
          statusText = 'Tgl ${sub.billingDay} · $daysUntil hari lagi';
          break;
      }
    }

    final categoryModel = provider.getCategoryByName(sub.categoryName);

    return InkWell(
      onTap: () => _showSubscriptionActionSheet(context, sub, provider),
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
                  color: !isPaid &&
                          (status == SubscriptionStatus.dueToday ||
                              status == SubscriptionStatus.overdue)
                      ? const Color(0xFFF43F5E).withOpacity(0.4)
                      : (isDark
                          ? Colors.white.withOpacity(0.08)
                          : const Color(0xFFCBD5E1)),
                ),
              ),
              alignment: Alignment.center,
              child: categoryModel != null
                  ? categoryModel.buildIconWidget(size: 20)
                  : Icon(Icons.repeat_rounded, size: 20, color: accentColor),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          sub.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            color: textColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        sub.cycle.shortUnit,
                        style: GoogleFonts.manrope(
                          color: mutedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (sub.reminderEnabled) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 13,
                          color: accentColor,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: statusColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  provider.formatCurrency(sub.amount),
                  style: GoogleFonts.interTight(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                if (isPaid) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Lunas',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF02539A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: const Size(0, 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () =>
                        _showPaymentConfirmationDialog(context, sub, provider),
                    child: Text(
                      'Bayar',
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, bool isCompletelyEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_repeat_rounded,
                size: 28,
                color: isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isCompletelyEmpty ? 'Belum Ada Tagihan Rutin' : 'Tidak Ada Tagihan di Kategori Ini',
              style: GoogleFonts.interTight(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isCompletelyEmpty
                  ? 'Catat komitmen bulanan seperti Netflix, WiFi, Listrik, atau Kos untuk memantau beban tetap dan pengingat jatuh tempo.'
                  : 'Semua tagihan untuk filter ini telah selesai atau belum tersedia.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            if (isCompletelyEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF02539A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Tambah Tagihan Pertama',
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: () => showAddOrEditSubscriptionSheet(context: context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
