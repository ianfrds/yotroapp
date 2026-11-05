import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../widgets/nested_card.dart';
import '../widgets/standard_screen_header.dart';

class DisplayPreferencesScreen extends StatelessWidget {
  const DisplayPreferencesScreen({super.key});

  static MaterialPageRoute route() {
    return MaterialPageRoute(
      builder: (_) => const DisplayPreferencesScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1C2229) : const Color(0xFFF4F5F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            const StandardScreenHeader(
              title: 'Preferensi Tampilan',
            ),
            const SizedBox(height: 14),
            NestedCard(
              title: 'Fokus Tampilan Beranda',
              innerPadding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih mode tampilan ringkasan finansial pada kartu beranda sesuai preferensi pencatatan Anda.',
                    style: GoogleFonts.manrope(
                      color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildOptionCard(
                    context: context,
                    provider: provider,
                    isDark: isDark,
                    mode: DashboardViewMode.complete,
                    title: 'Complete View',
                    badge: 'Bawaan',
                    description: 'Tampilan default lengkap: menampilkan saldo saat ini serta sub-kartu pengeluaran dan pemasukan.',
                    previewType: _PreviewType.complete,
                  ),
                  const SizedBox(height: 10),
                  _buildOptionCard(
                    context: context,
                    provider: provider,
                    isDark: isDark,
                    mode: DashboardViewMode.incomeExpense,
                    title: 'Pemasukan dan Pengeluaran',
                    description: 'Sembunyikan view saldo saat ini di kartu beranda. Tampilkan sub-kartu pemasukan dan pengeluaran berdampingan.',
                    previewType: _PreviewType.incomeExpense,
                  ),
                  const SizedBox(height: 10),
                  _buildOptionCard(
                    context: context,
                    provider: provider,
                    isDark: isDark,
                    mode: DashboardViewMode.expenseOnly,
                    title: 'Pengeluaran saja',
                    description: 'Fokus pada pengeluaran saja. View saldo saat ini dan pemasukan disembunyikan, sub-kartu pengeluaran tampil melebar penuh.',
                    previewType: _PreviewType.expenseOnly,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required TransactionProvider provider,
    required bool isDark,
    required DashboardViewMode mode,
    required String title,
    String? badge,
    required String description,
    required _PreviewType previewType,
  }) {
    final isSelected = provider.dashboardViewMode == mode;
    final accentColor = isDark ? const Color(0xFF55C7FF) : const Color(0xFF0F172A);

    return InkWell(
      onTap: () => provider.setDashboardViewMode(mode),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFF55C7FF).withOpacity(0.08)
                  : const Color(0xFF0F172A).withOpacity(0.05))
              : (isDark ? Colors.white.withOpacity(0.03) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF55C7FF) : const Color(0xFF0F172A))
                : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.interTight(
                          color: isSelected
                              ? (isDark ? const Color(0xFF55C7FF) : const Color(0xFF0F172A))
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.manrope(
                              color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF475569),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? accentColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : (isDark ? const Color(0xFF677B92) : const Color(0xFF94A3B8)),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: isDark ? Colors.black : Colors.white,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.manrope(
                color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            _buildWireframePreview(previewType, isDark, isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildWireframePreview(_PreviewType type, bool isDark, bool isSelected) {
    final cardBg = isDark ? const Color(0xFF0B2244) : const Color(0xFFE2E8F0);
    final podBg = isDark ? const Color(0xFF1A3358) : const Color(0xFFCBD5E1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(isDark ? 0.45 : 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFD1D5DB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 32, height: 6, decoration: BoxDecoration(color: podBg, borderRadius: BorderRadius.circular(3))),
              Container(width: 10, height: 6, decoration: BoxDecoration(color: podBg, borderRadius: BorderRadius.circular(3))),
            ],
          ),
          if (type == _PreviewType.complete) ...[
            const SizedBox(height: 6),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: podBg.withOpacity(0.6), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 4),
            Container(width: 80, height: 10, decoration: BoxDecoration(color: isDark ? Colors.white70 : Colors.black87, borderRadius: BorderRadius.circular(3))),
          ],
          const SizedBox(height: 6),
          if (type == _PreviewType.expenseOnly)
            Container(
              height: 18,
              width: double.infinity,
              decoration: BoxDecoration(color: podBg, borderRadius: BorderRadius.circular(4)),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(width: 40, height: 6, decoration: BoxDecoration(color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF0F172A), borderRadius: BorderRadius.circular(3))),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(color: podBg, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(color: podBg, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

enum _PreviewType {
  complete,
  incomeExpense,
  expenseOnly,
}
