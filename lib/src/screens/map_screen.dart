import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/fancy.dart';
import 'poi_sheet.dart';

class MapScreen extends StatefulWidget {
  final DesertData data;
  final int mapIndex;
  final ValueChanged<int> onMapChanged;
  const MapScreen({super.key, required this.data, required this.mapIndex, required this.onMapChanged});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Set<String> _hidden = {};
  bool _showGrid = true;
  final _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.data.maps[widget.mapIndex];
    final visible = map.pois.where((p) => !_hidden.contains(p.type)).toList();
    final types = map.filters.isNotEmpty
        ? map.filters
        : {for (final p in map.pois) p.type: PoiFilter(p.type, p.type, null)}.values.toList();
    return Scaffold(
      body: Column(
        children: [
          HeroHeader(
            title: 'DEEP DESERT',
            subtitle: '${map.label} map · ${widget.data.weekLabel ?? ''}',
            icon: Icons.map,
            actions: [
              IconButton(
                tooltip: _showGrid ? 'Hide grid' : 'Show grid',
                icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off, color: Spice.amber),
                onPressed: () => setState(() => _showGrid = !_showGrid),
              ),
              IconButton(
                tooltip: 'Legend',
                icon: const Icon(Icons.legend_toggle, color: Spice.amber),
                onPressed: () => _showLegend(types),
              ),
              IconButton(
                tooltip: 'Reset zoom',
                icon: const Icon(Icons.center_focus_strong, color: Spice.amber),
                onPressed: () => _controller.value = Matrix4.identity(),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: MapToggle(
                      data: widget.data,
                      index: widget.mapIndex,
                      onChanged: (i) {
                        _controller.value = Matrix4.identity();
                        widget.onMapChanged(i);
                      }),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final f in types)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(Spice.poiIcon(f.type), size: 18, color: Spice.poiColor(f.type)),
                      label: Text('${f.label} (${map.pois.where((p) => p.type == f.type).length})'),
                      selected: !_hidden.contains(f.type),
                      showCheckmark: false,
                      onSelected: (on) => setState(() => on ? _hidden.remove(f.type) : _hidden.add(f.type)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final side = box.biggest.shortestSide;
              return ClipRect(
                child: InteractiveViewer(
                  transformationController: _controller,
                  minScale: 1,
                  maxScale: 8,
                  boundaryMargin: const EdgeInsets.all(80),
                  child: Center(
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: NetImage(map.imageUrl, fit: BoxFit.fill, fallback: Icons.wifi_off),
                          ),
                          if (_showGrid) Positioned.fill(child: CustomPaint(painter: _GridPainter(map))),
                          for (final p in visible) _marker(map, p, side),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '${visible.length} POIs shown · pinch to zoom · tap a marker · positions approximate',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Spice.sand.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLegend(List<PoiFilter> types) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Spice.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('LEGEND', style: display(18)),
            const SizedBox(height: 10),
            for (final f in types)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  GlowIcon(icon: Spice.poiIcon(f.type), color: Spice.poiColor(f.type), size: 28),
                  const SizedBox(width: 14),
                  Text(f.label, style: const TextStyle(fontSize: 15)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _marker(DesertMap map, Poi p, double side) {
    final (fx, fy) = map.position(p);
    const size = 24.0;
    final c = Spice.poiColor(p.type);
    return Positioned(
      left: fx * side - size / 2,
      top: fy * side - size / 2,
      width: size,
      height: size,
      child: Tooltip(
        message: p.name,
        child: GestureDetector(
          onTap: () => showPoiSheet(context, p, map),
          child: GlowIcon(icon: Spice.poiIcon(p.type), color: c, size: size),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final DesertMap map;
  _GridPainter(this.map);

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Spice.amber.withValues(alpha: 0.25)
      ..strokeWidth = 0.6;
    final cw = size.width / map.cols.length, ch = size.height / map.rows.length;
    for (var i = 1; i < map.cols.length; i++) {
      canvas.drawLine(Offset(i * cw, 0), Offset(i * cw, size.height), line);
    }
    for (var i = 1; i < map.rows.length; i++) {
      canvas.drawLine(Offset(0, i * ch), Offset(size.width, i * ch), line);
    }
    for (var r = 0; r < map.rows.length; r++) {
      for (var c = 0; c < map.cols.length; c++) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${map.rows[r]}${map.cols[c]}',
            style: TextStyle(fontSize: 8, color: Spice.sand.withValues(alpha: 0.55)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(c * cw + 2, r * ch + 1));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.map != map;
}
