// Core data model and pure logic for Rasid, the warranty vault.
// All money is stored as integer paise (₹1 = 100 paise). Dates are yyyy-MM-dd strings.

// ---------------- models ----------------

class Member {
  Member({required this.id, required this.name});
  final String id;
  String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Member.fromJson(Map<String, dynamic> j) => Member(id: j['id'] as String, name: j['name'] as String);
}

class Warranty {
  Warranty({required this.label, required this.until});
  String label; // Product, Extended, Compressor, Motor, AMC ...
  String until;

  Map<String, dynamic> toJson() => {'label': label, 'until': until};
  factory Warranty.fromJson(Map<String, dynamic> j) =>
      Warranty(label: j['label'] as String, until: j['until'] as String);
}

class Repair {
  Repair({required this.date, required this.cost, this.note = ''});
  String date;
  int cost;
  String note;

  Map<String, dynamic> toJson() => {'date': date, 'cost': cost, 'note': note};
  factory Repair.fromJson(Map<String, dynamic> j) =>
      Repair(date: j['date'] as String, cost: j['cost'] as int, note: (j['note'] ?? '') as String);
}

class Item {
  Item({
    required this.id,
    required this.name,
    this.brand = '',
    this.model = '',
    this.serial = '',
    this.cat = 'other',
    this.room = '',
    required this.price,
    required this.date,
    this.store = '',
    this.inv = '',
    List<Warranty>? warranties,
    this.owner = 'me',
    List<Repair>? repairs,
  })  : warranties = warranties ?? [],
        repairs = repairs ?? [];

  final int id;
  String name;
  String brand;
  String model;
  String serial;
  String cat;
  String room;
  int price;
  String date; // bought on
  String store;
  String inv;
  List<Warranty> warranties;
  String owner;
  List<Repair> repairs;

  String get title => brand.trim().isEmpty ? name : '$brand $name';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'model': model,
        'serial': serial,
        'cat': cat,
        'room': room,
        'price': price,
        'date': date,
        'store': store,
        'inv': inv,
        'warranties': warranties.map((w) => w.toJson()).toList(),
        'owner': owner,
        'repairs': repairs.map((r) => r.toJson()).toList(),
      };

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] as int,
        name: j['name'] as String,
        brand: (j['brand'] ?? '') as String,
        model: (j['model'] ?? '') as String,
        serial: (j['serial'] ?? '') as String,
        cat: (j['cat'] ?? 'other') as String,
        room: (j['room'] ?? '') as String,
        price: j['price'] as int,
        date: j['date'] as String,
        store: (j['store'] ?? '') as String,
        inv: (j['inv'] ?? '') as String,
        warranties: ((j['warranties'] ?? []) as List)
            .map((e) => Warranty.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        owner: (j['owner'] ?? 'me') as String,
        repairs: ((j['repairs'] ?? []) as List).map((e) => Repair.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
}

class ClaimStep {
  ClaimStep({required this.title, this.date, this.done = false, this.now = false, this.note = ''});
  String title;
  String? date;
  bool done;
  bool now;
  String note;

  Map<String, dynamic> toJson() => {'title': title, 'date': date, 'done': done, 'now': now, 'note': note};
  factory ClaimStep.fromJson(Map<String, dynamic> j) => ClaimStep(
        title: j['title'] as String,
        date: j['date'] as String?,
        done: (j['done'] ?? false) as bool,
        now: (j['now'] ?? false) as bool,
        note: (j['note'] ?? '') as String,
      );
}

class Claim {
  Claim({required this.id, required this.itemId, required this.issue, required this.under, this.ref = '', required this.steps});
  final int id;
  final int itemId;
  String issue;
  String under;
  String ref;
  List<ClaimStep> steps;

  bool get isOpen => steps.isNotEmpty && !steps.last.done;
  String get started => steps.isNotEmpty && steps.first.date != null ? steps.first.date! : todayIso();

  ClaimStep? get current {
    for (final s in steps) {
      if (s.now) return s;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'issue': issue,
        'under': under,
        'ref': ref,
        'steps': steps.map((s) => s.toJson()).toList(),
      };
  factory Claim.fromJson(Map<String, dynamic> j) => Claim(
        id: j['id'] as int,
        itemId: j['itemId'] as int,
        issue: j['issue'] as String,
        under: (j['under'] ?? '') as String,
        ref: (j['ref'] ?? '') as String,
        steps: ((j['steps'] ?? []) as List).map((e) => ClaimStep.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
}

class Reminder {
  Reminder({
    required this.id,
    required this.title,
    required this.date,
    this.itemId,
    this.kind = 'service',
    this.on = true,
    this.everyMonths = 0,
  });
  final int id;
  String title;
  String date;
  int? itemId;
  String kind; // warranty | service
  bool on;
  int everyMonths; // 0 = once

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'itemId': itemId,
        'kind': kind,
        'on': on,
        'everyMonths': everyMonths,
      };
  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as int,
        title: j['title'] as String,
        date: j['date'] as String,
        itemId: j['itemId'] as int?,
        kind: (j['kind'] ?? 'service') as String,
        on: (j['on'] ?? true) as bool,
        everyMonths: (j['everyMonths'] ?? 0) as int,
      );
}

class AppData {
  AppData({
    required this.homeName,
    required this.meId,
    required this.members,
    List<Item>? items,
    List<Claim>? claims,
    List<Reminder>? reminders,
    this.nextId = 1000,
  })  : items = items ?? [],
        claims = claims ?? [],
        reminders = reminders ?? [];

  String homeName;
  String meId;
  List<Member> members;
  List<Item> items;
  List<Claim> claims;
  List<Reminder> reminders;
  int nextId;

  int newId() => nextId++;

  Member? member(String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Item? item(int id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  Claim? claim(int id) {
    for (final c in claims) {
      if (c.id == id) return c;
    }
    return null;
  }

  Reminder? reminder(int id) {
    for (final r in reminders) {
      if (r.id == id) return r;
    }
    return null;
  }

  String get myName => member(meId)?.name ?? 'You';
  String nameOf(String id) => member(id)?.name ?? 'Someone';

  List<String> get rooms {
    final out = <String>[];
    for (final i in items) {
      if (i.room.trim().isNotEmpty && !out.contains(i.room)) out.add(i.room);
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
        'homeName': homeName,
        'meId': meId,
        'members': members.map((e) => e.toJson()).toList(),
        'items': items.map((e) => e.toJson()).toList(),
        'claims': claims.map((e) => e.toJson()).toList(),
        'reminders': reminders.map((e) => e.toJson()).toList(),
        'nextId': nextId,
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    List<T> l<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] ?? []) as List).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    return AppData(
      homeName: (j['homeName'] ?? '') as String,
      meId: j['meId'] as String,
      members: l('members', Member.fromJson),
      items: l('items', Item.fromJson),
      claims: l('claims', Claim.fromJson),
      reminders: l('reminders', Reminder.fromJson),
      nextId: (j['nextId'] ?? 1000) as int,
    );
  }
}

// ---------------- categories ----------------

const categories = <String, String>{
  'kitchen': 'Kitchen',
  'cooling': 'Cooling',
  'laundry': 'Laundry',
  'phone': 'Phones',
  'computer': 'Computers',
  'water': 'Water',
  'audio': 'Audio',
  'tv': 'TV',
  'home': 'Home',
  'other': 'Other',
};

const claimIssues = ['Not working at all', 'Making noise', 'Overheating', 'Leaking', 'Part broken', 'Something else'];

// ---------------- warranty state ----------------

enum Cover { ok, soon, out }

class WarrantyState {
  const WarrantyState(this.cover, this.days, this.warranty);
  final Cover cover;
  final int? days; // days left on [warranty]; null when out of warranty
  final Warranty? warranty; // the next cover to end, or the last one that ended
}

/// Warranties still running on [today], the one ending first first.
List<Warranty> activeWarranties(Item it, String today) {
  final a = it.warranties.where((w) => daysBetween(today, w.until) >= 0).toList()
    ..sort((x, y) => x.until.compareTo(y.until));
  return a;
}

/// Coverage for an item: ok, ending within 30 days, or out of warranty.
WarrantyState warrantyState(Item it, String today) {
  final a = activeWarranties(it, today);
  if (a.isEmpty) {
    Warranty? last;
    for (final w in it.warranties) {
      if (last == null || w.until.compareTo(last.until) > 0) last = w;
    }
    return WarrantyState(Cover.out, null, last);
  }
  final d = daysBetween(today, a.first.until);
  return WarrantyState(d <= 30 ? Cover.soon : Cover.ok, d, a.first);
}

/// Share of the warranty period left, 0..1, for the progress bar.
double coverFraction(Item it, WarrantyState s) {
  final w = s.warranty;
  if (w == null || s.days == null) return 0;
  final total = daysBetween(it.date, w.until);
  if (total <= 0) return 1;
  final f = s.days! / total;
  if (f < 0.04) return 0.04;
  if (f > 1) return 1;
  return f;
}

/// "7 days", "4 mo", "1.5 yr", "9 yr".
String timeLeftLabel(int d) {
  if (d >= 365) {
    final y = (d / 365).toStringAsFixed(d >= 730 ? 0 : 1).replaceAll('.0', '');
    return '$y yr';
  }
  if (d >= 60) return '${(d / 30).round()} mo';
  return d == 1 ? '1 day' : '$d days';
}

/// Short label for a warranty, e.g. "Extended (₹1,999)" -> "Extended".
String shortLabel(String label) {
  final i = label.indexOf(' (');
  return i > 0 ? label.substring(0, i) : label;
}

/// A warranty of [months] bought on [bought] ends the day before the anniversary.
String warrantyEnd(String bought, int months) => addDaysIso(addMonthsIso(bought, months), -1);

// ---------------- vault filters ----------------

/// Filters by category ('all' or a key), status ('all' | 'covered' | 'out') and
/// free-text query, then sorts so the warranty that ends first comes first.
List<Item> filterItems(List<Item> items, {String query = '', String cat = 'all', String show = 'all', required String today}) {
  final q = query.trim().toLowerCase();
  final out = items.where((i) {
    if (cat != 'all' && i.cat != cat) return false;
    final s = warrantyState(i, today);
    if (show == 'covered' && s.cover == Cover.out) return false;
    if (show == 'out' && s.cover != Cover.out) return false;
    if (q.isEmpty) return true;
    final hay = [i.name, i.brand, i.model, i.store, i.serial, i.room, i.inv].join(' ').toLowerCase();
    return hay.contains(q);
  }).toList();
  out.sort((a, b) {
    final da = warrantyState(a, today).days ?? 99999;
    final db = warrantyState(b, today).days ?? 99999;
    return da.compareTo(db);
  });
  return out;
}

int coveredValue(List<Item> items, String today) =>
    items.where((i) => warrantyState(i, today).cover != Cover.out).fold<int>(0, (a, i) => a + i.price);

// ---------------- reminders ----------------

/// Reminders that need attention: switched on and due within [days] days.
/// Overdue service reminders stay on the list until they are marked done.
List<Reminder> alertReminders(List<Reminder> all, String today, {int days = 30}) {
  final out = all.where((r) {
    if (!r.on) return false;
    final d = daysBetween(today, r.date);
    if (d > days) return false;
    if (d < 0) return r.kind == 'service';
    return true;
  }).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return out;
}

String reminderTitleFor(Item it, Warranty w) =>
    w.label.toLowerCase() == 'product' ? '${it.title} warranty ends' : '${it.title}: ${w.label} ends';

/// One reminder per warranty that has not ended yet. Keeps the on/off choice of
/// matching reminders in [previous].
List<Reminder> warrantyReminders(Item it, String today, int Function() newId, {List<Reminder> previous = const []}) {
  final out = <Reminder>[];
  for (final w in it.warranties) {
    if (daysBetween(today, w.until) < 0) continue;
    final title = reminderTitleFor(it, w);
    var on = true;
    for (final p in previous) {
      if (p.itemId == it.id && p.kind == 'warranty' && (p.date == w.until || p.title == title)) on = p.on;
    }
    out.add(Reminder(id: newId(), title: title, date: w.until, itemId: it.id, kind: 'warranty', on: on));
  }
  return out;
}

/// Marks a service reminder done. Repeating ones move to their next date
/// (after today); one-off ones return false and should be removed.
bool completeReminder(Reminder r, String today) {
  if (r.everyMonths <= 0) return false;
  var next = addMonthsIso(r.date, r.everyMonths);
  while (daysBetween(today, next) < 0) {
    next = addMonthsIso(next, r.everyMonths);
  }
  r.date = next;
  return true;
}

// ---------------- claims ----------------

Claim newClaim({required int id, required Item item, required String issue, required String under, required String ref, required String today}) {
  final brand = item.brand.trim().isEmpty ? 'the brand' : item.brand;
  return Claim(
    id: id,
    itemId: item.id,
    issue: issue,
    under: under,
    ref: ref,
    steps: [
      ClaimStep(title: 'Claim raised with $brand', date: today, done: true),
      ClaimStep(title: 'Technician visit', now: true, note: 'Service centre usually calls within 48 hours'),
      ClaimStep(title: 'Repair done'),
    ],
  );
}

/// Completes the current step. When only "Repair done" is left, that is completed too.
void advanceClaim(Claim c, String today) {
  final i = c.steps.indexWhere((s) => s.now);
  if (i < 0) return;
  final s = c.steps[i];
  s.done = true;
  s.now = false;
  s.date ??= today;
  if (i + 1 < c.steps.length) {
    final n = c.steps[i + 1];
    if (i + 1 == c.steps.length - 1) {
      n.done = true;
      n.date = today;
    } else {
      n.now = true;
    }
  }
}

/// Completes the current step and adds a new "in progress" step before "Repair done".
void addClaimStep(Claim c, String title, String note, String today) {
  final i = c.steps.indexWhere((s) => s.now);
  if (i >= 0) {
    c.steps[i].done = true;
    c.steps[i].now = false;
    c.steps[i].date ??= today;
  }
  final at = c.steps.isEmpty ? 0 : c.steps.length - 1;
  c.steps.insert(at, ClaimStep(title: title, date: today, now: true, note: note));
}

/// Marks the whole claim as repaired today.
void closeClaim(Claim c, String today) {
  for (final s in c.steps) {
    if (!s.done) {
      s.done = true;
      s.now = false;
      s.date ??= today;
    }
  }
}

String claimSummary(Item it, String issue, String under, String until) {
  final lines = <String>[
    'Product: ${it.brand} ${it.model.isEmpty ? it.name : it.model}'.trim(),
    if (it.serial.isNotEmpty) 'Serial: ${it.serial}',
    'Invoice: ${it.inv.isEmpty ? 'attached' : it.inv}, ${longDate(it.date)}',
    if (it.store.isNotEmpty) 'Bought from: ${it.store}',
    'Warranty: $under until ${longDate(until)}',
    'Problem: $issue',
  ];
  return lines.join('\n');
}

String escalationText(Item it, Claim c, String today) {
  final days = daysBetween(c.started, today);
  final visit = c.steps.length > 1 && c.steps[1].date != null ? c.steps[1].date! : c.started;
  final s = warrantyState(it, today);
  final until = s.warranty == null ? '' : ' until ${longDate(s.warranty!.until)}';
  final ref = c.ref.trim().isEmpty ? 'Service request' : 'Service request ${c.ref.trim()}';
  return 'Complaint: ${it.brand} ${it.name} (${it.model}), serial ${it.serial}\n'
      'Bought ${longDate(it.date)} from ${it.store}, invoice ${it.inv}, ${inr(it.price)}.\n'
      'Under ${c.under}$until.\n'
      'Problem: ${c.issue}.\n'
      '$ref raised ${longDate(c.started)}. Technician visited ${longDate(visit)}. Still unresolved after $days days.\n'
      'Request: repair within 7 days or replacement.';
}

// ---------------- export ----------------

String _csvCell(String s) => (s.contains(',') || s.contains('"') || s.contains('\n')) ? '"${s.replaceAll('"', '""')}"' : s;

/// A CSV list for a home insurance claim.
String insuranceCsv(AppData d) {
  final rows = <List<String>>[
    ['Item', 'Brand', 'Model', 'Serial', 'Room', 'Owner', 'Bought on', 'Price (Rs)', 'Shop', 'Invoice', 'Warranties'],
    for (final i in d.items)
      [
        i.name,
        i.brand,
        i.model,
        i.serial,
        i.room,
        d.nameOf(i.owner),
        i.date,
        ((i.price + 50) ~/ 100).toString(),
        i.store,
        i.inv,
        i.warranties.map((w) => '${w.label} until ${w.until}').join('; '),
      ],
  ];
  return rows.map((r) => r.map(_csvCell).join(',')).join('\n');
}

/// Plain-text summary of the vault, for sharing.
String vaultSummary(AppData d, String today) {
  final b = StringBuffer('${d.homeName.isEmpty ? 'Home' : d.homeName}: ${d.items.length} items, ${inr(coveredValue(d.items, today))} still under warranty\n');
  for (final i in d.items) {
    final s = warrantyState(i, today);
    final cover = s.cover == Cover.out ? 'out of warranty' : '${shortLabel(s.warranty!.label).toLowerCase()} warranty until ${longDate(s.warranty!.until)}';
    b.writeln('• ${i.title} (${i.model}), ${inr(i.price)}, $cover');
  }
  return b.toString().trim();
}

// ---------------- bill text reader ----------------

/// Fields read from pasted bill or order-email text. Anything not found is null.
class BillDraft {
  String? store;
  String? invoice;
  String? date;
  String? gstin;
  String? brand;
  String? name;
  String? cat;
  String? model;
  String? serial;
  int? price;
  int? warrantyMonths;

  List<String> get found => [
        if (store != null) 'shop',
        if (invoice != null) 'invoice',
        if (date != null) 'date',
        if (brand != null) 'brand',
        if (name != null) 'item',
        if (model != null) 'model',
        if (serial != null) 'serial',
        if (price != null) 'price',
        if (warrantyMonths != null) 'warranty',
      ];
}

const knownBrands = [
  'Eureka Forbes', 'Morphy Richards', 'Blue Star', 'AO Smith', 'V-Guard', 'OnePlus', 'Samsung', 'Philips', 'Prestige',
  'Whirlpool', 'Panasonic', 'Aquaguard', 'Motorola', 'Crompton', 'Butterfly', 'Kenstar', 'Hitachi', 'Carrier', 'Lenovo',
  'Godrej', 'Havells', 'Voltas', 'Daikin', 'Xiaomi', 'Realme', 'Preethi', 'Racold', 'Orient', 'Pigeon', 'Lloyd', 'Bosch',
  'Haier', 'Bajaj', 'Apple', 'Redmi', 'Nokia', 'Kent', 'Usha', 'Vivo', 'Oppo', 'Dell', 'Asus', 'Acer', 'boAt', 'Sony',
  'JBL', 'IFB', 'LG', 'HP',
];

const knownStores = <String, String>{
  'amazon': 'Amazon.in',
  'flipkart': 'Flipkart',
  'croma': 'Croma',
  'reliance digital': 'Reliance Digital',
  'vijay sales': 'Vijay Sales',
  'tata cliq': 'Tata CLiQ',
  'jiomart': 'JioMart',
  'myntra': 'Myntra',
  'poorvika': 'Poorvika',
  'sangeetha': 'Sangeetha Mobiles',
  'bajaj electronics': 'Bajaj Electronics',
};

/// [keyword, item name, category], longest phrases first.
const productWords = [
  ['washing machine', 'Washing machine', 'laundry'],
  ['air conditioner', 'Air conditioner', 'cooling'],
  ['water purifier', 'Water purifier', 'water'],
  ['water heater', 'Water heater', 'home'],
  ['mixer grinder', 'Mixer grinder', 'kitchen'],
  ['refrigerator', 'Refrigerator', 'kitchen'],
  ['air fryer', 'Air fryer', 'kitchen'],
  ['microwave', 'Microwave oven', 'kitchen'],
  ['television', 'Television', 'tv'],
  ['smartphone', 'Smartphone', 'phone'],
  ['earbuds', 'Wireless earbuds', 'audio'],
  ['headphones', 'Headphones', 'audio'],
  ['speaker', 'Speaker', 'audio'],
  ['chimney', 'Kitchen chimney', 'kitchen'],
  ['induction', 'Induction cooktop', 'kitchen'],
  ['purifier', 'Water purifier', 'water'],
  ['kettle', 'Electric kettle', 'kitchen'],
  ['vacuum', 'Vacuum cleaner', 'home'],
  ['geyser', 'Water heater', 'home'],
  ['laptop', 'Laptop', 'computer'],
  ['monitor', 'Monitor', 'computer'],
  ['cooler', 'Air cooler', 'cooling'],
  ['fridge', 'Refrigerator', 'kitchen'],
  ['washer', 'Washing machine', 'laundry'],
  ['mixer', 'Mixer grinder', 'kitchen'],
  ['phone', 'Smartphone', 'phone'],
  ['mobile', 'Smartphone', 'phone'],
  ['oven', 'Oven', 'kitchen'],
  ['iron', 'Iron', 'home'],
  ['fan', 'Fan', 'home'],
  ['tv', 'Television', 'tv'],
];

const _months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];

String? _validDate(int y, int m, int d) {
  if (y < 100) y += 2000;
  if (m < 1 || m > 12 || d < 1 || d > 31 || y < 1990 || y > 2100) return null;
  final dt = DateTime(y, m, d);
  if (dt.month != m || dt.day != d) return null;
  return isoDate(dt);
}

/// Finds the first date in [s]: 26/09/2026, 26-09-26, 2026-09-26, 26 Sep 2026, Sep 26, 2026.
String? findDate(String s) {
  final iso = RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b').firstMatch(s);
  if (iso != null) {
    final v = _validDate(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!));
    if (v != null) return v;
  }
  for (final m in RegExp(r'\b(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4}|\d{2})\b').allMatches(s)) {
    final v = _validDate(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));
    if (v != null) return v;
  }
  final dmy = RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)?[\s\-]+([a-z]{3})[a-z]*\.?[\s,\-]+(\d{4})\b', caseSensitive: false).firstMatch(s);
  if (dmy != null) {
    final mi = _months.indexOf(dmy.group(2)!.toLowerCase());
    if (mi >= 0) {
      final v = _validDate(int.parse(dmy.group(3)!), mi + 1, int.parse(dmy.group(1)!));
      if (v != null) return v;
    }
  }
  final mdy = RegExp(r'\b([a-z]{3})[a-z]*\.?\s+(\d{1,2}),?\s+(\d{4})\b', caseSensitive: false).firstMatch(s);
  if (mdy != null) {
    final mi = _months.indexOf(mdy.group(1)!.toLowerCase());
    if (mi >= 0) {
      final v = _validDate(int.parse(mdy.group(3)!), mi + 1, int.parse(mdy.group(2)!));
      if (v != null) return v;
    }
  }
  return null;
}

final _amountRe = RegExp(r'\d[\d,]*(?:\.\d{1,2})?');

String _titleCase(String s) {
  if (s != s.toUpperCase()) return s;
  return s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

bool _hasWord(String hay, String word) =>
    RegExp('(^|[^a-z0-9])${RegExp.escape(word.toLowerCase())}(\$|[^a-z0-9])').hasMatch(hay.toLowerCase());

/// Reads shop, invoice number, date, item, price, serial and warranty from pasted
/// bill or order-email text using simple rules. The user checks every field.
BillDraft parseBillText(String text) {
  final d = BillDraft();
  final lines = text.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  if (lines.isEmpty) return d;
  final lower = text.toLowerCase();

  // GSTIN
  final g = RegExp(r'\b(\d{2}[A-Z]{5}\d{4}[A-Z][A-Z0-9]Z[A-Z0-9])\b').firstMatch(text.toUpperCase());
  if (g != null) d.gstin = g.group(1);

  // Invoice / order number
  final invRe = RegExp(r'\b(?:invoice|inv|bill|order)\b\s*(?:no\.?|number|num|#|id)?\s*[:#.\-]?\s*([A-Za-z0-9][A-Za-z0-9/\-]*\d[A-Za-z0-9/\-]*)',
      caseSensitive: false);
  for (final l in lines) {
    final m = invRe.firstMatch(l);
    if (m != null) {
      d.invoice = m.group(1);
      break;
    }
  }

  // Serial / IMEI
  final serRe = RegExp(r'\b(?:serial(?:\s*(?:no|number))?\.?|s/n|imei)\s*[:#.\-]?\s*([A-Za-z0-9][A-Za-z0-9\-]{3,})', caseSensitive: false);
  final sm = serRe.firstMatch(text);
  if (sm != null) d.serial = sm.group(1);

  // Date: prefer lines that say "date" or "ordered"
  for (final l in lines) {
    final ll = l.toLowerCase();
    if (ll.contains('date') || ll.contains('ordered') || ll.contains('dated')) {
      final v = findDate(l);
      if (v != null) {
        d.date = v;
        break;
      }
    }
  }
  d.date ??= findDate(text);

  // Total
  int? best;
  for (final l in lines) {
    final ll = l.toLowerCase();
    if (!RegExp(r'total|amount payable|net amount|amount paid|grand').hasMatch(ll)) continue;
    if (ll.contains('sub total') || ll.contains('subtotal')) continue;
    final nums = _amountRe.allMatches(l).map((m) => m.group(0)!).toList();
    if (nums.isEmpty) continue;
    final v = parseRupees(nums.last);
    if (v != null && v >= 100 && (best == null || v > best)) best = v;
  }
  if (best == null) {
    for (final m in RegExp(r'(?:₹|rs\.?|inr)\s*(\d[\d,]*(?:\.\d{1,2})?)', caseSensitive: false).allMatches(text)) {
      final v = parseRupees(m.group(1)!);
      if (v != null && v >= 100 && (best == null || v > best)) best = v;
    }
  }
  d.price = best;

  // Warranty period
  for (final l in lines) {
    final ll = l.toLowerCase();
    if (!ll.contains('warranty') && !ll.contains('guarantee')) continue;
    final m = RegExp(r'(\d+)\s*-?\s*(years?|yrs?|months?|mths?)\b').firstMatch(ll);
    if (m != null) {
      final n = int.parse(m.group(1)!);
      d.warrantyMonths = m.group(2)!.startsWith('y') ? n * 12 : n;
      break;
    }
  }

  // Shop
  bool skipLine(String l) {
    final ll = l.toLowerCase();
    if (RegExp(r'tax invoice|invoice|gstin|receipt|cash memo|bill of supply|order|thank|^date|^dear|^hi\b|^hello|^inv\b|^s/n').hasMatch(ll)) {
      return true;
    }
    return RegExp(r'[a-z]').allMatches(ll).length < 3;
  }

  String? firstLine;
  for (final l in lines.take(4)) {
    if (!skipLine(l)) {
      firstLine = l;
      break;
    }
  }
  String? knownStore;
  var knownKey = '';
  for (final e in knownStores.entries) {
    if (lower.contains(e.key)) {
      knownStore = e.value;
      knownKey = e.key;
      break;
    }
  }
  String? storeLine; // the line the shop name was taken from
  if (knownStore != null) {
    if (firstLine != null && firstLine.toLowerCase().startsWith(knownKey) && firstLine.length <= 40) {
      storeLine = firstLine;
      d.store = _titleCase(firstLine);
    } else {
      d.store = knownStore;
    }
  } else if (firstLine != null && firstLine.length <= 48) {
    storeLine = firstLine;
    d.store = _titleCase(firstLine);
  }

  // Product name and category
  for (final p in productWords) {
    if (_hasWord(lower, p[0])) {
      d.name = p[1];
      d.cat = p[2];
      break;
    }
  }

  // Brand and model (the rest of the line the brand is on)
  for (final b in knownBrands) {
    String? line;
    for (final l in lines) {
      if (_hasWord(l, b) && l != storeLine) {
        line = l;
        break;
      }
    }
    if (line == null) continue;
    d.brand = b;
    var rest = line.replaceFirst(RegExp(r'\s{2,}.*$'), '');
    final at = rest.toLowerCase().indexOf(b.toLowerCase());
    rest = at >= 0 ? rest.substring(at + b.length) : rest;
    rest = rest.replaceFirst(
        RegExp(r'\s+(?:(?:₹|rs\.?|inr)\s*\d[\d,]*(?:\.\d{1,2})?|\d{1,3}(?:,\d{2,3})+(?:\.\d{1,2})?|\d+\.\d{2})\s*$', caseSensitive: false), '');
    for (final p in productWords) {
      rest = rest.replaceAll(RegExp('(^|\\s)${RegExp.escape(p[0])}(?=\\s|\$)', caseSensitive: false), ' ');
    }
    rest = rest.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (rest.startsWith('-') || rest.startsWith(':') || rest.startsWith(',')) rest = rest.substring(1).trim();
    if (rest.isNotEmpty) d.model = rest;
    break;
  }
  return d;
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

/// Adds [n] months, clamping to the last day of the month (31 Jan + 1 = 28 Feb).
String addMonthsIso(String s, int n) {
  final d = parseIso(s);
  final lastDay = DateTime(d.year, d.month + n + 1, 0).day;
  return isoDate(DateTime(d.year, d.month + n, d.day > lastDay ? lastDay : d.day));
}

int daysBetween(String a, String b) {
  final x = parseIso(a), y = parseIso(b);
  return DateTime.utc(y.year, y.month, y.day).difference(DateTime.utc(x.year, x.month, x.day)).inDays;
}

const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String shortDate(String s) {
  final d = parseIso(s);
  return '${d.day} ${_mon[d.month - 1]}';
}

String longDate(String s) {
  final d = parseIso(s);
  return '${d.day} ${_mon[d.month - 1]} ${d.year}';
}

bool isIsoDate(String s) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s);

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

/// Parses user input like "1,250.50" into paise. Returns null if invalid.
int? parseRupees(String text) {
  final v = double.tryParse(text.replaceAll(',', '').replaceAll('₹', '').trim());
  if (v == null || v.isNaN || v.isInfinite) return null;
  return (v * 100).round();
}
