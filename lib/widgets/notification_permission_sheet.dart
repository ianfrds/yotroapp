import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import 'modal_card_sheet.dart';

void showNotificationPermissionSheet({
  required BuildContext context,
  required String featureTitle,
  required VoidCallback onGranted,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
  final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
  final podBg = isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9);
  final podBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);

  showModalCardSheet(
    context: context,
    title: 'Izin Notifikasi',
    titleIcon: Icons.notifications_active_rounded,
    titleIconColor: const Color(0xFF55C7FF),
    child: StatefulBuilder(
      builder: (ctx, setState) {
        final provider = ctx.watch<TransactionProvider>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Untuk mengaktifkan $featureTitle, aplikasi memerlukan izin menampilkan dan membaca notifikasi di perangkat Anda.',
              style: GoogleFonts.manrope(
                color: mutedColor,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),

            // Benefits pods
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: podBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: podBorder),
              ),
              child: Column(
                children: [
                  _buildPermissionBenefitItem(
                    icon: Icons.alarm_rounded,
                    title: 'Pengingat Transaksi Harian',
                    desc: 'Mengingatkan di jam pilihan jika belum ada pengeluaran/pemasukan dicatat hari ini.',
                    textColor: textColor,
                    mutedColor: mutedColor,
                    isDark: isDark,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      height: 1,
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  _buildPermissionBenefitItem(
                    icon: Icons.mark_email_read_outlined,
                    title: 'Pembaca Mutasi Otomatis',
                    desc: 'Mendeteksi notifikasi pembayaran perbankan/e-wallet untuk persetujuan cepat.',
                    textColor: textColor,
                    mutedColor: mutedColor,
                    isDark: isDark,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      height: 1,
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  _buildPermissionBenefitItem(
                    icon: Icons.shield_outlined,
                    title: '100% Privasi Terjaga',
                    desc: 'Semua deteksi diproses lokal di HP Anda, tanpa pernah dikirim ke internet.',
                    textColor: textColor,
                    mutedColor: mutedColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.manrope(
                        color: mutedColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF02539A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final granted = await provider.requestNotificationPermission();
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        if (granted) {
                          onGranted();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF131A26),
                              showCloseIcon: true,
                              closeIconColor: const Color(0xFF94A3B8),
                              content: Text(
                                'Izin notifikasi ditolak oleh perangkat. Anda dapat mengaktifkannya di Pengaturan HP.',
                                style: GoogleFonts.manrope(color: Colors.white, fontSize: 12),
                              ),
                              action: SnackBarAction(
                                label: 'Buka Pengaturan',
                                textColor: const Color(0xFF55C7FF),
                                onPressed: () => provider.openDeviceSettings(),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      'Izinkan Notifikasi',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildPermissionBenefitItem({
  required IconData icon,
  required String title,
  required String desc,
  required Color textColor,
  required Color mutedColor,
  required bool isDark,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: const Color(0xFF55C7FF),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.interTight(
                color: textColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: GoogleFonts.manrope(
                color: mutedColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

