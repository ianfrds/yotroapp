import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/wallet_model.dart';
import '../providers/transaction_provider.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_sync_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/modal_card_sheet.dart';
import 'edit_category_screen.dart';
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
  int _currentStep = 0; // 0: Auth Gate, 1: Data Diri, 2: Tema, 3: Dompet, 4: Kategori
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSignUpMode = false;
  bool _obscurePassword = true;
  String _selectedGender = 'Pria';
  TransactionType _selectedCategoryType = TransactionType.expense;
  Set<String> _selectedCategoryIds = {};
  bool _isSubmitting = false;
  bool _isAuthLoading = false;
  bool _isHandlingSuccess = false;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    if (SupabaseAuthService.isAuthenticated) {
      final cloudName = SupabaseAuthService.userName;
      if (cloudName != null && cloudName.isNotEmpty) {
        _nameController.text = cloudName;
      }
    }
    _authSub = SupabaseAuthService.onAuthStateChange?.listen((event) async {
      if (!mounted) return;
      if (event.session != null && !_isHandlingSuccess) {
        final cloudName = SupabaseAuthService.userName;
        if (cloudName != null && cloudName.isNotEmpty && _nameController.text.trim().isEmpty) {
          _nameController.text = cloudName;
        }

        final isExisting = await SupabaseSyncService.hasExistingUserData();
        if (isExisting && mounted) {
          await _handleExistingUserAuthSuccess();
        } else if (_currentStep == 0 && mounted) {
          setState(() {
            _isAuthLoading = false;
            _currentStep = 1;
          });
        }
      } else {
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCategoryIds.isEmpty) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      _selectedCategoryIds = provider.categories.map((c) => c.id).toSet();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        AppSnackBar.show(
          context,
          'Nama lengkap wajib diisi untuk melanjutkan',
          type: SnackBarType.danger,
        );
        return;
      }
    }

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _handleExistingUserAuthSuccess() async {
    if (_isHandlingSuccess) return;
    _isHandlingSuccess = true;

    final provider = context.read<TransactionProvider>();

    try {
      // 1. Tarik seluruh data yang ada dari cloud
      await SupabaseSyncService.pullCloudData(provider);

      // 2. Jika dompet di cloud kosong, upload default lokal agar aman
      if (provider.wallets.isEmpty) {
        await SupabaseSyncService.uploadAllLocalData(provider);
      }

      // 3. Lengkapi onboarding & tandai selesai
      final name = SupabaseAuthService.userName ?? provider.userName;
      await provider.completeOnboarding(
        name: name,
        phone: provider.userPhone,
        gender: provider.userGender,
      );
      await provider.handleAuthSuccess(fullName: name);

      if (!mounted) return;

      AppSnackBar.show(
        context,
        'Selamat datang kembali, $name!',
        type: SnackBarType.success,
      );

      // 4. Langsung navigasi ke Beranda (MainShell) tanpa setup ulang
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('[Onboarding] Error saat handleExistingUserAuthSuccess: $e');
      if (mounted) {
        final name = SupabaseAuthService.userName ?? provider.userName;
        await provider.completeOnboarding(
          name: name,
          phone: provider.userPhone,
          gender: provider.userGender,
        );
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MainShell(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
            (route) => false,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isAuthLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isAuthLoading = true);
    try {
      await SupabaseAuthService.signInWithGoogle();
      final name = SupabaseAuthService.userName;
      if (name != null && name.isNotEmpty && _nameController.text.trim().isEmpty) {
        _nameController.text = name;
      }
      if (mounted) {
        final isExisting = await SupabaseSyncService.hasExistingUserData();
        if (isExisting) {
          await _handleExistingUserAuthSuccess();
          return;
        }
        if (SupabaseAuthService.isAuthenticated) {
          AppSnackBar.show(
            context,
            'Berhasil menghubungkan akun Google. Lengkapi data awal Anda.',
            type: SnackBarType.success,
          );
          setState(() {
            _currentStep = 1;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Login Google gagal: $e',
          type: SnackBarType.danger,
        );
      }
    } finally {
      if (mounted && !_isHandlingSuccess) setState(() => _isAuthLoading = false);
    }
  }

  Future<void> _handleEmailAuth(BuildContext context) async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;

    if (email.isEmpty || pass.isEmpty) {
      AppSnackBar.show(context, 'Email dan kata sandi wajib diisi', type: SnackBarType.danger);
      return;
    }
    if (pass.length < 6) {
      AppSnackBar.show(context, 'Kata sandi minimal 6 karakter', type: SnackBarType.danger);
      return;
    }

    setState(() => _isAuthLoading = true);
    try {
      if (_isSignUpMode) {
        // Tab Daftar Baru -> Pendaftaran baru, lanjutkan ke Step 1
        await SupabaseAuthService.signUpWithEmail(
          email: email,
          password: pass,
          fullName: email.split('@').first,
        );
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = email.split('@').first;
        }
        if (mounted) {
          AppSnackBar.show(
            context,
            'Pendaftaran berhasil! Lengkapi data diri Anda.',
            type: SnackBarType.success,
          );
          setState(() {
            _currentStep = 1;
          });
        }
      } else {
        // Tab Masuk -> Akun sudah terdaftar! Langsung masuk ke Beranda
        await SupabaseAuthService.signInWithEmail(email: email, password: pass);
        if (mounted) {
          await _handleExistingUserAuthSuccess();
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Autentikasi gagal: $e', type: SnackBarType.danger);
      }
    } finally {
      if (mounted && !_isHandlingSuccess) setState(() => _isAuthLoading = false);
    }
  }

  Future<void> _handleContinueAsGuest(BuildContext context) async {
    final provider = context.read<TransactionProvider>();
    await provider.continueAsGuest();
    if (mounted) {
      setState(() {
        _currentStep = 1;
      });
    }
  }

  void _showForgotPasswordSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emailController = TextEditingController(text: _emailController.text.trim());
    bool isLoading = false;

    showModalCardSheet(
      context: context,
      title: 'Lupa Kata Sandi',
      titleIcon: Icons.lock_reset_rounded,
      titleIconColor: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
          final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
          final inputBg = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9);
          final inputBorder = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFCBD5E1);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Masukkan alamat email akun cloud Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.',
                style: GoogleFonts.manrope(
                  color: mutedColor,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Alamat Email',
                style: GoogleFonts.manrope(
                  color: mutedColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 46,
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.manrope(color: textColor, fontSize: 13.5),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
                      size: 18,
                      color: mutedColor,
                    ),
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
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
                        width: 1.5,
                      ),
                    ),
                    hintText: 'nama@email.com',
                    hintStyle: GoogleFonts.manrope(
                      color: isDark ? const Color(0xFF6C7D93) : const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            AppSnackBar.show(
                              context,
                              'Masukkan alamat email yang valid.',
                              type: SnackBarType.danger,
                            );
                            return;
                          }
                          setSheetState(() => isLoading = true);
                          try {
                            await SupabaseAuthService.resetPassword(email);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              AppSnackBar.show(
                                context,
                                'Tautan reset kata sandi telah dikirim ke $email',
                                type: SnackBarType.success,
                              );
                            }
                          } catch (e) {
                            setSheetState(() => isLoading = false);
                            if (context.mounted) {
                              AppSnackBar.show(
                                context,
                                SupabaseAuthService.formatAuthException(e),
                                type: SnackBarType.danger,
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02539A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Kirim Tautan Reset',
                          style: GoogleFonts.manrope(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
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

  Future<void> _finishOnboarding() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      setState(() => _currentStep = 1);
      AppSnackBar.show(
        context,
        'Nama lengkap wajib diisi untuk memulai aplikasi',
        type: SnackBarType.danger,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<TransactionProvider>();

    // Persist chosen categories if user customized them
    if (_selectedCategoryIds.isNotEmpty) {
      final chosen = provider.categories
          .where((c) => _selectedCategoryIds.contains(c.id))
          .toList();
      if (chosen.isNotEmpty) {
        await provider.setSelectedCategories(chosen);
      }
    }

    if (SupabaseAuthService.isAuthenticated) {
      await provider.completeOnboarding(
        name: name,
        phone: phone,
        gender: _selectedGender,
      );
      await provider.handleAuthSuccess(fullName: name);
      await SupabaseSyncService.uploadAllLocalData(provider);
    } else {
      await provider.continueAsGuest(name: name);
      await provider.completeOnboarding(
        name: name,
        phone: phone,
        gender: _selectedGender,
      );
    }

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

  void _showAddWalletModal(BuildContext context, TransactionProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    String selectedType = 'Bank';

    final sheetBg = isDark ? const Color(0xFF0C131D) : Colors.white;
    final cardBg = isDark ? const Color(0xFF131A26) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 24),
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: borderColor),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tambah Dompet Baru',
                        style: GoogleFonts.interTight(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded, size: 20, color: mutedColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Nama Dompet / Rekening',
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      style: GoogleFonts.manrope(color: textColor, fontSize: 13.5),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Misal: BCA, Mandiri, GoPay, Tunai',
                        hintStyle: GoogleFonts.manrope(color: mutedColor.withOpacity(0.6), fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Tipe Dompet',
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Bank', 'E-Wallet', 'Cash'].map((t) {
                      final isSelected = selectedType == t;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => setModalState(() => selectedType = t),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryButton
                                    : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryButton : borderColor,
                                ),
                              ),
                              child: Text(
                                t,
                                style: GoogleFonts.manrope(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Saldo Awal (Opsional)',
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: balanceCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.manrope(color: textColor, fontSize: 13.5),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        prefixText: 'Rp ',
                        prefixStyle: GoogleFonts.manrope(color: textColor, fontWeight: FontWeight.w600),
                        hintText: '0',
                        hintStyle: GoogleFonts.manrope(color: mutedColor.withOpacity(0.6), fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryButton,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        final balance = double.tryParse(balanceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                        await provider.addWallet(
                          name: name,
                          type: selectedType,
                          initialBalance: balance,
                          syncToTransaction: false,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          AppSnackBar.show(context, 'Dompet "$name" berhasil ditambahkan', type: SnackBarType.success);
                        }
                      },
                      child: Text(
                        'Simpan Dompet',
                        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: _currentStep == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _currentStep > 0) {
            _prevStep();
          }
        },
        child: Scaffold(
          backgroundColor: bgNavy,
          resizeToAvoidBottomInset: true,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final contentWidth = isWide ? 460.0 : constraints.maxWidth;
              final isCompactHero = _currentStep <= 1;
              final heroHeight = isCompactHero ? 155.0 : 225.0;
              final minCardHeight = (constraints.maxHeight - heroHeight).clamp(0.0, double.infinity);

              return Center(
                child: SizedBox(
                  width: contentWidth,
                  height: constraints.maxHeight,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- TOP BRAND HERO AREA (NAVY + PATTERN + Y EMBLEM) ---
                        SizedBox(
                          height: heroHeight,
                          child: Stack(
                            children: [
                              // Tiled pattern asset
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
                                  padding: EdgeInsets.only(top: isCompactHero ? 16 : 36),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/images/logo_splash.png',
                                          width: isCompactHero ? 36 : 48,
                                          height: isCompactHero ? 36 : 48,
                                          fit: BoxFit.contain,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: isCompactHero ? 8 : 12),
                                        Text(
                                          'Welcome to Yotro',
                                          style: GoogleFonts.manrope(
                                            color: Colors.white,
                                            fontSize: isCompactHero ? 15.5 : 17,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        if (_currentStep >= 1) ...[
                                          SizedBox(height: isCompactHero ? 12 : 18),
                                          // Step Progress Indicator
                                          _buildStepIndicator(),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- BOTTOM SHEET & FORM CARD ---
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: minCardHeight,
                          ),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(28),
                              ),
                              border: Border(
                                top: BorderSide(color: cardBorder, width: 1),
                              ),
                            ),
                            child: SafeArea(
                              top: false,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(22, isCompactHero ? 14 : 22, 22, isCompactHero ? 14 : 24),
                                child: _buildStepContent(
                                  context,
                                  provider,
                                  isDark,
                                  labelColor,
                                  inputBg,
                                  inputBorder,
                                  textInputColor,
                                  hintColor,
                                  iconColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    if (_currentStep == 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final stepNum = index + 1; // 1: Data Diri, 2: Tema, 3: Dompet, 4: Kategori
        final isActive = stepNum == _currentStep;
        final isCompleted = stepNum < _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24.0 : 8.0,
          height: 3.5,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : (isCompleted
                    ? Colors.white.withOpacity(0.65)
                    : Colors.white.withOpacity(0.22)),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    TransactionProvider provider,
    bool isDark,
    Color labelColor,
    Color inputBg,
    Color inputBorder,
    Color textInputColor,
    Color hintColor,
    Color iconColor,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildStep0AuthGate(
          context,
          provider,
          isDark,
          labelColor,
          inputBg,
          inputBorder,
          textInputColor,
          hintColor,
          iconColor,
        );
      case 1:
        return _buildStep1Profile(
          context,
          isDark,
          labelColor,
          inputBg,
          inputBorder,
          textInputColor,
          hintColor,
          iconColor,
        );
      case 2:
        return _buildStep2ThemeAndPreferences(context, provider, isDark, labelColor, textInputColor);
      case 3:
        return _buildStep3Wallets(context, provider, isDark, labelColor, textInputColor);
      case 4:
      default:
        return _buildStep4Categories(context, provider, isDark, labelColor, textInputColor);
    }
  }

  // --- STEP 0: AUTH GATE (EMAIL & PASS, GOOGLE, MASUK TANPA AKUN) ---
  Widget _buildStep0AuthGate(
    BuildContext context,
    TransactionProvider provider,
    bool isDark,
    Color labelColor,
    Color inputBg,
    Color inputBorder,
    Color textInputColor,
    Color hintColor,
    Color iconColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Subtitle
        Text(
          _isSignUpMode ? 'Daftar Akun Baru' : 'Masuk ke Akun Anda',
          style: GoogleFonts.interTight(
            color: textInputColor,
            fontSize: 16.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _isSignUpMode
              ? 'Daftar untuk backup cloud otomatis & akses multi-perangkat'
              : 'Gunakan email atau Google untuk sinkronisasi data cloud',
          style: GoogleFonts.manrope(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),

        // Segmented Switcher: Masuk vs Daftar Baru
        Container(
          height: 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131A26) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: inputBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isSignUpMode = false),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !_isSignUpMode ? AppColors.primaryButton : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      'Masuk',
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: !_isSignUpMode ? Colors.white : labelColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isSignUpMode = true),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isSignUpMode ? AppColors.primaryButton : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      'Daftar Baru',
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _isSignUpMode ? Colors.white : labelColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Field Email
        Text(
          'Alamat Email',
          style: GoogleFonts.manrope(
            color: labelColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 46,
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: false,
            textAlignVertical: TextAlignVertical.center,
            style: GoogleFonts.manrope(
              color: textInputColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputBg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: Icon(Icons.email_outlined, size: 18, color: iconColor),
              prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 46),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: inputBorder),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFF02539A), width: 1.5),
              ),
              hintText: 'nama@domain.com',
              hintStyle: GoogleFonts.manrope(
                color: hintColor,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Field Kata Sandi
        Text(
          'Kata Sandi',
          style: GoogleFonts.manrope(
            color: labelColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 46,
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofocus: false,
            textAlignVertical: TextAlignVertical.center,
            style: GoogleFonts.manrope(
              color: textInputColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputBg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: iconColor),
              prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 46),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: iconColor,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: inputBorder),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFF02539A), width: 1.5),
              ),
              hintText: 'Minimal 6 karakter',
              hintStyle: GoogleFonts.manrope(
                color: hintColor,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        if (!_isSignUpMode) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordSheet(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Lupa kata sandi?',
                style: GoogleFonts.manrope(
                  color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ] else ...[
          const SizedBox(height: 14),
        ],

        // Button Masuk / Daftar
        SizedBox(
          height: 46,
          child: ElevatedButton(
            onPressed: _isAuthLoading ? null : () => _handleEmailAuth(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryButton,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isAuthLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _isSignUpMode ? 'Daftar Akun' : 'Masuk',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: inputBorder, height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'atau lanjutkan dengan',
                style: GoogleFonts.manrope(fontSize: 11, color: labelColor.withOpacity(0.7)),
              ),
            ),
            Expanded(child: Divider(color: inputBorder, height: 1)),
          ],
        ),
        const SizedBox(height: 12),

        // Tombol Google
        SizedBox(
          height: 46,
          child: OutlinedButton(
            onPressed: _isAuthLoading ? null : _handleGoogleSignIn,
            style: OutlinedButton.styleFrom(
              backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
              side: BorderSide(color: inputBorder),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isAuthLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.g_mobiledata_rounded, size: 26, color: Color(0xFF4285F4)),
                        const SizedBox(width: 4),
                        Text(
                          'Lanjutkan dengan Google',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textInputColor,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),

        // Tombol Masuk Tanpa Akun
        Center(
          child: TextButton(
            onPressed: _isAuthLoading ? null : () => _handleContinueAsGuest(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
            child: Text(
              'Masuk tanpa akun',
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 1: PROFIL & DATA DIRI ---
  Widget _buildStep1Profile(
    BuildContext context,
    bool isDark,
    Color labelColor,
    Color inputBg,
    Color inputBorder,
    Color textInputColor,
    Color hintColor,
    Color iconColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (SupabaseAuthService.isAuthenticated) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131A26) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF38BDF8).withOpacity(0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF38BDF8), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Akun Cloud Terhubung',
                        style: GoogleFonts.interTight(
                          color: textInputColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        SupabaseAuthService.userEmail ?? '',
                        style: GoogleFonts.manrope(
                          color: labelColor,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await SupabaseAuthService.signOut();
                    setState(() {
                      _currentStep = 0;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Ganti',
                    style: GoogleFonts.manrope(
                      color: const Color(0xFFE05362),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131A26) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline_rounded, color: labelColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode Tamu (Offline)',
                        style: GoogleFonts.interTight(
                          color: textInputColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Data disimpan 100% lokal di perangkat ini',
                        style: GoogleFonts.manrope(
                          color: labelColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Masuk',
                    style: GoogleFonts.manrope(
                      color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        Text(
          'Data Diri',
          style: GoogleFonts.interTight(
            color: textInputColor,
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          SupabaseAuthService.isAuthenticated
              ? 'Periksa dan sesuaikan nama untuk profil keuangan Anda'
              : 'Lengkapi identitas untuk memulai pencatatan keuangan',
          style: GoogleFonts.manrope(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),

        // Field: Nama Lengkap
        Text(
          'Nama Lengkap',
          style: GoogleFonts.manrope(
            color: labelColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 46,
          child: TextField(
            controller: _nameController,
            autofocus: false,
            textCapitalization: TextCapitalization.words,
            textAlignVertical: TextAlignVertical.center,
            style: GoogleFonts.manrope(
              color: textInputColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputBg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: Icon(Icons.person_outline_rounded, size: 18, color: iconColor),
              prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 46),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: inputBorder),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFF02539A), width: 1.5),
              ),
              hintText: 'Masukkan nama lengkap',
              hintStyle: GoogleFonts.manrope(
                color: hintColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Field: No. Telp
        Text(
          'No. Telp',
          style: GoogleFonts.manrope(
            color: labelColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 46,
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            autofocus: false,
            textAlignVertical: TextAlignVertical.center,
            style: GoogleFonts.manrope(
              color: textInputColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputBg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: Icon(Icons.phone_outlined, size: 18, color: iconColor),
              prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 46),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: inputBorder),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFF02539A), width: 1.5),
              ),
              hintText: 'Masukkan nomor telepon',
              hintStyle: GoogleFonts.manrope(
                color: hintColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Field: Jenis Kelamin
        Text(
          'Jenis Kelamin',
          style: GoogleFonts.manrope(
            color: labelColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildGenderOption('Pria', Icons.male_rounded, isDark, inputBorder),
            const SizedBox(width: 10),
            _buildGenderOption('Wanita', Icons.female_rounded, isDark, inputBorder),
          ],
        ),
        const SizedBox(height: 16),

        // Action Buttons Row: Lanjutkan & Mulai Cepat
        SizedBox(
          height: 46,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryButton,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lanjutkan',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: _finishOnboarding,
            child: Text(
              'Mulai Mencatat',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon, bool isDark, Color inputBorder) {
    final isSelected = _selectedGender == gender;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedGender = gender),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryButton
                : (isDark ? Colors.white.withOpacity(0.04) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primaryButton : inputBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Text(
                gender,
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STEP 2: TEMA & PREFERENSI TAMPILAN ---
  Widget _buildStep2ThemeAndPreferences(
    BuildContext context,
    TransactionProvider provider,
    bool isDark,
    Color labelColor,
    Color textInputColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, size: 20, color: labelColor),
              onPressed: _prevStep,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tema & Tampilan',
                style: GoogleFonts.interTight(
                  color: textInputColor,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Section A: Mode Tampilan
        Text(
          'Mode Tampilan',
          style: GoogleFonts.manrope(
            color: labelColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildThemeOption(
              label: 'Sistem',
              icon: Icons.brightness_auto_rounded,
              mode: ThemeMode.system,
              currentMode: provider.themeMode,
              onTap: () => provider.setThemeMode(ThemeMode.system),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildThemeOption(
              label: 'Terang',
              icon: Icons.light_mode_rounded,
              mode: ThemeMode.light,
              currentMode: provider.themeMode,
              onTap: () => provider.setThemeMode(ThemeMode.light),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildThemeOption(
              label: 'Gelap',
              icon: Icons.dark_mode_rounded,
              mode: ThemeMode.dark,
              currentMode: provider.themeMode,
              onTap: () => provider.setThemeMode(ThemeMode.dark),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Section B: Preferensi Tampilan Dashboard
        Text(
          'Preferensi Tampilan Beranda',
          style: GoogleFonts.manrope(
            color: labelColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            _buildDashboardOption(
              title: 'Mode Lengkap',
              subtitle: 'Saldo saat ini, pemasukan & pengeluaran',
              mode: DashboardViewMode.complete,
              currentMode: provider.dashboardViewMode,
              onTap: () => provider.setDashboardViewMode(DashboardViewMode.complete),
              isDark: isDark,
            ),
            const SizedBox(height: 6),
            _buildDashboardOption(
              title: 'Masuk & Keluar',
              subtitle: 'Fokus perputaran arus kas 2 arah',
              mode: DashboardViewMode.incomeExpense,
              currentMode: provider.dashboardViewMode,
              onTap: () => provider.setDashboardViewMode(DashboardViewMode.incomeExpense),
              isDark: isDark,
            ),
            const SizedBox(height: 6),
            _buildDashboardOption(
              title: 'Pengeluaran Saja',
              subtitle: 'Fokus kontrol hemat dan limit belanja',
              mode: DashboardViewMode.expenseOnly,
              currentMode: provider.dashboardViewMode,
              onTap: () => provider.setDashboardViewMode(DashboardViewMode.expenseOnly),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Navigation Row
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _nextStep,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Lewati',
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lanjutkan',
                          style: GoogleFonts.manrope(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final isSelected = mode == currentMode;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryButton.withOpacity(0.15)
                : (isDark ? Colors.white.withOpacity(0.04) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryButton
                  : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1)),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? (isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A))
                    : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardOption({
    required String title,
    required String subtitle,
    required DashboardViewMode mode,
    required DashboardViewMode currentMode,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final isSelected = mode == currentMode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryButton.withOpacity(0.12)
              : (isDark ? Colors.white.withOpacity(0.03) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryButton
                : (isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 18,
              color: isSelected ? const Color(0xFF55C7FF) : (isDark ? const Color(0xFF65788F) : const Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.interTight(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 3: ATUR DOMPET ---
  Widget _buildStep3Wallets(
    BuildContext context,
    TransactionProvider provider,
    bool isDark,
    Color labelColor,
    Color textInputColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, size: 20, color: labelColor),
              onPressed: _prevStep,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Atur Dompet & Rekening',
                style: GoogleFonts.interTight(
                  color: textInputColor,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Daftar dompet aktif Anda. Tambah dompet baru jika diperlukan.',
          style: GoogleFonts.manrope(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),

        // Wallet list
        Column(
          children: provider.wallets.take(6).map((wallet) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryButton.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        wallet.type == 'Cash'
                            ? Icons.account_balance_wallet_outlined
                            : (wallet.type == 'Bank' ? Icons.account_balance_outlined : Icons.phone_android_rounded),
                        size: 16,
                        color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet.name,
                            style: GoogleFonts.interTight(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textInputColor,
                            ),
                          ),
                          Text(
                            wallet.type,
                            style: GoogleFonts.manrope(
                              fontSize: 10.5,
                              color: labelColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      provider.formatCurrency(wallet.balance),
                      style: GoogleFonts.interTight(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textInputColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Button: Tambah Dompet Baru
        SizedBox(
          height: 42,
          child: OutlinedButton.icon(
            onPressed: () => _showAddWalletModal(context, provider),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? const Color(0xFF55C7FF).withOpacity(0.35) : const Color(0xFF02539A).withOpacity(0.35),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(Icons.add_rounded, size: 18, color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A)),
            label: Text(
              'Tambah Dompet Baru',
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Navigation Row
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _nextStep,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Lewati',
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lanjutkan',
                          style: GoogleFonts.manrope(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- STEP 4: KATEGORI TRANSAKSI ---
  Widget _buildStep4Categories(
    BuildContext context,
    TransactionProvider provider,
    bool isDark,
    Color labelColor,
    Color textInputColor,
  ) {
    final filteredCategories = provider.categories
        .where((c) => c.type == _selectedCategoryType)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, size: 20, color: labelColor),
              onPressed: _prevStep,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Kategori Transaksi',
                style: GoogleFonts.interTight(
                  color: textInputColor,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Pilih kategori yang Anda butuhkan (ketuk untuk memilih) atau tambah baru.',
          style: GoogleFonts.manrope(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),

        // Segmented Switcher: Pengeluaran / Pemasukan
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedCategoryType = TransactionType.expense),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedCategoryType == TransactionType.expense
                          ? AppColors.primaryButton
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pengeluaran',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedCategoryType == TransactionType.expense ? Colors.white : labelColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedCategoryType = TransactionType.income),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedCategoryType == TransactionType.income
                          ? AppColors.primaryButton
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pemasukan',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedCategoryType == TransactionType.income ? Colors.white : labelColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Category grid preview (selectable chips)
        Wrap(
              spacing: 6,
              runSpacing: 6,
              children: filteredCategories.map((c) {
                final isSelected = _selectedCategoryIds.contains(c.id);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        final selectedCount = filteredCategories
                            .where((cat) => _selectedCategoryIds.contains(cat.id))
                            .length;
                        if (selectedCount <= 1) {
                          AppSnackBar.show(
                            context,
                            'Minimal pilih 1 kategori ${_selectedCategoryType == TransactionType.expense ? "pengeluaran" : "pemasukan"}',
                            type: SnackBarType.info,
                          );
                          return;
                        }
                        _selectedCategoryIds.remove(c.id);
                      } else {
                        _selectedCategoryIds.add(c.id);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? const Color(0xFF02539A).withOpacity(0.35)
                              : const Color(0xFF02539A).withOpacity(0.12))
                          : (isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A))
                            : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (c.emoji != null && c.emoji!.isNotEmpty)
                          Text(c.emoji!, style: const TextStyle(fontSize: 13))
                        else
                          Icon(
                            c.icon ?? Icons.category_rounded,
                            size: 14,
                            color: isSelected
                                ? (isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A))
                                : (isDark ? const Color(0xFF72849A) : const Color(0xFF94A3B8)),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          c.name,
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? Colors.white : const Color(0xFF02539A))
                                : (isDark ? const Color(0xFF72849A) : const Color(0xFF94A3B8)),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 10),

        // Action: Tambah Kategori Baru
        SizedBox(
          height: 42,
          child: OutlinedButton.icon(
            onPressed: () async {
              final newCat = await EditCategoryScreen.showAsModalSheet(
                context,
                initialType: _selectedCategoryType,
              );
              if (newCat != null && context.mounted) {
                setState(() {
                  _selectedCategoryIds.add(newCat.id);
                });
                AppSnackBar.show(context, 'Kategori "${newCat.name}" berhasil ditambahkan & dipilih', type: SnackBarType.success);
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? const Color(0xFF55C7FF).withOpacity(0.35) : const Color(0xFF02539A).withOpacity(0.35),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(Icons.add_rounded, size: 18, color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A)),
            label: Text(
              'Tambah Kategori Baru',
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Navigation Row: Lewati & Mulai Mencatat
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _finishOnboarding,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Lewati',
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Mulai Mencatat',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
