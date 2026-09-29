import 'package:flutter/material.dart';

import '../logic.dart';
import '../sheets/chat.dart';
import '../ui.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final blocked = store.blockedSet;
    final now = DateTime.now();
    final ids = d.threads.keys
        .where((id) => !blocked.contains(id) && d.person(id) != null && (d.threads[id] ?? const <Message>[]).isNotEmpty)
        .toList()
      ..sort((a, b) => d.threads[b]!.last.at.compareTo(d.threads[a]!.last.at));

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text('Messages', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
        if (ids.isEmpty)
          const EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No chats yet',
            body: 'Open someone on Discover and tap Message to say hello.',
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final id in ids) _ThreadTile(person: d.person(id)!, thread: d.threads[id]!, now: now),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            'Chats stay inside Lenden until you choose to share a number. Report anyone who asks for money or OTPs.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.person, required this.thread, required this.now});
  final Person person;
  final List<Message> thread;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final last = thread.last;
    final unread = thread.any((m) => m.unread);
    return ListTile(
      onTap: () => showChat(context, person.id),
      leading: PersonAvatar(person),
      title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        '${last.me ? 'You: ' : ''}${last.text}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: unread ? cs.onSurface : cs.onSurfaceVariant,
          fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(msgTime(last.at, now), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          if (unread) ...[
            const SizedBox(height: 4),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
          ],
        ],
      ),
    );
  }
}
