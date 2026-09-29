import 'package:flutter_test/flutter_test.dart';
import 'package:hariyali/logic.dart';
import 'package:hariyali/store.dart';

Plant plant({int id = 1, String exposure = 'indoor', int every = 2, required String last, String? nextCheck}) =>
    Plant(id: id, name: 'P$id', place: 'Balcony', exposure: exposure, every: every, last: last, nextCheck: nextCheck);

void main() {
  const today = '2026-09-28';

  group('watering plan', () {
    test('due today when the interval has passed', () {
      final p = plant(last: '2026-09-26');
      final r = planFor(p, today: today, season: 'summer');
      expect(r.kind, 'water');
      expect(r.reason, 'Due today');
    });

    test('overdue days are counted', () {
      final r = planFor(plant(last: '2026-09-23'), today: today, season: 'summer');
      expect(r.kind, 'water');
      expect(r.reason, startsWith('3 days overdue'));
    });

    test('later when not yet due', () {
      final r = planFor(plant(every: 6, last: '2026-09-24'), today: today, season: 'summer');
      expect(r.kind, 'later');
      expect(r.days, 2);
    });

    test('open plants are skipped when rain is expected, covered ones are not', () {
      final w = Weather(date: today, rain: true);
      final open = planFor(plant(exposure: 'open', last: '2026-09-26'), today: today, season: 'summer', weather: w);
      final covered = planFor(plant(exposure: 'covered', last: '2026-09-26'), today: today, season: 'summer', weather: w);
      expect(open.kind, 'skip');
      expect(covered.kind, 'water');
    });

    test('weather from another day is ignored', () {
      final w = Weather(date: '2026-09-27', rain: true, hot: true);
      final r = planFor(plant(exposure: 'open', last: '2026-09-26'), today: today, season: 'summer', weather: w);
      expect(r.kind, 'water');
      expect(r.reason, 'Due today');
    });

    test('hot day tip only for plants outside', () {
      final w = Weather(date: today, hot: true);
      final out = planFor(plant(exposure: 'covered', last: '2026-09-26'), today: today, season: 'summer', weather: w);
      final inside = planFor(plant(exposure: 'indoor', last: '2026-09-26'), today: today, season: 'summer', weather: w);
      expect(out.reason, contains('evening'));
      expect(inside.reason, isNot(contains('evening')));
    });

    test('events today mark the plant done', () {
      final p = plant(last: today);
      final r = planFor(p, today: today, season: 'summer', events: [CareEvent(plantId: 1, type: 'water', date: today)]);
      expect(r.kind, 'done');
    });

    test('damp soil check pushes the next check', () {
      final p = plant(last: '2026-09-26', nextCheck: '2026-09-30');
      expect(nextDue(p, 'summer'), '2026-09-30');
      expect(planFor(p, today: today, season: 'summer').kind, 'later');
    });
  });

  group('seasons and learning', () {
    test('monsoon and winter stretch intervals', () {
      expect(effectiveEvery(10, 'summer'), 10);
      expect(effectiveEvery(10, 'monsoon'), 13);
      expect(effectiveEvery(10, 'winter'), 15);
      expect(effectiveEvery(1, 'summer'), 1);
    });

    test('soil answers adjust the interval within bounds', () {
      expect(learnFromSoil(6, 'dry'), 6);
      expect(learnFromSoil(6, 'damp'), 7);
      expect(learnFromSoil(20, 'damp'), 23);
      expect(learnFromSoil(60, 'damp'), 60);
      expect(learnFromSoil(6, 'very_dry'), 5);
      expect(learnFromSoil(1, 'very_dry'), 1);
    });

    test('water level runs from full to empty', () {
      expect(waterLevel(plant(every: 4, last: today), today, 'summer'), 1.0);
      expect(waterLevel(plant(every: 4, last: '2026-09-26'), today, 'summer'), 0.5);
      expect(waterLevel(plant(every: 4, last: '2026-09-01'), today, 'summer'), 0.0);
    });

    test('feeding and treatment due dates', () {
      final p = plant(last: today)
        ..feedEvery = 30
        ..lastFed = '2026-08-29';
      expect(feedDue(p, today), isTrue);
      p.lastFed = '2026-09-20';
      expect(feedDue(p, today), isFalse);
      p
        ..treatEvery = 6
        ..treatNext = today
        ..treatUntil = '2026-10-26';
      expect(treatDue(p, today), isTrue);
      p.treatNext = '2026-10-04';
      expect(treatDue(p, today), isFalse);
    });
  });

  group('away notes', () {
    test('watering dates assume a full watering the day before', () {
      final p = plant(every: 2, last: today);
      expect(wateringDates(p, '2026-10-09', '2026-10-14', 'summer'), ['2026-10-10', '2026-10-12', '2026-10-14']);
      expect(wateringDates(plant(every: 14, last: today), '2026-10-09', '2026-10-14', 'summer'), isEmpty);
      expect(wateringDates(plant(every: 1, last: today), '2026-10-09', '2026-10-11', 'summer').length, 3);
    });

    test('care note lists daily, dated and no-water plants', () {
      final plants = [
        Plant(id: 1, name: 'Chilli', place: 'Balcony', exposure: 'open', every: 1, last: today),
        Plant(id: 2, name: 'Money plant', place: 'Hall', every: 3, last: today),
        Plant(id: 3, name: 'Snake plant', place: 'Bedroom', every: 14, last: today),
      ];
      final trip = Trip(from: '2026-10-09', to: '2026-10-14', helper: 'Lakshmi aunty');
      final en = careNote(plants: plants, trip: trip, season: 'summer', owner: 'Meenakshi');
      expect(en, contains('Hi Lakshmi aunty'));
      expect(en, contains('Every evening: Chilli.'));
      expect(en, contains('Money plant: water on 11 Oct, 14 Oct.'));
      expect(en, contains('No water needed: Snake plant.'));
      expect(en, contains('skip any day it rains'));
      trip.lang = 'ta';
      final ta = careNote(plants: plants, trip: trip, season: 'summer', owner: 'Meenakshi');
      expect(ta, contains('வணக்கம் Lakshmi aunty'));
      expect(ta, contains('அக்டோபர்'));
      expect(ta, contains('தண்ணீர் வேண்டாம்: Snake plant.'));
    });
  });

  group('library and problems', () {
    test('search finds plants by common, Indian and scientific names', () {
      expect(searchLibrary('pothos').map((s) => s.id), contains('money_plant'));
      expect(searchLibrary('KARUVEPPILAI').map((s) => s.id), contains('curry_leaf'));
      expect(searchLibrary('crassula').single.id, 'jade_plant');
      expect(searchLibrary('').length, plantLibrary.length);
      expect(searchLibrary('zzzz'), isEmpty);
    });

    test('library entries are sane', () {
      final ids = <String>{};
      for (final s in plantLibrary) {
        expect(ids.add(s.id), isTrue, reason: 'duplicate id ${s.id}');
        expect(s.every, inInclusiveRange(1, 30));
        expect(petLabels.containsKey(s.pet), isTrue);
        expect(lightLabels.containsKey(s.light), isTrue);
        expect(exposures.containsKey(s.exposure), isTrue);
      }
      expect(speciesById('snake_plant')?.pet, 'toxic');
    });

    test('symptoms rank the best match first', () {
      final m = matchProblems({'white_cotton', 'sticky'});
      expect(m.first.problem.id, 'mealybugs');
      expect(m.first.score, 2);
      expect(matchProblems({'wilt_wet', 'mushy'}).first.problem.id, 'overwatering');
      expect(matchProblems({}), isEmpty);
    });

    test('every problem symptom exists and treatments are complete', () {
      for (final p in problems) {
        for (final s in p.symptoms) {
          expect(symptoms.containsKey(s), isTrue, reason: '${p.id} uses unknown symptom $s');
        }
        if (p.repeatDays > 0) {
          expect(p.treatment, isNotEmpty);
          expect(p.courseDays, greaterThan(p.repeatDays));
        }
      }
    });
  });

  group('dates', () {
    test('adding days crosses months and years', () {
      expect(addDaysIso('2026-09-30', 1), '2026-10-01');
      expect(addDaysIso('2026-12-31', 1), '2027-01-01');
      expect(addDaysIso('2026-03-01', -1), '2026-02-28');
      expect(daysBetween('2026-09-28', '2026-10-04'), 6);
      expect(relDay('2026-09-28', '2026-09-29'), 'tomorrow');
      expect(tamilDate('2026-10-11'), '11 அக்டோபர்');
    });
  });

  test('sample data survives a save and load', () {
    final d = sampleData();
    final back = AppData.fromJson(d.toJson());
    expect(back.plants.length, 8);
    expect(back.trip?.helper, 'Lakshmi aunty');
    expect(back.weather?.rain, isTrue);
    expect(back.events.length, d.events.length);
    final t = todayIso();
    final kinds = back.plants.map((p) => planFor(p, today: t, season: back.season, weather: back.weather, events: back.events).kind).toList();
    expect(kinds.where((k) => k == 'water').length, 2);
    expect(kinds.where((k) => k == 'skip').length, 3);
  });
}
