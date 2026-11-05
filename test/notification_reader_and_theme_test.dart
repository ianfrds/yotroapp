import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/category_model.dart';
import 'package:money_tracker/models/notification_rule_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/dashboard_screen.dart';
import 'package:money_tracker/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp(Widget child, TransactionProvider provider) {
    return ChangeNotifierProvider<TransactionProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: provider.themeMode,
        home: Scaffold(body: child),
      ),
    );
  }

  group('Monochrome Theme & Dark/Light Mode Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Default theme is dark mode', () {
      final provider = TransactionProvider();
      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(provider.isDarkMode, isTrue);
    });

    test('Toggle theme mode switches between dark and light', () {
      final provider = TransactionProvider();
      provider.toggleThemeMode();
      expect(provider.themeMode, equals(ThemeMode.light));
      expect(provider.isDarkMode, isFalse);

      provider.toggleThemeMode();
      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(provider.isDarkMode, isTrue);
    });

    test('ThemeMode switches and provides correct mode states', () {
      final provider = TransactionProvider();
      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(provider.isDarkMode, isTrue);

      provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, equals(ThemeMode.light));
      expect(provider.isDarkMode, isFalse);
    });

    testWidgets('Settings screen contains Mode Tampilan toggle with Sun & Moon icons without description', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildApp(const SettingsScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Mode Tampilan'), findsOneWidget);
      // No description subtitle
      expect(find.text('Mode Gelap (Monochrome Slate)'), findsNothing);
      expect(find.text('Mode Terang (Monochrome Neutral)'), findsNothing);

      // Verify sun and moon icons are present in toggle
      expect(find.byIcon(Icons.wb_sunny_rounded), findsWidgets);
      expect(find.byIcon(Icons.nightlight_round), findsWidgets);

      // Tap the sun/moon toggle
      final sunFinder = find.byIcon(Icons.wb_sunny_rounded).first;
      await tester.tap(sunFinder);
      await tester.pumpAndSettle();

      expect(provider.themeMode, equals(ThemeMode.light));
    });
  });

  group('Daily Reminder & Notification Permission Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial reminder and permission states are correct', () {
      final provider = TransactionProvider();
      expect(provider.hasNotificationPermission, isFalse);
      expect(provider.isDailyReminderEnabled, isFalse);
      expect(provider.dailyReminderTime, equals('18:00'));
      expect(provider.dailyReminderTimes, containsAll(['18:00', '19:00']));
    });

    test('Cannot enable daily reminder without notification permission', () async {
      final provider = TransactionProvider();
      expect(provider.hasNotificationPermission, isFalse);

      final success = await provider.toggleDailyReminder(true);
      expect(success, isFalse);
      expect(provider.isDailyReminderEnabled, isFalse);
    });

    test('Can enable daily reminder after permission granted', () async {
      final provider = TransactionProvider();
      await provider.requestNotificationPermission();
      expect(provider.hasNotificationPermission, isTrue);

      final success = await provider.toggleDailyReminder(true);
      expect(success, isTrue);
      expect(provider.isDailyReminderEnabled, isTrue);

      await provider.setDailyReminderTime('21:00');
      expect(provider.dailyReminderTime, equals('21:00'));
    });

    test('Daily reminder shouldShowDailyReminder respects hasTransactionToday', () async {
      final provider = TransactionProvider();
      await provider.requestNotificationPermission();
      await provider.toggleDailyReminder(true);

      // Clear transactions
      await provider.clearAllTransactions();
      expect(provider.hasTransactionToday, isFalse);
      expect(provider.shouldShowDailyReminder, isTrue);

      // Add a transaction for today
      await provider.addTransaction(
        title: 'Makan Siang',
        amount: 25000.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'Food & Beverage',
        walletId: 'w_cash',
        date: DateTime.now(),
      );

      expect(provider.hasTransactionToday, isTrue);
      expect(provider.shouldShowDailyReminder, isFalse);
    });

    testWidgets('Settings screen contains Notifikasi & Pengingat section', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await tester.pumpWidget(buildApp(const SettingsScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Notifikasi & Pengingat'), findsOneWidget);
      expect(find.text('Izin Notifikasi Sistem'), findsOneWidget);
      expect(find.text('Pengingat Transaksi Harian'), findsOneWidget);
      expect(find.text('Tes Notifikasi HP'), findsOneWidget);
    });
  });

  group('Notification Reader Business Logic & Filter Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Rejects notification when master switch is disabled', () async {
      final provider = TransactionProvider();
      provider.toggleNotificationReader(false);

      final accepted = await provider.processIncomingNotification(
        sourceApp: 'myBCA',
        message: 'Pembayaran QRIS Rp 45.000 ke Kopi Kenangan BERHASIL',
      );

      expect(accepted, isFalse);
      expect(provider.pendingNotifications, isEmpty);
    });

    test('Ignores promotional messages automatically (Anti-Promo Filter)', () async {
      final provider = TransactionProvider();

      // Promo with discount / voucher / cashback keywords
      final accepted1 = await provider.processIncomingNotification(
        sourceApp: 'GoPay',
        message: 'Dapatkan diskon 50% dan promo voucher cashback hingga Rp 25.000 hari ini!',
      );
      expect(accepted1, isFalse);
      expect(provider.pendingNotifications, isEmpty);

      final accepted2 = await provider.processIncomingNotification(
        sourceApp: 'ShopeePay',
        message: 'Klaim penawaran voucher gratis ongkir spesial untukmu sekarang!',
      );
      expect(accepted2, isFalse);
      expect(provider.pendingNotifications, isEmpty);
    });

    test('Captures valid bank transaction and queues for approval', () async {
      final provider = TransactionProvider();

      final accepted = await provider.processIncomingNotification(
        sourceApp: 'myBCA',
        message: 'Transaksi QRIS Rp 35.000 di Janji Jiwa berhasil.',
      );

      expect(accepted, isTrue);
      expect(provider.pendingNotifications.length, equals(1));

      final pending = provider.pendingNotifications.first;
      expect(pending.sourceApp, equals('myBCA'));
      expect(pending.amount, equals(35000.0));
      expect(pending.status, equals(PendingNotificationStatus.pending));
    });

    test('Approval adds expense transaction and deducts wallet balance', () async {
      final provider = TransactionProvider();
      final initialBalance = provider.totalBalance;

      await provider.processIncomingNotification(
        sourceApp: 'myBCA',
        message: 'Transfer Berhasil Rp 50.000 ke Warung Nasi',
      );

      expect(provider.pendingNotifications.length, equals(1));
      final notifId = provider.pendingNotifications.first.id;

      await provider.approveNotification(notifId);

      // Notification is cleared from pending
      expect(provider.pendingNotifications, isEmpty);

      // Transaction added
      final latestTx = provider.transactions.first;
      expect(latestTx.amount, equals(50000.0));
      expect(latestTx.type, equals(TransactionType.expense));
      expect(provider.totalBalance, equals(initialBalance - 50000.0));
    });

    test('Reject notification discards it without modifying balance', () async {
      final provider = TransactionProvider();
      final initialBalance = provider.totalBalance;

      await provider.processIncomingNotification(
        sourceApp: 'Livin Mandiri',
        message: 'Pembayaran Debit Rp 75.000 di Superindo berhasil',
      );

      expect(provider.pendingNotifications.length, equals(1));
      final notifId = provider.pendingNotifications.first.id;

      await provider.rejectNotification(notifId);

      expect(provider.pendingNotifications, isEmpty);
      expect(provider.totalBalance, equals(initialBalance));
    });

    test('Rule management: add, toggle, and delete rules', () {
      final provider = TransactionProvider();
      final initialCount = provider.notificationRules.length;

      final newRule = NotificationRule(
        id: 'rule_custom',
        appName: 'Jenius',
        icon: Icons.credit_card_outlined,
        triggerKeywords: ['m-Card', 'berhasil'],
        ignoreKeywords: ['promo'],
        defaultWalletName: 'Dompet Utama',
        defaultCategoryName: 'Shopping',
        isEnabled: true,
      );

      provider.addNotificationRule(newRule);
      expect(provider.notificationRules.length, equals(initialCount + 1));

      final updatedRule = newRule.copyWith(isEnabled: false);
      provider.updateNotificationRule(updatedRule);
      expect(provider.notificationRules.firstWhere((r) => r.id == 'rule_custom').isEnabled, isFalse);

      provider.deleteNotificationRule('rule_custom');
      expect(provider.notificationRules.length, equals(initialCount));
    });
  });

  group('Dashboard Notification Card & UI Approval Integration', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Dashboard displays pending notification approval card and allows approval', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();

      // Trigger a notification
      await provider.processIncomingNotification(
        sourceApp: 'myBCA',
        message: 'Pembayaran QRIS Rp 28.000 di Fore Coffee Sukses',
      );

      await tester.pumpWidget(buildApp(const DashboardScreen(), provider));
      await tester.pumpAndSettle();

      // Card header should appear
      expect(find.text('Persetujuan Notifikasi'), findsOneWidget);
      expect(find.text('1 Menunggu'), findsOneWidget);
      expect(find.text('Setujui & Catat'), findsOneWidget);
      expect(find.text('Abaikan'), findsOneWidget);

      // Tap 'Setujui & Catat'
      await tester.tap(find.text('Setujui & Catat'));
      await tester.pumpAndSettle();

      // Notification card should disappear
      expect(find.text('Persetujuan Notifikasi'), findsNothing);
      expect(provider.pendingNotifications, isEmpty);
    });

    test('Pending notification approval is handled cleanly in provider', () async {
      final provider = TransactionProvider();
      await provider.processIncomingNotification(
        sourceApp: 'myBCA',
        message: 'myBCA: QRIS Rp 45.000',
      );
      expect(provider.pendingNotifications.length, equals(1));

      final id = provider.pendingNotifications.first.id;
      await provider.rejectNotification(id);
      expect(provider.pendingNotifications, isEmpty);
    });
  });
}
