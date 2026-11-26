import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/wallets_screen.dart';

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

  group('Wallet & Transaction Sync Business Logic Tests', () {
    test('Adding wallet with sync enabled creates initial balance transaction', () async {
      final provider = TransactionProvider();
      await provider.loadData();
      final initialTxCount = provider.transactions.length;

      await provider.addWallet(
        name: 'Bank Jago',
        type: 'Bank Account',
        initialBalance: 500000.0,
        syncToTransaction: true,
      );

      expect(provider.wallets.any((w) => w.name == 'Bank Jago'), isTrue);
      final jagoWallet = provider.wallets.firstWhere((w) => w.name == 'Bank Jago');
      expect(jagoWallet.balance, 500000.0);

      // Verify transaction created
      expect(provider.transactions.length, initialTxCount + 1);
      final createdTx = provider.transactions.first;
      expect(createdTx.type, TransactionType.income);
      expect(createdTx.amount, 500000.0);
      expect(createdTx.title, contains('Saldo Awal - Bank Jago'));
      expect(createdTx.walletId, jagoWallet.id);
    });

    test('Adding wallet with sync disabled does not create transaction', () async {
      final provider = TransactionProvider();
      await provider.loadData();
      final initialTxCount = provider.transactions.length;

      await provider.addWallet(
        name: 'Brankas Tunai',
        type: 'Cash',
        initialBalance: 1000000.0,
        syncToTransaction: false,
      );

      final cashWallet = provider.wallets.firstWhere((w) => w.name == 'Brankas Tunai');
      expect(cashWallet.balance, 1000000.0);
      // Transactions count must not change
      expect(provider.transactions.length, initialTxCount);
    });

    test('Updating wallet with positive balance change creates income adjustment transaction', () async {
      final provider = TransactionProvider();
      await provider.loadData();

      // Add a test wallet with 0 sync first
      await provider.addWallet(
        name: 'BCA Khusus',
        type: 'Bank Account',
        initialBalance: 200000.0,
        syncToTransaction: false,
      );
      final wallet = provider.wallets.firstWhere((w) => w.name == 'BCA Khusus');
      final txCountBefore = provider.transactions.length;

      // Update balance from 200.000 to 350.000 (+150.000)
      await provider.updateWallet(
        id: wallet.id,
        name: 'BCA Khusus',
        type: 'Bank Account',
        balance: 350000.0,
        syncToTransaction: true,
      );

      expect(wallet.balance, 350000.0);
      expect(provider.transactions.length, txCountBefore + 1);

      final adjTx = provider.transactions.first;
      expect(adjTx.type, TransactionType.income);
      expect(adjTx.amount, 150000.0);
      expect(adjTx.title, contains('Penyesuaian Saldo - BCA Khusus'));
      expect(adjTx.walletId, wallet.id);
    });

    test('Updating wallet with negative balance change creates expense adjustment transaction', () async {
      final provider = TransactionProvider();
      await provider.loadData();

      await provider.addWallet(
        name: 'OVO Merchant',
        type: 'E-Wallet',
        initialBalance: 500000.0,
        syncToTransaction: false,
      );
      final wallet = provider.wallets.firstWhere((w) => w.name == 'OVO Merchant');
      final txCountBefore = provider.transactions.length;

      // Update balance from 500.000 to 420.000 (-80.000)
      await provider.updateWallet(
        id: wallet.id,
        name: 'OVO Merchant',
        type: 'E-Wallet',
        balance: 420000.0,
        syncToTransaction: true,
      );

      expect(wallet.balance, 420000.0);
      expect(provider.transactions.length, txCountBefore + 1);

      final adjTx = provider.transactions.first;
      expect(adjTx.type, TransactionType.expense);
      expect(adjTx.amount, 80000.0);
      expect(adjTx.title, contains('Penyesuaian Saldo - OVO Merchant'));
      expect(adjTx.walletId, wallet.id);
    });

    test('Updating wallet with sync disabled updates balance without creating transaction', () async {
      final provider = TransactionProvider();
      await provider.loadData();

      await provider.addWallet(
        name: 'Dompet Manual',
        type: 'Cash',
        initialBalance: 100000.0,
        syncToTransaction: false,
      );
      final wallet = provider.wallets.firstWhere((w) => w.name == 'Dompet Manual');
      final txCountBefore = provider.transactions.length;

      await provider.updateWallet(
        id: wallet.id,
        name: 'Dompet Manual Edit',
        type: 'Cash',
        balance: 999000.0,
        syncToTransaction: false,
      );

      expect(wallet.balance, 999000.0);
      expect(wallet.name, 'Dompet Manual Edit');
      expect(provider.transactions.length, txCountBefore);
    });

    test('Updating wallet with identical balance does not create transaction', () async {
      final provider = TransactionProvider();
      await provider.loadData();

      await provider.addWallet(
        name: 'Dompet Tetap',
        type: 'Cash',
        initialBalance: 100000.0,
        syncToTransaction: false,
      );
      final wallet = provider.wallets.firstWhere((w) => w.name == 'Dompet Tetap');
      final txCountBefore = provider.transactions.length;

      await provider.updateWallet(
        id: wallet.id,
        name: 'Dompet Tetap Berganti Nama',
        type: 'Cash',
        balance: 100000.0,
        syncToTransaction: true,
      );

      expect(wallet.name, 'Dompet Tetap Berganti Nama');
      expect(provider.transactions.length, txCountBefore);
    });

    test('Provider toggle syncWalletToTransactions changes state', () async {
      final provider = TransactionProvider();
      await provider.loadData();

      expect(provider.syncWalletToTransactions, isTrue);
      await provider.setSyncWalletToTransactions(false);
      expect(provider.syncWalletToTransactions, isFalse);

      await provider.setSyncWalletToTransactions(true);
      expect(provider.syncWalletToTransactions, isTrue);
    });
  });

  group('WalletsScreen UI Tests', () {
    testWidgets('WalletsScreen omits Otomatisasi Transaksi toggle and renders Transfer card', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      await tester.pumpWidget(buildTestWidget(
        child: const WalletsScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Otomatisasi Transaksi'), findsNothing);
      expect(find.text('Sinkronkan ke Transaksi'), findsNothing);
      expect(find.text('Transfer Antar Dompet'), findsOneWidget);
    });

    testWidgets('Add wallet modal sheet omits Catat ke Transaksi toggle and enforces sync', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      await tester.pumpWidget(buildTestWidget(
        child: const WalletsScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Tap FAB 'Tambah Dompet'
      expect(find.byKey(const Key('fab_add_wallet')), findsOneWidget);
      await tester.tap(find.byKey(const Key('fab_add_wallet')));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Dompet / Akun'), findsOneWidget);
      expect(find.text('Catat ke Transaksi'), findsNothing);
      expect(find.text('Buat transaksi pemasukan saldo awal otomatis'), findsNothing);
      // Account type defaults to Cash / Tunai
      expect(find.text('Cash / Tunai'), findsOneWidget);
    });

    testWidgets('Tapping wallet navigates to WalletDetailScreen showing wallet transactions and edit modal', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      // Ensure we have a wallet with legacy type 'Dompet'
      final targetWallet = provider.wallets.first;
      targetWallet.type = 'Dompet';
      await provider.addTransaction(
        title: 'Gaji Khusus Dompet Ini',
        amount: 350000,
        type: TransactionType.income,
        categoryName: 'Gaji',
        categoryId: 'salary',
        walletId: targetWallet.id,
      );

      await tester.pumpWidget(buildTestWidget(
        child: const WalletsScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      // Tap on the wallet card to navigate to WalletDetailScreen
      await tester.tap(find.text(targetWallet.name).first);
      await tester.pumpAndSettle();

      expect(find.text('Informasi Dompet'), findsOneWidget);
      expect(find.text('Riwayat Transaksi Dompet'), findsOneWidget);
      expect(find.text('Gaji Khusus Dompet Ini'), findsOneWidget);

      // Tap Edit button in WalletDetailScreen header
      await tester.tap(find.byKey(const Key('btn_edit_wallet')));
      await tester.pumpAndSettle();

      expect(find.text('Ubah Dompet / Akun'), findsOneWidget);
      // The dropdown correctly resolved 'Dompet' -> 'Cash' ('Cash / Tunai'), never blank
      expect(find.text('Cash / Tunai'), findsOneWidget);
    });
  });
}
