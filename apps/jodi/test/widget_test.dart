import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jodi/logic.dart';
import 'package:jodi/main.dart';
import 'package:jodi/screens/partner.dart';
import 'package:jodi/screens/progress.dart';
import 'package:jodi/screens/you.dart';
import 'package:jodi/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs the app on a typical phone screen (360 x 800).
Future<JodiStore> startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final store = JodiStore();
  await store.load();
  await tester.pumpWidget(JodiApp(store: store));
  await tester.pumpAndSettle();
  return store;
}

Future<void> scrollTo(WidgetTester tester, Finder f, {Type? inScreen}) async {
  // IndexedStack keeps every tab in the tree, so pick the list of the visible screen.
  final scrollable = inScreen == null
      ? find.byType(Scrollable).first
      : find.descendant(of: find.byType(inScreen), matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(f, 200, scrollable: scrollable);
  await tester.pumpAndSettle();
}

Finder inScreen(Type screen, Finder f) => find.descendant(of: find.byType(screen), matching: f);

Future<void> goTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

Future<void> closeSheet(WidgetTester tester, Finder inside) async {
  Navigator.of(tester.element(inside)).pop();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding, sample data, every tab and the main sheets render', (tester) async {
    final store = await startApp(tester);

    await scrollTo(tester, find.text('Explore with sample data'));
    await tester.tap(find.text('Explore with sample data'));
    await tester.pumpAndSettle();
    expect(store.data?.meName, 'Ishaan');
    expect(find.byType(NavigationBar), findsOneWidget);

    for (final label in ['Tara', 'Progress', 'You', 'Today']) {
      await goTab(tester, label);
    }
    expect(tester.takeException(), isNull);

    // New habit sheet from the FAB, filled in and saved.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Start habit'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'I will'), 'Floss');
    await tester.enterText(find.widgetWithText(TextField, 'After I (an existing routine)'), 'brush my teeth at night');
    await tester.pumpAndSettle();
    expect(find.text('After I brush my teeth at night, I will floss.'), findsOneWidget);
    await tester.ensureVisible(find.text('Start habit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start habit'));
    await tester.pumpAndSettle();
    expect(store.data!.habits.any((h) => h.name == 'Floss' && h.cue == 'After I brush my teeth at night'), isTrue);

    // Check in on "Read 20 pages".
    await tester.ensureVisible(find.byKey(const ValueKey('tick-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tick-1')));
    await tester.pumpAndSettle();
    expect(find.text('How hard was it today?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Finished chapter 4');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Check in'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Check in'));
    await tester.pumpAndSettle();
    expect(store.data!.habit(1)!.log[todayIso()]?.note, 'Finished chapter 4');
    expect(tester.takeException(), isNull);

    // Habit detail from the Progress tab.
    await goTab(tester, 'Progress');
    await tester.tap(inScreen(ProgressScreen, find.text('Read 20 pages')));
    await tester.pumpAndSettle();
    expect(find.text('Recent check-ins'), findsOneWidget);
    await closeSheet(tester, find.text('Recent check-ins'));

    // Partner tab: react, and open the Sunday check-in.
    await goTab(tester, 'Tara');
    // Feed items are built lazily: scroll the partner list until Tara's first event is built.
    final fire = find.byKey(const ValueKey('react-501-🔥'));
    await scrollTo(tester, fire, inScreen: PartnerScreen);
    await tester.tap(fire);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Answer this week’s questions'), inScreen: PartnerScreen);
    await tester.tap(find.text('Answer this week’s questions'));
    await tester.pumpAndSettle();
    expect(find.text('Save answers'), findsOneWidget);
    await closeSheet(tester, find.text('Save answers'));

    // You tab: find a partner and edit the pact.
    await goTab(tester, 'You');
    await scrollTo(tester, find.text('Find a partner'), inScreen: YouScreen);
    await tester.tap(find.text('Find a partner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ask to pair up').first);
    await tester.pumpAndSettle();
    expect(store.data!.feed.firstWhere((e) => e.id == 501).react, '🔥');
    expect(store.data!.matchRequests, contains('Meera'));
    await closeSheet(tester, find.text('Kabir'));

    // The profile header is at the top of the You list; scroll back up to it.
    await tester.scrollUntilVisible(
      find.byTooltip('Edit names and pact'),
      -200,
      scrollable: inScreen(YouScreen, find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit names and pact'));
    await tester.pumpAndSettle();
    expect(find.text('Target for the week'), findsOneWidget);
    await closeSheet(tester, find.text('Target for the week'));

    await goTab(tester, 'Today');
    await tester.pump(const Duration(seconds: 5)); // let toasts time out
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('starting as a pair saves both names', (tester) async {
    final store = await startApp(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Umesh');
    await scrollTo(tester, find.widgetWithText(TextField, 'Partner’s name'));
    await tester.enterText(find.widgetWithText(TextField, 'Partner’s name'), 'Ravi');
    await scrollTo(tester, find.text('Start as a pair'));
    await tester.tap(find.text('Start as a pair'));
    await tester.pumpAndSettle();

    expect(store.data?.meName, 'Umesh');
    expect(store.data?.partnerName, 'Ravi');
    expect(find.text('Start with one small habit'), findsOneWidget);
    for (final label in ['Ravi', 'Progress', 'You', 'Today']) {
      await goTab(tester, label);
    }

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('For Ravi'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Ravi will'), 'Walk 8,000 steps');
    await tester.ensureVisible(find.text('Start habit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start habit'));
    await tester.pumpAndSettle();
    expect(store.data!.habitsOf(them).length, 1);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
