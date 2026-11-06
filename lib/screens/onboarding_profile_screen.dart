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
      gender: 'Pria',
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
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF141C28) : const Color(0xFFF8FAFC);
    final inputBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final contentWidth = isWide ? 400.0 : constraints.maxWidth;

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
                        Colors.black.withOpacity(0.18),
                        Colors.black.withOpacity(0.38),
                        const Color(0xFF09101C).withOpacity(0.70),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // 2. Centered Non-Scrolling Onboarding Card
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // App Emblem
                          Center(
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFF02539A),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF02539A).withOpacity(0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Heading
                          Text(
                            'Selamat Datang',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.interTight(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Clean single-line subtitle
                          Text(
                            'Lengkapi identitas Anda untuk personalisasi akun.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Floating Frosted Form Card Container
                          ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0C131D).withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.10),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.35),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Field 1: Nama Lengkap
                                    Text(
                                      'Nama Lengkap *',
                                      style: GoogleFonts.manrope(
                                        color: textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      height: 48,
                                      child: TextField(
                                        controller: _nameController,
                                        autofocus: true,
                                        textAlignVertical: TextAlignVertical.center,
                                        style: GoogleFonts.manrope(
                                          color: textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Contoh: John Doe',
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
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: inputBorder),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: inputBorder),
                                          ),
                                          focusedBorder: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(12)),
                                            borderSide: BorderSide(color: Color(0xFF02539A), width: 1.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Field 2: Nomor Telepon
                                    Text(
                                      'Nomor Telepon (Opsional)',
                                      style: GoogleFonts.manrope(
                                        color: textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      height: 48,
                                      child: TextField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        textAlignVertical: TextAlignVertical.center,
                                        style: GoogleFonts.manrope(
                                          color: textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
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
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: inputBorder),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: inputBorder),
                                          ),
                                          focusedBorder: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(12)),
                                            borderSide: BorderSide(color: Color(0xFF02539A), width: 1.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Primary CTA Button (Matching reference)
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _isSubmitting ? null : _handleSubmit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF02539A),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
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
                                            : Text(
                                                'Mulai Aplikasi',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Bottom Subtle Disclaimer
                          Text(
                            'Seluruh data tersimpan 100% aman di perangkat lokal.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
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
}
