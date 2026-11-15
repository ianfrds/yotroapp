import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/budget_screen.dart';

Widget buildTestApp(Widget home, TransactionProvider provider) {
  return ChangeNotifierProvider<TransactionProvider>.value(
    value: provider,
    child: MaterialApp(
      home: home,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Category Roll-up Budgeting Logic Tests', () {
    test('totalCategoryBudget and activeCategoryBudgetCount aggregate correctly', () async {
      final provider = TransactionProvider();
      expect(provider.totalCategoryBudget, equals(0.0));
      expect(provider.activeCategoryBudgetCount, equals(0));

      await provider.updateCategoryBudget('Makanan & Minuman', 2000000.0);
      await provider.updateCategoryBudget('Transportasi', 1000000.0);
      await provider.updateCategoryBudget('Hiburan', 1500000.0);

      expect(provider.totalCategoryBudget, equals(4500000.0));
      expect(provider.activeCategoryBudgetCount, equals(3));
      expect(provider.effectiveMonthlyBudget, equals(4500000.0));
    });

    test('totalBudgetedExpense isolates budgeted categories within active cycle', () async {
      final provider = TransactionProvider();
      await provider.updateCategoryBudget('Makanan & Minuman', 2000000.0);
      await provider.updateCategoryBudget('Transportasi', 1000000.0);
      await provider.updateBudgetResetDay(1);

      final now = DateTime.now();

      // Transaction in budgeted category (Makanan)
      await provider.addTransaction(
        title: 'Makan Siang',
        amount: 50000.0,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'makanan_minuman',
        walletId: 'w_bank',
        date: DateTime(now.year, now.month, 10),
      );

      // Transaction in budgeted category (Transportasi)
      await provider.addTransaction(
        title: 'Bensin Motor',
        amount: 30000.0,
        type: TransactionType.expense,
        categoryName: 'Transportasi',
        categoryId: 'transportasi',
        walletId: 'w_bank',
        date: DateTime(now.year, now.month, 12),
      );

      // Transaction in UNBUDGETED category (Kesehatan)
      await provider.addTransaction(
        title: 'Beli Obat',
        amount: 100000.0,
        type: TransactionType.expense,
        categoryName: 'Kesehatan',
        categoryId: 'kesehatan',
        walletId: 'w_bank',
        date: DateTime(now.year, now.month, 14),
      );

      // totalBudgetedExpense should ONLY sum Makanan (50k) + Transportasi (30k) = 80k
      expect(provider.totalBudgetedExpense, equals(80000.0));

      // totalCategoryBudget is 2jt + 1jt = 3jt
      expect(provider.totalCategoryBudget, equals(3000000.0));

      // remainingBudget is 3jt - 80k = 2.920.000
      expect(provider.remainingBudget, equals(2920000.0));

      // budgetUsagePercentage is (80k / 3jt) * 100 = 2.666...%
      expect(provider.budgetUsagePercentage, closeTo((80000.0 / 3000000.0) * 100, 0.01));
    });
  });

  group('Category Roll-up Budgeting UI Tests', () {
    testWidgets('BudgetScreen renders Top Card as Total Anggaran Bulan Ini with category roll-up', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.updateCategoryBudget('Makanan & Minuman', 2000000.0);
      await provider.updateCategoryBudget('Transportasi', 1000000.0);
      await provider.updateCategoryBudget('Hiburan', 1500000.0);

      await tester.pumpWidget(buildTestApp(const BudgetScreen(isStandalonePage: true), provider));
      await tester.pumpAndSettle();

      // Top roll-up card title and category count badge
      expect(find.text('Total Anggaran Bulan Ini'), findsOneWidget);
      expect(find.text('3 Kategori'), findsOneWidget);

      // Verify aggregate limit is rendered
      expect(find.textContaining('4.500.000'), findsWidgets);

      // Verify category list items are rendered
      expect(find.text('Budget Per Kategori'), findsOneWidget);
      expect(find.text('Makanan & Minuman'), findsOneWidget);
      expect(find.text('Transportasi'), findsOneWidget);
      expect(find.text('Hiburan'), findsOneWidget);

      // Quick add button at the bottom of the list
      expect(find.text('Tambah Kategori Lain'), findsOneWidget);
    });

    testWidgets('Tapping Tambah Kategori Lain opens add category budget sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.updateCategoryBudget('Makanan & Minuman', 2000000.0);

      await tester.pumpWidget(buildTestApp(const BudgetScreen(isStandalonePage: true), provider));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Kategori Lain'), findsOneWidget);
      await tester.tap(find.text('Tambah Kategori Lain'));
      await tester.pumpAndSettle();

      // Modal sheet opens with title 'Tambah Budget Kategori'
      expect(find.text('Tambah Budget Kategori'), findsOneWidget);
      expect(find.text('Kategori Pengeluaran'), findsOneWidget);
    });
  });
}
