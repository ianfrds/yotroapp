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
                  onPressed: () async {
                    if (selectedWalletId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pilih dompet pembayaran.')),
                      );
                      return;
                    }
                    await provider.paySubscription(
                      sub.id,
                      walletId: selectedWalletId,
                      date: selectedDate,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tagihan ${sub.name} berhasil dibayar & dicatat ke transaksi.'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
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

  void _showSubscriptionActionSheet(
    BuildContext context,
    SubscriptionModel sub,
    TransactionProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isPaid = sub.isPaidInMonth(now);

    showModalCardSheet(
      context: context,
      title: sub.name,
      titleIcon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPaid) ...[
            ListTile(
              leading: const Icon(Icons.undo_rounded, color: Color(0xFFE58B29)),
              title: Text(
                'Batalkan Status Lunas',
                style: GoogleFonts.manrope(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Ubah kembali status menjadi belum bayar bulan ini',
                style: GoogleFonts.manrope(fontSize: 11),
              ),
              onTap: () async {
                await provider.unpaySubscription(sub.id);
                Navigator.pop(context);
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
              title: Text(
                'Bayar & Catat Transaksi',
                style: GoogleFonts.manrope(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showPaymentConfirmationDialog(context, sub, provider);
              },
            ),
          ],
          ListTile(
            leading: Icon(
              Icons.edit_outlined,
              color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
            ),
            title: Text(
              'Ubah Data Tagihan',
              style: GoogleFonts.manrope(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              showAddOrEditSubscriptionSheet(
                context: context,
                existingSubscription: sub,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            title: Text(
              'Hapus Tagihan',
              style: GoogleFonts.manrope(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dCtx) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF131A26) : Colors.white,
                  title: Text(
                    'Hapus Tagihan?',
                    style: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                  ),
                  content: Text(
                    'Tagihan "${sub.name}" akan dihapus dari daftar. Riwayat mutasi transaksi masa lalu tidak akan terpengaruh.',
                    style: GoogleFonts.manrope(fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dCtx, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(dCtx, true),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await provider.deleteSubscription(sub.id);
              }
            },
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
      body: Stack(
        children: [
          if (isDark) const AmbientTopGlow(),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
              children: [
                // 1. Standard Header with Add Button
                StandardScreenHeader(
                  title: 'Tagihan & Langganan',
                  actionWidget: InkWell(
                    onTap: () => showAddOrEditSubscriptionSheet(context: context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                  ),
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
                  _buildEmptyState(context, isDark, subscriptions.isEmpty),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredSubscriptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final sub = filteredSubscriptions[index];
                      return _buildSubscriptionCard(context, sub, provider, isDark, now);
                    },
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

  Widget _buildSubscriptionCard(
    BuildContext context,
    SubscriptionModel sub,
    TransactionProvider provider,
    bool isDark,
    DateTime now,
  ) {
    final isPaid = sub.isPaidInMonth(now);
    final status = sub.getStatus(now);
    final daysUntil = sub.daysUntilDue(now);

    final cardBg = isDark ? const Color(0xFF131A26) : Colors.white;
    final cardBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);

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
          : 'Bulan ini';
      statusText = 'Lunas ($paidDateStr)';
    } else {
      switch (status) {
        case SubscriptionStatus.dueToday:
          statusColor = const Color(0xFFEF4444);
          statusText = 'Jatuh Tempo Hari Ini!';
          break;
        case SubscriptionStatus.overdue:
          statusColor = const Color(0xFFEF4444);
          statusText = 'Terlewat (${daysUntil.abs()} hari lalu)';
          break;
        case SubscriptionStatus.dueSoon:
          statusColor = const Color(0xFFE58B29);
          statusText = daysUntil == 1 ? 'Jatuh tempo besok' : 'Jatuh tempo $daysUntil hari lagi';
          break;
        default:
          statusColor = isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B);
          statusText = 'Tgl ${sub.billingDay} (${daysUntil} hari lagi)';
          break;
      }
    }

    final categoryModel = provider.getCategoryByName(sub.categoryName);

    return InkWell(
      onTap: () => _showSubscriptionActionSheet(context, sub, provider),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !isPaid && (status == SubscriptionStatus.dueToday || status == SubscriptionStatus.overdue)
                ? const Color(0xFFEF4444).withOpacity(0.35)
                : cardBorder,
          ),
        ),
        child: Row(
          children: [
            // Category Icon Badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: categoryModel != null
                  ? categoryModel.buildIconWidget(size: 20)
                  : const Icon(Icons.repeat_rounded, size: 20, color: Color(0xFF02539A)),
            ),
            const SizedBox(width: 12),

            // Main Info
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
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (sub.reminderEnabled) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 13,
                          color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Amount & Action Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  provider.formatCurrency(sub.amount),
                  style: GoogleFonts.interTight(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
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
                        const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'Lunas',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF10B981),
                            fontSize: 10.5,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _showPaymentConfirmationDialog(context, sub, provider),
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
