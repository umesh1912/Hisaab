import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

Future<void> showChat(BuildContext context, String id) => showAppSheet(context, (_) => _ChatSheet(id: id));

class _ChatSheet extends StatefulWidget {
  const _ChatSheet({required this.id});
  final String id;

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) StoreScope.read(context).markRead(widget.id);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final v = _text.text.trim();
    if (v.isEmpty) return;
    StoreScope.read(context).sendMessage(widget.id, v);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data;
    final p = d?.person(widget.id);
    final cs = Theme.of(context).colorScheme;
    if (d == null || p == null) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('This chat is no longer available.'));
    }
    final thread = d.threads[widget.id] ?? const <Message>[];
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(p.name, leading: PersonAvatar(p, size: 36)),
        const InfoNote('Keep chats in Lenden until you choose to share a number. Report anyone who asks for money or OTPs.'),
        const SizedBox(height: 14),
        if (thread.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('Say hello and suggest a time.', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          for (final m in thread)
            Align(
              alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  decoration: BoxDecoration(
                    color: m.me ? cs.primary : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(m.me ? 16 : 4),
                      bottomRight: Radius.circular(m.me ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.text, style: TextStyle(color: m.me ? cs.onPrimary : cs.onSurface)),
                      const SizedBox(height: 2),
                      Text(
                        msgTime(m.at, now),
                        style: TextStyle(fontSize: 11, color: m.me ? cs.onPrimary : cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(hintText: 'Message ${p.first}'),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Send',
              onPressed: _send,
              icon: Icon(Icons.send, color: cs.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Messages are saved on this phone. Sample neighbours cannot reply in this version.',
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}
