import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/models/wallet_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Wallet Reconciliation & Cloud Sync Protection Tests', () {
    test('reconcileWalletBalances auto-repairs Rp 0 wallet from transaction history', () async {
      final provider = TransactionProvider();
      await provider.loadData();

      // Configure a single wallet with 0 balance
      final walletId = 'w_main_test';
      final mainWallet = WalletModel(
        id: walletId,
        name: 'Dompet Utama',
        type: 'Cash',
        balance: 0.0,
      );

      // Add transactions: Income Rp 220,000, Expense Rp 55,000
      final tx1 = TransactionModel(
        id: 'tx_inc_1',
        title: 'Gaji / Pemasukan',
        amount: 220000.0,
        type: TransactionType.income,
        categoryId: 'salary',
        categoryName: 'Gaji',
        walletId: walletId,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      );
      final tx2 = TransactionModel(
        id: 'tx_exp_1',
        title: 'Bensin & Pengeluaran',
        amount: 55000.0,
        type: TransactionType.expense,
        categoryId: 'transport',
        categoryName: 'Transportasi',
        walletId: walletId,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      );

      // Inject state
      provider.applyCloudSnapshot(
        wallets: [mainWallet],
        transactions: [tx1, tx2],
      );

      // Because applyCloudSnapshot automatically reconciles, verify wallet is already repaired!
      expect(provider.wallets.first.balance, 165000.0);
      expect(provider.totalBalance, 165000.0);
    });

    test('reconcileWalletBalances correctly handles multi-wallet transfers', () async {
      final provider = TransactionProvider();
      await provider.loadData();

      final wA = WalletModel(id: 'w_a', name: 'Dompet A', type: 'Bank', balance: 0.0);
      final wB = WalletModel(id: 'w_b', name: 'Dompet B', type: 'E-Wallet', balance: 0.0);

      final txIncomeA = TransactionModel(
        id: 'tx_inc_a',
        title: 'Top Up A',
        amount: 100000.0,
        type: TransactionType.income,
        categoryId: 'topup',
        categoryName: 'Top Up',
        walletId: 'w_a',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      );

      final txTransfer = TransactionModel(
        id: 'tx_trf',
        title: 'Transfer A ke B',
        amount: 40000.0,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        categoryName: 'Transfer',
        walletId: 'w_a',
        fromWalletId: 'w_a',
        toWalletId: 'w_b',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      );

      provider.applyCloudSnapshot(
        wallets: [wA, wB],
        transactions: [txIncomeA, txTransfer],
      );

      final repairedA = provider.wallets.firstWhere((w) => w.id == 'w_a');
      final repairedB = provider.wallets.firstWhere((w) => w.id == 'w_b');

      expect(repairedA.balance, 60000.0);
      expect(repairedB.balance, 40000.0);
      expect(provider.totalBalance, 100000.0);
    });

    test('applyCloudSnapshot protects local balance when cloud sends 0 balance with no transactions', () async {
      final provider = TransactionProvider();
      await provider.loadData();

      // Set local wallet with valid balance
      final localW = WalletModel(id: 'w_local_1', name: 'Dompet Mandiri', type: 'Bank', balance: 350000.0);
      provider.applyCloudSnapshot(
        wallets: [localW],
        transactions: [],
      );
      expect(provider.wallets.first.balance, 350000.0);

      // Cloud sends snapshot with balance 0.0
      final incomingCloudW = WalletModel(id: 'w_local_1', name: 'Dompet Mandiri', type: 'Bank', balance: 0.0);
      provider.applyCloudSnapshot(
        wallets: [incomingCloudW],
      );

      // Verify local balance was protected and not wiped to 0
      expect(provider.wallets.first.balance, 350000.0);
    });

    test('loadData automatically reconciles corrupted 0 balance from SharedPreferences', () async {
      final corruptedStorage = {
        'userName': 'Ian Frds',
        'wallets': [
          {'id': 'w_saved_1', 'name': 'Dompet Utama', 'type': 'Cash', 'balance': 0.0}
        ],
        'transactions': [
          {
            'id': 'tx_saved_1',
            'title': 'Uang Saku',
            'amount': 220000.0,
            'type': 'income',
            'categoryId': 'other_inc',
            'categoryName': 'Lainnya',
            'walletId': 'w_saved_1',
            'timestamp': DateTime.now().toIso8601String(),
          },
          {
            'id': 'tx_saved_2',
            'title': 'Bensin',
            'amount': 55000.0,
            'type': 'expense',
            'categoryId': 'other_exp',
            'categoryName': 'Lainnya',
            'walletId': 'w_saved_1',
            'timestamp': DateTime.now().toIso8601String(),
          }
        ],
      };

      SharedPreferences.setMockInitialValues({
        'money_tracker_pro_v2_1': jsonEncode(corruptedStorage),
      });

      final provider = TransactionProvider();
      await provider.loadData();

      // Verify loadData auto-repaired the balance to 165,000
      expect(provider.wallets.first.balance, 165000.0);
      expect(provider.totalBalance, 165000.0);
    });
  });
}
