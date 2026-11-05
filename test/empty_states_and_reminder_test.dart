import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/analytics_screen.dart';
import 'package:money_tracker/screens/dashboard_screen.dart';
import 'package:money_tracker/screens/financial_analysis_screen.dart';
import 'package:money_tracker/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp(Widget child, TransactionProvider provider) {
    return ChangeNotifierProvider<TransactionProvider>.value(
      value: provider,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Empty States Verification', () {
    testWidgets('AnalyticsScreen displays empty state when there are zero transactions', (tester) async {
      final provider = TransactionProvider();
      await provider.clearAllTransactions();

      await tester.pumpWidget(buildApp(const AnalyticsScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Transaksi'), findsOneWidget);
      expect(find.text('Belum ada rincian transaksi pengeluaran.'), findsOneWidget);
      expect(find.text('Food & Beverage'), findsNothing);
      expect(find.text('Salary'), findsNothing);
    });

    testWidgets('FinancialAnalysisScreen displays empty state when there are zero transactions', (tester) async {
      final provider = TransactionProvider();
      await provider.clearAllTransactions();

      await tester.pumpWidget(buildApp(const FinancialAnalysisScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Data Analisis'), findsOneWidget);
      expect(find.text('Catat transaksi pengeluaran atau pemasukan pertama Anda untuk melihat skor kesehatan finansial, proyeksi arus kas, dan diagnosa otomatis.'), findsOneWidget);
      expect(find.text('Kesehatan Keuangan'), findsNothing);
    });

    testWidgets('DashboardScreen renders wave emoji 👋 next to user name', (tester) async {
      final provider = TransactionProvider();
      await provider.updateProfile(name: 'Ian Firdaus', phone: '', gender: 'Pria');

      await tester.pumpWidget(buildApp(const DashboardScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Ian Firdaus'), findsOneWidget);
      expect(find.text('👋'), findsOneWidget);
    });
  });

  group('Daily Reminder Auto-Enable & Editing Tests', () {
    test('completeOnboarding automatically enables daily reminder', () async {
      final provider = TransactionProvider();
      await provider.toggleDailyReminder(false);
      expect(provider.isDailyReminderEnabled, isFalse);

      await provider.completeOnboarding(
        name: 'Ian Firdaus',
        phone: '0812345678',
        gender: 'Pria',
      );

      expect(provider.isDailyReminderEnabled, isTrue);
      expect(provider.dailyReminderTimes, contains('18:00'));
      expect(provider.dailyReminderTimes, contains('19:00'));
    });

    testWidgets('SettingsScreen daily reminder alarms can be edited', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pump();
      await provider.requestNotificationPermission();
      await provider.toggleDailyReminder(true);

      await tester.pumpWidget(buildApp(const SettingsScreen(), provider));
      await tester.pumpAndSettle();

      final reminderFinder = find.text('Pengingat Transaksi Harian');
      expect(reminderFinder, findsOneWidget);
      await tester.tap(reminderFinder);
      await tester.pumpAndSettle();

      expect(find.text('Daftar Waktu Alarm (2)'), findsOneWidget);
      expect(find.text('18:00'), findsOneWidget);
      expect(find.text('Ketuk untuk ubah jam pengingat'), findsWidgets);
    });
  });
}
