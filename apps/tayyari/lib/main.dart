import 'package:flutter/material.dart';

import 'screens/notes.dart';
import 'screens/onboarding.dart';
import 'screens/practice.dart';
import 'screens/progress.dart';
import 'screens/syllabus.dart';
import 'screens/today.dart';
import 'sheets/add_mock.dart';
import 'sheets/add_note.dart';
import 'sheets/profile.dart';
import 'store.dart';
import 'ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = TayyariStore()..load();
  runApp(TayyariApp(store: store));
}

const seed = Color(0xFF2B44C8);

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

class TayyariApp extends StatelessWidget {
  const TayyariApp({super.key, required this.store});
  final TayyariStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Tayyari',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const Gate(),
      ),
    );
  }
}

/// Shows a splash while loading, onboarding when there is no profile, and the app otherwise.
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

class _ShellState extends State<Shell> {
  int tab = 0;

  static const _titles = ['Today', 'Practice', 'Syllabus', 'Your notes', 'Progress'];

  void go(int i) => setState(() => tab = i);

  Widget? _fab(BuildContext context) {
    switch (tab) {
      case 3:
        return FloatingActionButton.extended(
          onPressed: () => showAddNote(context),
          icon: const Icon(Icons.note_add_outlined),
          label: const Text('Add notes'),
        );
      case 4:
        return FloatingActionButton.extended(
          onPressed: () => showAddMock(context),
          icon: const Icon(Icons.add_chart),
          label: const Text('Add mock score'),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    if (d == null) return const Scaffold(); // just reset; Gate swaps to onboarding
    final cs = Theme.of(context).colorScheme;
    final p = d.profile;
    final dueCount = store.due.length;
    final pages = [
      TodayScreen(onGo: go),
      PracticeScreen(onGo: go),
      const SyllabusScreen(),
      const NotesScreen(),
      const ProgressScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: tab == 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tayyari', style: TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    '${p.exam} · ${p.name}${p.city.isEmpty ? '' : ', ${p.city}'}',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : Text(_titles[tab], style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Tooltip(
            message: 'Switch language',
            child: TextButton(
              onPressed: store.toggleLang,
              child: Text(store.hindi ? 'English' : 'हिंदी', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => showProfile(context),
            icon: CircleAvatar(
              radius: 15,
              backgroundColor: cs.primary,
              child: Text(
                p.name.trim().isEmpty ? '?' : p.name.trim()[0].toUpperCase(),
                style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: tab, children: pages),
      floatingActionButton: _fab(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: go,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Today'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: dueCount > 0 && store.session == null,
              label: Text('$dueCount'),
              child: const Icon(Icons.task_alt_outlined),
            ),
            selectedIcon: const Icon(Icons.task_alt),
            label: 'Practice',
          ),
          const NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Syllabus'),
          const NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Notes'),
          const NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Progress'),
        ],
      ),
    );
  }
}
