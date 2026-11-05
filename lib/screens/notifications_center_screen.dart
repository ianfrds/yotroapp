import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/notification_rule_model.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/nested_card.dart';
import '../widgets/standard_screen_header.dart';

class NotificationsCenterScreen extends StatelessWidget {
  const NotificationsCenterScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => const NotificationsCenterScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();
    final pendingList = provider.pendingNotifications;

    final bgColor = isDark ? AppColors.background : const Color(0xFFF4F5F7);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: [
            // Standard Screen Header
            StandardScreenHeader(
              title: 'Notifikasi',
              actionWidget: provider.pendingNotificationsCount > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B7A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${provider.pendingNotificationsCount} baru',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // Section 1: Pending Approvals
            NestedCard(
              title: 'Persetujuan Transaksi',
              action: pendingList.isNotEmpty ? 'Setujui Semua' : null,
              onActionTap: pendingList.isNotEmpty
                  ? () async {
                      for (final p in List.of(pendingList)) {
                        await provider.approveNotification(p.id);
                      }
                      if (context.mounted) {
                        AppSnackBar.show(
                          context,
                          'Semua transaksi berhasil disetujui dan dicatat',
                          type: SnackBarType.success,
                        );
                      }
                    }
                  : null,
              innerPadding: pendingList.isEmpty
                  ? const EdgeInsets.all(16)
                  : const EdgeInsets.symmetric(vertical: 4),
              child: pendingList.isEmpty
                  ? _buildEmptyPendingState(isDark, mutedColor)
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pendingList.length,
                      separatorBuilder: (_, __) => Divider(
                        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                        height: 1,
                        indent: 12,
                        endIndent: 12,
                      ),
                      itemBuilder: (context, index) {
                        final item = pendingList[index];
                        return _buildPendingItemCard(
                          context,
                          provider,
                          item,
                          isDark,
                          textColor,
                          mutedColor,
                          currencyFmt,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),

            // Section 2: Activity Notifications Log
            NestedCard(
              title: 'Aktivitas Transaksi',
              action: provider.activityNotifications.isNotEmpty ? 'Bersihkan' : null,
              onActionTap: provider.activityNotifications.isNotEmpty
                  ? () async {
                      await provider.clearActivityNotifications();
                      if (context.mounted) {
                        AppSnackBar.show(context, 'Riwayat aktivitas dibersihkan', type: SnackBarType.info);
                      }
                    }
                  : null,
              innerPadding: provider.activityNotifications.isEmpty
                  ? const EdgeInsets.all(16)
                  : const EdgeInsets.symmetric(vertical: 4),
              child: provider.activityNotifications.isEmpty
                  ? _buildEmptyActivityState(isDark, mutedColor)
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.activityNotifications.length,
                      separatorBuilder: (_, __) => Divider(
                        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                        height: 1,
                        indent: 12,
                        endIndent: 12,
                      ),
                      itemBuilder: (context, index) {
                        final item = provider.activityNotifications[index];
                        return _buildActivityItemCard(
                          context,
                          item,
                          isDark,
                          textColor,
                          mutedColor,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivityState(bool isDark, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 22,
                color: mutedColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Belum Ada Aktivitas',
              style: GoogleFonts.interTight(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aktivitas pencatatan pengeluaran, pemasukan, dan mutasi saldo akan tercatat di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: mutedColor,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItemCard(
    BuildContext context,
    ActivityNotification item,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    final isIncome = item.type == TransactionType.income;
    final isTransfer = item.type == TransactionType.transfer;
    final iconColor = isIncome
        ? const Color(0xFF10B981)
        : isTransfer
            ? const Color(0xFF55C7FF)
            : const Color(0xFFFF6B7A);
    final iconData = isIncome
        ? Icons.arrow_downward_rounded
        : isTransfer
            ? Icons.swap_horiz_rounded
            : Icons.arrow_upward_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.interTight(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatActivityTime(item.timestamp),
                      style: GoogleFonts.manrope(
                        color: mutedColor,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.message,
                  style: GoogleFonts.manrope(
                    color: mutedColor,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatActivityTime(DateTime dt) {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(dt);
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Hari ini, $timeStr';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return 'Kemarin, $timeStr';
    }
    return '${dt.day} ${DateFormat('MMM').format(dt)}, $timeStr';
  }

  Widget _buildEmptyPendingState(bool isDark, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.done_all_rounded,
                size: 24,
                color: mutedColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak Ada Transaksi Tertunda',
              style: GoogleFonts.interTight(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Transaksi otomatis yang terbaca dari MyBCA, SeaBank, dll akan muncul di sini untuk dikonfirmasi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: mutedColor,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingItemCard(
    BuildContext context,
    TransactionProvider provider,
    PendingNotification item,
    bool isDark,
    Color textColor,
    Color mutedColor,
    NumberFormat currencyFmt,
  ) {
    final isIncome = item.type == TransactionType.income;
    final isTransfer = item.type == TransactionType.transfer;
    final amountColor = isIncome
        ? const Color(0xFF34D399)
        : isTransfer
            ? const Color(0xFF55C7FF)
            : const Color(0xFFFF6B7A);
    final prefix = isIncome ? '+ ' : (isTransfer ? '' : '- ');
    final typeBadgeLabel = isIncome
        ? 'Masuk'
        : isTransfer
            ? 'Transfer'
            : 'Keluar';
    final typeBadgeColor = amountColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF55C7FF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.sourceApp,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF55C7FF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeBadgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  typeBadgeLabel,
                  style: GoogleFonts.manrope(
                    color: typeBadgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('HH:mm').format(item.timestamp),
                style: GoogleFonts.manrope(
                  color: mutedColor,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.interTight(
                        color: textColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.walletName} • ${item.categoryName}',
                      style: GoogleFonts.manrope(
                        color: mutedColor,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$prefix${currencyFmt.format(item.amount)}',
                style: GoogleFonts.interTight(
                  color: amountColor,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () async {
                      await provider.rejectNotification(item.id);
                      if (context.mounted) {
                        AppSnackBar.show(context, 'Transaksi diabaikan', type: SnackBarType.info);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: mutedColor,
                      side: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Tolak',
                      style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () async {
                      await provider.approveNotification(item.id);
                      if (context.mounted) {
                        AppSnackBar.show(
                          context,
                          'Transaksi ${item.title} berhasil dicatat',
                          type: SnackBarType.success,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF02539A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Setujui & Catat',
                      style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
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
}
