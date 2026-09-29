import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/task.dart';
import '../ui.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final open = openTasks(d.tasks);
    final done = d.tasks.where((t) => t.done).toList()..sort((a, b) => b.due.compareTo(a.due));
    final people = workload(d.tasks);

    if (d.tasks.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: const [
          EmptyState(
            icon: Icons.task_alt,
            title: 'No tasks yet',
            body: 'Add tasks for each function and hand them out to relatives. Send them their list on WhatsApp.',
          ),
        ],
      );
    }

    Widget count(int n) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text('$n', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
        );

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      children: [
        const NoteBanner(
          icon: Icons.shield_outlined,
          text: "Relatives don't need the app. Send each person their own task list on WhatsApp from Who's doing what.",
        ),
        SectionTitle('To do', trailing: count(open.length)),
        if (open.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('All done. Nice work.', style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          Card(child: Column(children: [for (final t in open) TaskTile(task: t)])),
        if (done.isNotEmpty) ...[
          SectionTitle('Done', trailing: count(done.length)),
          Card(child: Column(children: [for (final t in done) TaskTile(task: t)])),
        ],
        const SectionTitle("Who's doing what"),
        Card(
          child: Column(
            children: [
              for (final w in people)
                ListTile(
                  leading: Initial(w.who),
                  title: Text(w.who, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${w.open} open · ${w.done} done'),
                  trailing: w.who == 'You' || w.open == 0
                      ? null
                      : IconButton(
                          tooltip: 'Send ${w.who} their tasks',
                          icon: const Icon(Icons.send_outlined),
                          onPressed: () => openWhatsApp(context, taskListMessage(d, w.who), phone: d.helper(w.who)?.phone ?? ''),
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One task with a tick box; tap to edit.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task});
  final WTask task;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final today = todayIso();
    final late = isOverdue(task, today);
    final t = task;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 4, right: 16),
      leading: Checkbox(
        value: t.done,
        onChanged: (_) {
          final nowDone = store.toggleTask(t.id);
          if (nowDone) toast(context, t.who == 'You' ? 'Done.' : 'Done. Remember to thank ${t.who}.');
        },
      ),
      title: Text(
        t.title,
        style: t.done ? TextStyle(decoration: TextDecoration.lineThrough, color: cs.onSurfaceVariant) : null,
      ),
      subtitle: Text.rich(
        TextSpan(children: [
          TextSpan(text: '${t.who} · ${d.eventName(t.ev)} · '),
          TextSpan(
            text: late ? '${dueText(daysBetween(today, t.due))}, was due ${shortDate(t.due)}' : 'due ${shortDate(t.due)}',
            style: late ? TextStyle(color: cs.error, fontWeight: FontWeight.w800) : null,
          ),
        ]),
      ),
      onTap: () => showTaskSheet(context, id: t.id),
    );
  }
}
