import 'package:flutter/material.dart';

import 'logic.dart';
import 'screens/feed.dart';
import 'screens/inbox.dart';
import 'screens/lost_found.dart';
import 'screens/map.dart';
import 'screens/onboarding.dart';
import 'screens/you.dart';
import 'sheets/new_post.dart';
import 'sheets/notifications.dart';
import 'store.dart';
import 'ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = GalliStore()..load();
  runApp(GalliApp(store: store));
}

const seed = Color(0xFFF2551D);

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

class GalliApp extends StatelessWidget {
  const GalliApp({super.key, required this.store});
  final GalliStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Galli',
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

  void go(int i) => setState(() => tab = i);

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final unreadThreads = store.unreadThreads;
    final unreadNotifs = store.unreadNotifs;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'GALLI'),
                  TextSpan(text: '.', style: TextStyle(color: cs.primary)),
                ],
              ),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 0.5),
            ),
            Text(
              '${d.locality.isEmpty ? 'Near you' : d.locality} · within ${radiusLabel(d.radius)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => showNotifications(context),
            icon: Badge(
              isLabelVisible: unreadNotifs > 0,
              label: Text('$unreadNotifs'),
              child: const Icon(Icons.notifications_none),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: GestureDetector(
              onTap: () => go(4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: cs.primary,
                child: Text(
                  d.name.isEmpty ? '?' : d.name[0].toUpperCase(),
                  style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: tab,
        children: const [FeedScreen(), MapScreen(), LostFoundScreen(), InboxScreen(), YouScreen()],
      ),
      floatingActionButton: tab <= 2
          ? FloatingActionButton.extended(
              onPressed: () => showNewPost(context, onPosted: () => go(0)),
              icon: const Icon(Icons.add),
              label: const Text('Post'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: go,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.view_agenda_outlined), selectedIcon: Icon(Icons.view_agenda), label: 'Nearby'),
          const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          const NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Lost'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadThreads > 0,
              label: Text('$unreadThreads'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadThreads > 0,
              label: Text('$unreadThreads'),
              child: const Icon(Icons.chat_bubble),
            ),
            label: 'Inbox',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'You'),
        ],
      ),
    );
  }
}
