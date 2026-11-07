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

    final bgColor = isDark ? AppColors.background : const Color(0xFFF4F5F7);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: [
            // Standard Screen Header
            const StandardScreenHeader(
              title: 'Notifikasi',
            ),
            const SizedBox(height: 12),

            // Activity Notifications Log
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
}
