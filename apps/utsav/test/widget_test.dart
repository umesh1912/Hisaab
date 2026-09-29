import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utsav/main.dart';
import 'package:utsav/store.dart';

/// Runs the app on a typical phone screen (360 x 800).
Future<UtsavStore> startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final store = UtsavStore();
  await store.load();
  await tester.pumpWidget(UtsavApp(store: store));
  await tester.pumpAndSettle();
  return store;
}

Future<void> scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

Future<void> loadSample(WidgetTester tester) async {
  await scrollTo(tester, find.text('Explore with sample data'));
  await tester.tap(find.text('Explore with sample data'));
  await tester.pumpAndSettle();
}

Future<void> goTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

/// Closes the sheet that contains [inSheet].
Future<void> closeSheet(WidgetTester tester, Finder inSheet) async {
  Navigator.of(tester.element(inSheet)).pop();
  await tester.pumpAndSettle();
}

/// Scrolls a widget into view (in a sheet or a list) and taps it.
/// Works even when the widget is in a lazy list and not built yet, above or below.
Future<void> tapVisible(WidgetTester tester, Finder f) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  bool ready() => f.hitTestable().evaluate().isNotEmpty;
  if (!ready()) {
    final scrollables = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).hitTestable();
    for (final e in scrollables.evaluate().toList().reversed) {
      if (ready()) break;
      final s = find.byElementPredicate((x) => x == e);
      for (final dy in [300.0, -150.0]) {
        for (var i = 0; i < 40 && !ready(); i++) {
          if (f.evaluate().isNotEmpty) {
            await tester.ensureVisible(f);
            await tester.pumpAndSettle();
            if (ready()) break;
          }
          await tester.drag(s, Offset(0, dy), warnIfMissed: false);
          await tester.pumpAndSettle();
        }
        if (ready()) break;
      }
    }
  }
  await tester.tap(f.hitTestable().first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding, sample data, every tab and the main sheets render', (tester) async {
    await startApp(tester);

    expect(find.text('Utsav'), findsOneWidget);
    await loadSample(tester);
    expect(find.text('Riya & Kabir'), findsOneWidget);

    for (final label in ['Guests', 'Tasks', 'Budget', 'Vendors', 'Home']) {
      await goTab(tester, label);
    }
    expect(tester.takeException(), isNull);

    // Home: new task sheet
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Add task'), findsOneWidget);
    await tester.tap(find.text('Someone new'));
    await tester.pumpAndSettle();
    await closeSheet(tester, find.text('Add task'));

    // Guests: family sheet, caterer count, reminders, rooms
    await goTab(tester, 'Guests');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Save family'), findsOneWidget);
    await closeSheet(tester, find.text('Save family'));

    await tester.tap(find.byKey(const Key('share-count')));
    await tester.pumpAndSettle();
    expect(find.text('Headcount for caterer'), findsOneWidget);
    await closeSheet(tester, find.text('Headcount for caterer'));

    await tester.tap(find.byKey(const Key('remind')));
    await tester.pumpAndSettle();
    expect(find.text('RSVP reminder'), findsOneWidget);
    await closeSheet(tester, find.text('RSVP reminder'));

    await tester.scrollUntilVisible(
      find.byKey(const Key('rooms')),
      300,
      scrollable: find.descendant(of: find.byKey(const Key('guests-list')), matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rooms')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allot rooms automatically'));
    await tester.pumpAndSettle();
    expect(find.text('Clear all rooms'), findsOneWidget);
    await closeSheet(tester, find.text('Allot rooms automatically'));

    // Budget: new category sheet
    await goTab(tester, 'Budget');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Add category'), findsOneWidget);
    await closeSheet(tester, find.text('Add category'));

    // Vendors: payment and vendor sheets
    await goTab(tester, 'Vendors');
    await tester.tap(find.text('Record payment').first);
    await tester.pumpAndSettle();
    expect(find.text('Save payment'), findsOneWidget);
    await closeSheet(tester, find.text('Save payment'));

    await tester.tap(find.text('Genda Phool Decor'));
    await tester.pumpAndSettle();
    expect(find.text('Save vendor'), findsOneWidget);
    await closeSheet(tester, find.text('Save vendor'));

    // Settings
    await tester.tap(find.byTooltip('Wedding settings'));
    await tester.pumpAndSettle();
    expect(find.text('Add helper'), findsOneWidget);
    await closeSheet(tester, find.text('Add helper'));

    expect(tester.takeException(), isNull);
  });

  testWidgets('recording a payment updates the vendor and the budget', (tester) async {
    final store = await startApp(tester);
    await loadSample(tester);
    await goTab(tester, 'Vendors');

    final d = store.data!;
    final decor = d.vendors.firstWhere((v) => v.name == 'Genda Phool Decor');
    final line = d.lineFor('Decor and flowers')!;
    final paidBefore = decor.paid, budgetBefore = line.paid;

    // Genda Phool Decor is due soonest, so it is first; the amount is prefilled.
    await tester.tap(find.text('Record payment').first);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Save payment'));

    expect(decor.paid, paidBefore + 15000000);
    expect(line.paid, budgetBefore + 15000000);
    expect(decor.payments.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding a family saves it', (tester) async {
    final store = await startApp(tester);
    await loadSample(tester);
    await goTab(tester, 'Guests');

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Family'), 'Test family');
    await tapVisible(tester, find.text('Save family'));

    expect(store.data!.guests.length, 31);
    expect(store.data!.guests.last.name, 'Test family');
    expect(tester.takeException(), isNull);
  });

  testWidgets('creating a wedding sets up functions and budget', (tester) async {
    final store = await startApp(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Bride'), 'Asha');
    await tester.enterText(find.widgetWithText(TextField, 'Groom'), 'Vikram');
    await tester.enterText(find.widgetWithText(TextField, 'City'), 'Udaipur');
    await scrollTo(tester, find.text('Start planning'));
    await tester.tap(find.text('Start planning'));
    await tester.pumpAndSettle();

    expect(store.data?.events.length, 5);
    expect(store.data?.budget.length, 8);
    expect(find.text('Asha & Vikram'), findsOneWidget);

    for (final label in ['Guests', 'Tasks', 'Budget', 'Vendors', 'Home']) {
      await goTab(tester, label);
    }
    expect(tester.takeException(), isNull);
  });
}
