import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rasid/logic.dart';
import 'package:rasid/store.dart';

Item _item({
  int id = 1,
  String name = 'Refrigerator',
  String brand = 'Samsung',
  String serial = 'SN-1',
  String cat = 'kitchen',
  String date = '2026-01-01',
  List<Warranty>? warranties,
  int price = 2500000,
}) =>
    Item(id: id, name: name, brand: brand, serial: serial, cat: cat, price: price, date: date, warranties: warranties);

void main() {
  group('dates and money', () {
    test('indian grouping', () {
      expect(inr(4199000), '₹41,990');
      expect(inr(12345678900), '₹12,34,56,789');
      expect(inr(99), '₹1');
      expect(parseRupees('1,250.50'), 125050);
      expect(parseRupees('abc'), isNull);
    });

    test('add months clamps to month end', () {
      expect(addMonthsIso('2026-01-31', 1), '2026-02-28');
      expect(addMonthsIso('2026-12-15', 1), '2027-01-15');
      expect(warrantyEnd('2026-01-15', 12), '2027-01-14');
      expect(daysBetween('2026-01-01', '2026-01-31'), 30);
    });

    test('time left labels', () {
      expect(timeLeftLabel(1), '1 day');
      expect(timeLeftLabel(7), '7 days');
      expect(timeLeftLabel(95), '3 mo');
      expect(timeLeftLabel(369), '1 yr');
      expect(timeLeftLabel(548), '1.5 yr');
      expect(timeLeftLabel(2926), '8 yr');
    });
  });

  group('warranty state', () {
    final it = _item(warranties: [
      Warranty(label: 'Product', until: '2026-02-10'),
      Warranty(label: 'Compressor', until: '2030-01-01'),
    ]);

    test('the next cover to end is shown first', () {
      final s = warrantyState(it, '2026-01-20');
      expect(s.cover, Cover.soon);
      expect(s.days, 21);
      expect(s.warranty?.label, 'Product');
    });

    test('a longer cover keeps the item covered', () {
      final s = warrantyState(it, '2026-03-01');
      expect(s.cover, Cover.ok);
      expect(s.warranty?.label, 'Compressor');
    });

    test('out of warranty after the last cover ends', () {
      final s = warrantyState(it, '2031-01-01');
      expect(s.cover, Cover.out);
      expect(s.days, isNull);
      expect(s.warranty?.label, 'Compressor');
      expect(coverFraction(it, s), 0);
    });

    test('filters and covered value', () {
      final a = _item(id: 1, warranties: [Warranty(label: 'Product', until: '2027-01-01')]);
      final b = _item(id: 2, name: 'Laptop', brand: 'HP', serial: '5CD4381XKQ', cat: 'computer', price: 6000000, warranties: [
        Warranty(label: 'Product', until: '2026-02-01'),
      ]);
      final c = _item(id: 3, name: 'Fan', brand: 'Havells', cat: 'home', price: 300000, warranties: [
        Warranty(label: 'Product', until: '2025-06-01'),
      ]);
      const today = '2026-01-15';
      final all = filterItems([a, b, c], today: today);
      expect(all.map((i) => i.id).toList(), [2, 1, 3]);
      expect(filterItems([a, b, c], query: '5cd43', today: today).single.id, 2);
      expect(filterItems([a, b, c], show: 'out', today: today).single.id, 3);
      expect(filterItems([a, b, c], cat: 'kitchen', today: today).single.id, 1);
      expect(coveredValue([a, b, c], today), 2500000 + 6000000);
    });
  });

  group('reminders', () {
    const today = '2026-09-29';
    test('alerts show what is due soon and overdue services', () {
      final rs = [
        Reminder(id: 1, title: 'w soon', date: '2026-10-09', kind: 'warranty'),
        Reminder(id: 2, title: 'service late', date: '2026-09-24', kind: 'service'),
        Reminder(id: 3, title: 'warranty ended', date: '2026-09-24', kind: 'warranty'),
        Reminder(id: 4, title: 'off', date: '2026-10-01', kind: 'warranty', on: false),
        Reminder(id: 5, title: 'far', date: '2026-11-15', kind: 'service'),
      ];
      expect(alertReminders(rs, today).map((r) => r.id).toList(), [2, 1]);
    });

    test('repeating service moves past today, one-off is removed', () {
      final r = Reminder(id: 1, title: 'RO filter', date: '2026-01-10', everyMonths: 6);
      expect(completeReminder(r, today), isTrue);
      expect(r.date, '2027-01-10');
      final once = Reminder(id: 2, title: 'Once', date: '2026-09-01');
      expect(completeReminder(once, today), isFalse);
    });

    test('warranty reminders skip ended covers and keep on/off', () {
      final it = _item(id: 7, warranties: [
        Warranty(label: 'Product', until: '2026-01-01'),
        Warranty(label: 'Extended', until: '2027-06-01'),
      ]);
      var n = 100;
      final prev = [Reminder(id: 1, title: 'x', date: '2027-06-01', itemId: 7, kind: 'warranty', on: false)];
      final out = warrantyReminders(it, today, () => n++, previous: prev);
      expect(out.length, 1);
      expect(out.first.title, 'Samsung Refrigerator: Extended ends');
      expect(out.first.on, isFalse);
      expect(out.first.id, 100);
    });
  });

  group('claims', () {
    final it = _item(warranties: [Warranty(label: 'Product', until: '2027-01-01')]);

    test('advancing past the visit closes the claim', () {
      final c = newClaim(id: 1, item: it, issue: 'Leaking', under: 'Product warranty', ref: '', today: '2026-09-01');
      expect(c.isOpen, isTrue);
      expect(c.current?.title, 'Technician visit');
      advanceClaim(c, '2026-09-03');
      expect(c.isOpen, isFalse);
      expect(c.steps.last.date, '2026-09-03');
    });

    test('added steps go before repair done', () {
      final c = newClaim(id: 1, item: it, issue: 'Noise', under: 'Product warranty', ref: 'SR-1', today: '2026-09-01');
      addClaimStep(c, 'Waiting for spare part', 'Five days', '2026-09-02');
      expect(c.steps.length, 4);
      expect(c.current?.title, 'Waiting for spare part');
      expect(c.steps[1].done, isTrue);
      expect(c.steps.last.title, 'Repair done');
      expect(c.isOpen, isTrue);
      closeClaim(c, '2026-09-05');
      expect(c.isOpen, isFalse);
      expect(c.current, isNull);
    });

    test('claim summary and escalation text include the proof', () {
      final sum = claimSummary(it, 'Leaking', 'Product warranty', '2027-01-01');
      expect(sum, contains('Serial: SN-1'));
      expect(sum, contains('Problem: Leaking'));
      final c = newClaim(id: 1, item: it, issue: 'Leaking', under: 'Product warranty', ref: 'SR-9', today: '2026-09-01');
      final esc = escalationText(it, c, '2026-09-15');
      expect(esc, contains('Service request SR-9'));
      expect(esc, contains('14 days'));
    });
  });

  group('bill text reader', () {
    test('shop bill', () {
      final b = parseBillText('CROMA\n'
          'Tax Invoice\n'
          'Invoice No: CRM/GCB/0412/118\n'
          'Date: 14/03/2025\n'
          'LG Air Conditioner 1.5 ton  1  41,990.00\n'
          'Serial No: 503KAXQ0N119\n'
          'Warranty: 1 year\n'
          'Grand Total: 41,990.00');
      expect(b.store, 'Croma');
      expect(b.invoice, 'CRM/GCB/0412/118');
      expect(b.date, '2025-03-14');
      expect(b.brand, 'LG');
      expect(b.name, 'Air conditioner');
      expect(b.cat, 'cooling');
      expect(b.model, '1.5 ton');
      expect(b.serial, '503KAXQ0N119');
      expect(b.price, 4199000);
      expect(b.warrantyMonths, 12);
    });

    test('order email', () {
      final b = parseBillText('Hi Priya,\n'
          'Your order has been shipped.\n'
          'Order #408-1234567-7654321\n'
          'Ordered on 26 September 2026\n'
          'OnePlus Nord Buds 3 earbuds\n'
          'Order Total: ₹2,299.00\n'
          'Thanks for shopping at Amazon.in');
      expect(b.store, 'Amazon.in');
      expect(b.invoice, '408-1234567-7654321');
      expect(b.date, '2026-09-26');
      expect(b.brand, 'OnePlus');
      expect(b.name, 'Wireless earbuds');
      expect(b.price, 229900);
      expect(b.warrantyMonths, isNull);
    });

    test('empty text finds nothing', () {
      expect(parseBillText('   ').found, isEmpty);
    });

    test('date formats', () {
      expect(findDate('Bill dated 5-1-26'), '2026-01-05');
      expect(findDate('Sep 26, 2026'), '2026-09-26');
      expect(findDate('2026-09-26'), '2026-09-26');
      expect(findDate('31/02/2026'), isNull);
    });
  });

  test('insurance CSV quotes commas', () {
    final d = AppData(homeName: 'Home', meId: 'me', members: [Member(id: 'me', name: 'Priya')], items: [
      _item(name: 'Fan, ceiling', warranties: [Warranty(label: 'Product', until: '2027-01-01')]),
    ]);
    final lines = insuranceCsv(d).split('\n');
    expect(lines.length, 2);
    expect(lines.first, startsWith('Item,Brand,Model'));
    expect(lines[1], startsWith('"Fan, ceiling",Samsung'));
    expect(lines[1], contains('Priya'));
  });

  test('sample data survives a save and load', () {
    final d = sampleData();
    final back = AppData.fromJson(jsonDecode(jsonEncode(d.toJson())) as Map<String, dynamic>);
    expect(back.items.length, d.items.length);
    expect(back.claims.length, 1);
    expect(back.claims.first.isOpen, isTrue);
    expect(back.reminders.length, d.reminders.length);
    expect(back.member(back.meId)?.name, 'Priya');
    expect(back.item(5)?.warranties.length, 3);
    final today = todayIso();
    expect(warrantyState(back.item(1)!, today).cover, Cover.soon);
    expect(warrantyState(back.item(9)!, today).cover, Cover.out);
    expect(vaultSummary(back, today), contains('9 items'));
  });
}
