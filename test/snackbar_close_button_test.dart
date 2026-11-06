import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/widgets/app_snackbar.dart';

void main() {
  testWidgets('AppSnackBar displays close X button and tapping it hides snackbar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppSnackBar.show(
                  context,
                  'Testing snackbar with close button',
                  type: SnackBarType.success,
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );

    // Tap to show snackbar
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    // Verify snackbar content and close button
    expect(find.text('Testing snackbar with close button'), findsOneWidget);
    expect(find.byKey(const Key('btn_close_snackbar')), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Tap the close button
    await tester.tap(find.byKey(const Key('btn_close_snackbar')));
    await tester.pumpAndSettle();

    // Verify snackbar is dismissed
    expect(find.text('Testing snackbar with close button'), findsNothing);
  });
}

