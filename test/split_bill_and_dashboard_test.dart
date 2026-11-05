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

    testWidgets('SplitBillScreen supports mode switching, tax/service toggling, and button consistency', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const SplitBillScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Verify mode tabs
      expect(find.text('Bagi Rata'), findsOneWidget);
      expect(find.text('Bagi Kustom'), findsOneWidget);
      expect(find.text('Per Item'), findsOneWidget);

      // Verify standardized action buttons
      expect(find.text('Salin Teks'), findsOneWidget);
      expect(find.text('Catat Bagian Saya'), findsOneWidget);

      // Switch to Bagi Kustom
      await tester.tap(find.text('Bagi Kustom'));
      await tester.pumpAndSettle();

      // Switch to Per Item
      await tester.tap(find.text('Per Item'));
      await tester.pumpAndSettle();

      expect(find.text('Item Pesanan (0)'), findsOneWidget);
      expect(find.text('Tambah Item'), findsOneWidget);

      // Toggle Tax off
      final switchFinders = find.byType(Switch);
      expect(switchFinders, findsNWidgets(2)); // Tax & Service
      await tester.tap(switchFinders.first);
      await tester.pumpAndSettle();
    });

    testWidgets('SplitBillScreen handles itemized calculation correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const SplitBillScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Switch to Per Item
      await tester.tap(find.text('Per Item'));
      await tester.pumpAndSettle();

      // Tap + Tambah Item
      await tester.tap(find.text('Tambah Item'));
      await tester.pumpAndSettle();

      // Enter item name and price
      final nameInput = find.widgetWithText(TextField, 'Misal: Nasi Goreng Spesial');
      await tester.enterText(nameInput, 'Pizza');
      final priceInput = find.widgetWithText(TextField, '0');
      await tester.enterText(priceInput, '50000');
      await tester.pumpAndSettle();

      // Tap + inside item sheet to increase qty to 2
      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await tester.pumpAndSettle();

      // Verify dynamic total preview appears (2 x 50.000 = 100.000)
      expect(find.text('Total Item: Rp 100.000'), findsOneWidget);

      // Save item
      await tester.tap(find.text('Simpan Item'));
      await tester.pumpAndSettle();

      expect(find.text('Pizza'), findsOneWidget);
      // 100.000 subtotal + 10% tax (10.000) = 110.000 total bill / 3 members = 36.666,67
      expect(find.text('Rp 110.000'), findsOneWidget);
    });
  });
}

