import 'package:flutter/material.dart';

import 'screens/balances.dart';
import 'screens/chores.dart';
import 'screens/expenses.dart';
import 'screens/home.dart';
import 'screens/onboarding.dart';
import 'screens/shopping.dart';
import 'sheets/add_chore.dart';
import 'sheets/add_expense.dart';
import 'sheets/flat.dart';
import 'store.dart';
import 'ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = HisaabStore()..load();
  runApp(HisaabApp(store: store));
}

const seed = Color(0xFF1E5C4A);

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

class HisaabApp extends StatelessWidget {
  const HisaabApp({super.key, required this.store});
  final HisaabStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Hisaab',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const Gate(),
      ),
    );
  }
}

/// Shows a splash while loading, onboarding when there is no flat, and the app otherwise.
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

  static const _titles = ['Home', 'Expenses', 'Shopping list', 'Chores', 'Balances'];

  void go(int i) => setState(() => tab = i);

  Widget? _fab(BuildContext context) {
    switch (tab) {
      case 0:
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => showAddExpense(context),
          icon: const Icon(Icons.add),
          label: const Text('Add expense'),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: () => showAddChore(context),
          icon: const Icon(Icons.add_task),
          label: const Text('Add chore'),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final pages = [
      HomeScreen(onGo: go),
      const ExpensesScreen(),
      const ShoppingScreen(),
      const ChoresScreen(),
      const BalancesScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: tab == 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.flatName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${d.members.length} flatmates', style: Theme.of(context).textTheme.bodySmall),
                ],
              )
            : Text(_titles[tab], style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Flat settings',
            icon: const Icon(Icons.group_outlined),
            onPressed: () => showFlatSheet(context),
          ),
        ],
      ),
      body: IndexedStack(index: tab, children: pages),
      floatingActionButton: _fab(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: go,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'List'),
          NavigationDestination(icon: Icon(Icons.cleaning_services_outlined), selectedIcon: Icon(Icons.cleaning_services), label: 'Chores'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Balances'),
        ],
      ),
    );
  }
}
