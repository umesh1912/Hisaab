import 'package:flutter/material.dart';

import '../ui.dart';

class MatchProfile {
  const MatchProfile(this.name, this.place, this.goal, this.languages, this.time, this.category);
  final String name;
  final String place;
  final String goal;
  final String languages;
  final String time;
  final String category;
}

const matchCategories = ['Running', 'Reading', 'Mind', 'Fitness'];

/// Sample profiles: stranger matching needs Jodi's online service, which this offline build doesn't have.
const matchProfiles = [
  MatchProfile('Meera', 'Pune · IST', 'Run 5 km, 4× a week', 'Hindi, English', '6:00 AM', 'Running'),
  MatchProfile('Kabir', 'Bengaluru · IST', 'Couch to 5K', 'English, Kannada', '7:00 AM', 'Running'),
  MatchProfile('Sana', 'Mumbai · IST', 'Run 3 km, 3× a week', 'Hindi, English, Urdu', '6:30 AM', 'Running'),
  MatchProfile('Arjun', 'Chennai · IST', 'Read 30 pages a day', 'Tamil, English', '10:00 PM', 'Reading'),
  MatchProfile('Nidhi', 'Kolkata · IST', 'One book a month', 'Bengali, Hindi, English', '9:30 PM', 'Reading'),
  MatchProfile('Zoya', 'Hyderabad · IST', 'Meditate 10 min', 'Urdu, Telugu, English', '6:45 AM', 'Mind'),
  MatchProfile('Dev', 'Jaipur · IST', 'Journal three lines', 'Hindi, English', '11:00 PM', 'Mind'),
  MatchProfile('Riya', 'Ahmedabad · IST', '20 push-ups daily', 'Gujarati, Hindi, English', '7:30 AM', 'Fitness'),
  MatchProfile('Farhan', 'Lucknow · IST', 'Yoga 3× a week', 'Hindi, Urdu, English', '6:15 AM', 'Fitness'),
];

Future<void> showFindPartner(BuildContext context) => showAppSheet(context, (_) => const FindPartnerSheet());

class FindPartnerSheet extends StatefulWidget {
  const FindPartnerSheet({super.key});

  @override
  State<FindPartnerSheet> createState() => _FindPartnerSheetState();
}

class _FindPartnerSheetState extends State<FindPartnerSheet> {
  String category = matchCategories.first;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    if (d == null) return const SizedBox(height: 120);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final list = matchProfiles.where((m) => m.category == category).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle(
          'Find a partner',
          sub: 'Matches share your goal, check in at similar times and speak your language. You only see first names and goals.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final c in matchCategories)
              ChoiceChip(label: Text(c), selected: category == c, onSelected: (_) => setState(() => category = c)),
          ],
        ),
        const SizedBox(height: 12),
        for (final m in list)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(m.name, overflow: TextOverflow.ellipsis, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(99)),
                      child: Text(m.time, style: tt.labelMedium?.copyWith(color: cs.onPrimaryContainer)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${m.place} · ${m.goal} · ${m.languages}', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                d.matchRequests.contains(m.name)
                    ? OutlinedButton.icon(
                        onPressed: () => store.cancelMatch(m.name),
                        icon: const Icon(Icons.hourglass_top, size: 18),
                        label: const Text('Requested · cancel'),
                      )
                    : OutlinedButton(
                        onPressed: () {
                          store.requestMatch(m.name);
                          toast(context, 'Request sent to ${m.name}. You’ll start a 2-week trial pairing if they accept.');
                        },
                        child: const Text('Ask to pair up'),
                      ),
              ],
            ),
          ),
        Callout(
          icon: Icons.shield_outlined,
          child: Text(
            'Partners from matching can’t see your location, photos or contacts. Report or leave at any time. '
            'These are sample profiles; live matching needs Jodi’s online service.',
            style: tt.bodySmall,
          ),
        ),
      ],
    );
  }
}
