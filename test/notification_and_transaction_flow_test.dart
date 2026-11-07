import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/notification_rule_model.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/models/wallet_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/add_transaction_screen.dart';
import 'package:money_tracker/screens/dashboard_screen.dart';
import 'package:money_tracker/screens/notifications_center_screen.dart';
import 'package:money_tracker/screens/transaction_success_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget buildTestApp(Widget child, TransactionProvider provider) {
  return ChangeNotifierProvider<TransactionProvider>.value(
    value: provider,
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Transaction Success Screen Tests', () {
    testWidgets('renders full animated success screen with transaction details', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool homeTapped = false;
      bool addAnotherTapped = false;

      final tx = TransactionModel(
        id: 'tx_success_1',
        title: 'Makan Siang SeaBank',
        amount: 35000.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'Food & Beverage',
        walletId: 'w_bank',
        timestamp: DateTime(2026, 11, 4, 12, 30),
      );

      await tester.pumpWidget(MaterialApp(
        home: TransactionSuccessScreen(
          transaction: tx,
          onBackToHome: () => homeTapped = true,
          onAddAnother: () => addAnotherTapped = true,
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Transaksi Berhasil Dicatat'), findsOneWidget);
      expect(find.text('- Rp 35.000'), findsOneWidget);
      expect(find.text('Makan Siang SeaBank'), findsOneWidget);
      expect(find.text('Food & Beverage'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
      expect(find.text('Catat Transaksi Lain'), findsOneWidget);

      await tester.tap(find.text('Kembali ke Beranda'));
      expect(homeTapped, isTrue);

      await tester.tap(find.text('Catat Transaksi Lain'));
      expect(addAnotherTapped, isTrue);
    });

    testWidgets('TransactionSuccessScreen auto redirects to home after 5 seconds', (tester) async {
      bool homeRedirected = false;

      final tx = TransactionModel(
        id: 'tx_success_auto',
        title: 'Beli Bensin',
        amount: 50000.0,
        type: TransactionType.expense,
        categoryId: 'transport',
        categoryName: 'Transportasi',
        walletId: 'w_cash',
        timestamp: DateTime(2026, 11, 4, 14, 0),
      );

      await tester.pumpWidget(MaterialApp(
        home: TransactionSuccessScreen(
          transaction: tx,
          onBackToHome: () => homeRedirected = true,
        ),
      ));

      // Pump animation frames
      await tester.pump(const Duration(milliseconds: 1000));
      expect(homeRedirected, isFalse);

      // Advance 5 seconds
      await tester.pump(const Duration(seconds: 5));
      expect(homeRedirected, isTrue);
    });

    testWidgets('TransactionSuccessScreen strictly respects anti-slop font semibold constraint', (tester) async {
      final tx = TransactionModel(
        id: 'tx_success_font',
        title: 'Uji Font',
        amount: 25000.0,
        type: TransactionType.expense,
        categoryId: 'other',
        categoryName: 'Lainnya',
        walletId: 'w_cash',
        timestamp: DateTime(2026, 11, 4, 15, 0),
      );

      await tester.pumpWidget(MaterialApp(
        home: TransactionSuccessScreen(transaction: tx),
      ));
      await tester.pumpAndSettle();

      // Ensure no bold (w700, w800, w900, bold) texts exist
      final allTexts = tester.widgetList<Text>(find.byType(Text));
      for (final text in allTexts) {
        if (text.style != null && text.style!.fontWeight != null) {
          expect(
            text.style!.fontWeight!.index <= FontWeight.w600.index,
            isTrue,
            reason: 'Text "${text.data}" should not exceed semibold (w600), but was ${text.style!.fontWeight}',
          );
        }
      }
    });
  });

  group('Delete Transaction Confirmation Dialog Tests', () {
    testWidgets('cancelling dialog preserves transaction and balance', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();
      await provider.clearAllTransactions();
      final wallet = provider.wallets.first;
      final initialBalance = wallet.balance;

      final tx = await provider.addTransaction(
        title: 'Beli Kopi',
        amount: 25000.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'Food & Beverage',
        walletId: wallet.id,
      );

      expect(provider.transactions.length, equals(1));
      expect(wallet.balance, equals(initialBalance - 25000.0));

      await tester.pumpWidget(buildTestApp(
        AddTransactionScreen(initialTransaction: tx),
        provider,
      ));
      await tester.pumpAndSettle();

      // Tap bottom 'Hapus'
      final deleteBtn = find.byKey(const Key('btn_delete_transaction'));
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Confirmation bottom sheet must appear
      expect(find.text('Hapus Transaksi'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.byKey(const Key('btn_confirm_delete_modal')), findsOneWidget);

      // Tap Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Modal dismissed, transaction remains
      expect(find.text('Hapus Transaksi'), findsNothing);
      expect(provider.transactions.length, equals(1));
      expect(wallet.balance, equals(initialBalance - 25000.0));
    });

    testWidgets('confirming dialog deletes transaction and restores wallet balance', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();
      await provider.clearAllTransactions();
      final wallet = provider.wallets.first;
      final initialBalance = wallet.balance;

      final tx = await provider.addTransaction(
        title: 'Beli Pulsa SeaBank',
        amount: 50000.0,
        type: TransactionType.expense,
        categoryId: 'bills',
        categoryName: 'Bills & Utilities',
        walletId: wallet.id,
      );

      expect(provider.transactions.length, equals(1));
      expect(wallet.balance, equals(initialBalance - 50000.0));

      await tester.pumpWidget(buildTestApp(
        AddTransactionScreen(initialTransaction: tx),
        provider,
      ));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.byKey(const Key('btn_delete_transaction')));
      await tester.pumpAndSettle();

      // Tap confirm Hapus
      await tester.tap(find.byKey(const Key('btn_confirm_delete_modal')));
      await tester.pumpAndSettle();

      // Transaction is deleted, wallet balance is restored back to initial
      expect(provider.transactions, isEmpty);
      expect(wallet.balance, equals(initialBalance));
    });
  });

  group('Notifications Center & Bell Navigation Tests', () {
    testWidgets('Dashboard bell icon navigates to NotificationsCenterScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();

      await tester.pumpWidget(buildTestApp(
        const DashboardScreen(),
        provider,
      ));
      await tester.pumpAndSettle();

      // Find bell icon
      final bellFinder = find.byIcon(Icons.notifications_none_rounded);
      expect(bellFinder, findsOneWidget);

      await tester.tap(bellFinder);
      await tester.pumpAndSettle();

      // NotificationsCenterScreen is now open
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Persetujuan Transaksi'), findsNothing);
      expect(find.text('Aktivitas Transaksi'), findsOneWidget);
    });

    testWidgets('NotificationsCenterScreen displays activity history cleanly without pending approval card', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();

      // Trigger notification parse for SeaBank
      await provider.processIncomingNotification(
        sourceApp: 'SeaBank',
        packageName: 'com.seabank.id',
        message: 'Pembayaran QRIS sebesar Rp 75.000 ke Solaria telah berhasil.',
      );

      expect(provider.pendingNotifications.length, equals(1));

      await tester.pumpWidget(buildTestApp(
        const NotificationsCenterScreen(),
        provider,
      ));
      await tester.pumpAndSettle();

      // Approval section is removed
      expect(find.text('Persetujuan Transaksi'), findsNothing);
      expect(find.text('Aktivitas Transaksi'), findsOneWidget);

      // Provider approval works directly
      final pendingItem = provider.pendingNotifications.first;
      await provider.approveNotification(pendingItem.id);
      expect(provider.pendingNotifications, isEmpty);
      expect(provider.transactions.length, equals(1));
      expect(provider.transactions.first.amount, equals(75000.0));
    });
  });

  group('Real-time Banking App Notification Parser Tests', () {
    test('SeaBank real-time notification with package name parses correctly', () async {
      final provider = TransactionProvider();

      final parsed = await provider.processIncomingNotification(
        sourceApp: 'SeaBank',
        packageName: 'com.seabank.id',
        message: 'Transfer keluar sebesar Rp 150.000 ke BCA a.n. BUDI SANTOSO berhasil.',
      );

      expect(parsed, isTrue);
      expect(provider.pendingNotifications.length, equals(1));
      final item = provider.pendingNotifications.first;
      expect(item.sourceApp, equals('SeaBank'));
      expect(item.amount, equals(150000.0));
      expect(item.status, equals(PendingNotificationStatus.pending));
    });

    test('myBCA real-time notification with QRIS payment parses correctly', () async {
      final provider = TransactionProvider();

      final parsed = await provider.processIncomingNotification(
        sourceApp: 'myBCA',
        packageName: 'com.bca',
        message: 'myBCA: Pembayaran QRIS sebesar Rp 42.500 ke Kopi Kenangan sukses.',
      );

      expect(parsed, isTrue);
      expect(provider.pendingNotifications.length, equals(1));
      final item = provider.pendingNotifications.first;
      expect(item.sourceApp, equals('myBCA'));
      expect(item.amount, equals(42500.0));
    });
  });
}
