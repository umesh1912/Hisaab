// Core data model and pure logic for Jodi, a habit tracker for two partners.
// No Flutter imports here so everything can be unit tested.
//
// Dates are stored as 'yyyy-MM-dd' strings (they sort correctly as text).
// Times are stored as 'HH:mm' (24-hour).
//
// Streak rules ("never miss twice"):
// - Each person gets one skip per week (Mon–Sun), shared across all their habits.
// - The first missed scheduled day in a week is a skip: the streak survives but does not grow.
// - Any further miss that week breaks the streak of the habit that was missed.
// - Days while the partnership is paused don't count at all.

const me = 'me';
const them = 'them';

class CheckIn {
  CheckIn({required this.at, this.note = '', this.effort = 'OK', this.byPartnerLog = false});
  final String at; // HH:mm
  final String note;
  final String effort; // Easy | OK | Tough
  /// True when you logged it on your partner's behalf (they told you they did it).
  final bool byPartnerLog;

  Map<String, dynamic> toJson() => {'at': at, 'note': note, 'effort': effort, 'byPartnerLog': byPartnerLog};
  factory CheckIn.fromJson(Map<String, dynamic> j) => CheckIn(
        at: (j['at'] ?? '12:00') as String,
        note: (j['note'] ?? '') as String,
        effort: (j['effort'] ?? 'OK') as String,
        byPartnerLog: (j['byPartnerLog'] ?? false) as bool,
      );
}

class Habit {
  Habit({
    required this.id,
    required this.owner,
    required this.name,
    required this.cue,
    required this.days,
    required this.createdOn,
    this.proof = false,
    this.shared = true,
    Map<String, CheckIn>? log,
  }) : log = log ?? {};

  final int id;
  final String owner; // me | them
  String name;
  String cue; // e.g. "After dinner"
  List<bool> days; // Mon..Sun
  String createdOn;
  bool proof;
  bool shared;
  Map<String, CheckIn> log; // date -> check-in

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner': owner,
        'name': name,
        'cue': cue,
        'days': days,
        'createdOn': createdOn,
        'proof': proof,
        'shared': shared,
        'log': log.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory Habit.fromJson(Map<String, dynamic> j) {
    final rawDays = ((j['days'] ?? []) as List).map((e) => e == true).toList();
    while (rawDays.length < 7) {
      rawDays.add(true);
    }
    return Habit(
      id: j['id'] as int,
      owner: (j['owner'] ?? me) as String,
      name: j['name'] as String,
      cue: (j['cue'] ?? '') as String,
      days: rawDays.sublist(0, 7),
      createdOn: j['createdOn'] as String,
      proof: (j['proof'] ?? false) as bool,
      shared: (j['shared'] ?? true) as bool,
      log: ((j['log'] ?? {}) as Map).map(
        (k, v) => MapEntry(k as String, CheckIn.fromJson(Map<String, dynamic>.from(v as Map))),
      ),
    );
  }
}

class FeedEvent {
  FeedEvent({required this.id, required this.who, required this.text, this.note = '', required this.date, required this.at, this.react});
  final int id;
  final String who; // me | them
  final String text;
  final String note;
  final String date;
  final String at;
  /// For their events: your reaction. For your events: their reaction.
  String? react;

  Map<String, dynamic> toJson() => {'id': id, 'who': who, 'text': text, 'note': note, 'date': date, 'at': at, 'react': react};
  factory FeedEvent.fromJson(Map<String, dynamic> j) => FeedEvent(
        id: j['id'] as int,
        who: (j['who'] ?? me) as String,
        text: j['text'] as String,
        note: (j['note'] ?? '') as String,
        date: j['date'] as String,
        at: (j['at'] ?? '12:00') as String,
        react: j['react'] as String?,
      );
}

class Nudge {
  Nudge({required this.habitId, required this.date, required this.message});
  final int habitId;
  final String date;
  final String message;

  Map<String, dynamic> toJson() => {'habitId': habitId, 'date': date, 'message': message};
  factory Nudge.fromJson(Map<String, dynamic> j) =>
      Nudge(habitId: j['habitId'] as int, date: j['date'] as String, message: (j['message'] ?? '') as String);
}

class Pause {
  Pause({required this.from, this.to});
  final String from; // first paused day
  String? to; // day the partnership resumed (not paused); null while paused

  Map<String, dynamic> toJson() => {'from': from, 'to': to};
  factory Pause.fromJson(Map<String, dynamic> j) => Pause(from: j['from'] as String, to: j['to'] as String?);
}

/// Sunday check-in answers for one person for one week (keyed by the Monday of that week).
class Reflection {
  Reflection({required this.week, required this.who, required this.answers});
  final String week;
  final String who;
  final List<String> answers;

  Map<String, dynamic> toJson() => {'week': week, 'who': who, 'answers': answers};
  factory Reflection.fromJson(Map<String, dynamic> j) => Reflection(
        week: j['week'] as String,
        who: j['who'] as String,
        answers: ((j['answers'] ?? []) as List).map((e) => e.toString()).toList(),
      );
}

class AppData {
  AppData({
    required this.meName,
    required this.partnerName,
    this.meCity = '',
    this.partnerCity = '',
    required this.pairedOn,
    this.pact = 'The one below 80% this week buys chai',
    this.target = 80,
    List<Habit>? habits,
    List<FeedEvent>? feed,
    List<Nudge>? nudges,
    List<Pause>? pauses,
    List<Reflection>? reflections,
    List<String>? matchRequests,
    this.shareNotes = true,
    this.showNudges = true,
    this.simulatePartner = false,
    this.simulatedTo,
    this.nextId = 1000,
  })  : habits = habits ?? [],
        feed = feed ?? [],
        nudges = nudges ?? [],
        pauses = pauses ?? [],
        reflections = reflections ?? [],
        matchRequests = matchRequests ?? [];

  String meName;
  String partnerName;
  String meCity;
  String partnerCity;
  String pairedOn;
  String pact;
  int target; // percent
  List<Habit> habits;
  List<FeedEvent> feed;
  List<Nudge> nudges;
  List<Pause> pauses;
  List<Reflection> reflections;
  List<String> matchRequests;
  bool shareNotes;
  bool showNudges;
  /// Sample mode: the partner's check-ins are simulated day by day.
  bool simulatePartner;
  String? simulatedTo;
  int nextId;

  int newId() => nextId++;

  bool get paused => pauses.isNotEmpty && pauses.last.to == null;
  List<Habit> habitsOf(String who) => habits.where((h) => h.owner == who).toList();
  String nameOf(String who) => who == me ? meName : partnerName;

  Habit? habit(int id) {
    for (final h in habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'meName': meName,
        'partnerName': partnerName,
        'meCity': meCity,
        'partnerCity': partnerCity,
        'pairedOn': pairedOn,
        'pact': pact,
        'target': target,
        'habits': habits.map((e) => e.toJson()).toList(),
        'feed': feed.map((e) => e.toJson()).toList(),
        'nudges': nudges.map((e) => e.toJson()).toList(),
        'pauses': pauses.map((e) => e.toJson()).toList(),
        'reflections': reflections.map((e) => e.toJson()).toList(),
        'matchRequests': matchRequests,
        'shareNotes': shareNotes,
        'showNudges': showNudges,
        'simulatePartner': simulatePartner,
        'simulatedTo': simulatedTo,
        'nextId': nextId,
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    List<T> l<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] ?? []) as List).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    return AppData(
      meName: j['meName'] as String,
      partnerName: j['partnerName'] as String,
      meCity: (j['meCity'] ?? '') as String,
      partnerCity: (j['partnerCity'] ?? '') as String,
      pairedOn: j['pairedOn'] as String,
      pact: (j['pact'] ?? '') as String,
      target: (j['target'] ?? 80) as int,
      habits: l('habits', Habit.fromJson),
      feed: l('feed', FeedEvent.fromJson),
      nudges: l('nudges', Nudge.fromJson),
      pauses: l('pauses', Pause.fromJson),
      reflections: l('reflections', Reflection.fromJson),
      matchRequests: ((j['matchRequests'] ?? []) as List).map((e) => e.toString()).toList(),
      shareNotes: (j['shareNotes'] ?? true) as bool,
      showNudges: (j['showNudges'] ?? true) as bool,
      simulatePartner: (j['simulatePartner'] ?? false) as bool,
      simulatedTo: j['simulatedTo'] as String?,
      nextId: (j['nextId'] ?? 1000) as int,
    );
  }
}

// ---------------- schedule and streaks ----------------

enum DayState { done, skip, miss, pending, rest, future }

bool isPausedOn(String date, List<Pause> pauses) {
  for (final p in pauses) {
    final to = p.to;
    if (date.compareTo(p.from) >= 0 && (to == null || date.compareTo(to) < 0)) return true;
  }
  return false;
}

/// Whether [h] should be done on [date].
bool scheduledOn(Habit h, String date, List<Pause> pauses) =>
    date.compareTo(h.createdOn) >= 0 && h.days[weekdayIndex(date)] && !isPausedOn(date, pauses);

/// State of every day for every habit of ONE person, from the oldest habit up to [today].
/// Skips are shared across that person's habits: the first miss of each week is a skip.
Map<int, Map<String, DayState>> dayStates(List<Habit> habits, String today, List<Pause> pauses, {int maxDays = 400}) {
  final out = {for (final h in habits) h.id: <String, DayState>{}};
  if (habits.isEmpty) return out;
  var start = habits.map((h) => h.createdOn).reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
  final floor = addDaysIso(today, -maxDays);
  if (start.compareTo(floor) < 0) start = floor;
  if (start.compareTo(today) > 0) start = today;
  final sorted = [...habits]..sort((a, b) => a.id.compareTo(b.id));
  final skipUsed = <String>{};
  for (var d = start; d.compareTo(today) <= 0; d = addDaysIso(d, 1)) {
    final wk = weekStartIso(d);
    for (final h in sorted) {
      DayState s;
      if (h.log.containsKey(d)) {
        s = DayState.done;
      } else if (!scheduledOn(h, d, pauses)) {
        s = DayState.rest;
      } else if (d == today) {
        s = DayState.pending;
      } else if (!skipUsed.contains(wk)) {
        skipUsed.add(wk);
        s = DayState.skip;
      } else {
        s = DayState.miss;
      }
      out[h.id]![d] = s;
    }
  }
  return out;
}

/// Consecutive done days counting back from today. Skips and rest days don't break it.
int currentStreak(Map<String, DayState> states, String today) {
  var n = 0;
  for (var d = today; states.containsKey(d); d = addDaysIso(d, -1)) {
    final s = states[d]!;
    if (s == DayState.done) {
      n++;
    } else if (s == DayState.miss) {
      break;
    }
  }
  return n;
}

int bestStreak(Map<String, DayState> states) {
  final keys = states.keys.toList()..sort();
  var best = 0, run = 0;
  for (final k in keys) {
    final s = states[k]!;
    if (s == DayState.done) {
      run++;
      if (run > best) best = run;
    } else if (s == DayState.miss) {
      run = 0;
    }
  }
  return best;
}

/// Percent of scheduled days that were done, from [from] (inclusive). Today (pending) is ignored.
int successRate(Map<String, DayState> states, {String? from}) {
  var done = 0, total = 0;
  states.forEach((d, s) {
    if (from != null && d.compareTo(from) < 0) return;
    if (s == DayState.done) {
      done++;
      total++;
    } else if (s == DayState.skip || s == DayState.miss) {
      total++;
    }
  });
  return total == 0 ? 0 : (done * 100 / total).round();
}

class WeekScore {
  const WeekScore(this.done, this.of);
  final int done;
  final int of;
  int get pct => percent(done, of);
}

int percent(int done, int of) => of <= 0 ? 0 : (done * 100 / of).round();

/// This week's score for one person: check-ins done vs scheduled for the whole week (Mon–Sun).
/// Skipped days count as neither done nor scheduled.
WeekScore weekScore(List<Habit> habits, Map<int, Map<String, DayState>> states, String today, List<Pause> pauses) {
  final start = weekStartIso(today);
  var done = 0, of = 0;
  for (var i = 0; i < 7; i++) {
    final d = addDaysIso(start, i);
    for (final h in habits) {
      if (d.compareTo(today) <= 0) {
        final s = states[h.id]?[d];
        if (s == DayState.done) {
          done++;
          of++;
        } else if (s == DayState.miss || s == DayState.pending) {
          of++;
        }
      } else if (scheduledOn(h, d, pauses)) {
        of++;
      }
    }
  }
  return WeekScore(done, of);
}

/// 1 if the person's weekly skip is still unused, else 0.
int skipsLeft(Map<int, Map<String, DayState>> states, String today) {
  final start = weekStartIso(today);
  for (final m in states.values) {
    for (final e in m.entries) {
      if (e.value == DayState.skip && e.key.compareTo(start) >= 0 && e.key.compareTo(today) <= 0) return 0;
    }
  }
  return 1;
}

/// The 56 days shown in the heat map: 8 weeks, Monday first, ending with this week.
List<String> heatDates(String today) {
  final start = addDaysIso(weekStartIso(today), -49);
  return [for (var i = 0; i < 56; i++) addDaysIso(start, i)];
}

DayState cellState(Map<String, DayState> states, String date, String today) =>
    states[date] ?? (date.compareTo(today) > 0 ? DayState.future : DayState.rest);

/// One-line verdict for the weekly pact.
String pactVerdict(WeekScore mine, WeekScore theirs, int target, String partner) {
  final a = mine.pct >= target, b = theirs.pct >= target;
  if (mine.of == 0 && theirs.of == 0) return 'No habits scheduled this week yet';
  if (a && b) return 'You are both at $target% or more';
  if (!a && b) return 'You are below $target% so far';
  if (a && !b) return '$partner is below $target% so far';
  return 'You are both below $target% so far';
}

bool canNudge(List<Nudge> nudges, int habitId, String today) =>
    !nudges.any((n) => n.habitId == habitId && n.date == today);

// ---------------- habit wording ----------------

const _cueStarts = ['after ', 'before ', 'when ', 'at ', 'once ', 'on ', 'every ', 'while ', 'refill '];

/// Turns what the user typed into a cue. "brush my teeth" -> "After I brush my teeth";
/// "after dinner" -> "After dinner".
String normalizeCue(String input) {
  final t = input.trim();
  if (t.isEmpty) return '';
  final lower = t.toLowerCase();
  if (_cueStarts.any((s) => lower.startsWith(s))) return t[0].toUpperCase() + t.substring(1);
  return 'After I $t';
}

/// The editable part of a cue: strips a leading "After I ".
String cueBody(String cue) => cue.toLowerCase().startsWith('after i ') ? cue.substring(8) : cue;

/// "After dinner, I will read 20 pages."
String planText(String cue, String name) {
  final n = name.trim().isEmpty ? '…' : lowerFirst(name.trim());
  final c = cue.trim().isEmpty ? 'Each day' : cue.trim();
  return '$c, I will $n.';
}

String lowerFirst(String s) => s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String daysText(List<bool> days) {
  final n = days.where((d) => d).length;
  if (n == 7) return 'Every day';
  if (n == 0) return 'No days';
  if (n == 5 && days.sublist(0, 5).every((d) => d)) return 'Weekdays';
  if (n == 2 && days[5] && days[6]) return 'Weekends';
  return [for (var i = 0; i < 7; i++) if (days[i]) dayShort[i]].join(', ');
}

// ---------------- sample and simulation ----------------

/// The prototype's little random generator, so sample histories look the same each time.
List<bool> pseudoHistory(int seed, double rate, int len) {
  var x = seed;
  final out = <bool>[];
  for (var i = 0; i < len; i++) {
    x = (x * 9301 + 49297) % 233280;
    out.add(x / 233280 < rate);
  }
  return out;
}

/// Fills [h]'s log from its creation up to yesterday with a pseudo-random history,
/// and makes the last [recentRun] scheduled days done so the streak looks lived-in.
void fillHistory(Habit h, String today, {required int seed, required double rate, int recentRun = 0, String at = '20:30'}) {
  final start = h.createdOn;
  final n = daysBetween(start, today);
  if (n <= 0) return;
  final rnd = pseudoHistory(seed, rate, n);
  for (var i = 0; i < n; i++) {
    final d = addDaysIso(start, i);
    if (h.days[weekdayIndex(d)] && rnd[i]) h.log[d] = CheckIn(at: at);
  }
  var left = recentRun;
  for (var d = addDaysIso(today, -1); left > 0 && d.compareTo(start) >= 0; d = addDaysIso(d, -1)) {
    if (!h.days[weekdayIndex(d)]) continue;
    h.log.putIfAbsent(d, () => CheckIn(at: at));
    left--;
  }
}

int _hash(String s) {
  var h = 2166136261;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 16777619) & 0x7fffffff;
  }
  return h;
}

/// Deterministic yes/no for a simulated partner check-in.
bool simulatedDone(int habitId, String date, int ratePct) => _hash('$habitId|$date') % 100 < ratePct;

/// Sample mode only: fills in the partner's check-ins for days that passed since the app was
/// last opened, and posts a short summary for each of the last few days. Returns true if anything changed.
bool simulatePartner(AppData d, String today) {
  if (!d.simulatePartner) return false;
  final yesterday = addDaysIso(today, -1);
  final last = d.simulatedTo;
  if (last != null && last.compareTo(yesterday) >= 0) return false;
  var from = last == null ? yesterday : addDaysIso(last, 1);
  final floor = addDaysIso(today, -60);
  if (from.compareTo(floor) < 0) from = floor;
  final theirs = d.habitsOf(them);
  for (var day = from; day.compareTo(yesterday) <= 0; day = addDaysIso(day, 1)) {
    var due = 0, done = 0;
    for (final h in theirs) {
      if (!scheduledOn(h, day, d.pauses)) continue;
      due++;
      if (h.log.containsKey(day)) {
        done++;
      } else if (simulatedDone(h.id, day, 80)) {
        h.log[day] = CheckIn(at: '08:15');
        done++;
      }
    }
    if (due > 0 && daysBetween(day, today) <= 3) {
      d.feed.insert(
        0,
        FeedEvent(
          id: d.newId(),
          who: them,
          text: done == due ? '${d.partnerName} finished all $due habits' : '${d.partnerName} checked in $done of $due habits',
          date: day,
          at: '22:00',
        ),
      );
    }
  }
  d.simulatedTo = yesterday;
  return true;
}

// ---------------- dates ----------------

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Parsed as UTC midnight so day arithmetic never trips over daylight saving.
DateTime parseIso(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

String todayIso() => isoDate(DateTime.now());
String addDaysIso(String s, int n) {
  final d = parseIso(s);
  return isoDate(DateTime.utc(d.year, d.month, d.day + n));
}

int daysBetween(String a, String b) => parseIso(b).difference(parseIso(a)).inDays;

/// 0 = Monday … 6 = Sunday.
int weekdayIndex(String s) => parseIso(s).weekday - 1;

/// The Monday of the week containing [s].
String weekStartIso(String s) => addDaysIso(s, -weekdayIndex(s));

/// Days left in the week after today (Sunday = 0).
int daysLeftInWeek(String today) => 6 - weekdayIndex(today);

const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String shortDate(String s) {
  final d = parseIso(s);
  return '${d.day} ${_mon[d.month - 1]}';
}

String dayName(String s) => dayShort[weekdayIndex(s)];

String nowHm() {
  final n = DateTime.now();
  return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
}

/// "16:10" -> "4:10 PM".
String t12(String hm) {
  final p = hm.split(':');
  final h = int.tryParse(p.isNotEmpty ? p[0] : '') ?? 0;
  final m = p.length > 1 ? p[1].padLeft(2, '0') : '00';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:$m ${h < 12 ? 'AM' : 'PM'}';
}

/// Short label for when a feed event happened.
String whenText(String date, String at, String today) {
  final n = daysBetween(date, today);
  if (n <= 0) return t12(at);
  if (n == 1) return 'Yesterday';
  if (n < 7) return dayName(date);
  return shortDate(date);
}

/// "week 6 together".
int weekTogether(String pairedOn, String today) {
  final n = daysBetween(pairedOn, today);
  return n < 0 ? 1 : n ~/ 7 + 1;
}

String initial(String name) => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
