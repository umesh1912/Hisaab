import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rasid/main.dart';
import 'package:rasid/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs the app on a typical phone screen (360 x 800).
Future<RasidStore> startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final store = RasidStore();
  await store.load();
  await tester.pumpWidget(RasidApp(store: store));
  await tester.pumpAndSettle();
  return store;
}

Future<void> scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> closeSheet(WidgetTester tester, Finder inside) async {
  Navigator.of(tester.element(inside)).pop();
  await tester.pumpAndSettle();
}

Future<void> goTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding, sample data, every tab and the main sheets render', (tester) async {
    await startApp(tester);

    expect(find.text('Rasid'), findsOneWidget);
    await scrollTo(tester, find.text('Explore with sample data'));
    await tester.tap(find.text('Explore with sample data'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Flat 204, Kondapur'), findsWidgets);

    for (final label in ['Vault', 'Claims', 'Reminders', 'You', 'Home']) {
      await goTab(tester, label);
    }
    expect(tester.takeException(), isNull);

    // Add a bill, with the paste reader.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Save to vault'), findsOneWidget);
    await tester.tap(find.text('Paste bill or order email text'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('paste-box')), 'CROMA\nInvoice No: CRM/1/22\nDate: 14/03/2025\nLG Air Conditioner  41,990.00\nTotal: 41,990.00');
    await tester.tap(find.text('Read the text'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Check the fields marked below'), findsOneWidget);
    await closeSheet(tester, find.text('Save to vault'));

    // Item details, then a new claim from it.
    await tester.tap(find.text('Prestige Mixer grinder').first);
    await tester.pumpAndSettle();
    expect(find.text('Remove from vault'), findsOneWidget);
    await tapVisible(tester, find.text("Something's wrong: start a claim"));
    expect(find.text('Proof checklist'), findsOneWidget);
    await closeSheet(tester, find.text('Proof checklist'));
    await closeSheet(tester, find.text('Remove from vault'));
    expect(tester.takeException(), isNull);

    // Claims: update and escalate.
    await goTab(tester, 'Claims');
    await tapVisible(tester, find.text('Update status'));
    expect(find.text('Or add what happened'), findsOneWidget);
    await closeSheet(tester, find.text('Or add what happened'));
    await tapVisible(tester, find.text("It's taking too long"));
    expect(find.text('Escalate this claim'), findsOneWidget);
    await closeSheet(tester, find.text('Escalate this claim'));

    // Reminders: add a service reminder.
    await goTab(tester, 'Reminders');
    final remindersList = find
        .ancestor(of: find.textContaining('Warranty end dates and service dates'), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.byIcon(Icons.add_alarm), 200, scrollable: remindersList);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_alarm));
    await tester.pumpAndSettle();
    expect(find.text('Save reminder'), findsOneWidget);
    await closeSheet(tester, find.text('Save reminder'));

    // You: profile sheet.
    await goTab(tester, 'You');
    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);
    await closeSheet(tester, find.text('Your profile'));

    // Alerts under the bell.
    await tester.tap(find.byTooltip('Alerts'));
    await tester.pumpAndSettle();
    expect(find.text('See all reminders'), findsOneWidget);
    await tester.tap(find.text('See all reminders'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('creating a vault and saving a bill', (tester) async {
    final store = await startApp(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Umesh');
    await scrollTo(tester, find.text('Create my vault'));
    await tester.tap(find.text('Create my vault'));
    await tester.pumpAndSettle();

    expect(store.data?.members.length, 1);
    expect(find.text('Your vault is empty'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Brand'), 'Philips');
    await tester.enterText(find.widgetWithText(TextField, 'Item'), 'Air fryer');
    await tester.enterText(find.widgetWithText(TextField, 'Price (₹)'), '8999');
    await tapVisible(tester, find.text('Save to vault'));

    expect(store.data?.items.length, 1);
    expect(store.data?.items.first.price, 899900);
    expect(store.data?.reminders.length, 1);
    expect(store.tab, 1);

    // Let the confirmation snackbar time out so no timers are left.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
