import 'package:flutter_test/flutter_test.dart';
import 'package:jodi/logic.dart';
import 'package:jodi/store.dart';

const every = [true, true, true, true, true, true, true];

Habit habit(int id, List<String> doneDates, {String createdOn = '2026-09-07', List<bool> days = every, String owner = me}) => Habit(
      id: id,
      owner: owner,
      name: 'H$id',
      cue: 'After dinner',
      days: List.of(days),
      createdOn: createdOn,
      log: {for (final d in doneDates) d: CheckIn(at: '20:00')},
    );

void main() {
  group('dates', () {
    test('day arithmetic across months and years', () {
      expect(addDaysIso('2026-09-30', 1), '2026-10-01');
      expect(addDaysIso('2026-12-31', 1), '2027-01-01');
      expect(addDaysIso('2026-03-01', -1), '2026-02-28');
      expect(daysBetween('2026-09-07', '2026-09-28'), 21);
    });

    test('weeks start on Monday', () {
      expect(weekdayIndex('2026-09-28'), 0); // Monday
      expect(weekStartIso('2026-10-04'), '2026-09-28'); // Sunday -> Monday
      expect(weekStartIso('2026-09-28'), '2026-09-28');
      expect(daysLeftInWeek('2026-10-04'), 0);
    });

    test('heat map covers 8 full weeks ending this week', () {
      final h = heatDates('2026-09-30');
      expect(h.length, 56);
      expect(weekdayIndex(h.first), 0);
      expect(h.last, '2026-10-04');
    });

    test('12-hour time', () {
      expect(t12('16:10'), '4:10 PM');
      expect(t12('00:05'), '12:05 AM');
      expect(t12('12:00'), '12:00 PM');
      expect(whenText('2026-09-28', '07:40', '2026-09-28'), '7:40 AM');
      expect(whenText('2026-09-27', '07:40', '2026-09-28'), 'Yesterday');
    });

    test('week together', () {
      expect(weekTogether('2026-09-28', '2026-09-28'), 1);
      expect(weekTogether('2026-08-21', '2026-09-28'), 6);
    });
  });

  group('never miss twice', () {
    test('first miss of the week is a skip, the second breaks the streak', () {
      final h = habit(1, ['2026-09-07', '2026-09-09', '2026-09-11']);
      final s = dayStates([h], '2026-09-11', [])[1]!;
      expect(s['2026-09-08'], DayState.skip);
      expect(s['2026-09-10'], DayState.miss);
      expect(currentStreak(s, '2026-09-11'), 1);
      expect(bestStreak(s), 2);
      expect(successRate(s), 60);
    });

    test('a single skip keeps the streak alive', () {
      final h = habit(1, ['2026-09-07', '2026-09-09', '2026-09-10', '2026-09-11']);
      final s = dayStates([h], '2026-09-11', [])[1]!;
      expect(currentStreak(s, '2026-09-11'), 4);
    });

    test('today not done yet does not break the streak', () {
      final h = habit(1, ['2026-09-07', '2026-09-08']);
      final s = dayStates([h], '2026-09-09', [])[1]!;
      expect(s['2026-09-09'], DayState.pending);
      expect(currentStreak(s, '2026-09-09'), 2);
    });

    test('the weekly skip is shared across a person\'s habits', () {
      final a = habit(1, ['2026-09-07']);
      final b = habit(2, ['2026-09-07']);
      final s = dayStates([b, a], '2026-09-09', []);
      expect(s[1]!['2026-09-08'], DayState.skip);
      expect(s[2]!['2026-09-08'], DayState.miss);
      expect(skipsLeft(s, '2026-09-09'), 0);
    });

    test('a new week brings a new skip', () {
      final h = habit(1, ['2026-09-07', '2026-09-09', '2026-09-10', '2026-09-11', '2026-09-12', '2026-09-13']);
      final s = dayStates([h], '2026-09-15', []);
      expect(s[1]!['2026-09-14'], DayState.skip);
      expect(skipsLeft(s, '2026-09-15'), 0);
      expect(skipsLeft(dayStates([h], '2026-09-13', []), '2026-09-13'), 0);
    });

    test('rest days and paused days do not count', () {
      final h = habit(1, ['2026-09-07', '2026-09-09'], days: [true, false, true, false, true, false, false]);
      final s = dayStates([h], '2026-09-11', [])[1]!;
      expect(s['2026-09-08'], DayState.rest);
      expect(s['2026-09-11'], DayState.pending);
      expect(currentStreak(s, '2026-09-11'), 2);
      final paused = dayStates([habit(2, ['2026-09-07', '2026-09-09', '2026-09-11'])], '2026-09-11', [Pause(from: '2026-09-08', to: '2026-09-10')])[2]!;
      expect(paused['2026-09-08'], DayState.rest);
      expect(paused['2026-09-09'], DayState.done);
      expect(paused['2026-09-10'], DayState.skip);
      expect(currentStreak(paused, '2026-09-11'), 3);
      expect(isPausedOn('2026-09-10', [Pause(from: '2026-09-08')]), isTrue);
    });

    test('habits added later start counting from their first day', () {
      final h = habit(1, [], createdOn: '2026-09-10');
      final s = dayStates([h], '2026-09-10', [])[1]!;
      expect(s.length, 1);
      expect(s['2026-09-10'], DayState.pending);
    });
  });

  group('week score and pact', () {
    test('counts the whole week, skips excluded', () {
      final h = habit(1, ['2026-09-07', '2026-09-09', '2026-09-11']);
      final states = dayStates([h], '2026-09-11', []);
      final w = weekScore([h], states, '2026-09-11', []);
      expect(w.done, 3);
      expect(w.of, 6);
      expect(w.pct, 50);
    });

    test('verdicts', () {
      expect(pactVerdict(const WeekScore(9, 10), const WeekScore(8, 10), 80, 'Tara'), 'You are both at 80% or more');
      expect(pactVerdict(const WeekScore(5, 10), const WeekScore(9, 10), 80, 'Tara'), 'You are below 80% so far');
      expect(pactVerdict(const WeekScore(9, 10), const WeekScore(5, 10), 80, 'Tara'), 'Tara is below 80% so far');
      expect(percent(1, 0), 0);
    });

    test('one nudge per habit per day', () {
      final n = [Nudge(habitId: 5, date: '2026-09-28', message: 'Go')];
      expect(canNudge(n, 5, '2026-09-28'), isFalse);
      expect(canNudge(n, 5, '2026-09-29'), isTrue);
      expect(canNudge(n, 6, '2026-09-28'), isTrue);
    });
  });

  group('habit wording', () {
    test('cues become plans', () {
      expect(normalizeCue('brush my teeth at night'), 'After I brush my teeth at night');
      expect(normalizeCue('after dinner'), 'After dinner');
      expect(normalizeCue('  '), '');
      expect(cueBody('After I brush my teeth'), 'brush my teeth');
      expect(cueBody('After dinner'), 'After dinner');
      expect(planText('After I brush my teeth at night', 'Floss'), 'After I brush my teeth at night, I will floss.');
    });

    test('days text', () {
      expect(daysText(every), 'Every day');
      expect(daysText([true, true, true, true, true, false, false]), 'Weekdays');
      expect(daysText([false, false, false, false, false, true, true]), 'Weekends');
      expect(daysText([true, false, true, false, false, false, false]), 'Mon, Wed');
    });
  });

  group('sample and simulation', () {
    test('pseudo history is deterministic', () {
      expect(pseudoHistory(3, .86, 20), pseudoHistory(3, .86, 20));
    });

    test('fillHistory leaves a recent streak', () {
      final h = habit(1, [], createdOn: '2026-08-01');
      fillHistory(h, '2026-09-28', seed: 7, rate: .5, recentRun: 5);
      final s = dayStates([h], '2026-09-28', [])[1]!;
      expect(currentStreak(s, '2026-09-28'), greaterThanOrEqualTo(5));
      expect(h.log.containsKey('2026-09-28'), isFalse);
    });

    test('partner simulation runs once per day', () {
      final d = sampleData();
      final t = todayIso();
      expect(simulatePartner(d, t), isFalse); // already simulated up to yesterday
      d.simulatedTo = addDaysIso(t, -4);
      final feedBefore = d.feed.length;
      expect(simulatePartner(d, t), isTrue);
      expect(d.simulatedTo, addDaysIso(t, -1));
      expect(d.feed.length, greaterThan(feedBefore));
      expect(simulatePartner(d, t), isFalse);
    });

    test('sample data survives a save and load', () {
      final d = sampleData();
      final back = AppData.fromJson(d.toJson());
      expect(back.meName, 'Ishaan');
      expect(back.habits.length, 6);
      expect(back.habitsOf(them).length, 3);
      expect(back.habits.first.log.length, d.habits.first.log.length);
      expect(back.reflections.length, d.reflections.length);
      final t = todayIso();
      final meditate = back.habit(4)!;
      expect(meditate.log[t]?.note, 'Rough morning, this helped.');
      final s = dayStates(back.habitsOf(me), t, back.pauses);
      expect(currentStreak(s[1]!, t), greaterThanOrEqualTo(12));
    });
  });
}
