import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/widgets/transaction_tile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Light Mode Cyan to Sapphire Accent Tests', () {
    testWidgets('TransactionTile transfer amount and icon color adapt to sapphire in light mode and cyan in dark mode', (tester) async {
      final provider = TransactionProvider();
      await provider.loadData();

      final transferTx = TransactionModel(
        id: 'tx_transfer_test',
        title: 'Transfer Antar Rekening',
        amount: 250000,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        categoryName: 'Transfer',
        walletId: provider.wallets.first.id,
        toWalletId: provider.wallets.length > 1 ? provider.wallets[1].id : null,
        timestamp: DateTime.now(),
      );

      // 1. Light Mode Widget Test
      await tester.pumpWidget(
        ChangeNotifierProvider<TransactionProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: ThemeData(brightness: Brightness.light),
            home: Scaffold(
              body: TransactionTile(
                transaction: transferTx,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify amount text color in Light Mode is Sapphire (#02539A)
      final lightTextFinder = find.text('Rp 250.000');
      expect(lightTextFinder, findsOneWidget);
      final Text lightTextWidget = tester.widget(lightTextFinder);
      expect(lightTextWidget.style?.color, const Color(0xFF02539A));

      // 2. Dark Mode Widget Test
      await tester.pumpWidget(
        ChangeNotifierProvider<TransactionProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: ThemeData(brightness: Brightness.dark),
            home: Scaffold(
              body: TransactionTile(
                transaction: transferTx,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify amount text color in Dark Mode is Cyan (#55C7FF)
      final darkTextFinder = find.text('Rp 250.000');
      expect(darkTextFinder, findsOneWidget);
      final Text darkTextWidget = tester.widget(darkTextFinder);
      expect(darkTextWidget.style?.color, const Color(0xFF55C7FF));
    });
  });
}
