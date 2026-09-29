import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart';

/// Holds the app state, saves it on the phone, and exposes actions.
class LendenStore extends ChangeNotifier {
  static const _key = 'lenden_data_v1';
  AppData? data;
  bool loaded = false;

  // Screen state that is not saved.
  int tab = 0;
  int swapTab = 0; // 0 upcoming, 1 requests, 2 past

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

  void go(int t, {int? swaps}) {
    tab = t;
    if (swaps != null) swapTab = swaps;
    notifyListeners();
  }

  void setSwapTab(int i) {
    swapTab = i;
    notifyListeners();
  }

  // ---------- setup ----------
  void createProfile({required String name, required String area, required Skill teach, required List<String> learns}) {
    final t = todayIso();
    data = AppData(
      me: Me(name: name, area: area, teaches: [teach], learns: learns, publicOnly: true),
      people: samplePeople(),
      circles: sampleCircles(t),
      ledger: [LedgerEntry(date: t, text: 'Welcome credits', hrs: 2)],
    );
    tab = 0;
    swapTab = 0;
    _changed();
  }

  void loadSample() {
    data = sampleData();
    tab = 0;
    swapTab = 0;
    _changed();
  }

  void resetAll() {
    data = null;
    tab = 0;
    swapTab = 0;
    _changed();
  }

  // ---------- derived ----------
  double get balanceHrs => balance(data!.ledger);
  double get freeHrs => freeCredits(data!);
  Set<String> get blockedSet => data!.blocked.toSet();
  int get incomingCount =>
      data!.sessions.where((s) => s.status == 'incoming' && !blockedSet.contains(s.withId)).length;
  int get unreadThreads => data!.threads.entries
      .where((e) => !blockedSet.contains(e.key) && e.value.any((m) => m.unread))
      .length;

  // ---------- requests ----------
  /// Sends a request to learn [learn] from [personId]. For a swap, also books me
  /// to teach [teach] two days later. Returns an error message or null.
  String? sendRequest({
    required String personId,
    required String learn,
    required String pay,
    required String teach,
    required double hrs,
    required String mode,
    required String place,
    required String date,
    required String time,
    required String message,
  }) {
    final d = data!;
    if (pay == 'credits' && freeCredits(d) < hrs) {
      return "You don't have enough free credits. Teach a session first, or offer a swap.";
    }
    final s1 = Session(
      id: d.newId(),
      withId: personId,
      dir: 'learn',
      skill: learn,
      hrs: hrs,
      date: date,
      time: time,
      mode: mode,
      place: place,
      status: 'sent',
      pay: pay,
    );
    d.sessions.add(s1);
    if (pay == 'swap' && teach.isNotEmpty) {
      d.sessions.add(Session(
        id: d.newId(),
        withId: personId,
        dir: 'teach',
        skill: teach,
        hrs: hrs,
        date: addDaysIso(date, 2),
        time: time,
        mode: mode,
        place: place,
        status: 'sent',
        pair: s1.id,
      ));
    }
    _addMessage(personId, message.trim().isEmpty ? 'Sent a swap request.' : message.trim(), me: true);
    swapTab = 1;
    tab = 1;
    _changed();
    return null;
  }

  List<Session> _withPair(Session s) {
    final d = data!;
    return d.sessions.where((x) => x.id == s.id || x.pair == s.id || (s.pair != null && x.id == s.pair)).toList();
  }

  /// They replied yes (outside the app). Confirms the request and its pair.
  void markAccepted(int id) {
    final s = data!.session(id);
    if (s == null) return;
    for (final x in _withPair(s)) {
      if (x.status == 'sent') x.status = 'confirmed';
    }
    _changed();
  }

  void withdraw(int id) {
    final s = data!.session(id);
    if (s == null) return;
    final ids = _withPair(s).map((x) => x.id).toSet();
    data!.sessions.removeWhere((x) => ids.contains(x.id));
    _changed();
  }

  /// Accepts a request someone sent me. If they offered a skill in return,
  /// books my lesson with them the next day.
  Session? acceptIncoming(int id) {
    final d = data!;
    final s = d.session(id);
    if (s == null) return null;
    s.status = 'confirmed';
    Session? back;
    final p = d.person(s.withId);
    if (s.offer.isNotEmpty && p != null) {
      back = Session(
        id: d.newId(),
        withId: s.withId,
        dir: 'learn',
        skill: s.offer,
        hrs: s.hrs,
        date: addDaysIso(s.date, 1),
        time: p.avail.isNotEmpty ? p.avail.first : s.time,
        mode: s.mode,
        place: s.place,
        status: 'confirmed',
        pay: 'swap',
        pair: s.id,
      );
      d.sessions.add(back);
    }
    _changed();
    return back;
  }

  void decline(int id) {
    data!.sessions.removeWhere((x) => x.id == id);
    _changed();
  }

  /// Cancels a confirmed session (and its pair, if not yet done).
  void cancelSession(int id) {
    final s = data!.session(id);
    if (s == null) return;
    final ids = _withPair(s).where((x) => x.status != 'done').map((x) => x.id).toSet();
    data!.sessions.removeWhere((x) => ids.contains(x.id));
    _changed();
  }

  // ---------- sessions ----------
  void completeSession(int id) {
    final d = data!;
    final s = d.session(id);
    if (s == null || s.status == 'done') return;
    s.status = 'done';
    s.rated = false;
    s.date = todayIso().compareTo(s.date) < 0 ? todayIso() : s.date;
    d.ledger.insert(0, LedgerEntry(date: todayIso(), text: ledgerText(s, d.firstName(s.withId)), hrs: s.isLearn ? -s.hrs : s.hrs));
    _changed();
  }

  void rateSession(int id, int stars, String text) {
    final d = data!;
    final s = d.session(id);
    if (s == null) return;
    s.rated = true;
    final p = d.person(s.withId);
    if (p != null) {
      p.rating = newRating(p.rating, p.swaps, stars);
      p.swaps += 1;
      p.reviews.insert(0, Review(by: d.me.name, stars: stars, text: text));
    }
    _changed();
  }

  // ---------- circles ----------
  /// Books or releases a seat. Returns an error message or null.
  String? toggleCircle(int id) {
    final d = data!;
    final c = d.circle(id);
    if (c == null) return null;
    if (!c.joined) {
      if (freeCredits(d) < c.cost) return 'You need ${hrsText(c.cost)} free credit to book a seat.';
      if (c.left <= 0) return 'This circle is full.';
      c.joined = true;
      c.taken += 1;
    } else {
      c.joined = false;
      c.taken = c.taken > 0 ? c.taken - 1 : 0;
    }
    _changed();
    return null;
  }

  void attendCircle(int id) {
    final d = data!;
    final c = d.circle(id);
    if (c == null || !c.joined || c.attended) return;
    c.attended = true;
    d.ledger.insert(0, LedgerEntry(date: todayIso(), text: 'Seat at ${c.title}', hrs: -c.cost));
    _changed();
  }

  // ---------- messages ----------
  void _addMessage(String personId, String text, {required bool me}) {
    final th = data!.threads.putIfAbsent(personId, () => <Message>[]);
    th.add(Message(me: me, text: text, at: DateTime.now().toIso8601String()));
  }

  void sendMessage(String personId, String text) {
    if (text.trim().isEmpty) return;
    _addMessage(personId, text.trim(), me: true);
    _changed();
  }

  void markRead(String personId) {
    final th = data?.threads[personId];
    if (th == null || !th.any((m) => m.unread)) return;
    for (final m in th) {
      m.unread = false;
    }
    _changed();
  }

  // ---------- safety ----------
  void block(String personId) {
    final d = data!;
    if (!d.blocked.contains(personId)) d.blocked.add(personId);
    d.sessions.removeWhere((s) => s.withId == personId && s.status != 'done');
    _changed();
  }

  void unblock(String personId) {
    data!.blocked.remove(personId);
    _changed();
  }

  // ---------- profile ----------
  void updateProfile({required String name, required String area, required String bio, required String contactName, required String contactPhone}) {
    final me = data!.me;
    if (name.trim().isNotEmpty) me.name = name.trim();
    me.area = area.trim();
    me.bio = bio.trim();
    me.contactName = contactName.trim();
    me.contactPhone = contactPhone.trim();
    _changed();
  }

  void setShare(bool v) {
    data!.me.share = v;
    _changed();
  }

  void setVerifiedOnly(bool v) {
    data!.me.verifiedOnly = v;
    _changed();
  }

  void setPublicOnly(bool v) {
    data!.me.publicOnly = v;
    _changed();
  }

  /// Returns an error message or null.
  String? addTeach(String name, String cat, String level) {
    final me = data!.me;
    if (me.teaches.any((t) => t.name.toLowerCase() == name.toLowerCase())) return 'You already teach that.';
    me.teaches.add(Skill(name: name, cat: cat, level: level));
    _changed();
    return null;
  }

  String? addLearn(String name) {
    final me = data!.me;
    if (me.learns.any((l) => l.toLowerCase() == name.toLowerCase())) return "That's already on your list.";
    me.learns.add(name);
    _changed();
    return null;
  }

  void removeTeach(String name) {
    data!.me.teaches.removeWhere((t) => t.name == name);
    _changed();
  }

  void removeLearn(String name) {
    data!.me.learns.remove(name);
    _changed();
  }
}

// ---------------- sample data ----------------

Skill _sk(String name, String cat, String level) => Skill(name: name, cat: cat, level: level);

/// Neighbour profiles used both for a fresh setup and for the sample data.
List<Person> samplePeople() => [
      Person(
        id: 'vikram',
        name: 'Vikram S.',
        color: 0xFFC2532C,
        area: 'HSR Sector 6',
        km: 1.2,
        online: true,
        verified: true,
        rating: 4.9,
        swaps: 23,
        bio: 'Played in college bands for 8 years. Patient with total beginners.',
        teaches: [_sk('Acoustic guitar', 'music', 'Expert'), _sk('Music theory', 'music', 'Good')],
        wants: ['Excel & Google Sheets', 'Public speaking'],
        avail: ['07:00', '18:30'],
        reviews: [
          Review(by: 'Arun M.', stars: 5, text: 'Got me playing four chords in two sessions.'),
          Review(by: 'Meera J.', stars: 5, text: 'Always on time. Brings a spare guitar.'),
        ],
      ),
      Person(
        id: 'lakshmi',
        name: 'Lakshmi R.',
        color: 0xFF2B7A5B,
        area: 'HSR Sector 2',
        km: 0.8,
        online: true,
        verified: true,
        rating: 5.0,
        swaps: 11,
        bio: 'I run a small tiffin service from home. Happy to teach Kannada over coffee.',
        teaches: [_sk('Spoken Kannada', 'lang', 'Native'), _sk('South Indian cooking', 'food', 'Expert')],
        wants: ['Canva design', 'Instagram for small business'],
        avail: ['11:00', '16:00'],
        reviews: [Review(by: 'Neha', stars: 5, text: 'Learnt enough Kannada to chat with my auto driver.')],
      ),
      Person(
        id: 'deepa',
        name: 'Deepa K.',
        color: 0xFF6B4FB8,
        area: 'Agara',
        km: 1.6,
        online: false,
        verified: true,
        rating: 4.8,
        swaps: 17,
        bio: 'Certified hatha yoga teacher. Morning sessions in the park.',
        teaches: [_sk('Yoga', 'fit', 'Certified'), _sk('Pranayama', 'fit', 'Certified')],
        wants: ['Excel & Google Sheets'],
        avail: ['06:30', '07:30'],
        reviews: [Review(by: 'Farhan A.', stars: 5, text: 'Fixed my posture in a week.')],
      ),
      Person(
        id: 'ramesh',
        name: 'Ramesh G.',
        color: 0xFF8C6A12,
        area: 'HSR Sector 1',
        km: 0.5,
        online: false,
        verified: true,
        rating: 4.8,
        swaps: 6,
        bio: 'Retired bank manager. Chess on Sunday mornings, gardening the rest of the week.',
        teaches: [_sk('Chess', 'home', 'Expert'), _sk('Terrace gardening', 'home', 'Expert')],
        wants: ['Smartphone basics', 'WhatsApp video calls'],
        avail: ['07:00', '17:00'],
        reviews: [Review(by: 'Vikram S.', stars: 5, text: 'Knows every opening. Very kind teacher.')],
      ),
      Person(
        id: 'arun',
        name: 'Arun M.',
        color: 0xFF1F6FA8,
        area: 'Koramangala 5th Block',
        km: 2.9,
        online: true,
        verified: false,
        rating: 4.7,
        swaps: 9,
        bio: 'Backend developer. I teach Python from zero.',
        teaches: [_sk('Python basics', 'tech', 'Expert'), _sk('Git & GitHub', 'tech', 'Good')],
        wants: ['Data analysis (SQL)', 'Acoustic guitar'],
        avail: ['20:00', '21:00'],
        reviews: [Review(by: 'Neha', stars: 5, text: 'Clear explanations, lots of practice problems.')],
      ),
      Person(
        id: 'farhan',
        name: 'Farhan A.',
        color: 0xFFA33B6B,
        area: 'BTM Layout',
        km: 3.4,
        online: false,
        verified: true,
        rating: 4.6,
        swaps: 14,
        bio: 'Street photographer. Lightroom nerd.',
        teaches: [_sk('Photography', 'create', 'Expert'), _sk('Lightroom editing', 'create', 'Expert')],
        wants: ['Public speaking', 'Driving practice'],
        avail: ['08:00', '17:30'],
        reviews: [Review(by: 'Deepa K.', stars: 4, text: 'Great eye. Sessions ran a bit long, in a good way.')],
      ),
      Person(
        id: 'sneha',
        name: 'Sneha P.',
        color: 0xFF1E7F86,
        area: 'Online only',
        km: null,
        online: true,
        verified: true,
        rating: 4.9,
        swaps: 30,
        bio: 'Lived in Lyon for three years. Conversation-first French.',
        teaches: [_sk('Spoken French', 'lang', 'Fluent (B2)')],
        wants: ['Data analysis (SQL)'],
        avail: ['19:00', '20:30'],
        reviews: [Review(by: 'Neha', stars: 5, text: 'Fun and structured. Sends notes after each class.')],
      ),
    ];

List<Circle> sampleCircles(String today) => [
      Circle(
        id: 501,
        title: 'Sunday chess circle',
        host: 'ramesh',
        date: nextWeekday(today, DateTime.sunday),
        time: '07:00',
        place: 'Park, HSR Sector 1',
        seats: 8,
        taken: 5,
        cost: 1,
      ),
      Circle(
        id: 502,
        title: 'Kannada over chai',
        host: 'lakshmi',
        date: nextWeekday(today, DateTime.saturday),
        time: '16:00',
        place: 'Library reading room, HSR Sector 2',
        seats: 6,
        taken: 4,
        cost: 1,
      ),
    ];

/// Full sample account ("Neha") used for "Explore with sample data". Dates are relative to today.
AppData sampleData() {
  final t = todayIso();
  String day(int n) => addDaysIso(t, n);
  final now = DateTime.now();
  String at(int daysAgo, int h, int m) => DateTime(now.year, now.month, now.day - daysAgo, h, m).toIso8601String();
  const online = 'Video call';
  return AppData(
    me: Me(
      name: 'Neha',
      area: 'HSR Sector 3',
      bio: 'Analyst at a fintech. I explain spreadsheets without the jargon.',
      teaches: [
        _sk('Excel & Google Sheets', 'tech', 'Expert'),
        _sk('Data analysis (SQL)', 'tech', 'Good'),
        _sk('Canva design', 'create', 'Good'),
      ],
      learns: ['Acoustic guitar', 'Spoken Kannada', 'South Indian cooking', 'Yoga'],
      share: true,
      verifiedOnly: false,
      publicOnly: true,
      contactName: 'Mom',
      contactPhone: '',
    ),
    people: samplePeople(),
    sessions: [
      Session(id: 1, withId: 'vikram', dir: 'learn', skill: 'Acoustic guitar', hrs: 1, date: day(5), time: '17:00', mode: 'In person', place: 'Public park, HSR Sector 6 (east gate)', status: 'confirmed', pay: 'swap', pair: 2),
      Session(id: 2, withId: 'vikram', dir: 'teach', skill: 'Excel & Google Sheets', hrs: 1, date: day(7), time: '19:00', mode: 'Online', place: online, status: 'confirmed', pair: 1),
      Session(
        id: 3,
        withId: 'deepa',
        dir: 'teach',
        skill: 'Excel & Google Sheets',
        hrs: 1.5,
        date: day(3),
        time: '19:00',
        mode: 'In person',
        place: 'Agara Lake walking-track entrance',
        status: 'incoming',
        note: 'I track my yoga batches in a notebook. Want to move to Sheets! Happy to teach you yoga in return.',
        offer: 'Yoga',
      ),
      Session(id: 4, withId: 'arun', dir: 'teach', skill: 'Data analysis (SQL)', hrs: 1, date: day(-2), time: '20:00', mode: 'Online', place: online, status: 'done'),
      Session(id: 5, withId: 'lakshmi', dir: 'learn', skill: 'Spoken Kannada', hrs: 1, date: day(-7), time: '11:00', mode: 'In person', place: 'Library reading room, HSR Sector 2', status: 'done', rated: true, pay: 'credits'),
      Session(id: 6, withId: 'lakshmi', dir: 'teach', skill: 'Canva design', hrs: 1, date: day(-8), time: '16:00', mode: 'In person', place: 'Library reading room, HSR Sector 2', status: 'done', rated: true),
      Session(id: 7, withId: 'sneha', dir: 'teach', skill: 'Data analysis (SQL)', hrs: 1.5, date: day(-14), time: '19:00', mode: 'Online', place: online, status: 'done', rated: true),
    ],
    ledger: [
      LedgerEntry(date: day(-2), text: 'Taught SQL to Arun', hrs: 1),
      LedgerEntry(date: day(-7), text: 'Learnt Kannada from Lakshmi', hrs: -1),
      LedgerEntry(date: day(-8), text: 'Taught Canva to Lakshmi', hrs: 1),
      LedgerEntry(date: day(-14), text: 'Taught SQL to Sneha', hrs: 1.5),
      LedgerEntry(date: day(-27), text: 'Welcome credits', hrs: 2),
    ],
    circles: sampleCircles(t),
    threads: {
      'vikram': [
        Message(me: false, text: 'Hi Neha! Saturday 5 PM works. Do you have a guitar, or should I bring my spare?', at: at(1, 20, 12)),
        Message(me: true, text: "I don't have one yet. Could you bring the spare?", at: at(1, 20, 20)),
        Message(me: false, text: 'Sure. See you at the east gate.', at: at(1, 20, 21), unread: true),
      ],
      'deepa': [
        Message(me: false, text: 'Hi! I sent you a swap request for Excel. Mornings are best for yoga, evenings for Excel.', at: at(0, 9, 5), unread: true),
      ],
      'lakshmi': [
        Message(me: false, text: 'Namaskara! Same time next week?', at: at(7, 12, 10)),
        Message(me: true, text: 'Houdu! See you then.', at: at(7, 12, 14)),
      ],
    },
    nextId: 100,
  );
}
