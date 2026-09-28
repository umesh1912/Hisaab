import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart';

/// Holds the app state, saves it on the phone, and exposes actions.
class HisaabStore extends ChangeNotifier {
  static const _key = 'hisaab_data_v1';
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

  void _log(String text) => data!.activity.insert(0, Activity(text, todayIso()));

  // ---------- setup ----------
  void createFlat({required String flatName, required String myName, required String myUpi, required List<Member> flatmates}) {
    final me = Member(id: 'me', name: myName, upi: myUpi);
    data = AppData(flatName: flatName, meId: 'me', members: [me, ...flatmates]);
    data!.points = {for (final m in data!.members) m.id: 0};
    _log('Flat created');
    _changed();
  }

  void loadSample() {
    data = sampleData();
    _changed();
  }

  void resetAll() {
    data = null;
    _changed();
  }

  // ---------- derived ----------
  List<String> get ids => data!.members.map((m) => m.id).toList();
  Map<String, int> get net => netBalances(ids, data!.expenses, data!.payments);
  List<Transfer> get debts => data!.simplify ? simplifyDebts(net) : pairwiseDebts(ids, data!.expenses, data!.payments);
  Set<String> get awaySet => data!.members.where((m) => m.away).map((m) => m.id).toSet();

  // ---------- expenses ----------
  void addExpense({
    required String desc,
    required int amount,
    required String paidBy,
    required Map<String, int> shares,
    required String mode,
    required String cat,
    bool repeatMonthly = false,
    bool clearMyBoughtItems = false,
  }) {
    final d = data!;
    d.expenses.add(Expense(id: d.newId(), desc: desc, amount: amount, paidBy: paidBy, shares: shares, mode: mode, cat: cat, date: todayIso()));
    if (repeatMonthly) {
      d.recurring.add(Recurring(id: d.newId(), desc: desc, amount: amount, paidBy: paidBy, cat: cat, next: addMonthIso(todayIso())));
    }
    if (clearMyBoughtItems) d.list.removeWhere((i) => i.done && i.boughtBy == d.meId);
    _log('${d.nameOf(paidBy)} added $desc · ${inr(amount)}');
    _changed();
  }

  void deleteExpense(int id) {
    final d = data!;
    final e = d.expenses.firstWhere((x) => x.id == id);
    d.expenses.remove(e);
    _log('You deleted ${e.desc}');
    _changed();
  }

  void postRecurring(int id) {
    final d = data!;
    final r = d.recurring.firstWhere((x) => x.id == id);
    final month = monthName(parseIso(r.next).month);
    d.expenses.add(Expense(
      id: d.newId(),
      desc: '${r.desc} ($month)',
      amount: r.amount,
      paidBy: r.paidBy,
      shares: equalShares(r.amount, ids),
      mode: 'equal',
      cat: r.cat,
      date: todayIso(),
    ));
    r.next = addMonthIso(r.next);
    _log('${d.nameOf(r.paidBy)} added ${r.desc} · ${inr(r.amount)}');
    _changed();
  }

  void deleteRecurring(int id) {
    data!.recurring.removeWhere((r) => r.id == id);
    _changed();
  }

  // ---------- payments ----------
  void recordPayment(String from, String to, int amount) {
    final d = data!;
    d.payments.add(Payment(id: d.newId(), from: from, to: to, amount: amount, date: todayIso()));
    _log('${d.nameOf(from)} paid ${d.nameObj(to)} ${inr(amount)}');
    _changed();
  }

  void setSimplify(bool v) {
    data!.simplify = v;
    _changed();
  }

  // ---------- shopping list ----------
  void addItem(String name) {
    final d = data!;
    d.list.insert(0, ListItem(id: d.newId(), name: name, by: d.meId));
    _changed();
  }

  void toggleItem(int id) {
    final i = data!.list.firstWhere((x) => x.id == id);
    i.done = !i.done;
    i.boughtBy = i.done ? data!.meId : null;
    _changed();
  }

  void removeItem(int id) {
    data!.list.removeWhere((x) => x.id == id);
    _changed();
  }

  // ---------- chores ----------
  void addChore(String name, int everyDays, String firstId) {
    final d = data!;
    final all = ids;
    final k = all.indexOf(firstId);
    final rotation = [...all.sublist(k), ...all.sublist(0, k)];
    d.chores.add(Chore(id: d.newId(), name: name, everyDays: everyDays, rotation: rotation, due: todayIso()));
    _log('You added the chore $name');
    _changed();
  }

  /// Marks the current turn done. Returns the next person's id.
  String completeChore(int id) {
    final d = data!;
    final c = d.chores.firstWhere((x) => x.id == id);
    final ci = currentTurn(c, awaySet);
    final who = c.rotation[ci];
    d.points[who] = (d.points[who] ?? 0) + 1;
    c.idx = (ci + 1) % c.rotation.length;
    final base = daysBetween(c.due, todayIso()) > 0 ? todayIso() : c.due;
    c.due = addDaysIso(base, c.everyDays);
    _log('${d.nameOf(who)} finished ${c.name.toLowerCase()}');
    _changed();
    return c.rotation[currentTurn(c, awaySet)];
  }

  /// Swaps the current turn with the next person who isn't away. Returns their id.
  String swapChore(int id) {
    final d = data!;
    final c = d.chores.firstWhere((x) => x.id == id);
    final ci = currentTurn(c, awaySet);
    var nj = (ci + 1) % c.rotation.length;
    for (var k = 0; k < c.rotation.length && awaySet.contains(c.rotation[nj]); k++) {
      nj = (nj + 1) % c.rotation.length;
    }
    final other = c.rotation[nj];
    final tmp = c.rotation[ci];
    c.rotation[ci] = c.rotation[nj];
    c.rotation[nj] = tmp;
    _log('${d.nameOf(tmp)} swapped ${c.name.toLowerCase()} with ${d.nameObj(other)}');
    _changed();
    return other;
  }

  void deleteChore(int id) {
    data!.chores.removeWhere((c) => c.id == id);
    _changed();
  }

  // ---------- members ----------
  void setAway(String id, bool away) {
    final d = data!;
    d.member(id)!.away = away;
    _log('${d.nameOf(id)} ${id == d.meId ? 'are' : 'is'} ${away ? 'away' : 'back'}');
    _changed();
  }

  void addMember(String name, String upi) {
    final d = data!;
    final id = 'm${d.newId()}';
    d.members.add(Member(id: id, name: name, upi: upi));
    d.points[id] = 0;
    for (final c in d.chores) {
      c.rotation.add(id);
    }
    _log('$name joined the flat');
    _changed();
  }

  void updateMember(String id, {String? name, String? upi}) {
    final m = data!.member(id)!;
    if (name != null && name.trim().isNotEmpty) m.name = name.trim();
    if (upi != null) m.upi = upi.trim();
    _changed();
  }
}

/// Sample flat used for "Explore with sample data". Dates are relative to today.
AppData sampleData() {
  final t = todayIso();
  String ago(int n) => addDaysIso(t, -n);
  const all = ['me', 'rohan', 'priya', 'karthik'];
  Expense e(int id, String desc, int rupees, String by, List<String> who, String cat, int daysAgo) =>
      Expense(id: id, desc: desc, amount: rupees * 100, paidBy: by, shares: equalShares(rupees * 100, who), mode: 'equal', cat: cat, date: ago(daysAgo));
  return AppData(
    flatName: 'Flat 3B',
    meId: 'me',
    members: [
      Member(id: 'me', name: 'Anu', upi: 'anu.s@okaxis'),
      Member(id: 'rohan', name: 'Rohan', upi: 'rohan.k@oksbi'),
      Member(id: 'priya', name: 'Priya', upi: 'priya.m@ybl'),
      Member(id: 'karthik', name: 'Karthik', upi: 'karthik92@okicici'),
    ],
    expenses: [
      e(1, 'Monthly rent', 48000, 'rohan', all, 'rent', 27),
      e(2, 'Maid salary', 6000, 'me', all, 'help', 23),
      e(3, 'ACT Fibernet Wi-Fi', 1180, 'priya', all, 'utilities', 18),
      e(4, 'Cooking gas cylinder', 905, 'rohan', all, 'utilities', 14),
      e(5, 'Electricity bill', 3240, 'me', all, 'utilities', 10),
      e(6, 'Friday dinner', 1640, 'priya', ['me', 'priya', 'karthik'], 'food', 9),
      e(7, 'Monthly groceries', 2860, 'karthik', all, 'food', 6),
      Expense(id: 8, desc: 'New curtains', amount: 240000, paidBy: 'priya', shares: {'me': 90000, 'rohan': 50000, 'priya': 50000, 'karthik': 50000}, mode: 'exact', cat: 'other', date: ago(2), note: "Anu's room got the bigger pair"),
    ],
    payments: [Payment(id: 101, from: 'priya', to: 'rohan', amount: 1200000, date: ago(25))],
    recurring: [
      Recurring(id: 301, desc: 'Monthly rent', amount: 4800000, paidBy: 'rohan', cat: 'rent', next: addDaysIso(t, 3)),
      Recurring(id: 302, desc: 'Maid salary', amount: 600000, paidBy: 'me', cat: 'help', next: addDaysIso(t, 7)),
      Recurring(id: 303, desc: 'ACT Fibernet Wi-Fi', amount: 118000, paidBy: 'priya', cat: 'utilities', next: addDaysIso(t, 12)),
    ],
    list: [
      ListItem(id: 401, name: 'Milk, 2 packets', by: 'priya'),
      ListItem(id: 402, name: 'Dishwash liquid', by: 'me'),
      ListItem(id: 403, name: 'Eggs, 1 tray', by: 'karthik', done: true, boughtBy: 'me'),
      ListItem(id: 404, name: 'Garbage bags', by: 'rohan', done: true, boughtBy: 'me'),
    ],
    chores: [
      Chore(id: 1, name: 'Take out the trash', everyDays: 1, rotation: ['me', 'rohan', 'priya', 'karthik'], due: t),
      Chore(id: 2, name: 'Refill water cans', everyDays: 3, rotation: ['rohan', 'karthik', 'me', 'priya'], due: ago(2)),
      Chore(id: 3, name: 'Wash the dishes', everyDays: 1, rotation: ['karthik', 'priya', 'me', 'rohan'], due: t),
      Chore(id: 4, name: 'Clean the bathroom', everyDays: 7, rotation: ['priya', 'me', 'rohan', 'karthik'], due: addDaysIso(t, 1)),
    ],
    points: {'me': 14, 'rohan': 9, 'priya': 16, 'karthik': 11},
    activity: [
      Activity('Priya added New curtains · ₹2,400', ago(2)),
      Activity('Karthik added Monthly groceries · ₹2,860', ago(6)),
      Activity('Priya added Friday dinner · ₹1,640', ago(9)),
    ],
  );
}
