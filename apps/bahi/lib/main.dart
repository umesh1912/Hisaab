import 'package:flutter/material.dart';

import 'logic.dart';
import 'screens/collect.dart';
import 'screens/khata.dart';
import 'screens/onboarding.dart';
import 'screens/report.dart';
import 'screens/today.dart';
import 'sheets/settings.dart';
import 'store.dart';
import 'ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = BahiStore()..load();
  runApp(BahiApp(store: store));
}

const seed = brandRed;

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
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    ),
  );
}

class BahiApp extends StatelessWidget {
  const BahiApp({super.key, required this.store});
  final BahiStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Bahi',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const Gate(),
      ),
    );
  }
}

/// Shows a splash while loading, onboarding when there is no shop, and the register otherwise.
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
    final en = d.en;
    final today = todayIso();
    final overdue = d.customers.where((c) => isOverdue(c, today) && !promiseActive(c, today)).length;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              en ? 'Bahi' : 'बही',
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24, height: 1.1),
            ),
            Text(
              d.shop.display(en),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('lang'),
            onPressed: () => store.setLang(en ? 'hi' : 'en'),
            child: Text(en ? 'हिंदी' : 'English'),
          ),
          IconButton(
            tooltip: en ? 'Settings' : 'सेटिंग',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: tab,
        children: [
          const KhataScreen(),
          const TodayScreen(),
          const CollectScreen(),
          const ReportScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: go,
        destinations: [
          NavigationDestination(
            key: const ValueKey('nav-khata'),
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: en ? 'Khata' : 'खाता',
          ),
          NavigationDestination(
            key: const ValueKey('nav-today'),
            icon: const Icon(Icons.point_of_sale_outlined),
            selectedIcon: const Icon(Icons.point_of_sale),
            label: en ? 'Today' : 'आज',
          ),
          NavigationDestination(
            key: const ValueKey('nav-collect'),
            icon: Badge(
              isLabelVisible: overdue > 0,
              label: Text('$overdue'),
              child: const Icon(Icons.mark_chat_unread_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: overdue > 0,
              label: Text('$overdue'),
              child: const Icon(Icons.mark_chat_unread),
            ),
            label: en ? 'Collect' : 'वसूली',
          ),
          NavigationDestination(
            key: const ValueKey('nav-report'),
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: en ? 'Report' : 'हिसाब',
          ),
        ],
      ),
    );
  }
}
