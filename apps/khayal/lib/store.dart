import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart';

/// Holds the app state, saves it on the phone, and exposes actions.
class KhayalStore extends ChangeNotifier {
  static const _key = 'khayal_data_v1';
  AppData? data;
  bool loaded = false;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final d = AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        pruneLogs(d.logs, todayIso());
        if (d.activity.length > 60) d.activity.removeRange(60, d.activity.length);
        data = d.parents.isEmpty ? null : d;
      }
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

  /// Redraws screens whose content depends on the clock (due and missed doses).
  void tick() => notifyListeners();

  void _log(String text) {
    final now = DateTime.now();
    data!.activity.insert(0, Activity(text, isoDate(now), nowHhmm(now)));
  }

  // ---------- setup ----------
  void setup({required String caregiver, required String caregiverPhone, required List<Parent> parents}) {
    data = AppData(
      caregiver: caregiver,
      caregiverPhone: caregiverPhone,
      parents: parents,
      helpers: [Helper(id: 'me', name: caregiver, rel: 'You', phone: caregiverPhone, step: 60)],
    );
    _log('Khayal set up for ${parents.map((p) => p.name).join(' and ')}');
    _changed();
  }

  void loadSample() {
    data = sampleData(DateTime.now());
    _changed();
  }

  void resetAll() {
    data = null;
    _changed();
  }

  // ---------- derived ----------
  List<String> get parentIds => data!.parents.map((p) => p.id).toList();

  Parent get current {
    final d = data!;
    return d.parent(d.who) ?? d.parents.first;
  }

  List<Dose> missedNow() {
    final d = data!;
    return missedToday(d.meds, d.logs, parentIds, DateTime.now());
  }

  int get lowCount => lowStock(data!.meds).length;

  // ---------- selection ----------
  void selectWho(String id) {
    data!.who = id;
    _changed();
  }

  void setLang(String lang) {
    data!.lang = lang;
    _changed();
  }

  // ---------- doses ----------
  /// Records a dose as taken or skipped. Stock goes down when taken.
  void markDose(String date, int medId, String time, String status, String at, {String reason = ''}) {
    final d = data!;
    final m = d.med(medId);
    if (m == null) return;
    final key = doseKey(date, medId, time);
    final prev = d.logs[key];
    if (prev != null && prev.s == 'taken') m.stock += m.per;
    d.logs[key] = DoseLog(s: status, at: at, reason: reason);
    final who = d.nameOf(m.who);
    if (status == 'taken') {
      m.stock = m.stock - m.per < 0 ? 0 : m.stock - m.per;
      _log('$who took ${m.name} at ${t12(at)}${isLate(time, at) ? ' (late)' : ''}');
    } else {
      _log('${m.name} skipped for $who${reason.isEmpty ? '' : ' · $reason'}');
    }
    _changed();
  }

  /// Removes the record for a dose, putting stock back if it was taken.
  void clearDose(String date, int medId, String time) {
    final d = data!;
    final key = doseKey(date, medId, time);
    final prev = d.logs.remove(key);
    final m = d.med(medId);
    if (prev != null && prev.s == 'taken' && m != null) m.stock += m.per;
    _changed();
  }

  // ---------- medicines ----------
  int addMed({
    required String who,
    required String name,
    required String strength,
    required String form,
    required String purpose,
    required int color,
    required List<String> times,
    required String food,
    required int stock,
    required int per,
  }) {
    final d = data!;
    final id = d.newId();
    d.meds.add(Med(
      id: id,
      who: who,
      name: name,
      strength: strength,
      form: form,
      purpose: purpose.isEmpty ? 'as prescribed' : purpose,
      color: color,
      times: [...times]..sort((a, b) => mins(a).compareTo(mins(b))),
      food: food,
      stock: stock,
      per: per,
      since: todayIso(),
    ));
    _log('You added $name for ${d.nameOf(who)}');
    _changed();
    return id;
  }

  void updateMed(
    int id, {
    required String name,
    required String strength,
    required String form,
    required String purpose,
    required int color,
    required List<String> times,
    required String food,
    required int stock,
    required int per,
  }) {
    final m = data!.med(id);
    if (m == null) return;
    m
      ..name = name
      ..strength = strength
      ..form = form
      ..purpose = purpose.isEmpty ? 'as prescribed' : purpose
      ..color = color
      ..times = ([...times]..sort((a, b) => mins(a).compareTo(mins(b))))
      ..food = food
      ..stock = stock
      ..per = per;
    _log('You changed ${m.name} for ${data!.nameOf(m.who)}');
    _changed();
  }

  void stopMed(int id) {
    final d = data!;
    final m = d.med(id);
    if (m == null) return;
    d.meds.remove(m);
    _log('You stopped ${m.name} for ${d.nameOf(m.who)}');
    _changed();
  }

  void refill(int id) {
    final m = data!.med(id);
    if (m == null) return;
    m.stock += monthSupply(m);
    _log('${m.name} refilled for ${data!.nameOf(m.who)}');
    _changed();
  }

  // ---------- readings ----------
  void addReading(String who, String kind, int a, int b) {
    final d = data!;
    d.readings.add(Reading(id: d.newId(), who: who, kind: kind, date: todayIso(), a: a, b: b));
    _log('${d.nameOf(who)}\'s ${kind == 'bp' ? 'BP' : 'sugar'} logged: ${kind == 'bp' ? '$a/$b' : '$a mg/dL'}');
    _changed();
  }

  void deleteReading(int id) {
    data!.readings.removeWhere((r) => r.id == id);
    _changed();
  }

  // ---------- visits ----------
  void saveVisit({int? id, required String who, required String title, required String date, required String time, required String note}) {
    final d = data!;
    Visit? v;
    for (final x in d.visits) {
      if (x.id == id) v = x;
    }
    if (v == null) {
      d.visits.add(Visit(id: d.newId(), who: who, title: title, date: date, time: time, note: note));
      _log('You added ${d.nameOf(who)}\'s $title');
    } else {
      v
        ..who = who
        ..title = title
        ..date = date
        ..time = time
        ..note = note;
    }
    _changed();
  }

  void deleteVisit(int id) {
    data!.visits.removeWhere((v) => v.id == id);
    _changed();
  }

  // ---------- family ----------
  void saveHelper({String? id, required String name, required String rel, required String phone, required int step}) {
    final d = data!;
    final h = id == null ? null : d.helper(id);
    if (h == null) {
      d.helpers.add(Helper(id: 'h${d.newId()}', name: name, rel: rel, phone: phone, step: step));
      _log('$name added to the alert ladder');
    } else {
      h
        ..name = name
        ..rel = rel
        ..phone = phone
        ..step = step;
      if (h.id == 'me') {
        d.caregiver = name;
        d.caregiverPhone = phone;
      }
    }
    _changed();
  }

  void toggleHelper(String id, bool on) {
    final h = data!.helper(id);
    if (h == null) return;
    h.on = on;
    _changed();
  }

  void deleteHelper(String id) {
    if (id == 'me') return;
    data!.helpers.removeWhere((h) => h.id == id);
    _changed();
  }

  void setQuietHours(bool v) {
    data!.quietHours = v;
    _changed();
  }

  // ---------- parents and settings ----------
  void updateParent(String id, {required String name, required String full, required int age, required String phone, required String conditions}) {
    final p = data!.parent(id);
    if (p == null) return;
    if (name.trim().isNotEmpty) p.name = name.trim();
    p
      ..full = full.trim()
      ..age = age
      ..phone = phone.trim()
      ..conditions = conditions.trim();
    _changed();
  }

  void updateSettings({
    required String caregiver,
    required String caregiverPhone,
    required String address,
    required String chemist,
    required String chemistPhone,
  }) {
    final d = data!;
    if (caregiver.trim().isNotEmpty) d.caregiver = caregiver.trim();
    d
      ..caregiverPhone = caregiverPhone.trim()
      ..address = address.trim()
      ..chemist = chemist.trim()
      ..chemistPhone = chemistPhone.trim();
    final me = d.helper('me');
    if (me != null) {
      me
        ..name = d.caregiver
        ..phone = d.caregiverPhone;
    }
    _changed();
  }
}

/// Sample family used for "Explore with sample data". Dates and today's doses are relative to [now].
AppData sampleData(DateTime now) {
  final t = isoDate(now);
  String ago(int n) => addDaysIso(t, -n);
  final since = ago(30);
  final nowMin = now.hour * 60 + now.minute;

  final meds = [
    Med(id: 1, who: 'papa', name: 'Metformin', strength: '500 mg', purpose: 'for sugar', color: 0xFFF4F4F0, times: ['08:30', '20:30'], food: 'after', stock: 22, since: since),
    Med(id: 2, who: 'papa', name: 'Telmisartan', strength: '40 mg', purpose: 'for BP', color: 0xFFF7D9DE, times: ['08:00'], food: 'any', stock: 9, since: since),
    Med(id: 3, who: 'papa', name: 'Atorvastatin', strength: '10 mg', purpose: 'for cholesterol', color: 0xFFDDEAF7, times: ['21:30'], food: 'any', stock: 40, since: since),
    Med(id: 4, who: 'mummy', name: 'Thyroxine', strength: '50 mcg', purpose: 'for thyroid', color: 0xFFF4F4F0, times: ['06:30'], food: 'empty', stock: 60, since: since),
    Med(id: 5, who: 'mummy', name: 'Pantoprazole', strength: '40 mg', purpose: 'for acidity', color: 0xFFF6E6A8, times: ['07:30'], food: 'before', stock: 12, since: since),
    Med(id: 6, who: 'mummy', name: 'Calcium + Vitamin D3', strength: '500 mg', purpose: 'for bones', color: 0xFFF2E5C9, times: ['14:00'], food: 'after', stock: 18, since: since),
  ];

  final logs = <String, DoseLog>{};
  // Past six days: nearly everything taken, with the misses the prototype shows.
  for (var i = 6; i >= 1; i--) {
    final date = ago(i);
    for (final m in meds) {
      for (final time in m.times) {
        if (i == 4 && m.id == 3) continue; // Papa missed Atorvastatin
        if (i == 5 && m.id == 6) continue; // Mummy missed Calcium
        if (i == 1 && m.id == 1 && time == '20:30') {
          logs[doseKey(date, m.id, time)] = DoseLog(s: 'skipped', at: '21:40', reason: 'Forgot');
          continue;
        }
        final late = m.id == 1 && time == '08:30' && (i == 3 || i == 1);
        logs[doseKey(date, m.id, time)] = DoseLog(s: 'taken', at: late ? '09:10' : hhmm(mins(time) + 5));
      }
    }
  }
  // Today: morning doses confirmed; Mummy's 2 PM calcium is left unconfirmed.
  final activity = <Activity>[];
  final todays = <List<Object>>[];
  for (final m in meds) {
    if (m.id == 6) continue;
    for (final time in m.times) {
      var at = mins(time) + 5;
      if (m.id == 1 && time == '08:30') at = mins(time) + 40;
      if (at <= nowMin) todays.add([m, time, hhmm(at)]);
    }
  }
  todays.sort((a, b) => mins(a[2] as String).compareTo(mins(b[2] as String)));
  for (final x in todays) {
    final m = x[0] as Med;
    final time = x[1] as String;
    final at = x[2] as String;
    logs[doseKey(t, m.id, time)] = DoseLog(s: 'taken', at: at);
    final who = m.who == 'papa' ? 'Papa' : 'Mummy';
    activity.insert(0, Activity('$who took ${m.name} at ${t12(at)}${isLate(time, at) ? ' (late)' : ''}', t, at));
  }
  activity.addAll([
    Activity('Papa\'s BP logged: 133/83', ago(1), '19:15'),
    Activity('Metformin skipped for Papa · Forgot', ago(1), '21:40'),
  ]);

  const bp = [[138, 86], [142, 88], [135, 84], [131, 82], [129, 80], [133, 83], [128, 79]];
  const sugar = [132, 128, 141, 125, 119, 122, 118];
  var rid = 500;
  final readings = <Reading>[
    for (var i = 0; i < 7; i++) Reading(id: rid++, who: 'papa', kind: 'bp', date: ago(6 - i), a: bp[i][0], b: bp[i][1]),
    for (var i = 0; i < 7; i++) Reading(id: rid++, who: 'papa', kind: 'sugar', date: ago(6 - i), a: sugar[i]),
    Reading(id: rid++, who: 'mummy', kind: 'bp', date: ago(5), a: 124, b: 78),
    Reading(id: rid++, who: 'mummy', kind: 'bp', date: ago(2), a: 121, b: 76),
  ];

  return AppData(
    caregiver: 'Karan',
    caregiverPhone: '+91 98765 43210',
    address: 'Sharma, Flat 4, Shivaji Nagar, Nagpur',
    chemist: 'Shree Medical, Shivaji Nagar',
    chemistPhone: '+91 712 255 0199',
    parents: [
      Parent(id: 'papa', name: 'Papa', full: 'Suresh Sharma', age: 68, phone: '+91 98220 41137', conditions: 'Type 2 diabetes, high BP', color: 0xFF1D5C7A),
      Parent(id: 'mummy', name: 'Mummy', full: 'Kamla Sharma', age: 64, phone: '+91 98220 41138', conditions: 'Hypothyroidism, low bone density', color: 0xFFB5602B),
    ],
    meds: meds,
    logs: logs,
    readings: readings,
    visits: [
      Visit(id: 601, who: 'papa', title: 'Dr. Deshpande (diabetes)', date: addDaysIso(t, 8), time: '11:00', note: 'Carry sugar log and HbA1c report'),
      Visit(id: 602, who: 'mummy', title: 'Thyroid blood test (TSH)', date: addDaysIso(t, 17), time: '08:00', note: 'Before taking Thyroxine'),
    ],
    helpers: [
      Helper(id: 'me', name: 'Karan', rel: 'Son · Pune', phone: '+91 98765 43210', step: 60),
      Helper(id: 'neha', name: 'Neha', rel: 'Daughter · Bengaluru', phone: '+91 99001 22334', step: 60),
      Helper(id: 'joshi', name: 'Mr. Joshi', rel: 'Neighbour · 2 floors down', phone: '+91 98220 55012', step: 120),
    ],
    activity: activity,
    who: 'mummy',
  );
}
