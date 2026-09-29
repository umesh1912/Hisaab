import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic.dart';
import '../ui.dart';

/// A schematic neighbourhood map: blocks and lanes, your radius, pins for posts
/// and dotted trails of sightings for lost posts. Pins are placed by distance,
/// not on the exact spot.
class MapView extends StatelessWidget {
  const MapView({
    super.key,
    required this.posts,
    required this.radius,
    this.trails = const [],
    this.highlight,
    this.onPinTap,
  });

  final List<Post> posts;
  final double radius;
  final List<Post> trails;
  final int? highlight;
  final void Function(Post p)? onPinTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = isDark(context);
    final colors = _MapColors(
      bg: dark ? const Color(0xFF1A1C1F) : const Color(0xFFE4E6DF),
      block: dark ? const Color(0xFF202327) : const Color(0xFFD7DAD1),
      green: dark ? const Color(0xFF1D2A1E) : const Color(0xFFCFE3C5),
      road: dark ? const Color(0xFF2A2D32) : Colors.white,
      accent: cs.primary,
      accentFill: dark ? const Color(0x22FF7440) : const Color(0x14F2551D),
      trail: typeColor(context, 'lost'),
      surface: cs.surface,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: mapW / mapH,
        child: LayoutBuilder(
          builder: (context, c) {
            final s = c.maxWidth / mapW;
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _MapPainter(colors: colors, radius: radius, trails: trails)),
                ),
                Positioned(
                  left: youX * s - 30,
                  top: youY * s + 9,
                  width: 60,
                  child: Text(
                    'You',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                ),
                for (final p in posts) _pin(context, p, s),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pin(BuildContext context, Post p, double s) {
    final big = highlight == p.id;
    final size = math.max(big ? 30.0 : 24.0, (big ? 26 : 20) * s);
    final col = typeColor(context, p.type);
    final letter = (typeLabels[p.type] ?? '?')[0];
    final tap = onPinTap;
    return Positioned(
      left: p.x * s - size / 2,
      top: p.y * s - size / 2,
      width: size,
      height: size,
      child: Semantics(
        button: tap != null,
        label: p.title,
        child: Material(
          color: col,
          shape: CircleBorder(side: BorderSide(color: Theme.of(context).colorScheme.surface, width: 2.5)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: tap == null ? null : () => tap(p),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(color: onTypeColor(context), fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Colour key under the map.
class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        );
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final t in postTypes) item(typeColor(context, t), typeLabels[t] ?? t),
        item(const Color(0xFF2361D0), 'You'),
      ],
    );
  }
}

class _MapColors {
  const _MapColors({
    required this.bg,
    required this.block,
    required this.green,
    required this.road,
    required this.accent,
    required this.accentFill,
    required this.trail,
    required this.surface,
  });
  final Color bg;
  final Color block;
  final Color green;
  final Color road;
  final Color accent;
  final Color accentFill;
  final Color trail;
  final Color surface;
}

const _blocks = <List<double>>[
  [14, 14, 70, 50], [100, 10, 80, 40], [196, 12, 60, 36], [272, 14, 56, 44],
  [14, 82, 48, 56], [78, 70, 60, 40], [152, 62, 90, 34], [258, 72, 70, 40],
  [14, 152, 60, 40], [92, 124, 70, 50], [178, 110, 50, 44], [244, 128, 84, 42],
  [14, 210, 90, 40], [118, 188, 64, 58], [198, 172, 40, 72], [254, 186, 74, 60],
];

class _MapPainter extends CustomPainter {
  _MapPainter({required this.colors, required this.radius, required this.trails});
  final _MapColors colors;
  final double radius;
  final List<Post> trails;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / mapW;
    Offset o(double x, double y) => Offset(x * s, y * s);

    canvas.drawRect(Offset.zero & size, Paint()..color = colors.bg);

    for (var i = 0; i < _blocks.length; i++) {
      final b = _blocks[i];
      final paint = Paint()..color = (i == 6 || i == 13) ? colors.green : colors.block;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(b[0] * s, b[1] * s, b[2] * s, b[3] * s), Radius.circular(4 * s)),
        paint,
      );
    }

    final road = Paint()
      ..color = colors.road
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 * s;
    const lines = <List<double>>[
      [0, 60, 340, 54], [0, 118, 340, 104], [0, 176, 340, 172],
      [88, 0, 96, 260], [150, 0, 140, 260], [246, 0, 240, 260],
    ];
    for (final l in lines) {
      canvas.drawLine(o(l[0], l[1]), o(l[2], l[3]), road);
    }
    final main = Path()
      ..moveTo(0, 240 * s)
      ..cubicTo(120 * s, 214 * s, 200 * s, 250 * s, 340 * s, 220 * s);
    canvas.drawPath(
      main,
      Paint()
        ..color = colors.road
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13 * s,
    );

    // Your radius: a light fill and a dashed ring.
    final centre = o(youX, youY);
    final r = radius * pxPerKm * s;
    canvas.drawCircle(centre, r, Paint()..color = colors.accentFill);
    final ring = Paint()
      ..color = colors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rect = Rect.fromCircle(center: centre, radius: r);
    const dashes = 48;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * 2 * math.pi / dashes, math.pi / dashes, false, ring);
    }

    // Trails of sightings.
    final trail = Paint()
      ..color = colors.trail
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final p in trails) {
      if (p.sightings.isEmpty) continue;
      final pts = [o(p.x, p.y), ...p.sightings.map((x) => o(x.x, x.y))];
      for (var i = 0; i < pts.length - 1; i++) {
        _dashedLine(canvas, pts[i], pts[i + 1], trail);
      }
      for (final pt in pts.skip(1)) {
        canvas.drawCircle(pt, 4, Paint()..color = colors.surface);
        canvas.drawCircle(pt, 4, trail);
      }
    }

    // You.
    canvas.drawCircle(centre, 8, Paint()..color = Colors.white);
    canvas.drawCircle(centre, 6, Paint()..color = const Color(0xFF2361D0));
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final end = math.min(d + 4, total);
      canvas.drawLine(a + dir * d, a + dir * end, paint);
      d += 7;
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => true;
}
