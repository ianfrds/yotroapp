import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/auth_screen.dart';
import 'package:money_tracker/screens/main_shell.dart';
import 'package:money_tracker/services/supabase_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createAuthScreen({TransactionProvider? provider, bool fromSettings = false}) {
    final p = provider ?? TransactionProvider();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TransactionProvider>.value(value: p),
      ],
      child: MaterialApp(
        home: AuthScreen(fromSettings: fromSettings),
      ),
    );
  }

  void setTestViewSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('AuthScreen UI and Registration Tests', () {
    testWidgets('Renders Yotro branding, tabs, and register fields initially', (tester) async {
      setTestViewSize(tester);
      await tester.pumpWidget(createAuthScreen());
      await tester.pumpAndSettle();

      // Brand text
      expect(find.text('Yotro'), findsOneWidget);
      expect(find.text('Kelola Keuangan Lebih Tenang & Terkendali'), findsOneWidget);

      // Tabs
      expect(find.text('Daftar Baru'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);

      // Register fields
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Ulangi Kata Sandi'), findsOneWidget);
      expect(find.text('Daftar Akun Baru'), findsOneWidget);

      // Google button
      expect(find.text('Lanjutkan dengan Google'), findsOneWidget);

      // Guest / Offline mode option
      expect(find.text('Lewati / Masuk sebagai Tamu'), findsOneWidget);
      expect(find.text('Mode 100% lokal tanpa sinkronisasi cloud'), findsOneWidget);
    });

    testWidgets('Switches tabs between Daftar Baru and Masuk', (tester) async {
      setTestViewSize(tester);
      await tester.pumpWidget(createAuthScreen());
      await tester.pumpAndSettle();

      // Tap 'Masuk' tab
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      // On 'Masuk' tab:
      expect(find.text('Nama Lengkap'), findsNothing);
      expect(find.text('Ulangi Kata Sandi'), findsNothing);
      expect(find.text('Masuk ke Akun'), findsOneWidget);
      expect(find.text('Lupa kata sandi?'), findsOneWidget);

      // Tap 'Daftar Baru' tab back
      await tester.tap(find.text('Daftar Baru'));
      await tester.pumpAndSettle();

      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Ulangi Kata Sandi'), findsOneWidget);
      expect(find.text('Daftar Akun Baru'), findsOneWidget);
    });

    testWidgets('Validates required fields on register submit', (tester) async {
      setTestViewSize(tester);
      await tester.pumpWidget(createAuthScreen());
      await tester.pumpAndSettle();

      // Tap register button without filling inputs
      await tester.ensureVisible(find.text('Daftar Akun Baru'));
      await tester.tap(find.text('Daftar Akun Baru'));
      await tester.pumpAndSettle();

      expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    });

    testWidgets('Validates password confirmation mismatch', (tester) async {
      setTestViewSize(tester);
      await tester.pumpWidget(createAuthScreen());
      await tester.pumpAndSettle();

      // Enter name, email, password, and mismatched confirm password
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Ian Firdaus');
      await tester.enterText(textFields.at(1), 'ian@example.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'mismatch123');

      await tester.ensureVisible(find.text('Daftar Akun Baru'));
      await tester.tap(find.text('Daftar Akun Baru'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi kata sandi tidak cocok'), findsOneWidget);
    });

    testWidgets('Guest / Skip Mode sets local provider state without cloud login', (tester) async {
      setTestViewSize(tester);
      final provider = TransactionProvider();
      await tester.pumpWidget(createAuthScreen(provider: provider));
      await tester.pumpAndSettle();

      expect(provider.isGuestMode, isFalse);

      // Tap Lewati / Masuk sebagai Tamu button
      final guestBtn = find.byKey(const Key('btn_guest_mode'));
      await tester.ensureVisible(guestBtn);
      await tester.tap(guestBtn);
      await tester.pumpAndSettle();

      expect(provider.isGuestMode, isTrue);
      expect(provider.isOnboardingCompleted, isTrue);
      expect(provider.userName, 'Pengguna Tamu');
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('fromSettings = true shows back arrow and pops on guest action', (tester) async {
      setTestViewSize(tester);
      final provider = TransactionProvider();
      await tester.pumpWidget(createAuthScreen(provider: provider, fromSettings: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      final guestBtn = find.byKey(const Key('btn_guest_mode'));
      await tester.ensureVisible(guestBtn);
      await tester.tap(guestBtn);
      await tester.pumpAndSettle();

      expect(provider.isGuestMode, isTrue);
    });
  });

  group('SupabaseAuthService Error Formatting Tests', () {
    test('formatAuthException translates common auth errors to Indonesian', () {
      expect(
        SupabaseAuthService.formatAuthException(
          const AuthException('Invalid login credentials'),
        ),
        'Email atau kata sandi tidak sesuai.',
      );

      expect(
        SupabaseAuthService.formatAuthException(
          const AuthException('User already registered'),
        ),
        'Email sudah terdaftar. Silakan pilih tab Masuk.',
      );

      expect(
        SupabaseAuthService.formatAuthException(
          const AuthException('Password should be at least 6 characters'),
        ),
        'Kata sandi minimal 6 karakter.',
      );
    });
  });
}
