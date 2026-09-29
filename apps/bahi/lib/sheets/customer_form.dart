import 'package:flutter/material.dart';

import '../ui.dart';

/// Adds a customer, or edits one when [id] is given. Resolves to the customer's id when saved.
Future<int?> showCustomerForm(BuildContext context, {int? id, String presetName = ''}) {
  return showAppSheet<int>(context, (_) => CustomerForm(id: id, presetName: presetName));
}

class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key, this.id, this.presetName = ''});
  final int? id;
  final String presetName;

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final _name = TextEditingController();
  final _hi = TextEditingController();
  final _phone = TextEditingController();
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final id = widget.id;
    final c = id == null ? null : StoreScope.read(context).data!.customer(id);
    if (c != null) {
      _name.text = c.name;
      _hi.text = c.hi;
      _phone.text = c.phone;
    } else {
      _name.text = widget.presetName;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _hi.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    final store = StoreScope.read(context);
    final en = store.en;
    var name = _name.text.trim();
    final hi = _hi.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty && hi.isEmpty) {
      setState(() => error = en ? 'Write the customer\'s name.' : 'ग्राहक का नाम लिखें।');
      return;
    }
    if (name.isEmpty) name = hi;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isNotEmpty && (digits.length < 10 || digits.length > 12)) {
      setState(() => error = en ? 'Check the mobile number (10 digits).' : 'मोबाइल नंबर जाँचें (10 अंक)।');
      return;
    }
    final id = widget.id;
    int savedId;
    if (id == null) {
      savedId = store.addCustomer(name: name, hi: hi, phone: phone);
    } else {
      store.updateCustomer(id, name: name, hi: hi, phone: phone);
      savedId = id;
    }
    Navigator.pop(context, savedId);
    toast(context, id == null ? (en ? '$name added' : '$name जोड़ा गया') : (en ? 'Saved' : 'सेव हो गया'));
  }

  @override
  Widget build(BuildContext context) {
    final en = isEn(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final editing = widget.id != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          editing ? (en ? 'Edit customer' : 'ग्राहक बदलें') : (en ? 'New customer' : 'नया ग्राहक'),
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('cf-name'),
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: en ? 'Name (English letters)' : 'नाम (अंग्रेज़ी अक्षरों में)', hintText: 'Deepak Electrician'),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('cf-hi'),
          controller: _hi,
          decoration: InputDecoration(labelText: en ? 'Name in Hindi (optional)' : 'हिंदी में नाम (ज़रूरी नहीं)', hintText: 'दीपक इलेक्ट्रीशियन'),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('cf-phone'),
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: en ? 'Mobile (for WhatsApp)' : 'मोबाइल (WhatsApp के लिए)', hintText: '98260 77341', prefixText: '+91 '),
        ),
        const SizedBox(height: 8),
        Text(
          en ? 'Both names help Bahi recognise the customer when you type or speak an entry.' : 'दोनों नाम होने से बोलकर या लिखकर एंट्री करते समय ग्राहक पहचानना आसान होता है।',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('cf-save'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _save,
          child: Text(en ? 'Save' : 'सेव करें'),
        ),
      ],
    );
  }
}
