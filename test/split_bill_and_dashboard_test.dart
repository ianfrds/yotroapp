import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/dashboard_screen.dart';
import 'package:money_tracker/screens/analytics_screen.dart';
import 'package:money_tracker/screens/financial_analysis_screen.dart';
import 'package:money_tracker/screens/split_bill_screen.dart';
import 'package:money_tracker/widgets/transaction_tile.dart';

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

  group('DashboardScreen & Quick Actions Tests', () {
    testWidgets('Dashboard renders 4 quick action items: Dompet, Budget, Analisis, Split Bill', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const DashboardScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dompet'), findsWidgets);
      expect(find.text('Budget'), findsWidgets);
      expect(find.text('Analisis'), findsOneWidget);
      expect(find.text('Split Bill'), findsOneWidget);

      // Verify Masuk and Keluar quick action buttons are gone
      expect(find.widgetWithText(InkWell, 'Masuk'), findsNothing);
      expect(find.widgetWithText(InkWell, 'Keluar'), findsNothing);
    });

    testWidgets('Dashboard recent transactions render TransactionTile with emoji', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const DashboardScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Recent transactions should use TransactionTile
      expect(find.byType(TransactionTile), findsWidgets);
      // Food & Beverage has emoji 🍔
      expect(find.text('🍔'), findsWidgets);
    });
  });

  group('FinancialAnalysisScreen Tests', () {
    testWidgets('FinancialAnalysisScreen displays back button and header', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const FinancialAnalysisScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Analisis Keuangan'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('FinancialAnalysisScreen renders Financial Health and Cash Flow Stats cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const FinancialAnalysisScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Financial Health Card
      expect(find.text('Kesehatan Keuangan'), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
      expect(find.text('Tabungan'), findsOneWidget);
      expect(find.text('Rasio Beban'), findsOneWidget);
      expect(find.text('Arus Kas'), findsOneWidget);

      // Cash Flow Stats Card
      expect(find.text('Statistik & Arus Kas'), findsOneWidget);
      expect(find.text('Rata-rata Harian'), findsOneWidget);
      expect(find.text('Proyeksi Akhir Bulan'), findsOneWidget);
      expect(find.text('Rasio Pemasukan vs Pengeluaran'), findsOneWidget);
    });
  });

  group('AnalyticsScreen (Laporan Keuangan Nav Tab) Tests', () {
    testWidgets('AnalyticsScreen renders pure financial report without health score card', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const AnalyticsScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Laporan Keuangan'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Pemasukan'), findsOneWidget);
      // Verify health & stats cards are not present on Laporan Keuangan
      expect(find.text('Kesehatan Keuangan'), findsNothing);
      expect(find.text('Statistik & Arus Kas'), findsNothing);
    });
  });

  group('SplitBillScreen Tests', () {
    testWidgets('SplitBillScreen calculates equal share and updates per person', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const SplitBillScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Split Bill'), findsOneWidget);
      expect(find.text('Detail Tagihan'), findsOneWidget);
      expect(find.text('Anggota Tagihan (3 Orang)'), findsOneWidget);

      // Enter subtotal: 300000
      final amountField = find.widgetWithText(TextField, '0');
      await tester.enterText(amountField, '300000');
      await tester.pumpAndSettle();

      // Subtotal 300.000 + 10% tax (30.000) = 330.000
      // 330.000 / 3 orang = 110.000 per orang
      expect(find.text('Rp 110.000'), findsWidgets);
    });
  });
}

