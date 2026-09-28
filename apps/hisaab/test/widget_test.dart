import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/main.dart';
import 'package:hisaab/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs the app on a typical phone screen (360 x 800).
Future<HisaabStore> startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final store = HisaabStore();
  await store.load();
  await tester.pumpWidget(HisaabApp(store: store));
  await tester.pumpAndSettle();
  return store;
}

Future<void> scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding, sample data and every tab render', (tester) async {
    await startApp(tester);

    expect(find.text('Hisaab'), findsOneWidget);
    await scrollTo(tester, find.text('Explore with sample data'));
    await tester.tap(find.text('Explore with sample data'));
    await tester.pumpAndSettle();
    expect(find.text('Flat 3B'), findsOneWidget);

    for (final label in ['Expenses', 'List', 'Chores', 'Balances', 'Home']) {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Save expense'), findsOneWidget);
    await tester.tap(find.text('Exact'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shares'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Save expense'))).pop(); // close the sheet
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Flat settings'));
    await tester.pumpAndSettle();
    expect(find.text('Add flatmate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creating a flat saves members', (tester) async {
    final store = await startApp(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Flat name'), 'Flat 7');
    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Umesh');
    await scrollTo(tester, find.widgetWithText(TextField, 'Name 1'));
    await tester.enterText(find.widgetWithText(TextField, 'Name 1'), 'Ravi');
    await scrollTo(tester, find.text('Create flat'));
    await tester.tap(find.text('Create flat'));
    await tester.pumpAndSettle();

    expect(store.data?.members.length, 2);
    expect(find.text('Flat 7'), findsOneWidget);
  });
}
