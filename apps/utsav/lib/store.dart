import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart';

/// Holds the app state, saves it on the phone, and exposes actions.
class UtsavStore extends ChangeNotifier {
  static const _key = 'utsav_data_v1';
  AppData? data;
  bool loaded = false;

  /// Which event the Guests tab is showing (not saved).
  String? selectedEvent;

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
    try {
      final prefs = await SharedPreferences.getInstance();
      if (d == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, jsonEncode(d.toJson()));
      }
    } catch (_) {
      // Saving failed; the data stays in memory for this session.
    }
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  /// The event the Guests tab shows: the chosen one, else the next upcoming, else the first.
  WEvent? get currentEvent {
    final d = data;
    if (d == null || d.events.isEmpty) return null;
    final sel = selectedEvent == null ? null : d.event(selectedEvent!);
    if (sel != null) return sel;
    final evs = d.sortedEvents;
    final today = todayIso();
    for (final e in evs) {
      if (e.date.compareTo(today) >= 0) return e;
    }
    return evs.first;
  }

  void selectEvent(String id) {
    selectedEvent = id;
    notifyListeners();
  }

  // ---------- setup ----------
  void createWedding({
    required String myName,
    required String bride,
    required String groom,
    required String city,
    required String weddingDate,
    required List<String> eventNames,
  }) {
    final d = AppData(myName: myName, bride: bride, groom: groom, city: city, weddingDate: weddingDate);
    for (final p in presetEvents) {
      if (!eventNames.contains(p.$1)) continue;
      d.events.add(WEvent(id: 'e${d.newId()}', name: p.$1, date: addDaysIso(weddingDate, p.$2), time: p.$3));
    }
    for (final c in defaultCategories) {
      d.budget.add(BudgetLine(id: d.newId(), cat: c));
    }
    data = d;
    selectedEvent = null;
    _changed();
  }

  void loadSample() {
    data = sampleData();
    selectedEvent = null;
    _changed();
  }

  void resetAll() {
    data = null;
    selectedEvent = null;
    _changed();
  }

  void updateSettings({
    required String myName,
    required String bride,
    required String groom,
    required String city,
    required String weddingDate,
    required String hotelName,
    required int hotelRooms,
    required int perRoom,
    required int bufferPct,
  }) {
    final d = data!;
    d
      ..myName = myName
      ..bride = bride
      ..groom = groom
      ..city = city
      ..weddingDate = weddingDate
      ..hotelName = hotelName
      ..hotelRooms = hotelRooms
      ..perRoom = perRoom < 1 ? 1 : perRoom
      ..bufferPct = bufferPct < 0 ? 0 : bufferPct;
    _changed();
  }

  // ---------- events ----------
  void saveEvent({String? id, required String name, required String date, required String time, required String venue}) {
    final d = data!;
    final e = id == null ? null : d.event(id);
    if (e == null) {
      d.events.add(WEvent(id: 'e${d.newId()}', name: name, date: date, time: time, venue: venue));
    } else {
      e
        ..name = name
        ..date = date
        ..time = time
        ..venue = venue;
    }
    _changed();
  }

  void deleteEvent(String id) {
    final d = data!;
    d.events.removeWhere((e) => e.id == id);
    for (final g in d.guests) {
      g.events.remove(id);
    }
    for (final t in d.tasks) {
      if (t.ev == id) t.ev = '';
    }
    if (selectedEvent == id) selectedEvent = null;
    _changed();
  }

  // ---------- guests ----------
  /// Adds a family when [id] is null, otherwise updates it. Returns the id.
  int saveGuest({
    int? id,
    required String name,
    required String lead,
    required String phone,
    required String side,
    required int people,
    required String status,
    required List<String> events,
    required int jain,
    required String city,
    required String rel,
  }) {
    final d = data!;
    final existing = id == null ? null : d.guest(id);
    final g = existing ?? Guest(id: d.newId(), name: name);
    g
      ..name = name
      ..lead = lead
      ..phone = phone
      ..side = side
      ..people = people < 1 ? 1 : people
      ..status = status
      ..events = status == rsvpNo ? <String>[] : List<String>.of(events)
      ..jain = jain < 0 ? 0 : (jain > g.people ? g.people : jain)
      ..city = city
      ..rel = rel;
    if (status != rsvpYes) g.room = null;
    if (existing == null) d.guests.add(g);
    _changed();
    return g.id;
  }

  void deleteGuest(int id) {
    data!.guests.removeWhere((g) => g.id == id);
    _changed();
  }

  void markReminded(int id) {
    final g = data!.guest(id);
    if (g == null) return;
    g.remindedOn = todayIso();
    _changed();
  }

  /// Re-allots every room from scratch. Returns the plan used.
  RoomPlan allotHotelRooms() {
    final d = data!;
    final plan = allotRooms(d.guests, homeCity: d.city, rooms: d.hotelRooms, perRoom: d.perRoom);
    for (final g in d.guests) {
      g.room = plan.rooms[g.id];
    }
    _changed();
    return plan;
  }

  void clearRooms() {
    for (final g in data!.guests) {
      g.room = null;
    }
    _changed();
  }

  // ---------- tasks ----------
  int saveTask({int? id, required String title, required String who, required String ev, required String due}) {
    final d = data!;
    final t = id == null ? null : d.task(id);
    if (t == null) {
      final n = WTask(id: d.newId(), title: title, who: who, ev: ev, due: due);
      d.tasks.add(n);
      _changed();
      return n.id;
    }
    t
      ..title = title
      ..who = who
      ..ev = ev
      ..due = due;
    _changed();
    return t.id;
  }

  /// Flips done. Returns the new state.
  bool toggleTask(int id) {
    final t = data!.task(id);
    if (t == null) return false;
    t.done = !t.done;
    _changed();
    return t.done;
  }

  void deleteTask(int id) {
    data!.tasks.removeWhere((t) => t.id == id);
    _changed();
  }

  void saveHelper({String? oldName, required String name, required String phone}) {
    final d = data!;
    final h = oldName == null ? null : d.helper(oldName);
    if (h == null) {
      if (d.helper(name) != null) {
        d.helper(name)!.phone = phone;
      } else {
        d.helpers.add(Helper(name: name, phone: phone));
      }
    } else {
      if (oldName != name) {
        for (final t in d.tasks) {
          if (t.who == oldName) t.who = name;
        }
      }
      h
        ..name = name
        ..phone = phone;
    }
    _changed();
  }

  void removeHelper(String name) {
    data!.helpers.removeWhere((h) => h.name == name);
    _changed();
  }

  // ---------- budget ----------
  void saveBudgetLine({int? id, required String cat, required int est, required int com, required int paid}) {
    final d = data!;
    final b = id == null ? null : d.line(id);
    if (b == null) {
      d.budget.add(BudgetLine(id: d.newId(), cat: cat, est: est, com: com, paid: paid));
    } else {
      if (b.cat != cat) {
        for (final v in d.vendors) {
          if (v.cat == b.cat) v.cat = cat;
        }
      }
      b
        ..cat = cat
        ..est = est
        ..com = com
        ..paid = paid;
    }
    _changed();
  }

  void deleteBudgetLine(int id) {
    data!.budget.removeWhere((b) => b.id == id);
    _changed();
  }

  // ---------- vendors ----------
  void saveVendor({
    int? id,
    required String name,
    required String cat,
    required String phone,
    required int total,
    required int paid,
    int? nextAmount,
    String? nextDue,
    required String note,
  }) {
    final d = data!;
    final v = id == null ? null : d.vendor(id);
    final target = v ?? Vendor(id: d.newId(), name: name, cat: cat, total: total);
    target
      ..name = name
      ..cat = cat
      ..phone = phone
      ..total = total
      ..paid = paid > total ? total : paid
      ..nextAmount = nextAmount
      ..nextDue = nextAmount == null ? null : nextDue
      ..note = note;
    if (v == null) d.vendors.add(target);
    _changed();
  }

  void deleteVendor(int id) {
    data!.vendors.removeWhere((v) => v.id == id);
    _changed();
  }

  /// Records a payment to a vendor and adds it to the matching budget line.
  /// Returns what was actually applied (capped at what was left on the contract).
  int recordPayment(int vendorId, int amount, String method) {
    final d = data!;
    final v = d.vendor(vendorId);
    if (v == null) return 0;
    final today = todayIso();
    final r = applyPayment(total: v.total, paid: v.paid, nextAmount: v.nextAmount, nextDue: v.nextDue, amount: amount, today: today);
    if (r.applied <= 0) return 0;
    v
      ..paid = r.paid
      ..nextAmount = r.nextAmount
      ..nextDue = r.nextDue;
    v.payments.insert(0, VendorPayment(amount: r.applied, method: method, date: today));
    final b = d.lineFor(v.cat);
    if (b != null) b.paid += r.applied;
    _changed();
    return r.applied;
  }
}

// ---------------- sample data ----------------

/// Riya and Kabir's wedding in Jaipur, as in the prototype. Dates are relative to today.
AppData sampleData() {
  final t = todayIso();
  final wed = addDaysIso(t, 76);
  String rel(int n) => addDaysIso(t, n);

  final events = [
    WEvent(id: 'mehendi', name: 'Mehendi', date: addDaysIso(wed, -2), time: '16:00', venue: 'Home, Malviya Nagar'),
    WEvent(id: 'haldi', name: 'Haldi', date: addDaysIso(wed, -1), time: '10:00', venue: 'Home, Malviya Nagar'),
    WEvent(id: 'sangeet', name: 'Sangeet', date: addDaysIso(wed, -1), time: '19:00', venue: 'Hotel lawn'),
    WEvent(id: 'wedding', name: 'Wedding', date: wed, time: '19:00', venue: 'Rajmahal Gardens'),
    WEvent(id: 'reception', name: 'Reception', date: addDaysIso(wed, 1), time: '20:00', venue: 'Rajmahal Gardens'),
  ];

  // Same seeded generator as the prototype, so the sample families match it.
  var x = 17;
  double rnd() {
    x = (x * 9301 + 49297) % 233280;
    return x / 233280;
  }

  const surnames = [
    'Sharma', 'Agarwal', 'Mehta', 'Khandelwal', 'Joshi', 'Gupta', 'Saxena', 'Mathur', 'Bansal', 'Singhal', //
    'Kapoor', 'Malhotra', 'Verma', 'Jain', 'Goyal', 'Chauhan', 'Rathore', 'Pareek', 'Tiwari', 'Arora', //
    'Bhatia', 'Dixit', 'Mittal', 'Soni', 'Kulshrestha', 'Sethi', 'Bajaj', 'Nagpal', 'Oberoi', 'Chopra',
  ];
  const brideRel = ['Mama ji', 'Bua ji', 'Chacha ji', 'Mausi ji', 'Family friends', "Papa's office", 'Neighbours', 'College friends'];
  const groomRel = ["Kabir's mama ji", "Kabir's father's office", "Kabir's friends", "Kabir's chacha ji"];
  const firstNames = ['Suresh', 'Anita', 'Rakesh', 'Meena', 'Vinod', 'Kavita', 'Ajay', 'Neha', 'Manoj', 'Pooja'];
  const cities = ['Delhi', 'Indore', 'Mumbai', 'Kota', 'Ahmedabad', 'Lucknow'];
  const locals = ['Sharma', 'Mathur', 'Pareek', 'Khandelwal'];

  final guests = <Guest>[];
  for (var i = 0; i < surnames.length; i++) {
    final s = surnames[i];
    final side = i % 3 == 2 ? 'groom' : 'bride';
    final n = 2 + (rnd() * 4).floor();
    final r = rnd();
    final st = r < .62 ? rsvpYes : (r < .72 ? rsvpNo : rsvpWait);
    var jain = 0;
    if (s == 'Jain' || rnd() < .1) {
      final k = 1 + (rnd() * 2).floor();
      jain = k < n ? k : n;
    }
    final out = !locals.contains(s) && rnd() < .55;
    final evs = <String>[];
    if (st != rsvpNo) {
      for (var j = 0; j < events.length; j++) {
        final keep = j >= 2 || rnd() < .6 || (side == 'bride' && rnd() < .8);
        if (keep) evs.add(events[j].id);
      }
    }
    final phone = '98${(290000000 + i * 3137711).toString().substring(0, 8)}';
    guests.add(Guest(
      id: i + 1,
      name: '$s family',
      lead: '${firstNames[i % 10]} $s',
      phone: phone,
      side: side,
      people: n,
      status: st,
      events: evs,
      jain: jain,
      city: out ? cities[i % 6] : 'Jaipur',
      rel: side == 'groom' ? groomRel[i % 4] : brideRel[i % 8],
    ));
  }

  int l(int lakhTenths) => lakhTenths * 10000 * 100; // tenths of a lakh rupees -> paise
  return AppData(
    myName: 'Anjali',
    bride: 'Riya',
    groom: 'Kabir',
    city: 'Jaipur',
    weddingDate: wed,
    events: events,
    guests: guests,
    helpers: [
      Helper(name: 'Mama ji', phone: '9829012345'),
      Helper(name: 'Papa', phone: '9829054321'),
      Helper(name: 'Bua ji'),
      Helper(name: 'Mummy', phone: '9829067890'),
      Helper(name: "Kabir's cousin Aditya"),
    ],
    tasks: [
      WTask(id: 1, title: 'Book tent and chairs for Mehendi (80 guests)', who: 'Mama ji', ev: 'mehendi', due: rel(17)),
      WTask(id: 2, title: 'Finalise Sangeet song list with DJ', who: 'You', ev: 'sangeet', due: rel(7)),
      WTask(id: 3, title: "Collect Riya's lehenga after final fitting", who: 'Mummy', ev: 'wedding', due: rel(53)),
      WTask(id: 4, title: "Send e-invites to Kabir's side list", who: "Kabir's cousin Aditya", ev: 'wedding', due: rel(3), done: true),
      WTask(id: 5, title: 'Book 20 rooms at Hotel Aravali Inn', who: 'Papa', ev: 'wedding', due: rel(12), done: true),
      WTask(id: 6, title: 'Confirm pandit ji and muhurat timing', who: 'Papa', ev: 'wedding', due: rel(5)),
      WTask(id: 7, title: 'Arrange haldi, flowers and baskets', who: 'Bua ji', ev: 'haldi', due: addDaysIso(wed, -3)),
      WTask(id: 8, title: 'Get quotes from 3 mehendi artists', who: 'You', ev: 'mehendi', due: rel(-2)),
    ],
    budget: [
      BudgetLine(id: 201, cat: 'Venue', est: l(80), com: l(80), paid: l(40)),
      BudgetLine(id: 202, cat: 'Catering', est: l(90), com: l(96), paid: l(30)),
      BudgetLine(id: 203, cat: 'Decor and flowers', est: l(40), com: l(45), paid: l(15)),
      BudgetLine(id: 204, cat: 'Clothing and jewellery', est: l(50), com: l(38), paid: l(38)),
      BudgetLine(id: 205, cat: 'Photography', est: l(25), com: l(24), paid: l(10)),
      BudgetLine(id: 206, cat: 'Music and Sangeet', est: l(15), com: l(12), paid: l(4)),
      BudgetLine(id: 207, cat: 'Rooms and travel', est: l(15), com: 11000000, paid: 5500000),
      BudgetLine(id: 208, cat: 'Gifts and misc', est: l(15), com: l(6), paid: l(6)),
    ],
    vendors: [
      Vendor(id: 301, name: 'Rajmahal Gardens', cat: 'Venue', phone: '01412701234', total: l(80), paid: l(40), nextAmount: l(20), nextDue: rel(34), note: 'Lawn and banquet hall for Wedding and Reception'),
      Vendor(id: 302, name: 'Shree Annapurna Caterers', cat: 'Catering', phone: '9829010001', total: l(96), paid: l(30), nextAmount: l(33), nextDue: rel(48), note: 'Veg and Jain menu, all five functions'),
      Vendor(id: 303, name: 'Genda Phool Decor', cat: 'Decor and flowers', phone: '9783040002', total: l(45), paid: l(15), nextAmount: l(15), nextDue: rel(7)),
      Vendor(id: 304, name: 'Frames by Aakash', cat: 'Photography', phone: '9928460003', total: l(24), paid: l(10), nextAmount: l(7), nextDue: rel(64)),
      Vendor(id: 305, name: 'DJ Harsh', cat: 'Music and Sangeet', phone: '9887020004', total: l(12), paid: l(4), nextAmount: l(8), nextDue: addDaysIso(wed, -1)),
    ],
    hotelName: 'Hotel Aravali Inn',
    hotelRooms: 20,
    perRoom: 3,
    bufferPct: 10,
    nextId: 1000,
  );
}
