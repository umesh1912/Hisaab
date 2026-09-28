import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/logic.dart';
import 'package:hisaab/store.dart';

void main() {
  group('splits', () {
    test('equal shares always add up', () {
      final s = equalShares(1000, ['a', 'b', 'c']);
      expect(s.values.reduce((a, b) => a + b), 1000);
      expect(s['a'], 334);
      expect(s['c'], 333);
    });

    test('weighted shares add up', () {
      final s = weightedShares(10000, {'a': 2, 'b': 1, 'c': 0});
      expect(s.containsKey('c'), isFalse);
      expect(s.values.reduce((a, b) => a + b), 10000);
      expect(s['a'], 6667);
    });
  });

  group('balances', () {
    final ids = ['a', 'b', 'c'];
    final exps = [
      Expense(id: 1, desc: 'x', amount: 3000, paidBy: 'a', shares: equalShares(3000, ids), mode: 'equal', cat: 'food', date: '2026-09-01'),
      Expense(id: 2, desc: 'y', amount: 600, paidBy: 'b', shares: equalShares(600, ids), mode: 'equal', cat: 'food', date: '2026-09-02'),
    ];

    test('net balances sum to zero', () {
      final net = netBalances(ids, exps, []);
      expect(net.values.reduce((a, b) => a + b), 0);
      expect(net['a'], 1800);
      expect(net['b'], -600);
      expect(net['c'], -1200);
    });

    test('simplified debts clear every balance', () {
      final net = netBalances(ids, exps, []);
      final t = simplifyDebts(net);
      final after = Map.of(net);
      for (final x in t) {
        after[x.from] = after[x.from]! + x.amount;
        after[x.to] = after[x.to]! - x.amount;
      }
      expect(after.values.every((v) => v.abs() <= 50), isTrue);
      expect(t.length, lessThanOrEqualTo(ids.length - 1));
    });

    test('payments reduce debt', () {
      final pay = [Payment(id: 9, from: 'c', to: 'a', amount: 1200, date: '2026-09-03')];
      final net = netBalances(ids, exps, pay);
      expect(net['c'], 0);
    });

    test('pairwise matches net totals', () {
      final t = pairwiseDebts(ids, exps, []);
      final after = netBalances(ids, exps, []);
      for (final x in t) {
        after[x.from] = after[x.from]! + x.amount;
        after[x.to] = after[x.to]! - x.amount;
      }
      expect(after.values.every((v) => v.abs() <= 50), isTrue);
    });
  });

  group('chores', () {
    test('away people are skipped', () {
      final c = Chore(id: 1, name: 'Trash', everyDays: 1, rotation: ['a', 'b', 'c'], due: '2026-09-01');
      expect(currentTurn(c, {}), 0);
      expect(currentTurn(c, {'a'}), 1);
      expect(currentTurn(c, {'a', 'b'}), 2);
    });
  });

  group('formatting', () {
    test('indian grouping', () {
      expect(inr(4800000), '₹48,000');
      expect(inr(12345678900), '₹12,34,56,789');
      expect(inrExact(12345), '₹123.45');
      expect(parseRupees('1,250.50'), 125050);
      expect(parseRupees('abc'), isNull);
    });

    test('add month clamps to month end', () {
      expect(addMonthIso('2026-01-31'), '2026-02-28');
      expect(addMonthIso('2026-12-15'), '2027-01-15');
    });
  });

  test('sample data survives a save and load', () {
    final d = sampleData();
    final back = AppData.fromJson(d.toJson());
    expect(back.members.length, 4);
    expect(back.expenses.length, d.expenses.length);
    expect(netBalances(['me', 'rohan', 'priya', 'karthik'], back.expenses, back.payments).values.reduce((a, b) => a + b), 0);
  });
}
