import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'post_detail.dart';

/// Opens a conversation and marks it read.
Future<void> showThread(BuildContext context, int id) {
  StoreScope.read(context).markThreadRead(id);
  return showAppSheet(context, (_) => ThreadSheet(id: id));
}

class ThreadSheet extends StatefulWidget {
  const ThreadSheet({super.key, required this.id});
  final int id;

  @override
  State<ThreadSheet> createState() => _ThreadSheetState();
}

class _ThreadSheetState extends State<ThreadSheet> {
  final _msg = TextEditingController();

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  void _send() {
    final t = _msg.text.trim();
    if (t.isEmpty) return;
    StoreScope.read(context).sendMessage(widget.id, t);
    _msg.clear();
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Delete this conversation?',
      body: 'The messages are removed from this phone.',
      action: 'Delete',
    );
    if (!ok || !mounted) return;
    final store = StoreScope.read(context);
    Navigator.pop(context);
    store.deleteThread(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final t = d?.thread(widget.id);
    if (d == null || t == null) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Conversation removed.')));
    }
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final p = d.post(t.postId);
    final now = store.now;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.withName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(tooltip: 'Delete conversation', onPressed: _delete, icon: const Icon(Icons.delete_outline)),
          ],
        ),
        if (p != null)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => showPostDetail(context, p.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: TypeLabel(type: p.type),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        const NoteBox(
          icon: Icons.shield_outlined,
          text: "Your number stays hidden. Don't share OTPs or pay anyone to get something back.",
        ),
        const SizedBox(height: 12),
        for (final m in t.msgs)
          Align(
            alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: m.me ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(m.me ? 16 : 5),
                    bottomRight: Radius.circular(m.me ? 5 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.text, style: TextStyle(color: m.me ? cs.onPrimary : cs.onSurface)),
                    const SizedBox(height: 2),
                    Text(
                      ago(now, m.at),
                      style: TextStyle(fontSize: 11, color: m.me ? cs.onPrimary : cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msg,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Message', isDense: true),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(tooltip: 'Send', onPressed: _send, icon: const Icon(Icons.send)),
          ],
        ),
      ],
    );
  }
}
