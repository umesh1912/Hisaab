import 'package:flutter/material.dart';

import 'logic.dart';
import 'screens/credits.dart';
import 'screens/discover.dart';
import 'screens/messages.dart';
import 'screens/onboarding.dart';
import 'screens/profile.dart';
import 'screens/swaps.dart';
import 'store.dart';
import 'ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = LendenStore()..load();
  runApp(LendenApp(store: store));
}

ThemeData buildTheme(Brightness b) {
  final cs = ColorScheme.fromSeed(seedColor: brand, brightness: b);
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

class LendenApp extends StatelessWidget {
  const LendenApp({super.key, required this.store});
  final LendenStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Lenden',
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

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final incoming = store.incomingCount;
    final unread = store.unreadThreads;
    const pages = [DiscoverScreen(), SwapsScreen(), MessagesScreen(), CreditsScreen(), ProfileScreen()];
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lenden', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    d.me.area.isEmpty ? 'Your neighbourhood' : d.me.area,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: 'Your time credits',
              child: ActionChip(
                avatar: Icon(Icons.hourglass_bottom, size: 18, color: cs.onPrimary),
                label: Text('${hrsText(store.balanceHrs)} hrs'),
                labelStyle: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w700),
                backgroundColor: cs.primary,
                side: BorderSide.none,
                onPressed: () => store.go(3),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: store.tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: store.tab,
        onDestinationSelected: (i) => store.go(i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Discover'),
          NavigationDestination(
            icon: Badge(isLabelVisible: incoming > 0, label: Text('$incoming'), child: const Icon(Icons.swap_horiz)),
            selectedIcon: Badge(isLabelVisible: incoming > 0, label: Text('$incoming'), child: const Icon(Icons.swap_horizontal_circle)),
            label: 'Swaps',
          ),
          NavigationDestination(
            icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.chat_bubble_outline)),
            selectedIcon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.chat_bubble)),
            label: 'Messages',
          ),
          const NavigationDestination(icon: Icon(Icons.hourglass_empty), selectedIcon: Icon(Icons.hourglass_full), label: 'Credits'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
