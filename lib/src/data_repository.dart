import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'scraper.dart';

enum DataOrigin { live, cache, bundled }

class DataResult {
  final DesertData data;
  final DataOrigin origin;
  final DateTime? updatedAt;
  final String? error;
  const DataResult(this.data, this.origin, this.updatedAt, [this.error]);
  bool get stale => origin != DataOrigin.live;
}

Map<String, dynamic> _parseInIsolate(String html) => parseDeepDesertHtml(html);

/// Live fetch -> on failure last good cache -> on failure bundled asset.
class DesertRepository {
  static const _cacheKey = 'dd_cache_json_v1';
  static const userAgent =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/130.0.0.0 Mobile Safari/537.36';

  final http.Client _client;
  DesertRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<DataResult> load() async {
    String? err;
    try {
      final res = await _client.get(Uri.parse(kSourceUrl), headers: {
        'User-Agent': userAgent,
        'Accept': 'text/html,application/xhtml+xml',
      }).timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final json = await compute(_parseInIsolate, utf8.decode(res.bodyBytes, allowMalformed: true));
      final data = DesertData.fromJson(json); // validates shape
      unawaited(_saveCache(json));
      return DataResult(data, DataOrigin.live, data.scrapedAt?.toLocal() ?? DateTime.now());
    } catch (e) {
      err = e.toString();
      debugPrint('Live fetch failed: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        final data = DesertData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        return DataResult(data, DataOrigin.cache, data.scrapedAt?.toLocal(), err);
      }
    } catch (e) {
      debugPrint('Cache read failed: $e');
    }
    final data = await DesertData.loadBundled();
    return DataResult(data, DataOrigin.bundled, data.scrapedAt?.toLocal(), err);
  }

  Future<void> _saveCache(Map<String, dynamic> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(json));
    } catch (e) {
      debugPrint('Cache write failed: $e');
    }
  }
}

/// Exposes the current data state + refresh to any widget (e.g. HeroHeader).
class DataScope extends InheritedWidget {
  final DataResult result;
  final bool refreshing;
  final Future<void> Function() refresh;
  const DataScope(
      {super.key, required this.result, required this.refreshing, required this.refresh, required super.child});

  static DataScope? maybeOf(BuildContext c) => c.dependOnInheritedWidgetOfExactType<DataScope>();

  @override
  bool updateShouldNotify(DataScope old) => old.result != result || old.refreshing != refreshing;
}
