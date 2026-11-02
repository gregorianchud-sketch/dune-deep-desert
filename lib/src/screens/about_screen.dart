import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/fancy.dart';

class AboutScreen extends StatelessWidget {
  final DesertData data;
  const AboutScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final date = data.scrapedAt?.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final dateStr = date == null
        ? 'Unknown'
        : '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
    Widget row(IconData i, String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i, color: Spice.amber, size: 20),
            const SizedBox(width: 12),
            SizedBox(width: 92, child: Text(k, style: const TextStyle(color: Spice.orange))),
            Expanded(child: SelectableText(v)),
          ]),
        );
    return Column(children: [
      const HeroHeader(title: 'ABOUT', subtitle: 'Deep Desert Companion', icon: Icons.info),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 24), children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset('assets/icon/icon.png', width: 120, height: 120),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text('DEEP DESERT', style: display(24))),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(children: [
              row(Icons.calendar_month, 'Week', data.weekLabel ?? 'Unknown'),
              row(Icons.update, 'Data date', dateStr),
              row(Icons.public, 'Maps', data.maps.map((m) => '${m.label} (${m.pois.length} POIs)').join('\n')),
            ]),
          ),
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SOURCE', style: display(15)),
              const SizedBox(height: 8),
              Text('All map, POI and loot data comes from the ${data.sourceName}. Credit to Method.gg.'),
              const SizedBox(height: 6),
              SelectableText(data.source, style: const TextStyle(color: Spice.amber)),
              const SizedBox(height: 10),
              Text(
                'Data is bundled in the app and refreshed on each build. Marker positions are approximate '
                '(grid cell + 3x3 sub-cell). Map and item images load from the network and are cached for offline use.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Unofficial fan app. Dune: Awakening is a trademark of its owners.',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ),
        ]),
      ),
    ]);
  }
}
