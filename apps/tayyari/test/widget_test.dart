import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tayyari/main.dart';
import 'package:tayyari/store.dart';

/// Runs the app on a typical phone screen (360 x 800).
Future<TayyariStore> startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final store = TayyariStore();
  await store.load();
  await tester.pumpWidget(TayyariApp(store: store));
  await tester.pumpAndSettle();
  return store;
}

Future<void> scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

Future<void> tab(WidgetTester tester, String label) async {
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

    expect(find.text('Tayyari'), findsOneWidget);
    await scrollTo(tester, find.text('Explore with sample data'));
    await tester.tap(find.text('Explore with sample data'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('countdown')), findsOneWidget);

    for (final label in ['Practice', 'Syllabus', 'Notes', 'Progress', 'Today']) {
      await tab(tester, label);
    }
    expect(tester.takeException(), isNull);

    // Today's plan: learning block and test setup (the test itself is not started, so no timer runs).
    await tester.tap(find.byKey(const Key('plan-learn')));
    await tester.pumpAndSettle();
    expect(find.text('Mark as done'), findsOneWidget);
    await closeSheet(tester, find.text('Mark as done'));

    await tester.tap(find.byKey(const Key('plan-test')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('start-test')), findsOneWidget);
    await tester.tap(find.text('Full mock'));
    await tester.pumpAndSettle();
    await closeSheet(tester, find.byKey(const Key('start-test')));

    // A revision session: confidence, answer, feedback and rating.
    await tab(tester, 'Practice');
    await tester.tap(find.byKey(const Key('start-revision')));
    await tester.pumpAndSettle();
    expect(store.session, isNotNull);
    await tester.tap(find.byKey(const Key('sure-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opt-0')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('grade-3')));
    await tester.tap(find.byKey(const Key('grade-3')));
    await tester.pumpAndSettle();
    expect(store.session?.i, 1);

    // Hindi and back.
    await tester.tap(find.byTooltip('Switch language'));
    await tester.pumpAndSettle();
    expect(store.hindi, isTrue);
    await tester.tap(find.byTooltip('Switch language'));
    await tester.pumpAndSettle();

    store.endSession();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('start-revision')), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Syllabus week plan.
    await tab(tester, 'Syllabus');
    await tester.ensureVisible(find.byKey(const Key('plan-quant')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('plan-quant')));
    await tester.pumpAndSettle();
    expect(find.text('Add to my week'), findsOneWidget);
    await closeSheet(tester, find.text('Add to my week'));

    // Notes: add sheet and an existing note.
    await tab(tester, 'Notes');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Save note'), findsOneWidget);
    await closeSheet(tester, find.text('Save note'));
    await tester.tap(find.text('Fundamental Rights (Part III)'));
    await tester.pumpAndSettle();
    expect(find.text('Add a question'), findsOneWidget);
    await closeSheet(tester, find.text('Add a question'));

    // Progress: add mock sheet and a result screen.
    await tab(tester, 'Progress');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Save mock'), findsOneWidget);
    await closeSheet(tester, find.text('Save mock'));
    await scrollTo(tester, find.text('Mock 6'));
    await tester.tap(find.text('Mock 6'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong but felt certain'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Save profile'), findsOneWidget);
    await closeSheet(tester, find.text('Save profile'));

    expect(tester.takeException(), isNull);
  });

  testWidgets('setting up a profile adds today\'s first questions', (tester) async {
    final store = await startApp(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Umesh');
    await scrollTo(tester, find.text('Start preparing'));
    await tester.tap(find.text('Start preparing'));
    await tester.pumpAndSettle();

    expect(store.data?.profile.name, 'Umesh');
    expect(store.due.length, 10);
    expect(find.byKey(const Key('countdown')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
