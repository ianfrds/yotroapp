import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/nested_card.dart';
import 'add_transaction_screen.dart';

class TransactionSuccessScreen extends StatefulWidget {
  final TransactionModel transaction;
  final VoidCallback? onBackToHome;
  final VoidCallback? onAddAnother;

  const TransactionSuccessScreen({
    super.key,
    required this.transaction,
    this.onBackToHome,
    this.onAddAnother,
  });

  @override
  State<TransactionSuccessScreen> createState() => _TransactionSuccessScreenState();
}

class _TransactionSuccessScreenState extends State<TransactionSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
    );

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
    );

    _rippleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.85, curve: Curves.easeOut),
    );

    _contentFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateHome() {
    if (widget.onBackToHome != null) {
      try {
        widget.onBackToHome!();
        return;
      } catch (_) {}
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _navigateAddAnother() {
    if (widget.onAddAnother != null) {
      try {
        widget.onAddAnother!();
        return;
      } catch (_) {}
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tx = widget.transaction;

    final bgColor = isDark ? const Color(0xFF09101C) : const Color(0xFFF4F5F7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    Color amountColor;
    String prefix;
    switch (tx.type) {
      case TransactionType.expense:
        amountColor = const Color(0xFFFF6B7A);
        prefix = '- ';
        break;
      case TransactionType.income:
        amountColor = const Color(0xFF34D399);
        prefix = '+ ';
        break;
      case TransactionType.transfer:
        amountColor = const Color(0xFF55C7FF);
        prefix = '';
        break;
    }

    // Lookup wallet name from provider if available
    String walletName = 'Dompet Utama';
    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final wallet = provider.wallets.cast<dynamic>().firstWhere(
            (w) => w.id == tx.walletId,
            orElse: () => null,
          );
      if (wallet != null) walletName = wallet.name;
    } catch (_) {}

    return WillPopScope(
      onWillPop: () async {
        _navigateHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          // Animated Checkmark Icon
                          _buildAnimatedIllustration(isDark),
                          const SizedBox(height: 20),

                          // Title & Subtitle
                          FadeTransition(
                            opacity: _contentFadeAnimation,
                            child: Column(
                              children: [
                                Text(
                                  'Transaksi Berhasil Dicatat',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.interTight(
                                    color: textPrimary,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Data telah tersimpan dan saldo dompet telah diperbarui.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(
                                    color: textMuted,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Transaction Details Card using NestedCard (Design System Parity)
                          FadeTransition(
                            opacity: _contentFadeAnimation,
                            child: NestedCard(
                              title: 'Rincian Transaksi',
                              titleWidget: Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 18,
                                    color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF0F172A),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Rincian Transaksi',
                                    style: GoogleFonts.interTight(
                                      color: textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              innerPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Column(
                                children: [
                                  // Amount Display
                                  Center(
                                    child: Text(
                                      '$prefix${currencyFmt.format(tx.amount)}',
                                      style: GoogleFonts.interTight(
                                        color: amountColor,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Text(
                                      tx.title,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.manrope(
                                        color: textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Divider(
                                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 14),

                                  // Key-value Rows
                                  _buildDetailRow(
                                    isDark: isDark,
                                    label: 'Dompet',
                                    value: walletName,
                                    icon: Icons.account_balance_wallet_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                    isDark: isDark,
                                    label: 'Kategori',
                                    value: tx.categoryName,
                                    icon: Icons.category_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                    isDark: isDark,
                                    label: 'Tipe',
                                    value: tx.type == TransactionType.expense
                                        ? 'Pengeluaran'
                                        : tx.type == TransactionType.income
                                            ? 'Pemasukan'
                                            : 'Transfer',
                                    icon: Icons.swap_horiz_rounded,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                    isDark: isDark,
                                    label: 'Waktu',
                                    value: DateFormat('dd MMM yyyy, HH:mm').format(tx.timestamp),
                                    icon: Icons.access_time_rounded,
                                  ),
                                  if (tx.note.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildDetailRow(
                                      isDark: isDark,
                                      label: 'Catatan',
                                      value: tx.note,
                                      icon: Icons.notes_rounded,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Buttons
                  FadeTransition(
                    opacity: _contentFadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border(
                          top: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _navigateHome,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF55C7FF) : const Color(0xFF0F172A),
                                foregroundColor: isDark ? const Color(0xFF09101C) : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.home_outlined, size: 19),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Kembali ke Beranda',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton(
                              onPressed: _navigateAddAnother,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimary,
                                side: BorderSide(
                                  color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_rounded, size: 19),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Catat Transaksi Lain',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final textMuted = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Row(
      children: [
        Icon(icon, size: 15, color: textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            color: textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedIllustration(bool isDark) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle Radiating Ripple
          Transform.scale(
            scale: 1.0 + (_rippleAnimation.value * 0.35),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF38BDF8).withOpacity(
                    (1.0 - _rippleAnimation.value).clamp(0.0, 0.4),
                  ),
                  width: 2.0,
                ),
              ),
            ),
          ),

          // Central Disc
          Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF0B2244),
                          Color(0xFF131A26),
                        ]
                      : const [
                          Color(0xFFE0F2FE),
                          Color(0xFFBAE6FD),
                        ],
                ),
                border: Border.all(
                  color: isDark ? const Color(0xFF38BDF8).withOpacity(0.4) : const Color(0xFF0284C7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withOpacity(isDark ? 0.3 : 0.15),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _AnimatedCheckmarkPainter(
                  progress: _checkAnimation.value,
                  color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF0284C7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _AnimatedCheckmarkPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    final start = Offset(size.width * 0.28, size.height * 0.52);
    final elbow = Offset(size.width * 0.44, size.height * 0.68);
    final end = Offset(size.width * 0.72, size.height * 0.36);

    path.moveTo(start.dx, start.dy);

    if (progress <= 0.45) {
      final p = progress / 0.45;
      final currentX = start.dx + (elbow.dx - start.dx) * p;
      final currentY = start.dy + (elbow.dy - start.dy) * p;
      path.lineTo(currentX, currentY);
    } else {
      path.lineTo(elbow.dx, elbow.dy);
      final p = (progress - 0.45) / 0.55;
      final currentX = elbow.dx + (end.dx - elbow.dx) * p;
      final currentY = elbow.dy + (end.dy - elbow.dy) * p;
      path.lineTo(currentX, currentY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedCheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
