import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart';

/// Holds the app state, saves it on the phone, and exposes actions.
class GalliStore extends ChangeNotifier {
  static const _key = 'galli_data_v1';
  AppData? data;
  bool loaded = false;

  int get now => DateTime.now().millisecondsSinceEpoch;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) data = AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      data = null; // corrupt data: start fresh rather than crash
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final d = data;
    final prefs = await SharedPreferences.getInstance();
    if (d == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, jsonEncode(d.toJson()));
    }
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  // ---------- setup ----------
  void setup({required String name, required String locality, required double radius}) {
    data = AppData(
      name: name,
      locality: locality,
      radius: radius,
      areas: [Area(name: 'Home · $locality', radiusKm: radius)],
    );
    _changed();
  }

  void loadSample() {
    data = sampleData();
    _changed();
  }

  void resetAll() {
    data = null;
    _changed();
  }

  void updateProfile(String name, String locality) {
    final d = data!;
    if (name.trim().isNotEmpty) d.name = name.trim();
    if (locality.trim().isNotEmpty) d.locality = locality.trim();
    _changed();
  }

  // ---------- derived ----------
  int get unreadThreads => data?.threads.where((t) => t.unread).length ?? 0;

  List<Notif> get visibleNotifs {
    final d = data;
    if (d == null) return [];
    return d.notifs.where((n) => d.prefs[n.type] ?? true).toList()..sort((a, b) => b.at.compareTo(a.at));
  }

  int get unreadNotifs => visibleNotifs.where((n) => !n.read).length;

  // ---------- feed ----------
  void setRadius(double r) {
    data!.radius = r;
    _changed();
  }

  void setTypeFilter(String t) {
    data!.typeFilter = t;
    _changed();
  }

  /// Records "still on" (yes) or "over" (no) for an alert. Returns a message to show.
  String vote(int id, String v) {
    final d = data!;
    final p = d.post(id);
    if (p == null) return 'This post was removed.';
    final wasConfirmed = alertStatus(p) == 'confirmed';
    final first = applyVote(p, v);
    if (first) d.points += 1;
    _changed();
    if (v == 'yes') {
      if (!wasConfirmed && alertStatus(p) == 'confirmed') {
        return "Thanks. ${p.yes} neighbours confirm, so it's now shown as confirmed.";
      }
      return 'Thanks. Your confirmation helps others trust this.';
    }
    if (closedByVotes(p)) return 'Thanks. Most people say it is over, so the alert is now closed.';
    return "Thanks. If most people say it's over, the alert closes early.";
  }

  void addSighting(int id, String text) {
    final d = data!;
    final p = d.post(id);
    if (p == null) return;
    final pt = nextSightingPoint(p);
    p.sightings.add(Sighting(text: text, at: now, x: pt.x, y: pt.y));
    if (!p.mine) d.points += 3;
    _changed();
  }

  // ---------- messages ----------
  Thread _threadFor(Post p, String withName) {
    final d = data!;
    for (final t in d.threads) {
      if (t.postId == p.id && t.withName == withName) return t;
    }
    final t = Thread(id: d.newId(), withName: withName, postId: p.id);
    d.threads.insert(0, t);
    return t;
  }

  void _send(Thread t, String text) {
    final d = data!;
    t.msgs.add(Message(me: true, text: text, at: now));
    d.threads
      ..remove(t)
      ..insert(0, t);
  }

  /// "It's mine": sends a description to the finder. Returns the thread id.
  int claim(int postId, String text) {
    final p = data!.post(postId)!;
    final t = _threadFor(p, 'Finder · ${shortTitle(p.title, 20)}');
    _send(t, text);
    _changed();
    return t.id;
  }

  /// Private reply to a help request or notice. Returns the thread id.
  int reply(int postId, String text) {
    final p = data!.post(postId)!;
    final t = _threadFor(p, replyName(p));
    _send(t, text);
    _changed();
    return t.id;
  }

  /// Lets the owner of a lost post know about a matching found post.
  void tellOwner(int lostId, int foundId) {
    final d = data!;
    final lost = d.post(lostId);
    final found = d.post(foundId);
    if (lost == null || found == null) return;
    Thread? t;
    for (final x in d.threads) {
      if (x.postId == lost.id) {
        t = x;
        break;
      }
    }
    t ??= _threadFor(lost, 'Owner · ${shortTitle(lost.title, 20)}');
    _send(t, 'Could this be yours? Someone posted "${found.title}" (${kmText(found.km)} from me). It is in Galli under Found.');
    d.told.add(matchKey(lostId, foundId));
    d.points += 5;
    _changed();
  }

  /// For your own lost post: message whoever found a matching item.
  int messageFinder(int lostId, int foundId) {
    final d = data!;
    final lost = d.post(lostId)!;
    final found = d.post(foundId)!;
    final t = _threadFor(found, 'Finder · ${shortTitle(found.title, 20)}');
    _send(t, 'Hi, I think this might be mine. I posted "${lost.title}". ${lost.body}'.trim());
    d.told.add(matchKey(lostId, foundId));
    _changed();
    return t.id;
  }

  void sendMessage(int threadId, String text) {
    final t = data!.thread(threadId);
    if (t == null) return;
    _send(t, text);
    _changed();
  }

  void markThreadRead(int id) {
    final t = data!.thread(id);
    if (t == null || !t.unread) return;
    t.unread = false;
    _changed();
  }

  void deleteThread(int id) {
    data!.threads.removeWhere((t) => t.id == id);
    _changed();
  }

  void markNotifsRead() {
    var any = false;
    for (final n in data!.notifs) {
      if (!n.read) {
        n.read = true;
        any = true;
      }
    }
    if (any) _changed();
  }

  // ---------- posts ----------
  /// Adds your own post. Returns true if the radius was widened so you can see it.
  bool publish({
    required String type,
    required String cat,
    required String title,
    required String body,
    required String place,
    required double km,
    required int expiresHours,
    required String reward,
  }) {
    final d = data!;
    final id = d.newId();
    final pt = placeOnMap(km, id);
    final t = now;
    d.posts.add(Post(
      id: id,
      type: type,
      cat: cat,
      title: title,
      body: body,
      by: 'You',
      mine: true,
      km: km,
      x: pt.x,
      y: pt.y,
      at: t,
      yes: type == 'alert' ? 1 : 0,
      myVote: type == 'alert' ? 'yes' : '',
      expiresAt: type == 'alert' ? t + expiresHours * hourMs : null,
      safety: type == 'alert' && cat == 'Safety',
      reward: type == 'lost' ? reward : '',
      place: place,
    ));
    d.typeFilter = 'all';
    var widened = false;
    if (km > d.radius) {
      d.radius = radiusOptions.firstWhere((r) => r >= km, orElse: () => radiusOptions.last);
      widened = true;
    }
    _changed();
    return widened;
  }

  void updatePost(
    int id, {
    required String type,
    required String cat,
    required String title,
    required String body,
    required String place,
    required double km,
    required int expiresHours,
    required String reward,
  }) {
    final p = data!.post(id);
    if (p == null) return;
    if (p.km != km) {
      final pt = placeOnMap(km, id);
      p.x = pt.x;
      p.y = pt.y;
      p.km = km;
    }
    p.expiresAt = type == 'alert' ? now + expiresHours * hourMs : null;
    p.type = type;
    p.cat = cat;
    p.title = title;
    p.body = body;
    p.place = place;
    p.safety = type == 'alert' && cat == 'Safety';
    p.reward = type == 'lost' ? reward : '';
    _changed();
  }

  void setResolved(int id, bool v) {
    final p = data!.post(id);
    if (p == null) return;
    p.resolved = v;
    if (!v && p.type == 'alert' && (p.expiresAt ?? 0) <= now) p.expiresAt = now + 6 * hourMs;
    _changed();
  }

  void deletePost(int id) {
    final d = data!;
    d.posts.removeWhere((p) => p.id == id);
    d.threads.removeWhere((t) => t.postId == id);
    _changed();
  }

  void hidePost(int id) {
    final p = data!.post(id);
    if (p == null) return;
    p.hidden = true;
    _changed();
  }

  void unhideAll() {
    for (final p in data!.posts) {
      p.hidden = false;
    }
    _changed();
  }

  // ---------- you ----------
  void addArea(String name, double radiusKm) {
    data!.areas.add(Area(name: name, radiusKm: radiusKm));
    _changed();
  }

  void updateArea(int index, String name, double radiusKm) {
    final a = data!.areas;
    if (index < 0 || index >= a.length) return;
    a[index].name = name;
    a[index].radiusKm = radiusKm;
    _changed();
  }

  void setAreaOn(int index, bool on) {
    final a = data!.areas;
    if (index < 0 || index >= a.length) return;
    a[index].on = on;
    _changed();
  }

  void deleteArea(int index) {
    final a = data!.areas;
    if (index < 0 || index >= a.length) return;
    a.removeAt(index);
    _changed();
  }

  void setPref(String key, bool v) {
    data!.prefs[key] = v;
    _changed();
  }
}

/// Sample neighbourhood used for "Explore with sample data". Times are relative to now.
AppData sampleData() {
  final nowDt = DateTime.now();
  final now = nowDt.millisecondsSinceEpoch;
  int ago(int minutes) => now - minutes * minuteMs;
  int inHours(int h) => now + h * hourMs;
  final tomorrow4pm = DateTime(nowDt.year, nowDt.month, nowDt.day + 1, 16).millisecondsSinceEpoch;

  return AppData(
    name: 'Rhea',
    locality: 'Kothrud, Pune',
    radius: 1.0,
    points: 42,
    posts: [
      Post(
        id: 1,
        type: 'alert',
        cat: 'Power',
        title: 'No power on Mayur Colony lanes 3–7',
        body: 'Went off at 3:40 PM. MSEDCL helpline says a cable fault; no time given yet.',
        by: 'Neighbour',
        km: 0.4,
        x: 212,
        y: 158,
        at: ago(80),
        yes: 4,
        no: 1,
        expiresAt: inHours(5),
        place: 'Mayur Colony',
      ),
      Post(
        id: 2,
        type: 'lost',
        cat: 'Pet',
        title: 'Lost dog: Bruno, brown indie, red collar',
        body: 'Very friendly but scared of bikes. Answers to Bruno. Last seen near Karve Road, opposite Mrutyunjay Temple.',
        by: 'Neighbour',
        km: 0.6,
        x: 132,
        y: 98,
        at: ago(130),
        reward: 'Reward offered',
        place: 'Karve Road, Mrutyunjay Temple',
        sightings: [
          Sighting(text: 'Near Karishma Society gate', at: ago(95), x: 156, y: 120),
          Sighting(text: 'Running towards Dahanukar Colony', at: ago(60), x: 180, y: 146),
        ],
      ),
      Post(
        id: 3,
        type: 'alert',
        cat: 'Water',
        title: 'Water supply cut tomorrow, 6 AM to 4 PM',
        body: 'PMC notice for pipeline work. Parts of Kothrud, Karve Nagar and Warje affected. Store water tonight.',
        by: "Kothrud Residents' Forum",
        km: 0.9,
        x: 260,
        y: 74,
        at: ago(300),
        yes: 24,
        expiresAt: tomorrow4pm,
        official: true,
        place: 'Kothrud',
      ),
      Post(
        id: 4,
        type: 'alert',
        cat: 'Road',
        title: 'Tree fallen, lane blocked near Ideal Colony',
        body: "Big gulmohar branch across the lane. Two-wheelers can pass on the left, cars can't.",
        by: 'Neighbour',
        km: 0.8,
        x: 92,
        y: 206,
        at: ago(40),
        yes: 8,
        expiresAt: inHours(4),
        place: 'Ideal Colony',
      ),
      Post(
        id: 5,
        type: 'found',
        cat: 'Item',
        title: 'Found: black wallet near Dahanukar bus stop',
        body: "No cash inside, has some cards. Describe it (brand, what's inside) to claim.",
        by: 'Neighbour',
        km: 0.5,
        x: 188,
        y: 190,
        at: ago(210),
        place: 'Dahanukar Colony bus stop',
      ),
      Post(
        id: 6,
        type: 'alert',
        cat: 'Safety',
        title: 'Chain snatching reported near Paud Road signal',
        body: "A woman's chain was snatched by two men on a black scooter around 1 PM, according to a shopkeeper.",
        by: 'Neighbour',
        km: 1.0,
        x: 300,
        y: 190,
        at: ago(230),
        yes: 1,
        expiresAt: inHours(24),
        safety: true,
        place: 'Paud Road signal',
      ),
      Post(
        id: 7,
        type: 'help',
        cat: 'Ask',
        title: 'Looking for a tutor for Class 8 Marathi',
        body: 'Two evenings a week, near Bhelke Nagar. Please suggest someone you know.',
        by: 'Neighbour',
        km: 0.7,
        x: 70,
        y: 130,
        at: ago(1500),
        place: 'Bhelke Nagar',
      ),
      Post(
        id: 8,
        type: 'notice',
        cat: 'Event',
        title: 'Blood donation camp this Sunday',
        body: 'Community hall, Mayur Colony, 9 AM to 1 PM, with a hospital blood bank team. Bring ID.',
        by: 'Mayur Colony RWA',
        km: 0.3,
        x: 236,
        y: 132,
        at: ago(1700),
        official: true,
        place: 'Mayur Colony community hall',
      ),
      Post(
        id: 9,
        type: 'found',
        cat: 'Pet',
        title: 'Found: brown dog with red collar at Kothrud depot',
        body: "Friendly, hiding under a bench. I've given him water. Is he someone's?",
        by: 'Neighbour',
        km: 1.6,
        x: 34,
        y: 60,
        at: ago(20),
        place: 'Kothrud bus depot',
      ),
    ],
    threads: [
      Thread(
        id: 1,
        withName: "Bruno's owner",
        postId: 2,
        unread: true,
        msgs: [Message(me: false, text: 'Thank you for looking out! Please tell me if you see him.', at: ago(50))],
      ),
    ],
    notifs: [
      Notif(text: 'Tree fallen near Ideal Colony', at: ago(40), type: 'alert', postId: 4),
      Notif(text: '2 new sightings of Bruno within 500 m', at: ago(60), type: 'lost', postId: 2),
      Notif(text: 'Water cut tomorrow: 24 neighbours confirmed', at: ago(200), type: 'alert', postId: 3),
    ],
    areas: [
      Area(name: 'Home · Kothrud', radiusKm: 1),
      Area(name: 'Office · Hinjewadi Phase 1', radiusKm: 2),
      Area(name: 'Parents · Aundh', radiusKm: 1, on: false),
    ],
    nextId: 100,
  );
}
