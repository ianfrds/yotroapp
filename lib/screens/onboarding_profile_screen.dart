import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../widgets/app_snackbar.dart';
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
    final scaffoldBg = isDark ? const Color(0xFF070B12) : const Color(0xFFEDEFF3);
    final cardBg = isDark ? const Color(0xFF0C131D) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF141C28) : const Color(0xFFF8FAFC);
    final inputBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final cardTopBorder = isDark ? Colors.white.withOpacity(0.09) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final contentWidth = isWide ? 440.0 : constraints.maxWidth;

          return Stack(
            children: [
              // 1. Full-screen Atmospheric Fluted Glass Background
              Positioned.fill(
                child: Image.asset(
                  'assets/images/onboarding_bg.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.35),
                        const Color(0xFF09101C).withOpacity(0.65),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // 2. Interactive Foreground Flow
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 28,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: contentWidth,
                        minHeight: constraints.maxHeight - (isWide ? 40 : 10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Header: Brand Emblem & Welcome Title
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
                            child: Column(
                              children: [
                                // Official Yotro Emblem
                                Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0066FF),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0066FF).withOpacity(0.35),
                                        blurRadius: 22,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 62,
                                    height: 62,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Headline
                                Text(
                                  'Selamat Datang',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.interTight(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Subtitle
                                Text(
                                  'Lengkapi identitas Anda untuk personalisasi akun Yotro. Seluruh data tersimpan 100% aman di perangkat lokal.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 12.5,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Floating Frosted Form Card Container
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 0 : 16,
                              vertical: 10,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0C131D).withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.12),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.40),
                                        blurRadius: 28,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: inputBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: inputBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFF55C7FF), width: 1.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

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
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: inputBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: inputBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFF55C7FF), width: 1.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

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
                                  height: 46,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: inputBg,
                                    borderRadius: BorderRadius.circular(16),
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
                                const SizedBox(height: 16),

                                // Notification Callout Card
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF02539A).withOpacity(isDark ? 0.14 : 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF55C7FF).withOpacity(0.25),
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
                                          borderRadius: BorderRadius.circular(10),
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
                                              'Notifikasi sistem akan langsung diaktifkan saat memulai aplikasi untuk pengingat transaksi harian.',
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

                                // Primary CTA Button (Pill Stadium matching Image 3)
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting ? null : _handleSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? const Color(0xFF55C7FF) : const Color(0xFF0F172A),
                                      foregroundColor: isDark ? const Color(0xFF09101C) : Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
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
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward_rounded, size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Security footnote
                                Center(
                                  child: Text(
                                    'Seluruh data tersimpan 100% aman di perangkat lokal.',
                                    style: GoogleFonts.manrope(
                                      color: textSecondary.withOpacity(0.85),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
      borderRadius: BorderRadius.circular(13),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0B2244) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          border: isSelected
              ? Border.all(
                  color: isDark ? const Color(0xFF55C7FF).withOpacity(0.45) : const Color(0xFFCBD5E1),
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
