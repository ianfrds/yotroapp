import 'dart:async';
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
  static const Color _bluePrimary = Color(0xFF0066FF);

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _contentFadeAnimation;

  Timer? _autoRedirectTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
    );

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
    );

    _contentFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.95, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto redirect to home after 5 seconds without any countdown text
    _autoRedirectTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _navigateHome();
      }
    });
  }

  @override
  void dispose() {
    _autoRedirectTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _navigateHome() {
    _autoRedirectTimer?.cancel();
    if (widget.onBackToHome != null) {
      try {
        widget.onBackToHome!();
        return;
      } catch (_) {}
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _navigateAddAnother() {
    _autoRedirectTimer?.cancel();
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          // Animated Scalloped Rosette Checkmark (from user reference image)
                          _buildAnimatedIllustration(isDark),
                          const SizedBox(height: 18),

                          // Title & Subtitle (max semibold, no bold)
                          FadeTransition(
                            opacity: _contentFadeAnimation,
                            child: Column(
                              children: [
                                Text(
                                  'Transaksi Berhasil Dicatat',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.interTight(
                                    color: textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
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
                          const SizedBox(height: 20),

                          // Transaction Details Card using NestedCard (Design System Parity)
                          FadeTransition(
                            opacity: _contentFadeAnimation,
                            child: NestedCard(
                              title: 'Rincian Transaksi',
                              titleWidget: Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 17,
                                    color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF0F172A),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Rincian Transaksi',
                                    style: GoogleFonts.interTight(
                                      color: textPrimary,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              innerPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Column(
                                children: [
                                  // Amount Display (max semibold w600)
                                  Center(
                                    child: Text(
                                      '$prefix${currencyFmt.format(tx.amount)}',
                                      style: GoogleFonts.interTight(
                                        color: amountColor,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Center(
                                    child: Text(
                                      tx.title,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.manrope(
                                        color: textPrimary,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Divider(
                                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 10),

                                  // Key-value Rows (tightened spacing & aligned columns)
                                  _buildDetailRow(
                                    isDark: isDark,
                                    label: 'Dompet',
                                    value: walletName,
                                    icon: Icons.account_balance_wallet_outlined,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                    isDark: isDark,
                                    label: 'Kategori',
                                    value: tx.categoryName,
                                    icon: Icons.category_outlined,
                                  ),
                                  const SizedBox(height: 8),
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
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                    isDark: isDark,
                                    label: 'Waktu',
                                    value: DateFormat('dd MMM yyyy, HH:mm').format(tx.timestamp),
                                    icon: Icons.access_time_rounded,
                                  ),
                                  if (tx.note.isNotEmpty) ...[
                                    const SizedBox(height: 8),
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

                  // Bottom Action Buttons (standardized reusable theme buttons)
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
                          // Primary Button: Sapphire Blue, 48px height, 14px radius, semibold
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _navigateHome,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _bluePrimary,
                                foregroundColor: Colors.white,
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
                          // Secondary Button: Outlined, 48px height, 14px radius, semibold
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _navigateAddAnother,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
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
                                      fontSize: 14,
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
        SizedBox(
          width: 22,
          height: 22,
          child: Center(
            child: Icon(icon, size: 16, color: textMuted),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            color: textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
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
      width: 88,
      height: 88,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: CustomPaint(
            size: const Size(80, 80),
            painter: _ScallopedCheckmarkPainter(
              checkProgress: _checkAnimation.value,
              isDark: isDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScallopedCheckmarkPainter extends CustomPainter {
  final double checkProgress;
  final bool isDark;

  _ScallopedCheckmarkPainter({
    required this.checkProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. 8-lobed scalloped rosette matching user reference image
    const int lobes = 8;
    const double rMid = 35.0;
    const double amplitude = 4.2;

    final path = Path();
    const int steps = 120;
    for (int i = 0; i < steps; i++) {
      final theta = (2 * math.pi * i) / steps;
      final r = rMid + amplitude * math.cos(lobes * theta);
      final angle = theta - (math.pi / 2);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // 2. Subtle drop shadow (reduced shadow, zero heavy glow)
    canvas.drawShadow(path, Colors.black.withOpacity(0.18), 3.5, false);

    // 3. Fill badge with soft lime green from reference (#C4F988)
    final fillPaint = Paint()
      ..color = const Color(0xFFC4F988)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Subtle edge border
    final borderPaint = Paint()
      ..color = const Color(0xFFA7E86B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);

    // 4. Draw bold checkmark in dark green (#005928) with animation
    if (checkProgress > 0.0) {
      final checkPaint = Paint()
        ..color = const Color(0xFF005928)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final checkPath = Path();
      // Precise normalized coordinates matching the rosette proportions
      final start = Offset(size.width * 0.33, size.height * 0.52);
      final elbow = Offset(size.width * 0.46, size.height * 0.65);
      final end = Offset(size.width * 0.68, size.height * 0.38);

      checkPath.moveTo(start.dx, start.dy);

      if (checkProgress <= 0.45) {
        final p = checkProgress / 0.45;
        final currentX = start.dx + (elbow.dx - start.dx) * p;
        final currentY = start.dy + (elbow.dy - start.dy) * p;
        checkPath.lineTo(currentX, currentY);
      } else {
        checkPath.lineTo(elbow.dx, elbow.dy);
        final p = (checkProgress - 0.45) / 0.55;
        final currentX = elbow.dx + (end.dx - elbow.dx) * p;
        final currentY = elbow.dy + (end.dy - elbow.dy) * p;
        checkPath.lineTo(currentX, currentY);
      }

      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScallopedCheckmarkPainter oldDelegate) {
    return oldDelegate.checkProgress != checkProgress || oldDelegate.isDark != isDark;
  }
}
