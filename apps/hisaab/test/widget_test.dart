import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/main.dart';
import 'package:hisaab/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('onboarding, sample data and every tab render', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = HisaabStore();
    await store.load();
    await tester.pumpWidget(HisaabApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Create flat'), findsOneWidget);
    await tester.ensureVisible(find.text('Explore with sample data'));
    await tester.tap(find.text('Explore with sample data'));
    await tester.pumpAndSettle();
    expect(find.text('Flat 3B'), findsOneWidget);

    for (final label in ['Expenses', 'List', 'Chores', 'Balances', 'Home']) {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);

    // Open the add expense sheet
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    expect(find.text('Save expense'), findsOneWidget);
  });

  testWidgets('creating a flat saves members', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = HisaabStore();
    await store.load();
    await tester.pumpWidget(HisaabApp(store: store));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Flat name'), 'Flat 7');
    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Umesh');
    await tester.enterText(find.widgetWithText(TextField, 'Name 1'), 'Ravi');
    await tester.ensureVisible(find.text('Create flat'));
    await tester.tap(find.text('Create flat'));
    await tester.pumpAndSettle();

    expect(store.data?.members.length, 2);
    expect(find.text('Flat 7'), findsOneWidget);
  });
}
