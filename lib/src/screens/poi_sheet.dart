import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/fancy.dart';

String poiTypeLabel(DesertMap map, String type) {
  for (final f in map.filters) {
    if (f.type == type) return f.label;
  }
  return type.replaceAll('-', ' ');
}

void showPoiSheet(BuildContext context, Poi p, DesertMap map) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Spice.surface,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, scroll) {
        final t = Theme.of(context).textTheme;
        final c = Spice.poiColor(p.type);
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            if (p.thumbnail != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(aspectRatio: 16 / 9, child: NetImage(p.thumbnail)),
              ),
            const SizedBox(height: 14),
            Text(p.name, style: display(20)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Chip(
                avatar: Icon(Spice.poiIcon(p.type), size: 16, color: c),
                label: Text(poiTypeLabel(map, p.type)),
              ),
              Chip(avatar: const Icon(Icons.grid_4x4, size: 16), label: Text('Grid ${p.grid} · sub ${p.subX},${p.subY}')),
              Chip(avatar: const Icon(Icons.public, size: 16), label: Text(map.label)),
            ]),
            if (p.details.isNotEmpty) ...[
              const SizedBox(height: 12),
              GlassCard(
                  child: Column(children: [
                    for (final e in p.details.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          SizedBox(width: 100, child: Text(e.key, style: t.labelLarge?.copyWith(color: Spice.orange))),
                          Expanded(child: Text(e.value)),
                        ]),
                      ),
                  ]),
              ),
            ],
            for (final n in p.notes) Padding(padding: const EdgeInsets.only(top: 8), child: Text(n)),
            for (final lp in p.lootPreview) ...[
              const SizedBox(height: 14),
              Text(lp.title, style: t.titleSmall?.copyWith(color: Spice.amber)),
              const SizedBox(height: 6),
              for (final i in lp.items)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.inventory_2_outlined, color: Spice.orange),
                  title: Text(i.name),
                  trailing: Text(i.chance, style: const TextStyle(color: Spice.amber, fontWeight: FontWeight.w700)),
                ),
              if (lp.more != null)
                Text('+ ${lp.more} more — see the Loot tab', style: t.bodySmall),
            ],
          ],
        );
      },
    ),
  );
}
