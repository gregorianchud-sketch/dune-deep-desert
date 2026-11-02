import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../data_repository.dart';
import '../theme.dart';

/// Night-blue to burnt-sand gradient with a subtle sand-grain texture.
class DesertBackground extends StatelessWidget {
  final Widget child;
  const DesertBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Spice.night, Spice.black, Color(0xFF2A1A0E), Color(0xFF4A2C14)],
          stops: [0, 0.45, 0.8, 1],
        ),
      ),
      child: Stack(children: [
        const Positioned.fill(child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: _GrainPainter())))),
        child,
      ]),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(42);
    final p = Paint();
    final n = (size.width * size.height / 90).clamp(0, 30000).toInt();
    for (var i = 0; i < n; i++) {
      p.color = (rnd.nextBool() ? Spice.sand : Colors.black).withValues(alpha: rnd.nextDouble() * 0.05);
      canvas.drawRect(Rect.fromLTWH(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height, 1.2, 1.2), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Frosted glass card with amber border and soft spice glow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? glow;
  const GlassCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(14),
      this.margin = const EdgeInsets.symmetric(vertical: 6),
      this.glow});

  @override
  Widget build(BuildContext context) {
    final g = glow ?? Spice.orange;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: g.withValues(alpha: 0.18), blurRadius: 18, spreadRadius: -4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Spice.amber.withValues(alpha: 0.35)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withValues(alpha: 0.07), Spice.card.withValues(alpha: 0.55)],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

TextStyle display(double size, {Color color = Spice.amber}) => GoogleFonts.cinzel(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
      color: color,
      shadows: [Shadow(color: Spice.orange.withValues(alpha: 0.6), blurRadius: 12)],
    );

/// Hero header shown at the top of each tab.
class HeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> actions;
  const HeroHeader({super.key, required this.title, required this.subtitle, required this.icon, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final scope = DataScope.maybeOf(context);
    final header = Container(
      padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 14, 8, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Spice.orange.withValues(alpha: 0.22), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: Spice.amber.withValues(alpha: 0.25))),
      ),
      child: Row(children: [
        Hero(
          tag: 'hero-$title',
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [Spice.amber, Spice.orange, Spice.brown]),
              boxShadow: [BoxShadow(color: Spice.orange.withValues(alpha: 0.6), blurRadius: 16)],
            ),
            child: Icon(icon, color: Spice.black),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: display(22)),
            const SizedBox(height: 2),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Spice.sand.withValues(alpha: 0.7), fontSize: 12.5)),
          ]),
        ),
        ...actions,
        if (scope != null)
          scope.refreshing
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Spice.amber)),
                )
              : IconButton(
                  tooltip: 'Refresh data',
                  icon: const Icon(Icons.refresh, color: Spice.amber),
                  onPressed: scope.refresh,
                ),
      ]),
    );
    if (scope == null) return header;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      header,
      _StatusStrip(result: scope.result),
    ]);
  }
}

class _StatusStrip extends StatelessWidget {
  final DataResult result;
  const _StatusStrip({required this.result});

  static String _fmt(DateTime? t) {
    if (t == null) return 'unknown';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[t.month - 1]} ${t.day}';
  }

  @override
  Widget build(BuildContext context) {
    final week = result.data.weekLabel ?? '?';
    final line = 'Updated ${_fmt(result.updatedAt)} · Week $week';
    final stale = result.stale;
    final color = stale ? Spice.orange : Spice.amber;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withValues(alpha: stale ? 0.20 : 0.08),
          Colors.transparent,
        ]),
        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.18))),
      ),
      child: Row(children: [
        Icon(stale ? Icons.cloud_off : Icons.wb_sunny_outlined, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            stale
                ? '$line · ${result.origin == DataOrigin.cache ? 'Offline copy' : 'Built-in copy'}, data may be stale'
                : line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Spice.sand.withValues(alpha: 0.75), fontSize: 11.5, letterSpacing: 0.3),
          ),
        ),
      ]),
    );
  }
}

/// Glowing circular icon used for map markers and legend.
class GlowIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const GlowIcon({super.key, required this.icon, required this.color, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [Spice.black, Spice.black.withValues(alpha: 0.85)]),
        border: Border.all(color: color, width: 1.6),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.75), blurRadius: size * 0.45),
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: size, spreadRadius: 1),
        ],
      ),
      child: Icon(icon, size: size * 0.6, color: color),
    );
  }
}
