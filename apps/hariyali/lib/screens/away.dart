import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic.dart';
import '../sheets/trip.dart';
import '../ui.dart';

class AwayScreen extends StatelessWidget {
  const AwayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final t = d.trip;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final intro = PageTitle(
      'Going away?',
      sub: 'Hariyali writes simple care notes for whoever looks after your plants, planned around each plant\'s needs and the season.',
    );

    if (t == null) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          intro,
          const EmptyState(
            icon: Icons.luggage_outlined,
            title: 'No trip planned',
            body: 'Add your dates and your helper\'s name to get a care note you can send on WhatsApp.',
          ),
          Center(
            child: FilledButton.icon(
              onPressed: () => showTripSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Plan a trip'),
            ),
          ),
        ],
      );
    }

    final note = careNote(plants: d.plants, trip: t, season: d.season, owner: d.ownerName);
    final days = daysBetween(t.from, t.to) + 1;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        intro,
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoRow('Away', '${shortDate(t.from)} to ${shortDate(t.to)} · ${plural(days, 'day')}'),
                InfoRow('Helper', t.helper),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('English')),
                    ButtonSegment(value: 'ta', label: Text('தமிழ்')),
                  ],
                  selected: {t.lang},
                  onSelectionChanged: (s) => store.setTripLang(s.first),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                  child: SelectableText(note, style: tt.bodyMedium),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        launchUrl(
                          Uri.parse('https://wa.me/?text=${Uri.encodeComponent(note)}'),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Send on WhatsApp'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: note));
                        if (context.mounted) toast(context, 'Care note copied');
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                    TextButton(onPressed: () => showTripSheet(context), child: const Text('Edit trip')),
                    TextButton(
                      onPressed: () async {
                        final ok = await confirm(context, 'Clear this trip?', 'Clear');
                        if (ok) store.setTrip(null);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: NoteBox(
            'The note assumes you water everything well the day before you leave. Also move balcony pots out of the harshest afternoon sun, and group indoor plants together to keep them humid.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            'Plant names stay as you typed them. Tamil notes use simple fixed phrases; read them over before sending.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
