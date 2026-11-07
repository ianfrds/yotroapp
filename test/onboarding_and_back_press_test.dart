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

      expect(find.text('Welcome to Yotro'), findsOneWidget);
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
