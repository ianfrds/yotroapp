import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  static const _shortMonthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agt',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (isToday) return 'Hari ini, $timeStr';
    if (isYesterday) return 'Kemarin, $timeStr';
    return '${dt.day} ${_shortMonthNames[dt.month - 1]}, $timeStr';
  }

  static ({IconData icon, Color color}) _categoryVisual(
    String category,
    TransactionType type,
  ) {
    if (type == TransactionType.transfer) {
      return (icon: Icons.swap_horiz_rounded, color: const Color(0xFF55C7FF));
    }
    if (type == TransactionType.income) {
      switch (category) {
        case 'Salary':
          return (icon: Icons.payments_outlined, color: const Color(0xFF39D98A));
        case 'Freelance':
          return (icon: Icons.laptop_mac_outlined, color: const Color(0xFF2B8DE0));
        case 'Investment':
          return (icon: Icons.trending_up_rounded, color: const Color(0xFF14B8A6));
        case 'Business':
          return (icon: Icons.storefront_outlined, color: const Color(0xFF55C7FF));
        default:
          return (icon: Icons.add_circle_outline_rounded, color: const Color(0xFF39D98A));
      }
    }

    switch (category) {
      case 'Food & Beverage':
        return (icon: Icons.local_cafe_outlined, color: const Color(0xFFFFC857));
      case 'Transportation':
        return (icon: Icons.directions_car_outlined, color: const Color(0xFF55C7FF));
      case 'Bills & Utilities':
        return (icon: Icons.bolt_outlined, color: const Color(0xFFB996FF));
      case 'Shopping':
        return (icon: Icons.shopping_bag_outlined, color: const Color(0xFFFF6B7A));
      case 'Health':
        return (icon: Icons.medical_services_outlined, color: const Color(0xFF39D98A));
      case 'Entertainment':
        return (icon: Icons.movie_outlined, color: const Color(0xFFEC4899));
      default:
        return (icon: Icons.receipt_long_outlined, color: const Color(0xFF8CA7C5));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final isIncome = transaction.type == TransactionType.income;
    final isExpense = transaction.type == TransactionType.expense;
    final isTransfer = transaction.type == TransactionType.transfer;

    final visual = _categoryVisual(transaction.categoryName, transaction.type);

    final categoryModel = isTransfer
        ? null
        : provider.categories.cast<CategoryModel?>().firstWhere(
            (c) => c != null && (c.id == transaction.categoryId || (c.name == transaction.categoryName && c.type == transaction.type)),
            orElse: () => null,
          );

    final tileColor = isTransfer
        ? visual.color
        : (categoryModel?.colorValue != null ? Color(categoryModel!.colorValue!) : visual.color);

    final wallet = provider.wallets.firstWhere(
      (w) => w.id == transaction.walletId,
      orElse: () => provider.wallets.first,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final prefix = isIncome
        ? '+ '
        : isExpense
            ? '- '
            : '';
    final amountColor = isIncome
        ? const Color(0xFF39D98A)
        : isTransfer
            ? const Color(0xFF55C7FF)
            : (isDark ? Colors.white : const Color(0xFF0F172A));

    final dateStr = _formatDate(transaction.timestamp);
    final subtitle = '$dateStr • ${wallet.name}';
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF7F91A7) : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Circular Category Avatar
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tileColor.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: isTransfer
                  ? Icon(visual.icon, color: tileColor, size: 20)
                  : (categoryModel != null
                      ? categoryModel.buildIconWidget(size: 20)
                      : Text(CategoryModel.fallbackEmojiFor(transaction.categoryName), style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),

            // Title & Subtitle (Date • Wallet)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: titleColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: subtitleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Formatted Amount
            Text(
              '$prefix${provider.formatCurrency(transaction.amount)}',
              style: GoogleFonts.interTight(
                color: amountColor,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
