import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
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

    // Design System Tokens (Dark Matte Slate & Sapphire)
    const bgNavy = Color(0xFF081C41);
    final cardBg = isDark ? const Color(0xFF0C131D) : Colors.white;
    final cardBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final innerCardBg = isDark ? const Color(0xFF131A26) : const Color(0xFFF8FAFC);
    final innerCardBorder = isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE2E8F0);

    final labelColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF475569);
    final inputBg = isDark ? Colors.white.withOpacity(0.04) : Colors.white;
    final inputBorder = isDark ? Colors.white.withOpacity(0.09) : const Color(0xFFCBD5E1);
    final textInputColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final hintColor = isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8);
    final iconColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgNavy,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final contentWidth = isWide ? 440.0 : constraints.maxWidth;

          return Center(
            child: SizedBox(
              width: contentWidth,
              height: constraints.maxHeight,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // --- TOP BRAND HERO AREA (NAVY + PATTERN + Y EMBLEM) ---
                        Expanded(
                          child: Stack(
                            children: [
                              // Tiled pattern asset from user reference (Image 3)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Image.asset(
                                  'assets/images/onboarding_bg.png',
                                  fit: BoxFit.fitWidth,
                                  alignment: Alignment.topCenter,
                                ),
                              ),
                              // Seamless gradient fade into solid navy at top
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        bgNavy,
                                        Color(0x88081C41),
                                        Colors.transparent,
                                      ],
                                      stops: [0.0, 0.40, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              // Top Logo & Welcome Text
                              SafeArea(
                                bottom: false,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // White Y Emblem
                                        Image.asset(
                                          'assets/images/logo_splash.png',
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.contain,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Welcome to Yotro',
                                          style: GoogleFonts.manrope(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- BOTTOM SHEET & FORM CARD (APP DESIGN SYSTEM STYLE) ---
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                            border: Border(
                              top: BorderSide(color: cardBorder, width: 1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.45 : 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, -6),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: innerCardBg,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: innerCardBorder, width: 1),
                                ),
                                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Field 1: Nama Lengkap
                                    Text(
                                      'Nama Lengkap',
                                      style: GoogleFonts.manrope(
                                        color: labelColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 50,
                                      child: TextField(
                                        controller: _nameController,
                                        autofocus: false,
                                        textCapitalization: TextCapitalization.words,
                                        textAlignVertical: TextAlignVertical.center,
                                        style: GoogleFonts.manrope(
                                          color: textInputColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: inputBg,
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.person_outline_rounded,
                                            size: 19,
                                            color: iconColor,
                                          ),
                                          prefixIconConstraints: const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 50,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: BorderSide(color: inputBorder),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: BorderSide(color: inputBorder),
                                          ),
                                          focusedBorder: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(25)),
                                            borderSide: BorderSide(
                                              color: Color(0xFF02539A),
                                              width: 1.5,
                                            ),
                                          ),
                                          hintText: 'Masukkan nama lengkap',
                                          hintStyle: GoogleFonts.manrope(
                                            color: hintColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Field 2: No. Telp
                                    Text(
                                      'No. Telp',
                                      style: GoogleFonts.manrope(
                                        color: labelColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 50,
                                      child: TextField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        autofocus: false,
                                        textAlignVertical: TextAlignVertical.center,
                                        style: GoogleFonts.manrope(
                                          color: textInputColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: inputBg,
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.phone_outlined,
                                            size: 19,
                                            color: iconColor,
                                          ),
                                          prefixIconConstraints: const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 50,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: BorderSide(color: inputBorder),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: BorderSide(color: inputBorder),
                                          ),
                                          focusedBorder: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(25)),
                                            borderSide: BorderSide(
                                              color: Color(0xFF02539A),
                                              width: 1.5,
                                            ),
                                          ),
                                          hintText: 'Masukkan nomor telepon',
                                          hintStyle: GoogleFonts.manrope(
                                            color: hintColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Primary CTA Button: Mulai Mencatat
                                    SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isSubmitting ? null : _handleSubmit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryButton,
                                          foregroundColor: Colors.white,
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
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Mulai Mencatat',
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    size: 18,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // Local Data Security Footnote
                                    Text(
                                      'Seluruh data tersimpan aman di perangkat lokal.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.manrope(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.4)
                                            : const Color(0xFF94A3B8),
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
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
