import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/fancy.dart';

class EndgameScreen extends StatelessWidget {
  final DesertData data;
  const EndgameScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Hardest POIs pulled from the scraped details (no invented data).
    final hard = <String>[];
    for (final m in data.maps) {
      for (final p in m.pois) {
        final d = p.details['Difficulty'];
        if (d != null && d.toLowerCase().contains('hard')) hard.add('${p.name} · ${m.label}');
      }
    }
    return Column(children: [
      HeroHeader(title: 'ENDGAME', subtitle: 'Notes from the Deep Desert Companion', icon: Icons.military_tech),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          children: [
            for (final (i, n) in data.endgameNotes.indexed)
              GlassCard(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  GlowIcon(icon: _icon(n), color: i.isEven ? Spice.orange : Spice.amber, size: 34),
                  const SizedBox(width: 14),
                  Expanded(child: Text(n, style: const TextStyle(height: 1.4))),
                ]),
              ),
            if (hard.isNotEmpty)
              GlassCard(
                glow: const Color(0xFFFF4D2E),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('HARD DIFFICULTY POIs', style: display(15)),
                  const SizedBox(height: 8),
                  for (final h in hard)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        const Icon(Icons.local_fire_department, size: 16, color: Color(0xFFFF4D2E)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(h)),
                      ]),
                    ),
                ]),
              ),
          ],
        ),
      ),
    ]);
  }

  IconData _icon(String n) {
    final l = n.toLowerCase();
    if (l.contains('pvp')) return Icons.local_fire_department;
    if (l.contains('single')) return Icons.person;
    if (l.contains('row a')) return Icons.layers;
    if (l.contains('map')) return Icons.map;
    if (l.contains('reset')) return Icons.cyclone;
    return Icons.auto_awesome;
  }
}
