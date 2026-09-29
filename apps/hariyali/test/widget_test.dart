import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hariyali/logic.dart';
import 'package:hariyali/main.dart';
import 'package:hariyali/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs the app on a typical phone screen (360 x 800).
Future<HariyaliStore> startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final store = HariyaliStore();
  await store.load();
  await tester.pumpWidget(HariyaliApp(store: store));
  await tester.pumpAndSettle();
  return store;
}

Future<void> scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

Future<void> closeSheets(WidgetTester tester, Finder inside) async {
  Navigator.of(tester.element(inside)).pop();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding, sample data, every tab and the main sheets render', (tester) async {
    final store = await startApp(tester);

    expect(find.text('Hariyali'), findsOneWidget);
    await scrollTo(tester, find.text('Explore with sample data'));
    await tester.tap(find.text('Explore with sample data'));
    await tester.pumpAndSettle();
    expect(find.text('2 plants to water today'), findsOneWidget);

    for (final label in ['Plants', 'Guide', 'Away', 'You', 'Today']) {
      await tapTab(tester, label);
    }
    expect(tester.takeException(), isNull);

    // Water the tulsi after a soil check.
    await tester.tap(find.byKey(const Key('water-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('soil-dry')), findsOneWidget);
    await tester.tap(find.byKey(const Key('soil-dry')));
    await tester.pumpAndSettle();
    expect(store.data!.plant(1)!.last, todayIso());
    expect(find.text('1 plant to water today'), findsOneWidget);

    // Manual weather: turning rain off brings the open-balcony plants back.
    await tester.tap(find.byKey(const Key('rain-chip')));
    await tester.pumpAndSettle();
    expect(find.text('4 plants to water today'), findsOneWidget);

    // Add a plant from the library.
    await tapTab(tester, 'Plants');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Save plant'), findsOneWidget);
    final sheet = find.byType(BottomSheet);
    await tester.tap(find.descendant(of: sheet, matching: find.widgetWithText(ChoiceChip, 'Tomato')));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Where it lives'), 'Terrace (open)');
    await tester.ensureVisible(find.text('Save plant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save plant'));
    await tester.pumpAndSettle();
    expect(store.data!.plants.length, 9);
    expect(store.data!.plants.last.speciesId, 'tomato');

    // Plant detail, then the problem finder on top of it.
    await tester.tap(find.text('Hibiscus').first);
    await tester.pumpAndSettle();
    expect(find.text('Recent care'), findsOneWidget);
    await tester.ensureVisible(find.text('Something wrong?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Something wrong?'));
    await tester.pumpAndSettle();
    expect(find.text("What's wrong?"), findsOneWidget);
    await closeSheets(tester, find.text("What's wrong?"));
    await closeSheets(tester, find.text('Recent care'));

    // Guide: library search and a diagnosis.
    await tapTab(tester, 'Guide');
    await tester.enterText(find.widgetWithText(TextField, 'Search by name'), 'pothos');
    await tester.pumpAndSettle();
    expect(find.text('Money plant'), findsOneWidget);
    await tester.tap(find.text('Money plant'));
    await tester.pumpAndSettle();
    expect(find.text('Add another Money plant'), findsOneWidget);
    await closeSheets(tester, find.text('Add another Money plant'));

    await tester.tap(find.text('Problems'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('White cottony spots'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mealybugs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mealybugs'));
    await tester.pumpAndSettle();
    expect(find.text('What to do'), findsOneWidget);
    await closeSheets(tester, find.text('What to do'));

    // Away note in Tamil.
    await tapTab(tester, 'Away');
    await tester.tap(find.text('தமிழ்'));
    await tester.pumpAndSettle();
    expect(store.data!.trip!.lang, 'ta');

    // Pet safety flags toxic plants.
    await tapTab(tester, 'You');
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(store.data!.pets, isTrue);
    await tapTab(tester, 'Plants');
    expect(find.text('Not pet-safe'), findsWidgets);

    expect(tester.takeException(), isNull);
  });

  testWidgets('starting a new garden and adding a custom plant', (tester) async {
    final store = await startApp(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Rohit');
    await scrollTo(tester, find.text('Start my garden'));
    await tester.tap(find.text('Start my garden'));
    await tester.pumpAndSettle();
    expect(store.data?.ownerName, 'Rohit');
    expect(find.text('Nothing to water today'), findsOneWidget);

    await tester.tap(find.text('Add your first plant'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Fern');
    await tester.enterText(find.widgetWithText(TextField, 'Where it lives'), 'Bathroom window');
    await tester.ensureVisible(find.text('Save plant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save plant'));
    await tester.pumpAndSettle();
    expect(store.data!.plants.single.name, 'Fern');

    await tapTab(tester, 'Away');
    expect(find.text('Plan a trip'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
