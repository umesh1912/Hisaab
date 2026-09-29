// Core data model and pure logic for Khayal. No Flutter imports here.
// Times of day are 'HH:mm' strings, dates are 'yyyy-MM-dd' strings.

class Parent {
  Parent({
    required this.id,
    required this.name,
    this.full = '',
    this.age = 0,
    this.phone = '',
    this.conditions = '',
    this.color = 0xFF1D5C7A,
  });
  final String id;
  String name; // what the family calls them, e.g. Papa
  String full;
  int age;
  String phone;
  String conditions;
  int color;

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'full': full, 'age': age, 'phone': phone, 'conditions': conditions, 'color': color};
  factory Parent.fromJson(Map<String, dynamic> j) => Parent(
        id: j['id'] as String,
        name: j['name'] as String,
        full: (j['full'] ?? '') as String,
        age: (j['age'] ?? 0) as int,
        phone: (j['phone'] ?? '') as String,
        conditions: (j['conditions'] ?? '') as String,
        color: (j['color'] ?? 0xFF1D5C7A) as int,
      );
}

class Med {
  Med({
    required this.id,
    required this.who,
    required this.name,
    this.strength = '',
    this.form = 'tablet',
    this.purpose = 'as prescribed',
    this.color = 0xFFEDEDED,
    required this.times,
    this.food = 'after',
    this.stock = 0,
    this.per = 1,
    required this.since,
  });
  final int id;
  String who;
  String name;
  String strength;
  String form; // tablet | capsule
  String purpose;
  int color;
  List<String> times;
  String food; // after | before | empty | any
  int stock;
  int per;
  String since; // first day doses are expected

  Map<String, dynamic> toJson() => {
        'id': id,
        'who': who,
        'name': name,
        'strength': strength,
        'form': form,
        'purpose': purpose,
        'color': color,
        'times': times,
        'food': food,
        'stock': stock,
        'per': per,
        'since': since,
      };
  factory Med.fromJson(Map<String, dynamic> j) => Med(
        id: j['id'] as int,
        who: j['who'] as String,
        name: j['name'] as String,
        strength: (j['strength'] ?? '') as String,
        form: (j['form'] ?? 'tablet') as String,
        purpose: (j['purpose'] ?? '') as String,
        color: (j['color'] ?? 0xFFEDEDED) as int,
        times: ((j['times'] ?? []) as List).cast<String>().toList(),
        food: (j['food'] ?? 'any') as String,
        stock: (j['stock'] ?? 0) as int,
        per: (j['per'] ?? 1) as int,
        since: (j['since'] ?? '2000-01-01') as String,
      );

  String get title => strength.isEmpty ? name : '$name $strength';
}

/// What happened to one scheduled dose.
class DoseLog {
  DoseLog({required this.s, required this.at, this.reason = ''});
  final String s; // taken | skipped
  final String at; // HH:mm
  final String reason;

  Map<String, dynamic> toJson() => {'s': s, 'at': at, 'reason': reason};
  factory DoseLog.fromJson(Map<String, dynamic> j) =>
      DoseLog(s: j['s'] as String, at: j['at'] as String, reason: (j['reason'] ?? '') as String);
}

class Reading {
  Reading({required this.id, required this.who, required this.kind, required this.date, required this.a, this.b = 0});
  final int id;
  final String who;
  final String kind; // bp | sugar
  final String date;
  final int a; // systolic, or sugar mg/dL
  final int b; // diastolic (bp only)

  Map<String, dynamic> toJson() => {'id': id, 'who': who, 'kind': kind, 'date': date, 'a': a, 'b': b};
  factory Reading.fromJson(Map<String, dynamic> j) => Reading(
        id: j['id'] as int,
        who: j['who'] as String,
        kind: j['kind'] as String,
        date: j['date'] as String,
        a: j['a'] as int,
        b: (j['b'] ?? 0) as int,
      );

  String get label => kind == 'bp' ? '$a/$b' : '$a mg/dL';
}

class Visit {
  Visit({required this.id, required this.who, required this.title, required this.date, required this.time, this.note = ''});
  final int id;
  String who;
  String title;
  String date;
  String time;
  String note;

  Map<String, dynamic> toJson() => {'id': id, 'who': who, 'title': title, 'date': date, 'time': time, 'note': note};
  factory Visit.fromJson(Map<String, dynamic> j) => Visit(
        id: j['id'] as int,
        who: j['who'] as String,
        title: j['title'] as String,
        date: j['date'] as String,
        time: (j['time'] ?? '10:00') as String,
        note: (j['note'] ?? '') as String,
      );
}

/// Someone on the escalation ladder: the caregiver, a sibling, a neighbour.
class Helper {
  Helper({required this.id, required this.name, this.rel = '', this.phone = '', this.step = 60, this.on = true});
  final String id; // 'me' is the person using this phone
  String name;
  String rel;
  String phone;
  int step; // minutes after a dose before this person is told
  bool on;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'rel': rel, 'phone': phone, 'step': step, 'on': on};
  factory Helper.fromJson(Map<String, dynamic> j) => Helper(
        id: j['id'] as String,
        name: j['name'] as String,
        rel: (j['rel'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        step: (j['step'] ?? 60) as int,
        on: (j['on'] ?? true) as bool,
      );
}

class Activity {
  Activity(this.text, this.date, this.at);
  final String text;
  final String date;
  final String at;
  Map<String, dynamic> toJson() => {'text': text, 'date': date, 'at': at};
  factory Activity.fromJson(Map<String, dynamic> j) =>
      Activity(j['text'] as String, j['date'] as String, (j['at'] ?? '00:00') as String);
}

class AppData {
  AppData({
    required this.caregiver,
    this.caregiverPhone = '',
    this.address = '',
    this.chemist = '',
    this.chemistPhone = '',
    required this.parents,
    List<Med>? meds,
    Map<String, DoseLog>? logs,
    List<Reading>? readings,
    List<Visit>? visits,
    List<Helper>? helpers,
    List<Activity>? activity,
    String? who,
    this.lang = 'en',
    this.quietHours = true,
    this.nextId = 1000,
  })  : meds = meds ?? [],
        logs = logs ?? {},
        readings = readings ?? [],
        visits = visits ?? [],
        helpers = helpers ?? [],
        activity = activity ?? [],
        who = who ?? (parents.isEmpty ? '' : parents.first.id);

  String caregiver;
  String caregiverPhone;
  String address;
  String chemist;
  String chemistPhone;
  List<Parent> parents;
  List<Med> meds;
  Map<String, DoseLog> logs;
  List<Reading> readings;
  List<Visit> visits;
  List<Helper> helpers;
  List<Activity> activity;
  String who; // parent currently shown
  String lang; // en | hi, for parent mode
  bool quietHours;
  int nextId;

  int newId() => nextId++;

  Parent? parent(String id) {
    for (final p in parents) {
      if (p.id == id) return p;
    }
    return null;
  }

  Med? med(int id) {
    for (final m in meds) {
      if (m.id == id) return m;
    }
    return null;
  }

  Helper? helper(String id) {
    for (final h in helpers) {
      if (h.id == id) return h;
    }
    return null;
  }

  String nameOf(String parentId) => parent(parentId)?.name ?? 'Parent';

  Map<String, dynamic> toJson() => {
        'caregiver': caregiver,
        'caregiverPhone': caregiverPhone,
        'address': address,
        'chemist': chemist,
        'chemistPhone': chemistPhone,
        'parents': parents.map((e) => e.toJson()).toList(),
        'meds': meds.map((e) => e.toJson()).toList(),
        'logs': logs.map((k, v) => MapEntry(k, v.toJson())),
        'readings': readings.map((e) => e.toJson()).toList(),
        'visits': visits.map((e) => e.toJson()).toList(),
        'helpers': helpers.map((e) => e.toJson()).toList(),
        'activity': activity.map((e) => e.toJson()).toList(),
        'who': who,
        'lang': lang,
        'quietHours': quietHours,
        'nextId': nextId,
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    List<T> l<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] ?? []) as List).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    final rawLogs = (j['logs'] ?? {}) as Map;
    return AppData(
      caregiver: (j['caregiver'] ?? 'You') as String,
      caregiverPhone: (j['caregiverPhone'] ?? '') as String,
      address: (j['address'] ?? '') as String,
      chemist: (j['chemist'] ?? '') as String,
      chemistPhone: (j['chemistPhone'] ?? '') as String,
      parents: l('parents', Parent.fromJson),
      meds: l('meds', Med.fromJson),
      logs: rawLogs.map((k, v) => MapEntry(k as String, DoseLog.fromJson(Map<String, dynamic>.from(v as Map)))),
      readings: l('readings', Reading.fromJson),
      visits: l('visits', Visit.fromJson),
      helpers: l('helpers', Helper.fromJson),
      activity: l('activity', Activity.fromJson),
      who: j['who'] as String?,
      lang: (j['lang'] ?? 'en') as String,
      quietHours: (j['quietHours'] ?? true) as bool,
      nextId: (j['nextId'] ?? 1000) as int,
    );
  }
}

// ---------------- time of day ----------------

/// Minutes since midnight for 'HH:mm'. Bad input counts as midnight.
int mins(String t) {
  final p = t.split(':');
  if (p.length < 2) return 0;
  return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
}

String hhmm(int m) {
  final x = ((m % 1440) + 1440) % 1440;
  return '${(x ~/ 60).toString().padLeft(2, '0')}:${(x % 60).toString().padLeft(2, '0')}';
}

String nowHhmm(DateTime now) => hhmm(now.hour * 60 + now.minute);

/// '14:05' -> '2:05 PM'
String t12(String t) {
  final m = mins(t);
  final h = m ~/ 60;
  final mm = m % 60;
  final ap = h < 12 ? 'AM' : 'PM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${mm.toString().padLeft(2, '0')} $ap';
}

// ---------------- doses ----------------

class Dose {
  const Dose(this.med, this.time);
  final Med med;
  final String time;
  String key(String date) => doseKey(date, med.id, time);
}

String doseKey(String date, int medId, String time) => '$date|$medId|$time';

/// Every scheduled dose for one parent on [date], earliest first.
List<Dose> dosesOn(List<Med> meds, String who, String date) {
  final out = <Dose>[];
  for (final m in meds) {
    if (m.who != who) continue;
    if (m.since.compareTo(date) > 0) continue;
    for (final t in m.times) {
      out.add(Dose(m, t));
    }
  }
  out.sort((a, b) {
    final c = mins(a.time).compareTo(mins(b.time));
    return c != 0 ? c : a.med.name.compareTo(b.med.name);
  });
  return out;
}

/// taken | skipped (recorded), or missed | due | up (derived from the clock).
/// A dose becomes "missed" when it is an hour late and nobody confirmed it.
String doseStatus(DoseLog? log, String date, String time, DateTime now) {
  if (log != null) return log.s;
  final c = date.compareTo(isoDate(now));
  if (c < 0) return 'missed';
  if (c > 0) return 'up';
  final diff = now.hour * 60 + now.minute - mins(time);
  if (diff >= 60) return 'missed';
  if (diff >= 0) return 'due';
  return 'up';
}

bool isLate(String doseTime, String at) => mins(at) - mins(doseTime) > 30;

const statusLabels = {'taken': 'Taken', 'missed': 'Missed', 'due': 'Due now', 'up': 'Later', 'skipped': 'Skipped'};

/// Percent of doses taken on [date], counting only doses whose time has passed.
/// Null when nothing was due yet.
int? dayAdherence(List<Med> meds, Map<String, DoseLog> logs, String who, String date, DateTime now) {
  var total = 0, taken = 0;
  for (final d in dosesOn(meds, who, date)) {
    final s = doseStatus(logs[d.key(date)], date, d.time, now);
    if (s == 'up' || s == 'due') continue;
    total++;
    if (s == 'taken') taken++;
  }
  if (total == 0) return null;
  return (taken * 100 / total).round();
}

/// Last 7 days, oldest first, today last.
List<int?> weekAdherence(List<Med> meds, Map<String, DoseLog> logs, String who, DateTime now) {
  final t = isoDate(now);
  return [for (var i = 6; i >= 0; i--) dayAdherence(meds, logs, who, addDaysIso(t, -i), now)];
}

int? averageOf(List<int?> v) {
  final xs = v.whereType<int>().toList();
  if (xs.isEmpty) return null;
  return (xs.reduce((a, b) => a + b) / xs.length).round();
}

/// Missed doses today for the given parents, earliest first.
List<Dose> missedToday(List<Med> meds, Map<String, DoseLog> logs, List<String> who, DateTime now) {
  final t = isoDate(now);
  final out = <Dose>[];
  for (final w in who) {
    for (final d in dosesOn(meds, w, t)) {
      if (doseStatus(logs[d.key(t)], t, d.time, now) == 'missed') out.add(d);
    }
  }
  out.sort((a, b) => mins(a.time).compareTo(mins(b.time)));
  return out;
}

class WeekCounts {
  WeekCounts();
  int total = 0;
  int taken = 0;
  final Map<String, int> missed = {};
  final Map<String, int> late = {};
}

/// Taken, missed and late doses over the last 7 days for one parent.
WeekCounts weekCounts(List<Med> meds, Map<String, DoseLog> logs, String who, DateTime now) {
  final c = WeekCounts();
  final t = isoDate(now);
  for (var i = 6; i >= 0; i--) {
    final date = addDaysIso(t, -i);
    for (final d in dosesOn(meds, who, date)) {
      final log = logs[d.key(date)];
      final s = doseStatus(log, date, d.time, now);
      if (s == 'up' || s == 'due') continue;
      c.total++;
      if (s == 'taken') {
        c.taken++;
        if (log != null && isLate(d.time, log.at)) c.late[d.med.name] = (c.late[d.med.name] ?? 0) + 1;
      } else {
        c.missed[d.med.name] = (c.missed[d.med.name] ?? 0) + 1;
      }
    }
  }
  return c;
}

/// Removes dose records older than [keepDays] so storage stays small.
void pruneLogs(Map<String, DoseLog> logs, String today, {int keepDays = 60}) {
  final cutoff = addDaysIso(today, -keepDays);
  logs.removeWhere((k, _) => k.split('|').first.compareTo(cutoff) < 0);
}

// ---------------- stock ----------------

/// Whole days of medicine left at the current dose.
int daysLeft(Med m) {
  final perDay = m.times.length * m.per;
  if (perDay <= 0) return 999;
  return m.stock ~/ perDay;
}

/// A month's supply.
int monthSupply(Med m) => m.times.length * m.per * 30;

List<Med> lowStock(List<Med> meds, {int within = 10}) =>
    meds.where((m) => daysLeft(m) <= within).toList()..sort((a, b) => daysLeft(a).compareTo(daysLeft(b)));

// ---------------- readings ----------------

/// The newest [n] readings of one kind for one parent, oldest first.
List<Reading> recentReadings(List<Reading> all, String who, String kind, {int n = 7}) {
  final xs = all.where((r) => r.who == who && r.kind == kind).toList()
    ..sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  return xs.length > n ? xs.sublist(xs.length - n) : xs;
}

int avgInt(Iterable<int> xs) => xs.isEmpty ? 0 : (xs.reduce((a, b) => a + b) / xs.length).round();

/// Chart bounds that include [lo]..[hi] and every value, snapped to [step].
List<int> chartRange(Iterable<int> values, int lo, int hi, {int step = 20}) {
  var mn = lo, mx = hi;
  for (final v in values) {
    if (v < mn) mn = v;
    if (v > mx) mx = v;
  }
  mn = (mn ~/ step) * step;
  mx = ((mx + step - 1) ~/ step) * step;
  if (mx <= mn) mx = mn + step;
  return [mn, mx];
}

String? checkBp(int? s, int? d) {
  if (s == null || d == null || !(s > 60 && s < 260 && d > 30 && d < 160 && s > d)) {
    return 'Check the numbers. Upper should be bigger than lower, like 126/80.';
  }
  return null;
}

String? checkSugar(int? v) {
  if (v == null || !(v > 30 && v < 600)) return 'Enter the number from the meter, like 116.';
  return null;
}

// ---------------- escalation ----------------

/// Enabled helpers in the order they are told.
List<Helper> ladder(List<Helper> helpers) => helpers.where((h) => h.on).toList()..sort((a, b) => a.step.compareTo(b.step));

/// 11 PM to 6 AM.
bool inQuietHours(DateTime now) => now.hour >= 23 || now.hour < 6;

/// Digits for wa.me links. Ten-digit Indian numbers get the 91 prefix.
String waDigits(String phone) {
  final d = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.length == 10) return '91$d';
  if (d.length == 11 && d.startsWith('0')) return '91${d.substring(1)}';
  return d;
}

// ---------------- messages ----------------

String foodText(String f) {
  switch (f) {
    case 'after':
      return 'after food';
    case 'before':
      return 'before food';
    case 'empty':
      return 'on an empty stomach';
    default:
      return 'with or without food';
  }
}

String refillMessage({
  required List<Med> low,
  required String Function(String who) nameOf,
  required String address,
  required String caregiver,
}) {
  final b = StringBuffer();
  b.writeln(address.trim().isEmpty ? 'Namaste, please deliver:' : 'Namaste, please deliver to ${address.trim()}:');
  for (final m in low) {
    b.writeln('• ${m.title} × ${monthSupply(m)} (${nameOf(m.who)})');
  }
  b.write('Payment by UPI on delivery. – $caregiver');
  return b.toString();
}

String doctorSummary({
  required Parent p,
  required List<Med> meds,
  required Map<String, DoseLog> logs,
  required List<Reading> readings,
  Visit? visit,
  required DateTime now,
}) {
  final t = isoDate(now);
  final from = addDaysIso(t, -6);
  final b = StringBuffer();
  final who = p.full.trim().isEmpty ? p.name : p.full.trim();
  b.writeln('Khayal summary for $who${p.age > 0 ? ' (${p.age})' : ''}, ${shortDate(from)}–${shortDate(t)} ${parseIso(t).year}');
  if (p.conditions.trim().isNotEmpty) b.writeln('Conditions: ${p.conditions.trim()}');
  final c = weekCounts(meds, logs, p.id, now);
  if (c.total > 0) {
    b.writeln('Doses taken: ${(c.taken * 100 / c.total).round()}% (${c.taken} of ${c.total})');
  }
  final bp = recentReadings(readings, p.id, 'bp');
  if (bp.isNotEmpty) {
    final s = bp.map((r) => r.a);
    b.writeln('BP average of last ${bp.length}: ${avgInt(s)}/${avgInt(bp.map((r) => r.b))} '
        '(range ${s.reduce((x, y) => x < y ? x : y)}–${s.reduce((x, y) => x > y ? x : y)} systolic)');
  }
  final sg = recentReadings(readings, p.id, 'sugar');
  if (sg.isNotEmpty) {
    final v = sg.map((r) => r.a);
    b.writeln('Fasting sugar average of last ${sg.length}: ${avgInt(v)} mg/dL '
        '(range ${v.reduce((x, y) => x < y ? x : y)}–${v.reduce((x, y) => x > y ? x : y)})');
  }
  final mine = meds.where((m) => m.who == p.id).toList();
  if (mine.isNotEmpty) {
    b.writeln('Medicines: ${mine.map((m) => '${m.title} ${m.times.map(t12).join('/')}').join('; ')}');
  }
  final notes = <String>[];
  final names = {...c.missed.keys, ...c.late.keys}.toList()..sort();
  for (final n in names) {
    final parts = <String>[];
    if ((c.missed[n] ?? 0) > 0) parts.add('${c.missed[n]} missed');
    if ((c.late[n] ?? 0) > 0) parts.add('${c.late[n]} late');
    notes.add('$n ${parts.join(', ')}');
  }
  b.write('Missed or late doses: ${notes.isEmpty ? 'none' : notes.join('; ')}');
  if (visit != null) b.write('\nFor: ${visit.title}, ${shortDate(visit.date)} at ${t12(visit.time)}');
  return b.toString();
}

String weeklySummary({required AppData d, required DateTime now}) {
  final b = StringBuffer('Khayal weekly summary, week to ${shortDate(isoDate(now))}\n');
  for (final p in d.parents) {
    final c = weekCounts(d.meds, d.logs, p.id, now);
    final pct = c.total == 0 ? '-' : '${(c.taken * 100 / c.total).round()}%';
    final missed = c.missed.values.fold<int>(0, (a, v) => a + v);
    b.write('\n${p.name}: $pct of doses taken, $missed missed');
    final bp = recentReadings(d.readings, p.id, 'bp', n: 1);
    if (bp.isNotEmpty) b.write(', last BP ${bp.first.label}');
    final sg = recentReadings(d.readings, p.id, 'sugar', n: 1);
    if (sg.isNotEmpty) b.write(', last sugar ${sg.first.label}');
    final low = lowStock(d.meds.where((m) => m.who == p.id).toList());
    if (low.isNotEmpty) b.write('. Running low: ${low.map((m) => m.name).join(', ')}');
  }
  return b.toString();
}

// ---------------- presets ----------------

const foods = ['after', 'before', 'empty', 'any'];
const presetTimes = ['06:30', '07:30', '08:00', '08:30', '09:00', '13:00', '14:00', '20:00', '20:30', '21:30'];
const pillColors = [0xFFF4F4F0, 0xFFF7D9DE, 0xFFDDEAF7, 0xFFF6E6A8, 0xFFF2E5C9, 0xFFCFE8D5, 0xFFE3C4A8, 0xFFE8D5F2];
const parentColors = [0xFF1D5C7A, 0xFFB5602B, 0xFF7A4FB5, 0xFF5E7A2B];
const stepChoices = [30, 60, 90, 120, 180];
const skipReasons = ['Forgot', 'Felt unwell', 'Ran out', 'Doctor said to stop'];

class MedPreset {
  const MedPreset(this.name, this.strength, this.purpose, this.times, this.food);
  final String name;
  final String strength;
  final String purpose;
  final List<String> times;
  final String food;
}

/// Common medicines to fill the form faster. The user checks times against the prescription.
const medPresets = [
  MedPreset('Metformin', '500 mg', 'for sugar', ['08:30', '20:30'], 'after'),
  MedPreset('Telmisartan', '40 mg', 'for BP', ['08:00'], 'any'),
  MedPreset('Amlodipine', '5 mg', 'for BP', ['21:00'], 'any'),
  MedPreset('Atorvastatin', '10 mg', 'for cholesterol', ['21:30'], 'any'),
  MedPreset('Thyroxine', '50 mcg', 'for thyroid', ['06:30'], 'empty'),
  MedPreset('Pantoprazole', '40 mg', 'for acidity', ['07:30'], 'before'),
  MedPreset('Calcium + Vitamin D3', '500 mg', 'for bones', ['14:00'], 'after'),
];

// ---------------- Hindi for parent mode ----------------

const hindi = {
  'took': 'मैंने ले ली',
  'later': 'अभी नहीं',
  'next': 'अगली दवा',
  'now': 'अभी लें',
  'missed': 'छूट गई',
  'today': 'आज की दवाइयाँ',
  'call': 'को फ़ोन',
  'help': 'मदद चाहिए',
  'after': 'खाने के बाद',
  'before': 'खाने से पहले',
  'empty': 'खाली पेट',
  'any': '',
  'tablet': 'गोली',
  'capsule': 'कैप्सूल',
  'done': 'आज की सब दवाइयाँ हो गईं',
  'nothing': 'अभी कोई दवा नहीं। समय होने पर यहाँ दिखेगी।',
  'welldone': 'बहुत अच्छे! दवा ले ली गई है।',
  'snoozed': 'ठीक है। दवा लेने तक यह यहीं दिखेगी।',
};

// ---------------- dates ----------------

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime parseIso(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String todayIso() => isoDate(DateTime.now());
String addDaysIso(String s, int n) {
  final d = parseIso(s);
  return isoDate(DateTime(d.year, d.month, d.day + n));
}

int daysBetween(String a, String b) => parseIso(b).difference(parseIso(a)).inHours ~/ 24;

const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
String shortDate(String s) {
  final d = parseIso(s);
  return '${d.day} ${_mon[d.month - 1]}';
}

String dayName(String s) => _dow[parseIso(s).weekday - 1];

/// 'Today', 'Tomorrow', 'Yesterday' or 'Tue 6 Oct'.
String friendlyDate(String s, String today) {
  final n = daysBetween(today, s);
  if (n == 0) return 'Today';
  if (n == 1) return 'Tomorrow';
  if (n == -1) return 'Yesterday';
  return '${dayName(s)} ${shortDate(s)}';
}
