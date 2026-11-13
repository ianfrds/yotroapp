import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/models/changelog_model.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/screens/settings_screen.dart';
import 'package:money_tracker/services/app_update_service.dart';
import 'package:money_tracker/widgets/app_update_dialog.dart';

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
        home: Scaffold(body: child),
      ),
    );
  }

  group('ChangelogModel & Semantic Versioning Tests', () {
    test('ChangelogData history contains accurate metadata', () {
      expect(ChangelogData.currentVersion, '2.0.0');
      expect(ChangelogData.history, isNotEmpty);

      final current = ChangelogData.history.first;
      expect(current.version, '2.0.0');
      expect(current.isCurrent, isTrue);
      expect(current.features, isNotEmpty);
      expect(current.improvements, isNotEmpty);

      // Verify past versions exist
      final versions = ChangelogData.history.map((e) => e.version).toList();
      expect(versions, contains('2.0.0'));
      expect(versions, contains('1.0.6'));
      expect(versions, contains('1.0.5'));
      expect(versions, contains('1.0.0'));
    });

    test('AppUpdateService.isNewerVersion compares semver accurately', () {
      // Newer versions
      expect(AppUpdateService.isNewerVersion('2.0.1', '2.0.0'), isTrue);
      expect(AppUpdateService.isNewerVersion('v2.1.0', '2.0.0'), isTrue);
      expect(AppUpdateService.isNewerVersion('v3.0.0', '2.0.0'), isTrue);
      expect(AppUpdateService.isNewerVersion('2.0.0.1', '2.0.0'), isTrue);

      // Same or older versions
      expect(AppUpdateService.isNewerVersion('2.0.0', '2.0.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('v2.0.0', '2.0.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('v2.0.0+2', '2.0.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('1.0.6', '2.0.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('1.9.9', '2.0.0'), isFalse);
    });
  });

  group('SettingsScreen Changelog & OTA Update UI Tests', () {
    testWidgets('Renders Periksa Pembaruan and Catatan Rilis rows in SettingsScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = TransactionProvider();
      await provider.loadData();

      await tester.pumpWidget(buildTestWidget(
        child: const SettingsScreen(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      final checkUpdateRow = find.text('Periksa Pembaruan');
      final changelogRow = find.text('Catatan Rilis (Changelog)');

      await tester.scrollUntilVisible(checkUpdateRow, 300);
      await tester.pumpAndSettle();

      expect(checkUpdateRow, findsOneWidget);
      expect(changelogRow, findsOneWidget);
      expect(find.textContaining('Versi terpasang v2.0.0'), findsOneWidget);

      // Tap Catatan Rilis to open sheet
      await tester.tap(changelogRow);
      await tester.pumpAndSettle();

      expect(find.text('Catatan Rilis (Changelog)'), findsNWidgets(2)); // row + sheet title
      expect(find.text('Versi Terpasang'), findsOneWidget);
      expect(find.text('v2.0.0'), findsOneWidget);

      final v105 = find.text('v1.0.5');
      await tester.scrollUntilVisible(v105, 100, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
      expect(v105, findsOneWidget);
    });

    testWidgets('AppUpdateDialog renders release info, changelog, and action buttons', (tester) async {
      const releaseInfo = ReleaseInfo(
        tagName: 'v2.0.1',
        version: '2.0.1',
        body: 'Fitur baru dan perbaikan stabilitas transaksi.',
        apkUrl: 'https://github.com/ianfrds/yotroapp/releases/download/v2.0.1/yotro-app.apk',
        apkSize: 38200000,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppUpdateDialog(
              releaseInfo: releaseInfo,
              currentVersion: '2.0.0',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pembaruan Tersedia'), findsOneWidget);
      expect(find.textContaining('v2.0.1'), findsOneWidget);
      expect(find.text('Catatan Pembaruan:'), findsOneWidget);
      expect(find.textContaining('Fitur baru dan perbaikan stabilitas'), findsOneWidget);
      expect(find.text('Perbarui Sekarang'), findsOneWidget);
      expect(find.text('Nanti Saja'), findsOneWidget);

      // Tap Nanti Saja closes dialog
      await tester.tap(find.text('Nanti Saja'));
      await tester.pumpAndSettle();
    });
  });
}
