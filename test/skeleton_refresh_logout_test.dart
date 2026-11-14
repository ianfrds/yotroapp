import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/settings_screen.dart';
import 'package:money_tracker/screens/dashboard_screen.dart';
import 'package:money_tracker/widgets/app_skeleton.dart';

Widget buildTestApp(Widget child, TransactionProvider provider) {
  return ChangeNotifierProvider<TransactionProvider>.value(
    value: provider,
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('AppSkeleton Widgets Test', () {
    testWidgets('AppSkeleton components render without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SkeletonHeroCard(),
                  SkeletonTransactionList(count: 3),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonHeroCard), findsOneWidget);
      expect(find.byType(SkeletonTransactionList), findsOneWidget);
      expect(find.byType(SkeletonTransactionTile), findsNWidgets(3));
    });
  });

  group('Pull-to-Refresh & Provider refreshData() Test', () {
    test('TransactionProvider.refreshData() completes cleanly', () async {
      final provider = TransactionProvider();
      await provider.loadData();
      expect(provider.isLoading, isFalse);

      final refreshFuture = provider.refreshData();
      expect(provider.isLoading, isTrue);

      await refreshFuture;
      expect(provider.isLoading, isFalse);
    });

    testWidgets('DashboardScreen has RefreshIndicator with AlwaysScrollableScrollPhysics',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      await tester.pumpWidget(buildTestApp(const DashboardScreen(), provider));
      await tester.pumpAndSettle();

      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);

      final listView = tester.widget<ListView>(find.byType(ListView).first);
      expect(listView.physics, isA<AlwaysScrollableScrollPhysics>());
    });
  });

  group('SettingsScreen Logout & Cloud Sync Card Tests', () {
    testWidgets(
        'Cloud sync card does not have "Keluar" button; Bottom has "Keluar dari Akun" button',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      await tester.pumpWidget(buildTestApp(const SettingsScreen(), provider));
      await tester.pumpAndSettle();

      // In Cloud Sync Card, "Keluar" button must NOT exist
      expect(find.text('Keluar'), findsNothing);

      // At bottom of SettingsScreen, "Keluar dari Akun" button must exist
      final logoutButton = find.text('Keluar dari Akun');
      await tester.scrollUntilVisible(logoutButton, 200);
      await tester.pumpAndSettle();
      expect(logoutButton, findsOneWidget);

      // Tapping "Keluar dari Akun" shows the confirmation sheet
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari Akun?'), findsOneWidget);
      expect(find.text('Ya, Keluar'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Tapping Batal dismisses the sheet
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Keluar dari Akun?'), findsNothing);
    });
  });
}
