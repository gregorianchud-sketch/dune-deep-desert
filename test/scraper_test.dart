import 'dart:convert';
import 'dart:io';

import 'package:dune_deep_desert/src/models.dart';
import 'package:dune_deep_desert/src/scraper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final html = File('test/fixtures/deep_desert_companion.html').readAsStringSync();
  final parsed = parseDeepDesertHtml(html);

  test('parser output matches the Python scraper output exactly', () {
    final expected = jsonDecode(File('test/fixtures/expected.json').readAsStringSync());
    final actual = jsonDecode(jsonEncode(parsed)) as Map<String, dynamic>..remove('scraped_at');
    expect(actual, equals(expected));
  });

  test('parsed data loads into the UI models', () {
    final d = DesertData.fromJson(jsonDecode(jsonEncode(parsed)));
    expect(d.weekLabel, isNotEmpty);
    expect(d.maps.map((m) => m.label), containsAll(['Standard', 'Single Player']));
    final std = d.maps.first;
    expect(std.imageUrl, startsWith('https://'));
    expect(std.pois.length, greaterThanOrEqualTo(10));
    expect(std.loot['pve'], isNotEmpty);
    expect(std.loot['pvp'], isNotEmpty);
    expect(d.endgameNotes, isNotEmpty);
  });

  test('broken page throws instead of returning junk', () {
    expect(() => parseDeepDesertHtml('<html><body>nope</body></html>'), throwsA(isA<ScrapeException>()));
  });
}
