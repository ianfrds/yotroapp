import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/budget_model.dart';
import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/budget_screen.dart';
import 'package:money_tracker/screens/settings_screen.dart';

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

  group('Budget Cycle Calculation Unit Tests', () {
    test('Default reset day is 1 and spans current calendar month', () {
      final provider = TransactionProvider();
      final ref = DateTime(2026, 11, 15);
      final cycle = provider.getBudgetCycleForDate(referenceDate: ref, resetDay: 1);

      expect(cycle.start, equals(DateTime(2026, 11, 1, 0, 0, 0)));
      expect(cycle.end.year, equals(2026));
      expect(cycle.end.month, equals(11));
      expect(cycle.end.day, equals(30));
    });

    test('Reset day 25 before 25th starts previous month on the 25th', () {
      final provider = TransactionProvider();
      final ref = DateTime(2026, 11, 15);
      final cycle = provider.getBudgetCycleForDate(referenceDate: ref, resetDay: 25);

      expect(cycle.start, equals(DateTime(2026, 10, 25, 0, 0, 0)));
      expect(cycle.end.year, equals(2026));
      expect(cycle.end.month, equals(11));
      expect(cycle.end.day, equals(24));
    });

    test('Reset day 25 after 25th starts current month on the 25th', () {
      final provider = TransactionProvider();
      final ref = DateTime(2026, 11, 26);
      final cycle = provider.getBudgetCycleForDate(referenceDate: ref, resetDay: 25);

      expect(cycle.start, equals(DateTime(2026, 11, 25, 0, 0, 0)));
      expect(cycle.end.year, equals(2026));
      expect(cycle.end.month, equals(12));
      expect(cycle.end.day, equals(24));
    });

    test('Reset day 25 exactly on 25th resets and starts new cycle', () {
      final provider = TransactionProvider();
      final ref = DateTime(2026, 11, 25);
      final cycle = provider.getBudgetCycleForDate(referenceDate: ref, resetDay: 25);

      expect(cycle.start, equals(DateTime(2026, 11, 25, 0, 0, 0)));
      expect(cycle.end.year, equals(2026));
      expect(cycle.end.month, equals(12));
      expect(cycle.end.day, equals(24));
    });

    test('Reset day 31 clamps gracefully on February and 30-day months', () {
      final provider = TransactionProvider();
      final ref = DateTime(2027, 2, 15); // February 2027 has 28 days
      final cycle = provider.getBudgetCycleForDate(referenceDate: ref, resetDay: 31);

      expect(cycle.start, equals(DateTime(2027, 1, 31, 0, 0, 0)));
      expect(cycle.end.year, equals(2027));
      expect(cycle.end.month, equals(2));
      expect(cycle.end.day, equals(27)); // Last day before 28th
    });

    test('Cycle expense only counts transactions within active cycle window', () async {
      final provider = TransactionProvider();
      await provider.updateOverallBudget(3000000.0);
      await provider.updateBudgetResetDay(1); // Standard current calendar month

      final now = DateTime.now();
      // Transaction this month
      await provider.addTransaction(
        title: 'Makan Siang',
        amount: 50000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: DateTime(now.year, now.month, 10),
      );

      // Transaction 3 months ago (outside current cycle)
      await provider.addTransaction(
        title: 'Beli Sepatu Lama',
        amount: 500000,
        type: TransactionType.expense,
        categoryName: 'Belanja',
        categoryId: 'belanja',
        walletId: 'w_bank',
        date: DateTime(now.year, now.month - 3, 10),
      );

      // Total expense includes both
      expect(provider.totalExpense, equals(550000.0));
      // Current cycle expense only includes this month's expense!
      expect(provider.currentCycleExpense, equals(50000.0));
      // Remaining budget reflects cycle expense
      expect(provider.remainingBudget, equals(2950000.0));
      // Usage percentage
      expect(provider.budgetUsagePercentage, closeTo((50000 / 3000000) * 100, 0.01));
    });

    test('Category cycle expense isolates category and active cycle', () async {
      final provider = TransactionProvider();
      await provider.updateCategoryBudget('Makanan & Minuman', 1000000.0);
      await provider.updateBudgetResetDay(1);

      final now = DateTime.now();
      await provider.addTransaction(
        title: 'Kopi',
        amount: 25000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: DateTime(now.year, now.month, 5),
      );

      await provider.addTransaction(
        title: 'Kopi Bulan Lalu',
        amount: 25000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: DateTime(now.year, now.month - 1, 5),
      );

      expect(provider.getCategoryCycleExpense('Makanan & Minuman'), equals(25000.0));
    });
  });

  group('SettingsScreen Reset Cycle Widget Tests', () {
    testWidgets('Renders Siklus Reset Anggaran row in SettingsScreen and opens picker sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.updateOverallBudget(2500000);
      await provider.updateBudgetResetDay(1);

      await tester.pumpWidget(buildTestApp(const SettingsScreen(), provider));
      await tester.pumpAndSettle();

      // Verify row exists in SettingsScreen
      expect(find.text('Siklus Reset Anggaran'), findsOneWidget);
      expect(find.textContaining('Tiap tgl 1'), findsWidgets);

      // Tap on the row to open bottom sheet
      await tester.tap(find.text('Siklus Reset Anggaran'));
      await tester.pumpAndSettle();

      // Verify sheet title & presets
      expect(find.text('Tanggal Reset Bulanan'), findsOneWidget);
      expect(find.text('Tgl 1 (Awal)'), findsOneWidget);
      expect(find.text('Tgl 25 (Gajian)'), findsOneWidget);
      expect(find.text('Tgl 28 (Akhir)'), findsOneWidget);

      // Tap preset Tgl 25
      await tester.tap(find.text('Tgl 25 (Gajian)'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Simpan Tanggal Reset'));
      await tester.pumpAndSettle();

      // Verify state updated to 25
      expect(provider.budget.monthlyResetDay, equals(25));
      expect(find.textContaining('Tgl 25'), findsWidgets);
    });

    testWidgets('BudgetScreen is clean and does not render reset cycle setting card', (tester) async {
      final provider = TransactionProvider();
      await provider.updateOverallBudget(2500000);

      await tester.pumpWidget(buildTestApp(const BudgetScreen(isStandalonePage: true), provider));
      await tester.pumpAndSettle();

      expect(find.text('Siklus Reset Anggaran'), findsNothing);
    });
  });
}
