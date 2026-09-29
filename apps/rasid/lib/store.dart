import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart';

/// Holds the app state, saves it on the phone, and exposes actions.
class RasidStore extends ChangeNotifier {
  static const _key = 'rasid_data_v1';
  AppData? data;
  bool loaded = false;

  // Screen state that is not saved.
  int tab = 0;
  String vaultQuery = '';
  int searchEpoch = 0; // bumped when the query is set from outside the search box
  String vaultCat = 'all';
  String vaultShow = 'all';

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

  // ---------- navigation ----------
  void goTab(int i) {
    tab = i;
    notifyListeners();
  }

  void setQuery(String q) {
    vaultQuery = q;
    notifyListeners();
  }

  /// Opens the vault searching for [q] (used by room shortcuts).
  void searchVault(String q) {
    vaultQuery = q;
    vaultCat = 'all';
    vaultShow = 'all';
    searchEpoch++;
    tab = 1;
    notifyListeners();
  }

  void setVaultCat(String c) {
    vaultCat = c;
    notifyListeners();
  }

  void setVaultShow(String s) {
    vaultShow = s;
    notifyListeners();
  }

  void _resetScreens() {
    tab = 0;
    vaultQuery = '';
    vaultCat = 'all';
    vaultShow = 'all';
    searchEpoch++;
  }

  // ---------- setup ----------
  void createVault({required String myName, required String homeName, String partner = ''}) {
    data = AppData(
      homeName: homeName,
      meId: 'me',
      members: [
        Member(id: 'me', name: myName),
        if (partner.trim().isNotEmpty) Member(id: 'm1', name: partner.trim()),
      ],
    );
    _resetScreens();
    _changed();
  }

  void loadSample() {
    data = sampleData();
    _resetScreens();
    _changed();
  }

  void resetAll() {
    data = null;
    _resetScreens();
    _changed();
  }

  String exportJson() => data == null ? '' : jsonEncode(data!.toJson());

  /// Replaces all data with a backup. Returns false if the text is not a valid backup.
  bool importJson(String raw) {
    try {
      final d = AppData.fromJson(jsonDecode(raw.trim()) as Map<String, dynamic>);
      if (d.member(d.meId) == null) return false;
      data = d;
      _resetScreens();
      _changed();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------- profile & household ----------
  void updateProfile({required String myName, required String homeName}) {
    final d = data!;
    d.member(d.meId)?.name = myName;
    d.homeName = homeName;
    _changed();
  }

  void addMember(String name) {
    final d = data!;
    d.members.add(Member(id: 'm${d.newId()}', name: name));
    _changed();
  }

  void renameMember(String id, String name) {
    data!.member(id)?.name = name;
    _changed();
  }

  /// Removes a person; their items move to you.
  void removeMember(String id) {
    final d = data!;
    if (id == d.meId) return;
    d.members.removeWhere((m) => m.id == id);
    for (final i in d.items) {
      if (i.owner == id) i.owner = d.meId;
    }
    _changed();
  }

  // ---------- items ----------
  int newId() => data!.newId();

  void addItem(Item it) {
    final d = data!;
    d.items.add(it);
    d.reminders.addAll(warrantyReminders(it, todayIso(), d.newId));
    _changed();
  }

  void updateItem(Item it) {
    final d = data!;
    final k = d.items.indexWhere((x) => x.id == it.id);
    if (k < 0) return;
    d.items[k] = it;
    final old = d.reminders.where((r) => r.itemId == it.id && r.kind == 'warranty').toList();
    d.reminders.removeWhere((r) => r.itemId == it.id && r.kind == 'warranty');
    d.reminders.addAll(warrantyReminders(it, todayIso(), d.newId, previous: old));
    _changed();
  }

  void deleteItem(int id) {
    final d = data!;
    d.items.removeWhere((i) => i.id == id);
    d.reminders.removeWhere((r) => r.itemId == id);
    d.claims.removeWhere((c) => c.itemId == id);
    _changed();
  }

  void addRepair(int itemId, Repair r) {
    final it = data!.item(itemId);
    if (it == null) return;
    it.repairs.insert(0, r);
    _changed();
  }

  // ---------- claims ----------
  Claim raiseClaim({required Item item, required String issue, required String under, required String ref}) {
    final d = data!;
    final c = newClaim(id: d.newId(), item: item, issue: issue, under: under, ref: ref, today: todayIso());
    d.claims.add(c);
    _changed();
    return c;
  }

  void advance(int claimId) {
    final c = data!.claim(claimId);
    if (c == null) return;
    advanceClaim(c, todayIso());
    _changed();
  }

  void addStep(int claimId, String title, String note) {
    final c = data!.claim(claimId);
    if (c == null) return;
    addClaimStep(c, title, note, todayIso());
    _changed();
  }

  void markRepaired(int claimId) {
    final c = data!.claim(claimId);
    if (c == null) return;
    closeClaim(c, todayIso());
    _changed();
  }

  void setClaimRef(int claimId, String ref) {
    final c = data!.claim(claimId);
    if (c == null) return;
    c.ref = ref;
    _changed();
  }

  void deleteClaim(int claimId) {
    data!.claims.removeWhere((c) => c.id == claimId);
    _changed();
  }

  // ---------- reminders ----------
  void toggleReminder(int id, bool on) {
    data!.reminder(id)?.on = on;
    _changed();
  }

  void addReminder({required String title, required String date, int? itemId, int everyMonths = 0}) {
    final d = data!;
    d.reminders.add(Reminder(id: d.newId(), title: title, date: date, itemId: itemId, kind: 'service', everyMonths: everyMonths));
    _changed();
  }

  void updateReminder(int id, {required String title, required String date, int? itemId, required int everyMonths}) {
    final r = data!.reminder(id);
    if (r == null) return;
    r.title = title;
    r.date = date;
    r.itemId = itemId;
    r.everyMonths = everyMonths;
    _changed();
  }

  /// Marks a service reminder done. Returns the next date, or null if it was removed.
  String? doneReminder(int id) {
    final d = data!;
    final r = d.reminder(id);
    if (r == null) return null;
    final keep = completeReminder(r, todayIso());
    if (!keep) d.reminders.remove(r);
    _changed();
    return keep ? r.date : null;
  }

  void deleteReminder(int id) {
    data!.reminders.removeWhere((r) => r.id == id);
    _changed();
  }
}

/// Sample household used for "Explore with sample data". Dates are relative to today.
AppData sampleData() {
  final t = todayIso();
  String on(int n) => addDaysIso(t, n);
  Warranty w(String label, int n) => Warranty(label: label, until: on(n));
  final items = [
    Item(id: 1, name: 'Mixer grinder', brand: 'Prestige', model: 'Iris 750W', serial: 'PIR750-24-118392', cat: 'kitchen', room: 'Kitchen', price: 429900, date: on(-722), store: 'Ratnadeep Homes, Kondapur', inv: 'RH/24-25/08812', warranties: [w('Product', 7)], owner: 'me'),
    Item(id: 2, name: 'Smartphone', brand: 'OnePlus', model: '12R 8/256', serial: 'IMEI 86********4471', cat: 'phone', room: 'Priya', price: 3999900, date: on(-348), store: 'Amazon.in', inv: 'IN-HYD-5521907', warranties: [w('Product', 16)], owner: 'me'),
    Item(id: 3, name: 'Laptop', brand: 'HP', model: 'Pavilion 14-ek2', serial: '5CD4381XKQ', cat: 'computer', room: 'Study', price: 6299000, date: on(-269), store: 'Vijay Sales, Madhapur', inv: 'VS/MDP/260102/77', warranties: [w('Product', 95)], owner: 'arjun'),
    Item(id: 4, name: 'Water purifier', brand: 'Kent', model: 'Grand Plus RO', serial: 'KGP-2511-40219', cat: 'water', room: 'Kitchen', price: 1750000, date: on(-312), store: 'Kent authorised dealer', inv: 'KD/1120/339', warranties: [w('Product', 52), w('AMC (paid)', 417)], owner: 'me'),
    Item(id: 5, name: 'Refrigerator', brand: 'Samsung', model: '253 L Frost Free', serial: '0A2K4ABT700219', cat: 'kitchen', room: 'Kitchen', price: 2749000, date: on(-725), store: 'Reliance Digital, Kukatpally', inv: 'RD/KKP/1003/2291', warranties: [w('Product', -361), w('Extended (₹1,999)', 369), w('Compressor', 2926)], owner: 'me'),
    Item(id: 6, name: 'Split AC 1.5 ton', brand: 'LG', model: 'Dual Inverter 5 star', serial: '503KAXQ0N119', cat: 'cooling', room: 'Bedroom', price: 4199000, date: on(-534), store: 'Croma, Gachibowli', inv: 'CRM/GCB/0412/118', warranties: [w('Product', -170), w('Compressor', 3117)], owner: 'arjun'),
    Item(id: 7, name: 'Washing machine', brand: 'Bosch', model: '7 kg Front Load', serial: 'WAJ2416SIN-338120', cat: 'laundry', room: 'Utility', price: 3399000, date: on(-1055), store: 'Croma, Gachibowli', inv: 'CRM/GCB/1108/044', warranties: [w('Product', -325), w('Motor', 3327)], owner: 'me'),
    Item(id: 8, name: 'Wireless earbuds', brand: 'boAt', model: 'Airdopes 141', serial: 'BT141-A99201', cat: 'audio', room: 'Arjun', price: 179900, date: on(-211), store: 'Flipkart', inv: 'OD4290117', warranties: [w('Product', 153)], owner: 'arjun'),
    Item(id: 9, name: 'Ceiling fans x3', brand: 'Havells', model: 'Stealth Air BLDC', serial: '3 units', cat: 'home', room: 'Living room', price: 897000, date: on(-840), store: 'Local electrician (cash bill)', inv: 'Handwritten #312', warranties: [w('Product', -111)], owner: 'arjun'),
  ];
  final claims = [
    Claim(id: 1, itemId: 7, issue: 'Drum makes a grinding noise during spin', under: 'Motor warranty', ref: 'BSH-SR-2609-55812', steps: [
      ClaimStep(title: 'Claim raised with Bosch', date: on(-8), done: true),
      ClaimStep(title: 'Technician visited', date: on(-6), done: true, note: 'Motor bearing needs replacement'),
      ClaimStep(title: 'Waiting for spare part', date: on(-6), now: true, note: 'Promised within 5 working days'),
      ClaimStep(title: 'Repair done'),
    ]),
  ];
  final reminders = [
    Reminder(id: 11, title: 'Prestige Mixer grinder warranty ends', date: on(7), itemId: 1, kind: 'warranty'),
    Reminder(id: 12, title: 'OnePlus Smartphone warranty ends', date: on(16), itemId: 2, kind: 'warranty'),
    Reminder(id: 13, title: 'Change RO filter', date: on(53), itemId: 4, kind: 'service', everyMonths: 6),
    Reminder(id: 14, title: 'Kent Water purifier warranty ends', date: on(52), itemId: 4, kind: 'warranty'),
    Reminder(id: 15, title: 'Kent Water purifier: AMC (paid) ends', date: on(417), itemId: 4, kind: 'warranty'),
    Reminder(id: 16, title: 'Service ACs before summer', date: on(140), itemId: 6, kind: 'service', everyMonths: 12),
    Reminder(id: 17, title: 'Samsung Refrigerator: Extended (₹1,999) ends', date: on(369), itemId: 5, kind: 'warranty'),
    Reminder(id: 18, title: 'HP Laptop warranty ends', date: on(95), itemId: 3, kind: 'warranty'),
    Reminder(id: 19, title: 'boAt Wireless earbuds warranty ends', date: on(153), itemId: 8, kind: 'warranty'),
  ];
  return AppData(
    homeName: 'Flat 204, Kondapur',
    meId: 'me',
    members: [Member(id: 'me', name: 'Priya'), Member(id: 'arjun', name: 'Arjun')],
    items: items,
    claims: claims,
    reminders: reminders,
    nextId: 100,
  );
}
