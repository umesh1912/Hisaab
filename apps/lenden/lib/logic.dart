// Core data model and pure logic for Lenden.
// Time credits are counted in hours (1 hour of teaching = 1 credit).
// Session lengths are whole or half hours, so doubles stay exact.

const categories = <String, String>{
  'music': 'Music',
  'lang': 'Languages',
  'food': 'Cooking',
  'fit': 'Fitness',
  'tech': 'Tech',
  'create': 'Creative',
  'home': 'Home & hobbies',
};

const skillLevels = ['Good', 'Expert', 'Certified', 'Native'];

double _d(Object? v) => v is num ? v.toDouble() : 0.0;
List<String> _strs(Object? v) => ((v ?? []) as List).map((e) => e as String).toList();
List<T> _objs<T>(Object? v, T Function(Map<String, dynamic>) f) =>
    ((v ?? []) as List).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();

class Skill {
  Skill({required this.name, required this.cat, required this.level});
  String name;
  String cat;
  String level;

  Map<String, dynamic> toJson() => {'name': name, 'cat': cat, 'level': level};
  factory Skill.fromJson(Map<String, dynamic> j) => Skill(
        name: j['name'] as String,
        cat: (j['cat'] ?? 'home') as String,
        level: (j['level'] ?? 'Good') as String,
      );
}

class Review {
  Review({required this.by, required this.stars, required this.text});
  final String by;
  final int stars;
  final String text;

  Map<String, dynamic> toJson() => {'by': by, 'stars': stars, 'text': text};
  factory Review.fromJson(Map<String, dynamic> j) =>
      Review(by: j['by'] as String, stars: j['stars'] as int, text: (j['text'] ?? '') as String);
}

/// A neighbour. In this single-phone version every neighbour is a sample profile.
class Person {
  Person({
    required this.id,
    required this.name,
    required this.color,
    required this.area,
    this.km,
    this.online = false,
    this.verified = false,
    this.rating = 5,
    this.swaps = 0,
    this.bio = '',
    List<Skill>? teaches,
    List<String>? wants,
    List<String>? avail,
    List<Review>? reviews,
  })  : teaches = teaches ?? [],
        wants = wants ?? [],
        avail = avail ?? [],
        reviews = reviews ?? [];

  final String id;
  String name;
  int color;
  String area;
  double? km; // null = online only
  bool online;
  bool verified;
  double rating;
  int swaps;
  String bio;
  List<Skill> teaches;
  List<String> wants;
  List<String> avail; // "HH:mm" times they are usually free
  List<Review> reviews;

  String get first => name.split(' ').first;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'area': area,
        'km': km,
        'online': online,
        'verified': verified,
        'rating': rating,
        'swaps': swaps,
        'bio': bio,
        'teaches': teaches.map((e) => e.toJson()).toList(),
        'wants': wants,
        'avail': avail,
        'reviews': reviews.map((e) => e.toJson()).toList(),
      };

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: j['id'] as String,
        name: j['name'] as String,
        color: (j['color'] ?? 0xFF1F6FA8) as int,
        area: (j['area'] ?? '') as String,
        km: j['km'] == null ? null : _d(j['km']),
        online: (j['online'] ?? false) as bool,
        verified: (j['verified'] ?? false) as bool,
        rating: _d(j['rating'] ?? 5),
        swaps: (j['swaps'] ?? 0) as int,
        bio: (j['bio'] ?? '') as String,
        teaches: _objs(j['teaches'], Skill.fromJson),
        wants: _strs(j['wants']),
        avail: _strs(j['avail']),
        reviews: _objs(j['reviews'], Review.fromJson),
      );
}

/// The person using the app.
class Me {
  Me({
    required this.name,
    required this.area,
    this.bio = '',
    List<Skill>? teaches,
    List<String>? learns,
    this.share = false,
    this.verifiedOnly = false,
    this.publicOnly = true,
    this.contactName = '',
    this.contactPhone = '',
  })  : teaches = teaches ?? [],
        learns = learns ?? [];

  String name;
  String area;
  String bio;
  List<Skill> teaches;
  List<String> learns;
  bool share; // share in-person sessions with a trusted contact
  bool verifiedOnly;
  bool publicOnly;
  String contactName;
  String contactPhone;

  List<String> get teachNames => teaches.map((t) => t.name).toList();

  Map<String, dynamic> toJson() => {
        'name': name,
        'area': area,
        'bio': bio,
        'teaches': teaches.map((e) => e.toJson()).toList(),
        'learns': learns,
        'share': share,
        'verifiedOnly': verifiedOnly,
        'publicOnly': publicOnly,
        'contactName': contactName,
        'contactPhone': contactPhone,
      };

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        name: j['name'] as String,
        area: (j['area'] ?? '') as String,
        bio: (j['bio'] ?? '') as String,
        teaches: _objs(j['teaches'], Skill.fromJson),
        learns: _strs(j['learns']),
        share: (j['share'] ?? false) as bool,
        verifiedOnly: (j['verifiedOnly'] ?? false) as bool,
        publicOnly: (j['publicOnly'] ?? true) as bool,
        contactName: (j['contactName'] ?? '') as String,
        contactPhone: (j['contactPhone'] ?? '') as String,
      );
}

/// One lesson between me and a neighbour.
/// dir: 'learn' (they teach me) or 'teach' (I teach them).
/// status: 'incoming' (they asked me), 'sent' (I asked), 'confirmed', 'done'.
/// pay: 'swap' or 'credits' for lessons I learn.
class Session {
  Session({
    required this.id,
    required this.withId,
    required this.dir,
    required this.skill,
    required this.hrs,
    required this.date,
    required this.time,
    required this.mode,
    required this.place,
    required this.status,
    this.pay = '',
    this.note = '',
    this.offer = '',
    this.rated = false,
    this.pair,
  });

  final int id;
  final String withId;
  final String dir;
  String skill;
  double hrs;
  String date; // yyyy-MM-dd
  String time; // HH:mm
  String mode; // In person | Online
  String place;
  String status;
  String pay;
  String note;
  String offer;
  bool rated;
  int? pair; // the other half of a two-way swap

  bool get isLearn => dir == 'learn';

  Map<String, dynamic> toJson() => {
        'id': id,
        'withId': withId,
        'dir': dir,
        'skill': skill,
        'hrs': hrs,
        'date': date,
        'time': time,
        'mode': mode,
        'place': place,
        'status': status,
        'pay': pay,
        'note': note,
        'offer': offer,
        'rated': rated,
        'pair': pair,
      };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        id: j['id'] as int,
        withId: j['withId'] as String,
        dir: j['dir'] as String,
        skill: j['skill'] as String,
        hrs: _d(j['hrs']),
        date: j['date'] as String,
        time: (j['time'] ?? '10:00') as String,
        mode: (j['mode'] ?? 'In person') as String,
        place: (j['place'] ?? '') as String,
        status: j['status'] as String,
        pay: (j['pay'] ?? '') as String,
        note: (j['note'] ?? '') as String,
        offer: (j['offer'] ?? '') as String,
        rated: (j['rated'] ?? false) as bool,
        pair: j['pair'] as int?,
      );
}

class LedgerEntry {
  LedgerEntry({required this.date, required this.text, required this.hrs});
  final String date;
  final String text;
  final double hrs; // + earned, - spent

  Map<String, dynamic> toJson() => {'date': date, 'text': text, 'hrs': hrs};
  factory LedgerEntry.fromJson(Map<String, dynamic> j) =>
      LedgerEntry(date: j['date'] as String, text: j['text'] as String, hrs: _d(j['hrs']));
}

/// A small group lesson hosted by a neighbour. A seat costs credits.
class Circle {
  Circle({
    required this.id,
    required this.title,
    required this.host,
    required this.date,
    required this.time,
    required this.place,
    required this.seats,
    required this.taken,
    this.cost = 1,
    this.joined = false,
    this.attended = false,
  });

  final int id;
  String title;
  String host;
  String date;
  String time;
  String place;
  int seats;
  int taken;
  double cost;
  bool joined;
  bool attended;

  int get left => seats - taken;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'host': host,
        'date': date,
        'time': time,
        'place': place,
        'seats': seats,
        'taken': taken,
        'cost': cost,
        'joined': joined,
        'attended': attended,
      };

  factory Circle.fromJson(Map<String, dynamic> j) => Circle(
        id: j['id'] as int,
        title: j['title'] as String,
        host: j['host'] as String,
        date: j['date'] as String,
        time: (j['time'] ?? '07:00') as String,
        place: (j['place'] ?? '') as String,
        seats: (j['seats'] ?? 8) as int,
        taken: (j['taken'] ?? 0) as int,
        cost: _d(j['cost'] ?? 1),
        joined: (j['joined'] ?? false) as bool,
        attended: (j['attended'] ?? false) as bool,
      );
}

class Message {
  Message({required this.me, required this.text, required this.at, this.unread = false});
  final bool me;
  final String text;
  final String at; // ISO date-time
  bool unread;

  Map<String, dynamic> toJson() => {'me': me, 'text': text, 'at': at, 'unread': unread};
  factory Message.fromJson(Map<String, dynamic> j) => Message(
        me: (j['me'] ?? false) as bool,
        text: j['text'] as String,
        at: j['at'] as String,
        unread: (j['unread'] ?? false) as bool,
      );
}

class AppData {
  AppData({
    required this.me,
    List<Person>? people,
    List<Session>? sessions,
    List<LedgerEntry>? ledger,
    List<Circle>? circles,
    Map<String, List<Message>>? threads,
    List<String>? blocked,
    this.nextId = 1000,
  })  : people = people ?? [],
        sessions = sessions ?? [],
        ledger = ledger ?? [],
        circles = circles ?? [],
        threads = threads ?? {},
        blocked = blocked ?? [];

  Me me;
  List<Person> people;
  List<Session> sessions;
  List<LedgerEntry> ledger; // newest first
  List<Circle> circles;
  Map<String, List<Message>> threads;
  List<String> blocked;
  int nextId;

  int newId() => nextId++;

  Person? person(String id) {
    for (final p in people) {
      if (p.id == id) return p;
    }
    return null;
  }

  Session? session(int id) {
    for (final s in sessions) {
      if (s.id == id) return s;
    }
    return null;
  }

  Circle? circle(int id) {
    for (final c in circles) {
      if (c.id == id) return c;
    }
    return null;
  }

  String firstName(String id) => person(id)?.first ?? 'Someone';

  Map<String, dynamic> toJson() => {
        'me': me.toJson(),
        'people': people.map((e) => e.toJson()).toList(),
        'sessions': sessions.map((e) => e.toJson()).toList(),
        'ledger': ledger.map((e) => e.toJson()).toList(),
        'circles': circles.map((e) => e.toJson()).toList(),
        'threads': threads.map((k, v) => MapEntry(k, v.map((m) => m.toJson()).toList())),
        'blocked': blocked,
        'nextId': nextId,
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    final th = <String, List<Message>>{};
    ((j['threads'] ?? {}) as Map).forEach((k, v) => th[k as String] = _objs(v, Message.fromJson));
    return AppData(
      me: Me.fromJson(Map<String, dynamic>.from(j['me'] as Map)),
      people: _objs(j['people'], Person.fromJson),
      sessions: _objs(j['sessions'], Session.fromJson),
      ledger: _objs(j['ledger'], LedgerEntry.fromJson),
      circles: _objs(j['circles'], Circle.fromJson),
      threads: th,
      blocked: _strs(j['blocked']),
      nextId: (j['nextId'] ?? 1000) as int,
    );
  }
}

// ---------------- credits ----------------

double balance(List<LedgerEntry> ledger) => ledger.fold<double>(0, (a, l) => a + l.hrs);

/// Credits already promised: lessons I pay for with credits that are not done yet,
/// plus circle seats I booked but have not attended.
double reserved(List<Session> sessions, List<Circle> circles) {
  var r = 0.0;
  for (final s in sessions) {
    if (s.isLearn && s.pay == 'credits' && (s.status == 'sent' || s.status == 'confirmed')) r += s.hrs;
  }
  for (final c in circles) {
    if (c.joined && !c.attended) r += c.cost;
  }
  return r;
}

double freeCredits(AppData d) => balance(d.ledger) - reserved(d.sessions, d.circles);

/// Hours taught (earned from lessons, not welcome credits) and hours learnt.
double taughtHours(List<LedgerEntry> ledger) =>
    ledger.where((l) => l.hrs > 0 && !l.text.startsWith('Welcome')).fold<double>(0, (a, l) => a + l.hrs);
double learntHours(List<LedgerEntry> ledger) => -ledger.where((l) => l.hrs < 0).fold<double>(0, (a, l) => a + l.hrs);

/// "1", "1.5", "12".
String hrsText(double h) {
  final a = h.abs();
  return a == a.roundToDouble() ? a.round().toString() : a.toStringAsFixed(1);
}

/// "+1.5" or "−1".
String signedHrs(double h) => '${h >= 0 ? '+' : '−'}${hrsText(h)}';

// ---------------- matching ----------------

List<String> theyWantMine(Person p, Me me) {
  final mine = me.teachNames.map((s) => s.toLowerCase()).toSet();
  return p.wants.where((w) => mine.contains(w.toLowerCase())).toList();
}

List<String> iWantTheirs(Person p, Me me) {
  final wants = me.learns.map((s) => s.toLowerCase()).toSet();
  return p.teaches.where((t) => wants.contains(t.name.toLowerCase())).map((t) => t.name).toList();
}

bool isTwoWay(Person p, Me me) => theyWantMine(p, me).isNotEmpty && iWantTheirs(p, me).isNotEmpty;

/// Higher is better: people who want my skills, then people who teach what I want,
/// then closeness and rating.
double matchScore(Person p, Me me) {
  var s = 0.0;
  if (theyWantMine(p, me).isNotEmpty) s += 50;
  if (iWantTheirs(p, me).isNotEmpty) s += 30;
  final km = p.km;
  if (km != null) {
    final near = 20 * (1 - km / 5);
    s += near > 0 ? near : 0;
  } else {
    s += 6;
  }
  s += (p.rating - 4) * 10;
  return s;
}

class PeopleFilter {
  PeopleFilter({this.query = '', this.cat = 'all', this.mutual = false, this.near = false, this.online = false, this.verified = false});
  String query;
  String cat;
  bool mutual; // wants my skills
  bool near; // within 2 km
  bool online;
  bool verified;
}

/// People shown on Discover, best match first.
List<Person> discoverPeople(AppData d, PeopleFilter f) {
  final q = f.query.trim().toLowerCase();
  final blocked = d.blocked.toSet();
  final list = d.people.where((p) {
    if (blocked.contains(p.id)) return false;
    if (f.cat != 'all' && !p.teaches.any((t) => t.cat == f.cat)) return false;
    if (f.mutual && theyWantMine(p, d.me).isEmpty) return false;
    final km = p.km;
    if (f.near && (km == null || km > 2)) return false;
    if (f.online && !p.online) return false;
    if ((f.verified || d.me.verifiedOnly) && !p.verified) return false;
    if (q.isNotEmpty &&
        !p.name.toLowerCase().contains(q) &&
        !p.teaches.any((t) => t.name.toLowerCase().contains(q))) {
      return false;
    }
    return true;
  }).toList();
  list.sort((a, b) => matchScore(b, d.me).compareTo(matchScore(a, d.me)));
  return list;
}

/// New average after adding one rating, weighted by the swaps already done.
double newRating(double rating, int swaps, int stars) {
  final n = swaps < 1 ? 1 : swaps;
  final v = (rating * n + stars) / (n + 1);
  return (v * 100).round() / 100;
}

/// The 4-digit code shown at check-in.
String checkInCode(int sessionId) => (1000 + (sessionId * 7919) % 9000).toString();

/// Short verb line for the credit history, e.g. "Taught SQL to Arun".
String ledgerText(Session s, String firstName) {
  final skill = s.skill.split(' (').first;
  return s.isLearn ? 'Learnt $skill from $firstName' : 'Taught $skill to $firstName';
}

// ---------------- swap lists ----------------

List<Session> upcomingSessions(List<Session> all, Set<String> blocked) =>
    all.where((s) => s.status == 'confirmed' && !blocked.contains(s.withId)).toList()..sort(_byWhen);

List<Session> requestSessions(List<Session> all, Set<String> blocked) =>
    all.where((s) => (s.status == 'incoming' || s.status == 'sent') && !blocked.contains(s.withId)).toList()..sort(_byWhen);

List<Session> pastSessions(List<Session> all) =>
    all.where((s) => s.status == 'done').toList()..sort((a, b) => _byWhen(b, a));

int _byWhen(Session a, Session b) {
  final c = a.date.compareTo(b.date);
  return c != 0 ? c : a.time.compareTo(b.time);
}

// ---------------- dates and times ----------------

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

int daysBetween(String a, String b) {
  final x = parseIso(a), y = parseIso(b);
  return DateTime.utc(y.year, y.month, y.day).difference(DateTime.utc(x.year, x.month, x.day)).inDays;
}

/// The next date that falls on [weekday] (1 = Monday … 7 = Sunday), at least one day after [from].
String nextWeekday(String from, int weekday) {
  var d = addDaysIso(from, 1);
  while (parseIso(d).weekday != weekday) {
    d = addDaysIso(d, 1);
  }
  return d;
}

const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String shortDate(String s) {
  final d = parseIso(s);
  return '${d.day} ${_mon[d.month - 1]}';
}

String monthShort(String s) => _mon[parseIso(s).month - 1];
String dayName(String s) => _dow[parseIso(s).weekday - 1];

/// "17:00" -> "5 PM", "18:30" -> "6:30 PM".
String t12(String hhmm) {
  final p = hhmm.split(':');
  final h = int.tryParse(p[0]) ?? 0;
  final m = p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0;
  final ap = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return m == 0 ? '$h12 $ap' : '$h12:${m.toString().padLeft(2, '0')} $ap';
}

/// Chat time: "9:05 AM" today, "Yesterday", or "21 Sep".
String msgTime(String at, DateTime now) {
  final t = DateTime.tryParse(at);
  if (t == null) return '';
  final days = daysBetween(isoDate(t), isoDate(now));
  if (days <= 0) return t12('${t.hour}:${t.minute}');
  if (days == 1) return 'Yesterday';
  return shortDate(isoDate(t));
}

String greeting(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// Splits "Guitar, yoga ,  Kannada" into a clean list without duplicates.
List<String> splitSkills(String text) {
  final out = <String>[];
  for (final part in text.split(',')) {
    final s = part.trim();
    if (s.isNotEmpty && !out.any((o) => o.toLowerCase() == s.toLowerCase())) out.add(s);
  }
  return out;
}

/// Phone number in the form wa.me expects: digits only, with India's 91 added to
/// 10-digit numbers. Returns '' when there is no usable number.
String waNumber(String phone) {
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('0')) digits = digits.substring(1);
  if (digits.length == 10) return '91$digits';
  if (digits.length == 12 && digits.startsWith('91')) return digits;
  return '';
}
