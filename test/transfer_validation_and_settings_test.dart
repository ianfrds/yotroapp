import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/add_transaction_screen.dart';
import 'package:money_tracker/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Transfer Validation Tests', () {
    test('TransactionProvider rejects transfer when fromWalletId == toWalletId', () async {
      final provider = TransactionProvider();

      expect(
        () => provider.addTransaction(
          title: 'Transfer Mandiri ke Mandiri',
          amount: 50000,
          type: TransactionType.transfer,
          categoryId: 'transfer',
          categoryName: 'Transfer',
          walletId: 'w_bank',
          fromWalletId: 'w_bank',
          toWalletId: 'w_bank',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    testWidgets('AddTransactionScreen displays alert banner and blocks save when transfer wallets match',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TransactionProvider>.value(
            value: provider,
            child: const AddTransactionScreen(
              initialType: TransactionType.transfer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify transfer mode is active
      expect(find.text('Dari Dompet'), findsOneWidget);
      expect(find.text('Ke Dompet'), findsOneWidget);

      // Initially, wallets are distinct, so error banner shouldn't appear yet
      expect(find.text('Dompet asal dan tujuan tidak boleh sama'), findsNothing);

      // Now change "Ke Dompet" dropdown to match "Dari Dompet" (w_bank)
      final dropdowns = find.byType(DropdownButton<String>);
      expect(dropdowns, findsNWidgets(2));

      // Tap the second dropdown ("Ke Dompet")
      await tester.tap(dropdowns.at(1));
      await tester.pumpAndSettle();

      // Select the first wallet name (e.g. 'BCA Prioritas') which matches fromWallet
      final firstWalletName = provider.wallets.first.name;
      final bankOption = find.text(firstWalletName).last;
      await tester.tap(bankOption);
      await tester.pumpAndSettle();

      // Verify warning alert banner appears
      expect(find.text('Dompet asal dan tujuan tidak boleh sama'), findsWidgets);

      // Enter amount > 0 so that wallet check is evaluated
      final amountFinder = find.byKey(const Key('amount_input_field'));
      if (amountFinder.evaluate().isNotEmpty) {
        await tester.enterText(amountFinder, '50000');
        await tester.pumpAndSettle();
      }

      // Try tapping "Simpan Transaksi"
      final initialTxCount = provider.transactions.length;
      final saveButton = find.byKey(const Key('btn_save_transaction'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Transaction count should NOT change
      expect(provider.transactions.length, equals(initialTxCount));
      // Error alert remains visible
      expect(find.text('Dompet asal dan tujuan tidak boleh sama'), findsWidgets);
    });
  });

  group('SettingsScreen Reset Data Bawaan Tests', () {
    testWidgets('SettingsScreen does not show Reset ke Data Bawaan in native mobile environment',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TransactionProvider>.value(
            value: provider,
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On non-web (standard flutter_test defaults kIsWeb == false)
      // "Reset ke Data Bawaan" MUST NOT exist
      expect(find.text('Reset ke Data Bawaan'), findsNothing);

      // "Kosongkan Riwayat Transaksi" MUST still exist
      expect(find.text('Kosongkan Riwayat Transaksi'), findsOneWidget);
    });
  });
}
