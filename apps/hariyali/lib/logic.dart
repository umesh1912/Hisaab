// Core data model and pure logic for Hariyali. No Flutter imports here.

// ---------------- models ----------------

class Plant {
  Plant({
    required this.id,
    required this.name,
    this.sci = '',
    this.speciesId = '',
    required this.place,
    this.exposure = 'indoor',
    required this.every,
    required this.last,
    this.nextCheck,
    this.health = 'ok',
    this.issue = '',
    this.tip = '',
    this.pet = 'unknown',
    this.feedEvery = 0,
    this.lastFed,
    this.treatNote = '',
    this.treatEvery = 0,
    this.treatNext,
    this.treatUntil,
  });

  final int id;
  String name;
  String sci;
  String speciesId; // library id, '' for a custom plant
  String place; // free text, e.g. "Balcony (west, open)"
  String exposure; // indoor | covered | open  (open = gets rain)
  int every; // days between waterings in the hot season; learned from soil checks
  String last; // last watered, yyyy-MM-dd
  String? nextCheck; // set when the soil was still damp
  String health; // ok | watch | sick
  String issue;
  String tip;
  String pet; // safe | toxic | unknown
  int feedEvery; // days, 0 = no feeding reminders
  String? lastFed;
  String treatNote; // e.g. "Neem soap spray (mealybugs)"
  int treatEvery;
  String? treatNext;
  String? treatUntil;

  bool get treating => treatNext != null && treatUntil != null && treatEvery > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sci': sci,
        'speciesId': speciesId,
        'place': place,
        'exposure': exposure,
        'every': every,
        'last': last,
        'nextCheck': nextCheck,
        'health': health,
        'issue': issue,
        'tip': tip,
        'pet': pet,
        'feedEvery': feedEvery,
        'lastFed': lastFed,
        'treatNote': treatNote,
        'treatEvery': treatEvery,
        'treatNext': treatNext,
        'treatUntil': treatUntil,
      };

  factory Plant.fromJson(Map<String, dynamic> j) => Plant(
        id: j['id'] as int,
        name: j['name'] as String,
        sci: (j['sci'] ?? '') as String,
        speciesId: (j['speciesId'] ?? '') as String,
        place: (j['place'] ?? '') as String,
        exposure: (j['exposure'] ?? 'indoor') as String,
        every: (j['every'] ?? 3) as int,
        last: j['last'] as String,
        nextCheck: j['nextCheck'] as String?,
        health: (j['health'] ?? 'ok') as String,
        issue: (j['issue'] ?? '') as String,
        tip: (j['tip'] ?? '') as String,
        pet: (j['pet'] ?? 'unknown') as String,
        feedEvery: (j['feedEvery'] ?? 0) as int,
        lastFed: j['lastFed'] as String?,
        treatNote: (j['treatNote'] ?? '') as String,
        treatEvery: (j['treatEvery'] ?? 0) as int,
        treatNext: j['treatNext'] as String?,
        treatUntil: j['treatUntil'] as String?,
      );
}

/// Something that happened to a plant: water | damp | feed | treat.
class CareEvent {
  CareEvent({required this.plantId, required this.type, required this.date, this.note = ''});
  final int plantId;
  final String type;
  final String date;
  final String note;

  Map<String, dynamic> toJson() => {'plantId': plantId, 'type': type, 'date': date, 'note': note};
  factory CareEvent.fromJson(Map<String, dynamic> j) => CareEvent(
        plantId: j['plantId'] as int,
        type: j['type'] as String,
        date: j['date'] as String,
        note: (j['note'] ?? '') as String,
      );
}

/// Weather the owner entered by hand. Only counts on the day it was set.
class Weather {
  Weather({required this.date, this.rain = false, this.hot = false});
  final String date;
  final bool rain; // 5 mm or more expected in the next 24 hours
  final bool hot; // 33 °C or above today

  Map<String, dynamic> toJson() => {'date': date, 'rain': rain, 'hot': hot};
  factory Weather.fromJson(Map<String, dynamic> j) =>
      Weather(date: j['date'] as String, rain: (j['rain'] ?? false) as bool, hot: (j['hot'] ?? false) as bool);
}

class Trip {
  Trip({required this.from, required this.to, required this.helper, this.lang = 'en'});
  String from;
  String to;
  String helper;
  String lang; // en | ta

  Map<String, dynamic> toJson() => {'from': from, 'to': to, 'helper': helper, 'lang': lang};
  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        from: j['from'] as String,
        to: j['to'] as String,
        helper: (j['helper'] ?? '') as String,
        lang: (j['lang'] ?? 'en') as String,
      );
}

class AppData {
  AppData({
    required this.ownerName,
    this.location = '',
    this.pets = false,
    this.season = 'summer',
    this.weather,
    List<Plant>? plants,
    List<CareEvent>? events,
    this.trip,
    this.nextId = 1000,
  })  : plants = plants ?? [],
        events = events ?? [];

  String ownerName;
  String location;
  bool pets;
  String season; // summer | monsoon | winter
  Weather? weather;
  List<Plant> plants;
  List<CareEvent> events; // newest first
  Trip? trip;
  int nextId;

  int newId() => nextId++;

  Plant? plant(int id) {
    for (final p in plants) {
      if (p.id == id) return p;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'ownerName': ownerName,
        'location': location,
        'pets': pets,
        'season': season,
        'weather': weather?.toJson(),
        'plants': plants.map((e) => e.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'trip': trip?.toJson(),
        'nextId': nextId,
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    List<T> l<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] ?? []) as List).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    final w = j['weather'];
    final t = j['trip'];
    return AppData(
      ownerName: (j['ownerName'] ?? '') as String,
      location: (j['location'] ?? '') as String,
      pets: (j['pets'] ?? false) as bool,
      season: (j['season'] ?? 'summer') as String,
      weather: w == null ? null : Weather.fromJson(Map<String, dynamic>.from(w as Map)),
      plants: l('plants', Plant.fromJson),
      events: l('events', CareEvent.fromJson),
      trip: t == null ? null : Trip.fromJson(Map<String, dynamic>.from(t as Map)),
      nextId: (j['nextId'] ?? 1000) as int,
    );
  }
}

// ---------------- watering model ----------------

const seasons = {'summer': 'Summer', 'monsoon': 'Monsoon', 'winter': 'Winter'};
const exposures = {'indoor': 'Indoors', 'covered': 'Covered balcony', 'open': 'Open to rain'};
const healthLabels = {'ok': 'Healthy', 'watch': 'Keep an eye', 'sick': 'Needs care'};
const petLabels = {
  'toxic': 'Toxic to cats and dogs',
  'safe': 'Generally considered safe',
  'unknown': 'Not sure; keep out of reach',
};

/// Soil dries slower in the monsoon and in cool weather, so intervals stretch.
double seasonFactor(String season) {
  switch (season) {
    case 'monsoon':
      return 1.3;
    case 'winter':
      return 1.5;
    default:
      return 1.0;
  }
}

/// Days between waterings for [every] (a hot-season interval) in [season].
int effectiveEvery(int every, String season) {
  final v = (every * seasonFactor(season)).round();
  return v < 1 ? 1 : v;
}

/// The date the soil should next be checked.
String nextDue(Plant p, String season) => p.nextCheck ?? addDaysIso(p.last, effectiveEvery(p.every, season));

/// Weather counts only on the day it was entered.
Weather? weatherFor(Weather? w, String today) => (w != null && w.date == today) ? w : null;

class CarePlan {
  const CarePlan(this.kind, this.reason, [this.days = 0]);
  final String kind; // water | skip | later | done
  final String reason;
  final int days; // for "later": days until due
}

String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

/// Decides what a plant needs today. [events] are newest first.
CarePlan planFor(Plant p, {required String today, required String season, Weather? weather, List<CareEvent> events = const []}) {
  for (final e in events) {
    if (e.plantId != p.id || e.date != today) continue;
    if (e.type == 'water') return const CarePlan('done', 'Watered today');
    if (e.type == 'damp') return CarePlan('done', 'Soil was damp: checking again ${shortDate(nextDue(p, season))}');
  }
  final due = daysBetween(today, nextDue(p, season));
  if (due > 0) return CarePlan('later', 'Water in ${plural(due, 'day')}', due);
  final w = weatherFor(weather, today);
  if (p.exposure == 'open' && w != null && w.rain) {
    return const CarePlan('skip', 'Rain expected in the next 24 hours. Open spot, so it gets the rain.');
  }
  var why = due < 0 ? '${plural(-due, 'day')} overdue' : 'Due today';
  if (w != null && w.hot && p.exposure != 'indoor') why += ' · hot day, water in the evening';
  return CarePlan('water', why);
}

/// 1.0 = just watered, 0.0 = due now.
double waterLevel(Plant p, String today, String season) {
  final eff = effectiveEvery(p.every, season);
  final d = daysBetween(today, nextDue(p, season));
  final v = d / eff;
  if (v < 0) return 0;
  if (v > 1) return 1;
  return v;
}

/// Adjusts a plant's interval from what the soil felt like: dry | very_dry | damp.
int learnFromSoil(int every, String answer) {
  final step = (every * 0.15).round() < 1 ? 1 : (every * 0.15).round();
  if (answer == 'damp') return every + step > 60 ? 60 : every + step;
  if (answer == 'very_dry') return every - step < 1 ? 1 : every - step;
  return every;
}

bool feedDue(Plant p, String today) =>
    p.feedEvery > 0 && (p.lastFed == null || daysBetween(p.lastFed!, today) >= p.feedEvery);

bool treatDue(Plant p, String today) => p.treating && daysBetween(p.treatNext!, today) >= 0;

// ---------------- away notes ----------------

/// Days a helper should water during [from]..[to], assuming the owner waters
/// everything well the day before leaving.
List<String> wateringDates(Plant p, String from, String to, String season) {
  final eff = effectiveEvery(p.every, season);
  final out = <String>[];
  var d = addDaysIso(from, -1);
  for (var i = 0; i < 400; i++) {
    d = addDaysIso(d, eff);
    if (d.compareTo(to) > 0) break;
    out.add(d);
  }
  return out;
}

const _taMon = ['ஜனவரி', 'பிப்ரவரி', 'மார்ச்', 'ஏப்ரல்', 'மே', 'ஜூன்', 'ஜூலை', 'ஆகஸ்ட்', 'செப்டம்பர்', 'அக்டோபர்', 'நவம்பர்', 'டிசம்பர்'];
String tamilDate(String s) {
  final d = parseIso(s);
  return '${d.day} ${_taMon[d.month - 1]}';
}

/// Writes simple care instructions for whoever looks after the plants.
String careNote({required List<Plant> plants, required Trip trip, required String season, required String owner}) {
  final ta = trip.lang == 'ta';
  String dl(String s) => ta ? tamilDate(s) : shortDate(s);
  final span = daysBetween(trip.from, trip.to) + 1;
  final daily = <String>[];
  final lines = <String>[];
  final none = <String>[];
  final open = <String>[];
  for (final p in plants) {
    final dates = wateringDates(p, trip.from, trip.to, season);
    if (p.exposure == 'open' && dates.isNotEmpty) open.add(p.name);
    if (dates.isEmpty) {
      none.add(p.name);
    } else if (dates.length == span) {
      daily.add(p.name);
    } else {
      final list = dates.map(dl).join(', ');
      if (ta) {
        lines.add('${p.name}: $list அன்று தண்ணீர் ஊற்றவும்.');
      } else {
        lines.add(dates.length == 1 ? '${p.name}: water once, on $list.' : '${p.name}: water on $list.');
      }
    }
  }
  final b = StringBuffer();
  final helper = trip.helper.trim();
  if (ta) {
    b.writeln('வணக்கம்${helper.isEmpty ? '' : ' $helper'} 🙏');
    b.writeln('${dl(trip.from)} முதல் ${dl(trip.to)} வரை என் செடிகளைப் பார்த்துக்கொள்வதற்கு நன்றி.');
    b.writeln();
    if (daily.isNotEmpty) b.writeln('தினமும் மாலையில் தண்ணீர் ஊற்றவும்: ${daily.join(', ')}.');
    for (final l in lines) {
      b.writeln(l);
    }
    if (none.isNotEmpty) b.writeln('தண்ணீர் வேண்டாம்: ${none.join(', ')}.');
    if (open.isNotEmpty) b.writeln('திறந்த பால்கனி செடிகள் (${open.join(', ')}): மழை பெய்த நாளில் தண்ணீர் வேண்டாம்.');
    b.writeln();
    b.writeln('பானையின் அடியில் தண்ணீர் சிறிது வெளியே வரும் வரை ஊற்றவும்.');
    b.writeln('சந்தேகம் இருந்தால் மண்ணைத் தொட்டுப் பாருங்கள்: ஈரமாக இருந்தால் ஊற்ற வேண்டாம்.');
  } else {
    b.writeln('Hi${helper.isEmpty ? '' : ' $helper'} 🙏');
    b.writeln('Thank you for looking after my plants from ${dl(trip.from)} to ${dl(trip.to)}.');
    b.writeln();
    if (daily.isNotEmpty) b.writeln('Every evening: ${daily.join(', ')}.');
    for (final l in lines) {
      b.writeln(l);
    }
    if (none.isNotEmpty) b.writeln('No water needed: ${none.join(', ')}.');
    if (open.isNotEmpty) b.writeln('Open balcony (${open.join(', ')}): skip any day it rains.');
    b.writeln();
    b.writeln('Water slowly until a little drains out of the bottom of the pot.');
    b.writeln("If in doubt, touch the soil. If it's damp, don't water.");
  }
  if (owner.trim().isNotEmpty) b.write('– ${owner.trim()}');
  return b.toString().trimRight();
}

// ---------------- plant library ----------------

class Species {
  const Species({
    required this.id,
    required this.name,
    required this.sci,
    this.aka = '',
    required this.group,
    required this.light,
    required this.exposure,
    required this.every,
    required this.water,
    this.feedEvery = 0,
    required this.pet,
    required this.tip,
  });
  final String id;
  final String name;
  final String sci;
  final String aka; // other common names, including Indian names
  final String group;
  final String light; // sun | bright | low
  final String exposure; // suggested spot
  final int every; // hot-season starting interval in a typical pot, in days
  final String water;
  final int feedEvery;
  final String pet;
  final String tip;
}

const lightLabels = {
  'sun': 'Full sun, 6+ hours',
  'bright': 'Bright, indirect light',
  'low': 'Tolerates low light',
};

/// Starting points for common plants in Indian homes. Pet safety follows the
/// ASPCA toxic and non-toxic plant lists; "unknown" where a plant isn't listed.
const plantLibrary = <Species>[
  Species(id: 'tulsi', name: 'Tulsi', sci: 'Ocimum tenuiflorum', aka: 'Holy basil', group: 'Balcony and edible', light: 'sun', exposure: 'covered', every: 2, water: 'Water when the top 2 cm of soil is dry. Pots in full sun dry fast in summer.', feedEvery: 30, pet: 'unknown', tip: 'Pinch off flower spikes to keep leaves coming.'),
  Species(id: 'curry_leaf', name: 'Curry leaf', sci: 'Murraya koenigii', aka: 'Kadi patta, karuveppilai', group: 'Balcony and edible', light: 'sun', exposure: 'open', every: 3, water: 'Let the top few cm dry between waterings. Dislikes waterlogged soil.', feedEvery: 30, pet: 'unknown', tip: 'Likes full sun. Feed once a month in the growing season.'),
  Species(id: 'chilli', name: 'Chilli', sci: 'Capsicum annuum', aka: 'Mirchi, milagai', group: 'Balcony and edible', light: 'sun', exposure: 'open', every: 1, water: 'Keep soil evenly moist, not soggy. Small pots in summer may need daily water.', feedEvery: 30, pet: 'unknown', tip: 'Pick ripe chillies to get more.'),
  Species(id: 'tomato', name: 'Tomato', sci: 'Solanum lycopersicum', aka: 'Tamatar, thakkali', group: 'Balcony and edible', light: 'sun', exposure: 'open', every: 1, water: 'Water deeply and regularly. Uneven watering causes cracked fruit and blossom-end rot.', feedEvery: 14, pet: 'toxic', tip: 'Stake the plant and water the soil, not the leaves.'),
  Species(id: 'mint', name: 'Mint', sci: 'Mentha spicata', aka: 'Pudina', group: 'Balcony and edible', light: 'bright', exposure: 'covered', every: 1, water: 'Likes consistently moist soil. Give it afternoon shade in summer.', feedEvery: 30, pet: 'toxic', tip: 'Spreads fast. Grow it in its own pot.'),
  Species(id: 'lemongrass', name: 'Lemongrass', sci: 'Cymbopogon citratus', aka: 'Gavati chaha', group: 'Balcony and edible', light: 'sun', exposure: 'open', every: 2, water: 'Water when the top 2–3 cm is dry. Needs less in cool weather.', feedEvery: 30, pet: 'toxic', tip: 'Cut stalks from the base; the clump regrows.'),
  Species(id: 'hibiscus', name: 'Hibiscus', sci: 'Hibiscus rosa-sinensis', aka: 'Gudhal, sembaruthi', group: 'Flowering', light: 'sun', exposure: 'covered', every: 1, water: 'Drinks a lot when flowering in summer. Water when the top 2 cm feels dry.', feedEvery: 14, pet: 'safe', tip: 'Heavy feeder when flowering. Check leaf undersides for mealybugs.'),
  Species(id: 'mogra', name: 'Mogra', sci: 'Jasminum sambac', aka: 'Arabian jasmine, malligai', group: 'Flowering', light: 'sun', exposure: 'open', every: 2, water: 'Keep lightly moist in summer; let the top dry out between waterings.', feedEvery: 30, pet: 'safe', tip: 'Needs 6+ hours of sun to flower. Prune after the flowering season.'),
  Species(id: 'rose', name: 'Rose', sci: 'Rosa hybrids', aka: 'Gulab', group: 'Flowering', light: 'sun', exposure: 'open', every: 2, water: 'Water deeply at the base when the top 2–3 cm is dry. Avoid wetting the leaves.', feedEvery: 14, pet: 'safe', tip: 'Remove faded flowers to get more blooms.'),
  Species(id: 'bougainvillea', name: 'Bougainvillea', sci: 'Bougainvillea glabra', aka: 'Kagaz phool', group: 'Flowering', light: 'sun', exposure: 'open', every: 4, water: 'Let the soil dry well between waterings. Too much water means leaves, not flowers.', feedEvery: 30, pet: 'unknown', tip: 'Flowers best when slightly root-bound and on the dry side.'),
  Species(id: 'marigold', name: 'Marigold', sci: 'Tagetes erecta', aka: 'Genda, saamanthi', group: 'Flowering', light: 'sun', exposure: 'open', every: 2, water: 'Water when the top 2 cm is dry. Water the soil, not the flowers.', feedEvery: 30, pet: 'unknown', tip: 'Pinch off spent flowers to keep it blooming.'),
  Species(id: 'periwinkle', name: 'Periwinkle', sci: 'Catharanthus roseus', aka: 'Sadabahar, nithya kalyani', group: 'Flowering', light: 'sun', exposure: 'open', every: 3, water: 'Drought-tolerant. Let the top soil dry out; it rots in soggy soil.', feedEvery: 0, pet: 'toxic', tip: 'Very hardy in heat. Keep it away from pets and children.'),
  Species(id: 'adenium', name: 'Adenium', sci: 'Adenium obesum', aka: 'Desert rose', group: 'Flowering', light: 'sun', exposure: 'covered', every: 7, water: 'Let the soil dry completely. Water much less in the monsoon and winter.', feedEvery: 30, pet: 'toxic', tip: 'Its sap is poisonous. A gritty, fast-draining mix prevents rot.'),
  Species(id: 'money_plant', name: 'Money plant', sci: 'Epipremnum aureum', aka: 'Pothos', group: 'Indoor foliage', light: 'bright', exposure: 'indoor', every: 6, water: 'Water when the top 2–3 cm of soil is dry.', feedEvery: 30, pet: 'toxic', tip: 'Yellow leaves usually mean too much water.'),
  Species(id: 'snake_plant', name: 'Snake plant', sci: 'Dracaena trifasciata', aka: 'Sansevieria', group: 'Indoor foliage', light: 'low', exposure: 'indoor', every: 14, water: 'Let the soil dry out completely. Every 2–3 weeks, less in winter.', feedEvery: 0, pet: 'toxic', tip: 'Rot is the main risk. Less water in low light.'),
  Species(id: 'zz_plant', name: 'ZZ plant', sci: 'Zamioculcas zamiifolia', group: 'Indoor foliage', light: 'low', exposure: 'indoor', every: 14, water: 'Let the soil dry out completely. It stores water in its thick roots.', feedEvery: 0, pet: 'toxic', tip: 'Overwatering is the usual way it dies.'),
  Species(id: 'areca_palm', name: 'Areca palm', sci: 'Dypsis lutescens', group: 'Indoor foliage', light: 'bright', exposure: 'indoor', every: 4, water: 'Keep lightly moist, never soggy. Water when the top 2–3 cm is dry.', feedEvery: 30, pet: 'safe', tip: 'Brown tips often mean dry air or salts in tap water.'),
  Species(id: 'peace_lily', name: 'Peace lily', sci: 'Spathiphyllum wallisii', group: 'Indoor foliage', light: 'low', exposure: 'indoor', every: 5, water: 'Water when the top 2–3 cm is dry. It droops when thirsty and perks up after water.', feedEvery: 30, pet: 'toxic', tip: 'Not a true lily, but still irritating to pets if chewed.'),
  Species(id: 'rubber_plant', name: 'Rubber plant', sci: 'Ficus elastica', group: 'Indoor foliage', light: 'bright', exposure: 'indoor', every: 7, water: 'Let the top half of the soil dry between waterings.', feedEvery: 30, pet: 'toxic', tip: 'Wipe dust off the big leaves so they get light.'),
  Species(id: 'spider_plant', name: 'Spider plant', sci: 'Chlorophytum comosum', group: 'Indoor foliage', light: 'bright', exposure: 'indoor', every: 5, water: 'Water when the top 2–3 cm is dry.', feedEvery: 30, pet: 'safe', tip: 'Pot up the baby plantlets to get new plants.'),
  Species(id: 'aglaonema', name: 'Aglaonema', sci: 'Aglaonema commutatum', aka: 'Chinese evergreen', group: 'Indoor foliage', light: 'low', exposure: 'indoor', every: 6, water: 'Water when the top 2–3 cm is dry. Less in cool weather.', feedEvery: 30, pet: 'toxic', tip: 'Keep away from cold AC drafts.'),
  Species(id: 'syngonium', name: 'Syngonium', sci: 'Syngonium podophyllum', aka: 'Arrowhead plant', group: 'Indoor foliage', light: 'bright', exposure: 'indoor', every: 5, water: 'Water when the top 2–3 cm is dry.', feedEvery: 30, pet: 'toxic', tip: 'Pinch long vines to keep it bushy.'),
  Species(id: 'croton', name: 'Croton', sci: 'Codiaeum variegatum', group: 'Indoor foliage', light: 'bright', exposure: 'covered', every: 3, water: 'Likes evenly moist soil; drops leaves if it dries out hard.', feedEvery: 30, pet: 'toxic', tip: 'More light gives brighter leaf colours.'),
  Species(id: 'boston_fern', name: 'Boston fern', sci: 'Nephrolepis exaltata', group: 'Indoor foliage', light: 'bright', exposure: 'covered', every: 2, water: 'Keep the soil moist but not soggy. Likes humidity.', feedEvery: 30, pet: 'safe', tip: 'Keep out of direct afternoon sun.'),
  Species(id: 'aloe_vera', name: 'Aloe vera', sci: 'Aloe vera', aka: 'Ghritkumari, kathalai', group: 'Succulents', light: 'sun', exposure: 'covered', every: 12, water: 'Let the soil dry out completely between waterings.', feedEvery: 0, pet: 'toxic', tip: 'Use a pot with a drainage hole and sandy soil.'),
  Species(id: 'jade_plant', name: 'Jade plant', sci: 'Crassula ovata', group: 'Succulents', light: 'sun', exposure: 'covered', every: 10, water: 'Let the soil dry out completely. Wrinkled leaves mean it is thirsty.', feedEvery: 0, pet: 'toxic', tip: 'Protect from heavy monsoon rain.'),
  Species(id: 'cactus', name: 'Cactus', sci: 'Cactaceae', group: 'Succulents', light: 'sun', exposure: 'covered', every: 14, water: 'Water only when the soil is completely dry. Very little in the monsoon and winter.', feedEvery: 0, pet: 'unknown', tip: 'Keep out of rain. Spines can hurt pets and children.'),
];

Species? speciesById(String id) {
  for (final s in plantLibrary) {
    if (s.id == id) return s;
  }
  return null;
}

/// Case-insensitive search over name, scientific name, other names and group.
List<Species> searchLibrary(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return List.of(plantLibrary);
  return plantLibrary
      .where((s) => '${s.name} ${s.sci} ${s.aka} ${s.group}'.toLowerCase().contains(q))
      .toList();
}

// ---------------- problem guide ----------------

const symptoms = <String, String>{
  'white_cotton': 'White cottony spots',
  'sticky': 'Sticky leaves or ants',
  'bugs_tips': 'Tiny bugs on new shoots',
  'curled': 'Curled new leaves',
  'webbing': 'Fine webbing',
  'speckles': 'Tiny pale speckles',
  'bumps': 'Brown bumps on stems',
  'white_flies': 'Tiny white flies',
  'soil_flies': 'Tiny dark flies at the soil',
  'yellow_lower': 'Older leaves turning yellow',
  'yellow_veins': 'New leaves yellow, veins green',
  'wilt_wet': 'Wilting, soil wet',
  'wilt_dry': 'Wilting, soil dry',
  'crispy': 'Crispy brown edges',
  'scorch': 'Bleached or scorched patches',
  'spots': 'Brown or black leaf spots',
  'powder': 'White powder on leaves',
  'mushy': 'Soft, dark stem base',
  'slow': 'Slow growth, few flowers',
};

class Problem {
  const Problem({
    required this.id,
    required this.name,
    required this.signs,
    required this.symptoms,
    required this.steps,
    required this.caution,
    this.treatment = '',
    this.repeatDays = 0,
    this.courseDays = 0,
  });
  final String id;
  final String name;
  final String signs;
  final List<String> symptoms;
  final List<String> steps;
  final String caution;
  final String treatment; // repeating task name, '' for none
  final int repeatDays;
  final int courseDays;
}

const _sprayCaution = "Don't spray in full sun, and test on one leaf first. Keep sprays away from pets and children.";

const problems = <Problem>[
  Problem(
    id: 'mealybugs',
    name: 'Mealybugs',
    signs: 'White, cottony clusters on leaf undersides, stems and leaf joints. They suck sap and leave a sticky residue.',
    symptoms: ['white_cotton', 'sticky', 'yellow_lower', 'slow'],
    steps: [
      'Move the plant away from other plants for two weeks.',
      'Dab visible bugs with cotton dipped in a little rubbing alcohol, or wash them off with a strong spray of water.',
      'Spray leaves, especially undersides, with neem oil soap solution every 5–7 days, in the evening.',
      'Check new growth and leaf joints every few days. Ants on the plant often mean the pests are still there.',
    ],
    caution: _sprayCaution,
    treatment: 'Neem spray (mealybugs)',
    repeatDays: 6,
    courseDays: 28,
  ),
  Problem(
    id: 'aphids',
    name: 'Aphids',
    signs: 'Clusters of tiny green, black or yellow soft insects on new shoots and buds. New leaves curl and feel sticky.',
    symptoms: ['bugs_tips', 'curled', 'sticky'],
    steps: [
      'Wash them off with a strong spray of water, or rub them off with your fingers.',
      'Snip off badly infested tips.',
      'Spray neem oil soap solution every 5–7 days, in the evening, covering leaf undersides.',
      'Keep ants off the plant; they protect aphids.',
    ],
    caution: _sprayCaution,
    treatment: 'Neem spray (aphids)',
    repeatDays: 6,
    courseDays: 21,
  ),
  Problem(
    id: 'spider_mites',
    name: 'Spider mites',
    signs: 'Fine webbing and tiny pale speckles on leaves; undersides look dusty. Worse in hot, dry weather.',
    symptoms: ['webbing', 'speckles', 'crispy'],
    steps: [
      'Rinse the leaves, especially undersides, with water to knock mites off.',
      'Isolate the plant; mites spread easily.',
      'Spray neem oil or insecticidal soap every 5–7 days for at least three weeks.',
      'Remove leaves that are badly speckled or webbed.',
    ],
    caution: _sprayCaution,
    treatment: 'Rinse and neem spray (mites)',
    repeatDays: 5,
    courseDays: 21,
  ),
  Problem(
    id: 'scale',
    name: 'Scale insects',
    signs: 'Brown or tan bumps on stems and along leaf veins that do not move. Often with sticky leaves.',
    symptoms: ['bumps', 'sticky', 'yellow_lower'],
    steps: [
      'Scrape bumps off with a fingernail or an old soft toothbrush.',
      'Wipe stems with cotton dipped in a little rubbing alcohol.',
      'Spray neem or horticultural oil every 7 days to smother young scale.',
      'Check again after two weeks; scale often comes back.',
    ],
    caution: _sprayCaution,
    treatment: 'Wipe and oil spray (scale)',
    repeatDays: 7,
    courseDays: 28,
  ),
  Problem(
    id: 'whitefly',
    name: 'Whitefly',
    signs: 'Tiny white flying insects that rise in a cloud when you touch the plant. Leaves yellow and get sticky.',
    symptoms: ['white_flies', 'sticky', 'yellow_lower'],
    steps: [
      'Hang yellow sticky traps near the plant.',
      'Spray leaf undersides with water to knock off eggs and young.',
      'Spray neem oil soap solution every 5–7 days, in the evening.',
    ],
    caution: _sprayCaution,
    treatment: 'Neem spray (whitefly)',
    repeatDays: 6,
    courseDays: 21,
  ),
  Problem(
    id: 'overwatering',
    name: 'Overwatering or root rot',
    signs: 'Leaves yellow and droop even though the soil is wet. The stem base may be soft and dark, and the soil can smell sour.',
    symptoms: ['wilt_wet', 'yellow_lower', 'mushy', 'soil_flies'],
    steps: [
      'Stop watering until the top few cm of soil are dry.',
      'Make sure the pot has a drainage hole, and empty any saucer after watering.',
      'If the stem is mushy or the soil smells, unpot it: trim black, mushy roots with clean scissors and repot in fresh, well-draining mix.',
      'Water less often from now on and always check the soil first.',
    ],
    caution: 'A plant with most of its roots rotted may not recover. Take a healthy cutting as a backup.',
  ),
  Problem(
    id: 'underwatering',
    name: 'Underwatering',
    signs: 'Wilting with dry soil that pulls away from the pot edge. Leaf edges go crispy. It perks up after watering.',
    symptoms: ['wilt_dry', 'crispy'],
    steps: [
      'Water slowly until water drains out of the bottom.',
      'If water runs straight through, stand the pot in a bucket of water for 20–30 minutes.',
      'In summer, move balcony pots out of the harshest afternoon sun, or add mulch on top of the soil.',
    ],
    caution: 'Water a wilted plant in the evening or in shade, not in the midday sun.',
  ),
  Problem(
    id: 'sunburn',
    name: 'Sunburn (leaf scorch)',
    signs: 'Bleached, pale or brown patches on the leaves facing the sun, often after moving the plant to a sunnier spot.',
    symptoms: ['scorch', 'crispy'],
    steps: [
      'Move the plant to bright shade in the afternoon.',
      'When moving plants into more sun, do it gradually over one to two weeks.',
      'Remove badly burned leaves once new growth appears.',
    ],
    caution: 'Burned patches will not turn green again; judge recovery by the new leaves.',
  ),
  Problem(
    id: 'leaf_spot',
    name: 'Fungal leaf spot',
    signs: 'Brown or black spots, often with a yellow ring, that spread in humid or rainy weather.',
    symptoms: ['spots', 'yellow_lower'],
    steps: [
      'Pick off and throw away spotted leaves (not in compost).',
      'Water the soil, not the leaves, and water in the morning.',
      'Give the plant more space for air to move.',
      'If it keeps spreading, ask a nursery about a suitable fungicide and follow the label.',
    ],
    caution: 'Clean scissors after cutting infected leaves.',
  ),
  Problem(
    id: 'powdery_mildew',
    name: 'Powdery mildew',
    signs: 'A white or grey powder on the leaf surface that wipes off. Common on roses, chilli and gourds.',
    symptoms: ['powder', 'curled'],
    steps: [
      'Remove the worst affected leaves.',
      'Improve air flow and avoid wetting the leaves in the evening.',
      'Spray neem oil every 7 days to slow its spread.',
    ],
    caution: _sprayCaution,
    treatment: 'Neem spray (mildew)',
    repeatDays: 7,
    courseDays: 21,
  ),
  Problem(
    id: 'nitrogen',
    name: 'Hungry plant (low nitrogen)',
    signs: 'Older, lower leaves turn evenly pale yellow while new leaves stay green. Growth is slow.',
    symptoms: ['yellow_lower', 'slow'],
    steps: [
      'Feed with compost or a balanced liquid fertiliser at the dose on the label.',
      'Repeat monthly in the growing season.',
      'If the plant has been in the same pot for years, repot with fresh soil.',
    ],
    caution: 'More fertiliser is not better. Too much burns roots.',
  ),
  Problem(
    id: 'iron',
    name: 'Iron deficiency',
    signs: 'New leaves turn yellow while their veins stay green. Common in hibiscus, mogra and citrus.',
    symptoms: ['yellow_veins', 'slow'],
    steps: [
      'Use a micronutrient or chelated iron feed at the dose on the label.',
      'Avoid overwatering; waterlogged roots cannot take up iron.',
      'Add compost when repotting.',
    ],
    caution: 'Follow the label dose exactly for micronutrient feeds.',
  ),
  Problem(
    id: 'fungus_gnats',
    name: 'Fungus gnats',
    signs: 'Tiny dark flies around the soil surface. Their larvae live in soil that stays wet.',
    symptoms: ['soil_flies', 'wilt_wet'],
    steps: [
      'Let the top few cm of soil dry out between waterings.',
      'Put yellow sticky traps at soil level.',
      'Scrape off the top layer of soil and replace it with dry mix or sand.',
    ],
    caution: 'Gnats are a sign the soil stays too wet. Fix the watering first.',
  ),
];

Problem? problemById(String id) {
  for (final p in problems) {
    if (p.id == id) return p;
  }
  return null;
}

class ProblemMatch {
  const ProblemMatch(this.problem, this.score);
  final Problem problem;
  final int score;
}

/// Ranks problems by how many of the [picked] symptoms they explain.
/// Ties go to the problem with fewer signs overall (the more specific match).
List<ProblemMatch> matchProblems(Set<String> picked) {
  final out = <ProblemMatch>[];
  for (final p in problems) {
    final s = p.symptoms.where(picked.contains).length;
    if (s > 0) out.add(ProblemMatch(p, s));
  }
  out.sort((a, b) {
    final c = b.score.compareTo(a.score);
    if (c != 0) return c;
    return a.problem.symptoms.length.compareTo(b.problem.symptoms.length);
  });
  return out;
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

int daysBetween(String a, String b) => (parseIso(b).difference(parseIso(a)).inHours / 24).round();

const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String shortDate(String s) {
  final d = parseIso(s);
  return '${d.day} ${_mon[d.month - 1]}';
}

String dayName(String s) => _dow[parseIso(s).weekday - 1];

/// "today", "tomorrow", "yesterday" or "Fri, 3 Oct".
String relDay(String today, String s) {
  final n = daysBetween(today, s);
  if (n == 0) return 'today';
  if (n == 1) return 'tomorrow';
  if (n == -1) return 'yesterday';
  return '${dayName(s)}, ${shortDate(s)}';
}
