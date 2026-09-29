import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'customer_form.dart';
import 'entry.dart';

/// Type (or dictate with the keyboard's mic) an entry like "रमेश 340 उधार दूध", check it, save it.
Future<void> showQuickEntry(BuildContext context) {
  return showAppSheet(context, (_) => const QuickEntry());
}

const quickExamples = ['रमेश जी 340 उधार दूध ब्रेड', 'Salim 200 jama', 'मोहन के साढ़े तीन सौ चीनी'];

class QuickEntry extends StatefulWidget {
  const QuickEntry({super.key});

  @override
  State<QuickEntry> createState() => _QuickEntryState();
}

class _QuickEntryState extends State<QuickEntry> {
  final _text = TextEditingController();
  int? picked; // chosen customer when several names match

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _fill(String s) {
    _text.text = s;
    _text.selection = TextSelection.collapsed(offset: s.length);
    setState(() => picked = null);
  }

  Customer? _customer(ParsedEntry r, AppData d) {
    final p = picked;
    if (p != null) {
      final chosen = d.customer(p);
      if (chosen != null) return chosen;
    }
    if (r.matches.length == 1) return r.matches.first;
    return null;
  }

  void _save(ParsedEntry r, Customer c) {
    final store = StoreScope.read(context);
    final en = store.en;
    final bal = store.addEntry(customerId: c.id, kind: r.kind, amount: r.amount, note: r.note);
    Navigator.pop(context);
    toast(context, '${c.display(en)}: ${r.kind == 'credit' ? '' : '+'}${inrExact(r.amount)} · ${en ? 'balance' : 'बाकी'} ${inr(bal)}');
  }

  void _edit(ParsedEntry r, Customer? c) {
    final nav = Navigator.of(context);
    nav.pop();
    showEntrySheet(nav.context, kind: r.kind, customerId: c?.id, amount: r.amount, note: r.note);
  }

  Future<void> _newCustomer() async {
    final id = await showCustomerForm(context);
    if (id != null && mounted) setState(() => picked = id);
  }

  @override
  Widget build(BuildContext context) {
    final d = StoreScope.of(context).data!;
    final en = d.en;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final r = parseEntry(_text.text, d.customers);
    final c = r == null ? null : _customer(r, d);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(en ? 'Speak or type an entry' : 'बोलकर या लिखकर एंट्री', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        NoteBox(
          icon: Icons.mic_none,
          color: const Color(0x33F2B705),
          text: en
              ? 'Say or type the name, the amount and “udhaar” or “jama”. To speak, tap the mic on your keyboard.'
              : 'नाम, रकम और “उधार” या “जमा” बोलें या लिखें। बोलने के लिए कीबोर्ड का माइक दबाएँ।',
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('quick-text'),
          controller: _text,
          autofocus: false,
          minLines: 1,
          maxLines: 3,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: en ? 'Entry' : 'एंट्री',
            hintText: en ? 'Ramesh 340 udhaar doodh' : 'रमेश 340 उधार दूध',
            suffixIcon: _text.text.isEmpty
                ? null
                : IconButton(
                    tooltip: en ? 'Clear' : 'साफ़ करें',
                    icon: const Icon(Icons.close),
                    onPressed: () => _fill(''),
                  ),
          ),
          onChanged: (_) => setState(() => picked = null),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < quickExamples.length; i++)
              ActionChip(
                key: ValueKey('example-$i'),
                label: Text(quickExamples[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                onPressed: () => _fill(quickExamples[i]),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (r != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x1FF2B705),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: turmeric, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Line(
                  label: en ? 'Customer' : 'ग्राहक',
                  child: c != null
                      ? Text(c.display(en), style: const TextStyle(fontWeight: FontWeight.w800))
                      : Text(
                          r.matches.length > 1 ? (en ? 'Which one?' : 'कौन से?') : (en ? 'Not found' : 'नहीं मिला'),
                          style: TextStyle(fontWeight: FontWeight.w800, color: dueColor(context)),
                        ),
                ),
                if (r.matches.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final m in r.matches)
                          ChoiceChip(
                            label: Text(m.display(en)),
                            selected: picked == m.id,
                            onSelected: (_) => setState(() => picked = m.id),
                          ),
                      ],
                    ),
                  ),
                _Line(
                  label: en ? 'Amount' : 'रकम',
                  child: Text(r.amount > 0 ? inrExact(r.amount) : '—', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                _Line(
                  label: en ? 'Type' : 'प्रकार',
                  child: Text(
                    r.kind == 'credit' ? (en ? 'Gave credit' : 'उधार दिया') : (en ? 'Got payment' : 'पैसा मिला'),
                    style: TextStyle(fontWeight: FontWeight.w800, color: r.kind == 'credit' ? dueColor(context) : goodColor(context)),
                  ),
                ),
                if (r.note.isNotEmpty)
                  _Line(label: en ? 'Note' : 'नोट', child: Text(r.note, style: const TextStyle(fontWeight: FontWeight.w700))),
                const SizedBox(height: 8),
                if (c != null && r.amount > 0)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _edit(r, c),
                          child: Text(en ? 'Edit' : 'बदलें'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          key: const ValueKey('quick-save'),
                          onPressed: () => _save(r, c),
                          child: Text(en ? 'Correct, save it' : 'सही है, लिखें', textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  )
                else ...[
                  Text(
                    en ? 'Say the customer\'s name and an amount, like “Salim 200 jama”.' : 'ग्राहक का नाम और रकम बोलें, जैसे “सलीम 200 जमा”।',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (c == null && r.matches.isEmpty)
                        TextButton.icon(
                          onPressed: _newCustomer,
                          icon: const Icon(Icons.person_add_alt),
                          label: Text(en ? 'New customer' : 'नया ग्राहक'),
                        ),
                      TextButton.icon(
                        onPressed: () => _edit(r, c),
                        icon: const Icon(Icons.dialpad),
                        label: Text(en ? 'Use numpad' : 'नंबर पैड से लिखें'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
