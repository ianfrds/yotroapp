import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/dashboard_screen.dart';

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

  group('Dashboard Balance Mode (Monthly vs Total Saldo) Tests', () {
    test('Provider calculates dashboardMonthNetBalance and heroCardDisplayBalance correctly', () async {
      final provider = TransactionProvider();
      await provider.loadData();

      // Clear existing transactions to test with predictable amounts
      provider.transactions.clear();

      final now = DateTime.now();
      provider.setSelectedDashboardMonth(now);

      // Add income: 5.000.000, expense: 2.000.000 in this month
      await provider.addTransaction(
        title: 'Gaji Pokok',
        amount: 5000000.0,
        type: TransactionType.income,
        categoryId: 'cat_income_1',
        categoryName: 'Gaji',
        walletId: provider.wallets.first.id,
        date: now,
      );

      await provider.addTransaction(
        title: 'Belanja Bulanan',
        amount: 2000000.0,
        type: TransactionType.expense,
        categoryId: 'cat_expense_1',
        categoryName: 'Belanja',
        walletId: provider.wallets.first.id,
        date: now,
      );

      // In monthly mode
      expect(provider.dashboardBalanceMode, DashboardBalanceMode.monthly);
      expect(provider.dashboardMonthIncome, 5000000.0);
      expect(provider.dashboardMonthExpense, 2000000.0);
      expect(provider.dashboardMonthNetBalance, 3000000.0);
      expect(provider.heroCardDisplayBalance, 3000000.0);

      // Switch to total mode
      provider.setDashboardBalanceMode(DashboardBalanceMode.total);
      expect(provider.dashboardBalanceMode, DashboardBalanceMode.total);
      expect(provider.heroCardDisplayBalance, provider.totalBalance);
      expect(
        provider.bankWalletsTotalBalance + provider.cashAndDigitalWalletsTotalBalance,
        provider.totalBalance,
      );

      // Toggle back to monthly
      provider.toggleDashboardBalanceMode();
      expect(provider.dashboardBalanceMode, DashboardBalanceMode.monthly);
      expect(provider.heroCardDisplayBalance, 3000000.0);
    });

    testWidgets('Dashboard hero card renders Total Saldo button and toggles card mode with individual wallet subcards', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      await tester.pumpWidget(buildTestWidget(
        child: const DashboardScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Default monthly mode: shows 'Saldo saat ini' and 'Total Saldo' button
      expect(find.text('Saldo saat ini'), findsOneWidget);
      expect(find.text('Total Saldo'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Pemasukan'), findsOneWidget);

      // Tap 'Total Saldo' button
      await tester.tap(find.byKey(const ValueKey('hero_total_saldo_button')));
      await tester.pumpAndSettle();

      // Card switches to Total Saldo version with individual wallet sub-cards
      expect(provider.dashboardBalanceMode, DashboardBalanceMode.total);
      expect(find.text('Total Saldo'), findsWidgets); // Button and title both present
      expect(find.text('BCA Utama'), findsOneWidget);
      expect(find.text('Dompet Tunai'), findsOneWidget);
      expect(find.text('GoPay / OVO'), findsOneWidget);

      // Tap Month button to switch back
      await tester.tap(find.byKey(const ValueKey('hero_month_button')));
      await tester.pumpAndSettle();

      expect(provider.dashboardBalanceMode, DashboardBalanceMode.monthly);
      expect(find.text('Saldo saat ini'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Pemasukan'), findsOneWidget);
    });

    testWidgets('Total Saldo button only shows in complete view mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      // In complete view mode: Total Saldo button is shown
      provider.setDashboardViewMode(DashboardViewMode.complete);
      await tester.pumpWidget(buildTestWidget(
        child: const DashboardScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Total Saldo'), findsOneWidget);

      // In incomeExpense mode: Total Saldo button is hidden
      provider.setDashboardViewMode(DashboardViewMode.incomeExpense);
      await tester.pumpAndSettle();
      expect(find.text('Total Saldo'), findsNothing);

      // In expenseOnly mode: Total Saldo button is hidden
      provider.setDashboardViewMode(DashboardViewMode.expenseOnly);
      await tester.pumpAndSettle();
      expect(find.text('Total Saldo'), findsNothing);
    });

    testWidgets('Dashboard hero card can be swiped horizontally and via pagination dots', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      await tester.pumpWidget(buildTestWidget(
        child: const DashboardScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Starts on Monthly card (Page 0)
      expect(provider.dashboardBalanceMode, DashboardBalanceMode.monthly);
      expect(find.text('Saldo saat ini'), findsOneWidget);
      expect(find.text('BCA Utama'), findsNothing);

      // Swipe horizontally to the left (drag -300px)
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Now on Total Saldo card (Page 1)
      expect(provider.dashboardBalanceMode, DashboardBalanceMode.total);
      expect(find.text('BCA Utama'), findsOneWidget);
      expect(find.text('Dompet Tunai'), findsOneWidget);

      // Swipe horizontally to the right on balance area (drag +300px)
      await tester.drag(find.text('Total Saldo').at(1), const Offset(300, 0));
      await tester.pumpAndSettle();

      // Back to Monthly card (Page 0)
      expect(provider.dashboardBalanceMode, DashboardBalanceMode.monthly);
      expect(find.text('Saldo saat ini'), findsOneWidget);

      // Tap second dot to navigate to Total Saldo card
      await tester.tap(find.byKey(const ValueKey('hero_pagination_dot_1')));
      await tester.pumpAndSettle();

      expect(provider.dashboardBalanceMode, DashboardBalanceMode.total);
      expect(find.text('BCA Utama'), findsOneWidget);

      // Tap first dot to navigate back to Monthly card
      await tester.tap(find.byKey(const ValueKey('hero_pagination_dot_0')));
      await tester.pumpAndSettle();

      expect(provider.dashboardBalanceMode, DashboardBalanceMode.monthly);
      expect(find.text('Saldo saat ini'), findsOneWidget);
    });

    testWidgets('Wallets section renders standard Row for <= 2 wallets, and horizontal scroll for > 2 wallets', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      // Case A: 2 wallets -> Row layout (no horizontal SingleChildScrollView inside total page)
      provider.wallets.removeRange(2, provider.wallets.length);
      expect(provider.wallets.length, 2);

      await tester.pumpWidget(buildTestWidget(
        child: const DashboardScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Go to total saldo
      await tester.tap(find.byKey(const ValueKey('hero_total_saldo_button')));
      await tester.pumpAndSettle();

      expect(find.text('BCA Utama'), findsOneWidget);
      expect(find.text('Dompet Tunai'), findsOneWidget);

      // Case B: Add 3rd and 4th wallet -> triggers horizontal scroll with peeking
      await provider.addWallet(name: 'Bank Mandiri', type: 'Bank Account', initialBalance: 500000);
      await provider.addWallet(name: 'ShopeePay', type: 'E-Wallet', initialBalance: 120000);
      expect(provider.wallets.length, 4);

      await tester.pumpAndSettle();
      expect(find.text('BCA Utama'), findsOneWidget);
      expect(find.text('Dompet Tunai'), findsOneWidget);
      expect(find.text('Bank Mandiri'), findsOneWidget);
    });

    testWidgets('Dashboard view modes (incomeExpense and expenseOnly) adjust height snug without overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      // 1. incomeExpense mode
      provider.setDashboardViewMode(DashboardViewMode.incomeExpense);
      await tester.pumpWidget(buildTestWidget(
        child: const DashboardScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Saldo saat ini'), findsNothing);
      expect(find.text('Total Saldo'), findsNothing);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Pemasukan'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. expenseOnly mode
      provider.setDashboardViewMode(DashboardViewMode.expenseOnly);
      await tester.pumpAndSettle();

      expect(find.text('Total Pengeluaran'), findsOneWidget);
      expect(find.text('Total Saldo'), findsNothing);
      expect(find.text('Pengeluaran'), findsNothing); // subcard hidden
      expect(find.text('Pemasukan'), findsNothing); // subcard hidden
      expect(tester.takeException(), isNull);
    });
  });
}
