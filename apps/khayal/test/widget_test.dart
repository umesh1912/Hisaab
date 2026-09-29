import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khayal/main.dart';
import 'package:khayal/screens/parent_mode.dart';
import 'package:khayal/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs the app on a typical phone screen (360 x 800).
Future<KhayalStore> startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final store = KhayalStore();
  await store.load();
  await tester.pumpWidget(KhayalApp(store: store));
  await tester.pumpAndSettle();
  return store;
}

Future<void> showIt(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
}

Future<void> closeSheet(WidgetTester tester, Finder inside) async {
  Navigator.of(tester.element(inside)).pop();
  await tester.pumpAndSettle();
}

Finder navTab(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('onboarding, sample data, every tab, sheets and parent mode render', (tester) async {
    await startApp(tester);

    expect(find.text('Khayal'), findsOneWidget);
    await showIt(tester, find.text('Explore with sample data'));
    await tester.tap(find.text('Explore with sample data'));
    await tester.pumpAndSettle();
    expect(find.text('Looking after Papa and Mummy'), findsOneWidget);

    for (final label in ['Medicines', 'Refills', 'Health', 'Family', 'Today']) {
      await tester.tap(navTab(label));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);

    // Add medicine sheet
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Add medicine'), findsOneWidget);
    await closeSheet(tester, find.text('Add medicine'));

    // Health: reading sheet and doctor summary
    await tester.tap(navTab('Health'));
    await tester.pumpAndSettle();
    await showIt(tester, find.text('Add reading'));
    await tester.tap(find.text('Add reading'));
    await tester.pumpAndSettle();
    expect(find.text('Save reading'), findsOneWidget);
    await closeSheet(tester, find.text('Save reading'));
    await showIt(tester, find.text('Doctor summary'));
    await tester.tap(find.text('Doctor summary'));
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsOneWidget);
    await closeSheet(tester, find.text('Copy'));

    // Refills: order sheet
    await tester.tap(navTab('Refills'));
    await tester.pumpAndSettle();
    await showIt(tester, find.text('Send list to chemist'));
    await tester.tap(find.text('Send list to chemist'));
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsOneWidget);
    await closeSheet(tester, find.text('Copy'));

    // Family: invite sheet
    await tester.tap(navTab('Family'));
    await tester.pumpAndSettle();
    await showIt(tester, find.text('Invite'));
    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();
    expect(find.text('Add a helper'), findsOneWidget);
    await closeSheet(tester, find.text('Add a helper'));

    // Settings sheet
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Save settings'), findsOneWidget);
    await closeSheet(tester, find.text('Save settings'));
    expect(tester.takeException(), isNull);

    // Parent's phone, in English and Hindi
    await tester.tap(find.byTooltip("Parent's phone"));
    await tester.pumpAndSettle();
    expect(find.byType(ParentModeScreen), findsOneWidget);
    await tester.tap(find.text('हिंदी'));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(ParentModeScreen))).pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('setting up and adding a medicine saves it', (tester) async {
    final store = await startApp(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Umesh');
    await showIt(tester, find.text('Start'));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(store.data?.parents.length, 2);
    expect(find.text('Looking after Papa and Mummy'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Medicine'), 'Metformin');
    await showIt(tester, find.text('Add medicine'));
    await tester.tap(find.text('Add medicine'));
    await tester.pumpAndSettle();

    expect(store.data?.meds.length, 1);
    expect(store.data?.meds.first.name, 'Metformin');
    expect(tester.takeException(), isNull);
  });
}
