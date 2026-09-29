import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart';

/// Holds the app state, saves it on the phone, and exposes actions.
class HariyaliStore extends ChangeNotifier {
  static const _key = 'hariyali_data_v1';
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

  void _log(int plantId, String type, [String note = '']) {
    final d = data!;
    d.events.insert(0, CareEvent(plantId: plantId, type: type, date: todayIso(), note: note));
    if (d.events.length > 400) d.events.removeRange(400, d.events.length);
  }

  // ---------- setup ----------
  void setup({required String owner, required String location, required String season, required bool pets}) {
    data = AppData(ownerName: owner, location: location, season: season, pets: pets);
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
  String get today => todayIso();
  Weather? get weatherToday => weatherFor(data!.weather, today);

  CarePlan planOf(Plant p) {
    final d = data!;
    return planFor(p, today: today, season: d.season, weather: d.weather, events: d.events);
  }

  int get toWaterCount => data == null ? 0 : data!.plants.where((p) => planOf(p).kind == 'water').length;

  List<CareEvent> historyOf(int plantId) => data!.events.where((e) => e.plantId == plantId).toList();

  // ---------- home settings ----------
  void updateProfile(String owner, String location) {
    final d = data!;
    if (owner.trim().isNotEmpty) d.ownerName = owner.trim();
    d.location = location.trim();
    _changed();
  }

  void setPets(bool v) {
    data!.pets = v;
    _changed();
  }

  void setSeason(String s) {
    data!.season = s;
    _changed();
  }

  void setWeather({required bool rain, required bool hot}) {
    data!.weather = Weather(date: today, rain: rain, hot: hot);
    _changed();
  }

  // ---------- plants ----------
  void addPlant(Plant p) {
    data!.plants.add(p);
    _changed();
  }

  void editPlant(int id, void Function(Plant p) change) {
    final p = data!.plant(id);
    if (p == null) return;
    change(p);
    _changed();
  }

  void deletePlant(int id) {
    final d = data!;
    d.plants.removeWhere((p) => p.id == id);
    d.events.removeWhere((e) => e.plantId == id);
    _changed();
  }

  /// Records a soil check. Returns a message to show. [answer]: dry | very_dry | damp.
  String soilCheck(int id, String answer) {
    final d = data!;
    final p = d.plant(id);
    if (p == null) return '';
    p.every = learnFromSoil(p.every, answer);
    if (answer == 'damp') {
      p.nextCheck = addDaysIso(today, 2);
      _log(id, 'damp');
      _changed();
      return 'Good call. Hariyali will check again in 2 days and waters ${p.name} a little less often.';
    }
    p.last = today;
    p.nextCheck = null;
    _log(id, 'water');
    _changed();
    final next = shortDate(nextDue(p, d.season));
    if (answer == 'very_dry') return '${p.name} watered. It dries fast here, so the next check is sooner: $next.';
    return '${p.name} watered. Next check $next.';
  }

  void markFed(int id) {
    final p = data!.plant(id);
    if (p == null) return;
    p.lastFed = today;
    _log(id, 'feed');
    _changed();
  }

  /// Starts a repeating treatment (or just notes the problem) on a plant.
  void startTreatment(int id, Problem pr) {
    final p = data!.plant(id);
    if (p == null) return;
    p.health = 'watch';
    if (pr.repeatDays > 0) {
      p.issue = '${pr.name}: ${pr.treatment.toLowerCase()} every ${pr.repeatDays} days';
      p.treatNote = pr.treatment;
      p.treatEvery = pr.repeatDays;
      p.treatNext = today;
      p.treatUntil = addDaysIso(today, pr.courseDays);
    } else {
      p.issue = pr.name;
    }
    _changed();
  }

  /// Marks today's treatment done. Returns true when the course is finished.
  bool treatDone(int id) {
    final p = data!.plant(id);
    if (p == null) return false;
    _log(id, 'treat', p.treatNote);
    final next = addDaysIso(today, p.treatEvery);
    final until = p.treatUntil;
    if (until == null || next.compareTo(until) > 0) {
      _clearTreatment(p);
      _changed();
      return true;
    }
    p.treatNext = next;
    _changed();
    return false;
  }

  void stopTreatment(int id) {
    final p = data!.plant(id);
    if (p == null) return;
    _clearTreatment(p);
    _changed();
  }

  void _clearTreatment(Plant p) {
    p.treatNote = '';
    p.treatEvery = 0;
    p.treatNext = null;
    p.treatUntil = null;
  }

  // ---------- away ----------
  void setTrip(Trip? t) {
    data!.trip = t;
    _changed();
  }

  void setTripLang(String lang) {
    final t = data!.trip;
    if (t == null) return;
    t.lang = lang;
    _changed();
  }
}

/// Sample home used for "Explore with sample data". Dates are relative to today.
AppData sampleData() {
  final t = todayIso();
  String ago(int n) => addDaysIso(t, -n);
  return AppData(
    ownerName: 'Meenakshi',
    location: 'Adyar, Chennai',
    pets: false,
    season: 'summer',
    weather: Weather(date: t, rain: true, hot: true),
    trip: Trip(from: addDaysIso(t, 10), to: addDaysIso(t, 15), helper: 'Lakshmi aunty', lang: 'en'),
    nextId: 100,
    plants: [
      Plant(id: 1, name: 'Tulsi', sci: 'Ocimum tenuiflorum', speciesId: 'tulsi', place: 'Balcony (covered corner)', exposure: 'covered', every: 2, last: ago(2), tip: 'Pinch off flower spikes to keep leaves coming.', pet: 'unknown', feedEvery: 30, lastFed: ago(12)),
      Plant(id: 2, name: 'Curry leaf', sci: 'Murraya koenigii', speciesId: 'curry_leaf', place: 'Balcony (west, open)', exposure: 'open', every: 3, last: ago(3), tip: 'Likes full sun. Feed once a month in the growing season.', pet: 'unknown', feedEvery: 30, lastFed: ago(10)),
      Plant(id: 3, name: 'Hibiscus', sci: 'Hibiscus rosa-sinensis', speciesId: 'hibiscus', place: 'Balcony (covered)', exposure: 'covered', every: 1, last: ago(1), health: 'sick', issue: 'White cotton-like spots under leaves', tip: 'Heavy feeder when flowering.', pet: 'safe', feedEvery: 14, lastFed: ago(5)),
      Plant(id: 4, name: 'Money plant', sci: 'Epipremnum aureum (pothos)', speciesId: 'money_plant', place: 'Living room (bright, indirect)', exposure: 'indoor', every: 6, last: ago(4), tip: 'Water when the top 2–3 cm of soil is dry.', pet: 'toxic'),
      Plant(id: 5, name: 'Mogra', sci: 'Jasminum sambac', speciesId: 'mogra', place: 'Balcony (west, open)', exposure: 'open', every: 2, last: ago(2), health: 'watch', issue: 'Few buds this month', tip: 'Needs 6+ hours of sun to flower.', pet: 'safe', feedEvery: 30, lastFed: ago(30)),
      Plant(id: 6, name: 'Snake plant', sci: 'Dracaena trifasciata', speciesId: 'snake_plant', place: 'Bedroom (low light)', exposure: 'indoor', every: 14, last: ago(8), tip: 'Rot is the main risk. Less water in low light.', pet: 'toxic'),
      Plant(id: 7, name: 'Aloe vera', sci: 'Aloe vera', speciesId: 'aloe_vera', place: 'Kitchen window', exposure: 'indoor', every: 12, last: ago(9), tip: 'Let the soil dry out completely.', pet: 'toxic'),
      Plant(id: 8, name: 'Chilli', sci: 'Capsicum annuum', speciesId: 'chilli', place: 'Balcony (west, open)', exposure: 'open', every: 1, last: ago(1), tip: 'Pick ripe chillies to get more.', pet: 'unknown', feedEvery: 30, lastFed: ago(20)),
    ],
    events: [
      CareEvent(plantId: 3, type: 'water', date: ago(1)),
      CareEvent(plantId: 8, type: 'water', date: ago(1)),
      CareEvent(plantId: 1, type: 'water', date: ago(2)),
      CareEvent(plantId: 5, type: 'water', date: ago(2)),
      CareEvent(plantId: 2, type: 'water', date: ago(3)),
      CareEvent(plantId: 4, type: 'water', date: ago(4)),
      CareEvent(plantId: 3, type: 'feed', date: ago(5)),
      CareEvent(plantId: 6, type: 'water', date: ago(8)),
      CareEvent(plantId: 7, type: 'water', date: ago(9)),
    ],
  );
}
