import 'package:flutter_test/flutter_test.dart';
import 'package:khayal/logic.dart';
import 'package:khayal/store.dart';

Med med({int id = 1, String who = 'p', List<String> times = const ['08:00', '20:00'], int stock = 20, int per = 1, String since = '2026-01-01'}) =>
    Med(id: id, who: who, name: 'M$id', strength: '5 mg', times: [...times], stock: stock, per: per, since: since);

void main() {
  group('time of day', () {
    test('minutes and 12-hour format', () {
      expect(mins('08:30'), 510);
      expect(hhmm(510), '08:30');
      expect(hhmm(1440 + 15), '00:15');
      expect(t12('00:05'), '12:05 AM');
      expect(t12('12:00'), '12:00 PM');
      expect(t12('20:30'), '8:30 PM');
    });
  });

  group('dose status', () {
    final now = DateTime(2026, 9, 28, 17, 0);
    test('recorded doses keep their status', () {
      expect(doseStatus(DoseLog(s: 'taken', at: '08:05'), '2026-09-28', '08:00', now), 'taken');
      expect(doseStatus(DoseLog(s: 'skipped', at: '08:05'), '2026-09-28', '08:00', now), 'skipped');
    });
    test('unconfirmed doses turn due, then missed after an hour', () {
      expect(doseStatus(null, '2026-09-28', '17:30', now), 'up');
      expect(doseStatus(null, '2026-09-28', '16:30', now), 'due');
      expect(doseStatus(null, '2026-09-28', '16:00', now), 'missed');
      expect(doseStatus(null, '2026-09-27', '21:00', now), 'missed');
      expect(doseStatus(null, '2026-09-29', '06:00', now), 'up');
    });
    test('late means more than 30 minutes', () {
      expect(isLate('08:30', '09:10'), isTrue);
      expect(isLate('08:30', '09:00'), isFalse);
    });
  });

  group('adherence', () {
    final now = DateTime(2026, 9, 28, 12, 0);
    final meds = [med(times: ['08:00', '20:00'])];
    test('only doses whose time has passed count today', () {
      final logs = {doseKey('2026-09-28', 1, '08:00'): DoseLog(s: 'taken', at: '08:10')};
      expect(dayAdherence(meds, logs, 'p', '2026-09-28', now), 100);
      expect(dayAdherence(meds, {}, 'p', '2026-09-28', now), 0);
    });
    test('past days count every dose', () {
      final logs = {doseKey('2026-09-27', 1, '08:00'): DoseLog(s: 'taken', at: '08:10')};
      expect(dayAdherence(meds, logs, 'p', '2026-09-27', now), 50);
    });
    test('no doses before the medicine started', () {
      final late = [med(since: '2026-09-28')];
      expect(dayAdherence(late, {}, 'p', '2026-09-27', now), isNull);
      expect(weekAdherence(late, {}, 'p', now).length, 7);
      expect(averageOf([null, 50, 100]), 75);
      expect(averageOf([null]), isNull);
    });
    test('missed today lists unconfirmed past doses', () {
      final m = missedToday(meds, {}, ['p'], DateTime(2026, 9, 28, 21, 30));
      expect(m.map((d) => d.time).toList(), ['08:00', '20:00']);
    });
    test('week counts split missed and late', () {
      final logs = {
        doseKey('2026-09-28', 1, '08:00'): DoseLog(s: 'taken', at: '09:00'),
        doseKey('2026-09-27', 1, '08:00'): DoseLog(s: 'skipped', at: '09:00'),
      };
      final c = weekCounts([med(since: '2026-09-27')], logs, 'p', now);
      expect(c.total, 3); // 27th both doses, 28th morning
      expect(c.taken, 1);
      expect(c.late['M1'], 1);
      expect(c.missed['M1'], 2);
    });
  });

  group('stock', () {
    test('days left and low stock', () {
      final a = med(id: 1, times: ['08:00', '20:00'], stock: 9); // 4 days
      final b = med(id: 2, times: ['08:00'], stock: 40);
      expect(daysLeft(a), 4);
      expect(monthSupply(a), 60);
      expect(lowStock([b, a]).map((m) => m.id).toList(), [1]);
      expect(daysLeft(med(times: [])), 999);
    });
    test('refill message lists each low medicine', () {
      final msg = refillMessage(low: [med(stock: 2)], nameOf: (_) => 'Papa', address: 'Flat 4', caregiver: 'Karan');
      expect(msg, contains('deliver to Flat 4'));
      expect(msg, contains('M1 5 mg × 60 (Papa)'));
      expect(msg, endsWith('– Karan'));
    });
  });

  group('readings', () {
    test('chart range covers target and values', () {
      expect(chartRange([128, 142], 60, 160), [60, 160]);
      expect(chartRange([185, 55], 60, 160), [40, 200]);
    });
    test('validation', () {
      expect(checkBp(126, 80), isNull);
      expect(checkBp(80, 126), isNotNull);
      expect(checkBp(null, 80), isNotNull);
      expect(checkSugar(116), isNull);
      expect(checkSugar(5), isNotNull);
    });
    test('recent readings are oldest first and capped', () {
      final rs = [for (var i = 0; i < 10; i++) Reading(id: i, who: 'p', kind: 'bp', date: '2026-09-${(10 + i)}', a: 120 + i, b: 80)];
      final r = recentReadings(rs.reversed.toList(), 'p', 'bp');
      expect(r.length, 7);
      expect(r.first.a, 123);
      expect(r.last.a, 129);
    });
  });

  group('misc', () {
    test('whatsapp digits', () {
      expect(waDigits('98220 41137'), '919822041137');
      expect(waDigits('+91 98220 41137'), '919822041137');
      expect(waDigits(''), '');
    });
    test('prune removes old dose records', () {
      final logs = {
        doseKey('2026-01-01', 1, '08:00'): DoseLog(s: 'taken', at: '08:00'),
        doseKey('2026-09-27', 1, '08:00'): DoseLog(s: 'taken', at: '08:00'),
      };
      pruneLogs(logs, '2026-09-28');
      expect(logs.length, 1);
    });
    test('ladder is sorted and skips people turned off', () {
      final l = ladder([
        Helper(id: 'a', name: 'A', step: 120),
        Helper(id: 'b', name: 'B', step: 60),
        Helper(id: 'c', name: 'C', step: 30, on: false),
      ]);
      expect(l.map((h) => h.id).toList(), ['b', 'a']);
    });
    test('dates', () {
      expect(addDaysIso('2026-12-31', 1), '2027-01-01');
      expect(friendlyDate('2026-09-29', '2026-09-28'), 'Tomorrow');
      expect(friendlyDate('2026-10-06', '2026-09-28'), 'Tue 6 Oct');
    });
  });

  group('sample data', () {
    final now = DateTime(2026, 9, 28, 17, 0);
    test('survives a save and load', () {
      final d = sampleData(now);
      final back = AppData.fromJson(d.toJson());
      expect(back.parents.length, 2);
      expect(back.meds.length, d.meds.length);
      expect(back.logs.length, d.logs.length);
      expect(back.readings.length, d.readings.length);
      expect(back.who, 'mummy');
    });
    test("at 5 PM Mummy's 2 PM calcium is the one missed dose", () {
      final d = sampleData(now);
      final m = missedToday(d.meds, d.logs, ['papa', 'mummy'], now);
      expect(m.length, 1);
      expect(m.first.med.name, 'Calcium + Vitamin D3');
      expect(lowStock(d.meds).map((x) => x.name), contains('Telmisartan'));
    });
    test('doctor summary and weekly summary include the facts', () {
      final d = sampleData(now);
      final s = doctorSummary(p: d.parent('papa')!, meds: d.meds, logs: d.logs, readings: d.readings, visit: d.visits.first, now: now);
      expect(s, contains('Suresh Sharma (68)'));
      expect(s, contains('Metformin'));
      expect(s, contains('BP average of last 7'));
      final w = weeklySummary(d: d, now: now);
      expect(w, contains('Papa:'));
      expect(w, contains('Mummy:'));
    });
  });
}
