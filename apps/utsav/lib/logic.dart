// Core data model and pure logic for Utsav.
// All money is stored as integer paise (₹1 = 100 paise).

/// One function within the wedding: Mehendi, Sangeet, Wedding...
class WEvent {
  WEvent({required this.id, required this.name, required this.date, required this.time, this.venue = ''});
  final String id;
  String name;
  String date; // yyyy-MM-dd
  String time; // HH:mm (24h)
  String venue;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'date': date, 'time': time, 'venue': venue};
  factory WEvent.fromJson(Map<String, dynamic> j) => WEvent(
        id: j['id'] as String,
        name: j['name'] as String,
        date: j['date'] as String,
        time: (j['time'] ?? '19:00') as String,
        venue: (j['venue'] ?? '') as String,
      );
}

/// RSVP status for a family.
const rsvpYes = 'yes';
const rsvpNo = 'no';
const rsvpWait = 'wait';

const rsvpLabels = {rsvpYes: 'Coming', rsvpWait: 'Waiting', rsvpNo: "Can't come"};

/// A family invited together: the unit for RSVPs and rooms.
class Guest {
  Guest({
    required this.id,
    required this.name,
    this.lead = '',
    this.phone = '',
    this.side = 'bride',
    this.people = 2,
    this.status = rsvpWait,
    List<String>? events,
    this.jain = 0,
    this.city = '',
    this.room,
    this.rel = '',
    this.remindedOn,
  }) : events = events ?? [];
  final int id;
  String name;
  String lead;
  String phone; // 10 digits, Indian mobile
  String side; // bride | groom
  int people;
  String status; // yes | no | wait
  List<String> events;
  int jain; // how many of them eat Jain food
  String city;
  String? room;
  String rel;
  String? remindedOn;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lead': lead,
        'phone': phone,
        'side': side,
        'people': people,
        'status': status,
        'events': events,
        'jain': jain,
        'city': city,
        'room': room,
        'rel': rel,
        'remindedOn': remindedOn,
      };
  factory Guest.fromJson(Map<String, dynamic> j) => Guest(
        id: j['id'] as int,
        name: j['name'] as String,
        lead: (j['lead'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        side: (j['side'] ?? 'bride') as String,
        people: (j['people'] ?? 1) as int,
        status: (j['status'] ?? rsvpWait) as String,
        events: ((j['events'] ?? []) as List).cast<String>().toList(),
        jain: (j['jain'] ?? 0) as int,
        city: (j['city'] ?? '') as String,
        room: j['room'] as String?,
        rel: (j['rel'] ?? '') as String,
        remindedOn: j['remindedOn'] as String?,
      );
}

class WTask {
  WTask({required this.id, required this.title, required this.who, required this.ev, required this.due, this.done = false});
  final int id;
  String title;
  String who; // "You" or a helper's name
  String ev; // event id ('' when not tied to an event)
  String due; // yyyy-MM-dd
  bool done;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'who': who, 'ev': ev, 'due': due, 'done': done};
  factory WTask.fromJson(Map<String, dynamic> j) => WTask(
        id: j['id'] as int,
        title: j['title'] as String,
        who: j['who'] as String,
        ev: (j['ev'] ?? '') as String,
        due: j['due'] as String,
        done: (j['done'] ?? false) as bool,
      );
}

/// A relative who helps with tasks. Phone is optional (used for WhatsApp).
class Helper {
  Helper({required this.name, this.phone = ''});
  String name;
  String phone;

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
  factory Helper.fromJson(Map<String, dynamic> j) => Helper(name: j['name'] as String, phone: (j['phone'] ?? '') as String);
}

class BudgetLine {
  BudgetLine({required this.id, required this.cat, this.est = 0, this.com = 0, this.paid = 0});
  final int id;
  String cat;
  int est; // estimate
  int com; // committed (signed contracts, agreed amounts)
  int paid;

  bool get over => com > est;

  Map<String, dynamic> toJson() => {'id': id, 'cat': cat, 'est': est, 'com': com, 'paid': paid};
  factory BudgetLine.fromJson(Map<String, dynamic> j) => BudgetLine(
        id: j['id'] as int,
        cat: j['cat'] as String,
        est: (j['est'] ?? 0) as int,
        com: (j['com'] ?? 0) as int,
        paid: (j['paid'] ?? 0) as int,
      );
}

class VendorPayment {
  VendorPayment({required this.amount, required this.method, required this.date});
  final int amount;
  final String method;
  final String date;

  Map<String, dynamic> toJson() => {'amount': amount, 'method': method, 'date': date};
  factory VendorPayment.fromJson(Map<String, dynamic> j) =>
      VendorPayment(amount: j['amount'] as int, method: (j['method'] ?? '') as String, date: j['date'] as String);
}

class Vendor {
  Vendor({
    required this.id,
    required this.name,
    required this.cat,
    this.phone = '',
    required this.total,
    this.paid = 0,
    this.nextAmount,
    this.nextDue,
    this.note = '',
    List<VendorPayment>? payments,
  }) : payments = payments ?? [];
  final int id;
  String name;
  String cat; // matches a BudgetLine.cat
  String phone;
  int total;
  int paid;
  int? nextAmount;
  String? nextDue;
  String note;
  List<VendorPayment> payments;

  int get left => total - paid > 0 ? total - paid : 0;
  bool get hasNext => nextAmount != null && nextDue != null && left > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cat': cat,
        'phone': phone,
        'total': total,
        'paid': paid,
        'nextAmount': nextAmount,
        'nextDue': nextDue,
        'note': note,
        'payments': payments.map((p) => p.toJson()).toList(),
      };
  factory Vendor.fromJson(Map<String, dynamic> j) => Vendor(
        id: j['id'] as int,
        name: j['name'] as String,
        cat: (j['cat'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        total: (j['total'] ?? 0) as int,
        paid: (j['paid'] ?? 0) as int,
        nextAmount: j['nextAmount'] as int?,
        nextDue: j['nextDue'] as String?,
        note: (j['note'] ?? '') as String,
        payments: ((j['payments'] ?? []) as List).map((e) => VendorPayment.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
}

class AppData {
  AppData({
    required this.myName,
    required this.bride,
    required this.groom,
    required this.city,
    required this.weddingDate,
    List<WEvent>? events,
    List<Guest>? guests,
    List<WTask>? tasks,
    List<Helper>? helpers,
    List<BudgetLine>? budget,
    List<Vendor>? vendors,
    this.hotelName = '',
    this.hotelRooms = 0,
    this.perRoom = 3,
    this.bufferPct = 10,
    this.nextId = 1000,
  })  : events = events ?? [],
        guests = guests ?? [],
        tasks = tasks ?? [],
        helpers = helpers ?? [],
        budget = budget ?? [],
        vendors = vendors ?? [];

  String myName;
  String bride;
  String groom;
  String city; // home city: guests from elsewhere need rooms
  String weddingDate;
  List<WEvent> events;
  List<Guest> guests;
  List<WTask> tasks;
  List<Helper> helpers;
  List<BudgetLine> budget;
  List<Vendor> vendors;
  String hotelName;
  int hotelRooms;
  int perRoom;
  int bufferPct;
  int nextId;

  int newId() => nextId++;

  String get couple => '$bride & $groom';

  WEvent? event(String id) {
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
  }

  Guest? guest(int id) {
    for (final g in guests) {
      if (g.id == id) return g;
    }
    return null;
  }

  WTask? task(int id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Vendor? vendor(int id) {
    for (final v in vendors) {
      if (v.id == id) return v;
    }
    return null;
  }

  BudgetLine? line(int id) {
    for (final b in budget) {
      if (b.id == id) return b;
    }
    return null;
  }

  BudgetLine? lineFor(String cat) {
    for (final b in budget) {
      if (b.cat == cat) return b;
    }
    return null;
  }

  Helper? helper(String name) {
    for (final h in helpers) {
      if (h.name == name) return h;
    }
    return null;
  }

  String eventName(String id) => event(id)?.name ?? 'General';
  String sideName(String side) => side == 'groom' ? "$groom's side" : "$bride's side";

  /// Events in date and time order.
  List<WEvent> get sortedEvents => [...events]..sort((a, b) => '${a.date} ${a.time}'.compareTo('${b.date} ${b.time}'));

  Map<String, dynamic> toJson() => {
        'myName': myName,
        'bride': bride,
        'groom': groom,
        'city': city,
        'weddingDate': weddingDate,
        'events': events.map((e) => e.toJson()).toList(),
        'guests': guests.map((e) => e.toJson()).toList(),
        'tasks': tasks.map((e) => e.toJson()).toList(),
        'helpers': helpers.map((e) => e.toJson()).toList(),
        'budget': budget.map((e) => e.toJson()).toList(),
        'vendors': vendors.map((e) => e.toJson()).toList(),
        'hotelName': hotelName,
        'hotelRooms': hotelRooms,
        'perRoom': perRoom,
        'bufferPct': bufferPct,
        'nextId': nextId,
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    List<T> l<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] ?? []) as List).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    return AppData(
      myName: (j['myName'] ?? '') as String,
      bride: j['bride'] as String,
      groom: j['groom'] as String,
      city: (j['city'] ?? '') as String,
      weddingDate: j['weddingDate'] as String,
      events: l('events', WEvent.fromJson),
      guests: l('guests', Guest.fromJson),
      tasks: l('tasks', WTask.fromJson),
      helpers: l('helpers', Helper.fromJson),
      budget: l('budget', BudgetLine.fromJson),
      vendors: l('vendors', Vendor.fromJson),
      hotelName: (j['hotelName'] ?? '') as String,
      hotelRooms: (j['hotelRooms'] ?? 0) as int,
      perRoom: (j['perRoom'] ?? 3) as int,
      bufferPct: (j['bufferPct'] ?? 10) as int,
      nextId: (j['nextId'] ?? 1000) as int,
    );
  }
}

// ---------------- headcounts ----------------

bool attends(Guest g, String evId) => g.status == rsvpYes && g.events.contains(evId);

/// People confirmed for an event.
int confirmedFor(List<Guest> guests, String evId) =>
    guests.where((g) => attends(g, evId)).fold<int>(0, (a, g) => a + g.people);

/// Jain plates among the confirmed (never more than the family's size).
int jainFor(List<Guest> guests, String evId) =>
    guests.where((g) => attends(g, evId)).fold<int>(0, (a, g) => a + (g.jain < g.people ? g.jain : g.people));

/// Plates to order: confirmed plus a buffer, rounded up.
int platesWithBuffer(int confirmed, int bufferPct) {
  if (confirmed <= 0) return 0;
  final t = confirmed * (100 + bufferPct);
  return (t + 99) ~/ 100;
}

int familiesWaiting(List<Guest> guests) => guests.where((g) => g.status == rsvpWait).length;
int peopleConfirmed(List<Guest> guests) =>
    guests.where((g) => g.status == rsvpYes).fold<int>(0, (a, g) => a + g.people);

/// Families still expected at an event: coming, or not yet replied.
int familiesInvitedTo(List<Guest> guests, String evId) =>
    guests.where((g) => g.status != rsvpNo && (g.events.contains(evId) || g.status == rsvpWait)).length;

String headcountText(AppData d, WEvent e, String today) {
  final c = confirmedFor(d.guests, e.id);
  final j = jainFor(d.guests, e.id);
  final lines = [
    '${e.name}, ${dayName(e.date)} ${shortDate(e.date)}, ${time12(e.time)}',
    if (e.venue.isNotEmpty) e.venue,
    'Confirmed: $c',
    'Veg: ${c - j}  ·  Jain: $j',
    'With ${d.bufferPct}% buffer: ${platesWithBuffer(c, d.bufferPct)} plates',
    'Updated ${shortDate(today)}',
  ];
  return lines.join('\n');
}

// ---------------- rooms ----------------

class RoomPlan {
  RoomPlan(this.rooms, this.used, this.unplaced);

  /// guest id -> room label, e.g. "101" or "102–103".
  final Map<int, String> rooms;
  final int used;

  /// Confirmed out-of-town families who didn't fit.
  final List<int> unplaced;
}

int roomsNeeded(int people, int perRoom) {
  final cap = perRoom < 1 ? 1 : perRoom;
  return people <= 0 ? 0 : (people + cap - 1) ~/ cap;
}

/// First-fit, largest families first. Only confirmed families from outside [homeCity].
RoomPlan allotRooms(List<Guest> guests, {required String homeCity, required int rooms, int perRoom = 3, int firstRoom = 101}) {
  final home = homeCity.trim().toLowerCase();
  final out = guests
      .where((g) => g.status == rsvpYes && g.city.trim().isNotEmpty && g.city.trim().toLowerCase() != home)
      .toList()
    ..sort((a, b) {
      final c = b.people.compareTo(a.people);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  final plan = <int, String>{};
  final unplaced = <int>[];
  var r = firstRoom;
  var used = 0;
  for (final g in out) {
    final need = roomsNeeded(g.people, perRoom);
    if (need > 0 && used + need <= rooms) {
      plan[g.id] = need == 1 ? '$r' : '$r–${r + need - 1}';
      r += need;
      used += need;
    } else {
      unplaced.add(g.id);
    }
  }
  return RoomPlan(plan, used, unplaced);
}

// ---------------- budget ----------------

class BudgetTotals {
  const BudgetTotals(this.est, this.com, this.paid);
  final int est;
  final int com;
  final int paid;
  int get toPay => com - paid > 0 ? com - paid : 0;

  /// 0..1 of the estimate that is paid / committed (0 when there's no estimate).
  double get paidShare => est <= 0 ? 0 : (paid / est).clamp(0.0, 1.0).toDouble();
  double get committedShare => est <= 0 ? 0 : (com / est).clamp(0.0, 1.0).toDouble();
  int get paidPercent => est <= 0 ? 0 : (paid * 100 + est ~/ 2) ~/ est;
}

BudgetTotals budgetTotals(List<BudgetLine> lines) {
  var e = 0, c = 0, p = 0;
  for (final b in lines) {
    e += b.est;
    c += b.com;
    p += b.paid;
  }
  return BudgetTotals(e, c, p);
}

// ---------------- vendor payments ----------------

class PaymentResult {
  const PaymentResult({required this.applied, required this.paid, this.nextAmount, this.nextDue});
  final int applied; // what actually counted (never more than what was left)
  final int paid;
  final int? nextAmount;
  final String? nextDue;
}

/// Applies a payment to a vendor contract.
/// Paying less than the due instalment leaves the rest due on the same date;
/// paying it in full moves the remaining balance to [gapDays] later.
PaymentResult applyPayment({
  required int total,
  required int paid,
  int? nextAmount,
  String? nextDue,
  required int amount,
  required String today,
  int gapDays = 30,
}) {
  final left = total - paid > 0 ? total - paid : 0;
  final applied = amount <= 0 ? 0 : (amount < left ? amount : left);
  final newPaid = paid + applied;
  final rest = total - newPaid;
  if (rest <= 0) return PaymentResult(applied: applied, paid: newPaid);
  if (nextAmount != null && nextDue != null && applied < nextAmount) {
    final due = nextAmount - applied;
    return PaymentResult(applied: applied, paid: newPaid, nextAmount: due < rest ? due : rest, nextDue: nextDue);
  }
  final base = nextDue ?? today;
  return PaymentResult(applied: applied, paid: newPaid, nextAmount: rest, nextDue: addDaysIso(base, gapDays));
}

// ---------------- tasks ----------------

bool isOverdue(WTask t, String today) => !t.done && t.due.compareTo(today) < 0;

List<WTask> openTasks(List<WTask> tasks) => tasks.where((t) => !t.done).toList()..sort((a, b) => a.due.compareTo(b.due));

class Workload {
  Workload(this.who, this.open, this.done);
  final String who;
  int open;
  int done;
}

/// Open and done task counts per person, in order of first appearance.
List<Workload> workload(List<WTask> tasks) {
  final m = <String, Workload>{};
  for (final t in tasks) {
    final w = m.putIfAbsent(t.who, () => Workload(t.who, 0, 0));
    if (t.done) {
      w.done++;
    } else {
      w.open++;
    }
  }
  return m.values.toList();
}

// ---------------- messages ----------------

String rsvpReminderText(AppData d) {
  final evs = d.sortedEvents;
  final range = evs.isEmpty ? shortDate(d.weddingDate) : dateRange(evs.first.date, evs.last.date);
  final names = evs.map((e) => e.name).join(', ');
  return 'Namaste! We would love to know if you can join us for ${d.bride} and ${d.groom}\'s wedding celebrations'
      '${d.city.isEmpty ? '' : ' in ${d.city}'}, $range.\n\n'
      'Please reply with which functions you will attend${names.isEmpty ? '' : ' ($names)'} and how many of you are coming. '
      'Do tell us if anyone eats Jain food.\n\n'
      'With love,\n${d.myName.isEmpty ? 'The family' : d.myName}';
}

String taskMessage(AppData d, WTask t) {
  final ev = d.event(t.ev);
  return 'Namaste ${t.who}! For ${d.bride} and ${d.groom}\'s wedding, could you please take care of this:\n\n'
      '${t.title}${ev == null ? '' : ' (${ev.name})'}\nBy ${dayName(t.due)} ${shortDate(t.due)}\n\nThank you!';
}

String taskListMessage(AppData d, String who) {
  final list = openTasks(d.tasks).where((t) => t.who == who).toList();
  final lines = [for (final t in list) '• ${t.title} (by ${shortDate(t.due)})'];
  return 'Namaste $who! Your tasks for ${d.bride} and ${d.groom}\'s wedding:\n\n${lines.join('\n')}\n\nPlease tell me when each one is done. Thank you!';
}

/// Digits only, with India's country code, for wa.me links. Empty if not a usable number.
String waNumber(String phone) {
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('0')) digits = digits.substring(1);
  if (digits.length == 10) return '91$digits';
  if (digits.length == 12 && digits.startsWith('91')) return digits;
  return '';
}

/// A WhatsApp link: to a person when [phone] is usable, else "pick a chat".
String waLink(String text, {String phone = ''}) {
  final n = waNumber(phone);
  return 'https://wa.me/$n?text=${Uri.encodeComponent(text)}';
}

String prettyPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 10) return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
  return phone;
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

int daysBetween(String a, String b) {
  final x = parseIso(a), y = parseIso(b);
  return DateTime.utc(y.year, y.month, y.day).difference(DateTime.utc(x.year, x.month, x.day)).inDays;
}

const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monLong = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
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

/// "11–14 December", or "30 November – 2 December" across months.
String dateRange(String a, String b) {
  final x = parseIso(a), y = parseIso(b);
  if (a == b) return '${x.day} ${_monLong[x.month - 1]}';
  if (x.year == y.year && x.month == y.month) return '${x.day}–${y.day} ${_monLong[x.month - 1]}';
  return '${x.day} ${_monLong[x.month - 1]} – ${y.day} ${_monLong[y.month - 1]}';
}

/// "19:00" -> "7 PM", "16:30" -> "4:30 PM".
String time12(String t) {
  final p = t.split(':');
  if (p.length != 2) return t;
  final h = int.tryParse(p[0]) ?? 0;
  final m = int.tryParse(p[1]) ?? 0;
  final ap = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return m == 0 ? '$h12 $ap' : '$h12:${m.toString().padLeft(2, '0')} $ap';
}

String hhmm(int hour, int minute) => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

String dueText(int days) {
  if (days < -1) return 'overdue by ${-days} days';
  if (days == -1) return 'overdue since yesterday';
  if (days == 0) return 'due today';
  if (days == 1) return 'due tomorrow';
  return 'due in $days days';
}

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

/// Short form for big numbers: ₹9.6 L, ₹48 L, ₹1.2 Cr; smaller amounts in full.
String inrShort(int paise) {
  final neg = paise < 0;
  final r = (paise.abs() + 50) ~/ 100;
  String one(int v, int unit, String suffix) {
    final tenths = (v * 10 + unit ~/ 2) ~/ unit; // rounded to 1 decimal
    final whole = tenths ~/ 10, frac = tenths % 10;
    return frac == 0 ? '$whole $suffix' : '$whole.$frac $suffix';
  }

  final String body;
  if (r >= 10000000) {
    body = one(r, 10000000, 'Cr');
  } else if (r >= 100000) {
    body = one(r, 100000, 'L');
  } else {
    body = _group(r);
  }
  return '${neg ? '-' : ''}₹$body';
}

/// Parses user input like "1,250.50" into paise. Returns null if invalid.
int? parseRupees(String text) {
  final v = double.tryParse(text.replaceAll(',', '').replaceAll('₹', '').trim());
  if (v == null || v.isNaN || v.isInfinite) return null;
  return (v * 100).round();
}

/// Paise to an editable rupee string ("1250" or "1250.50").
String rupeesField(int paise) {
  final r = paise ~/ 100, p = paise % 100;
  return p == 0 ? '$r' : '$r.${p.toString().padLeft(2, '0')}';
}

// ---------------- defaults ----------------

const defaultCategories = [
  'Venue',
  'Catering',
  'Decor and flowers',
  'Clothing and jewellery',
  'Photography',
  'Music and Sangeet',
  'Rooms and travel',
  'Gifts and misc',
];

const paymentMethods = ['UPI', 'Bank transfer', 'Cash', 'Cheque'];

/// Standard functions, as (name, days from the wedding day, time).
const presetEvents = [
  ('Mehendi', -2, '16:00'),
  ('Haldi', -1, '10:00'),
  ('Sangeet', -1, '19:00'),
  ('Wedding', 0, '19:00'),
  ('Reception', 1, '20:00'),
];
