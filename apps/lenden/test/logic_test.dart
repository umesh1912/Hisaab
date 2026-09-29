import 'package:flutter_test/flutter_test.dart';
import 'package:lenden/logic.dart';
import 'package:lenden/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LendenStore> sampleStore() async {
  SharedPreferences.setMockInitialValues({});
  final s = LendenStore();
  await s.load();
  s.loadSample();
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('credits', () {
    test('sample balance and reserved credits', () {
      final d = sampleData();
      expect(balance(d.ledger), 4.5);
      expect(reserved(d.sessions, d.circles), 0);
      expect(taughtHours(d.ledger), 3.5);
      expect(learntHours(d.ledger), 1);
    });

    test('credit-paid lessons and circle seats are reserved', () {
      final d = sampleData();
      d.sessions.add(Session(
        id: 900,
        withId: 'sneha',
        dir: 'learn',
        skill: 'Spoken French',
        hrs: 1.5,
        date: addDaysIso(todayIso(), 2),
        time: '19:00',
        mode: 'Online',
        place: 'Video call',
        status: 'sent',
        pay: 'credits',
      ));
      d.circles.first.joined = true;
      expect(reserved(d.sessions, d.circles), 2.5);
      expect(freeCredits(d), 2);
    });

    test('hour formatting', () {
      expect(hrsText(1), '1');
      expect(hrsText(1.5), '1.5');
      expect(hrsText(-2), '2');
      expect(signedHrs(1.5), '+1.5');
      expect(signedHrs(-1), '−1');
    });
  });

  group('matching', () {
    final d = sampleData();
    Person p(String id) => d.person(id)!;

    test('two-way matches', () {
      expect(theyWantMine(p('vikram'), d.me), ['Excel & Google Sheets']);
      expect(iWantTheirs(p('vikram'), d.me), ['Acoustic guitar']);
      expect(isTwoWay(p('vikram'), d.me), isTrue);
      expect(isTwoWay(p('farhan'), d.me), isFalse);
      expect(theyWantMine(p('sneha'), d.me), ['Data analysis (SQL)']);
      expect(iWantTheirs(p('sneha'), d.me), isEmpty);
    });

    test('best matches come first', () {
      final list = discoverPeople(d, PeopleFilter());
      expect(list.length, 7);
      expect(isTwoWay(list.first, d.me), isTrue);
      expect(list.last.id, 'farhan');
    });

    test('filters', () {
      expect(discoverPeople(d, PeopleFilter(mutual: true)).every((x) => theyWantMine(x, d.me).isNotEmpty), isTrue);
      expect(discoverPeople(d, PeopleFilter(near: true)).map((x) => x.id).toSet(), {'vikram', 'lakshmi', 'deepa', 'ramesh'});
      expect(discoverPeople(d, PeopleFilter(online: true)).every((x) => x.online), isTrue);
      expect(discoverPeople(d, PeopleFilter(verified: true)).any((x) => x.id == 'arun'), isFalse);
      expect(discoverPeople(d, PeopleFilter(cat: 'music')).map((x) => x.id).toList(), ['vikram']);
      expect(discoverPeople(d, PeopleFilter(query: 'python')).map((x) => x.id).toList(), ['arun']);
      expect(discoverPeople(d, PeopleFilter(query: 'lakshmi')).map((x) => x.id).toList(), ['lakshmi']);
    });

    test('blocked people are hidden', () {
      final d2 = sampleData()..blocked.add('vikram');
      expect(discoverPeople(d2, PeopleFilter()).any((x) => x.id == 'vikram'), isFalse);
    });

    test('rating update', () {
      expect(newRating(5, 1, 3), 4);
      expect(newRating(4.8, 17, 5), closeTo(4.81, 0.001));
    });
  });

  group('dates and text', () {
    test('12-hour times', () {
      expect(t12('07:00'), '7 AM');
      expect(t12('18:30'), '6:30 PM');
      expect(t12('00:15'), '12:15 AM');
      expect(t12('12:00'), '12 PM');
    });

    test('next weekday is always in the future', () {
      expect(nextWeekday('2026-09-28', DateTime.sunday), '2026-10-04'); // a Monday
      expect(nextWeekday('2026-10-04', DateTime.sunday), '2026-10-11'); // a Sunday
      expect(daysBetween('2026-09-28', '2026-10-04'), 6);
      expect(addDaysIso('2026-12-31', 1), '2027-01-01');
    });

    test('message times', () {
      final now = DateTime(2026, 9, 28, 15, 0);
      expect(msgTime(DateTime(2026, 9, 28, 9, 5).toIso8601String(), now), '9:05 AM');
      expect(msgTime(DateTime(2026, 9, 27, 20, 0).toIso8601String(), now), 'Yesterday');
      expect(msgTime(DateTime(2026, 9, 21, 11, 0).toIso8601String(), now), '21 Sep');
    });

    test('check-in codes have four digits', () {
      for (var i = 0; i < 200; i++) {
        expect(checkInCode(i).length, 4);
      }
    });

    test('skill lists and phone numbers', () {
      expect(splitSkills(' Yoga, chess ,, yoga,Kannada '), ['Yoga', 'chess', 'Kannada']);
      expect(waNumber('+91 98765 43210'), '919876543210');
      expect(waNumber('09876543210'), '919876543210');
      expect(waNumber('123'), '');
    });

    test('ledger text drops brackets', () {
      final s = Session(
        id: 1,
        withId: 'arun',
        dir: 'teach',
        skill: 'Data analysis (SQL)',
        hrs: 1,
        date: '2026-09-26',
        time: '20:00',
        mode: 'Online',
        place: '',
        status: 'done',
      );
      expect(ledgerText(s, 'Arun'), 'Taught Data analysis to Arun');
    });
  });

  group('store flows', () {
    test('a swap request books both halves, and withdrawing removes both', () async {
      final store = await sampleStore();
      final n = store.data!.sessions.length;
      final err = store.sendRequest(
        personId: 'vikram',
        learn: 'Acoustic guitar',
        pay: 'swap',
        teach: 'Excel & Google Sheets',
        hrs: 1,
        mode: 'In person',
        place: 'Park',
        date: addDaysIso(todayIso(), 1),
        time: '07:00',
        message: 'Hi!',
      );
      expect(err, isNull);
      expect(store.data!.sessions.length, n + 2);
      final sent = store.data!.sessions.where((s) => s.status == 'sent').toList();
      expect(sent.length, 2);
      store.markAccepted(sent.last.id);
      expect(store.data!.sessions.where((s) => s.status == 'sent'), isEmpty);
      store.cancelSession(sent.first.id);
      expect(store.data!.sessions.length, n);
    });

    test('paying with credits needs free credits', () async {
      final store = await sampleStore();
      String? send(double hrs) => store.sendRequest(
            personId: 'sneha',
            learn: 'Spoken French',
            pay: 'credits',
            teach: '',
            hrs: hrs,
            mode: 'Online',
            place: 'Video call',
            date: addDaysIso(todayIso(), 2),
            time: '19:00',
            message: '',
          );
      expect(send(2), isNull);
      expect(send(2), isNull);
      expect(store.freeHrs, 0.5);
      expect(send(1), isNotNull);
    });

    test('accepting, finishing and rating a session', () async {
      final store = await sampleStore();
      final back = store.acceptIncoming(3);
      expect(back, isNotNull);
      expect(back!.skill, 'Yoga');
      expect(store.data!.session(3)!.status, 'confirmed');

      final before = store.balanceHrs;
      store.completeSession(3); // I teach Deepa for 1.5 hr
      expect(store.balanceHrs, before + 1.5);
      store.completeSession(3); // no double counting
      expect(store.balanceHrs, before + 1.5);

      final deepa = store.data!.person('deepa')!;
      final swaps = deepa.swaps;
      store.rateSession(3, 4, 'Keen learner');
      expect(store.data!.session(3)!.rated, isTrue);
      expect(deepa.swaps, swaps + 1);
      expect(deepa.reviews.first.text, 'Keen learner');
    });

    test('circle seats reserve then spend a credit', () async {
      final store = await sampleStore();
      final c = store.data!.circles.first;
      final taken = c.taken;
      expect(store.toggleCircle(c.id), isNull);
      expect(c.taken, taken + 1);
      expect(store.freeHrs, 3.5);
      store.attendCircle(c.id);
      expect(store.balanceHrs, 3.5);
      expect(store.freeHrs, 3.5);
    });

    test('blocking cancels open sessions but keeps history', () async {
      final store = await sampleStore();
      store.block('lakshmi');
      store.block('vikram');
      expect(store.data!.sessions.any((s) => s.withId == 'vikram'), isFalse);
      expect(store.data!.sessions.where((s) => s.withId == 'lakshmi').length, 2);
      store.unblock('vikram');
      expect(store.data!.blocked, ['lakshmi']);
    });

    test('messages and unread counts', () async {
      final store = await sampleStore();
      expect(store.unreadThreads, 2);
      store.markRead('vikram');
      expect(store.unreadThreads, 1);
      store.sendMessage('ramesh', 'Is there a seat left?');
      expect(store.data!.threads['ramesh']!.length, 1);
    });

    test('skills cannot be added twice', () async {
      final store = await sampleStore();
      expect(store.addTeach('excel & google sheets', 'tech', 'Good'), isNotNull);
      expect(store.addTeach('Public speaking', 'create', 'Good'), isNull);
      expect(store.addLearn('yoga'), isNotNull);
      store.removeLearn('Yoga');
      expect(store.addLearn('Yoga'), isNull);
    });
  });

  test('sample data survives a save and load', () {
    final d = sampleData();
    final back = AppData.fromJson(d.toJson());
    expect(back.people.length, 7);
    expect(back.sessions.length, d.sessions.length);
    expect(back.sessions.firstWhere((s) => s.id == 3).hrs, 1.5);
    expect(back.threads['vikram']!.length, 3);
    expect(balance(back.ledger), balance(d.ledger));
    expect(back.people.firstWhere((p) => p.id == 'sneha').km, isNull);
  });
}
