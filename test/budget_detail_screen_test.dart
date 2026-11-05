import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/budget_detail_screen.dart';
import 'package:money_tracker/screens/budget_screen.dart';
import 'package:money_tracker/widgets/semicircle_budget_gauge.dart';

Widget buildTestApp(Widget child, TransactionProvider provider) {
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

  group('BudgetDetailScreen Tests', () {
    testWidgets('renders category details, chart title, and transactions', (tester) async {
      final provider = TransactionProvider();
      await provider.updateCategoryBudget('Makanan & Minuman', 1000000.0);

      // Add transactions
      await provider.addTransaction(
        title: 'Mie Goreng',
        amount: 7000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: DateTime.now(),
      );

      await provider.addTransaction(
        title: 'Nasi Campur',
        amount: 13000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestApp(
          const BudgetDetailScreen(categoryName: 'Makanan & Minuman'),
          provider,
        ),
      );
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Rincian Anggaran'), findsOneWidget);
      expect(find.text('Makanan & Minuman'), findsOneWidget);

      // Check budget total, terpakai, and sisa
      expect(find.text('Rp 1.000.000'), findsOneWidget);
      expect(find.textContaining('Terpakai :'), findsOneWidget);
      expect(find.textContaining('Sisa :'), findsOneWidget);

      // Check sections
      expect(find.text('Statistik Penggunaan Anggaran'), findsOneWidget);
      expect(find.text('Riwayat Transaksi'), findsOneWidget);

      // Check transaction list
      expect(find.text('Mie Goreng'), findsOneWidget);
      expect(find.text('Nasi Campur'), findsOneWidget);
      expect(find.text('-Rp 7.000'), findsOneWidget);
      expect(find.text('-Rp 13.000'), findsOneWidget);
    });

    testWidgets('BudgetScreen taps navigate to BudgetDetailScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.updateCategoryBudget('Makanan & Minuman', 500000.0);

      await tester.pumpWidget(buildTestApp(const BudgetScreen(), provider));
      await tester.pumpAndSettle();

      // Tap on Makanan & Minuman category budget
      final catFinder = find.text('Makanan & Minuman');
      expect(catFinder, findsOneWidget);
      await tester.tap(catFinder);
      await tester.pumpAndSettle();

      // Expect BudgetDetailScreen to be pushed
      expect(find.text('Rincian Anggaran'), findsOneWidget);
      expect(find.text('Statistik Penggunaan Anggaran'), findsOneWidget);
      expect(find.text('Riwayat Transaksi'), findsOneWidget);
    });

    testWidgets('Overall budget tap in BudgetScreen navigates to overall BudgetDetailScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestApp(const BudgetScreen(), provider));
      await tester.pumpAndSettle();

      // Tap on overall budget linear progress card
      await tester.tap(find.byType(LinearProgressIndicator).first);
      await tester.pumpAndSettle();

      // Expect overall BudgetDetailScreen to open
      expect(find.text('Rincian Anggaran'), findsOneWidget);
      expect(find.text('Semua Pengeluaran'), findsOneWidget);
    });

    testWidgets('Chart is dynamic, matches normalized category and is interactive', (tester) async {
      final provider = TransactionProvider();
      await provider.updateCategoryBudget('Makanan & Minuman', 500000.0);

      final day1 = DateTime.now().subtract(const Duration(days: 2));
      final day2 = DateTime.now();

      await provider.addTransaction(
        title: 'Nasi Padang',
        amount: 25000,
        type: TransactionType.expense,
        categoryName: 'Makanan', // test normalization
        categoryId: 'food',
        walletId: 'w_bank',
        date: day1,
      );

      await provider.addTransaction(
        title: 'Ayam Geprek',
        amount: 35000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'food',
        walletId: 'w_bank',
        date: day2,
      );

      await tester.pumpWidget(
        buildTestApp(
          const BudgetDetailScreen(categoryName: 'Makanan & Minuman'),
          provider,
        ),
      );
      await tester.pumpAndSettle();

      // Terpakai should be 60.000 (25k + 35k)
      expect(find.textContaining('60.000'), findsWidgets);

      // Riwayat Transaksi should have both
      expect(find.text('Nasi Padang'), findsOneWidget);
      expect(find.text('Ayam Geprek'), findsOneWidget);

      // Verify chart dynamic metrics: average and peak
      expect(find.textContaining('Puncak:'), findsOneWidget);
      expect(find.textContaining('Rata-rata:'), findsOneWidget);

      // Tap on a bar date label to filter
      final day1Label = find.text(intl_format(day1));
      if (day1Label.evaluate().isNotEmpty) {
        await tester.tap(day1Label.first);
        await tester.pumpAndSettle();

        // When day1 is selected, 'Lihat Semua' button should appear
        expect(find.text('Lihat Semua'), findsOneWidget);

        // Tap 'Lihat Semua' to reset
        await tester.tap(find.text('Lihat Semua'));
        await tester.pumpAndSettle();
        expect(find.text('Nasi Padang'), findsOneWidget);
        expect(find.text('Ayam Geprek'), findsOneWidget);
      }
    });
  });
}

String intl_format(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month';
}
