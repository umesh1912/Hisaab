import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// Hotel details and automatic room allotment for out-of-town families.
Future<void> showRoomsSheet(BuildContext context) {
  return showAppSheet(context, (ctx) => const _Rooms());
}

class _Rooms extends StatefulWidget {
  const _Rooms();

  @override
  State<_Rooms> createState() => _RoomsState();
}

class _RoomsState extends State<_Rooms> {
  final _hotel = TextEditingController();
  final _rooms = TextEditingController();
  final _per = TextEditingController();
  String? error;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final d = StoreScope.read(context).data;
    if (d == null) return;
    _hotel.text = d.hotelName;
    _rooms.text = d.hotelRooms > 0 ? '${d.hotelRooms}' : '';
    _per.text = '${d.perRoom}';
  }

  @override
  void dispose() {
    _hotel.dispose();
    _rooms.dispose();
    _per.dispose();
    super.dispose();
  }

  void _allot() {
    final store = StoreScope.read(context);
    final d = store.data;
    if (d == null) return;
    final rooms = int.tryParse(_rooms.text.trim());
    final per = int.tryParse(_per.text.trim());
    if (rooms == null || rooms < 1) return setState(() => error = 'How many rooms are booked?');
    if (per == null || per < 1) return setState(() => error = 'People per room must be at least 1.');
    setState(() => error = null);
    store.updateSettings(
      myName: d.myName,
      bride: d.bride,
      groom: d.groom,
      city: d.city,
      weddingDate: d.weddingDate,
      hotelName: _hotel.text.trim(),
      hotelRooms: rooms,
      perRoom: per,
      bufferPct: d.bufferPct,
    );
    final plan = store.allotHotelRooms();
    final placed = plan.rooms.length;
    final left = plan.unplaced.length;
    toast(
      context,
      '${plan.used} of $rooms rooms allotted to $placed ${placed == 1 ? 'family' : 'families'}'
      '${left > 0 ? '. $left still need rooms' : ''}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final d = store.data;
    final cs = Theme.of(context).colorScheme;
    if (d == null) return const SizedBox.shrink();
    final home = d.city.trim().toLowerCase();
    final withRooms = d.guests.where((g) => g.room != null).toList()..sort((a, b) => a.room!.compareTo(b.room!));
    final needRooms = d.guests
        .where((g) => g.status == rsvpYes && g.room == null && g.city.trim().isNotEmpty && g.city.trim().toLowerCase() != home)
        .toList();
    final used = withRooms.fold<int>(0, (a, g) => a + roomsNeeded(g.people, d.perRoom));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(
          'Hotel rooms',
          sub: 'Confirmed families from outside ${d.city.isEmpty ? 'your city' : d.city} get rooms, largest families first.',
        ),
        TextField(
          controller: _hotel,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Hotel', hintText: 'Hotel Aravali Inn'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _rooms,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Rooms booked'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _per,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'People per room'),
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: TextStyle(color: cs.error)),
          ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _allot,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: const Text('Allot rooms automatically'),
        ),
        const SizedBox(height: 6),
        Text(
          'This redoes every room from scratch, so run it again after RSVPs change.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        if (withRooms.isNotEmpty) ...[
          const FieldLabel('Allotted'),
          Text('$used of ${d.hotelRooms} rooms in use', style: const TextStyle(fontWeight: FontWeight.w700)),
          for (final g in withRooms)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('${g.name} · ${g.people}', overflow: TextOverflow.ellipsis),
              subtitle: Text(g.city, overflow: TextOverflow.ellipsis),
              trailing: Text('Room ${g.room}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          TextButton(onPressed: store.clearRooms, child: const Text('Clear all rooms')),
        ],
        if (needRooms.isNotEmpty) ...[
          const FieldLabel('Still need rooms'),
          for (final g in needRooms)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('${g.name} · ${g.people}', overflow: TextOverflow.ellipsis),
              subtitle: Text(g.city, overflow: TextOverflow.ellipsis),
              trailing: Text('${roomsNeeded(g.people, d.perRoom)} needed'),
            ),
        ],
      ],
    );
  }
}
