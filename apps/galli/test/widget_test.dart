import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galli/main.dart';
import 'package:galli/sheets/new_post.dart';
import 'package:galli/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs the app on a typical phone screen (360 x 800).
Future<GalliStore> startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final store = GalliStore();
  await store.load();
  await tester.pumpWidget(GalliApp(store: store));
  await tester.pumpAndSettle();
  return store;
}

Future<void> scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

Future<void> closeSheet(WidgetTester tester, Finder inside) async {
  Navigator.of(tester.element(inside)).pop();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding, sample data, every tab and the main sheets render', (tester) async {
    await startApp(tester);

    expect(find.text('Galli'), findsOneWidget);
    await scrollTo(tester, find.text('Explore with sample data'));
    await tester.tap(find.text('Explore with sample data'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Notifications'), findsOneWidget);

    for (final label in ['Map', 'Lost', 'Inbox', 'You', 'Nearby']) {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    // New post sheet, switching through every type.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('New post'), findsOneWidget);
    for (final t in ['Alert', 'Lost', 'Help needed', 'Notice', 'Found']) {
      await tester.tap(find.descendant(of: find.byType(NewPostForm), matching: find.widgetWithText(ChoiceChip, t)));
      await tester.pumpAndSettle();
    }
    await closeSheet(tester, find.text('New post'));

    // Filter the feed to lost posts and open the lost dog.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Lost'));
    await tester.pumpAndSettle();
    final bruno = find.text('Lost dog: Bruno, brown indie, red collar');
    expect(bruno, findsOneWidget);
    await tester.tap(bruno);
    await tester.pumpAndSettle();
    expect(find.text('Add sighting'), findsOneWidget);
    await closeSheet(tester, find.text('Add sighting'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();

    // Notifications.
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    await closeSheet(tester, find.text('Notifications'));

    // A conversation in the inbox.
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Inbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Bruno's owner"));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Send'), findsOneWidget);
    await closeSheet(tester, find.byTooltip('Send'));

    expect(tester.takeException(), isNull);
  });

  testWidgets('setting up and posting saves data', (tester) async {
    final store = await startApp(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Umesh');
    await tester.enterText(find.widgetWithText(TextField, 'Your locality'), 'Aundh, Pune');
    await scrollTo(tester, find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(store.data?.name, 'Umesh');
    expect(find.text('Aundh, Pune · within 1 km'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Headline'), 'Found: blue school bag near Vanaz metro');
    final post = find.text('Post to neighbours within 2 km');
    await tester.ensureVisible(post);
    await tester.pumpAndSettle();
    await tester.tap(post);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5)); // let the toast go away
    await tester.pumpAndSettle();

    expect(store.data?.posts.length, 1);
    expect(find.text('Found: blue school bag near Vanaz metro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
