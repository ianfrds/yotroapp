import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/supabase_config.dart';
import '../providers/transaction_provider.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_sync_service.dart';
import '../widgets/app_snackbar.dart';
import 'main_shell.dart';
import 'onboarding_profile_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool fromSettings;

  const AuthScreen({
    super.key,
    this.fromSettings = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  static const Color _bgDark = Color(0xFF09101C);
  static const Color _cardDark = Color(0xFF131A26);
  static const Color _borderDark = Color(0x1FFFFFFF);
  static const Color _cyanAccent = Color(0xFF55C7FF);
  static const Color _sapphireBlue = Color(0xFF02539A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _formKey.currentState?.reset();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignUp(TransactionProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseAuthService.signUpWithEmail(
        email: email,
        password: password,
        fullName: name,
      );

      if (!mounted) return;

      if (response.session != null) {
        // Auto-confirmed session
        await provider.handleAuthSuccess(fullName: name);
        if (mounted) {
          AppSnackBar.show(
            context,
            'Pendaftaran berhasil. Selamat datang, $name!',
            type: SnackBarType.success,
          );
        }
        await _onAuthSuccessNavigate(provider, isNewUser: true);
      } else if (response.user != null) {
        // Email confirmation required
        if (mounted) {
          _showEmailConfirmationDialog(email);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          SupabaseAuthService.formatAuthException(e),
          type: SnackBarType.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEmailSignIn(TransactionProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseAuthService.signInWithEmail(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.session != null) {
        await provider.handleAuthSuccess();
        if (mounted) {
          AppSnackBar.show(
            context,
            'Berhasil masuk ke akun Yotro.',
            type: SnackBarType.success,
          );
        }
        await _onAuthSuccessNavigate(provider, isNewUser: false);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          SupabaseAuthService.formatAuthException(e),
          type: SnackBarType.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn(TransactionProvider provider) async {
    setState(() => _isLoading = true);

    try {
      final success = await SupabaseAuthService.signInWithGoogle();
      if (!success) {
        if (mounted) {
          AppSnackBar.show(
            context,
            'Proses login Google dibatalkan.',
            type: SnackBarType.info,
          );
        }
      } else {
        if (mounted) {
          await provider.handleAuthSuccess();
          await _onAuthSuccessNavigate(provider, isNewUser: false);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Gagal masuk dengan Google: $e',
          type: SnackBarType.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleContinueAsGuest(TransactionProvider provider) async {
    await provider.continueAsGuest(name: 'Pengguna Tamu');

    if (!mounted) return;

    if (widget.fromSettings) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MainShell(),
      ),
    );
  }

  Future<void> _onAuthSuccessNavigate(TransactionProvider provider, {required bool isNewUser}) async {
    if (!mounted) return;

    if (widget.fromSettings) {
      // Sync local data to newly logged in cloud account
      if (isNewUser) {
        await SupabaseSyncService.uploadAllLocalData(provider);
      } else {
        await SupabaseSyncService.pullCloudData(provider);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    // If new user, sync initial local defaults to cloud; if existing, pull remote
    if (isNewUser) {
      await SupabaseSyncService.uploadAllLocalData(provider);
    } else {
      await SupabaseSyncService.pullCloudData(provider);
    }

    if (!mounted) return;

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

  void _showEmailConfirmationDialog(String email) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? _cardDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Verifikasi Email Terkirim',
            style: GoogleFonts.interTight(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          content: Text(
            'Tautan konfirmasi pendaftaran telah dikirim ke $email. Silakan periksa kotak masuk atau spam email Anda untuk mengaktifkan akun, lalu masuk kembali.',
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              height: 1.5,
              color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF475569),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _tabController.animateTo(1); // Switch to Masuk tab
              },
              child: Text(
                'Buka Tab Masuk',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  color: _cyanAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? _cardDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Atur Ulang Kata Sandi',
            style: GoogleFonts.interTight(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan email akun Yotro Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.manrope(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'nama@email.com',
                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0C131D) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Batal',
                style: GoogleFonts.manrope(color: isDark ? Colors.white60 : Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  AppSnackBar.show(context, 'Masukkan format email yang valid', type: SnackBarType.danger);
                  return;
                }
                Navigator.of(ctx).pop();
                try {
                  await SupabaseAuthService.resetPassword(email);
                  if (context.mounted) {
                    AppSnackBar.show(
                      context,
                      'Tautan reset kata sandi telah dikirim ke $email',
                      type: SnackBarType.success,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppSnackBar.show(
                      context,
                      'Gagal kirim reset email: $e',
                      type: SnackBarType.danger,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyanAccent,
                foregroundColor: const Color(0xFF09101C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Kirim Tautan', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();

    final bgColor = isDark ? _bgDark : const Color(0xFFF8FAFC);
    final cardBg = isDark ? _cardDark : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF0B121E) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? _borderDark : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button if opened from Settings
                    if (widget.fromSettings)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: textColor,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),

                    // App Emblem & Branding
                    Center(
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_cyanAccent, _sapphireBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _cyanAccent.withOpacity(0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Y',
                          style: GoogleFonts.interTight(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // App Title & Tagline
                    Center(
                      child: Text(
                        'Yotro',
                        style: GoogleFonts.interTight(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Kelola Keuangan Lebih Tenang & Terkendali',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: mutedColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Main Container Card
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tab Bar: Daftar vs Masuk
                          Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2838) : Colors.white,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              labelColor: isDark ? Colors.white : const Color(0xFF0F172A),
                              unselectedLabelColor: mutedColor,
                              labelStyle: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              unselectedLabelStyle: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              tabs: const [
                                Tab(text: 'Daftar Baru'),
                                Tab(text: 'Masuk'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Form Fields based on Selected Tab
                          AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, _) {
                              final isSignUp = _tabController.index == 0;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Name input (Only for Daftar tab)
                                  if (isSignUp) ...[
                                    _buildLabel('Nama Lengkap', textColor),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _nameController,
                                      style: GoogleFonts.manrope(color: textColor, fontSize: 14),
                                      decoration: _buildInputDecoration(
                                        hint: 'Contoh: Ian Firdaus',
                                        icon: Icons.person_outline_rounded,
                                        inputBg: inputBg,
                                        borderColor: borderColor,
                                        mutedColor: mutedColor,
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Nama lengkap wajib diisi';
                                        }
                                        if (val.trim().length < 2) {
                                          return 'Nama terlalu pendek (min. 2 karakter)';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                  ],

                                  // Email input (Both tabs)
                                  _buildLabel('Email', textColor),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: GoogleFonts.manrope(color: textColor, fontSize: 14),
                                    decoration: _buildInputDecoration(
                                      hint: 'nama@email.com',
                                      icon: Icons.mail_outline_rounded,
                                      inputBg: inputBg,
                                      borderColor: borderColor,
                                      mutedColor: mutedColor,
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Email wajib diisi';
                                      }
                                      final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
                                      if (!emailRegex.hasMatch(val.trim())) {
                                        return 'Format email tidak valid';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Password input (Both tabs)
                                  _buildLabel('Kata Sandi', textColor),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    style: GoogleFonts.manrope(color: textColor, fontSize: 14),
                                    decoration: _buildInputDecoration(
                                      hint: isSignUp ? 'Minimal 6 karakter' : 'Masukkan kata sandi',
                                      icon: Icons.lock_outline_rounded,
                                      inputBg: inputBg,
                                      borderColor: borderColor,
                                      mutedColor: mutedColor,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: mutedColor,
                                          size: 19,
                                        ),
                                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Kata sandi wajib diisi';
                                      }
                                      if (isSignUp && val.length < 6) {
                                        return 'Kata sandi minimal 6 karakter';
                                      }
                                      return null;
                                    },
                                  ),

                                  // Confirm Password (Only for Daftar tab)
                                  if (isSignUp) ...[
                                    const SizedBox(height: 14),
                                    _buildLabel('Ulangi Kata Sandi', textColor),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: !_isConfirmPasswordVisible,
                                      style: GoogleFonts.manrope(color: textColor, fontSize: 14),
                                      decoration: _buildInputDecoration(
                                        hint: 'Ketik ulang kata sandi',
                                        icon: Icons.lock_reset_rounded,
                                        inputBg: inputBg,
                                        borderColor: borderColor,
                                        mutedColor: mutedColor,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isConfirmPasswordVisible
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                            color: mutedColor,
                                            size: 19,
                                          ),
                                          onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                                        ),
                                      ),
                                      validator: (val) {
                                        if (val == null || val.isEmpty) {
                                          return 'Konfirmasi kata sandi wajib diisi';
                                        }
                                        if (val != _passwordController.text) {
                                          return 'Konfirmasi kata sandi tidak cocok';
                                        }
                                        return null;
                                      },
                                    ),
                                  ] else ...[
                                    // Forgot password link on Masuk tab
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _showForgotPasswordDialog,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Lupa kata sandi?',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _cyanAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 20),

                                  // Primary Action Button
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => isSignUp
                                              ? _handleEmailSignUp(provider)
                                              : _handleEmailSignIn(provider),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _cyanAccent,
                                        foregroundColor: const Color(0xFF09101C),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Color(0xFF09101C),
                                              ),
                                            )
                                          : Text(
                                              isSignUp ? 'Daftar Akun Baru' : 'Masuk ke Akun',
                                              style: GoogleFonts.manrope(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.1,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 18),

                          // Divider "atau"
                          Row(
                            children: [
                              Expanded(child: Divider(color: borderColor)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'atau',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: mutedColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: borderColor)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Google Sign-In Button
                          SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () => _handleGoogleSignIn(provider),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF0E1521) : const Color(0xFFF8FAFC),
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildCleanGoogleIcon(),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Lanjutkan dengan Google',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Guest / Skip Mode Action
                    Material(
                      color: isDark ? const Color(0xFF101724) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        key: const Key('btn_guest_mode'),
                        onTap: _isLoading ? null : () => _handleContinueAsGuest(provider),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFF172030) : const Color(0xFFF1F5F9),
                              ),
                              child: Icon(
                                Icons.offline_bolt_outlined,
                                color: _cyanAccent,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lewati / Masuk sebagai Tamu',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    'Mode 100% lokal tanpa sinkronisasi cloud',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      color: mutedColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: mutedColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color textColor) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    required Color inputBg,
    required Color borderColor,
    required Color mutedColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(fontSize: 13, color: mutedColor),
      prefixIcon: Icon(icon, size: 19, color: mutedColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cyanAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  Widget _buildCleanGoogleIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Text(
        'G',
        style: GoogleFonts.interTight(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF4285F4),
        ),
      ),
    );
  }
}
