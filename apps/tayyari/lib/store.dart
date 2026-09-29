import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bank.dart';
import 'logic.dart';

/// A revision or practice session in progress. Lives in memory only.
class PracticeSession {
  PracticeSession({required this.ids, required this.kind, required this.title});
  final List<int> ids;
  final String kind; // 'due' | 'section' | 'topic'
  final String title;
  final DateTime started = DateTime.now();
  final results = <bool>[];
  int i = 0;
  int? picked; // chosen option for the current question
  int? sure; // 0 guessing, 1 fairly sure, 2 certain
  int confidentMisses = 0;

  int get current => ids[i];
  bool get answered => picked != null;
}

class SessionSummary {
  const SessionSummary({required this.correct, required this.total, required this.confidentMisses, required this.kind});
  final int correct;
  final int total;
  final int confidentMisses;
  final String kind;
}

/// Holds the app state, saves it on the phone, and exposes actions.
class TayyariStore extends ChangeNotifier {
  static const _key = 'tayyari_data_v1';
  AppData? data;
  bool loaded = false;
  PracticeSession? session;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) data = AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      data = null; // corrupt data: start fresh rather than crash
    }
    loaded = true;
    if (data != null && _introduceNew()) await _save();
    notifyListeners();
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
      // Saving failed (storage full or unavailable). Keep going with the data in memory.
    }
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  // ---------- questions ----------
  List<Question> get allQuestions => [...bank, ...(data?.custom ?? const <Question>[])];

  Question? question(int id) {
    for (final q in bank) {
      if (q.id == id) return q;
    }
    for (final q in data?.custom ?? const <Question>[]) {
      if (q.id == id) return q;
    }
    return null;
  }

  List<Question> questionsIn(String sec, {String? topic}) =>
      allQuestions.where((q) => q.sec == sec && (topic == null || q.topic == topic)).toList();

  bool get hindi => data?.lang == 'hi';
  Set<int> get _validIds => allQuestions.map((q) => q.id).toSet();
  List<int> get due => data == null ? const [] : dueIds(data!.cards, todayIso(), only: _validIds);
  List<int> get dueWeek => dueCounts(data!.cards, todayIso(), only: _validIds);
  int get confidentMissCount => data!.cards.values.where((c) => c.confidentMiss).length;

  // ---------- plan ----------
  DayPlan get plan {
    final d = data!;
    final t = todayIso();
    if (d.plan.date != t) d.plan = DayPlan(date: t);
    return d.plan;
  }

  PlanBlock? get todayBlock {
    final t = todayIso();
    for (final b in data!.week) {
      if (b.date == t) return b;
    }
    return null;
  }

  /// The topic to learn today: this week's block if there is one, otherwise the weakest topic.
  TopicMastery get learnTarget {
    final d = data!;
    final b = todayBlock;
    if (b != null) {
      final s = d.stats[topicKey(b.sec, b.topic)];
      return TopicMastery(b.sec, b.topic, mastery(s), s?.n ?? 0);
    }
    return weakestOverall(d.stats);
  }

  List<MockResult> get mocksByDate => List<MockResult>.of(data!.mocks)..sort((a, b) => a.date.compareTo(b.date));

  MockResult? get lastFull {
    final full = mocksByDate.where((m) => m.isFull).toList();
    return full.isEmpty ? null : full.last;
  }

  /// Section with the lowest marks in the last full mock (Quant if there is none).
  String get testSection {
    final m = lastFull;
    if (m == null) return 'quant';
    var best = 'quant';
    var low = double.infinity;
    for (final s in sectionKeys) {
      final sc = m.sections[s];
      if (sc != null && sc.marks < low) {
        low = sc.marks;
        best = s;
      }
    }
    return best;
  }

  MockResult? mock(int id) {
    for (final m in data?.mocks ?? const <MockResult>[]) {
      if (m.id == id) return m;
    }
    return null;
  }

  StudyNote? note(int id) {
    for (final n in data?.notes ?? const <StudyNote>[]) {
      if (n.id == id) return n;
    }
    return null;
  }

  List<Question> noteQuestions(int noteId) => data!.custom.where((q) => q.noteId == noteId).toList();

  // ---------- setup ----------
  void setup({required String name, required String city, required String exam, required String examDate, required int target}) {
    data = AppData(
      profile: Profile(name: name, city: city, exam: exam, examDate: examDate, target: target),
      plan: DayPlan(date: todayIso()),
    );
    session = null;
    _introduceNew();
    _changed();
  }

  void loadSample() {
    data = sampleData();
    session = null;
    _changed();
  }

  void resetAll() {
    data = null;
    session = null;
    _changed();
  }

  void toggleLang() {
    final d = data;
    if (d == null) return;
    d.lang = d.lang == 'hi' ? 'en' : 'hi';
    _changed();
  }

  void updateProfile({required String name, required String city, required String exam, required String examDate, required int target}) {
    final p = data!.profile;
    if (name.trim().isNotEmpty) p.name = name.trim();
    p.city = city.trim();
    if (exam.trim().isNotEmpty) p.exam = exam.trim();
    p.examDate = examDate;
    p.target = target;
    _changed();
  }

  /// Once a day, adds up to [newPerDay] unseen bank questions (one section at a time) to today's revision.
  bool _introduceNew() {
    final d = data;
    if (d == null) return false;
    final t = todayIso();
    if (d.lastNewDay == t) return false;
    d.lastNewDay = t;
    if (dueIds(d.cards, t).length >= 30) return true; // enough to do already
    final unseen = {for (final s in sectionKeys) s: bank.where((q) => q.sec == s && !d.cards.containsKey(q.id)).toList()};
    var added = 0;
    var round = 0;
    while (added < newPerDay && round < questionsPerSection) {
      for (final s in sectionKeys) {
        final list = unseen[s]!;
        if (round < list.length && added < newPerDay) {
          d.cards[list[round].id] = CardState(due: t);
          added++;
        }
      }
      round++;
    }
    return true;
  }

  // ---------- practice sessions ----------
  void startSession(List<int> ids, String kind, String title) {
    if (ids.isEmpty) return;
    session = PracticeSession(ids: List<int>.of(ids), kind: kind, title: title);
    notifyListeners();
  }

  void setSure(int v) {
    final s = session;
    if (s == null || s.answered) return;
    s.sure = v;
    notifyListeners();
  }

  void answer(int option) {
    final s = session;
    if (s == null || s.answered) return;
    s.sure ??= 1;
    s.picked = option;
    notifyListeners();
  }

  /// Rates the answered question and moves on. Returns a summary when the session ends.
  SessionSummary? grade(int g) {
    final s = session;
    final d = data;
    if (s == null || d == null || !s.answered) return null;
    final t = todayIso();
    final q = question(s.current);
    if (q != null) {
      final correct = s.picked == q.a;
      final card = d.cards.putIfAbsent(q.id, () => CardState(due: t));
      applyReview(card, g, correct, t, certain: s.sure == 2);
      recordAnswer(d.stats.putIfAbsent(topicKey(q.sec, q.topic), () => TopicStat()), correct);
      s.results.add(correct);
      if (!correct && s.sure == 2) s.confidentMisses++;
    }
    s.i++;
    s.picked = null;
    s.sure = null;
    if (s.i < s.ids.length) {
      _changed();
      return null;
    }
    _logStudy(DateTime.now().difference(s.started).inSeconds);
    if (s.kind == 'due') plan.rev = true;
    if (s.kind == 'topic') {
      plan.learn = true;
      final b = todayBlock;
      if (b != null) b.done = true;
    }
    session = null;
    _changed();
    return SessionSummary(
      correct: s.results.where((r) => r).length,
      total: s.results.length,
      confidentMisses: s.confidentMisses,
      kind: s.kind,
    );
  }

  void endSession() {
    final s = session;
    if (s == null) return;
    if (s.results.isNotEmpty) _logStudy(DateTime.now().difference(s.started).inSeconds);
    session = null;
    _changed();
  }

  void _logStudy(int seconds) {
    final t = todayIso();
    final m = math.max(1, (seconds / 60).ceil());
    data!.minutes[t] = (data!.minutes[t] ?? 0) + m;
  }

  // ---------- timed tests ----------
  /// Up to 25 random questions from a section, or 25 from each section for 'full'.
  List<Question> buildTest(String sec) {
    final rnd = math.Random();
    List<Question> pick(String s) => (questionsIn(s)..shuffle(rnd)).take(questionsPerSection).toList();
    if (sec == 'full') return [for (final s in sectionKeys) ...pick(s)];
    return pick(sec);
  }

  /// Saves a finished test. Wrong answers come back in tomorrow's revision.
  MockResult saveTest({
    required String name,
    required String kind,
    required List<Question> questions,
    required Map<int, int> answers,
    required Map<int, int> sure,
    required int seconds,
  }) {
    final d = data!;
    final t = todayIso();
    final r = scoreTest(
      id: d.newId(),
      name: name,
      date: t,
      kind: kind,
      questions: questions,
      answers: answers,
      sure: sure,
      seconds: seconds,
    );
    d.mocks.add(r);
    for (final q in questions) {
      final a = answers[q.id];
      if (a == null) continue;
      final correct = a == q.a;
      recordAnswer(d.stats.putIfAbsent(topicKey(q.sec, q.topic), () => TopicStat()), correct);
      if (!correct) {
        final c = d.cards.putIfAbsent(q.id, () => CardState(due: t));
        c.due = addDaysIso(t, 1);
        c.ivl = 1;
        c.reps = 0;
        c.lapses++;
        c.confidentMiss = sure[q.id] == 2;
      }
    }
    _logStudy(seconds);
    plan.test = true;
    _changed();
    return r;
  }

  void addManualMock({required String name, required String date, required Map<String, SectionScore> sections, required int confidentWrong}) {
    final d = data!;
    d.mocks.add(MockResult(id: d.newId(), name: name, date: date, kind: 'manual', sections: sections, confidentWrong: confidentWrong));
    _changed();
  }

  void deleteMock(int id) {
    data!.mocks.removeWhere((m) => m.id == id);
    _changed();
  }

  // ---------- week plan ----------
  /// Replaces the week plan with one block a day for [sec], weakest topic first.
  void setWeekPlan(String sec) {
    final d = data!;
    final t = todayIso();
    final topics = weakestTopics(d.stats, sec);
    d.week = [
      for (var i = 0; i < topics.length; i++) PlanBlock(date: addDaysIso(t, i), sec: sec, topic: topics[i].topic),
    ];
    _changed();
  }

  void markLearnDone() {
    plan.learn = true;
    final b = todayBlock;
    if (b != null) b.done = true;
    _changed();
  }

  // ---------- notes ----------
  int addNote(String name, String sec, String topic) {
    final d = data!;
    final id = d.newId();
    d.notes.insert(0, StudyNote(id: id, name: name, sec: sec, topic: topic, at: todayIso()));
    _changed();
    return id;
  }

  void deleteNote(int id) {
    final d = data!;
    final ids = d.custom.where((q) => q.noteId == id).map((q) => q.id).toSet();
    d.custom.removeWhere((q) => ids.contains(q.id));
    d.cards.removeWhere((k, _) => ids.contains(k));
    d.notes.removeWhere((n) => n.id == id);
    _changed();
  }

  /// Adds a question typed in from a note. It first comes up in tomorrow's revision.
  void addNoteQuestion({required int noteId, required String q, required List<String> o, required int a, required String ex, required String src}) {
    final d = data!;
    final n = note(noteId);
    if (n == null) return;
    final id = d.newId();
    d.custom.add(Question(
      id: id,
      sec: n.sec,
      topic: n.topic,
      q: q,
      o: o,
      a: a,
      ex: ex.isEmpty ? 'From your notes.' : ex,
      src: src.isEmpty ? null : src,
      noteId: noteId,
    ));
    d.cards[id] = CardState(due: addDaysIso(todayIso(), 1));
    _changed();
  }

  void deleteNoteQuestion(int id) {
    final d = data!;
    d.custom.removeWhere((q) => q.id == id);
    d.cards.remove(id);
    _changed();
  }
}

/// Sample profile used for "Explore with sample data": Aman, preparing for SSC CGL in Patna.
/// Dates are relative to today.
AppData sampleData() {
  final t = todayIso();
  String ago(int n) => addDaysIso(t, -n);

  // Mastery built up from earlier practice (percent per topic).
  const seedMastery = <String, Map<String, int>>{
    'quant': {'Percentages': 78, 'Profit and loss': 52, 'Time and work': 66, 'Geometry': 41, 'Data interpretation': 58},
    'reason': {'Series': 88, 'Coding-decoding': 86, 'Syllogism': 79, 'Blood relations': 91},
    'eng': {'Synonyms': 74, 'Error spotting': 55, 'Fill in the blanks': 63, 'Idioms': 71},
    'ga': {'Polity': 57, 'History': 46, 'Geography': 52, 'Economy': 44, 'Static GK': 39},
  };
  final stats = <String, TopicStat>{};
  seedMastery.forEach((sec, topics) {
    topics.forEach((topic, p) {
      stats[topicKey(sec, topic)] = TopicStat(ewma: seedEwma(p / 100, 30), n: 30);
    });
  });

  // Questions already in revision, with their next due day (0 = today, negative = overdue).
  const introduced = [1, 2, 3, 4, 5, 6, 7, 8, 11, 12, 16, 21, 26, 27, 28, 33, 34, 39, 45, 51, 52, 58, 64, 70, 76, 77, 78, 79, 82, 87, 92, 97];
  const offsets = [-1, 2, 1, 0, 3, 5, 0, 4, 6, 9, 1, 12, 0, 2, 7, 3, 0, 5, 1, 10, 0, 4, 2, 15, 0, 6, 3, 1, 8, 2, 11, 0];
  final cards = <int, CardState>{};
  for (var i = 0; i < introduced.length; i++) {
    final off = offsets[i];
    cards[introduced[i]] = CardState(due: addDaysIso(t, off), ivl: off < 2 ? 2 : off, reps: 2);
  }
  cards[87] = CardState(due: t, ivl: 1, reps: 0, lapses: 2, ease: 2.1, confidentMiss: true);

  final notes = [
    StudyNote(id: 1, name: 'Fundamental Rights (Part III)', sec: 'ga', topic: 'Polity', at: ago(8)),
    StudyNote(id: 2, name: 'Quant shortcuts: Profit and loss', sec: 'quant', topic: 'Profit and loss', at: ago(4)),
  ];
  const custom = [
    Question(
      id: 1001,
      sec: 'ga',
      topic: 'Polity',
      noteId: 1,
      q: 'Which Article prohibits discrimination on grounds of religion, race, caste, sex or place of birth?',
      o: ['Article 14', 'Article 15', 'Article 16', 'Article 17'],
      a: 1,
      ex: 'Article 15 bars discrimination by the State on these grounds. Article 16 covers equal opportunity in public employment.',
      src: 'p.1: "Art. 15 – no discrimination on religion, race, caste, sex, place of birth"',
    ),
    Question(
      id: 1002,
      sec: 'ga',
      topic: 'Polity',
      noteId: 1,
      q: 'Which writ is issued to release a person who has been unlawfully detained?',
      o: ['Mandamus', 'Certiorari', 'Habeas corpus', 'Quo warranto'],
      a: 2,
      ex: 'Habeas corpus means "to have the body". The court orders the detained person to be produced and freed if the detention is unlawful.',
      src: 'p.3: "Writs under Art. 32 – habeas corpus (produce the body)…"',
    ),
    Question(
      id: 1003,
      sec: 'ga',
      topic: 'Polity',
      noteId: 1,
      q: 'Article 23 prohibits which of the following?',
      o: ['Child labour in factories', 'Traffic in human beings and forced labour', 'Titles', 'Untouchability'],
      a: 1,
      ex: 'Article 23 prohibits traffic in human beings, begar and other forced labour. Child labour in factories is Article 24; titles are abolished by Article 18.',
      src: 'p.4: "Art. 23 – traffic in human beings, begar"',
    ),
    Question(
      id: 1004,
      sec: 'ga',
      topic: 'Polity',
      noteId: 1,
      q: 'How many Fundamental Rights does the Constitution list today?',
      o: ['5', '6', '7', '8'],
      a: 1,
      ex: 'There were originally seven. The Right to Property was removed by the 44th Amendment (1978), leaving six.',
      src: 'p.1: "Originally 7… now 6"',
    ),
    Question(
      id: 1005,
      sec: 'quant',
      topic: 'Profit and loss',
      noteId: 2,
      q: 'Successive discounts of 20% and 10% are equal to a single discount of:',
      o: ['28%', '30%', '25%', '27%'],
      a: 0,
      ex: 'You pay 0.8 × 0.9 = 0.72 of the price, so the single discount is 28%. Shortcut: 20 + 10 − (20 × 10)/100 = 28.',
      src: 'p.1: "Successive discounts: a + b − ab/100"',
    ),
    Question(
      id: 1006,
      sec: 'quant',
      topic: 'Profit and loss',
      noteId: 2,
      q: 'The cost price of 12 articles equals the selling price of 10. What is the profit percentage?',
      o: ['16.67%', '20%', '25%', '10%'],
      a: 1,
      ex: 'Let each article cost ₹1. Ten articles cost ₹10 and sell for ₹12, so profit = 2 ÷ 10 = 20%.',
      src: 'p.1: "CP of x = SP of y → profit % = (x − y)/y × 100"',
    ),
    Question(
      id: 1007,
      sec: 'quant',
      topic: 'Profit and loss',
      noteId: 2,
      q: 'A dealer claims to sell at cost price but uses an 800 g weight for 1 kg. What is his gain percentage?',
      o: ['20%', '25%', '22.5%', '18%'],
      a: 1,
      ex: 'He gives 800 g but charges for 1,000 g. Gain = 200 ÷ 800 × 100 = 25%.',
      src: 'p.1: "False weight: gain % = error/(true value − error) × 100"',
    ),
  ];
  const customDue = {1001: 0, 1002: 1, 1003: 3, 1004: 2, 1005: 0, 1006: 4, 1007: 1};
  customDue.forEach((id, off) => cards[id] = CardState(due: addDaysIso(t, off), ivl: 2, reps: 1));

  // Earlier full mocks entered by hand: [right, wrong] per section, 25 questions each.
  MockResult m(int id, String name, int daysAgo, List<List<int>> rw, int cw) => MockResult(
        id: id,
        name: name,
        date: ago(daysAgo),
        kind: 'manual',
        sections: {
          for (var i = 0; i < 4; i++)
            sectionKeys[i]: SectionScore(right: rw[i][0], wrong: rw[i][1], skipped: questionsPerSection - rw[i][0] - rw[i][1]),
        },
        confidentWrong: cw,
      );
  final mocks = [
    m(201, 'Mock 3', 28, [[15, 6], [20, 4], [15, 4], [14, 6]], 11), // 118
    m(202, 'Mock 4', 21, [[16, 5], [21, 2], [15, 4], [14, 4]], 9), // 124.5
    m(203, 'Mock 5', 14, [[18, 4], [21, 2], [16, 4], [14, 4]], 8), // 131
    m(204, 'Mock 6', 7, [[17, 6], [21, 4], [16, 6], [14, 2]], 10), // 127
    m(205, 'Mock 7', 2, [[20, 4], [22, 0], [18, 7], [15, 4]], 9), // 142.5
  ];

  // Study hours over the last four weeks, oldest first, ending yesterday.
  const heat = [0, 2, 3, 1, 0, 3, 4, 2, 3, 3, 1, 4, 4, 2, 0, 3, 2, 4, 3, 3, 2, 4, 4, 3, 1, 3, 4, 2];
  final minutes = <String, int>{};
  for (var i = 0; i < heat.length; i++) {
    if (heat[i] > 0) minutes[ago(heat.length - i)] = heat[i] * 60 - 10;
  }

  return AppData(
    profile: Profile(name: 'Aman', city: 'Patna', exam: 'SSC CGL Tier 1', examDate: addDaysIso(t, 75), target: 150),
    cards: cards,
    stats: stats,
    custom: List<Question>.of(custom),
    notes: notes,
    mocks: mocks,
    minutes: minutes,
    plan: DayPlan(date: t),
    lastNewDay: t,
    nextId: 1100,
  );
}
