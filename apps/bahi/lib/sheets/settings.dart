import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui.dart';

/// Shop details, language, backup / restore and reset.
Future<void> showSettingsSheet(BuildContext context) {
  return showAppSheet(context, (_) => const SettingsSheet());
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  final _name = TextEditingController();
  final _nameHi = TextEditingController();
  final _owner = TextEditingController();
  final _upi = TextEditingController();
  final _restore = TextEditingController();
  bool showRestore = false;
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final s = StoreScope.read(context).data?.shop;
    if (s != null) {
      _name.text = s.name;
      _nameHi.text = s.nameHi;
      _owner.text = s.owner;
      _upi.text = s.upi;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nameHi.dispose();
    _owner.dispose();
    _upi.dispose();
    _restore.dispose();
    super.dispose();
  }

  void _saveShop() {
    final store = StoreScope.read(context);
    final en = store.en;
    final name = _name.text.trim();
    final upi = _upi.text.trim();
    if (name.isEmpty) {
      setState(() => error = en ? 'Write the shop name.' : 'दुकान का नाम लिखें।');
      return;
    }
    if (upi.isNotEmpty && !upi.contains('@')) {
      setState(() => error = en ? 'A UPI ID looks like name@bank.' : 'UPI ID ऐसी होती है: name@bank');
      return;
    }
    store.updateShop(name: name, nameHi: _nameHi.text.trim(), owner: _owner.text.trim(), upi: upi);
    setState(() => error = null);
    toast(context, en ? 'Shop details saved' : 'दुकान की जानकारी सेव हुई');
  }

  Future<void> _copyBackup() async {
    final store = StoreScope.read(context);
    await Clipboard.setData(ClipboardData(text: store.backupText()));
    if (mounted) toast(context, store.en ? 'Backup copied. Paste it in a WhatsApp chat to yourself.' : 'बैकअप कॉपी हुआ। इसे WhatsApp पर खुद को भेज दें।');
  }

  Future<void> _doRestore() async {
    final store = StoreScope.read(context);
    final en = store.en;
    final ok = await confirm(
      context,
      title: en ? 'Replace all data?' : 'सारा डेटा बदलें?',
      body: en ? 'Everything on this phone will be replaced by the backup.' : 'इस फ़ोन का सारा डेटा बैकअप से बदल जाएगा।',
      yes: en ? 'Restore' : 'वापस लाएँ',
      no: en ? 'Cancel' : 'रद्द करें',
    );
    if (!ok || !mounted) return;
    if (store.restore(_restore.text)) {
      Navigator.pop(context);
      toast(context, store.en ? 'Backup restored' : 'बैकअप वापस आया');
    } else {
      setState(() => error = en ? 'That doesn\'t look like a Bahi backup.' : 'यह Bahi का बैकअप नहीं लगता।');
    }
  }

  Future<void> _reset() async {
    final store = StoreScope.read(context);
    final en = store.en;
    final ok = await confirm(
      context,
      title: en ? 'Delete everything?' : 'सब कुछ हटाएँ?',
      body: en ? 'All customers, entries and sales on this phone will be deleted. Copy a backup first if you need it.' : 'इस फ़ोन से सारे ग्राहक, एंट्री और बिक्री हट जाएँगे। ज़रूरत हो तो पहले बैकअप कॉपी करें।',
      yes: en ? 'Delete' : 'हटाएँ',
      no: en ? 'Cancel' : 'रद्द करें',
    );
    if (!ok || !mounted) return;
    Navigator.pop(context);
    store.resetAll();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final en = store.en;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    if (store.data == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(en ? 'Settings' : 'सेटिंग', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'hi', label: Text('हिंदी')),
            ButtonSegment(value: 'en', label: Text('English')),
          ],
          selected: {store.data!.lang},
          onSelectionChanged: (s) => store.setLang(s.first),
        ),
        const SizedBox(height: 16),
        Text(en ? 'Shop' : 'दुकान', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(controller: _name, decoration: InputDecoration(labelText: en ? 'Shop name' : 'दुकान का नाम')),
        const SizedBox(height: 10),
        TextField(controller: _nameHi, decoration: InputDecoration(labelText: en ? 'Shop name in Hindi (optional)' : 'हिंदी में दुकान का नाम (ज़रूरी नहीं)')),
        const SizedBox(height: 10),
        TextField(controller: _owner, decoration: InputDecoration(labelText: en ? 'Owner name' : 'मालिक का नाम')),
        const SizedBox(height: 10),
        TextField(
          controller: _upi,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: en ? 'Shop UPI ID (shown in reminders)' : 'दुकान की UPI ID (रिमाइंडर में)', hintText: 'guptastore@okaxis'),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _saveShop,
          child: Text(en ? 'Save shop details' : 'जानकारी सेव करें'),
        ),
        const SizedBox(height: 20),
        Text(en ? 'Backup' : 'बैकअप', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          en
              ? 'Bahi works fully offline and keeps the register only on this phone. Copy a backup now and then and keep it somewhere safe, such as a WhatsApp chat with yourself.'
              : 'Bahi बिना इंटरनेट चलता है और खाता सिर्फ़ इसी फ़ोन में रखता है। समय-समय पर बैकअप कॉपी करके सुरक्षित जगह रखें, जैसे WhatsApp पर खुद को भेजकर।',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _copyBackup,
              icon: const Icon(Icons.copy),
              label: Text(en ? 'Copy backup' : 'बैकअप कॉपी करें'),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() => showRestore = !showRestore),
              icon: const Icon(Icons.restore),
              label: Text(en ? 'Restore' : 'वापस लाएँ'),
            ),
          ],
        ),
        if (showRestore) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _restore,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(labelText: en ? 'Paste the backup text here' : 'बैकअप का टेक्स्ट यहाँ चिपकाएँ'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: _doRestore, child: Text(en ? 'Restore this backup' : 'यह बैकअप वापस लाएँ')),
        ],
        const SizedBox(height: 20),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: cs.error),
          onPressed: _reset,
          icon: const Icon(Icons.delete_forever_outlined),
          label: Text(en ? 'Delete all data' : 'सारा डेटा हटाएँ'),
        ),
      ],
    );
  }
}
