import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Check-in code, then "Mark session done", then the rating form.
Future<void> showCheckIn(BuildContext context, int sessionId) =>
    showAppSheet(context, (_) => _SessionSheet(sessionId: sessionId, rateOnly: false));

Future<void> showRate(BuildContext context, int sessionId) =>
    showAppSheet(context, (_) => _SessionSheet(sessionId: sessionId, rateOnly: true));

class _SessionSheet extends StatefulWidget {
  const _SessionSheet({required this.sessionId, required this.rateOnly});
  final int sessionId;
  final bool rateOnly;

  @override
  State<_SessionSheet> createState() => _SessionSheetState();
}

class _SessionSheetState extends State<_SessionSheet> {
  final _review = TextEditingController();
  bool _justDone = false;
  int _stars = 5;
  final Set<String> _tags = {'On time'};

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    final s = d?.session(widget.sessionId);
    final p = s == null ? null : d?.person(s.withId);
    if (d == null || s == null || p == null) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('This session is no longer available.'));
    }
    final rating = widget.rateOnly || _justDone || s.status == 'done';
    return rating ? _rateView(context, d, s, p) : _checkInView(context, d, s, p);
  }

  Widget _checkInView(BuildContext context, AppData d, Session s, Person p) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final inPerson = s.mode == 'In person';
    final contact = d.me.contactName.isEmpty ? 'your trusted contact' : d.me.contactName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetTitle('Check in'),
        Text(
          'When you meet ${p.first}, show this code. ${p.first} enters it in their app, which confirms you are both there.',
          style: tt.bodyLarge,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(18)),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              checkInCode(s.id),
              style: tt.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 12, color: cs.onPrimaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SummaryBox([
          (s.isLearn ? 'Learning' : 'Teaching', s.skill),
          ('With', p.name),
          ('Length', '${hrsText(s.hrs)} hr'),
          ('When', '${dayName(s.date)} ${shortDate(s.date)}, ${t12(s.time)}'),
          ('Where', s.place),
        ]),
        if (inPerson) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(
                onPressed: () => openExternal(context, mapsUrl(s.place)),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Directions'),
              ),
              if (d.me.share)
                OutlinedButton.icon(
                  onPressed: () => openExternal(
                    context,
                    whatsAppUrl(
                      'Hi, I am at a Lenden session: ${s.skill} with ${p.name}, '
                      '${dayName(s.date)} ${shortDate(s.date)} at ${t12(s.time)}, ${s.place}. '
                      'Check-in code ${checkInCode(s.id)}. I will message you when it is done.',
                      phone: d.me.contactPhone,
                    ),
                  ),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Tell trusted contact'),
                ),
            ],
          ),
          if (d.me.share) ...[
            const SizedBox(height: 8),
            InfoNote('Share the time and place with $contact on WhatsApp before you go.'),
          ],
        ],
        const SizedBox(height: 18),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            StoreScope.read(context).completeSession(s.id);
            setState(() => _justDone = true);
          },
          child: const Text('Mark session done'),
        ),
      ],
    );
  }

  Widget _rateView(BuildContext context, AppData d, Session s, Person p) {
    final cs = Theme.of(context).colorScheme;
    final tags = s.isLearn
        ? const ['On time', 'Clear explanations', 'Patient', 'Well prepared', 'Would learn again']
        : const ['On time', 'Keen learner', 'Did the practice', 'Friendly', 'Would teach again'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle('Rate ${p.first}'),
        if (_justDone) ...[
          InfoNote(
            'Session done. ${signedHrs(s.isLearn ? -s.hrs : s.hrs)} hr ${s.isLearn ? 'spent from' : 'added to'} your credits.',
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'How was ${s.skill.toLowerCase()} with ${p.first}?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var n = 1; n <= 5; n++)
              IconButton(
                tooltip: '$n star${n > 1 ? 's' : ''}',
                onPressed: () => setState(() => _stars = n),
                icon: Icon(
                  n <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 34,
                  color: n <= _stars ? starColor(context) : cs.outline,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            for (final t in tags)
              FilterChip(
                label: Text(t),
                selected: _tags.contains(t),
                onSelected: (v) => setState(() => v ? _tags.add(t) : _tags.remove(t)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _review,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Review (optional)', hintText: 'What stood out?'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () {
            final written = _review.text.trim();
            final text = written.isNotEmpty ? written : tags.where(_tags.contains).join(' · ');
            StoreScope.read(context).rateSession(s.id, _stars, text);
            Navigator.pop(context);
            toast(context, 'Thanks. Your review is on ${p.first}\'s profile.');
          },
          child: const Text('Post review'),
        ),
        if (_justDone)
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Rate later')),
      ],
    );
  }
}
