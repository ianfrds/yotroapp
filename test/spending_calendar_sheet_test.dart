import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/add_transaction_screen.dart';
import 'package:money_tracker/widgets/spending_calendar_card.dart';
import 'package:money_tracker/widgets/transaction_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Tapping calendar date with transactions opens daily transactions sheet', (tester) async {
    final provider = TransactionProvider();
    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month, 15, 14, 30);

    // Seed test transactions on the 15th of the current displayed month
    await provider.addTransaction(
      title: 'Beli Kopi Kenangan',
      amount: 25000.0,
      type: TransactionType.expense,
      categoryName: 'Makanan & Minuman',
      categoryId: 'c_food',
      walletId: 'w_bank',
      date: targetDate,
    );
    await provider.addTransaction(
      title: 'Makan Siang Soto',
      amount: 30000.0,
      type: TransactionType.expense,
      categoryName: 'Makanan & Minuman',
      categoryId: 'c_food',
      walletId: 'w_bank',
      date: targetDate,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<TransactionProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpendingCalendarCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify calendar renders
    expect(find.byType(SpendingCalendarCard), findsOneWidget);

    // Find date cell with '15' and tap it
    final dateCellFinder = find.widgetWithText(InkWell, '15');
    expect(dateCellFinder, findsWidgets);
    await tester.tap(dateCellFinder.first);
    await tester.pumpAndSettle();

    // Verify modal bottom sheet opened
    expect(find.textContaining('15'), findsWidgets);
    expect(find.text('Total Pengeluaran'), findsOneWidget);
    expect(find.text('- Rp 55.000'), findsOneWidget);
    expect(find.text('2 Mutasi'), findsOneWidget);

    // Verify TransactionTiles render
    expect(find.byType(TransactionTile), findsNWidgets(2));
    expect(find.text('Beli Kopi Kenangan'), findsOneWidget);
    expect(find.text('Makan Siang Soto'), findsOneWidget);
  });

  testWidgets('Tapping empty calendar date opens sheet with clean empty state and Catat Transaksi button', (tester) async {
    final provider = TransactionProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<TransactionProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpendingCalendarCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find date cell with '8' (which has 0 transactions) and tap it
    final dateCellFinder = find.widgetWithText(InkWell, '8');
    expect(dateCellFinder, findsWidgets);
    await tester.tap(dateCellFinder.first);
    await tester.pumpAndSettle();

    // Verify modal bottom sheet opened with empty state
    expect(find.text('Belum Ada Transaksi'), findsOneWidget);
    expect(find.textContaining('Tidak ada mutasi yang dicatat pada 8'), findsOneWidget);
    expect(find.text('Catat Transaksi'), findsOneWidget);

    // Tap Catat Transaksi button
    await tester.tap(find.text('Catat Transaksi'));
    await tester.pumpAndSettle();

    // Verify navigated to AddTransactionScreen
    expect(find.byType(AddTransactionScreen), findsOneWidget);
  });

  testWidgets('Calendar directly opens sheet on date tap without bottom summary pill', (tester) async {
    final provider = TransactionProvider();
    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month, 15, 10, 0);

    await provider.addTransaction(
      title: 'Bensin Motor',
      amount: 40000.0,
      type: TransactionType.expense,
      categoryName: 'Transportasi',
      categoryId: 'c_transport',
      walletId: 'w_bank',
      date: targetDate,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<TransactionProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpendingCalendarCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify calendar renders and does NOT render bottom summary pill
    expect(find.byType(SpendingCalendarCard), findsOneWidget);
    expect(find.text('Rp 40.000'), findsNothing);

    // Tap date 15 directly
    final dateCellFinder = find.widgetWithText(InkWell, '15');
    await tester.tap(dateCellFinder.first);
    await tester.pumpAndSettle();

    // Verify sheet opened directly with transaction details and count label above card
    expect(find.text('Bensin Motor'), findsOneWidget);
    expect(find.text('1 Mutasi'), findsOneWidget);
    expect(find.text('- Rp 40.000'), findsNWidgets(2));
    expect(find.text('Total Pengeluaran'), findsOneWidget);
  });
}
