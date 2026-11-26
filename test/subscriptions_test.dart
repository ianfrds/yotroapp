import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/subscription_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/dashboard_screen.dart';
import 'package:money_tracker/screens/subscriptions_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({
    required Widget child,
    required TransactionProvider provider,
  }) {
    return ChangeNotifierProvider<TransactionProvider>.value(
      value: provider,
      child: MaterialApp(home: child),
    );
  }

  group('SubscriptionModel Unit Tests', () {
    test('SubscriptionModel toJson and fromJson roundtrip correctly', () {
      final now = DateTime(2026, 11, 20);
      final sub = SubscriptionModel(
        id: 'sub_test_1',
        name: 'Spotify Family',
        amount: 86000,
        billingDay: 15,
        cycle: SubscriptionCycle.monthly,
        categoryId: 'cat_entertainment',
        categoryName: 'Hiburan',
        walletId: 'w_bank',
        reminderEnabled: true,
        reminderDaysBefore: 1,
        lastPaidDate: DateTime(2026, 11, 15),
        createdAt: now,
      );

      final json = sub.toJson();
      final restored = SubscriptionModel.fromJson(json);

      expect(restored.id, 'sub_test_1');
      expect(restored.name, 'Spotify Family');
      expect(restored.amount, 86000);
      expect(restored.billingDay, 15);
      expect(restored.cycle, SubscriptionCycle.monthly);
      expect(restored.isPaidInMonth(DateTime(2026, 11)), isTrue);
      expect(restored.isPaidInMonth(DateTime(2026, 12)), isFalse);
    });

    test('SubscriptionModel calculates status and due date accurately', () {
      final now = DateTime(2026, 11, 20);

      // 1. Due Today
      final dueToday = SubscriptionModel(
        id: 'sub_today',
        name: 'Listrik',
        amount: 200000,
        billingDay: 20,
        categoryId: 'bills',
        categoryName: 'Tagihan',
        walletId: 'w1',
        createdAt: now,
      );
      expect(dueToday.getStatus(now), SubscriptionStatus.dueToday);

      // 2. Due Soon (in 2 days)
      final dueSoon = SubscriptionModel(
        id: 'sub_soon',
        name: 'Netflix',
        amount: 186000,
        billingDay: 22,
        categoryId: 'bills',
        categoryName: 'Tagihan',
        walletId: 'w1',
        createdAt: now,
      );
      expect(dueSoon.getStatus(now), SubscriptionStatus.dueSoon);
      expect(dueSoon.daysUntilDue(now), 2);

      // 3. Overdue (was due on 10th and not paid)
      final overdue = SubscriptionModel(
        id: 'sub_overdue',
        name: 'WiFi',
        amount: 350000,
        billingDay: 10,
        categoryId: 'bills',
        categoryName: 'Tagihan',
        walletId: 'w1',
        createdAt: now,
      );
      expect(overdue.getStatus(now), SubscriptionStatus.overdue);

      // 4. Paid this month
      final paid = SubscriptionModel(
        id: 'sub_paid',
        name: 'BPJS',
        amount: 150000,
        billingDay: 10,
        categoryId: 'health',
        categoryName: 'Kesehatan',
        walletId: 'w1',
        lastPaidDate: DateTime(2026, 11, 10),
        createdAt: now,
      );
      expect(paid.getStatus(now), SubscriptionStatus.paid);
      expect(paid.isPaidInMonth(now), isTrue);
    });
  });

  group('TransactionProvider Subscriptions Management & Payment Flow Tests', () {
    test('Provider adds, updates, deletes, and calculates commitment totals', () async {
      final provider = TransactionProvider();
      await provider.clearAllTransactions();

      expect(provider.totalMonthlySubscriptions, 0.0);

      // Add subscription 1
      await provider.addSubscription(
        name: 'Netflix',
        amount: 186000,
        billingDay: 25,
        categoryId: 'cat_ent',
        categoryName: 'Hiburan',
        walletId: provider.wallets.first.id,
      );

      // Add subscription 2
      await provider.addSubscription(
        name: 'WiFi IndiHome',
        amount: 350000,
        billingDay: 15,
        categoryId: 'cat_bills',
        categoryName: 'Tagihan & Utilitas',
        walletId: provider.wallets.first.id,
      );

      expect(provider.subscriptions.length, 2);
      expect(provider.totalMonthlySubscriptions, 536000.0);
      expect(provider.totalPaidSubscriptionsThisMonth, 0.0);
      expect(provider.totalUnpaidSubscriptionsThisMonth, 536000.0);
      expect(provider.unpaidSubscriptionsCount, 2);

      // Update subscription 1 amount
      final sub1 = provider.subscriptions.first;
      await provider.updateSubscription(sub1.copyWith(amount: 200000));
      expect(provider.totalMonthlySubscriptions, 550000.0);

      // Delete subscription 2
      final sub2 = provider.subscriptions.last;
      await provider.deleteSubscription(sub2.id);
      expect(provider.subscriptions.length, 1);
      expect(provider.totalMonthlySubscriptions, 200000.0);
    });

    test('paySubscription creates expense transaction, cuts wallet balance, and marks paid', () async {
      final provider = TransactionProvider();
      await provider.clearAllTransactions();

      final wallet = provider.wallets.first;
      final initialBalance = wallet.balance;

      await provider.addSubscription(
        name: 'Netflix Premium',
        amount: 186000,
        billingDay: 25,
        categoryId: 'cat_ent',
        categoryName: 'Hiburan',
        walletId: wallet.id,
      );

      final sub = provider.subscriptions.first;
      expect(sub.isPaidInMonth(DateTime.now()), isFalse);

      // Pay the subscription
      await provider.paySubscription(
        sub.id,
        walletId: wallet.id,
        date: DateTime.now(),
      );

      // Check transaction created
      final latestTx = provider.transactions.first;
      expect(latestTx.title, 'Tagihan Netflix Premium');
      expect(latestTx.amount, 186000);
      expect(latestTx.type, TransactionType.expense);
      expect(latestTx.walletId, wallet.id);

      // Check wallet balance deducted
      expect(wallet.balance, initialBalance - 186000);

      // Check subscription marked as paid
      final updatedSub = provider.subscriptions.first;
      expect(updatedSub.isPaidInMonth(DateTime.now()), isTrue);
      expect(provider.totalPaidSubscriptionsThisMonth, 186000);
      expect(provider.totalUnpaidSubscriptionsThisMonth, 0.0);
      expect(provider.unpaidSubscriptionsCount, 0);

      // Unpay subscription rolls back transaction & wallet balance
      await provider.unpaySubscription(sub.id);
      expect(provider.subscriptions.first.isPaidInMonth(DateTime.now()), isFalse);
      expect(provider.unpaidSubscriptionsCount, 1);
      expect(wallet.balance, initialBalance);
      expect(provider.transactions.any((tx) => tx.title == 'Tagihan Netflix Premium'), isFalse);
    });

    test('paySubscription prevents duplicate payment in the same period', () async {
      final provider = TransactionProvider();
      await provider.clearAllTransactions();
      final wallet = provider.wallets.first;
      final initialBalance = wallet.balance;

      await provider.addSubscription(
        name: 'Spotify',
        amount: 55000,
        billingDay: 10,
        categoryId: 'cat_ent',
        categoryName: 'Hiburan',
        walletId: wallet.id,
      );
      final sub = provider.subscriptions.first;
      final now = DateTime.now();

      await provider.paySubscription(sub.id, walletId: wallet.id, date: now);
      await provider.paySubscription(sub.id, walletId: wallet.id, date: now);

      expect(wallet.balance, initialBalance - 55000);
      expect(provider.transactions.where((tx) => tx.title == 'Tagihan Spotify').length, 1);
    });

    test('SubscriptionCycle yearly and weekly evaluate paid status per cycle', () {
      // Yearly paid in Nov 2026 stays paid in Dec 2026, resets in Jan 2027
      final yearlySub = SubscriptionModel(
        id: 'sub_yearly',
        name: 'Domain .com',
        amount: 200000,
        billingDay: 15,
        cycle: SubscriptionCycle.yearly,
        categoryId: 'bills',
        categoryName: 'Tagihan',
        walletId: 'w1',
        lastPaidDate: DateTime(2026, 11, 15),
        createdAt: DateTime(2026, 11, 15),
      );
      expect(yearlySub.isPaidInMonth(DateTime(2026, 12, 1)), isTrue);
      expect(yearlySub.isPaidInMonth(DateTime(2027, 1, 1)), isFalse);

      // Weekly paid on Monday Nov 23 stays paid on Friday Nov 27, resets on Monday Nov 30
      final weeklySub = SubscriptionModel(
        id: 'sub_weekly',
        name: 'Katering Mingguan',
        amount: 150000,
        billingDay: 23,
        cycle: SubscriptionCycle.weekly,
        categoryId: 'food',
        categoryName: 'Makanan',
        walletId: 'w1',
        lastPaidDate: DateTime(2026, 11, 23),
        createdAt: DateTime(2026, 11, 23),
      );
      expect(weeklySub.isPaidInMonth(DateTime(2026, 11, 27)), isTrue);
      expect(weeklySub.isPaidInMonth(DateTime(2026, 11, 30)), isFalse);
    });
  });

  group('SubscriptionsScreen Widget & UI Interaction Tests', () {
    testWidgets('SubscriptionsScreen renders hero commitment card and list', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.clearAllTransactions();

      await provider.addSubscription(
        name: 'Listrik PLN',
        amount: 250000,
        billingDay: 20,
        categoryId: 'cat_bills',
        categoryName: 'Tagihan & Utilitas',
        walletId: provider.wallets.first.id,
      );

      await tester.pumpWidget(buildTestWidget(
        child: const SubscriptionsScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tagihan & Langganan'), findsOneWidget);
      expect(find.text('Komitmen Rutin Bulanan'), findsOneWidget);
      expect(find.text('Listrik PLN'), findsOneWidget);
      expect(find.text('Bayar'), findsOneWidget);
      expect(find.text('Belum Dibayar'), findsOneWidget);
      expect(find.text('Sudah Dibayar'), findsOneWidget);
    });

    testWidgets('DashboardScreen renders Tagihan quick action and navigates to SubscriptionsScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestWidget(
        child: const DashboardScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      final tagihanQuickAction = find.text('Tagihan');
      expect(tagihanQuickAction, findsOneWidget);

      await tester.tap(tagihanQuickAction);
      await tester.pumpAndSettle();

      expect(find.text('Tagihan & Langganan'), findsOneWidget);
    });
  });
}
