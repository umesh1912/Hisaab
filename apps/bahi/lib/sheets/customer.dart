import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';
import 'customer_form.dart';
import 'entry.dart';

/// One customer's khata: balance, statement with running balance, entries, promise and reminders.
Future<void> showCustomerSheet(BuildContext context, int id) {
  return showAppSheet(context, (_) => CustomerSheet(id: id));
}

class CustomerSheet extends StatelessWidget {
  const CustomerSheet({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final c = d?.customer(id);
    final en = store.en;
    if (d == null || c == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(en ? 'This customer was deleted.' : 'यह ग्राहक हटा दिया गया है।', textAlign: TextAlign.center),
      );
    }
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = todayIso();
    final b = balanceOf(c);
    final runs = runningBalances(c);
    final hasPhone = phoneForWhatsApp(c.phone).isNotEmpty;

    Future<void> remind() async {
      final ok = await openExternal(
        context,
        whatsAppLink(c.phone, reminderText(d.shop, c, en)),
        failMessage: en ? 'WhatsApp is not installed.' : 'WhatsApp नहीं मिला।',
      );
      if (ok) store.markReminded(c.id);
    }

    Future<void> pickPromise() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: c.promise != null && c.promise!.compareTo(today) >= 0 ? parseIso(c.promise!) : now.add(const Duration(days: 3)),
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: now.add(const Duration(days: 365)),
      );
      if (picked != null) store.setPromise(c.id, isoDate(picked));
    }

    Future<void> delete() async {
      final ok = await confirm(
        context,
        title: en ? 'Delete ${c.display(en)}?' : '${c.display(en)} को हटाएँ?',
        body: en ? 'Their whole khata will be removed from this phone.' : 'इनका पूरा खाता इस फ़ोन से हट जाएगा।',
        yes: en ? 'Delete' : 'हटाएँ',
        no: en ? 'Cancel' : 'रद्द करें',
      );
      if (!ok || !context.mounted) return;
      final name = c.display(en);
      Navigator.pop(context);
      store.deleteCustomer(c.id);
      toast(context, en ? '$name deleted' : '$name हटाया गया');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Initial(id: c.id, name: c.display(en), size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                c.display(en),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: en ? 'Edit customer' : 'ग्राहक बदलें',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showCustomerForm(context, id: c.id),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Fact(
                label: b < 0 ? (en ? 'Advance' : 'एडवांस') : (en ? 'Balance' : 'बाकी'),
                value: inr(b.abs()),
                color: balanceColor(context, b),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Fact(
                label: en ? 'Oldest unpaid' : 'सबसे पुराना बाकी',
                value: '${oldestUnpaidDays(c, today)} ${en ? 'days' : 'दिन'}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (c.phone.isNotEmpty)
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text('+91 ${c.phone}', overflow: TextOverflow.ellipsis)),
              TextButton(
                onPressed: () => openExternal(context, telLink(c.phone), failMessage: en ? 'Can\'t open the dialer.' : 'फ़ोन नहीं खुल सका।'),
                child: Text(en ? 'Call' : 'कॉल करें'),
              ),
            ],
          ),
        if (b > 0)
          Row(
            children: [
              Icon(Icons.handshake_outlined, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.promise == null
                      ? (en ? 'No promise to pay' : 'भुगतान का कोई वादा नहीं')
                      : '${en ? 'Promised' : 'वादा'}: ${dateLabel(c.promise!, en)}${promiseActive(c, today) ? '' : (en ? ' (missed)' : ' (नहीं आया)')}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.promise != null && !promiseActive(c, today) ? dueColor(context) : null),
                ),
              ),
              if (c.promise != null)
                IconButton(
                  tooltip: en ? 'Clear promise' : 'वादा हटाएँ',
                  icon: const Icon(Icons.close),
                  onPressed: () => store.setPromise(c.id, null),
                ),
              TextButton(onPressed: pickPromise, child: Text(en ? 'Set date' : 'तारीख')),
            ],
          ),
        const SizedBox(height: 8),
        if (c.entries.isEmpty)
          LedgerBox(children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(en ? 'No entries yet.' : 'अभी कोई एंट्री नहीं।', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          ])
        else
          LedgerBox(
            children: [
              for (var i = 0; i < c.entries.length; i++)
                _StatementRow(
                  entry: c.entries[i],
                  running: runs[i],
                  onTap: () => showEntrySheet(context, kind: c.entries[i].kind, customerId: c.id, entryId: c.entries[i].id),
                ),
            ],
          ),
        const SizedBox(height: 4),
        Text(
          en ? 'Tap an entry to correct or delete it.' : 'बदलने या हटाने के लिए एंट्री पर टैप करें।',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BigAction(
                credit: true,
                title: en ? 'Gave credit' : 'उधार दिया',
                onTap: () => showEntrySheet(context, kind: 'credit', customerId: c.id),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BigAction(
                credit: false,
                title: en ? 'Got payment' : 'पैसा मिला',
                onTap: () => showEntrySheet(context, kind: 'pay', customerId: c.id),
              ),
            ),
          ],
        ),
        if (b > 0) ...[
          const SizedBox(height: 16),
          Text(en ? 'WhatsApp reminder preview' : 'WhatsApp संदेश', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          _WhatsAppBubble(text: reminderText(d.shop, c, en)),
          if (d.shop.upi.trim().isEmpty) ...[
            const SizedBox(height: 8),
            NoteBox(text: en ? 'Add your shop\'s UPI ID in Settings so customers can pay you directly.' : 'सेटिंग में दुकान की UPI ID जोड़ें, ताकि ग्राहक सीधे भुगतान कर सकें।'),
          ],
          if (remindedRecently(c, today)) ...[
            const SizedBox(height: 8),
            NoteBox(
              icon: Icons.schedule,
              text: en
                  ? 'You reminded them ${relativeDay(c.reminded!, today, en)}. Waiting 3 days between reminders keeps it polite.'
                  : 'आपने ${relativeDay(c.reminded!, today, en)} याद दिलाया था। 3 दिन रुककर दोबारा याद दिलाना अच्छा रहता है।',
            ),
          ],
          if (quietHours(DateTime.now())) ...[
            const SizedBox(height: 8),
            NoteBox(
              icon: Icons.nightlight_outlined,
              text: en ? 'It\'s outside 9 AM to 9 PM. Better to send this in the morning.' : 'अभी सुबह 9 से रात 9 के बाहर का समय है। सुबह भेजना ठीक रहेगा।',
            ),
          ],
          if (!hasPhone) ...[
            const SizedBox(height: 8),
            NoteBox(text: en ? 'No mobile number saved, so WhatsApp will ask you to pick the chat.' : 'मोबाइल नंबर नहीं है, इसलिए WhatsApp में चैट खुद चुननी होगी।'),
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const ValueKey('remind-one'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: whatsAppGreen, foregroundColor: Colors.white),
            onPressed: remind,
            icon: const Icon(Icons.chat_outlined),
            label: Text(en ? 'Remind on WhatsApp' : 'WhatsApp पर याद दिलाएँ'),
          ),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => openExternal(
            context,
            whatsAppLink(c.phone, statementText(d.shop, c, en)),
            failMessage: en ? 'WhatsApp is not installed.' : 'WhatsApp नहीं मिला।',
          ),
          icon: const Icon(Icons.ios_share),
          label: Text(en ? 'Share statement' : 'हिसाब भेजें'),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: cs.error),
          onPressed: delete,
          icon: const Icon(Icons.delete_outline),
          label: Text(en ? 'Delete customer' : 'ग्राहक हटाएँ'),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          SizedBox(
            height: 30,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color ?? cs.onSurface)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementRow extends StatelessWidget {
  const _StatementRow({required this.entry, required this.running, required this.onTap});
  final Entry entry;
  final int running;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final en = isEn(context);
    final cs = Theme.of(context).colorScheme;
    final e = entry;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 9, 12, 9),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Text(dateLabel(e.date, en), maxLines: 2, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                e.note.isEmpty ? (e.isCredit ? (en ? 'Credit' : 'उधार') : (en ? 'Payment' : 'जमा')) : e.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14.5),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 72,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${e.isCredit ? '' : '+'}${inrExact(e.amount)}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: e.isCredit ? dueColor(context) : goodColor(context)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 62,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(inr(running), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsAppBubble extends StatelessWidget {
  const _WhatsAppBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1F3320) : const Color(0xFFE7F5DF),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Text(text, style: TextStyle(fontSize: 14.5, color: dark ? const Color(0xFFE2F0DA) : const Color(0xFF1C2B18))),
    );
  }
}
