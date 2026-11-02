import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

class MapToggle extends StatelessWidget {
  final DesertData data;
  final int index;
  final ValueChanged<int> onChanged;
  const MapToggle({super.key, required this.data, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      showSelectedIcon: false,
      segments: [
        for (var i = 0; i < data.maps.length; i++)
          ButtonSegment(value: i, label: Text(data.maps[i].label)),
      ],
      selected: {index},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class TierBadge extends StatelessWidget {
  final String? tier;
  const TierBadge(this.tier, {super.key});

  @override
  Widget build(BuildContext context) {
    if (tier == null) return const SizedBox.shrink();
    final c = Spice.tierColor(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.45), blurRadius: 8)],
      ),
      child: Text(tier!, style: TextStyle(color: c, fontWeight: FontWeight.w800)),
    );
  }
}

class NetImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallback;
  const NetImage(this.url,
      {super.key, this.width, this.height, this.fit = BoxFit.cover, this.fallback = Icons.image_not_supported});

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Container(
          width: width,
          height: height,
          color: Spice.card,
          child: Icon(fallback, color: Spice.brown),
        );
    if (url == null) return placeholder();
    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => placeholder(),
      errorWidget: (_, _, _) => placeholder(),
    );
  }
}
