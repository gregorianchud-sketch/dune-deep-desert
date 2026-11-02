import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/fancy.dart';

class LootScreen extends StatefulWidget {
  final DesertData data;
  final int mapIndex;
  final ValueChanged<int> onMapChanged;
  const LootScreen({super.key, required this.data, required this.mapIndex, required this.onMapChanged});

  @override
  State<LootScreen> createState() => _LootScreenState();
}

class _LootScreenState extends State<LootScreen> {
  String _mode = 'pve';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final map = widget.data.maps[widget.mapIndex];
    final modes = map.loot.keys.toList();
    final mode = modes.contains(_mode) ? _mode : modes.first;
    final q = _query.toLowerCase();
    final sections = <(LootSection, List<LootItem>)>[];
    for (final s in map.loot[mode] ?? <LootSection>[]) {
      final items = q.isEmpty
          ? s.items
          : s.items
              .where((i) =>
                  i.name.toLowerCase().contains(q) ||
                  i.category.toLowerCase().contains(q) ||
                  s.title.toLowerCase().contains(q))
              .toList();
      if (items.isNotEmpty) sections.add((s, items));
    }
    return Column(children: [
      HeroHeader(
        title: 'LOOT TABLES',
        subtitle: '${map.label} · ${mode.toUpperCase()} · unique schematics',
        icon: Icons.inventory_2,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Row(children: [
          Expanded(child: MapToggle(data: widget.data, index: widget.mapIndex, onChanged: widget.onMapChanged)),
          const SizedBox(width: 8),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              const ButtonSegment(value: 'pve', label: Text('PvE')),
              ButtonSegment(value: 'pvp', label: const Text('PvP'), enabled: modes.contains('pvp')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search items, categories or POIs',
            prefixIcon: const Icon(Icons.search, color: Spice.amber),
            filled: true,
            fillColor: Spice.card.withValues(alpha: 0.7),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ),
      if (!modes.contains('pvp'))
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Single Player has no PvP loot table.', style: Theme.of(context).textTheme.bodySmall),
        ),
      Expanded(
        child: sections.isEmpty
            ? const Center(child: Text('No loot matches your search'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                itemCount: sections.length,
                itemBuilder: (context, i) {
                  final (s, items) = sections[i];
                  return GlassCard(
                    padding: EdgeInsets.zero,
                    glow: s.type == null ? Spice.amber : Spice.poiColor(s.type!),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: q.isNotEmpty || (i == 0 && !s.rowA),
                        leading: s.type == null
                            ? const GlowIcon(icon: Icons.auto_awesome, color: Spice.amber, size: 30)
                            : GlowIcon(icon: Spice.poiIcon(s.type!), color: Spice.poiColor(s.type!), size: 30),
                        title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${items.length} items${s.rowA ? ' · Row A (Mk5)' : ''}',
                            style: Theme.of(context).textTheme.bodySmall),
                        children: [for (final it in items) _LootTile(it)],
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

class _LootTile extends StatelessWidget {
  final LootItem item;
  const _LootTile(this.item);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Spice.tierColor(item.tier))),
          child: NetImage(item.iconUrl, width: 40, height: 40, fit: BoxFit.contain, fallback: Icons.inventory_2),
        ),
      ),
      title: Text(item.name),
      subtitle: Text(item.category, style: t.bodySmall),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (item.dropChance != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(item.dropChance!, style: const TextStyle(color: Spice.amber, fontWeight: FontWeight.w700)),
          ),
        TierBadge(item.tier),
      ]),
      children: [
        if (item.sources.isEmpty)
          const ListTile(dense: true, title: Text('No drop sources listed')),
        for (final s in item.sources)
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(Spice.poiIcon(s.type ?? ''), size: 18, color: Spice.poiColor(s.type ?? '')),
            title: Text(s.poi),
            trailing: Text(s.chance, style: const TextStyle(color: Spice.amber)),
          ),
      ],
    );
  }
}
