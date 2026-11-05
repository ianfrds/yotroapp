import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../theme/app_colors.dart';

class CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onSelected;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.accentPrimary : const Color(0xFF0F172A))
              : (isDark ? AppColors.surface : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.accentPrimary : const Color(0xFF0F172A))
                : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            category.buildIconWidget(size: 15),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? AppColors.backgroundDark : Colors.white)
                    : (isDark ? AppColors.textSecondary : const Color(0xFF475569)),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

