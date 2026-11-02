import 'dart:convert';

import 'package:flutter/services.dart';

class LootPreviewItem {
  final String name;
  final String chance;
  LootPreviewItem(this.name, this.chance);
}

class LootPreview {
  final String title;
  final List<LootPreviewItem> items;
  final int? more;
  LootPreview(this.title, this.items, this.more);
}

class Poi {
  final String name;
  final String type;
  final String grid;
  final String row;
  final int col;
  final int subX;
  final int subY;
  final Map<String, String> details;
  final List<String> notes;
  final List<LootPreview> lootPreview;
  final String? thumbnail;
  final String? guideUrl;

  Poi.fromJson(Map<String, dynamic> j)
      : name = j['name'] ?? '',
        type = j['type'] ?? 'unknown',
        grid = j['grid'] ?? '',
        row = j['row'] ?? '',
        col = j['col'] ?? 1,
        subX = j['sub_x'] ?? 2,
        subY = j['sub_y'] ?? 2,
        details = Map<String, String>.from(j['details'] ?? const {}),
        notes = List<String>.from(j['notes'] ?? const []),
        lootPreview = ((j['loot_preview'] ?? {}) as Map<String, dynamic>)
            .entries
            .map((e) => LootPreview(
                  e.key,
                  (e.value['items'] as List)
                      .map((i) => LootPreviewItem(i['name'], i['chance']))
                      .toList(),
                  e.value['more'],
                ))
            .toList(),
        thumbnail = j['thumbnail'],
        guideUrl = j['guide_url'];
}

class PoiFilter {
  final String type;
  final String label;
  final String? iconUrl;
  PoiFilter(this.type, this.label, this.iconUrl);
}

class LootSource {
  final String poi;
  final String? type;
  final String chance;
  LootSource(this.poi, this.type, this.chance);
}

class LootItem {
  final String name;
  final String category;
  final String? tier;
  final String? dropChance;
  final String? iconUrl;
  final List<LootSource> sources;

  LootItem.fromJson(Map<String, dynamic> j)
      : name = j['name'] ?? '',
        category = j['category'] ?? '',
        tier = j['tier'],
        dropChance = j['drop_chance'],
        iconUrl = j['icon_url'],
        sources = (j['sources'] as List? ?? [])
            .map((s) => LootSource(s['poi'] ?? '', s['type'], s['chance'] ?? ''))
            .toList();
}

class LootSection {
  final String title;
  final String? type;
  final bool rowA;
  final List<LootItem> items;

  LootSection.fromJson(Map<String, dynamic> j)
      : title = j['title'] ?? '',
        type = j['type'],
        rowA = j['row_a_collapsed'] ?? false,
        items = (j['items'] as List).map((i) => LootItem.fromJson(i)).toList();
}

class DesertMap {
  final String id;
  final String label;
  final String? imageUrl;
  final List<String> rows;
  final List<int> cols;
  final int subdivisions;
  final List<PoiFilter> filters;
  final List<Poi> pois;
  final Map<String, List<LootSection>> loot;

  DesertMap.fromJson(this.id, Map<String, dynamic> j)
      : label = j['label'] ?? id,
        imageUrl = j['map_image_url'],
        rows = List<String>.from(j['grid']['rows']),
        cols = List<int>.from(j['grid']['cols']),
        subdivisions = j['grid']['subdivisions'] ?? 3,
        filters = (j['filters'] as List)
            .map((f) => PoiFilter(f['type'], f['label'] ?? f['type'], f['icon_url']))
            .toList(),
        pois = (j['pois'] as List).map((p) => Poi.fromJson(p)).toList(),
        loot = ((j['loot'] ?? {}) as Map<String, dynamic>).map((k, v) => MapEntry(
            k, (v as List).map((s) => LootSection.fromJson(s)).toList()));

  /// Fractional (0..1) position of a POI derived from grid cell + 3x3 sub-cell.
  /// Approximate: the source only gives cells, not exact coordinates.
  (double, double) position(Poi p) {
    final r = rows.indexOf(p.row).clamp(0, rows.length - 1);
    final c = cols.indexOf(p.col).clamp(0, cols.length - 1);
    final x = (c + (p.subX - 0.5) / subdivisions) / cols.length;
    final y = (r + (p.subY - 0.5) / subdivisions) / rows.length;
    return (x, y);
  }
}

class DesertData {
  final String source;
  final String sourceName;
  final DateTime? scrapedAt;
  final String? weekLabel;
  final List<DesertMap> maps;
  final List<String> endgameNotes;

  DesertData.fromJson(Map<String, dynamic> j)
      : source = j['source'] ?? '',
        sourceName = j['source_name'] ?? 'Method.gg',
        scrapedAt = DateTime.tryParse(j['scraped_at'] ?? ''),
        weekLabel = j['week_label'],
        maps = ((j['maps'] ?? {}) as Map<String, dynamic>)
            .entries
            .map((e) => DesertMap.fromJson(e.key, e.value))
            .toList(),
        endgameNotes = List<String>.from(j['endgame_notes'] ?? const []);

  static Future<DesertData> loadBundled() async {
    final raw = await rootBundle.loadString('assets/data/deep_desert.json');
    return DesertData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
