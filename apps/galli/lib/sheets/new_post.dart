import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Opens the form for a new post, or for editing your own post when [editId] is given.
Future<void> showNewPost(BuildContext context, {int? editId, VoidCallback? onPosted}) =>
    showAppSheet(context, (_) => NewPostForm(editId: editId, onPosted: onPosted));

class NewPostForm extends StatefulWidget {
  const NewPostForm({super.key, this.editId, this.onPosted});
  final int? editId;
  final VoidCallback? onPosted;

  @override
  State<NewPostForm> createState() => _NewPostFormState();
}

class _NewPostFormState extends State<NewPostForm> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _place = TextEditingController();
  final _reward = TextEditingController();
  String type = 'found';
  String cat = 'Item';
  double km = 0.5;
  int hours = 6;
  String? error;
  bool _init = false;

  bool get editing => widget.editId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final id = widget.editId;
    if (id == null) return;
    final p = StoreScope.read(context).data?.post(id);
    if (p == null) return;
    type = p.type;
    cat = p.cat;
    km = distanceOptions.contains(p.km) ? p.km : 0.5;
    _title.text = p.title;
    _body.text = p.body;
    _place.text = p.place;
    _reward.text = p.reward;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _place.dispose();
    _reward.dispose();
    super.dispose();
  }

  void _setType(String t) {
    setState(() {
      type = t;
      final cats = categoriesByType[t] ?? const ['Other'];
      if (!cats.contains(cat)) cat = cats.first;
    });
  }

  void _save() {
    final store = StoreScope.read(context);
    final title = _title.text.trim();
    if (title.length < 8) {
      setState(() => error = 'Write a short headline people can act on, like "Found: blue school bag near Vanaz metro".');
      return;
    }
    final id = widget.editId;
    if (id != null) {
      store.updatePost(
        id,
        type: type,
        cat: cat,
        title: title,
        body: _body.text.trim(),
        place: _place.text.trim(),
        km: km,
        expiresHours: hours,
        reward: _reward.text.trim(),
      );
      Navigator.pop(context);
      toast(context, 'Post updated.');
      return;
    }
    final widened = store.publish(
      type: type,
      cat: cat,
      title: title,
      body: _body.text.trim(),
      place: _place.text.trim(),
      km: km,
      expiresHours: hours,
      reward: _reward.text.trim(),
    );
    final r = store.data?.radius ?? 1;
    Navigator.pop(context);
    widget.onPosted?.call();
    toast(
      context,
      widened
          ? 'Posted. Your radius is now ${radiusLabel(r)} so you can see it.'
          : 'Posted. Share it on WhatsApp to reach neighbours who are not on Galli yet.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    if (d == null) return const SizedBox(height: 120);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final reach = (type == 'lost' || type == 'found') ? 2.0 : d.radius;

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(t, style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(editing ? 'Edit post' : 'New post', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        label('What is it?'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final t in postTypes)
              ChoiceChip(
                avatar: Icon(typeIcons[t], size: 18, color: typeColor(context, t)),
                label: Text(typeLabels[t] ?? t),
                selected: type == t,
                onSelected: (_) => _setType(t),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(typeHints[type] ?? '', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        label('Category'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final c in categoriesByType[type] ?? const <String>['Other'])
              ChoiceChip(
                label: Text(c),
                selected: cat == c,
                onSelected: (_) => setState(() => cat = c),
              ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Headline', hintText: 'Found: blue school bag near Vanaz metro'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _body,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Details',
            hintText: 'What people should know or do',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _place,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Near (a landmark, not your address)', hintText: 'Vanaz metro station'),
        ),
        if (type == 'lost') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _reward,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Reward (optional)', hintText: 'Reward offered'),
          ),
        ],
        const SizedBox(height: 14),
        label('How far from you'),
        KmPicker(options: distanceOptions, value: km, onChanged: (v) => setState(() => km = v)),
        const SizedBox(height: 6),
        Text(
          'Shown as "About ${kmText(km)} from you". Your exact location is never shown.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        if (type == 'alert') ...[
          const SizedBox(height: 14),
          label(editing ? 'Remove after (from now)' : 'Remove after'),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [for (final h in expiryOptions) ButtonSegment(value: h, label: Text('$h hours'))],
              selected: {hours},
              onSelectionChanged: (s) => setState(() => hours = s.first),
            ),
          ),
        ],
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(editing ? 'Save changes' : 'Post to neighbours within ${radiusLabel(reach)}'),
        ),
      ],
    );
  }
}
