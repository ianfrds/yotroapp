import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_tracker/providers/transaction_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TransactionProvider Balance States', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial states: isBalanceVisible is true, hideBalanceSection is false, dashboardViewMode is complete', () {
      final provider = TransactionProvider();
      expect(provider.isBalanceVisible, isTrue);
      expect(provider.hideBalanceSection, isFalse);
      expect(provider.showBalanceSection, isTrue);
      expect(provider.dashboardViewMode, equals(DashboardViewMode.complete));
    });

    test('setDashboardViewMode switches between complete, incomeExpense, and expenseOnly', () {
      final provider = TransactionProvider();
      provider.setDashboardViewMode(DashboardViewMode.incomeExpense);
      expect(provider.dashboardViewMode, equals(DashboardViewMode.incomeExpense));
      expect(provider.hideBalanceSection, isTrue);
      expect(provider.showBalanceSection, isFalse);

      provider.setDashboardViewMode(DashboardViewMode.expenseOnly);
      expect(provider.dashboardViewMode, equals(DashboardViewMode.expenseOnly));
      expect(provider.hideBalanceSection, isTrue);
      expect(provider.showBalanceSection, isFalse);

      provider.setDashboardViewMode(DashboardViewMode.complete);
      expect(provider.dashboardViewMode, equals(DashboardViewMode.complete));
      expect(provider.hideBalanceSection, isFalse);
      expect(provider.showBalanceSection, isTrue);
    });

    test('toggleBalanceVisibility only toggles isBalanceVisible', () {
      final provider = TransactionProvider();
      provider.toggleBalanceVisibility();
      expect(provider.isBalanceVisible, isFalse);
      expect(provider.hideBalanceSection, isFalse);

      provider.toggleBalanceVisibility();
      expect(provider.isBalanceVisible, isTrue);
      expect(provider.hideBalanceSection, isFalse);
    });

    test('setHideBalanceSection toggles hideBalanceSection and showBalanceSection', () {
      final provider = TransactionProvider();
      provider.setHideBalanceSection(true);
      expect(provider.hideBalanceSection, isTrue);
      expect(provider.showBalanceSection, isFalse);
      expect(provider.isBalanceVisible, isTrue);

      provider.setHideBalanceSection(false);
      expect(provider.hideBalanceSection, isFalse);
      expect(provider.showBalanceSection, isTrue);
      expect(provider.isBalanceVisible, isTrue);
    });
  });
}
