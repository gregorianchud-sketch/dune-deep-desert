// Dart port of tool/scrape.py: parses the Method.gg Deep Desert Companion
// page into the same JSON shape the app's models consume.
import 'package:html/dom.dart';
import 'package:html/parser.dart' as hp;

const kSourceUrl = 'https://www.method.gg/dune-awakening/deep-desert-companion';
const _base = 'https://www.method.gg';
const _modes = {'multiplayer': 'Standard', 'singleplayer': 'Single Player'};

class ScrapeException implements Exception {
  final String message;
  ScrapeException(this.message);
  @override
  String toString() => 'ScrapeException: $message';
}

String? _abs(String? u) => (u == null || u.isEmpty || u.startsWith('http')) ? u : '$_base$u';

void _texts(Node n, List<String> out) {
  if (n is Text) {
    final t = n.data.trim();
    if (t.isNotEmpty) out.add(t);
  } else {
    for (final c in n.nodes) {
      _texts(c, out);
    }
  }
}

/// Equivalent of BeautifulSoup `get_text(" ", strip=True)` + whitespace collapse.
String txt(Node? el) {
  if (el == null) return '';
  final out = <String>[];
  _texts(el, out);
  return out.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

Map<String, dynamic> _parseTooltip(String html) {
  final t = hp.parseFragment(html);
  final d = <String, dynamic>{
    'name': txt(t.querySelector('.pin-name')),
    'details': <String, String>{},
    'thumbnail': null,
    'loot_preview': <String, dynamic>{},
  };
  final img = t.querySelector('.pin-image img');
  if (img != null) d['thumbnail'] = _abs(img.attributes['src']);
  String? current;
  final preview = d['loot_preview'] as Map<String, dynamic>;
  for (final tip in t.querySelectorAll('.pin-tip')) {
    final b = tip.querySelector('b');
    if (b != null) {
      current = txt(b);
      preview[current] = <String, dynamic>{'items': <Map<String, String>>[], 'more': null};
      continue;
    }
    final lab = tip.querySelector('.pin-tip-label');
    final s = txt(tip);
    if (lab != null) {
      final lt = txt(lab);
      var k = lt;
      while (k.endsWith(':')) {
        k = k.substring(0, k.length - 1);
      }
      final v = (s.length >= lt.length ? s.substring(lt.length) : '').trim();
      if (current != null) {
        (preview[current]['items'] as List).add({'name': k, 'chance': v});
      } else {
        (d['details'] as Map<String, String>)[k] = v;
      }
    } else if (s.isNotEmpty) {
      final m = RegExp(r'^and (\d+) more').firstMatch(s);
      if (m != null && current != null) {
        preview[current]['more'] = int.parse(m.group(1)!);
      } else if (!s.toLowerCase().startsWith('full list')) {
        (d.putIfAbsent('notes', () => <String>[]) as List<String>).add(s);
      }
    }
  }
  return d;
}

Map<String, dynamic> _parseGrid(Element pane) {
  final g = pane.querySelector('.grid-wrapper');
  if (g == null) throw ScrapeException('grid-wrapper missing');
  final m = RegExp(r"url\('([^']+)'\)").firstMatch(g.attributes['style'] ?? '');
  final cols = <int>{
    for (final a in g.querySelectorAll('.axis-label'))
      if (RegExp(r'^\d+$').hasMatch(txt(a))) int.parse(txt(a))
  }.toList()
    ..sort();
  final rows = <String>[];
  final pois = <Map<String, dynamic>>[];
  for (final cell in g.querySelectorAll('.main-cell')) {
    final parts = (cell.attributes['data-main-cell'] ?? '').split(':');
    if (parts.length != 2) continue;
    final r = parts[0], c = parts[1];
    if (!rows.contains(r)) rows.add(r);
    for (final w in cell.querySelectorAll('.grid-icon-wrap')) {
      final tip = _parseTooltip(w.attributes['data-content'] ?? '');
      final a = w.querySelector('a');
      final icon = w.querySelector('img');
      pois.add({
        'name': tip['name'],
        'type': w.attributes['data-poitype'],
        'grid': '$r$c',
        'row': r,
        'col': int.parse(c),
        'sub_x': int.tryParse(w.attributes['data-subx'] ?? '') ?? 2,
        'sub_y': int.tryParse(w.attributes['data-suby'] ?? '') ?? 2,
        'details': tip['details'],
        'notes': tip['notes'] ?? <String>[],
        'loot_preview': tip['loot_preview'],
        'thumbnail': tip['thumbnail'],
        'guide_url': a != null ? _abs(a.attributes['href']) : null,
        'icon_url': icon != null ? _abs(icon.attributes['src']) : null,
      });
    }
  }
  final filters = [
    for (final f in pane.querySelectorAll('.grid-filter-btn'))
      {
        'type': f.attributes['data-type'],
        'label': f.attributes['title'],
        'icon_url': f.querySelector('img') != null ? _abs(f.querySelector('img')!.attributes['src']) : null,
      }
  ];
  return {
    'map_image_url': m != null ? _abs(m.group(1)) : null,
    'grid': {'rows': rows, 'cols': cols, 'subdivisions': 3, 'row_order': 'top-to-bottom'},
    'filters': filters,
    'pois': pois,
  };
}

List<Map<String, dynamic>> _parseLoot(Element wrapper) {
  final sections = <Map<String, dynamic>>[];
  for (final sec in wrapper.querySelectorAll('.loot-section-block')) {
    final cls = sec.classes.where((c) => c.startsWith('loot-section-type-')).toList();
    final stype = cls.isNotEmpty ? cls.first.replaceAll('loot-section-type-', '') : '';
    final items = <Map<String, dynamic>>[];
    for (final tile in sec.querySelectorAll('.loot-tile')) {
      final tier = txt(tile.querySelector('.loot-tier-list'));
      final link = tile.querySelector('.loot-tile-link');
      final img = tile.querySelector('.loot-tile-image img');
      final sources = <Map<String, dynamic>>[];
      for (final holder in tile.querySelectorAll('.loot-poi-str')) {
        for (final s in holder.children.where((e) => e.localName == 'div')) {
          final st = s.classes.map((c) => c.replaceAll('loot-poi-str-type-', '')).toList();
          sources.add({
            'poi': txt(s.querySelector('.loot-poi-str__name')),
            'type': st.isNotEmpty ? st.first : null,
            'chance': txt(s.querySelector('.loot-poi-str__drop')),
          });
        }
      }
      final drop = txt(tile.querySelector('.loot-drop-chance'));
      items.add({
        'name': txt(tile.querySelector('.loot-name')),
        'category': txt(tile.querySelector('.loot-type')),
        'tier': tier.isEmpty ? null : tier,
        'drop_chance': drop.isEmpty ? null : drop,
        'icon_url': img != null ? _abs(img.attributes['src']) : null,
        'url': link != null ? _abs(link.attributes['href']) : null,
        'sources': sources,
      });
    }
    sections.add({
      'title': txt(sec.querySelector('.loot-section-title')),
      'type': stype.isEmpty ? null : stype,
      'row_a_collapsed': sec.parent?.classes.contains('collapse') ?? false,
      'items': items,
    });
  }
  return sections;
}

String? _weekLabel(Element content) {
  final all = <Text>[];
  void walk(Node n) {
    if (n is Text) {
      all.add(n);
    } else {
      n.nodes.forEach(walk);
    }
  }

  walk(content);
  final i = all.indexWhere((t) => t.data.contains('Updated for:'));
  if (i < 0) return null;
  for (final t in all.skip(i + 1)) {
    final s = t.data.trim();
    if (s.isNotEmpty && !s.contains('Updated for')) return s;
  }
  return null;
}

const _notePatterns = [
  r'In the PVP instance of the Deep Desert, mining yields and spice harvesting is increased by \d+%',
  r'On Single Player, the Deep Desert does not reset with the Coriolis Storm[^.]*\.',
  r'Row A \(Mk5\) loot tables are at the bottom \(collapsed\)\.',
  r'The loot tables below contain all of the Unique Schematics that are available from the Deep Desert each week\.',
  r'Updated shortly after the reset each week\.',
  r'Try switching the map view from Normal to Detailed[^.]*\.',
];

/// Parses the page HTML. Throws [ScrapeException] if the result looks broken.
Map<String, dynamic> parseDeepDesertHtml(String html, {DateTime? now}) {
  final doc = hp.parse(html);
  final content = doc.querySelector('.news-content-list') ?? doc.documentElement!;
  final data = <String, dynamic>{
    'source': kSourceUrl,
    'source_name': 'Method.gg Deep Desert Companion',
    'scraped_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
    'week_label': _weekLabel(content),
    'maps': <String, dynamic>{},
    'endgame_notes': <String>[],
  };
  for (final e in _modes.entries) {
    final pane = content.querySelector('.tab-pane#${e.key}');
    if (pane == null) continue;
    final m = _parseGrid(pane);
    m['label'] = e.value;
    final loot = <String, dynamic>{};
    for (final w in pane.querySelectorAll('.loot-tables-wrapper')) {
      loot[w.attributes['data-loot'] ?? 'pve'] = _parseLoot(w);
    }
    m['loot'] = loot;
    (data['maps'] as Map<String, dynamic>)[e.key] = m;
  }
  final full = txt(content).replaceAll(' .', '.').replaceAll(' ,', ',');
  final notes = data['endgame_notes'] as List<String>;
  for (final p in _notePatterns) {
    final mm = RegExp(p).firstMatch(full);
    if (mm == null) continue;
    var n = mm.group(0)!;
    if (notes.contains(n)) continue;
    while (n.endsWith('.')) {
      n = n.substring(0, n.length - 1);
    }
    notes.add('$n.');
  }
  final std = (data['maps'] as Map)['multiplayer'] as Map?;
  if (std == null || (std['pois'] as List).length < 10 || ((std['loot'] as Map)['pve'] as List?)?.isEmpty != false) {
    throw ScrapeException('Page structure changed: too few POIs or no PvE loot');
  }
  return data;
}
