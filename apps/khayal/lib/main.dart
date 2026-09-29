import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/family.dart';
import 'screens/health.dart';
import 'screens/meds.dart';
import 'screens/onboarding.dart';
import 'screens/parent_mode.dart';
import 'screens/refills.dart';
import 'screens/today.dart';
import 'sheets/add_med.dart';
import 'sheets/settings.dart';
import 'store.dart';
import 'ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = KhayalStore()..load();
  runApp(KhayalApp(store: store));
}

const seed = Color(0xFF1D5C7A);

ThemeData buildTheme(Brightness b) {
  final cs = ColorScheme.fromSeed(seedColor: seed, brightness: b);
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: cs.surface,
    appBarTheme: AppBarTheme(backgroundColor: cs.surface, surfaceTintColor: Colors.transparent, centerTitle: false),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cs.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    ),
  );
}

class KhayalApp extends StatelessWidget {
  const KhayalApp({super.key, required this.store});
  final KhayalStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Khayal',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const Gate(),
      ),
    );
  }
}

/// Shows a splash while loading, onboarding when nothing is set up, and the app otherwise.
class Gate extends StatelessWidget {
  const Gate({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    if (!store.loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (store.data == null) return const OnboardingScreen();
    return const Shell();
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int tab = 0;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Doses turn "due" and "missed" as time passes, so redraw every minute.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) StoreScope.read(context).tick();
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) StoreScope.read(context).tick();
  }

  void go(int i) => setState(() => tab = i);

  Widget? _fab(BuildContext context) {
    if (tab != 0 && tab != 1) return null;
    return FloatingActionButton.extended(
      onPressed: () => showMedForm(context),
      icon: const Icon(Icons.add),
      label: const Text('Medicine'),
    );
  }

  Widget _badged(IconData icon, int n) {
    return Badge(isLabelVisible: n > 0, label: Text('$n'), child: Icon(icon));
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final missed = store.missedNow().length;
    final low = store.lowCount;
    final names = d.parents.map((p) => p.name).join(' and ');
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Khayal', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              'Looking after $names',
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Parent's phone",
            icon: const Icon(Icons.phone_android),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => ParentModeScreen(parentId: store.current.id)),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showSettings(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: tab,
        children: [
          TodayScreen(onGo: go),
          const MedsScreen(),
          const RefillsScreen(),
          const HealthScreen(),
          const FamilyScreen(),
        ],
      ),
      floatingActionButton: _fab(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: go,
        destinations: [
          NavigationDestination(icon: _badged(Icons.schedule, missed), label: 'Today'),
          const NavigationDestination(icon: Icon(Icons.medication_outlined), selectedIcon: Icon(Icons.medication), label: 'Medicines'),
          NavigationDestination(icon: _badged(Icons.inventory_2_outlined, low), label: 'Refills'),
          const NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), selectedIcon: Icon(Icons.monitor_heart), label: 'Health'),
          const NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Family'),
        ],
      ),
    );
  }
}
