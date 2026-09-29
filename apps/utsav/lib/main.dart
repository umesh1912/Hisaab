import 'package:flutter/material.dart';

import 'logic.dart';
import 'screens/budget.dart';
import 'screens/guests.dart';
import 'screens/home.dart';
import 'screens/onboarding.dart';
import 'screens/tasks.dart';
import 'screens/vendors.dart';
import 'sheets/budget_line.dart';
import 'sheets/guest.dart';
import 'sheets/settings.dart';
import 'sheets/task.dart';
import 'sheets/vendor.dart';
import 'store.dart';
import 'ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = UtsavStore()..load();
  runApp(UtsavApp(store: store));
}

const seed = Color(0xFF7A1F3D);

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

class UtsavApp extends StatelessWidget {
  const UtsavApp({super.key, required this.store});
  final UtsavStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Utsav',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const Gate(),
      ),
    );
  }
}

/// Shows a splash while loading, onboarding when there is no wedding, and the app otherwise.
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

  static const _titles = ['Home', 'Guests', 'Tasks', 'Budget', 'Vendors'];

  void go(int i) => setState(() => tab = i);

  void goGuests(String eventId) {
    StoreScope.read(context).selectEvent(eventId);
    go(1);
  }

  Widget? _fab(BuildContext context) {
    switch (tab) {
      case 0:
      case 2:
        return FloatingActionButton.extended(
          onPressed: () => showTaskSheet(context),
          icon: const Icon(Icons.add_task),
          label: const Text('Task'),
        );
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => showGuestSheet(context),
          icon: const Icon(Icons.group_add_outlined),
          label: const Text('Family'),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: () => showBudgetLineSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Category'),
        );
      case 4:
        return FloatingActionButton.extended(
          onPressed: () => showVendorSheet(context),
          icon: const Icon(Icons.add_business_outlined),
          label: const Text('Vendor'),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final today = todayIso();
    final waiting = familiesWaiting(d.guests);
    final late = d.tasks.where((t) => isOverdue(t, today)).length;
    final pages = [
      HomeScreen(onGo: go, onGuests: goGuests),
      const GuestsScreen(),
      const TasksScreen(),
      const BudgetScreen(),
      const VendorsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: tab == 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Utsav', style: TextStyle(fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
                  Text(
                    "${d.couple}'s wedding",
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            : Text(_titles[tab], style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Wedding settings',
            icon: const Icon(Icons.tune),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
        bottom: const PreferredSize(preferredSize: Size.fromHeight(14), child: Toran()),
      ),
      body: IndexedStack(index: tab, children: pages),
      floatingActionButton: _fab(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: go,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.local_florist_outlined), selectedIcon: Icon(Icons.local_florist), label: 'Home'),
          NavigationDestination(
            icon: Badge.count(count: waiting, isLabelVisible: waiting > 0, child: const Icon(Icons.groups_outlined)),
            selectedIcon: Badge.count(count: waiting, isLabelVisible: waiting > 0, child: const Icon(Icons.groups)),
            label: 'Guests',
          ),
          NavigationDestination(
            icon: Badge.count(count: late, isLabelVisible: late > 0, child: const Icon(Icons.task_alt_outlined)),
            selectedIcon: Badge.count(count: late, isLabelVisible: late > 0, child: const Icon(Icons.task_alt)),
            label: 'Tasks',
          ),
          const NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Budget'),
          const NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Vendors'),
        ],
      ),
    );
  }
}
