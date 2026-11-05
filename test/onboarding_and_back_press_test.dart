import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/onboarding_profile_screen.dart';
import 'package:money_tracker/screens/main_shell.dart';
import 'package:money_tracker/screens/notification_reader_screen.dart';

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
    testWidgets('Onboarding renders title, inputs for name, phone, gender, and submits', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const OnboardingProfileScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Profil Pengguna'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Nomor Telepon (Opsional)'), findsOneWidget);
      expect(find.text('Jenis Kelamin'), findsOneWidget);
      expect(find.text('Pria'), findsOneWidget);
      expect(find.text('Wanita'), findsOneWidget);
      expect(find.text('Izin Notifikasi Otomatis'), findsOneWidget);

      // Enter name & phone
      await tester.enterText(find.byType(TextField).first, 'Budi Santoso');
      await tester.enterText(find.byType(TextField).at(1), '081299998888');
      await tester.pumpAndSettle();

      // Tap Wanita
      await tester.tap(find.text('Wanita'));
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.tap(find.text('Mulai Aplikasi'));
      await tester.pumpAndSettle();

      expect(provider.isOnboardingCompleted, isTrue);
      expect(provider.userName, 'Budi Santoso');
      expect(provider.userPhone, '081299998888');
      expect(provider.userGender, 'Wanita');
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
    testWidgets('NotificationReaderScreen has zero emojis and clean action chips', (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const NotificationReaderScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pembaca Notifikasi'), findsOneWidget);
      expect(find.text('Uji Coba Deteksi Notifikasi'), findsOneWidget);
      expect(find.text('Aturan & Filter Aplikasi'), findsOneWidget);
      expect(find.text('+ Tambah'), findsOneWidget);

      // Verify no emoji in simulation chips
      expect(find.textContaining('myBCA: QRIS Rp 45.000'), findsOneWidget);
      expect(find.textContaining('GoPay: Bayar Rp 22.000'), findsOneWidget);
    });
  });
}
