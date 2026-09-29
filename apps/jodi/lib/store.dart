import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart';

/// Holds the app state, saves it on the phone, and exposes actions.
class JodiStore extends ChangeNotifier {
  static const _key = 'jodi_data_v1';
  AppData? data;
  bool loaded = false;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) data = AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      data = null; // corrupt data: start fresh rather than crash
    }
    final d = data;
    loaded = true;
    if (d != null && simulatePartner(d, todayIso())) {
      _changed();
    } else {
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final d = data;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (d == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, jsonEncode(d.toJson()));
      }
    } catch (_) {
      // Saving failed (storage full or unavailable); keep going with the data in memory.
    }
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  void _post(String who, String text, {String note = ''}) {
    final d = data!;
    d.feed.insert(0, FeedEvent(id: d.newId(), who: who, text: text, note: note, date: todayIso(), at: nowHm()));
    if (d.feed.length > 200) d.feed.removeRange(200, d.feed.length);
  }

  // ---------- setup ----------
  void createPair({
    required String meName,
    required String partnerName,
    String meCity = '',
    String partnerCity = '',
    String pact = '',
    int target = 80,
  }) {
    data = AppData(
      meName: meName,
      partnerName: partnerName,
      meCity: meCity,
      partnerCity: partnerCity,
      pairedOn: todayIso(),
      pact: pact.isEmpty ? 'The one below $target% this week buys chai' : pact,
      target: target,
    );
    _post(me, 'You and $partnerName paired up');
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

  // ---------- derived ----------
  Map<int, Map<String, DayState>> statesOf(String who) {
    final d = data!;
    return dayStates(d.habitsOf(who), todayIso(), d.pauses);
  }

  WeekScore scoreOf(String who, Map<int, Map<String, DayState>> states) {
    final d = data!;
    return weekScore(d.habitsOf(who), states, todayIso(), d.pauses);
  }

  /// Habits of [who] that are due today (or already done today).
  List<Habit> dueToday(String who) {
    final d = data!;
    final t = todayIso();
    return d.habitsOf(who).where((h) => h.log.containsKey(t) || scheduledOn(h, t, d.pauses)).toList();
  }

  int get partnerPending {
    final t = todayIso();
    return dueToday(them).where((h) => !h.log.containsKey(t)).length;
  }

  // ---------- check-ins ----------
  /// Checks in one of your habits for today. Returns the new streak.
  int checkIn(int id, {String note = '', String effort = 'OK'}) {
    final d = data!;
    final h = d.habit(id);
    if (h == null) return 0;
    final t = todayIso();
    h.log[t] = CheckIn(at: nowHm(), note: note, effort: effort);
    _post(me, 'You checked in: ${h.name}', note: note);
    _changed();
    return currentStreak(statesOf(h.owner)[h.id] ?? const {}, t);
  }

  /// Logs a partner's habit as done today, when they told you they did it.
  void logForPartner(int id, {String note = ''}) {
    final d = data!;
    final h = d.habit(id);
    if (h == null) return;
    h.log[todayIso()] = CheckIn(at: nowHm(), note: note, byPartnerLog: true);
    _post(them, '${d.partnerName} checked in: ${h.name}', note: note);
    _changed();
  }

  void undoCheckIn(int id) {
    final d = data!;
    final h = d.habit(id);
    if (h == null) return;
    final t = todayIso();
    h.log.remove(t);
    final who = h.owner;
    final text = who == me ? 'You checked in: ${h.name}' : '${d.partnerName} checked in: ${h.name}';
    final i = d.feed.indexWhere((e) => e.date == t && e.who == who && e.text == text);
    if (i >= 0) d.feed.removeAt(i);
    _changed();
  }

  // ---------- habits ----------
  Habit addHabit({
    required String owner,
    required String name,
    required String cue,
    required List<bool> days,
    bool proof = false,
    bool shared = true,
  }) {
    final d = data!;
    final h = Habit(
      id: d.newId(),
      owner: owner,
      name: name,
      cue: cue,
      days: List.of(days),
      createdOn: todayIso(),
      proof: proof,
      shared: shared,
    );
    d.habits.add(h);
    _post(owner, owner == me ? 'You started a new habit: $name' : '${d.partnerName} started a new habit: $name', note: planText(cue, name));
    _changed();
    return h;
  }

  void updateHabit(int id, {required String name, required String cue, required List<bool> days, required bool proof, required bool shared}) {
    final h = data!.habit(id);
    if (h == null) return;
    h
      ..name = name
      ..cue = cue
      ..days = List.of(days)
      ..proof = proof
      ..shared = shared;
    _changed();
  }

  void deleteHabit(int id) {
    final d = data!;
    d.habits.removeWhere((h) => h.id == id);
    d.nudges.removeWhere((n) => n.habitId == id);
    _changed();
  }

  // ---------- partner ----------
  void nudge(int habitId, String message) {
    final d = data!;
    final h = d.habit(habitId);
    if (h == null) return;
    d.nudges.add(Nudge(habitId: habitId, date: todayIso(), message: message));
    _post(me, 'You nudged ${d.partnerName} about ${lowerFirst(h.name)}', note: message);
    _changed();
  }

  void react(int eventId, String emoji) {
    for (final e in data!.feed) {
      if (e.id == eventId) {
        e.react = e.react == emoji ? null : emoji;
        break;
      }
    }
    _changed();
  }

  Reflection? reflection(String who, String week) {
    for (final r in data!.reflections) {
      if (r.who == who && r.week == week) return r;
    }
    return null;
  }

  void saveReflection(List<String> answers) {
    final d = data!;
    final week = weekStartIso(todayIso());
    d.reflections.removeWhere((r) => r.who == me && r.week == week);
    d.reflections.add(Reflection(week: week, who: me, answers: answers));
    _post(me, 'You answered the Sunday check-in');
    _changed();
  }

  // ---------- settings ----------
  void setShareNotes(bool v) {
    data!.shareNotes = v;
    _changed();
  }

  void setShowNudges(bool v) {
    data!.showNudges = v;
    _changed();
  }

  void setPaused(bool v) {
    final d = data!;
    final t = todayIso();
    if (v && !d.paused) {
      d.pauses.add(Pause(from: t));
      _post(me, 'You paused the partnership. Streaks are frozen for both of you.');
    } else if (!v && d.paused) {
      final p = d.pauses.last;
      if (p.from == t) {
        d.pauses.removeLast(); // paused and resumed the same day: nothing to freeze
      } else {
        p.to = t;
      }
      _post(me, 'You resumed the partnership');
    }
    _changed();
  }

  void updateProfile({
    required String meName,
    required String meCity,
    required String partnerName,
    required String partnerCity,
    required String pact,
    required int target,
  }) {
    final d = data!;
    if (meName.trim().isNotEmpty) d.meName = meName.trim();
    if (partnerName.trim().isNotEmpty) d.partnerName = partnerName.trim();
    d.meCity = meCity.trim();
    d.partnerCity = partnerCity.trim();
    if (pact.trim().isNotEmpty && pact.trim() != d.pact) {
      d.pact = pact.trim();
      _post(me, 'You changed the pact', note: d.pact);
    }
    d.target = target < 10 ? 10 : (target > 100 ? 100 : target);
    _changed();
  }

  void requestMatch(String name) {
    final d = data!;
    if (!d.matchRequests.contains(name)) d.matchRequests.add(name);
    _changed();
  }

  void cancelMatch(String name) {
    data!.matchRequests.remove(name);
    _changed();
  }
}

/// Sample pair used for "Explore with sample data": you are Ishaan in Mumbai, paired with Tara in Delhi.
/// Dates are relative to today, and Tara's check-ins keep being simulated day by day.
AppData sampleData() {
  final t = todayIso();
  final since = addDaysIso(t, -38);
  const every = [true, true, true, true, true, true, true];

  Habit hb(int id, String owner, String name, String cue, List<bool> days, {bool proof = false}) =>
      Habit(id: id, owner: owner, name: name, cue: cue, days: List.of(days), createdOn: since, proof: proof);

  final read = hb(1, me, 'Read 20 pages', 'After dinner', every);
  final run = hb(2, me, 'Run 3 km', 'After waking up, before chai', [true, false, true, false, true, true, false], proof: true);
  final phone = hb(3, me, 'No phone after 11 PM', 'When the 11 PM alarm rings', every);
  final meditate = hb(4, them, 'Meditate 10 min', 'After morning shower', every);
  final guitar = hb(5, them, 'Guitar practice 20 min', 'After logging off work', [true, true, true, true, true, false, false]);
  final water = hb(6, them, 'Drink 2 L water', 'Refill bottle at lunch', every);

  fillHistory(read, t, seed: 3, rate: .86, recentRun: 12, at: '21:40');
  fillHistory(run, t, seed: 7, rate: .74, recentRun: 5, at: '06:45');
  fillHistory(phone, t, seed: 11, rate: .62, recentRun: 3, at: '23:00');
  fillHistory(meditate, t, seed: 5, rate: .92, recentRun: 21, at: '07:40');
  fillHistory(guitar, t, seed: 9, rate: .66, recentRun: 2, at: '19:10');
  fillHistory(water, t, seed: 13, rate: .8, recentRun: 9, at: '16:10');

  run.log[addDaysIso(t, -2)] = CheckIn(at: '06:40', note: 'Carter Road, 19 min', effort: 'Tough');
  meditate.log[t] = CheckIn(at: '07:40', note: 'Rough morning, this helped.', effort: 'OK');
  water.log[t] = CheckIn(at: '16:10', effort: 'Easy');

  final week = weekStartIso(t);
  return AppData(
    meName: 'Ishaan',
    meCity: 'Mumbai',
    partnerName: 'Tara',
    partnerCity: 'Delhi',
    pairedOn: since,
    pact: 'The one below 80% this week buys chai',
    target: 80,
    habits: [read, run, phone, meditate, guitar, water],
    feed: [
      FeedEvent(id: 501, who: them, text: 'Tara drank 2 L of water', date: t, at: '16:10'),
      FeedEvent(id: 502, who: them, text: 'Tara meditated for 10 min', note: 'Rough morning, this helped.', date: t, at: '07:40'),
      FeedEvent(id: 503, who: me, text: 'You ran 3 km', note: 'Carter Road, 19 min', date: addDaysIso(t, -2), at: '06:40', react: '🔥'),
      FeedEvent(id: 504, who: them, text: 'Tara finished all 3 habits', date: addDaysIso(t, -3), at: '22:00', react: '👏'),
      FeedEvent(id: 505, who: them, text: 'Tara changed the pact', note: 'The one below 80% this week buys chai', date: addDaysIso(t, -5), at: '10:15'),
    ],
    reflections: [
      Reflection(week: week, who: them, answers: [
        'Meditated every morning, even the rough ones.',
        'Late calls on Thursday ate my guitar time.',
        'Guitar straight after logging off, before dinner.',
      ]),
      Reflection(week: addDaysIso(week, -7), who: them, answers: [
        'Water every day, finally.',
        'A wedding on Saturday.',
        'Keep the bottle on my desk.',
      ]),
      Reflection(week: addDaysIso(week, -7), who: me, answers: [
        'Read every night after dinner.',
        'Skipped a run when it rained.',
        'Lay out running shoes the night before.',
      ]),
    ],
    simulatePartner: true,
    simulatedTo: addDaysIso(t, -1),
    nextId: 1000,
  );
}
