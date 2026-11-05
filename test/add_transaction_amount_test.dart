import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/add_transaction_screen.dart';
import 'package:money_tracker/screens/splash_screen.dart';
import 'package:provider/provider.dart';

Widget buildTestScreen(Widget child, TransactionProvider provider) {
  return MaterialApp(
    home: ChangeNotifierProvider<TransactionProvider>.value(
      value: provider,
      child: child,
    ),
  );
}

void main() {
  group('AddTransactionScreen Amount Formatting & No Leading Zero', () {
    testWidgets('Amount textfield has autofocus and focusNode on open', (tester) async {
      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestScreen(const AddTransactionScreen(), provider));
      await tester.pumpAndSettle();

      final amountFieldFinder = find.byType(TextField).first;
      final textField = tester.widget(amountFieldFinder) as TextField;
      expect(textField.autofocus, isTrue);
      expect(textField.focusNode!.hasFocus, isTrue);
    });

    testWidgets('default amount is 0 and typing 5 replaces 0 without leading zero', (tester) async {
      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestScreen(const AddTransactionScreen(), provider));
      await tester.pumpAndSettle();

      final amountFieldFinder = find.byType(TextField).first;
      final controller = (tester.widget(amountFieldFinder) as TextField).controller!;
      expect(controller.text, '0');

      // Enter '5'
      await tester.enterText(amountFieldFinder, '5');
      await tester.pumpAndSettle();

      expect(controller.text, '5');
      expect(find.text('05'), findsNothing);

      // Append '000' to make 5.000
      await tester.enterText(amountFieldFinder, '5000');
      await tester.pumpAndSettle();
      expect(controller.text, '5.000');

      // Change to 100000 -> 100.000
      await tester.enterText(amountFieldFinder, '100000');
      await tester.pumpAndSettle();
      expect(controller.text, '100.000');

      // Change to 2000000 -> 2.000.000
      await tester.enterText(amountFieldFinder, '2000000');
      await tester.pumpAndSettle();
      expect(controller.text, '2.000.000');
    });

    testWidgets('Nominal card contains title/note field and accepts input', (tester) async {
      final provider = TransactionProvider();
      await tester.pumpWidget(buildTestScreen(const AddTransactionScreen(), provider));
      await tester.pumpAndSettle();

      final noteFieldFinder = find.widgetWithText(TextField, 'Catatan / judul transaksi (cth: Mie Goreng, Bensin)...');
      expect(noteFieldFinder, findsOneWidget);

      await tester.enterText(noteFieldFinder, 'Nasi Goreng Spesial');
      await tester.pumpAndSettle();

      expect(find.text('Nasi Goreng Spesial'), findsOneWidget);
    });

    testWidgets('Edit transaction formats existing amount with dots', (tester) async {
      final provider = TransactionProvider();
      final tx = TransactionModel(
        id: 'tx_test',
        title: 'Kopi',
        amount: 35000,
        type: TransactionType.expense,
        categoryName: 'Food & Beverage',
        categoryId: 'food_beverage',
        walletId: 'w_bank',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(buildTestScreen(AddTransactionScreen(initialTransaction: tx), provider));
      await tester.pumpAndSettle();

      expect(find.text('35.000'), findsOneWidget);
    });
  });

  group('SplashScreen & Rebranding to Yotro Tests', () {
    testWidgets('SplashScreen displays Yotro branding and emblem', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen(autoNavigate: false)));
      await tester.pump();
      expect(find.text('Yotro'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Personal Finance & Wealth Tracker'), findsOneWidget);
    });
  });
}
