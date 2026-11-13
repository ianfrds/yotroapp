import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseAuthService {
  static SupabaseClient? get client => SupabaseConfig.client;

  static bool get isConfigured => SupabaseConfig.isConfigured;

  static bool get isAuthenticated => client?.auth.currentUser != null;

  static User? get currentUser => client?.auth.currentUser;

  static String? get userEmail => currentUser?.email;

  static String? get userName {
    final meta = currentUser?.userMetadata;
    if (meta == null) return userEmail?.split('@').first;
    return meta['full_name'] as String? ??
        meta['name'] as String? ??
        userEmail?.split('@').first;
  }

  static String? get userAvatarUrl {
    final meta = currentUser?.userMetadata;
    return meta?['avatar_url'] as String? ?? meta?['picture'] as String?;
  }

  static Stream<AuthState>? get onAuthStateChange => client?.auth.onAuthStateChange;

  /// Sign In with Google via OAuth
  static Future<bool> signInWithGoogle() async {
    if (!SupabaseConfig.isInitialized || client == null) {
      throw StateError('Koneksi Supabase belum aktif atau Anon Key belum disetel.');
    }

    try {
      final success = await client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.yotro://login-callback',
        authScreenLaunchMode:
            kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
      return success;
    } catch (e) {
      debugPrint('[SupabaseAuthService] Gagal login Google: $e');
      rethrow;
    }
  }

  /// Delete authenticated user account & cascade all data on Supabase
  static Future<void> deleteUserAccount() async {
    if (!SupabaseConfig.isInitialized || client == null) {
      throw StateError('Koneksi Supabase belum aktif atau Anon Key belum disetel.');
    }
    if (!isAuthenticated) return;

    try {
      await client!.rpc('delete_user_account');
      await signOut();
    } catch (e) {
      debugPrint('[SupabaseAuthService] Gagal menghapus akun: $e');
      rethrow;
    }
  }

  /// Sign Up with Email, Password, and Full Name
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (!SupabaseConfig.isInitialized || client == null) {
      throw StateError('Koneksi Supabase belum aktif atau Anon Key belum disetel.');
    }

    try {
      final response = await client!.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
        },
      );
      return response;
    } catch (e) {
      debugPrint('[SupabaseAuthService] Gagal daftar email: $e');
      rethrow;
    }
  }

  /// Sign In with Email and Password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!SupabaseConfig.isInitialized || client == null) {
      throw StateError('Koneksi Supabase belum aktif atau Anon Key belum disetel.');
    }

    try {
      final response = await client!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('[SupabaseAuthService] Gagal login email: $e');
      rethrow;
    }
  }

  /// Update password for the currently signed-in user
  static Future<void> updatePassword(String newPassword) async {
    if (!SupabaseConfig.isInitialized || client == null || !isAuthenticated) {
      throw StateError('Anda harus terhubung ke akun cloud terlebih dahulu.');
    }

    try {
      await client!.auth.updateUser(
        UserAttributes(password: newPassword.trim()),
      );
    } catch (e) {
      debugPrint('[SupabaseAuthService] Gagal memperbarui kata sandi: $e');
      rethrow;
    }
  }

  /// Reset Password via Email
  static Future<void> resetPassword(String email) async {
    if (!SupabaseConfig.isInitialized || client == null) {
      throw StateError('Koneksi Supabase belum aktif atau Anon Key belum disetel.');
    }

    try {
      await client!.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kIsWeb ? null : 'io.supabase.yotro://login-callback',
      );
    } catch (e) {
      debugPrint('[SupabaseAuthService] Gagal reset password: $e');
      rethrow;
    }
  }

  /// Human-friendly Indonesian error formatter for Supabase Auth errors
  static String formatAuthException(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
        return 'Email atau kata sandi tidak sesuai.';
      }
      if (msg.contains('user already registered') || msg.contains('already registered')) {
        return 'Email sudah terdaftar. Silakan pilih tab Masuk.';
      }
      if (msg.contains('password should be at least')) {
        return 'Kata sandi minimal 6 karakter.';
      }
      if (msg.contains('different from the old password') || msg.contains('should be different')) {
        return 'Kata sandi baru harus berbeda dari kata sandi lama.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Email belum dikonfirmasi. Periksa kotak masuk Anda.';
      }
      if (msg.contains('rate limit')) {
        return 'Terlalu banyak percobaan. Tunggu beberapa saat lagi.';
      }
      return error.message;
    }
    return error.toString();
  }

  /// Sign Out from Supabase
  static Future<void> signOut() async {
    try {
      if (client != null && isAuthenticated) {
        await client!.auth.signOut();
      }
    } catch (e) {
      debugPrint('[SupabaseAuthService] Error saat sign out: $e');
    }
  }
}
