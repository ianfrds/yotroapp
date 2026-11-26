import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/models/budget_model.dart';
import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/subscription_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/models/wallet_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Critical Sync & Persistence Protection', () {
    test('applyCloudSnapshot preserves local subscriptions not yet in cloud and keeps newer lastPaidDate', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.addSubscription(
        name: 'Spotify Family',
        amount: 86900,
        billingDay: 15,
        cycle: SubscriptionCycle.monthly,
        categoryId: 'cat_bills',
        categoryName: 'Tagihan & Utilitas',
        walletId: 'w_bank',
      );

      final localPaidDate = DateTime(2026, 11, 20, 10, 0);
      final cloudSharedSub = SubscriptionModel(
        id: 'sub_cloud_1',
        name: 'Netflix',
        amount: 186000,
        billingDay: 25,
        cycle: SubscriptionCycle.monthly,
        categoryId: 'cat_bills',
        categoryName: 'Tagihan & Utilitas',
        walletId: 'w_bank',
        lastPaidDate: null,
        createdAt: DateTime(2026, 11, 1),
      );

      // Simulate local has sub_cloud_1 paid locally, plus Spotify Family only local
      await provider.updateSubscription(cloudSharedSub.copyWith(lastPaidDate: localPaidDate));
      // Add cloudSharedSub directly first if updateSubscription didn't insert it
      provider.applyCloudSnapshot(
        subscriptions: [cloudSharedSub.copyWith(lastPaidDate: localPaidDate)],
      );

      // Now simulate Day 2 cloud pull where cloud only has cloudSharedSub (unpaid) and doesn't have Spotify Family yet
      provider.applyCloudSnapshot(
        subscriptions: [cloudSharedSub],
      );

      final spotify = provider.subscriptions.where((s) => s.name == 'Spotify Family').toList();
      expect(spotify.length, 1);

      final netflix = provider.subscriptions.firstWhere((s) => s.id == 'sub_cloud_1');
      expect(netflix.lastPaidDate, isNotNull);
      expect(netflix.lastPaidDate!.year, 2026);
      expect(netflix.lastPaidDate!.month, 11);
      expect(netflix.lastPaidDate!.day, 20);
    });

    test('Budget mutations update local state and reset day cleanly', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.updateOverallBudget(5000000);
      await provider.updateCategoryBudget('Makanan & Minuman', 1500000);
      await provider.updateBudgetResetDay(25);

      expect(provider.budget.overallMonthlyLimit, 5000000);
      expect(provider.budget.categoryBudgets['Makanan & Minuman'], 1500000);
      expect(provider.budget.monthlyResetDay, 25);

      await provider.deleteCategoryBudget('Makanan & Minuman');
      expect(provider.budget.categoryBudgets.containsKey('Makanan & Minuman'), isFalse);

      await provider.deleteOverallBudget();
      expect(provider.budget.overallMonthlyLimit, 0.0);
    });

    test('Profile updates persist name and phone cleanly', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.updateProfile(
        name: 'Ian Firdaus Updated',
        phone: '081234567890',
      );

      expect(provider.userName, 'Ian Firdaus Updated');
      expect(provider.userPhone, '081234567890');
    });

    test('applyCloudSnapshot applies cloud budget cleanly', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final cloudBudget = BudgetModel(
        overallMonthlyLimit: 7500000,
        categoryBudgets: {'Transportasi': 800000},
        monthlyResetDay: 10,
      );

      provider.applyCloudSnapshot(budget: cloudBudget);

      expect(provider.budget.overallMonthlyLimit, 7500000);
      expect(provider.budget.categoryBudgets['Transportasi'], 800000);
      expect(provider.budget.monthlyResetDay, 10);
    });

    test('applyCloudSnapshot automatically reconciles stale cloud wallet balance to transaction net sum', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final walletId = provider.wallets.first.id;
      final tx = TransactionModel(
        id: 'tx_drift_1',
        title: 'Freelance',
        amount: 700000,
        type: TransactionType.income,
        categoryId: 'other_inc',
        categoryName: 'Lainnya',
        walletId: walletId,
        timestamp: DateTime(2026, 11, 23),
      );

      // Simulate stale cloud wallet balance (63500) despite 700000 income in transactions
      provider.applyCloudSnapshot(
        wallets: [WalletModel(id: walletId, name: 'Dompet Utama', type: 'Cash', balance: 63500)],
        transactions: [tx],
      );

      // Should auto-reconcile immediately without manual intervention
      expect(provider.wallets.first.balance, 700000);
      expect(provider.hasWalletBalanceDrift, isFalse);
    });

    test('applyCloudSnapshot preserves local wallet balance when it matches transactions while cloud wallet is stale', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final walletId = provider.wallets.first.id;
      final tx = TransactionModel(
        id: 'tx_sync_1',
        title: 'Freelance',
        amount: 700000,
        type: TransactionType.income,
        categoryId: 'other_inc',
        categoryName: 'Lainnya',
        walletId: walletId,
        timestamp: DateTime(2026, 11, 23),
      );

      // First establish consistent local state: wallet=700000, tx=700000
      provider.applyCloudSnapshot(
        wallets: [WalletModel(id: walletId, name: 'Dompet Utama', type: 'Cash', balance: 700000)],
        transactions: [tx],
      );
      expect(provider.wallets.first.balance, 700000);

      // Now cloud snapshot returns stale wallet balance (63500) with same transaction
      provider.applyCloudSnapshot(
        wallets: [WalletModel(id: walletId, name: 'Dompet Utama', type: 'Cash', balance: 63500)],
        transactions: [tx],
      );

      expect(provider.wallets.first.balance, 700000);
      expect(provider.hasWalletBalanceDrift, isFalse);
    });

    test('Tight-loop addTransaction generates unique transaction IDs without collision', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      final walletId = provider.wallets.first.id;

      final ids = <String>{};
      for (int i = 0; i < 10; i++) {
        final tx = await provider.addTransaction(
          title: 'Item $i',
          amount: 1000,
          type: TransactionType.expense,
          categoryName: 'Makanan & Minuman',
          categoryId: 'food',
          walletId: walletId,
        );
        ids.add(tx.id);
      }

      expect(ids.length, 10);
    });

    test('addTransaction with invalid walletId resolves tx.walletId to fallback wallet', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      final fallbackId = provider.wallets.first.id;

      final tx = await provider.addTransaction(
        title: 'Bonus',
        amount: 250000,
        type: TransactionType.income,
        categoryName: 'Lainnya',
        categoryId: 'other_inc',
        walletId: 'w_non_existent_id',
      );

      expect(tx.walletId, fallbackId);
      expect(provider.wallets.first.balance, provider.calculateWalletNetBalance(fallbackId));
      expect(provider.hasWalletBalanceDrift, isFalse);
    });

    test('Manual per-wallet balance (syncToTransaction: false) is not overwritten by auto-reconcile', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.addWallet(
        name: 'Dompet Manual Uji',
        type: 'Cash',
        initialBalance: 500000,
        syncToTransaction: false,
      );
      final manualWallet = provider.wallets.firstWhere((w) => w.name == 'Dompet Manual Uji');

      // Add a transaction to that manual wallet (balance becomes 550000)
      await provider.addTransaction(
        title: 'Cashback',
        amount: 50000,
        type: TransactionType.income,
        categoryName: 'Lainnya',
        categoryId: 'other_inc',
        walletId: manualWallet.id,
      );
      expect(manualWallet.balance, 550000);

      // Trigger auto-reconcile (force: true) -> must NOT wipe out the 500000 manual initial balance!
      provider.reconcileWalletBalances(force: true);
      expect(manualWallet.balance, 550000);
    });

    test('deleteWallet reassigns transactions cleanly and reconciles fallback balance', () async {
      final provider = TransactionProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.addWallet(
        name: 'Dompet Kedua',
        type: 'E-Wallet',
        initialBalance: 100000,
        syncToTransaction: true,
      );
      final secondWallet = provider.wallets.firstWhere((w) => w.name == 'Dompet Kedua');
      final firstWallet = provider.wallets.firstWhere((w) => w.id != secondWallet.id);
      final firstInitial = firstWallet.balance;

      await provider.addTransaction(
        title: 'Jajan GoPay',
        amount: 25000,
        type: TransactionType.expense,
        categoryName: 'Makanan & Minuman',
        categoryId: 'food',
        walletId: secondWallet.id,
      );

      await provider.deleteWallet(secondWallet.id);

      expect(provider.wallets.any((w) => w.id == secondWallet.id), isFalse);
      expect(
        provider.transactions.any((tx) => tx.walletId == secondWallet.id),
        isFalse,
      );
      expect(firstWallet.balance, firstInitial + 75000);
    });
  });
}
