import 'package:flutter_test/flutter_test.dart';
import 'package:utsav/logic.dart';
import 'package:utsav/store.dart';

Guest g(int id, String status, int people, List<String> events, {int jain = 0, String city = 'Jaipur'}) =>
    Guest(id: id, name: 'F$id', status: status, people: people, events: events, jain: jain, city: city);

void main() {
  group('headcounts', () {
    final guests = [
      g(1, rsvpYes, 4, ['sangeet', 'wedding'], jain: 2),
      g(2, rsvpYes, 3, ['wedding'], jain: 5), // jain capped at family size
      g(3, rsvpWait, 5, ['sangeet']),
      g(4, rsvpNo, 2, []),
    ];

    test('only confirmed families count, per event', () {
      expect(confirmedFor(guests, 'sangeet'), 4);
      expect(confirmedFor(guests, 'wedding'), 7);
      expect(confirmedFor(guests, 'mehendi'), 0);
    });

    test('jain never exceeds family size', () {
      expect(jainFor(guests, 'wedding'), 5);
      expect(jainFor(guests, 'sangeet'), 2);
    });

    test('buffer rounds up', () {
      expect(platesWithBuffer(63, 10), 70); // 69.3 -> 70
      expect(platesWithBuffer(50, 10), 55);
      expect(platesWithBuffer(0, 10), 0);
      expect(platesWithBuffer(7, 0), 7);
    });

    test('waiting and confirmed totals', () {
      expect(familiesWaiting(guests), 1);
      expect(peopleConfirmed(guests), 7);
    });
  });

  group('rooms', () {
    test('largest out-of-town families first, locals skipped', () {
      final guests = [
        g(1, rsvpYes, 2, ['wedding'], city: 'Delhi'),
        g(2, rsvpYes, 5, ['wedding'], city: 'Mumbai'),
        g(3, rsvpYes, 6, ['wedding'], city: 'jaipur '), // local, any case
        g(4, rsvpWait, 4, ['wedding'], city: 'Kota'), // not confirmed
      ];
      final p = allotRooms(guests, homeCity: 'Jaipur', rooms: 3, perRoom: 3);
      expect(p.rooms[2], '101–102');
      expect(p.rooms[1], '103');
      expect(p.rooms.containsKey(3), isFalse);
      expect(p.rooms.containsKey(4), isFalse);
      expect(p.used, 3);
      expect(p.unplaced, isEmpty);
    });

    test('families that do not fit are listed', () {
      final guests = [g(1, rsvpYes, 6, ['w'], city: 'Delhi'), g(2, rsvpYes, 3, ['w'], city: 'Pune')];
      final p = allotRooms(guests, homeCity: 'Jaipur', rooms: 2, perRoom: 3);
      expect(p.rooms, {1: '101–102'});
      expect(p.unplaced, [2]);
    });

    test('rooms needed rounds up', () {
      expect(roomsNeeded(5, 3), 2);
      expect(roomsNeeded(3, 3), 1);
      expect(roomsNeeded(1, 0), 1);
    });
  });

  group('budget', () {
    test('totals and shares', () {
      final t = budgetTotals([
        BudgetLine(id: 1, cat: 'Venue', est: 800000, com: 800000, paid: 400000),
        BudgetLine(id: 2, cat: 'Catering', est: 900000, com: 960000, paid: 300000),
      ]);
      expect(t.est, 1700000);
      expect(t.com, 1760000);
      expect(t.paid, 700000);
      expect(t.toPay, 1060000);
      expect(t.paidPercent, 41);
      expect(t.committedShare, 1.0);
    });

    test('empty budget does not divide by zero', () {
      final t = budgetTotals([]);
      expect(t.paidShare, 0);
      expect(t.paidPercent, 0);
    });
  });

  group('vendor payments', () {
    test('paying the instalment moves the balance 30 days on', () {
      final r = applyPayment(total: 1000, paid: 400, nextAmount: 300, nextDue: '2026-11-01', amount: 300, today: '2026-10-01');
      expect(r.applied, 300);
      expect(r.paid, 700);
      expect(r.nextAmount, 300);
      expect(r.nextDue, '2026-12-01');
    });

    test('a part payment leaves the rest due on the same date', () {
      final r = applyPayment(total: 1000, paid: 400, nextAmount: 300, nextDue: '2026-11-01', amount: 100, today: '2026-10-01');
      expect(r.paid, 500);
      expect(r.nextAmount, 200);
      expect(r.nextDue, '2026-11-01');
    });

    test('overpaying is capped and closes the contract', () {
      final r = applyPayment(total: 1000, paid: 900, nextAmount: 100, nextDue: '2026-11-01', amount: 500, today: '2026-10-01');
      expect(r.applied, 100);
      expect(r.paid, 1000);
      expect(r.nextAmount, isNull);
      expect(r.nextDue, isNull);
    });
  });

  group('tasks', () {
    test('overdue and workload', () {
      final tasks = [
        WTask(id: 1, title: 'a', who: 'Papa', ev: '', due: '2026-09-01'),
        WTask(id: 2, title: 'b', who: 'Papa', ev: '', due: '2026-09-01', done: true),
        WTask(id: 3, title: 'c', who: 'You', ev: '', due: '2026-12-01'),
      ];
      expect(isOverdue(tasks[0], '2026-09-02'), isTrue);
      expect(isOverdue(tasks[1], '2026-09-02'), isFalse);
      final w = workload(tasks);
      expect(w.first.who, 'Papa');
      expect(w.first.open, 1);
      expect(w.first.done, 1);
      expect(openTasks(tasks).map((t) => t.id), [1, 3]);
    });
  });

  group('formatting', () {
    test('indian grouping and short lakhs', () {
      expect(inr(80000000), '₹8,00,000');
      expect(inrShort(96000000), '₹9.6 L');
      expect(inrShort(80000000), '₹8 L');
      expect(inrShort(1500000000), '₹1.5 Cr');
      expect(inrShort(4500000), '₹45,000');
      expect(inrExact(12345), '₹123.45');
      expect(parseRupees('4,50,000'), 45000000);
      expect(parseRupees('abc'), isNull);
      expect(rupeesField(125050), '1250.50');
    });

    test('dates and times', () {
      expect(time12('19:00'), '7 PM');
      expect(time12('16:30'), '4:30 PM');
      expect(time12('00:15'), '12:15 AM');
      expect(dateRange('2026-12-11', '2026-12-14'), '11–14 December');
      expect(daysBetween('2026-09-28', '2026-12-13'), 76);
      expect(addDaysIso('2026-12-31', 1), '2027-01-01');
    });

    test('whatsapp numbers', () {
      expect(waNumber('98290 12345'), '919829012345');
      expect(waNumber('+91 98290 12345'), '919829012345');
      expect(waNumber('09829012345'), '919829012345');
      expect(waNumber('123'), '');
      expect(waLink('hi there'), 'https://wa.me/?text=hi%20there');
    });
  });

  group('sample data', () {
    test('matches the prototype and survives a save and load', () {
      final d = AppData.fromJson(sampleData().toJson());
      expect(d.guests.length, 30);
      expect(d.events.length, 5);
      expect(familiesWaiting(d.guests), 10);
      expect(peopleConfirmed(d.guests), 63);
      expect(confirmedFor(d.guests, 'sangeet'), 63);
      expect(jainFor(d.guests, 'sangeet'), 1);
      expect(confirmedFor(d.guests, 'mehendi'), 56);
      expect(daysBetween(todayIso(), d.weddingDate), 76);
      final t = budgetTotals(d.budget);
      expect(inrShort(t.est), '₹33 L');
      expect(inrShort(t.com), '₹31.2 L');
      expect(d.tasks.where((x) => isOverdue(x, todayIso())).length, 1);
    });

    test('every out-of-town family fits in 20 rooms', () {
      final d = sampleData();
      final p = allotRooms(d.guests, homeCity: d.city, rooms: d.hotelRooms, perRoom: d.perRoom);
      expect(p.rooms.length, 9);
      expect(p.used, 14);
      expect(p.unplaced, isEmpty);
    });
  });
}
