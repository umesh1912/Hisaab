import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenden/main.dart';
import 'package:lenden/screens/discover.dart';
import 'package:lenden/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs the app on a typical phone screen (360 x 800).
Future<LendenStore> startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final store = LendenStore();
  await store.load();
  await tester.pumpWidget(LendenApp(store: store));
  await tester.pumpAndSettle();
  return store;
}

Future<void> scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

/// Scrolls a widget into view (in a sheet or a list) and taps it.
Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Lets any snack bar time out so it does not cover buttons.
Future<void> clearToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Future<void> goTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding, sample data and every tab render', (tester) async {
    await startApp(tester);

    expect(find.text('Lenden'), findsOneWidget);
    await scrollTo(tester, find.text('Explore with sample data'));
    await tester.tap(find.text('Explore with sample data'));
    await tester.pumpAndSettle();
    expect(find.text('Wants my skills'), findsOneWidget);
    final discoverList = find.descendant(of: find.byType(DiscoverScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('BEST MATCHES'), 300, scrollable: discoverList);
    await tester.pumpAndSettle();
    await tester.drag(discoverList, const Offset(0, 3000));
    await tester.pumpAndSettle();

    for (final label in ['Swaps', 'Messages', 'Credits', 'Profile', 'Discover']) {
      await goTab(tester, label);
    }
    expect(tester.takeException(), isNull);

    // Filters and categories.
    await tester.tap(find.text('Wants my skills'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wants my skills'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Music'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('request, accept, run and rate a swap', (tester) async {
    final store = await startApp(tester);
    await scrollTo(tester, find.text('Explore with sample data'));
    await tester.tap(find.text('Explore with sample data'));
    await tester.pumpAndSettle();

    // Open Vikram's profile, then the request sheet.
    final discoverList = find.descendant(of: find.byType(DiscoverScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Vikram S.'), 300, scrollable: discoverList);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vikram S.'));
    await tester.pumpAndSettle();
    expect(find.text('Wants to learn'), findsOneWidget);
    await tapVisible(tester, find.text('Request a swap'));
    expect(find.text('Send request'), findsOneWidget);

    // Sending without a time shows an error.
    await tapVisible(tester, find.text('Send request'));
    expect(find.text('Pick a time that suits Vikram.'), findsOneWidget);

    await tapVisible(tester, find.text('Pay with credits'));
    await tapVisible(tester, find.text('Teach Vikram back'));
    await tapVisible(tester, find.text('1.5 hr'));
    await tapVisible(tester, find.textContaining('· 7 AM').first);
    await tapVisible(tester, find.text('Send request'));
    expect(tester.takeException(), isNull);
    expect(store.tab, 1);
    expect(store.data!.sessions.where((s) => s.status == 'sent').length, 2);
    await clearToast(tester);

    // Record that Vikram said yes, and accept Deepa's request.
    await tapVisible(tester, find.text('Vikram said yes').first);
    expect(store.data!.sessions.where((s) => s.status == 'sent').length, 0);
    await clearToast(tester);
    await tapVisible(tester, find.text('Accept'));
    expect(store.data!.sessions.where((s) => s.status == 'incoming').length, 0);
    await clearToast(tester);

    // Run the first upcoming session and rate it.
    await tapVisible(tester, find.textContaining('Upcoming'));
    final ledgerBefore = store.data!.ledger.length;
    await tapVisible(tester, find.text('Start session').first);
    expect(find.text('Check in'), findsOneWidget);
    await tapVisible(tester, find.text('Mark session done'));
    expect(store.data!.ledger.length, ledgerBefore + 1);
    await tapVisible(tester, find.text('Post review'));
    expect(tester.takeException(), isNull);
    await clearToast(tester);

    // Past sessions list.
    await tapVisible(tester, find.textContaining('Past'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile, skills and chat sheets', (tester) async {
    final store = await startApp(tester);
    await scrollTo(tester, find.text('Explore with sample data'));
    await tester.tap(find.text('Explore with sample data'));
    await tester.pumpAndSettle();

    await goTab(tester, 'Profile');
    await tapVisible(tester, find.byKey(const ValueKey('add-teach')));
    expect(find.text('Add a skill you teach'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Skill'), 'Public speaking');
    await tapVisible(tester, find.text('Add skill'));
    expect(store.data!.me.teachNames.contains('Public speaking'), isTrue);
    await clearToast(tester);

    await tapVisible(tester, find.byKey(const ValueKey('add-learn')));
    expect(find.text('Add something to learn'), findsOneWidget);
    Navigator.of(tester.element(find.text('Add something to learn'))).pop();
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byTooltip('Edit profile'));
    expect(find.text('Save profile'), findsOneWidget);
    Navigator.of(tester.element(find.text('Save profile'))).pop();
    await tester.pumpAndSettle();

    await goTab(tester, 'Messages');
    await tapVisible(tester, find.text('Vikram S.'));
    final before = store.data!.threads['vikram']!.length;
    await tester.enterText(find.byType(TextField).last, 'See you Saturday');
    await tapVisible(tester, find.byTooltip('Send'));
    expect(store.data!.threads['vikram']!.length, before + 1);
    expect(store.unreadThreads, 1);
    Navigator.of(tester.element(find.byTooltip('Send'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Your time credits'));
    await tester.pumpAndSettle();
    expect(store.tab, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creating a profile starts with welcome credits', (tester) async {
    final store = await startApp(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Umesh');
    await tester.enterText(find.widgetWithText(TextField, 'Neighbourhood'), 'Indiranagar');
    await scrollTo(tester, find.widgetWithText(TextField, 'Skill'));
    await tester.enterText(find.widgetWithText(TextField, 'Skill'), 'Excel & Google Sheets');
    await scrollTo(tester, find.widgetWithText(TextField, 'Skills to learn'));
    await tester.enterText(find.widgetWithText(TextField, 'Skills to learn'), 'Yoga, Chess');
    await scrollTo(tester, find.text('Start swapping'));
    await tester.tap(find.text('Start swapping'));
    await tester.pumpAndSettle();

    expect(store.data?.me.name, 'Umesh');
    expect(store.data?.me.learns, ['Yoga', 'Chess']);
    expect(store.balanceHrs, 2);
    expect(find.text('Indiranagar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
