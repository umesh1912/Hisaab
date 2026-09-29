import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart';

/// Holds the register, saves it on the phone, and exposes actions.
class BahiStore extends ChangeNotifier {
  static const _key = 'bahi_data_v1';
  AppData? data;
  bool loaded = false;

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

  bool get en => data?.en ?? false;

  // ---------- setup ----------
  void createShop({required String name, required String owner, required String upi, required String lang}) {
    data = AppData(shop: Shop(name: name, owner: owner, upi: upi), lang: lang);
    _changed();
  }

  void loadSample({String lang = 'hi'}) {
    data = sampleData()..lang = lang;
    _changed();
  }

  void resetAll() {
    data = null;
    _changed();
  }

  /// Replaces everything with a backup. Returns false if the text isn't a Bahi backup.
  bool restore(String text) {
    try {
      final d = AppData.fromJson(jsonDecode(text.trim()) as Map<String, dynamic>);
      for (final c in d.customers) {
        sortEntries(c);
      }
      data = d;
      _changed();
      return true;
    } catch (_) {
      return false;
    }
  }

  String backupText() => jsonEncode(data?.toJson() ?? {});

  void setLang(String lang) {
    data!.lang = lang;
    _changed();
  }

  void updateShop({required String name, required String nameHi, required String owner, required String upi}) {
    final s = data!.shop;
    s.name = name;
    s.nameHi = nameHi;
    s.owner = owner;
    s.upi = upi;
    _changed();
  }

  // ---------- customers ----------
  int addCustomer({required String name, String hi = '', String phone = ''}) {
    final d = data!;
    final c = Customer(id: d.newId(), name: name, hi: hi, phone: phone);
    d.customers.add(c);
    _changed();
    return c.id;
  }

  void updateCustomer(int id, {required String name, required String hi, required String phone}) {
    final c = data!.customer(id);
    if (c == null) return;
    c.name = name;
    c.hi = hi;
    c.phone = phone;
    _changed();
  }

  void deleteCustomer(int id) {
    data!.customers.removeWhere((c) => c.id == id);
    _changed();
  }

  void setPromise(int id, String? date) {
    final c = data!.customer(id);
    if (c == null) return;
    c.promise = date;
    _changed();
  }

  void markReminded(int id) {
    final c = data!.customer(id);
    if (c == null) return;
    c.reminded = todayIso();
    _changed();
  }

  // ---------- entries ----------
  /// Adds an entry and returns the customer's new balance. A payment clears any promise.
  int addEntry({required int customerId, required String kind, required int amount, String note = '', String? date}) {
    final d = data!;
    final c = d.customer(customerId);
    if (c == null) return 0;
    c.entries.add(Entry(id: d.newId(), date: date ?? todayIso(), kind: kind, amount: amount, note: note));
    sortEntries(c);
    if (kind == 'pay') c.promise = null;
    _changed();
    return balanceOf(c);
  }

  int updateEntry({required int customerId, required int entryId, required String kind, required int amount, required String note, required String date}) {
    final c = data!.customer(customerId);
    if (c == null) return 0;
    for (final e in c.entries) {
      if (e.id == entryId) {
        e.kind = kind;
        e.amount = amount;
        e.note = note;
        e.date = date;
      }
    }
    sortEntries(c);
    _changed();
    return balanceOf(c);
  }

  void deleteEntry(int customerId, int entryId) {
    final c = data!.customer(customerId);
    if (c == null) return;
    c.entries.removeWhere((e) => e.id == entryId);
    _changed();
  }

  // ---------- counter sales ----------
  void setSales(String date, {required int cash, required int upi}) {
    data!.sales[date] = DaySales(cash: cash, upi: upi);
    _changed();
  }
}

/// Gupta General Store, Indore: the prototype's sample register. Dates are relative to today.
AppData sampleData() {
  final t = todayIso();
  String ago(int n) => addDaysIso(t, -n);
  var nextEntry = 1;
  Entry cr(int daysAgo, int rupees, String note) => Entry(id: nextEntry++, date: ago(daysAgo), kind: 'credit', amount: rupees * 100, note: note);
  Entry pay(int daysAgo, int rupees, String note) => Entry(id: nextEntry++, date: ago(daysAgo), kind: 'pay', amount: rupees * 100, note: note);

  final customers = [
    Customer(id: 1, name: 'Ramesh Yadav', hi: 'रमेश यादव', phone: '98260 11223', entries: [
      cr(26, 1200, 'Atta 10 kg, tel'),
      pay(18, 800, 'UPI'),
      pay(12, 400, 'Cash'),
      cr(8, 1240, 'Rashan'),
      cr(2, 600, 'Doodh, Bread'),
    ]),
    Customer(id: 2, name: 'Mohan Chai Wala', hi: 'मोहन चाय वाला', phone: '98930 44512', entries: [
      cr(29, 900, 'Cheeni 10 kg'),
      pay(21, 500, 'Cash'),
      cr(16, 1150, 'Chai patti, cheeni'),
      cr(6, 900, 'Doodh 30 L'),
    ]),
    Customer(id: 3, name: 'Anita Didi', hi: 'अनीता दीदी', phone: '97540 88120', entries: [
      cr(33, 720, 'Rashan'),
      pay(30, 300, 'Cash'),
      cr(23, 700, 'Chawal 10 kg'),
    ]),
    Customer(id: 4, name: 'Salim Bhai', hi: 'सलीम भाई', phone: '99260 33019', promise: addDaysIso(t, 4), entries: [
      cr(16, 450, 'Tel, masale'),
      pay(9, 300, 'UPI'),
      cr(4, 825, 'Rashan'),
    ]),
    Customer(id: 5, name: 'Sunita (Flat 12)', hi: 'सुनीता (फ़्लैट 12)', phone: '90390 55771', entries: [
      cr(10, 400, 'Doodh'),
      pay(3, 400, 'UPI'),
      cr(0, 620, 'Sabzi, Doodh'),
    ]),
    Customer(id: 6, name: 'Pinky Beauty Parlour', hi: 'पिंकी ब्यूटी पार्लर', phone: '98270 90114', entries: [
      cr(0, 310, 'Detergent, sabun'),
    ]),
    Customer(id: 7, name: 'Verma ji', hi: 'वर्मा जी', phone: '94250 12788', entries: [
      cr(14, 540, 'Rashan'),
      pay(7, 540, 'Cash'),
    ]),
    Customer(id: 8, name: 'Kapoor ji', hi: 'कपूर जी', phone: '98261 70045', entries: [
      pay(8, 500, 'Advance'),
    ]),
  ];
  for (final c in customers) {
    sortEntries(c);
  }

  // Last 7 days of counter sales, oldest first: [cash, upi] in rupees.
  const week = [
    [6120, 3890],
    [7450, 4210],
    [5980, 4020],
    [8810, 5530],
    [9240, 6010],
    [7120, 4480],
    [8430, 5210],
  ];
  final sales = <String, DaySales>{
    for (var i = 0; i < week.length; i++) ago(6 - i): DaySales(cash: week[i][0] * 100, upi: week[i][1] * 100),
  };

  return AppData(
    shop: Shop(name: 'Gupta General Store, Indore', nameHi: 'गुप्ता जनरल स्टोर, इंदौर', owner: 'Rakesh Gupta', upi: 'guptastore@okaxis'),
    lang: 'hi',
    customers: customers,
    sales: sales,
    nextId: 1000,
  );
}
