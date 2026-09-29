import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'post_detail.dart';

/// Shows the notification list and marks everything read.
Future<void> showNotifications(BuildContext context) {
  final store = StoreScope.read(context);
  // Take the list before marking read so new ones can be highlighted.
  final unread = store.visibleNotifs.where((n) => !n.read).toSet();
  store.markNotifsRead();
  return showAppSheet(context, (_) => _NotifSheet(unread: unread));
}

class _NotifSheet extends StatelessWidget {
  const _NotifSheet({required this.unread});
  final Set<Notif> unread;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    if (d == null) return const SizedBox(height: 120);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final list = store.visibleNotifs;
    final now = store.now;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Notifications', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          'Galli keeps these on your phone. Choose what shows here under You.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const EmptyState(
            icon: Icons.notifications_none,
            title: 'Nothing new',
            body: 'Updates about posts near you will show up here.',
          )
        else
          for (final n in list)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: typeColor(context, n.type == 'safety' ? 'alert' : n.type),
                child: Icon(
                  typeIcons[n.type == 'safety' ? 'alert' : n.type] ?? Icons.notifications_none,
                  color: onTypeColor(context),
                  size: 20,
                ),
              ),
              title: Text(
                n.text,
                style: TextStyle(fontWeight: unread.contains(n) ? FontWeight.w700 : FontWeight.w500),
              ),
              subtitle: Text(ago(now, n.at)),
              onTap: n.postId != null && d.post(n.postId!) != null ? () => showPostDetail(context, n.postId!) : null,
            ),
      ],
    );
  }
}
