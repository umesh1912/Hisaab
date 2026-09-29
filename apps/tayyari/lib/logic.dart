// Core data model and pure logic for Tayyari. No Flutter imports here.
import 'dart:math' as math;

// ---------------- exam ----------------

const sectionKeys = ['quant', 'reason', 'eng', 'ga'];
const sectionNames = {'quant': 'Quant', 'reason': 'Reasoning', 'eng': 'English', 'ga': 'General Awareness'};
const sectionShort = {'quant': 'Quant', 'reason': 'Reasoning', 'eng': 'English', 'ga': 'GA'};

/// Topics tracked for mastery, per section.
const syllabus = <String, List<String>>{
  'quant': ['Percentages', 'Profit and loss', 'Time and work', 'Geometry', 'Data interpretation'],
  'reason': ['Series', 'Coding-decoding', 'Syllogism', 'Blood relations'],
  'eng': ['Synonyms', 'Error spotting', 'Fill in the blanks', 'Idioms'],
  'ga': ['Polity', 'History', 'Geography', 'Economy', 'Static GK'],
};

/// SSC CGL Tier 1: 25 questions a section, +2 for right, −0.5 for wrong, 60 minutes for 100.
const questionsPerSection = 25;
const markRight = 2.0;
const markWrong = 0.5;
const examSecondsPerQuestion = 36;
const relaxedSecondsPerQuestion = 84;
const newPerDay = 10;

String secName(String sec) => sectionNames[sec] ?? sec;

// ---------------- questions ----------------

class Question {
  const Question({
    required this.id,
    required this.sec,
    required this.topic,
    required this.q,
    required this.o,
    required this.a,
    required this.ex,
    this.hi,
    this.ohi,
    this.exhi,
    this.src,
    this.noteId,
  });

  final int id;
  final String sec;
  final String topic;
  final String q;
  final List<String> o;
  final int a;
  final String ex;
  final String? hi;
  final List<String>? ohi;
  final String? exhi;
  final String? src;
  final int? noteId;

  bool get hasHindi => hi != null && ohi != null;
  String text(bool hindi) => hindi ? (hi ?? q) : q;
  List<String> options(bool hindi) => hindi ? (ohi ?? o) : o;
  String explanation(bool hindi) => hindi ? (exhi ?? ex) : ex;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sec': sec,
        'topic': topic,
        'q': q,
        'o': o,
        'a': a,
        'ex': ex,
        if (hi != null) 'hi': hi,
        if (ohi != null) 'ohi': ohi,
        if (exhi != null) 'exhi': exhi,
        if (src != null) 'src': src,
        if (noteId != null) 'noteId': noteId,
      };

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'] as int,
        sec: j['sec'] as String,
        topic: j['topic'] as String,
        q: j['q'] as String,
        o: (j['o'] as List).map((e) => e as String).toList(),
        a: j['a'] as int,
        ex: (j['ex'] ?? '') as String,
        hi: j['hi'] as String?,
        ohi: j['ohi'] == null ? null : (j['ohi'] as List).map((e) => e as String).toList(),
        exhi: j['exhi'] as String?,
        src: j['src'] as String?,
        noteId: j['noteId'] as int?,
      );
}

// ---------------- revision scheduler ----------------

/// Spaced-repetition state for one question.
class CardState {
  CardState({required this.due, this.ivl = 0, this.ease = 2.5, this.reps = 0, this.lapses = 0, this.confidentMiss = false});
  String due; // yyyy-MM-dd
  int ivl; // days until the next review
  double ease;
  int reps; // correct reviews in a row
  int lapses; // times answered wrong
  bool confidentMiss; // last answer was wrong although the student was certain

  Map<String, dynamic> toJson() => {'due': due, 'ivl': ivl, 'ease': ease, 'reps': reps, 'lapses': lapses, 'cm': confidentMiss};
  factory CardState.fromJson(Map<String, dynamic> j) => CardState(
        due: j['due'] as String,
        ivl: (j['ivl'] ?? 0) as int,
        ease: ((j['ease'] ?? 2.5) as num).toDouble(),
        reps: (j['reps'] ?? 0) as int,
        lapses: (j['lapses'] ?? 0) as int,
        confidentMiss: (j['cm'] ?? false) as bool,
      );
}

class SchedResult {
  const SchedResult(this.ivl, this.ease, this.lapses);
  final int ivl;
  final double ease;
  final int lapses;
}

/// grade: 1 Again, 2 Hard, 3 Good, 4 Easy. Wrong answers (or Again) always come back tomorrow.
SchedResult schedule(CardState c, int grade, bool correct) {
  if (!correct || grade == 1) {
    return SchedResult(1, math.max(1.3, c.ease - 0.2), c.lapses + (correct ? 0 : 1));
  }
  final e = math.max(1.3, c.ease + (grade == 2 ? -0.15 : (grade == 4 ? 0.15 : 0.0)));
  final base = c.reps < 1 ? 1.0 : (c.reps < 2 ? 3.0 : c.ivl * e);
  final factor = grade == 2 ? 0.8 : (grade == 4 ? 1.3 : 1.0);
  final ivl = math.max(1, (base * factor).round());
  return SchedResult(ivl, e, c.lapses);
}

/// Updates [c] after a review done on [today].
void applyReview(CardState c, int grade, bool correct, String today, {bool certain = false}) {
  final r = schedule(c, grade, correct);
  c.ivl = r.ivl;
  c.ease = r.ease;
  c.lapses = r.lapses;
  c.reps = (correct && grade > 1) ? c.reps + 1 : 0;
  c.due = addDaysIso(today, r.ivl);
  c.confidentMiss = !correct && certain;
}

String intervalLabel(int ivl) {
  if (ivl <= 1) return 'tomorrow';
  if (ivl < 30) return '$ivl days';
  return '${(ivl / 30).round()} mo';
}

/// Question ids due on or before [today], most overdue first.
List<int> dueIds(Map<int, CardState> cards, String today, {Set<int>? only}) {
  final ids = cards.entries
      .where((e) => (only == null || only.contains(e.key)) && e.value.due.compareTo(today) <= 0)
      .map((e) => e.key)
      .toList();
  ids.sort((a, b) {
    final c = cards[a]!.due.compareTo(cards[b]!.due);
    return c != 0 ? c : a.compareTo(b);
  });
  return ids;
}

/// Number of questions due on each of the next [days] days; day 0 includes overdue ones.
List<int> dueCounts(Map<int, CardState> cards, String today, {int days = 7, Set<int>? only}) {
  final out = List<int>.filled(days, 0);
  cards.forEach((id, c) {
    if (only != null && !only.contains(id)) return;
    final d = daysBetween(today, c.due);
    if (d <= 0) {
      out[0]++;
    } else if (d < days) {
      out[d]++;
    }
  });
  return out;
}

/// Picks up to [n] questions to practise: overdue first, then new ones, then the ones due soonest.
List<Question> pickPractice(List<Question> pool, Map<int, CardState> cards, String today, int n) {
  String key(Question q) {
    final c = cards[q.id];
    if (c == null) return today;
    return c.due;
  }

  final list = List<Question>.of(pool)
    ..sort((a, b) {
      final k = key(a).compareTo(key(b));
      return k != 0 ? k : a.id.compareTo(b.id);
    });
  return list.take(n).toList();
}

// ---------------- mastery ----------------

/// Exponentially weighted accuracy for one topic.
class TopicStat {
  TopicStat({this.ewma = 0.5, this.n = 0});
  double ewma;
  int n;

  Map<String, dynamic> toJson() => {'e': ewma, 'n': n};
  factory TopicStat.fromJson(Map<String, dynamic> j) =>
      TopicStat(ewma: ((j['e'] ?? 0.5) as num).toDouble(), n: (j['n'] ?? 0) as int);
}

const masteryAlpha = 0.15; // weight of the newest answer
const masteryPrior = 2.0; // pseudo-answers at 50% that pull thin evidence to the middle
const masteryCap = 12; // an EWMA never "remembers" more than about this many answers

String topicKey(String sec, String topic) => '$sec|$topic';

void recordAnswer(TopicStat s, bool correct) {
  final v = correct ? 1.0 : 0.0;
  s.ewma = s.n == 0 ? v : s.ewma * (1 - masteryAlpha) + v * masteryAlpha;
  s.n++;
}

/// 0..1. Recent answers count more; few answers are shrunk towards 50%.
double mastery(TopicStat? s) {
  if (s == null || s.n == 0) return 0.5;
  final ne = math.min(s.n, masteryCap).toDouble();
  return (ne * s.ewma + masteryPrior * 0.5) / (ne + masteryPrior);
}

int pct(double v) => (v * 100).round();

/// The EWMA that makes [mastery] show [target] (0..1) after [n] answers. Used for sample data.
double seedEwma(double target, int n) {
  final ne = math.min(n, masteryCap).toDouble();
  final e = (target * (ne + masteryPrior) - masteryPrior * 0.5) / ne;
  return e.clamp(0.0, 1.0).toDouble();
}

class TopicMastery {
  const TopicMastery(this.sec, this.topic, this.value, this.n);
  final String sec;
  final String topic;
  final double value;
  final int n;
  int get percent => pct(value);
  bool get started => n > 0;
}

List<TopicMastery> topicMasteries(Map<String, TopicStat> stats, String sec) => [
      for (final t in syllabus[sec] ?? const <String>[])
        TopicMastery(sec, t, mastery(stats[topicKey(sec, t)]), stats[topicKey(sec, t)]?.n ?? 0),
    ];

/// Weakest first. Topics not started count as 50%.
List<TopicMastery> weakestTopics(Map<String, TopicStat> stats, String sec) =>
    topicMasteries(stats, sec)..sort((a, b) => a.value.compareTo(b.value));

/// Section mastery in percent, or null when nothing in the section has been answered.
int? sectionMastery(Map<String, TopicStat> stats, String sec) {
  var w = 0.0, sum = 0.0;
  for (final t in topicMasteries(stats, sec)) {
    if (!t.started) continue;
    final ne = math.min(t.n, masteryCap).toDouble();
    w += ne;
    sum += ne * t.value;
  }
  if (w == 0) return null;
  return pct(sum / w);
}

/// The weakest topic inside the weakest section.
TopicMastery weakestOverall(Map<String, TopicStat> stats) {
  var best = sectionKeys.first;
  var bestV = 101;
  for (final s in sectionKeys) {
    final v = sectionMastery(stats, s) ?? 50;
    if (v < bestV) {
      bestV = v;
      best = s;
    }
  }
  return weakestTopics(stats, best).first;
}

// ---------------- tests and scoring ----------------

class SectionScore {
  SectionScore({this.right = 0, this.wrong = 0, this.skipped = 0});
  int right;
  int wrong;
  int skipped;

  int get total => right + wrong + skipped;
  double get marks => right * markRight - wrong * markWrong;
  double get maxMarks => total * markRight;

  Map<String, dynamic> toJson() => {'r': right, 'w': wrong, 's': skipped};
  factory SectionScore.fromJson(Map<String, dynamic> j) =>
      SectionScore(right: (j['r'] ?? 0) as int, wrong: (j['w'] ?? 0) as int, skipped: (j['s'] ?? 0) as int);
}

class MockResult {
  MockResult({
    required this.id,
    required this.name,
    required this.date,
    required this.kind,
    required this.sections,
    this.confidentWrong = 0,
    this.seconds = 0,
    List<int>? qids,
    Map<int, int>? answers,
    Map<int, int>? sure,
  })  : qids = qids ?? [],
        answers = answers ?? {},
        sure = sure ?? {};

  final int id;
  String name;
  final String date;
  final String kind; // 'full' | 'sectional' | 'manual'
  final Map<String, SectionScore> sections;
  int confidentWrong;
  int seconds;
  final List<int> qids; // empty for mocks entered by hand
  final Map<int, int> answers; // question id -> chosen option
  final Map<int, int> sure; // question id -> 0 guessing, 1 fairly sure, 2 certain

  int get right => sections.values.fold<int>(0, (a, s) => a + s.right);
  int get wrong => sections.values.fold<int>(0, (a, s) => a + s.wrong);
  int get skipped => sections.values.fold<int>(0, (a, s) => a + s.skipped);
  int get questions => sections.values.fold<int>(0, (a, s) => a + s.total);
  double get score => right * markRight - wrong * markWrong;
  double get negative => wrong * markWrong;
  double get maxMarks => questions * markRight;
  bool get isFull => maxMarks == 200.0;
  bool get reviewable => qids.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date,
        'kind': kind,
        'sections': sections.map((k, v) => MapEntry(k, v.toJson())),
        'cw': confidentWrong,
        'sec': seconds,
        'qids': qids,
        'answers': answers.map((k, v) => MapEntry('$k', v)),
        'sure': sure.map((k, v) => MapEntry('$k', v)),
      };

  factory MockResult.fromJson(Map<String, dynamic> j) => MockResult(
        id: j['id'] as int,
        name: j['name'] as String,
        date: j['date'] as String,
        kind: (j['kind'] ?? 'manual') as String,
        sections: ((j['sections'] ?? {}) as Map)
            .map((k, v) => MapEntry(k as String, SectionScore.fromJson(Map<String, dynamic>.from(v as Map)))),
        confidentWrong: (j['cw'] ?? 0) as int,
        seconds: (j['sec'] ?? 0) as int,
        qids: ((j['qids'] ?? []) as List).map((e) => e as int).toList(),
        answers: ((j['answers'] ?? {}) as Map).map((k, v) => MapEntry(int.parse(k as String), v as int)),
        sure: ((j['sure'] ?? {}) as Map).map((k, v) => MapEntry(int.parse(k as String), v as int)),
      );
}

/// Scores a finished test with SSC CGL marking (+2 right, −0.5 wrong, 0 skipped).
MockResult scoreTest({
  required int id,
  required String name,
  required String date,
  required String kind,
  required List<Question> questions,
  required Map<int, int> answers,
  Map<int, int> sure = const {},
  int seconds = 0,
}) {
  final sections = <String, SectionScore>{};
  for (final s in sectionKeys) {
    if (questions.any((q) => q.sec == s)) sections[s] = SectionScore();
  }
  var cw = 0;
  for (final q in questions) {
    final s = sections.putIfAbsent(q.sec, () => SectionScore());
    final a = answers[q.id];
    if (a == null) {
      s.skipped++;
    } else if (a == q.a) {
      s.right++;
    } else {
      s.wrong++;
      if (sure[q.id] == 2) cw++;
    }
  }
  return MockResult(
    id: id,
    name: name,
    date: date,
    kind: kind,
    sections: sections,
    confidentWrong: cw,
    seconds: seconds,
    qids: questions.map((q) => q.id).toList(),
    answers: Map<int, int>.of(answers),
    sure: Map<int, int>.of(sure),
  );
}

/// Average marks from answering a question at random among [options] remaining choices.
/// With 4 options at +2/−0.5 this is +0.125, so a blind guess gains marks on average.
double guessValue(int options, {double right = markRight, double wrong = markWrong}) {
  if (options <= 0) return 0;
  return (right - (options - 1) * wrong) / options;
}

/// "142.5", "142", "-1.5".
String fmtMarks(double v) {
  final r = (v * 2).round() / 2;
  if (r == r.roundToDouble()) return r.toInt().toString();
  return r.toStringAsFixed(1);
}

String fmtClock(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final m = s ~/ 60, r = s % 60;
  return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
}

String fmtMinutes(int seconds) {
  final m = (seconds / 60).round();
  if (m < 60) return '$m min';
  return '${m ~/ 60} h ${m % 60} min';
}

// ---------------- study log ----------------

/// Consecutive study days ending today (or yesterday, if today has no study yet).
int streak(Map<String, int> minutes, String today) {
  var d = today;
  if ((minutes[d] ?? 0) <= 0) d = addDaysIso(d, -1);
  var n = 0;
  while ((minutes[d] ?? 0) > 0) {
    n++;
    d = addDaysIso(d, -1);
  }
  return n;
}

/// 0 = no study, 1 = under an hour, 2 = 1–2 h, 3 = 2–3 h, 4 = 3 h or more.
int heatLevel(int minutes) {
  if (minutes <= 0) return 0;
  if (minutes < 60) return 1;
  if (minutes < 120) return 2;
  if (minutes < 180) return 3;
  return 4;
}

// ---------------- app data ----------------

class Profile {
  Profile({required this.name, required this.city, required this.exam, required this.examDate, this.target = 150});
  String name;
  String city;
  String exam;
  String examDate;
  int target; // out of 200

  Map<String, dynamic> toJson() => {'name': name, 'city': city, 'exam': exam, 'examDate': examDate, 'target': target};
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: j['name'] as String,
        city: (j['city'] ?? '') as String,
        exam: (j['exam'] ?? 'SSC CGL Tier 1') as String,
        examDate: j['examDate'] as String,
        target: (j['target'] ?? 150) as int,
      );
}

class StudyNote {
  StudyNote({required this.id, required this.name, required this.sec, required this.topic, required this.at});
  final int id;
  String name;
  String sec;
  String topic;
  final String at;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'sec': sec, 'topic': topic, 'at': at};
  factory StudyNote.fromJson(Map<String, dynamic> j) => StudyNote(
        id: j['id'] as int,
        name: j['name'] as String,
        sec: j['sec'] as String,
        topic: j['topic'] as String,
        at: j['at'] as String,
      );
}

/// Which of today's three plan items are done.
class DayPlan {
  DayPlan({required this.date, this.rev = false, this.learn = false, this.test = false});
  final String date;
  bool rev;
  bool learn;
  bool test;

  Map<String, dynamic> toJson() => {'date': date, 'rev': rev, 'learn': learn, 'test': test};
  factory DayPlan.fromJson(Map<String, dynamic> j) => DayPlan(
        date: j['date'] as String,
        rev: (j['rev'] ?? false) as bool,
        learn: (j['learn'] ?? false) as bool,
        test: (j['test'] ?? false) as bool,
      );
}

/// One topic block in the week plan.
class PlanBlock {
  PlanBlock({required this.date, required this.sec, required this.topic, this.done = false});
  final String date;
  final String sec;
  final String topic;
  bool done;

  Map<String, dynamic> toJson() => {'date': date, 'sec': sec, 'topic': topic, 'done': done};
  factory PlanBlock.fromJson(Map<String, dynamic> j) => PlanBlock(
        date: j['date'] as String,
        sec: j['sec'] as String,
        topic: j['topic'] as String,
        done: (j['done'] ?? false) as bool,
      );
}

class AppData {
  AppData({
    required this.profile,
    this.lang = 'en',
    Map<int, CardState>? cards,
    Map<String, TopicStat>? stats,
    List<Question>? custom,
    List<StudyNote>? notes,
    List<MockResult>? mocks,
    Map<String, int>? minutes,
    DayPlan? plan,
    List<PlanBlock>? week,
    this.lastNewDay = '',
    this.nextId = 1000,
  })  : cards = cards ?? {},
        stats = stats ?? {},
        custom = custom ?? [],
        notes = notes ?? [],
        mocks = mocks ?? [],
        minutes = minutes ?? {},
        plan = plan ?? DayPlan(date: ''),
        week = week ?? [];

  Profile profile;
  String lang; // 'en' | 'hi'
  Map<int, CardState> cards;
  Map<String, TopicStat> stats;
  List<Question> custom; // questions typed in from the student's notes
  List<StudyNote> notes;
  List<MockResult> mocks;
  Map<String, int> minutes; // study minutes per day
  DayPlan plan;
  List<PlanBlock> week;
  String lastNewDay;
  int nextId;

  int newId() => nextId++;

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'lang': lang,
        'cards': cards.map((k, v) => MapEntry('$k', v.toJson())),
        'stats': stats.map((k, v) => MapEntry(k, v.toJson())),
        'custom': custom.map((e) => e.toJson()).toList(),
        'notes': notes.map((e) => e.toJson()).toList(),
        'mocks': mocks.map((e) => e.toJson()).toList(),
        'minutes': minutes,
        'plan': plan.toJson(),
        'week': week.map((e) => e.toJson()).toList(),
        'lastNewDay': lastNewDay,
        'nextId': nextId,
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    List<T> l<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] ?? []) as List).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    Map<String, dynamic> m(String k) => Map<String, dynamic>.from((j[k] ?? {}) as Map);
    return AppData(
      profile: Profile.fromJson(m('profile')),
      lang: (j['lang'] ?? 'en') as String,
      cards: m('cards').map((k, v) => MapEntry(int.parse(k), CardState.fromJson(Map<String, dynamic>.from(v as Map)))),
      stats: m('stats').map((k, v) => MapEntry(k, TopicStat.fromJson(Map<String, dynamic>.from(v as Map)))),
      custom: l('custom', Question.fromJson),
      notes: l('notes', StudyNote.fromJson),
      mocks: l('mocks', MockResult.fromJson),
      minutes: m('minutes').map((k, v) => MapEntry(k, v as int)),
      plan: j['plan'] == null ? null : DayPlan.fromJson(m('plan')),
      week: l('week', PlanBlock.fromJson),
      lastNewDay: (j['lastNewDay'] ?? '') as String,
      nextId: (j['nextId'] ?? 1000) as int,
    );
  }
}

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

int daysBetween(String a, String b) => (parseIso(b).difference(parseIso(a)).inHours / 24).round();

const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String shortDate(String s) {
  final d = parseIso(s);
  return '${d.day} ${_mon[d.month - 1]}';
}

String longDate(String s) {
  final d = parseIso(s);
  return '${d.day} ${_mon[d.month - 1]} ${d.year}';
}

String dayName(String s) => _dow[parseIso(s).weekday - 1];
