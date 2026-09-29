// Core data model and pure logic for Galli.
// Times are stored as milliseconds since epoch. Distances are in km from the
// user's home locality. Map positions are in a 340 x 260 schematic grid.

import 'dart:math' as math;

const postTypes = ['alert', 'lost', 'found', 'help', 'notice'];

const typeLabels = <String, String>{
  'alert': 'Alert',
  'lost': 'Lost',
  'found': 'Found',
  'help': 'Help needed',
  'notice': 'Notice',
};

const typeHints = <String, String>{
  'alert': 'Power, water, roads, safety',
  'lost': 'Pet, keys, phone, ID',
  'found': 'Something you picked up',
  'help': 'Ask neighbours',
  'notice': 'Events, meetings',
};

const categoriesByType = <String, List<String>>{
  'alert': ['Power', 'Water', 'Road', 'Safety', 'Other'],
  'lost': ['Pet', 'Item', 'Phone', 'Document'],
  'found': ['Pet', 'Item', 'Phone', 'Document'],
  'help': ['Ask', 'Lift', 'Recommendation'],
  'notice': ['Event', 'Meeting', 'Notice'],
};

const radiusOptions = [0.5, 1.0, 2.0];
const distanceOptions = [0.2, 0.5, 1.0, 2.0];
const expiryOptions = [2, 6, 24];

const minuteMs = 60000;
const hourMs = 3600000;
const dayMs = 86400000;

// ---------------- models ----------------

double _d(Object? v, [double fallback = 0]) => v is num ? v.toDouble() : fallback;

class Sighting {
  Sighting({required this.text, required this.at, required this.x, required this.y});
  final String text;
  final int at;
  final double x;
  final double y;

  Map<String, dynamic> toJson() => {'text': text, 'at': at, 'x': x, 'y': y};
  factory Sighting.fromJson(Map<String, dynamic> j) => Sighting(
        text: j['text'] as String,
        at: j['at'] as int,
        x: _d(j['x']),
        y: _d(j['y']),
      );
}

class Post {
  Post({
    required this.id,
    required this.type,
    required this.cat,
    required this.title,
    required this.body,
    required this.by,
    required this.km,
    required this.x,
    required this.y,
    required this.at,
    this.mine = false,
    this.yes = 0,
    this.no = 0,
    this.myVote = '',
    this.expiresAt,
    this.official = false,
    this.safety = false,
    this.reward = '',
    this.place = '',
    List<Sighting>? sightings,
    this.resolved = false,
    this.hidden = false,
  }) : sightings = sightings ?? [];

  final int id;
  String type; // alert | lost | found | help | notice
  String cat;
  String title;
  String body;
  String by;
  double km;
  double x;
  double y;
  int at;
  bool mine;
  int yes;
  int no;
  String myVote; // '' | yes | no
  int? expiresAt;
  bool official;
  bool safety;
  String reward;
  String place;
  List<Sighting> sightings;
  bool resolved;
  bool hidden;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'cat': cat,
        'title': title,
        'body': body,
        'by': by,
        'km': km,
        'x': x,
        'y': y,
        'at': at,
        'mine': mine,
        'yes': yes,
        'no': no,
        'myVote': myVote,
        'expiresAt': expiresAt,
        'official': official,
        'safety': safety,
        'reward': reward,
        'place': place,
        'sightings': sightings.map((s) => s.toJson()).toList(),
        'resolved': resolved,
        'hidden': hidden,
      };

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as int,
        type: j['type'] as String,
        cat: (j['cat'] ?? '') as String,
        title: j['title'] as String,
        body: (j['body'] ?? '') as String,
        by: (j['by'] ?? 'Neighbour') as String,
        km: _d(j['km'], 0.5),
        x: _d(j['x'], youX),
        y: _d(j['y'], youY),
        at: j['at'] as int,
        mine: (j['mine'] ?? false) as bool,
        yes: (j['yes'] ?? 0) as int,
        no: (j['no'] ?? 0) as int,
        myVote: (j['myVote'] ?? '') as String,
        expiresAt: j['expiresAt'] as int?,
        official: (j['official'] ?? false) as bool,
        safety: (j['safety'] ?? false) as bool,
        reward: (j['reward'] ?? '') as String,
        place: (j['place'] ?? '') as String,
        sightings: ((j['sightings'] ?? []) as List)
            .map((e) => Sighting.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        resolved: (j['resolved'] ?? false) as bool,
        hidden: (j['hidden'] ?? false) as bool,
      );
}

class Message {
  Message({required this.me, required this.text, required this.at});
  final bool me;
  final String text;
  final int at;

  Map<String, dynamic> toJson() => {'me': me, 'text': text, 'at': at};
  factory Message.fromJson(Map<String, dynamic> j) =>
      Message(me: j['me'] as bool, text: j['text'] as String, at: j['at'] as int);
}

class Thread {
  Thread({required this.id, required this.withName, required this.postId, List<Message>? msgs, this.unread = false})
      : msgs = msgs ?? [];
  final int id;
  String withName;
  int postId;
  List<Message> msgs;
  bool unread;

  Map<String, dynamic> toJson() => {
        'id': id,
        'withName': withName,
        'postId': postId,
        'msgs': msgs.map((m) => m.toJson()).toList(),
        'unread': unread,
      };
  factory Thread.fromJson(Map<String, dynamic> j) => Thread(
        id: j['id'] as int,
        withName: j['withName'] as String,
        postId: j['postId'] as int,
        msgs: ((j['msgs'] ?? []) as List).map((e) => Message.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        unread: (j['unread'] ?? false) as bool,
      );
}

class Notif {
  Notif({required this.text, required this.at, required this.type, this.read = false, this.postId});
  final String text;
  final int at;
  final String type; // a key of notifyPrefs
  bool read;
  final int? postId;

  Map<String, dynamic> toJson() => {'text': text, 'at': at, 'type': type, 'read': read, 'postId': postId};
  factory Notif.fromJson(Map<String, dynamic> j) => Notif(
        text: j['text'] as String,
        at: j['at'] as int,
        type: (j['type'] ?? 'alert') as String,
        read: (j['read'] ?? false) as bool,
        postId: j['postId'] as int?,
      );
}

class Area {
  Area({required this.name, required this.radiusKm, this.on = true});
  String name;
  double radiusKm;
  bool on;

  Map<String, dynamic> toJson() => {'name': name, 'radiusKm': radiusKm, 'on': on};
  factory Area.fromJson(Map<String, dynamic> j) =>
      Area(name: j['name'] as String, radiusKm: _d(j['radiusKm'], 1), on: (j['on'] ?? true) as bool);
}

/// Keys, titles and subtitles for the "Notify me about" switches.
const notifyPrefs = <List<String>>[
  ['alert', 'Alerts', 'Power, water, roads'],
  ['safety', 'Safety reports', 'Only once 3 neighbours confirm'],
  ['lost', 'Lost pets and items', 'Within 2 km'],
  ['found', 'Found items', ''],
  ['notice', 'Notices', 'From RWAs and verified groups'],
  ['help', 'Help requests', 'Tutors, lifts, recommendations'],
];

Map<String, bool> defaultPrefs() =>
    {'alert': true, 'safety': true, 'lost': true, 'found': true, 'notice': true, 'help': false};

class AppData {
  AppData({
    required this.name,
    required this.locality,
    this.radius = 1.0,
    this.points = 0,
    this.typeFilter = 'all',
    List<Post>? posts,
    List<Thread>? threads,
    List<Notif>? notifs,
    List<Area>? areas,
    Map<String, bool>? prefs,
    List<String>? told,
    this.nextId = 1000,
  })  : posts = posts ?? [],
        threads = threads ?? [],
        notifs = notifs ?? [],
        areas = areas ?? [],
        prefs = prefs ?? defaultPrefs(),
        told = told ?? [];

  String name;
  String locality;
  double radius;
  int points;
  String typeFilter;
  List<Post> posts;
  List<Thread> threads;
  List<Notif> notifs;
  List<Area> areas;
  Map<String, bool> prefs;
  List<String> told; // "lostId-foundId" pairs the user already acted on
  int nextId;

  int newId() => nextId++;

  Post? post(int id) {
    for (final p in posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  Thread? thread(int id) {
    for (final t in threads) {
      if (t.id == id) return t;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'locality': locality,
        'radius': radius,
        'points': points,
        'typeFilter': typeFilter,
        'posts': posts.map((e) => e.toJson()).toList(),
        'threads': threads.map((e) => e.toJson()).toList(),
        'notifs': notifs.map((e) => e.toJson()).toList(),
        'areas': areas.map((e) => e.toJson()).toList(),
        'prefs': prefs,
        'told': told,
        'nextId': nextId,
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    List<T> l<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] ?? []) as List).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    final prefs = defaultPrefs();
    ((j['prefs'] ?? {}) as Map).forEach((k, v) => prefs[k as String] = v as bool);
    return AppData(
      name: j['name'] as String,
      locality: (j['locality'] ?? '') as String,
      radius: _d(j['radius'], 1),
      points: (j['points'] ?? 0) as int,
      typeFilter: (j['typeFilter'] ?? 'all') as String,
      posts: l('posts', Post.fromJson),
      threads: l('threads', Thread.fromJson),
      notifs: l('notifs', Notif.fromJson),
      areas: l('areas', Area.fromJson),
      prefs: prefs,
      told: ((j['told'] ?? []) as List).cast<String>(),
      nextId: (j['nextId'] ?? 1000) as int,
    );
  }
}

class PossibleMatch {
  const PossibleMatch(this.lost, this.found, this.score);
  final Post lost;
  final Post found;
  final int score;
  String get key => matchKey(lost.id, found.id);
}

String matchKey(int lostId, int foundId) => '$lostId-$foundId';

// ---------------- alerts ----------------

/// 'official' for verified groups, 'confirmed' once enough neighbours agree, otherwise 'unverified'.
String alertStatus(Post p) {
  if (p.official) return 'official';
  if (p.yes >= 5 && p.yes > p.no * 2) return 'confirmed';
  return 'unverified';
}

/// If most people say it's over, the alert closes early.
bool closedByVotes(Post p) => p.no >= 3 && p.no > p.yes;

/// Records the user's vote. Changing a vote moves it; the same vote twice does nothing.
/// Returns true only the first time the user votes on this post.
bool applyVote(Post p, String v) {
  if (p.myVote == v) return false;
  final first = p.myVote.isEmpty;
  if (p.myVote == 'yes') {
    p.yes = math.max(0, p.yes - 1);
  } else if (p.myVote == 'no') {
    p.no = math.max(0, p.no - 1);
  }
  if (v == 'yes') {
    p.yes++;
  } else {
    p.no++;
  }
  p.myVote = v;
  return first;
}

/// Alerts end when they expire, are marked over, or are voted closed.
/// Lost and found posts stay for 14 days; help and notices for 7.
bool isEnded(Post p, int now) {
  switch (p.type) {
    case 'alert':
      final exp = p.expiresAt;
      return p.resolved || closedByVotes(p) || (exp != null && exp <= now);
    case 'lost':
    case 'found':
      return now - p.at > 14 * dayMs;
    default:
      return now - p.at > 7 * dayMs;
  }
}

// ---------------- lists ----------------

List<Post> feedPosts(List<Post> posts, double radius, String type, int now) {
  final out = posts
      .where((p) => !p.hidden && !isEnded(p, now) && p.km <= radius + 1e-9 && (type == 'all' || p.type == type))
      .toList()
    ..sort((a, b) => b.at.compareTo(a.at));
  return out;
}

/// Alerts in [list] posted within the last two hours.
int liveAlertCount(List<Post> list, int now) =>
    list.where((p) => p.type == 'alert' && !p.resolved && now - p.at < 2 * hourMs).length;

/// Open lost or found posts (any distance, since pets travel), open ones first, newest first.
List<Post> lostFoundPosts(List<Post> posts, String type, int now) {
  final out = posts.where((p) => p.type == type && !p.hidden && !isEnded(p, now)).toList()
    ..sort((a, b) {
      if (a.resolved != b.resolved) return a.resolved ? 1 : -1;
      return b.at.compareTo(a.at);
    });
  return out;
}

const _stop = {
  'the', 'and', 'with', 'near', 'for', 'lost', 'found', 'from', 'this', 'that', 'has', 'have', 'was', 'very',
  'but', 'opposite', 'someone', 'please', 'your', 'our', 'his', 'her', 'its', 'are', 'not', 'any', 'some',
};

/// Lower-case words of 3+ letters, minus filler words.
Set<String> keywords(String s) =>
    s.toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((w) => w.length >= 3 && !_stop.contains(w)).toSet();

/// How well a found post matches a lost one: shared title words, same category,
/// and the found post must come after the lost one. 0 means no match.
int matchScore(Post lost, Post found) {
  if (lost.type != 'lost' || found.type != 'found') return 0;
  if (lost.cat != found.cat) return 0;
  if (found.at < lost.at) return 0;
  return keywords(lost.title).intersection(keywords(found.title)).length;
}

List<PossibleMatch> possibleMatches(List<Post> posts, int now) {
  bool open(Post p) => !p.hidden && !p.resolved && !isEnded(p, now);
  final out = <PossibleMatch>[];
  for (final l in posts.where((p) => p.type == 'lost' && open(p))) {
    for (final f in posts.where((p) => p.type == 'found' && open(p))) {
      if (l.mine && f.mine) continue;
      final s = matchScore(l, f);
      if (s >= 2) out.add(PossibleMatch(l, f, s));
    }
  }
  out.sort((a, b) => b.score.compareTo(a.score));
  return out;
}

String resolvedLabel(String type) {
  switch (type) {
    case 'lost':
      return 'Reunited';
    case 'found':
      return 'Returned to owner';
    case 'alert':
      return 'Over';
    case 'help':
      return 'Sorted';
    default:
      return 'Done';
  }
}

String resolveAction(String type) {
  switch (type) {
    case 'lost':
      return 'Mark as found';
    case 'found':
      return 'Mark as returned';
    case 'alert':
      return 'Mark as over';
    case 'help':
      return 'Mark as sorted';
    default:
      return 'Mark as done';
  }
}

/// "Lost dog: Bruno, brown indie" -> "Bruno, brown indie", cut to [max] characters.
String shortTitle(String title, [int max = 28]) {
  final t = title.replaceFirst(RegExp(r'^(Lost|Found)( dog| cat)?:\s*', caseSensitive: false), '').trim();
  if (t.length <= max) return t;
  return '${t.substring(0, max - 1).trimRight()}…';
}

/// Who a reply thread is with, from the post's author.
String replyName(Post p) => p.by == 'Neighbour' ? 'Neighbour · ${shortTitle(p.title, 20)}' : p.by;

// ---------------- map ----------------

const mapW = 340.0;
const mapH = 260.0;
const youX = 190.0;
const youY = 140.0;
const pxPerKm = 110.0;

class MapPoint {
  const MapPoint(this.x, this.y);
  final double x;
  final double y;
}

double _clampX(double v) => v < 14 ? 14 : (v > mapW - 14 ? mapW - 14 : v);
double _clampY(double v) => v < 14 ? 14 : (v > mapH - 14 ? mapH - 14 : v);

/// Places a pin [km] from "you" in a direction picked from [seed], so pins sit
/// near (not on) the reported spot and never reveal an exact address.
MapPoint placeOnMap(double km, int seed) {
  final angle = (seed * 137.508) * math.pi / 180;
  final r = km * pxPerKm;
  return MapPoint(_clampX(youX + math.cos(angle) * r), _clampY(youY + math.sin(angle) * r));
}

/// A point a short step away from the latest sighting (or the post itself).
MapPoint nextSightingPoint(Post p) {
  final last = p.sightings.isEmpty ? MapPoint(p.x, p.y) : MapPoint(p.sightings.last.x, p.sightings.last.y);
  final angle = (p.sightings.length * 71 + p.id * 29) * math.pi / 180;
  return MapPoint(_clampX(last.x + math.cos(angle) * 24), _clampY(last.y + math.sin(angle) * 24));
}

// ---------------- text ----------------

String ago(int now, int at) {
  final m = (now - at) ~/ minuteMs;
  if (m < 1) return 'just now';
  if (m < 60) return '$m min ago';
  if (m < 1440) return '${m ~/ 60} h ago';
  return '${m ~/ 1440} d ago';
}

/// 0.4 -> "0.4 km", 1.0 -> "1 km".
String kmText(double km) {
  final r = (km * 10).round() / 10;
  return r == r.roundToDouble() ? '${r.toInt()} km' : '$r km';
}

/// 0.5 -> "500 m", 2.0 -> "2 km".
String radiusLabel(double r) => r < 1 ? '${(r * 1000).round()} m' : kmText(r);

const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String clockLabel(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ap = d.hour < 12 ? 'AM' : 'PM';
  return d.minute == 0 ? '$h $ap' : '$h:${d.minute.toString().padLeft(2, '0')} $ap';
}

/// "10 PM", "Tomorrow 4 PM" or "3 Oct 9 AM".
String endsLabel(int now, int at) {
  final n = DateTime.fromMillisecondsSinceEpoch(now);
  final e = DateTime.fromMillisecondsSinceEpoch(at);
  final days = (DateTime(e.year, e.month, e.day).difference(DateTime(n.year, n.month, n.day)).inHours / 24).round();
  if (days == 0) return clockLabel(e);
  if (days == 1) return 'Tomorrow ${clockLabel(e)}';
  return '${e.day} ${_mon[e.month - 1]} ${clockLabel(e)}';
}

String shareText(Post p, String locality) {
  final where = [p.place, locality].where((s) => s.trim().isNotEmpty).join(', ');
  final b = StringBuffer('${typeLabels[p.type] ?? 'Post'}: ${p.title}');
  if (p.body.trim().isNotEmpty) b.write('\n${p.body.trim()}');
  if (where.isNotEmpty) b.write('\nWhere: $where');
  if (p.reward.trim().isNotEmpty) b.write('\n${p.reward.trim()}');
  b.write('\n(shared from Galli)');
  return b.toString();
}

String whatsappUrl(String text) => 'https://wa.me/?text=${Uri.encodeComponent(text)}';

String mapsUrl(String place, String locality) {
  final q = [place, locality].where((s) => s.trim().isNotEmpty).join(', ');
  return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}';
}
