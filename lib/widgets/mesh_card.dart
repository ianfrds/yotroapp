import 'package:flutter/material.dart';
import '../providers/transaction_provider.dart';

class MeshCard extends StatelessWidget {
  final double amount;
  final bool isAmountOnly;
  final String title;
  final bool isVisible;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onChangeAmount;

  const MeshCard({
    super.key,
    required this.amount,
    this.isAmountOnly = false,
    this.title = 'Total balance',
    this.isVisible = true,
    this.onToggleVisibility,
    this.onChangeAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: isAmountOnly ? 190 : 200,
      decoration: BoxDecoration(
        color: const Color(0xFF131620),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Stack(
        children: [
          // Fluid organic mesh gradient blob inside card
          Positioned(
            right: -20,
            bottom: -30,
            child: Container(
              width: 240,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.85),
                    const Color(0xFF38BDF8).withOpacity(0.75),
                    const Color(0xFF34D399).withOpacity(0.60),
                    const Color(0xFFFB923C).withOpacity(0.50),
                    Colors.transparent,
                  ],
                  stops: const [0.1, 0.35, 0.6, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Card Selector & Network Logo
                if (!isAmountOnly)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Main card **** 6510',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                      // Mastercard Logo (Dual circle)
                      SizedBox(
                        width: 32,
                        height: 20,
                        child: Stack(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),

                // Center/Bottom Content
                if (!isAmountOnly)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isVisible ? TransactionProvider.formatRupiah(amount) : '••••••••',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      if (onToggleVisibility != null)
                        InkWell(
                          onTap: onToggleVisibility,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.white.withOpacity(0.7),
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          TransactionProvider.formatRupiah(amount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: onChangeAmount,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_outlined, color: Colors.white, size: 13),
                                SizedBox(width: 6),
                                Text(
                                  'Change amount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
    );
  }
}

