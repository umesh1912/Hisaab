import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/note_detail.dart';
import '../ui.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final tt = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            'Turn your class notes, PDFs or notebook into questions. Type each question with the line it came from, '
            'so you can always check it. New questions join tomorrow\'s revision.',
            style: tt.bodyMedium,
          ),
        ),
        if (d.notes.isEmpty)
          const EmptyState(
            icon: Icons.description_outlined,
            title: 'No notes yet',
            body: 'Tap "Add notes" to start a set of questions from a chapter you studied.',
          )
        else
          for (final n in d.notes)
            Card(
              child: ListTile(
                leading: IconBox(sectionIcons[n.sec] ?? Icons.description_outlined),
                title: Text(n.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Builder(builder: (context) {
                  final count = store.noteQuestions(n.id).length;
                  return Text('$count question${count == 1 ? '' : 's'} · ${sectionShort[n.sec]} · ${n.topic} · ${shortDate(n.at)}');
                }),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showNoteDetail(context, n.id),
              ),
            ),
      ],
    );
  }
}
