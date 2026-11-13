import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String defaultProjectRef = 'njjcviwihzvzjgfbzitg';
  static const String defaultUrl = 'https://njjcviwihzvzjgfbzitg.supabase.co';
  static const String defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qamN2aXdpaHp2empnZmJ6aXRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ1NTU1MTMsImV4cCI6MjExMDEzMTUxM30.fnCmLdU5agVm0oRXWYoBXsH7WjgvvgmLSPb7aXP2nTI';

  // Can be injected via --dart-define=SUPABASE_URL=...
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: defaultUrl);
  // Can be injected via --dart-define=SUPABASE_ANON_KEY=...
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: defaultAnonKey);

  static const String _prefUrlKey = 'yotro_supabase_url';
  static const String _prefAnonKey = 'yotro_supabase_anon_key';

  static String _currentUrl = _envUrl;
  static String _currentAnonKey = _envAnonKey;
  static bool _isInitialized = false;

  static String get supabaseUrl => _currentUrl;
  static String get supabaseAnonKey => _currentAnonKey;
  static bool get isInitialized => _isInitialized;

  static bool get isConfigured =>
      _currentUrl.trim().isNotEmpty && _currentAnonKey.trim().isNotEmpty;

  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Safe initialization that never crashes the app startup
  static Future<bool> initialize({String? customUrl, String? customAnonKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUrl = prefs.getString(_prefUrlKey);
      final storedKey = prefs.getString(_prefAnonKey);

      _currentUrl = customUrl ?? storedUrl ?? _envUrl;
      if (_currentUrl.isEmpty) _currentUrl = defaultUrl;

      _currentAnonKey = customAnonKey ?? storedKey ?? _envAnonKey;

      if (!isConfigured) {
        debugPrint('[SupabaseConfig] Belum dikonfigurasi (Anon Key kosong). Mode offline aktif.');
        _isInitialized = false;
        return false;
      }

      await Supabase.initialize(
        url: _currentUrl,
        anonKey: _currentAnonKey,
        debug: kDebugMode,
      );

      _isInitialized = true;
      debugPrint('[SupabaseConfig] Berhasil terhubung ke $_currentUrl');
      return true;
    } catch (e) {
      _isInitialized = false;
      debugPrint('[SupabaseConfig] Gagal inisialisasi: $e. Berjalan dalam mode offline.');
      return false;
    }
  }

  /// Update and persist credentials (e.g. from Settings form)
  static Future<bool> updateCredentials({
    required String url,
    required String anonKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefUrlKey, url.trim().isEmpty ? defaultUrl : url.trim());
    await prefs.setString(_prefAnonKey, anonKey.trim());
    return await initialize(customUrl: url, customAnonKey: anonKey);
  }

  /// Clear custom credentials
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefUrlKey);
    await prefs.remove(_prefAnonKey);
    _currentUrl = defaultUrl;
    _currentAnonKey = '';
    _isInitialized = false;
  }
}
