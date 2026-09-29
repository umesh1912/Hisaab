import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:galli/logic.dart';
import 'package:galli/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Post alert({int id = 1, int yes = 0, int no = 0, bool official = false, int? expiresAt, int at = 0}) => Post(
      id: id,
      type: 'alert',
      cat: 'Power',
      title: 'No power',
      body: '',
      by: 'Neighbour',
      km: 0.4,
      x: 200,
      y: 150,
      at: at,
      yes: yes,
      no: no,
      official: official,
      expiresAt: expiresAt,
    );

Post simple(int id, String type, String title, {double km = 0.5, int at = 0, String cat = 'Pet'}) => Post(
      id: id,
      type: type,
      cat: cat,
      title: title,
      body: '',
      by: 'Neighbour',
      km: km,
      x: 100,
      y: 100,
      at: at,
    );

void main() {
  group('alerts', () {
    test('status moves from unverified to confirmed', () {
      final p = alert(yes: 4, no: 1);
      expect(alertStatus(p), 'unverified');
      applyVote(p, 'yes');
      expect(p.yes, 5);
      expect(alertStatus(p), 'confirmed');
      expect(alertStatus(alert(official: true)), 'official');
      expect(alertStatus(alert(yes: 5, no: 3)), 'unverified'); // not more than twice the "over" votes
    });

    test('votes count once and can be changed', () {
      final p = alert(yes: 2, no: 0);
      expect(applyVote(p, 'yes'), isTrue);
      expect(applyVote(p, 'yes'), isFalse);
      expect(p.yes, 3);
      expect(applyVote(p, 'no'), isFalse); // changed, not first
      expect(p.yes, 2);
      expect(p.no, 1);
      expect(p.myVote, 'no');
    });

    test('alerts close when most say over, or when they expire', () {
      expect(closedByVotes(alert(yes: 1, no: 3)), isTrue);
      expect(closedByVotes(alert(yes: 4, no: 3)), isFalse);
      final now = 10 * dayMs;
      expect(isEnded(alert(expiresAt: now - 1), now), isTrue);
      expect(isEnded(alert(expiresAt: now + hourMs), now), isFalse);
      expect(isEnded(alert(yes: 0, no: 3, expiresAt: now + hourMs), now), isTrue);
    });

    test('lost posts last 14 days, help posts 7', () {
      final now = 30 * dayMs;
      expect(isEnded(simple(1, 'lost', 'x', at: now - 13 * dayMs), now), isFalse);
      expect(isEnded(simple(1, 'lost', 'x', at: now - 15 * dayMs), now), isTrue);
      expect(isEnded(simple(1, 'help', 'x', at: now - 8 * dayMs), now), isTrue);
    });
  });

  group('lists', () {
    test('feed filters by radius, type and hidden, newest first', () {
      final now = 5 * dayMs;
      final a = simple(1, 'help', 'Near', km: 0.4, at: now - 100);
      final b = simple(2, 'help', 'Far', km: 1.6, at: now - 50);
      final c = simple(3, 'notice', 'Newer', km: 0.9, at: now - 10);
      final h = simple(4, 'help', 'Hidden', km: 0.2, at: now)..hidden = true;
      final all = [a, b, c, h];
      expect(feedPosts(all, 1, 'all', now).map((p) => p.id).toList(), [3, 1]);
      expect(feedPosts(all, 2, 'help', now).map((p) => p.id).toList(), [2, 1]);
      expect(feedPosts(all, 0.5, 'all', now).map((p) => p.id).toList(), [1]);
    });

    test('live alert count only counts recent alerts', () {
      final now = 5 * dayMs;
      final list = [alert(id: 1, at: now - 30 * minuteMs), alert(id: 2, at: now - 3 * hourMs)];
      expect(liveAlertCount(list, now), 1);
    });
  });

  group('matching', () {
    test('keywords drop filler words', () {
      expect(keywords('Lost dog: Bruno, brown indie, red collar'), {'dog', 'bruno', 'brown', 'indie', 'red', 'collar'});
    });

    test('a found dog matches the lost dog', () {
      final lost = simple(2, 'lost', 'Lost dog: Bruno, brown indie, red collar', at: 100);
      final found = simple(9, 'found', 'Found: brown dog with red collar at Kothrud depot', at: 200, km: 1.6);
      final wallet = simple(5, 'found', 'Found: black wallet near bus stop', at: 200, cat: 'Item');
      expect(matchScore(lost, found), 4);
      expect(matchScore(lost, wallet), 0);
      final m = possibleMatches([lost, found, wallet], 300);
      expect(m.length, 1);
      expect(m.first.key, '2-9');
    });

    test('found before lost is not a match', () {
      final lost = simple(2, 'lost', 'Lost dog brown red collar', at: 500);
      final found = simple(9, 'found', 'Found dog brown red collar', at: 100);
      expect(matchScore(lost, found), 0);
    });
  });

  group('map', () {
    test('pins land at the right distance and inside the map', () {
      for (var id = 0; id < 40; id++) {
        final pt = placeOnMap(0.5, id);
        expect(pt.x, inInclusiveRange(14, mapW - 14));
        expect(pt.y, inInclusiveRange(14, mapH - 14));
        final dist = math.sqrt(math.pow(pt.x - youX, 2) + math.pow(pt.y - youY, 2));
        expect(dist, closeTo(55, 0.01));
      }
      final far = placeOnMap(5, 3);
      expect(far.x, inInclusiveRange(14, mapW - 14));
      expect(far.y, inInclusiveRange(14, mapH - 14));
    });

    test('next sighting is near the last one', () {
      final p = simple(2, 'lost', 'x')..sightings.add(Sighting(text: 'a', at: 0, x: 150, y: 120));
      final n = nextSightingPoint(p);
      final dist = math.sqrt(math.pow(n.x - 150, 2) + math.pow(n.y - 120, 2));
      expect(dist, lessThanOrEqualTo(24.01));
    });
  });

  group('text', () {
    test('ago', () {
      expect(ago(1000000, 1000000), 'just now');
      expect(ago(100 * minuteMs, 60 * minuteMs), '40 min ago');
      expect(ago(10 * hourMs, 5 * hourMs), '5 h ago');
      expect(ago(3 * dayMs, 0), '3 d ago');
    });

    test('distances', () {
      expect(kmText(0.4), '0.4 km');
      expect(kmText(1.0), '1 km');
      expect(kmText(1.6), '1.6 km');
      expect(radiusLabel(0.5), '500 m');
      expect(radiusLabel(2), '2 km');
    });

    test('ends labels', () {
      final now = DateTime(2026, 9, 29, 17).millisecondsSinceEpoch;
      expect(endsLabel(now, DateTime(2026, 9, 29, 22).millisecondsSinceEpoch), '10 PM');
      expect(endsLabel(now, DateTime(2026, 9, 29, 21, 30).millisecondsSinceEpoch), '9:30 PM');
      expect(endsLabel(now, DateTime(2026, 9, 30, 16).millisecondsSinceEpoch), 'Tomorrow 4 PM');
      expect(endsLabel(now, DateTime(2026, 10, 3, 0).millisecondsSinceEpoch), '3 Oct 12 AM');
    });

    test('short titles and links', () {
      expect(shortTitle('Lost dog: Bruno, brown indie, red collar', 40), 'Bruno, brown indie, red collar');
      expect(shortTitle('Found: black wallet near Dahanukar bus stop', 12), 'black walle…');
      expect(mapsUrl('Kothrud depot', 'Pune'), contains('query=Kothrud%20depot%2C%20Pune'));
      expect(whatsappUrl('a b'), 'https://wa.me/?text=a%20b');
    });
  });

  test('sample data survives a save and load', () {
    final d = sampleData();
    final back = AppData.fromJson(d.toJson());
    expect(back.posts.length, d.posts.length);
    expect(back.post(2)!.sightings.length, 2);
    expect(back.post(1)!.km, 0.4);
    expect(back.threads.first.unread, isTrue);
    expect(back.prefs['help'], isFalse);
    expect(back.radius, 1.0);
  });

  group('store', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    Future<GalliStore> fresh() async {
      SharedPreferences.setMockInitialValues({});
      final s = GalliStore();
      await s.load();
      s.loadSample();
      return s;
    }

    test('fifth confirmation marks the power cut as confirmed', () async {
      final s = await fresh();
      final msg = s.vote(1, 'yes');
      expect(msg, contains('confirmed'));
      expect(alertStatus(s.data!.post(1)!), 'confirmed');
      expect(s.data!.points, 43);
    });

    test('publishing far away widens the radius', () async {
      final s = await fresh();
      final widened = s.publish(
        type: 'found',
        cat: 'Item',
        title: 'Found: blue school bag near Vanaz metro',
        body: 'Class 5 books inside',
        place: 'Vanaz metro',
        km: 2,
        expiresHours: 6,
        reward: '',
      );
      expect(widened, isTrue);
      expect(s.data!.radius, 2.0);
      expect(s.data!.posts.last.mine, isTrue);
    });

    test('telling the owner adds a message and points', () async {
      final s = await fresh();
      final before = s.data!.thread(1)!.msgs.length;
      s.tellOwner(2, 9);
      expect(s.data!.thread(1)!.msgs.length, before + 1);
      expect(s.data!.told, contains('2-9'));
      expect(s.data!.points, 47);
    });

    test('claiming creates a thread, deleting a post removes it', () async {
      final s = await fresh();
      final tid = s.claim(5, 'Black leather, my PAN card inside');
      expect(s.data!.thread(tid), isNotNull);
      s.deletePost(5);
      expect(s.data!.thread(tid), isNull);
    });
  });
}
