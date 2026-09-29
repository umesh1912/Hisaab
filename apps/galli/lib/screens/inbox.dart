import 'package:flutter/material.dart';

import '../sheets/thread.dart';
import '../ui.dart';

/// Private conversations started from posts (claims, replies, sightings).
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data!;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const ScreenTitle('Inbox'),
        if (d.threads.isEmpty)
          const EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No conversations yet',
            body: 'When you reply to a post or claim something you lost, the conversation shows up here.',
          )
        else
          for (final t in d.threads)
            Card(
              child: ListTile(
                onTap: () => showThread(context, t.id),
                leading: CircleAvatar(
                  backgroundColor: typeColor(context, d.post(t.postId)?.type ?? 'notice'),
                  child: Text(
                    t.withName.isEmpty ? '?' : t.withName[0].toUpperCase(),
                    style: TextStyle(color: onTypeColor(context), fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(t.withName, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  t.msgs.isEmpty ? 'No messages yet' : '${t.msgs.last.me ? 'You: ' : ''}${t.msgs.last.text}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.unread ? TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700) : null,
                ),
                trailing: t.unread ? Icon(Icons.circle, size: 12, color: cs.primary) : null,
              ),
            ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: NoteBox(
            icon: Icons.shield_outlined,
            text: "Replies stay inside Galli. Neither side sees the other's number unless they choose to share it.",
          ),
        ),
      ],
    );
  }
}
