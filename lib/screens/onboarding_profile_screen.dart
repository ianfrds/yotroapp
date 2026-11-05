import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/nested_card.dart';
import 'main_shell.dart';

class OnboardingProfileScreen extends StatefulWidget {
  const OnboardingProfileScreen({super.key});

  static MaterialPageRoute route() {
    return MaterialPageRoute(
      builder: (_) => const OnboardingProfileScreen(),
    );
  }

  @override
  State<OnboardingProfileScreen> createState() => _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState extends State<OnboardingProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedGender = 'Pria';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      AppSnackBar.show(
        context,
        'Nama lengkap wajib diisi untuk memulai aplikasi',
        type: SnackBarType.danger,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<TransactionProvider>();
    await provider.completeOnboarding(
      name: name,
      phone: phone,
      gender: _selectedGender,
    );

    if (!mounted) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF09101C) : const Color(0xFFF4F5F7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF181C26) : const Color(0xFFF8FAFC);
    final inputBorder = isDark ? Colors.white.withOpacity(0.10) : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Official Yotro Logo Emblem
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0066FF).withOpacity(0.25),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Titles
                  Text(
                    'Profil Pengguna',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.interTight(
                      color: textPrimary,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lengkapi identitas Anda untuk personalisasi akun Yotro. Seluruh data tersimpan 100% aman di perangkat lokal.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: textSecondary,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile Card using NestedCard (Design System Parity)
                  NestedCard(
                    title: 'Data Profil Pengguna',
                    titleWidget: Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 18,
                          color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF0F172A),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Data Identitas',
                          style: GoogleFonts.interTight(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    innerPadding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Field 1: Nama Lengkap
                        Text(
                          'Nama Lengkap',
                          style: GoogleFonts.manrope(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          autofocus: true,
                          style: GoogleFonts.manrope(
                            color: textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Contoh: Ian Firdaus',
                            hintStyle: GoogleFonts.manrope(
                              color: isDark ? const Color(0xFF5A667A) : const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                              size: 19,
                            ),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: inputBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: inputBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF55C7FF), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Field 2: Nomor Telepon
                        Text(
                          'Nomor Telepon (Opsional)',
                          style: GoogleFonts.manrope(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.manrope(
                            color: textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Contoh: 081234567890',
                            hintStyle: GoogleFonts.manrope(
                              color: isDark ? const Color(0xFF5A667A) : const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                              size: 18,
                            ),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: inputBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: inputBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF55C7FF), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Field 3: Jenis Kelamin
                        Text(
                          'Jenis Kelamin',
                          style: GoogleFonts.manrope(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: inputBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildGenderOption(
                                  label: 'Pria',
                                  icon: Icons.male_rounded,
                                  isSelected: _selectedGender == 'Pria',
                                  isDark: isDark,
                                  onTap: () => setState(() => _selectedGender = 'Pria'),
                                ),
                              ),
                              Expanded(
                                child: _buildGenderOption(
                                  label: 'Wanita',
                                  icon: Icons.female_rounded,
                                  isSelected: _selectedGender == 'Wanita',
                                  isDark: isDark,
                                  onTap: () => setState(() => _selectedGender = 'Wanita'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Notification Permission Callout Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF02539A).withOpacity(isDark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF55C7FF).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF55C7FF).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Color(0xFF55C7FF),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Izin Notifikasi Otomatis',
                                style: GoogleFonts.interTight(
                                  color: textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Notifikasi sistem akan langsung diaktifkan saat memulai aplikasi untuk pengingat transaksi harian dan deteksi mutasi.',
                                style: GoogleFonts.manrope(
                                  color: textSecondary,
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Primary CTA
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF55C7FF) : const Color(0xFF0F172A),
                        foregroundColor: isDark ? const Color(0xFF09101C) : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Mulai Aplikasi',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0B2244) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: isSelected
              ? Border.all(
                  color: isDark ? const Color(0xFF55C7FF).withOpacity(0.4) : const Color(0xFFCBD5E1),
                )
              : null,
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF55C7FF)
                  : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B)),
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
