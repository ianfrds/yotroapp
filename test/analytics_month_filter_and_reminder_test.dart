import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/analytics_screen.dart';

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

  group('Analytics Category Breakdown Month Filter Tests', () {
    test('getCategoryBreakdown filters accurately by month', () async {
      final provider = TransactionProvider();
      await provider.clearAllTransactions();

      // Add tx in Oct 2026
      await provider.addTransaction(
        title: 'Makan Siang Oktober',
        amount: 25000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'cat_food',
        walletId: provider.wallets.first.id,
        date: DateTime(2026, 10, 15, 12, 0),
      );

      // Add tx in Nov 2026
      await provider.addTransaction(
        title: 'Bensin November',
        amount: 50000,
        type: TransactionType.expense,
        categoryName: 'Transportasi',
        categoryId: 'cat_trans',
        walletId: provider.wallets.first.id,
        date: DateTime(2026, 11, 5, 8, 30),
      );

      // Add another tx in Nov 2026
      await provider.addTransaction(
        title: 'Kopi November',
        amount: 15000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'cat_food',
        walletId: provider.wallets.first.id,
        date: DateTime(2026, 11, 10, 14, 0),
      );

      // All-time breakdown
      final allTimeBreakdown = provider.getCategoryBreakdown();
      expect(allTimeBreakdown['Makanan & Minuman'], 40000);
      expect(allTimeBreakdown['Transportasi'], 50000);

      // Oct 2026 breakdown
      final octBreakdown = provider.getCategoryBreakdown(month: DateTime(2026, 10, 1));
      expect(octBreakdown['Makanan & Minuman'], 25000);
      expect(octBreakdown.containsKey('Transportasi'), isFalse);

      // Nov 2026 breakdown
      final novBreakdown = provider.getCategoryBreakdown(month: DateTime(2026, 11, 1));
      expect(novBreakdown['Makanan & Minuman'], 15000);
      expect(novBreakdown['Transportasi'], 50000);

      // Dec 2026 breakdown (empty)
      final decBreakdown = provider.getCategoryBreakdown(month: DateTime(2026, 12, 1));
      expect(decBreakdown.isEmpty, isTrue);
    });

    testWidgets('AnalyticsScreen displays data scoped to selected month', (tester) async {
      final provider = TransactionProvider();
      await provider.clearAllTransactions();

      // Current month tx
      final now = DateTime.now();
      await provider.addTransaction(
        title: 'Belanja Bulan Ini',
        amount: 75000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'cat_food',
        walletId: provider.wallets.first.id,
        date: DateTime(now.year, now.month, 1),
      );

      await tester.pumpWidget(buildApp(const AnalyticsScreen(), provider));
      await tester.pumpAndSettle();

      // Should show the category and amount
      expect(find.text('Makanan & Minuman'), findsOneWidget);
      expect(find.text('1 transaksi'), findsOneWidget);
    });
  });

  group('Daily Reminder Conditional Display Tests', () {
    test('hasTransactionToday and shouldShowDailyReminder toggle cleanly', () async {
      final provider = TransactionProvider();
      await provider.clearAllTransactions();
      await provider.requestNotificationPermission();
      await provider.toggleDailyReminder(true);

      // Initially no transaction today
      expect(provider.hasTransactionToday, isFalse);
      expect(provider.shouldShowDailyReminder, isTrue);

      // Add backdated transaction (yesterday)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await provider.addTransaction(
        title: 'Makan Kemarin',
        amount: 20000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'cat_food',
        walletId: provider.wallets.first.id,
        date: yesterday,
      );

      // Still no transaction today
      expect(provider.hasTransactionToday, isFalse);
      expect(provider.shouldShowDailyReminder, isTrue);

      // Add transaction for today
      final now = DateTime.now();
      final todayTx = await provider.addTransaction(
        title: 'Makan Siang Hari Ini',
        amount: 35000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'cat_food',
        walletId: provider.wallets.first.id,
        date: now,
      );

      // Now today has transaction, reminder should hide
      expect(provider.hasTransactionToday, isTrue);
      expect(provider.shouldShowDailyReminder, isFalse);

      // Delete today's transaction
      await provider.deleteTransaction(todayTx.id);

      // Reverts back to no transaction today
      expect(provider.hasTransactionToday, isFalse);
      expect(provider.shouldShowDailyReminder, isTrue);
    });
  });
}
