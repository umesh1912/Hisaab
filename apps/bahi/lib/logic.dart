// Core data model and pure logic for Bahi, the udhaar (credit) register.
// All money is stored as integer paise (₹1 = 100 paise). No Flutter imports here.

class Shop {
  Shop({required this.name, this.nameHi = '', this.owner = '', this.upi = ''});
  String name;
  String nameHi;
  String owner;
  String upi;

  /// Shop name in the chosen language, falling back to the English name.
  String display(bool en) => en || nameHi.trim().isEmpty ? name : nameHi;

  Map<String, dynamic> toJson() => {'name': name, 'nameHi': nameHi, 'owner': owner, 'upi': upi};
  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
        name: (j['name'] ?? '') as String,
        nameHi: (j['nameHi'] ?? '') as String,
        owner: (j['owner'] ?? '') as String,
        upi: (j['upi'] ?? '') as String,
      );
}

/// One line in a customer's khata. kind is 'credit' (goods given on udhaar) or 'pay' (money received).
class Entry {
  Entry({required this.id, required this.date, required this.kind, required this.amount, this.note = ''});
  final int id;
  String date; // yyyy-MM-dd
  String kind;
  int amount; // paise, always positive
  String note;

  bool get isCredit => kind == 'credit';

  Map<String, dynamic> toJson() => {'id': id, 'date': date, 'kind': kind, 'amount': amount, 'note': note};
  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: j['id'] as int,
        date: j['date'] as String,
        kind: j['kind'] as String,
        amount: j['amount'] as int,
        note: (j['note'] ?? '') as String,
      );
}

class Customer {
  Customer({
    required this.id,
    required this.name,
    this.hi = '',
    this.phone = '',
    List<Entry>? entries,
    this.promise,
    this.reminded,
  }) : entries = entries ?? [];
  final int id;
  String name; // Latin script, used in English and for search
  String hi; // Devanagari name, optional
  String phone;
  List<Entry> entries; // kept sorted oldest first
  String? promise; // date the customer promised to pay by
  String? reminded; // date of the last WhatsApp reminder

  String display(bool en) => en || hi.trim().isEmpty ? name : hi;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hi': hi,
        'phone': phone,
        'entries': entries.map((e) => e.toJson()).toList(),
        'promise': promise,
        'reminded': reminded,
      };
  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'] as int,
        name: j['name'] as String,
        hi: (j['hi'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        entries: ((j['entries'] ?? []) as List).map((e) => Entry.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        promise: j['promise'] as String?,
        reminded: j['reminded'] as String?,
      );
}

/// Cash and UPI counter sales for one day, entered by the shopkeeper.
class DaySales {
  DaySales({this.cash = 0, this.upi = 0});
  int cash;
  int upi;
  int get total => cash + upi;

  Map<String, dynamic> toJson() => {'cash': cash, 'upi': upi};
  factory DaySales.fromJson(Map<String, dynamic> j) => DaySales(cash: (j['cash'] ?? 0) as int, upi: (j['upi'] ?? 0) as int);
}

class AppData {
  AppData({
    required this.shop,
    this.lang = 'hi',
    List<Customer>? customers,
    Map<String, DaySales>? sales,
    this.nextId = 1000,
  })  : customers = customers ?? [],
        sales = sales ?? {};

  Shop shop;
  String lang; // 'hi' or 'en'
  List<Customer> customers;
  Map<String, DaySales> sales; // keyed by yyyy-MM-dd
  int nextId;

  bool get en => lang == 'en';
  int newId() => nextId++;

  Customer? customer(int id) {
    for (final c in customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'shop': shop.toJson(),
        'lang': lang,
        'customers': customers.map((c) => c.toJson()).toList(),
        'sales': sales.map((k, v) => MapEntry(k, v.toJson())),
        'nextId': nextId,
      };

  factory AppData.fromJson(Map<String, dynamic> j) => AppData(
        shop: Shop.fromJson(Map<String, dynamic>.from(j['shop'] as Map)),
        lang: (j['lang'] ?? 'hi') as String,
        customers: ((j['customers'] ?? []) as List).map((e) => Customer.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        sales: ((j['sales'] ?? {}) as Map).map((k, v) => MapEntry(k as String, DaySales.fromJson(Map<String, dynamic>.from(v as Map)))),
        nextId: (j['nextId'] ?? 1000) as int,
      );
}

// ---------------- balances ----------------

/// Positive = the customer owes the shop; negative = the customer has paid in advance.
int balanceOf(Customer c) => c.entries.fold<int>(0, (a, e) => a + (e.isCredit ? e.amount : -e.amount));

/// Sorts entries oldest first (by date, then by id so same-day entries keep their order).
void sortEntries(Customer c) {
  c.entries.sort((a, b) {
    final d = a.date.compareTo(b.date);
    return d != 0 ? d : a.id.compareTo(b.id);
  });
}

/// Running balance after each entry, in the same order as [Customer.entries].
List<int> runningBalances(Customer c) {
  var run = 0;
  return [
    for (final e in c.entries) run += e.isCredit ? e.amount : -e.amount,
  ];
}

String? lastPayDate(Customer c) {
  String? out;
  for (final e in c.entries) {
    if (!e.isCredit && (out == null || e.date.compareTo(out) >= 0)) out = e.date;
  }
  return out;
}

/// Age in days of the oldest rupee still owed: walk credits newest to oldest until they cover the balance.
int oldestUnpaidDays(Customer c, String today) {
  final b = balanceOf(c);
  if (b <= 0) return 0;
  var run = 0;
  final credits = c.entries.where((e) => e.isCredit).toList().reversed;
  for (final e in credits) {
    run += e.amount;
    if (run >= b) return daysBetween(e.date, today);
  }
  return c.entries.isEmpty ? 0 : daysBetween(c.entries.first.date, today);
}

/// Collection priority: balance × (1 + days unpaid / 10), kept in integers (scaled by 10).
int priorityOf(Customer c, String today) => balanceOf(c) * (10 + oldestUnpaidDays(c, today));

bool isOverdue(Customer c, String today) => balanceOf(c) > 0 && oldestUnpaidDays(c, today) > 14;

/// True while the customer's promised date has not passed yet.
bool promiseActive(Customer c, String today) => c.promise != null && c.promise!.compareTo(today) >= 0;

/// Customers who owe money and have no active promise, most urgent first.
List<Customer> collectList(List<Customer> all, String today) {
  final out = all.where((c) => balanceOf(c) > 0 && !promiseActive(c, today)).toList();
  out.sort((a, b) => priorityOf(b, today).compareTo(priorityOf(a, today)));
  return out;
}

/// Customers who owe money but promised to pay on a date that hasn't come yet, soonest first.
List<Customer> promisedList(List<Customer> all, String today) {
  final out = all.where((c) => balanceOf(c) > 0 && promiseActive(c, today)).toList();
  out.sort((a, b) => a.promise!.compareTo(b.promise!));
  return out;
}

int totalToCollect(List<Customer> all) => all.fold<int>(0, (a, c) {
      final b = balanceOf(c);
      return a + (b > 0 ? b : 0);
    });

List<Customer> byBalance(List<Customer> all) {
  final out = [...all];
  out.sort((a, b) {
    final d = balanceOf(b).compareTo(balanceOf(a));
    return d != 0 ? d : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return out;
}

class DayEntry {
  const DayEntry(this.customer, this.entry);
  final Customer customer;
  final Entry entry;
}

List<DayEntry> entriesOn(List<Customer> all, String date) {
  final out = <DayEntry>[
    for (final c in all)
      for (final e in c.entries)
        if (e.date == date) DayEntry(c, e),
  ];
  out.sort((a, b) => b.entry.id.compareTo(a.entry.id));
  return out;
}

int creditOn(List<Customer> all, String date) =>
    entriesOn(all, date).where((d) => d.entry.isCredit).fold<int>(0, (a, d) => a + d.entry.amount);
int collectedOn(List<Customer> all, String date) =>
    entriesOn(all, date).where((d) => !d.entry.isCredit).fold<int>(0, (a, d) => a + d.entry.amount);

/// Customer matches the search text in either script.
bool matchesSearch(Customer c, String q) {
  final t = q.trim();
  if (t.isEmpty) return true;
  final n = normalize(t);
  return normalize(c.name).contains(n) || normalize(c.hi).contains(n) || c.phone.replaceAll(' ', '').contains(t.replaceAll(' ', ''));
}

// ---------------- reminders ----------------

/// Reminders should go at most once every 3 days per customer.
bool remindedRecently(Customer c, String today) => c.reminded != null && daysBetween(c.reminded!, today) < 3;

/// No reminders after 9 PM or before 9 AM.
bool quietHours(DateTime now) => now.hour >= 21 || now.hour < 9;

String firstWord(String s) {
  final parts = s.trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? '' : parts.first;
}

/// The polite reminder, in the app's language.
String reminderText(Shop shop, Customer c, bool en) {
  final b = inr(balanceOf(c));
  final upi = shop.upi.trim();
  if (en) {
    return [
      'Namaste ${firstWord(c.name)} ji,',
      'Your balance at ${shop.display(true)} is $b.',
      if (upi.isNotEmpty) 'Pay by UPI: $upi',
      'Thank you 🙏',
    ].join('\n');
  }
  return [
    'नमस्ते ${firstWord(c.display(false))} जी,',
    '${shop.display(false)} पर आपका $b बाकी है।',
    if (upi.isNotEmpty) 'UPI से भुगतान करें: $upi',
    'धन्यवाद 🙏',
  ].join('\n');
}

/// A plain-text statement with every entry and the running balance.
String statementText(Shop shop, Customer c, bool en) {
  final runs = runningBalances(c);
  final lines = <String>[
    '${shop.display(en)} · ${c.display(en)}',
    en ? 'Khata statement' : 'खाता हिसाब',
    '',
  ];
  for (var i = 0; i < c.entries.length; i++) {
    final e = c.entries[i];
    final kind = e.isCredit ? (en ? 'Credit' : 'उधार') : (en ? 'Paid' : 'जमा');
    final note = e.note.isEmpty ? '' : ' (${e.note})';
    lines.add('${dateLabel(e.date, en)}: $kind ${inr(e.amount)}$note → ${inr(runs[i])}');
  }
  lines.add('');
  final b = balanceOf(c);
  if (b > 0) {
    lines.add(en ? 'Balance due: ${inr(b)}' : 'कुल बाकी: ${inr(b)}');
    if (shop.upi.trim().isNotEmpty) lines.add(en ? 'Pay by UPI: ${shop.upi.trim()}' : 'UPI से भुगतान: ${shop.upi.trim()}');
  } else if (b < 0) {
    lines.add(en ? 'Advance with shop: ${inr(-b)}' : 'एडवांस जमा: ${inr(-b)}');
  } else {
    lines.add(en ? 'All settled. Thank you!' : 'हिसाब साफ़। धन्यवाद!');
  }
  return lines.join('\n');
}

/// Digits of an Indian mobile number with the 91 country code, or '' if it doesn't look valid.
String phoneForWhatsApp(String phone) {
  final d = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.length == 10) return '91$d';
  if (d.length == 11 && d.startsWith('0')) return '91${d.substring(1)}';
  if (d.length == 12 && d.startsWith('91')) return d;
  return '';
}

/// WhatsApp click-to-chat link. Without a valid number WhatsApp asks which chat to use.
String whatsAppLink(String phone, String text) {
  final p = phoneForWhatsApp(phone);
  return 'https://wa.me/$p?text=${Uri.encodeComponent(text)}';
}

String telLink(String phone) => 'tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}';

// ---------------- understanding a typed or spoken entry ----------------

const creditItems = ['Doodh', 'Bread', 'Atta', 'Chawal', 'Cheeni', 'Tel', 'Sabzi', 'Rashan'];
const payItems = ['Cash', 'UPI'];

const _itemWords = {
  'doodh': 'Doodh', 'dudh': 'Doodh', 'दूध': 'Doodh',
  'bread': 'Bread', 'ब्रेड': 'Bread',
  'atta': 'Atta', 'aata': 'Atta', 'आटा': 'Atta',
  'cheeni': 'Cheeni', 'chini': 'Cheeni', 'चीनी': 'Cheeni',
  'tel': 'Tel', 'तेल': 'Tel',
  'chawal': 'Chawal', 'chaawal': 'Chawal', 'चावल': 'Chawal',
  'sabzi': 'Sabzi', 'sabji': 'Sabzi', 'सब्ज़ी': 'Sabzi', 'सब्जी': 'Sabzi',
  'rashan': 'Rashan', 'ration': 'Rashan', 'राशन': 'Rashan',
  'upi': 'UPI', 'cash': 'Cash', 'नकद': 'Cash',
};

const _payWords = {
  'jama', 'mila', 'mile', 'paid', 'received', 'chukaya', 'diye', 'dia',
  'जमा', 'मिला', 'मिले', 'दिए', 'दिये', 'चुकाए', 'चुकाया', 'भुगतान',
};
const _creditWords = {'udhaar', 'udhar', 'udhari', 'baki', 'baaki', 'उधार', 'बाकी', 'बाक़ी'};

const _units = {
  'ek': 1, 'एक': 1, 'do': 2, 'दो': 2, 'teen': 3, 'तीन': 3, 'char': 4, 'chaar': 4, 'चार': 4,
  'paanch': 5, 'panch': 5, 'पाँच': 5, 'पांच': 5, 'chhe': 6, 'chhah': 6, 'छह': 6, 'छः': 6, 'छे': 6,
  'saat': 7, 'सात': 7, 'aath': 8, 'आठ': 8, 'nau': 9, 'नौ': 9, 'das': 10, 'दस': 10,
  'gyarah': 11, 'ग्यारह': 11, 'barah': 12, 'baarah': 12, 'बारह': 12, 'terah': 13, 'तेरह': 13,
  'chaudah': 14, 'चौदह': 14, 'pandrah': 15, 'पंद्रह': 15, 'solah': 16, 'सोलह': 16,
  'satrah': 17, 'सत्रह': 17, 'atharah': 18, 'अठारह': 18, 'unnis': 19, 'उन्नीस': 19,
  'bees': 20, 'बीस': 20, 'pachchis': 25, 'पच्चीस': 25, 'tees': 30, 'तीस': 30,
  'chalis': 40, 'chaalis': 40, 'चालीस': 40, 'pachas': 50, 'pachaas': 50, 'पचास': 50,
  'saath': 60, 'साठ': 60, 'sattar': 70, 'सत्तर': 70, 'assi': 80, 'अस्सी': 80, 'nabbe': 90, 'नब्बे': 90,
};
const _fractions = {'dedh': 1.5, 'डेढ़': 1.5, 'dhai': 2.5, 'dhaai': 2.5, 'ढाई': 2.5};
const _modifiers = {'sadhe': 0.5, 'saadhe': 0.5, 'साढ़े': 0.5, 'sava': 0.25, 'savaa': 0.25, 'सवा': 0.25};
const _multipliers = {'sau': 100, 'सौ': 100, 'hazaar': 1000, 'hazar': 1000, 'hajar': 1000, 'हज़ार': 1000, 'lakh': 100000, 'लाख': 100000};

Map<String, V> _norm<V>(Map<String, V> m) => {for (final e in m.entries) normalize(e.key): e.value};
final _unitsN = _norm(_units);
final _fractionsN = _norm(_fractions);
final _modifiersN = _norm(_modifiers);
final _multipliersN = _norm(_multipliers);
final _itemsN = _norm(_itemWords);
final _payN = _payWords.map(normalize).toSet();
final _creditN = _creditWords.map(normalize).toSet();

/// Lowercases, turns Devanagari digits into 0-9 and removes nukta / chandrabindu differences,
/// so "हज़ार" and "हजार", or "पाँच" and "पांच", compare equal.
String normalize(String s) {
  const nukta = {
    0x0958: 0x0915, 0x0959: 0x0916, 0x095A: 0x0917, 0x095B: 0x091C,
    0x095C: 0x0921, 0x095D: 0x0922, 0x095E: 0x092B, 0x095F: 0x092F,
  };
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    if (r == 0x093C) continue; // combining nukta
    if (r >= 0x0966 && r <= 0x096F) {
      b.write(r - 0x0966);
    } else if (r == 0x0901) {
      b.writeCharCode(0x0902); // chandrabindu → anusvara
    } else {
      b.writeCharCode(nukta[r] ?? r);
    }
  }
  return b.toString();
}

List<String> _tokens(String normalized) =>
    normalized.split(RegExp(r'[\s,.!?;:()"“”।/\-₹]+')).where((t) => t.isNotEmpty).toList();

/// Every amount (in rupees) found in the text, from digits or from Hindi / Hinglish number words.
List<double> amountsIn(String text) {
  final t = normalize(text);
  final out = <double>[];
  for (final m in RegExp(r'\d[\d,]*(\.\d+)?').allMatches(t)) {
    final v = double.tryParse(m.group(0)!.replaceAll(',', ''));
    if (v != null) out.add(v);
  }
  final words = _tokens(t.replaceAll(RegExp(r'\d[\d,]*(\.\d+)?'), ' '));
  double total = 0, current = 0, mod = 0;
  var inRun = false;
  void flush() {
    if (inRun) {
      final v = total + current + (current > 0 ? mod : 0);
      if (v > 0) out.add(v);
    }
    total = 0;
    current = 0;
    mod = 0;
    inRun = false;
  }

  for (final w in words) {
    final unit = _unitsN[w];
    final frac = _fractionsN[w];
    final m = _modifiersN[w];
    final mult = _multipliersN[w];
    if (unit != null) {
      current += unit;
      inRun = true;
    } else if (frac != null) {
      current += frac;
      inRun = true;
    } else if (m != null) {
      mod = m;
      inRun = true;
    } else if (mult != null) {
      final double base = (current == 0 ? 1.0 : current) + mod;
      mod = 0;
      if (mult == 100) {
        current = base * 100;
      } else {
        total += base * mult;
        current = 0;
      }
      inRun = true;
    } else {
      flush();
    }
  }
  flush();
  return out;
}

class ParsedEntry {
  const ParsedEntry({required this.matches, required this.amount, required this.kind, required this.note});
  final List<Customer> matches; // best-scoring customers; more than one means "which one?"
  final int amount; // paise, 0 if none found
  final String kind; // credit | pay
  final String note;
}

/// Reads entries like "रमेश 340 उधार दूध", "Salim 200 jama" or "मोहन के साढ़े तीन सौ".
/// Credit is the default when the text doesn't say money was received.
ParsedEntry? parseEntry(String text, List<Customer> customers) {
  final raw = text.trim();
  if (raw.isEmpty) return null;
  final t = normalize(raw);
  final tokens = _tokens(t);

  final amounts = amountsIn(raw);
  var best = 0.0;
  for (final a in amounts) {
    if (a > best) best = a;
  }

  var top = 0;
  var matches = <Customer>[];
  for (final c in customers) {
    final en = normalize(c.name.trim());
    final hi = normalize(c.hi.trim());
    final enTok = _tokens(en);
    final hiTok = _tokens(hi);
    final firstEn = enTok.isEmpty ? '' : enTok.first;
    final firstHi = hiTok.isEmpty ? '' : hiTok.first;
    var s = 0;
    if ((en.length > 2 && t.contains(en)) || (hi.length > 1 && t.contains(hi))) {
      s = 3;
    } else if ((firstEn.isNotEmpty && tokens.contains(firstEn)) || (firstHi.isNotEmpty && tokens.contains(firstHi))) {
      s = 2;
    } else if (firstEn.length >= 4 && tokens.any((w) => w.startsWith(firstEn))) {
      s = 1;
    }
    if (s == 0) continue;
    if (s > top) {
      top = s;
      matches = [c];
    } else if (s == top) {
      matches.add(c);
    }
  }

  final isPay = tokens.any(_payN.contains) && !tokens.any(_creditN.contains);
  final kind = isPay ? 'pay' : 'credit';
  final items = <String>[];
  for (final w in tokens) {
    final item = _itemsN[w];
    if (item != null && !items.contains(item)) items.add(item);
  }
  final note = items.isNotEmpty ? items.join(', ') : (isPay ? 'Cash' : '');
  return ParsedEntry(matches: matches, amount: (best * 100).round(), kind: kind, note: note);
}

// ---------------- dates ----------------

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseIso(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

DateTime _utc(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

String todayIso() => isoDate(DateTime.now());
String addDaysIso(String s, int n) => isoDate(_utc(s).add(Duration(days: n)));

/// Whole days from [a] to [b] (positive when b is later).
int daysBetween(String a, String b) => _utc(b).difference(_utc(a)).inDays;

const _monEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monHi = ['जन', 'फ़र', 'मार्च', 'अप्रै', 'मई', 'जून', 'जुला', 'अग', 'सित', 'अक्टू', 'नव', 'दिस'];
const _dowEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _dowHi = ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'];

String dateLabel(String iso, bool en) {
  final d = parseIso(iso);
  return '${d.day} ${(en ? _monEn : _monHi)[d.month - 1]}';
}

String dayShort(String iso, bool en) => (en ? _dowEn : _dowHi)[parseIso(iso).weekday - 1];

/// "today", "yesterday", "3 days ago" or a date.
String relativeDay(String iso, String today, bool en) {
  final n = daysBetween(iso, today);
  if (n == 0) return en ? 'today' : 'आज';
  if (n == 1) return en ? 'yesterday' : 'कल';
  if (n > 1 && n < 7) return en ? '$n days ago' : '$n दिन पहले';
  return dateLabel(iso, en);
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

/// Parses user input like "1,250.50" into paise. Returns null if invalid or negative.
int? parseRupees(String text) {
  final t = text.replaceAll(',', '').replaceAll('₹', '').trim();
  if (t.isEmpty) return null;
  final v = double.tryParse(t);
  if (v == null || v.isNaN || v.isInfinite || v < 0) return null;
  return (v * 100).round();
}

/// Rupee text for a text field ("1250" or "1250.5").
String rupeesField(int paise) => paise % 100 == 0 ? '${paise ~/ 100}' : (paise / 100).toStringAsFixed(2);
