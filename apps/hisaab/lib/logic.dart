// Core data model and pure logic for Hisaab.
// All money is stored as integer paise (₹1 = 100 paise).

class Member {
  Member({required this.id, required this.name, this.upi = '', this.away = false});
  final String id;
  String name;
  String upi;
  bool away;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'upi': upi, 'away': away};
  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: j['id'] as String,
        name: j['name'] as String,
        upi: (j['upi'] ?? '') as String,
        away: (j['away'] ?? false) as bool,
      );
}

class Expense {
  Expense({
    required this.id,
    required this.desc,
    required this.amount,
    required this.paidBy,
    required this.shares,
    required this.mode,
    required this.cat,
    required this.date,
    this.note = '',
  });
  final int id;
  String desc;
  int amount;
  String paidBy;
  Map<String, int> shares;
  String mode; // equal | exact | shares
  String cat;
  String date; // yyyy-MM-dd
  String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'desc': desc,
        'amount': amount,
        'paidBy': paidBy,
        'shares': shares,
        'mode': mode,
        'cat': cat,
        'date': date,
        'note': note,
      };
  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as int,
        desc: j['desc'] as String,
        amount: j['amount'] as int,
        paidBy: j['paidBy'] as String,
        shares: (j['shares'] as Map).map((k, v) => MapEntry(k as String, v as int)),
        mode: j['mode'] as String,
        cat: j['cat'] as String,
        date: j['date'] as String,
        note: (j['note'] ?? '') as String,
      );
}

class Payment {
  Payment({required this.id, required this.from, required this.to, required this.amount, required this.date});
  final int id;
  final String from;
  final String to;
  final int amount;
  final String date;

  Map<String, dynamic> toJson() => {'id': id, 'from': from, 'to': to, 'amount': amount, 'date': date};
  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'] as int,
        from: j['from'] as String,
        to: j['to'] as String,
        amount: j['amount'] as int,
        date: j['date'] as String,
      );
}

class Recurring {
  Recurring({required this.id, required this.desc, required this.amount, required this.paidBy, required this.cat, required this.next});
  final int id;
  String desc;
  int amount;
  String paidBy;
  String cat;
  String next;

  Map<String, dynamic> toJson() => {'id': id, 'desc': desc, 'amount': amount, 'paidBy': paidBy, 'cat': cat, 'next': next};
  factory Recurring.fromJson(Map<String, dynamic> j) => Recurring(
        id: j['id'] as int,
        desc: j['desc'] as String,
        amount: j['amount'] as int,
        paidBy: j['paidBy'] as String,
        cat: j['cat'] as String,
        next: j['next'] as String,
      );
}

class ListItem {
  ListItem({required this.id, required this.name, required this.by, this.done = false, this.boughtBy});
  final int id;
  String name;
  String by;
  bool done;
  String? boughtBy;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'by': by, 'done': done, 'boughtBy': boughtBy};
  factory ListItem.fromJson(Map<String, dynamic> j) => ListItem(
        id: j['id'] as int,
        name: j['name'] as String,
        by: j['by'] as String,
        done: (j['done'] ?? false) as bool,
        boughtBy: j['boughtBy'] as String?,
      );
}

class Chore {
  Chore({required this.id, required this.name, required this.everyDays, required this.rotation, this.idx = 0, required this.due});
  final int id;
  String name;
  int everyDays;
  List<String> rotation;
  int idx;
  String due;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'everyDays': everyDays, 'rotation': rotation, 'idx': idx, 'due': due};
  factory Chore.fromJson(Map<String, dynamic> j) => Chore(
        id: j['id'] as int,
        name: j['name'] as String,
        everyDays: j['everyDays'] as int,
        rotation: (j['rotation'] as List).cast<String>(),
        idx: (j['idx'] ?? 0) as int,
        due: j['due'] as String,
      );
}

class Activity {
  Activity(this.text, this.date);
  final String text;
  final String date;
  Map<String, dynamic> toJson() => {'text': text, 'date': date};
  factory Activity.fromJson(Map<String, dynamic> j) => Activity(j['text'] as String, j['date'] as String);
}

class Transfer {
  const Transfer(this.from, this.to, this.amount);
  final String from;
  final String to;
  final int amount;
  @override
  String toString() => '$from->$to:$amount';
}

class AppData {
  AppData({
    required this.flatName,
    required this.meId,
    required this.members,
    List<Expense>? expenses,
    List<Payment>? payments,
    List<Recurring>? recurring,
    List<ListItem>? list,
    List<Chore>? chores,
    Map<String, int>? points,
    List<Activity>? activity,
    this.simplify = true,
    this.nextId = 1000,
  })  : expenses = expenses ?? [],
        payments = payments ?? [],
        recurring = recurring ?? [],
        list = list ?? [],
        chores = chores ?? [],
        points = points ?? {},
        activity = activity ?? [];

  String flatName;
  String meId;
  List<Member> members;
  List<Expense> expenses;
  List<Payment> payments;
  List<Recurring> recurring;
  List<ListItem> list;
  List<Chore> chores;
  Map<String, int> points;
  List<Activity> activity;
  bool simplify;
  int nextId;

  int newId() => nextId++;

  Member? member(String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  String nameOf(String id) => id == meId ? 'You' : (member(id)?.name ?? 'Someone');
  String nameObj(String id) => id == meId ? 'you' : (member(id)?.name ?? 'someone');

  Map<String, dynamic> toJson() => {
        'flatName': flatName,
        'meId': meId,
        'members': members.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'payments': payments.map((e) => e.toJson()).toList(),
        'recurring': recurring.map((e) => e.toJson()).toList(),
        'list': list.map((e) => e.toJson()).toList(),
        'chores': chores.map((e) => e.toJson()).toList(),
        'points': points,
        'activity': activity.map((e) => e.toJson()).toList(),
        'simplify': simplify,
        'nextId': nextId,
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    List<T> l<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] ?? []) as List).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    return AppData(
      flatName: j['flatName'] as String,
      meId: j['meId'] as String,
      members: l('members', Member.fromJson),
      expenses: l('expenses', Expense.fromJson),
      payments: l('payments', Payment.fromJson),
      recurring: l('recurring', Recurring.fromJson),
      list: l('list', ListItem.fromJson),
      chores: l('chores', Chore.fromJson),
      points: ((j['points'] ?? {}) as Map).map((k, v) => MapEntry(k as String, v as int)),
      activity: l('activity', Activity.fromJson),
      simplify: (j['simplify'] ?? true) as bool,
      nextId: (j['nextId'] ?? 1000) as int,
    );
  }
}

// ---------------- splitting ----------------

/// Splits [amount] paise equally. Leftover paise go to the first people in order,
/// so the shares always add up exactly to [amount].
Map<String, int> equalShares(int amount, List<String> ids) {
  if (ids.isEmpty) return {};
  final base = amount ~/ ids.length;
  var extra = amount - base * ids.length;
  final out = <String, int>{};
  for (final id in ids) {
    out[id] = base + (extra > 0 ? 1 : 0);
    if (extra > 0) extra--;
  }
  return out;
}

/// Splits [amount] by integer weights (shares). The last person absorbs rounding.
Map<String, int> weightedShares(int amount, Map<String, int> weights) {
  final ids = weights.keys.where((k) => (weights[k] ?? 0) > 0).toList();
  final total = ids.fold<int>(0, (a, k) => a + weights[k]!);
  if (total == 0) return {};
  final out = <String, int>{};
  var used = 0;
  for (var i = 0; i < ids.length; i++) {
    final id = ids[i];
    final v = i == ids.length - 1 ? amount - used : (amount * weights[id]! / total).round();
    used += v;
    out[id] = v;
  }
  return out;
}

// ---------------- balances ----------------

/// Positive = the person is owed money; negative = they owe.
Map<String, int> netBalances(List<String> ids, List<Expense> expenses, List<Payment> payments) {
  final net = {for (final id in ids) id: 0};
  for (final e in expenses) {
    net[e.paidBy] = (net[e.paidBy] ?? 0) + e.amount;
    e.shares.forEach((id, v) => net[id] = (net[id] ?? 0) - v);
  }
  for (final p in payments) {
    net[p.from] = (net[p.from] ?? 0) + p.amount;
    net[p.to] = (net[p.to] ?? 0) - p.amount;
  }
  return net;
}

/// Greedy settlement: largest debtor pays largest creditor. At most n-1 transfers.
/// Amounts under ₹1 are ignored.
List<Transfer> simplifyDebts(Map<String, int> net) {
  final cr = net.entries.where((e) => e.value > 50).map((e) => [e.key, e.value]).toList()
    ..sort((a, b) => (b[1] as int).compareTo(a[1] as int));
  final db = net.entries.where((e) => e.value < -50).map((e) => [e.key, -e.value]).toList()
    ..sort((a, b) => (b[1] as int).compareTo(a[1] as int));
  final out = <Transfer>[];
  var i = 0, j = 0;
  while (i < db.length && j < cr.length) {
    final d = db[i][1] as int, c = cr[j][1] as int;
    final x = d < c ? d : c;
    if (x > 50) out.add(Transfer(db[i][0] as String, cr[j][0] as String, x));
    db[i][1] = d - x;
    cr[j][1] = c - x;
    if ((db[i][1] as int) <= 50) i++;
    if ((cr[j][1] as int) <= 50) j++;
  }
  return out;
}

/// Each pair settles only what they owe each other.
List<Transfer> pairwiseDebts(List<String> ids, List<Expense> expenses, List<Payment> payments) {
  final m = <String, Map<String, int>>{for (final a in ids) a: {for (final b in ids) b: 0}};
  for (final e in expenses) {
    e.shares.forEach((id, v) {
      if (id != e.paidBy && m.containsKey(id) && m[id]!.containsKey(e.paidBy)) {
        m[id]![e.paidBy] = m[id]![e.paidBy]! + v;
      }
    });
  }
  for (final p in payments) {
    if (m.containsKey(p.from) && m[p.from]!.containsKey(p.to)) {
      m[p.from]![p.to] = m[p.from]![p.to]! - p.amount;
    }
  }
  final out = <Transfer>[];
  for (var a = 0; a < ids.length; a++) {
    for (var b = a + 1; b < ids.length; b++) {
      final d = m[ids[a]]![ids[b]]! - m[ids[b]]![ids[a]]!;
      if (d > 50) out.add(Transfer(ids[a], ids[b], d));
      if (d < -50) out.add(Transfer(ids[b], ids[a], -d));
    }
  }
  out.sort((x, y) => y.amount.compareTo(x.amount));
  return out;
}

// ---------------- chores ----------------

/// Index in the rotation whose turn it is, skipping people who are away.
int currentTurn(Chore c, Set<String> away) {
  for (var k = 0; k < c.rotation.length; k++) {
    final i = (c.idx + k) % c.rotation.length;
    if (!away.contains(c.rotation[i])) return i;
  }
  return c.idx % (c.rotation.isEmpty ? 1 : c.rotation.length);
}

// ---------------- dates ----------------

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime parseIso(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String todayIso() => isoDate(DateTime.now());
String addDaysIso(String s, int n) => isoDate(parseIso(s).add(Duration(days: n)));
String addMonthIso(String s) {
  final d = parseIso(s);
  final lastDay = DateTime(d.year, d.month + 2, 0).day;
  return isoDate(DateTime(d.year, d.month + 1, d.day > lastDay ? lastDay : d.day));
}

int daysBetween(String a, String b) => parseIso(b).difference(parseIso(a)).inHours ~/ 24;

const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
String shortDate(String s) {
  final d = parseIso(s);
  return '${d.day} ${_mon[d.month - 1]}';
}

String dayName(String s) => _dow[parseIso(s).weekday - 1];
String monthName(int m) => _mon[m - 1];

// ---------------- money ----------------

String _group(int rupees) {
  final s = rupees.toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

/// ₹ with Indian digit grouping, rounded to the rupee.
String inr(int paise) {
  final neg = paise < 0;
  final r = (paise.abs() + 50) ~/ 100;
  return '${neg ? '-' : ''}₹${_group(r)}';
}

/// ₹ with paise shown when not a whole rupee.
String inrExact(int paise) {
  final neg = paise < 0;
  final a = paise.abs();
  final r = a ~/ 100, p = a % 100;
  return '${neg ? '-' : ''}₹${_group(r)}${p == 0 ? '' : '.${p.toString().padLeft(2, '0')}'}';
}

/// Parses user input like "1,250.50" into paise. Returns null if invalid.
int? parseRupees(String text) {
  final v = double.tryParse(text.replaceAll(',', '').replaceAll('₹', '').trim());
  if (v == null || v.isNaN || v.isInfinite) return null;
  return (v * 100).round();
}

// ---------------- categories ----------------

const categories = {
  'rent': 'Rent',
  'utilities': 'Bills',
  'food': 'Food',
  'help': 'House help',
  'other': 'Other',
};
