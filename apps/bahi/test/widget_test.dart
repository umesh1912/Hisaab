import 'package:bahi/main.dart';
import 'package:bahi/logic.dart';
import 'package:bahi/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs the app on a typical phone screen (360 x 800).
Future<BahiStore> startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final store = BahiStore();
  await store.load();
  await tester.pumpWidget(BahiApp(store: store));
  await tester.pumpAndSettle();
  return store;
}

Finder key(String k) => find.byKey(ValueKey(k));

/// Scrolls [f] into view and taps it. Waits out any snack bar first so it can't cover the target.
Future<void> tapIt(WidgetTester tester, Finder f) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> closeSheet(WidgetTester tester, Finder inside) async {
  Navigator.of(tester.element(inside)).pop();
  await tester.pumpAndSettle();
}

Future<void> visitTabs(WidgetTester tester) async {
  for (final k in ['nav-today', 'nav-collect', 'nav-report', 'nav-khata']) {
    await tester.tap(key(k));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('sample data, every tab and the main sheets render', (tester) async {
    final store = await startApp(tester);

    expect(find.text('बही'), findsOneWidget);
    await tapIt(tester, key('onb-sample'));
    expect(store.data, isNotNull);
    expect(key('quick'), findsOneWidget);

    await visitTabs(tester);
    expect(tester.takeException(), isNull);

    // Typed / spoken entry: pick an example and save it.
    await tapIt(tester, key('quick'));
    await tapIt(tester, key('example-0'));
    expect(key('quick-save'), findsOneWidget);
    await tapIt(tester, key('quick-save'));
    expect(balanceOf(store.data!.customer(1)!), 184000 + 34000);

    // Numpad sheet: type an amount, try to save without a customer.
    await tapIt(tester, key('gave'));
    for (final k in ['key-1', 'key-2', 'key-0', 'key-del', 'key-00']) {
      await tapIt(tester, key(k));
    }
    await tapIt(tester, key('entry-save'));
    expect(find.text('ग्राहक चुनें।'), findsOneWidget);
    await closeSheet(tester, key('entry-save'));

    await tapIt(tester, key('got'));
    await closeSheet(tester, key('entry-save'));

    // A customer's khata.
    await tapIt(tester, key('cust-2'));
    expect(key('remind-one'), findsOneWidget);
    await closeSheet(tester, key('remind-one'));

    // New customer form.
    await tester.scrollUntilVisible(key('new-customer'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tapIt(tester, key('new-customer'));
    await tester.enterText(key('cf-name'), 'Deepak Electrician');
    await tester.enterText(key('cf-phone'), '98260 77341');
    await tapIt(tester, key('cf-save'));
    expect(store.data!.customers.length, 9);

    // Collections: tick one customer and open the reminder sheet.
    await tester.tap(key('nav-collect'));
    await tester.pumpAndSettle();
    await tapIt(tester, key('collect-2'));
    await tapIt(tester, key('remind-selected'));
    expect(find.text('याद दिलाएँ'), findsOneWidget);
    await closeSheet(tester, find.text('याद दिलाएँ'));

    // Today: write the counter sales.
    await tester.tap(key('nav-today'));
    await tester.pumpAndSettle();
    await tapIt(tester, key('update-sales'));
    await tester.enterText(key('sales-cash'), '1000');
    await tester.enterText(key('sales-upi'), '500.50');
    await tapIt(tester, key('sales-save'));
    expect(store.data!.sales[todayIso()]!.total, 150050);

    // Settings.
    await tester.tap(find.byTooltip('सेटिंग'));
    await tester.pumpAndSettle();
    expect(find.text('जानकारी सेव करें'), findsOneWidget);
    await closeSheet(tester, find.text('जानकारी सेव करें'));

    // Switch to English and visit everything again.
    await tester.tap(key('lang'));
    await tester.pumpAndSettle();
    expect(find.text('Bahi'), findsOneWidget);
    await visitTabs(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    await tapIt(tester, key('quick'));
    await closeSheet(tester, key('quick-text'));

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('setting up a shop starts an empty khata', (tester) async {
    final store = await startApp(tester);

    await tester.enterText(key('onb-shop'), 'Sharma Kirana');
    await tester.enterText(key('onb-upi'), 'sharma@okicici');
    await tapIt(tester, key('onb-start'));

    expect(store.data?.shop.name, 'Sharma Kirana');
    expect(store.data?.customers, isEmpty);
    expect(find.text('Sharma Kirana'), findsOneWidget);
    await visitTabs(tester);
    expect(tester.takeException(), isNull);
  });
}
