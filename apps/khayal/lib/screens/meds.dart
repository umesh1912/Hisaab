import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/med_detail.dart';
import '../sheets/parent_edit.dart';
import '../ui.dart';

class MedsScreen extends StatelessWidget {
  const MedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final p = store.current;
    final meds = d.meds.where((m) => m.who == p.id).toList()
      ..sort((a, b) {
        final ta = a.times.isEmpty ? 0 : mins(a.times.first);
        final tb = b.times.isEmpty ? 0 : mins(b.times.first);
        return ta.compareTo(tb);
      });
    final about = [
      if (p.full.isNotEmpty) p.full,
      if (p.age > 0) '${p.age}',
    ].join(', ');

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        const WhoSwitch(),
        SectionTitle("${p.name}'s medicines · ${meds.length} active"),
        if (meds.isEmpty)
          EmptyState(
            icon: Icons.medication_outlined,
            title: 'No medicines for ${p.name}',
            body: 'Add each medicine from the prescription or the strip, with the times the doctor gave.',
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < meds.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    leading: PillDot(meds[i].color, size: 28),
                    title: Text(meds[i].title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${meds[i].purpose} · ${meds[i].times.map(t12).join(', ')} · ${foodText(meds[i].food)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showMedDetail(context, meds[i].id),
                  ),
                ],
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: InfoNote("Khayal never changes a prescription. Any change to doses should come from ${p.name}'s doctor."),
        ),
        const SectionTitle('About'),
        Card(
          child: ListTile(
            leading: Avatar(name: p.name, color: Color(p.color)),
            title: Text(about.isEmpty ? p.name : about),
            subtitle: Text(
              [
                if (p.conditions.isNotEmpty) p.conditions,
                if (p.phone.isNotEmpty) p.phone,
              ].join(' · ').ifEmpty('Add conditions and phone number'),
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => showParentEdit(context, p.id),
          ),
        ),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
