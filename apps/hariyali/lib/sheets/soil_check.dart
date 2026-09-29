import 'package:flutter/material.dart';

import '../ui.dart';

/// Asks how the soil feels before watering, then records the answer.
Future<void> showSoilCheck(BuildContext context, int plantId) =>
    showAppSheet(context, (_) => _SoilCheck(plantId: plantId));

class _SoilCheck extends StatelessWidget {
  const _SoilCheck({required this.plantId});
  final int plantId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final p = store.data?.plant(plantId);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    if (p == null) return const Padding(padding: EdgeInsets.all(24), child: Text('This plant was removed.'));

    void answer(String a) {
      final msg = store.soilCheck(plantId, a);
      Navigator.pop(context);
      toast(context, msg);
    }

    Widget option(String key, IconData icon, String title, String sub) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: OutlinedButton(
          key: Key('soil-$key'),
          onPressed: () => answer(key),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.centerLeft,
          ),
          child: Row(
            children: [
              Icon(icon, color: key == 'damp' ? cs.primary : waterColor(context)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
                    Text(sub, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(p.name, sub: p.place),
        Text('Before watering, push a finger 2–3 cm into the soil. How does it feel?', style: tt.bodyLarge),
        const SizedBox(height: 16),
        option('dry', Icons.water_drop, 'Dry', 'Water now'),
        option('very_dry', Icons.water_drop_outlined, 'Very dry, plant drooping', 'Water now and check sooner next time'),
        option('damp', Icons.hourglass_bottom, 'Still damp', 'Wait 2 days'),
        const SizedBox(height: 6),
        Text(
          'Overwatering is a common reason houseplants fail. Checking first protects the roots, and your answers tune how often Hariyali asks.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
