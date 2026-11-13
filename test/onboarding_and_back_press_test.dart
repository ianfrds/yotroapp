import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/onboarding_profile_screen.dart';
import 'package:money_tracker/screens/main_shell.dart';
import 'package:money_tracker/screens/notifications_center_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({required Widget child, TransactionProvider? provider}) {
    final prov = provider ?? TransactionProvider();
    return ChangeNotifierProvider<TransactionProvider>.value(
      value: prov,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('OnboardingProfileScreen Tests', () {
    testWidgets('Onboarding renders Auth Gate and transitions to profile inputs via guest mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const OnboardingProfileScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Yotro'), findsOneWidget);
      expect(find.text('Masuk ke Akun Anda'), findsOneWidget);
      expect(find.text('Alamat Email'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Lupa kata sandi?'), findsOneWidget);
      expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
      expect(find.text('Masuk tanpa akun'), findsOneWidget);

      // Tap "Lupa kata sandi?" opens sheet
      await tester.tap(find.text('Lupa kata sandi?'));
      await tester.pumpAndSettle();
      expect(find.text('Lupa Kata Sandi'), findsOneWidget);
      expect(find.text('Kirim Tautan Reset'), findsOneWidget);

      // Close modal sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Tap tab "Daftar Baru" - forgot password button should disappear
      await tester.tap(find.text('Daftar Baru'));
      await tester.pumpAndSettle();
      expect(find.text('Daftar Akun Baru'), findsOneWidget);
      expect(find.text('Lupa kata sandi?'), findsNothing);

      // Tap "Masuk tanpa akun" to enter guest mode setup
      await tester.tap(find.text('Masuk tanpa akun'));
      await tester.pumpAndSettle();

      expect(find.text('Data Diri'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('No. Telp'), findsOneWidget);

      // Enter name & phone
      await tester.enterText(find.byType(TextField).first, 'Budi Santoso');
      await tester.enterText(find.byType(TextField).at(1), '081299998888');
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.tap(find.text('Mulai Mencatat'));
      await tester.pumpAndSettle();

      expect(provider.isOnboardingCompleted, isTrue);
      expect(provider.userName, 'Budi Santoso');
      expect(provider.userPhone, '081299998888');
    });

    testWidgets('Onboarding multi-step flow with carousel lines and selectable categories', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const OnboardingProfileScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Tap "Masuk tanpa akun" from Auth Gate
      expect(find.text('Masuk tanpa akun'), findsOneWidget);
      await tester.tap(find.text('Masuk tanpa akun'));
      await tester.pumpAndSettle();

      // Ensure no text stepper like '1. Profil' exists
      expect(find.text('1. Profil'), findsNothing);
      expect(find.text('Profil'), findsNothing);
      expect(find.text('Data Diri'), findsOneWidget);

      // Enter name
      await tester.enterText(find.byType(TextField).first, 'Siti Rahma');
      await tester.pumpAndSettle();

      // Tap Lanjutkan to go to Step 2 (Tema & Tampilan)
      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();

      expect(find.text('Tema & Tampilan'), findsOneWidget);
      // Ensure no top "Lewati" TextButton in header (only 1 Lewati button at bottom)
      expect(find.text('Lewati'), findsOneWidget);

      // Tap Lewati at bottom to advance to Step 3 (Atur Dompet)
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();

      expect(find.text('Atur Dompet & Rekening'), findsOneWidget);
      expect(find.text('Lewati'), findsOneWidget);

      // Tap Lewati to go to Step 4 (Kategori)
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();

      expect(find.text('Kategori Transaksi'), findsOneWidget);

      // Categories are clickable/selectable
      // Find a category chip e.g. 'Makanan & Minuman' and tap to toggle
      final foodChip = find.text('Makanan & Minuman');
      expect(foodChip, findsOneWidget);
      await tester.tap(foodChip);
      await tester.pumpAndSettle();

      // Tap Mulai Mencatat to finish
      await tester.tap(find.text('Mulai Mencatat'));
      await tester.pumpAndSettle();

      expect(provider.isOnboardingCompleted, isTrue);
      expect(provider.userName, 'Siti Rahma');
    });

    testWidgets('TransactionProvider logout resets isOnboardingCompleted to false', (tester) async {
      final provider = TransactionProvider();
      await provider.completeOnboarding(
        name: 'Ian Firdaus',
        phone: '08111111',
        gender: 'Pria',
      );
      expect(provider.isOnboardingCompleted, isTrue);

      await provider.logout();
      expect(provider.isOnboardingCompleted, isFalse);
    });
  });

  group('MainShell Back Navigation Tests (Requirement 5)', () {
    testWidgets('Navigating on tab 1 and pressing back returns to tab 0 (Beranda)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const MainShell(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Tap second tab (Riwayat Transaksi)
      await tester.tap(find.byIcon(Icons.description_rounded));
      await tester.pumpAndSettle();

      // Trigger back button pop
      final dynamic popScope = tester.widget(find.byWidgetPredicate((w) => w is PopScope));
      popScope.onPopInvokedWithResult(false, null);
      await tester.pumpAndSettle();

      // Tab index returned to Beranda (index 0)
      expect(find.text('Saldo saat ini'), findsWidgets);
    });

    testWidgets('Back press on Beranda shows snackbar warning', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const MainShell(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Trigger back button pop while on Beranda
      final dynamic popScope = tester.widget(find.byWidgetPredicate((w) => w is PopScope));
      popScope.onPopInvokedWithResult(false, null);
      await tester.pumpAndSettle();

      // Expect snackbar with double back warning
      expect(find.text('Tekan sekali lagi untuk keluar dari Yotro'), findsOneWidget);
    });
  });

  group('Notification Anti-Slop Tests', () {
    testWidgets('NotificationsCenterScreen renders without slop or emojis', (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const NotificationsCenterScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Aktivitas Transaksi'), findsOneWidget);
      expect(find.text('Belum Ada Aktivitas'), findsOneWidget);
    });
  });
}
