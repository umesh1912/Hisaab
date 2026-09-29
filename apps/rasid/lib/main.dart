import 'package:flutter/material.dart';

import 'logic.dart';
import 'screens/claims.dart';
import 'screens/home.dart';
import 'screens/onboarding.dart';
import 'screens/reminders.dart';
import 'screens/vault.dart';
import 'screens/you.dart';
import 'sheets/alerts.dart';
import 'sheets/item_form.dart';
import 'store.dart';
import 'ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = RasidStore()..load();
  runApp(RasidApp(store: store));
}

const seed = Color(0xFF2B55F0);

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

class RasidApp extends StatelessWidget {
  const RasidApp({super.key, required this.store});
  final RasidStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Rasid',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const Gate(),
      ),
    );
  }
}

/// Shows a splash while loading, onboarding when there is no vault, and the app otherwise.
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

  static const _titles = ['Rasid', 'Vault', 'Repairs and claims', 'Reminders', 'You'];

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final tab = store.tab;
    final today = todayIso();
    final alerts = alertReminders(d.reminders, today).length;
    final openClaims = d.claims.where((c) => c.isOpen).length;
    const pages = [HomeScreen(), VaultScreen(), ClaimsScreen(), RemindersScreen(), YouScreen()];

    return Scaffold(
      appBar: AppBar(
        title: tab == 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rasid', style: TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    [
                      if (d.homeName.isNotEmpty) d.homeName,
                      if (d.members.length > 1) 'shared with ${d.members.where((m) => m.id != d.meId).map((m) => m.name).join(', ')}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            : Text(_titles[tab], style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Alerts',
            onPressed: () => showAlerts(context),
            icon: Badge(
              isLabelVisible: alerts > 0,
              label: Text('$alerts'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: tab, children: pages),
      floatingActionButton: tab <= 1
          ? FloatingActionButton.extended(
              onPressed: () => showItemForm(context),
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Add bill'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: store.goTab,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Vault'),
          NavigationDestination(
            icon: Badge(isLabelVisible: openClaims > 0, label: Text('$openClaims'), child: const Icon(Icons.build_outlined)),
            selectedIcon: Badge(isLabelVisible: openClaims > 0, label: Text('$openClaims'), child: const Icon(Icons.build)),
            label: 'Claims',
          ),
          const NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Reminders'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'You'),
        ],
      ),
    );
  }
}
