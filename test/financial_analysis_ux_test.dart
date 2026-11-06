import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/analytics_screen.dart';
import 'package:money_tracker/screens/financial_analysis_screen.dart';

Widget buildTestWidget({
  required Widget child,
  required TransactionProvider provider,
}) {
  return ChangeNotifierProvider<TransactionProvider>.value(
    value: provider,
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FinancialAnalysisScreen UX & Layman Language Tests', () {
    testWidgets('Header help button opens Panduan Membaca Analisis sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.resetToDemoData();

      await tester.pumpWidget(buildTestWidget(
        child: const FinancialAnalysisScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Find and tap help button
      final helpBtn = find.byIcon(Icons.help_outline_rounded);
      expect(helpBtn, findsOneWidget);
      await tester.tap(helpBtn);
      await tester.pumpAndSettle();

      // Verify guide sheet contents
      expect(find.text('Panduan Membaca Analisis'), findsOneWidget);
      expect(find.text('Skor Keuangan (0 - 100)'), findsOneWidget);
      expect(find.text('Tabungan (Uang Tersimpan)'), findsOneWidget);
      expect(find.text('Rasio Beban (Porsi Belanja)'), findsOneWidget);
      expect(find.text('Arus Kas (Sisa Uang Bersih)'), findsOneWidget);
      expect(find.text('Rata-rata Harian & Proyeksi Akhir Bulan'), findsOneWidget);
    });

    testWidgets('Displays layman financial health, cash flow, and budget guidance cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.resetToDemoData();
      // Set budget to 0 to test unconfigured budget CTA
      await provider.updateOverallBudget(0.0);

      await tester.pumpWidget(buildTestWidget(
        child: const FinancialAnalysisScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Verify Card 1: Kesehatan Keuangan
      expect(find.text('Kesehatan Keuangan'), findsOneWidget);
      expect(find.text('Kurang'), findsOneWidget);
      expect(find.text('Waspada'), findsOneWidget);
      expect(find.text('Aman'), findsOneWidget);
      expect(find.text('Sangat Baik'), findsWidgets);
      expect(find.text('Catatan & Saran Keuangan'), findsOneWidget);

      // Verify Card 2: Statistik & Arus Kas
      expect(find.text('Statistik & Arus Kas'), findsOneWidget);
      expect(find.text('Rata-rata Harian'), findsOneWidget);
      expect(find.text('Proyeksi Akhir Bulan'), findsOneWidget);
      expect(find.text('Rasio Pemasukan vs Pengeluaran'), findsOneWidget);
      expect(find.text('Pengeluaran Terbanyak'), findsOneWidget);

      // Verify Card 3: Target & Anggaran Belanja (Budget = 0 CTA)
      await tester.scrollUntilVisible(find.text('Target & Anggaran Belanja'), 200);
      expect(find.text('Target & Anggaran Belanja'), findsOneWidget);
      expect(find.text('Ingin belanja lebih terarah?'), findsOneWidget);
      expect(find.text('Pasang'), findsOneWidget);
    });

    testWidgets('Budget guidance reflects active budget when limit is configured', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.resetToDemoData();
      await provider.updateOverallBudget(5000000.0);

      await tester.pumpWidget(buildTestWidget(
        child: const FinancialAnalysisScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pantauan Anggaran Bulanan'), findsOneWidget);
      expect(find.textContaining('Batas: Rp 5.000.000'), findsOneWidget);
    });
  });

  group('AnalyticsScreen to FinancialAnalysis UX Bridge Tests', () {
    testWidgets('AnalyticsScreen includes banner to open Financial Analysis', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.resetToDemoData();

      await tester.pumpWidget(buildTestWidget(
        child: const AnalyticsScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Find bridge banner
      expect(find.text('Cek Analisis Finansial & Saran'), findsOneWidget);
      expect(find.text('Skor kesehatan, proyeksi akhir bulan, dan saran hemat'), findsOneWidget);

      // Tap banner to trigger bottom sheet
      await tester.tap(find.text('Cek Analisis Finansial & Saran'));
      await tester.pumpAndSettle();

      // Verify Financial Analysis modal opens
      expect(find.text('Analisis Keuangan'), findsWidgets);
      expect(find.text('Kesehatan Keuangan'), findsOneWidget);
    });
  });
}
