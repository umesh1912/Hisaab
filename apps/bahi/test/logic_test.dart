import 'package:bahi/logic.dart';
import 'package:bahi/store.dart';
import 'package:flutter_test/flutter_test.dart';

Customer cust(AppData d, int id) => d.customer(id)!;

void main() {
  group('balances', () {
    test('sample khata balances match the prototype', () {
      final d = sampleData();
      expect(balanceOf(cust(d, 1)), 184000); // Ramesh
      expect(balanceOf(cust(d, 2)), 245000); // Mohan
      expect(balanceOf(cust(d, 3)), 112000); // Anita
      expect(balanceOf(cust(d, 4)), 97500); // Salim
      expect(balanceOf(cust(d, 7)), 0); // Verma: settled
      expect(balanceOf(cust(d, 8)), -50000); // Kapoor: advance
      expect(totalToCollect(d.customers), 731500);
    });

    test('running balance ends at the balance', () {
      final d = sampleData();
      for (final c in d.customers) {
        final r = runningBalances(c);
        expect(r.isEmpty ? 0 : r.last, balanceOf(c));
      }
    });

    test('oldest unpaid walks credits newest to oldest', () {
      final c = Customer(id: 1, name: 'A', entries: [
        Entry(id: 1, date: '2026-09-01', kind: 'credit', amount: 50000),
        Entry(id: 2, date: '2026-09-10', kind: 'pay', amount: 50000),
        Entry(id: 3, date: '2026-09-20', kind: 'credit', amount: 30000),
        Entry(id: 4, date: '2026-09-25', kind: 'credit', amount: 10000),
      ]);
      expect(balanceOf(c), 40000);
      expect(oldestUnpaidDays(c, '2026-09-28'), 8);
      expect(isOverdue(c, '2026-09-28'), isFalse);
      expect(isOverdue(c, '2026-10-10'), isTrue);
      expect(lastPayDate(c), '2026-09-10');
    });

    test('settled or advance customers have no unpaid days', () {
      final c = Customer(id: 1, name: 'A', entries: [Entry(id: 1, date: '2026-09-01', kind: 'pay', amount: 100)]);
      expect(oldestUnpaidDays(c, '2026-09-28'), 0);
    });

    test('collect list ranks by amount and age, skipping promises', () {
      final d = sampleData();
      final today = todayIso();
      final ids = collectList(d.customers, today).map((c) => c.id).toList();
      expect(ids, [2, 3, 1, 5, 6]);
      expect(promisedList(d.customers, today).map((c) => c.id), [4]);
    });

    test('today totals come from entries', () {
      final d = sampleData();
      final today = todayIso();
      expect(creditOn(d.customers, today), 93000);
      expect(collectedOn(d.customers, today), 0);
      expect(entriesOn(d.customers, today).length, 2);
    });
  });

  group('parsing entries', () {
    final customers = sampleData().customers;

    test('Hindi credit with items', () {
      final r = parseEntry('रमेश जी 340 उधार दूध ब्रेड', customers)!;
      expect(r.matches.map((c) => c.id), [1]);
      expect(r.amount, 34000);
      expect(r.kind, 'credit');
      expect(r.note, 'Doodh, Bread');
    });

    test('Hinglish payment', () {
      final r = parseEntry('Salim 200 jama', customers)!;
      expect(r.matches.map((c) => c.id), [4]);
      expect(r.amount, 20000);
      expect(r.kind, 'pay');
      expect(r.note, 'Cash');
    });

    test('number words', () {
      final r = parseEntry('मोहन के साढ़े तीन सौ चीनी', customers)!;
      expect(r.matches.map((c) => c.id), [2]);
      expect(r.amount, 35000);
      expect(r.kind, 'credit');
      expect(r.note, 'Cheeni');
      expect(amountsIn('डेढ़ सौ'), [150]);
      expect(amountsIn('ढाई हज़ार'), [2500]);
      expect(amountsIn('ढाई हजार'), [2500]);
      expect(amountsIn('सवा सौ'), [125]);
      expect(amountsIn('तीन सौ चालीस'), [340]);
      expect(amountsIn('do hazaar teen sau pachas'), [2350]);
      expect(amountsIn('१२०'), [120]);
      expect(amountsIn('₹1,250/-'), [1250]);
    });

    test('unknown name and empty text', () {
      final r = parseEntry('Deepak 150 udhaar', customers)!;
      expect(r.matches, isEmpty);
      expect(r.amount, 15000);
      expect(parseEntry('   ', customers), isNull);
    });

    test('two customers with the same first name are both offered', () {
      final two = [Customer(id: 1, name: 'Ramesh Yadav'), Customer(id: 2, name: 'Ramesh Jain')];
      expect(parseEntry('Ramesh 50', two)!.matches.length, 2);
      expect(parseEntry('Ramesh Jain 50', two)!.matches.map((c) => c.id), [2]);
    });
  });

  group('reminders', () {
    test('message has the balance and UPI ID', () {
      final d = sampleData();
      final hi = reminderText(d.shop, cust(d, 1), false);
      expect(hi, contains('₹1,840'));
      expect(hi, contains('guptastore@okaxis'));
      expect(hi, startsWith('नमस्ते रमेश जी'));
      expect(reminderText(d.shop, cust(d, 1), true), startsWith('Namaste Ramesh ji'));
      expect(statementText(d.shop, cust(d, 1), true), contains('Balance due: ₹1,840'));
    });

    test('WhatsApp links', () {
      expect(whatsAppLink('98260 11223', 'hi there'), 'https://wa.me/919826011223?text=hi%20there');
      expect(whatsAppLink('+91 98260 11223', 'x'), 'https://wa.me/919826011223?text=x');
      expect(whatsAppLink('', 'x'), 'https://wa.me/?text=x');
      expect(telLink('98260 11223'), 'tel:9826011223');
    });

    test('rate limit and quiet hours', () {
      final c = Customer(id: 1, name: 'A', reminded: '2026-09-27');
      expect(remindedRecently(c, '2026-09-28'), isTrue);
      expect(remindedRecently(c, '2026-09-30'), isFalse);
      expect(quietHours(DateTime(2026, 9, 28, 21, 5)), isTrue);
      expect(quietHours(DateTime(2026, 9, 28, 8, 59)), isTrue);
      expect(quietHours(DateTime(2026, 9, 28, 14)), isFalse);
    });
  });

  group('formatting', () {
    test('indian grouping and parsing', () {
      expect(inr(4800000), '₹48,000');
      expect(inr(12345678900), '₹12,34,56,789');
      expect(inr(-50000), '-₹500');
      expect(inrExact(12345), '₹123.45');
      expect(parseRupees('1,250.50'), 125050);
      expect(parseRupees('abc'), isNull);
      expect(parseRupees('-5'), isNull);
      expect(rupeesField(125000), '1250');
    });

    test('dates', () {
      expect(daysBetween('2026-09-01', '2026-09-28'), 27);
      expect(addDaysIso('2026-12-31', 1), '2027-01-01');
      expect(dateLabel('2026-09-28', true), '28 Sep');
      expect(dayShort('2026-09-28', true), 'Mon');
      expect(relativeDay('2026-09-27', '2026-09-28', true), 'yesterday');
    });
  });

  test('sample data survives a save and load', () {
    final d = sampleData();
    final back = AppData.fromJson(d.toJson());
    expect(back.customers.length, 8);
    expect(back.shop.upi, 'guptastore@okaxis');
    expect(back.sales.length, 7);
    expect(totalToCollect(back.customers), totalToCollect(d.customers));
    expect(back.customer(4)!.promise, d.customer(4)!.promise);
  });
}
