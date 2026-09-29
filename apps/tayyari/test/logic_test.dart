import 'package:flutter_test/flutter_test.dart';
import 'package:tayyari/bank.dart';
import 'package:tayyari/logic.dart';
import 'package:tayyari/store.dart';

void main() {
  group('question bank', () {
    test('25 valid questions in every section, unique ids', () {
      expect(bank.map((q) => q.id).toSet().length, bank.length);
      for (final s in sectionKeys) {
        expect(bank.where((q) => q.sec == s).length, questionsPerSection, reason: s);
      }
      for (final q in bank) {
        expect(q.o.length, 4, reason: 'q${q.id}');
        expect(q.o.toSet().length, 4, reason: 'q${q.id} has duplicate options');
        expect(q.a, inInclusiveRange(0, 3), reason: 'q${q.id}');
        expect(syllabus[q.sec], contains(q.topic), reason: 'q${q.id} topic');
        if (q.ohi != null) expect(q.ohi!.length, 4, reason: 'q${q.id} hindi options');
      }
    });

    test('every General Awareness question has Hindi', () {
      expect(bank.where((q) => q.sec == 'ga').every((q) => q.hasHindi && q.exhi != null), isTrue);
    });
  });

  group('scheduler', () {
    test('wrong answers come back tomorrow and count a lapse', () {
      final c = CardState(due: '2026-09-01', ivl: 10, reps: 4);
      final r = schedule(c, 4, false);
      expect(r.ivl, 1);
      expect(r.lapses, 1);
      expect(r.ease, closeTo(2.3, 1e-9));
    });

    test('intervals grow with correct answers', () {
      final c = CardState(due: '2026-09-01');
      applyReview(c, 3, true, '2026-09-01');
      expect(c.ivl, 1);
      applyReview(c, 3, true, '2026-09-02');
      expect(c.ivl, 3);
      applyReview(c, 3, true, '2026-09-05');
      expect(c.ivl, 8); // 3 × 2.5 = 7.5 → 8
      expect(c.due, '2026-09-13');
      applyReview(c, 4, true, '2026-09-13');
      expect(c.ivl, greaterThan(20));
    });

    test('hard gives a shorter interval than easy', () {
      final c = CardState(due: '2026-09-01', ivl: 10, reps: 3);
      expect(schedule(c, 2, true).ivl, lessThan(schedule(c, 3, true).ivl));
      expect(schedule(c, 3, true).ivl, lessThan(schedule(c, 4, true).ivl));
    });

    test('confident mistakes are flagged', () {
      final c = CardState(due: '2026-09-01', ivl: 5, reps: 2);
      applyReview(c, 3, false, '2026-09-01', certain: true);
      expect(c.confidentMiss, isTrue);
      expect(c.reps, 0);
      expect(c.due, '2026-09-02');
    });

    test('due lists include overdue cards', () {
      final cards = {
        1: CardState(due: '2026-09-10'),
        2: CardState(due: '2026-09-08'),
        3: CardState(due: '2026-09-12'),
        4: CardState(due: '2026-09-20'),
      };
      expect(dueIds(cards, '2026-09-10'), [2, 1]);
      expect(dueCounts(cards, '2026-09-10'), [2, 0, 1, 0, 0, 0, 0]);
      expect(intervalLabel(1), 'tomorrow');
      expect(intervalLabel(12), '12 days');
      expect(intervalLabel(60), '2 mo');
    });
  });

  group('negative marking', () {
    test('a blind guess among four options gains marks on average', () {
      expect(guessValue(4), closeTo(0.125, 1e-9));
      expect(guessValue(3), closeTo(1 / 3, 1e-9));
      expect(guessValue(2), closeTo(0.75, 1e-9));
      expect(guessValue(4), greaterThan(0));
    });

    test('scoreTest applies +2 / -0.5 and finds confident mistakes', () {
      final qs = bank.where((q) => q.sec == 'quant').take(4).toList();
      final answers = {
        qs[0].id: qs[0].a, // right
        qs[1].id: (qs[1].a + 1) % 4, // wrong, certain
        qs[2].id: (qs[2].a + 1) % 4, // wrong, guessing
      }; // qs[3] skipped
      final r = scoreTest(
        id: 1,
        name: 'T',
        date: '2026-09-01',
        kind: 'sectional',
        questions: qs,
        answers: answers,
        sure: {qs[1].id: 2, qs[2].id: 0},
      );
      expect(r.right, 1);
      expect(r.wrong, 2);
      expect(r.skipped, 1);
      expect(r.score, 1.0);
      expect(r.negative, 1.0);
      expect(r.maxMarks, 8.0);
      expect(r.confidentWrong, 1);
      expect(r.sections.keys.toList(), ['quant']);
    });

    test('marks format', () {
      expect(fmtMarks(142.5), '142.5');
      expect(fmtMarks(142), '142');
      expect(fmtMarks(-1.5), '-1.5');
      expect(fmtClock(905), '15:05');
    });
  });

  group('mastery', () {
    test('no answers means 50%, and recent answers count more', () {
      expect(mastery(null), 0.5);
      final s = TopicStat();
      for (var i = 0; i < 10; i++) {
        recordAnswer(s, true);
      }
      final high = mastery(s);
      expect(high, greaterThan(0.8));
      recordAnswer(s, false);
      recordAnswer(s, false);
      expect(mastery(s), lessThan(high));
    });

    test('seedEwma reproduces the target percentage', () {
      for (final p in [39, 52, 78, 91]) {
        final s = TopicStat(ewma: seedEwma(p / 100, 30), n: 30);
        expect(pct(mastery(s)), p);
      }
    });

    test('weakest topic comes from the weakest section', () {
      final stats = {
        topicKey('quant', 'Geometry'): TopicStat(ewma: 0.3, n: 20),
        topicKey('ga', 'Static GK'): TopicStat(ewma: 0.1, n: 20),
        topicKey('ga', 'Polity'): TopicStat(ewma: 0.9, n: 20),
      };
      final w = weakestOverall(stats);
      expect(w.sec, 'quant');
      expect(w.topic, 'Geometry');
      expect(sectionMastery(stats, 'eng'), isNull);
    });
  });

  group('study log', () {
    test('streak counts back from yesterday when today is empty', () {
      final m = {'2026-09-07': 30, '2026-09-08': 60, '2026-09-09': 20};
      expect(streak(m, '2026-09-10'), 3);
      expect(streak(m, '2026-09-09'), 3);
      expect(streak(m, '2026-09-12'), 0);
      expect(heatLevel(0), 0);
      expect(heatLevel(50), 1);
      expect(heatLevel(230), 4);
    });
  });

  test('sample data matches its story and survives a save and load', () {
    final d = sampleData();
    final back = AppData.fromJson(d.toJson());
    expect(back.profile.name, 'Aman');
    expect(back.cards.length, d.cards.length);
    expect(back.custom.length, 7);
    expect(back.mocks.length, 5);
    final m7 = back.mocks.firstWhere((m) => m.name == 'Mock 7');
    expect(m7.score, 142.5);
    expect(m7.isFull, isTrue);
    for (final m in back.mocks) {
      for (final s in m.sections.values) {
        expect(s.total, questionsPerSection);
        expect(s.skipped, greaterThanOrEqualTo(0));
      }
    }
    expect(streak(back.minutes, todayIso()), 13);
    expect(pct(mastery(back.stats[topicKey('ga', 'Static GK')])), 39);
  });

  test('scored test survives a save and load', () {
    final qs = bank.take(3).toList();
    final r = scoreTest(id: 5, name: 'X', date: '2026-09-01', kind: 'sectional', questions: qs, answers: {qs[0].id: 1}, sure: {qs[0].id: 2});
    final back = MockResult.fromJson(r.toJson());
    expect(back.answers, r.answers);
    expect(back.sure, r.sure);
    expect(back.qids, r.qids);
    expect(back.score, r.score);
  });
}
