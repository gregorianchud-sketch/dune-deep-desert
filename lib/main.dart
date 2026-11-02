import 'package:flutter/material.dart';

import 'src/data_repository.dart';
import 'src/models.dart';
import 'src/screens/about_screen.dart';
import 'src/screens/endgame_screen.dart';
import 'src/screens/loot_screen.dart';
import 'src/screens/map_screen.dart';
import 'src/theme.dart';
import 'src/widgets/fancy.dart';

void main() => runApp(const DeepDesertApp());

class DeepDesertApp extends StatelessWidget {
  const DeepDesertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deep Desert Companion',
      debugShowCheckedModeBanner: false,
      theme: Spice.theme(),
      builder: (context, child) => DesertBackground(child: child ?? const SizedBox()),
      home: const SplashGate(),
    );
  }
}

/// Themed splash: pulsing emblem while bundled data loads (min ~1.4s).
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  final _repo = DesertRepository();
  DataResult? _result;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _load(minSplash: true);
  }

  Future<void> _load({bool minSplash = false}) async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    DataResult? r;
    try {
      final f = await Future.wait<Object?>([
        _repo.load(),
        if (minSplash) Future<void>.delayed(const Duration(milliseconds: 1400)),
      ]);
      r = f[0] as DataResult;
    } catch (e) {
      debugPrint('Load failed: $e');
    }
    if (!mounted) return;
    setState(() {
      if (r != null) _result = r;
      _refreshing = false;
    });
    if (!minSplash && r != null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(r.stale ? 'Couldn\'t reach Method.gg, showing saved data' : 'Deep Desert data is up to date'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: _result != null
          ? DataScope(
              result: _result!,
              refreshing: _refreshing,
              refresh: _load,
              child: HomeShell(key: const ValueKey('home'), data: _result!.data),
            )
          : Scaffold(
              key: const ValueKey('splash'),
              body: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                              color: Spice.orange.withValues(alpha: 0.25 + 0.35 * _pulse.value),
                              blurRadius: 30 + 30 * _pulse.value),
                        ],
                      ),
                      child: child,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.asset('assets/icon/icon.png', width: 170, height: 170),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('DEEP DESERT', style: display(30)),
                  const SizedBox(height: 6),
                  Text('COMPANION', style: display(14, color: Spice.sand)),
                  const SizedBox(height: 28),
                  const SizedBox(width: 140, child: LinearProgressIndicator(color: Spice.orange)),
                  const SizedBox(height: 14),
                  Text('Reading this week\'s Deep Desert…',
                      style: TextStyle(color: Spice.sand.withValues(alpha: 0.7), fontSize: 12.5)),
                ]),
              ),
            ),
    );
  }
}

class HomeShell extends StatefulWidget {
  final DesertData data;
  const HomeShell({super.key, required this.data});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  int _tab = 0;
  int _mapIndex = 0;
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 380), value: 1);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _tab) return;
    setState(() => _tab = i);
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    if (_mapIndex >= d.maps.length) _mapIndex = 0;
    final pages = [
      MapScreen(data: d, mapIndex: _mapIndex, onMapChanged: (i) => setState(() => _mapIndex = i)),
      LootScreen(data: d, mapIndex: _mapIndex, onMapChanged: (i) => setState(() => _mapIndex = i)),
      EndgameScreen(data: d),
      AboutScreen(data: d),
    ];
    final curve = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    return Scaffold(
      body: FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curve),
          child: RefreshIndicator(
            color: Spice.orange,
            backgroundColor: Spice.card,
            notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
            onRefresh: () => DataScope.maybeOf(context)?.refresh() ?? Future.value(),
            child: IndexedStack(index: _tab, children: pages),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Loot'),
          NavigationDestination(
              icon: Icon(Icons.military_tech_outlined), selectedIcon: Icon(Icons.military_tech), label: 'Endgame'),
          NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label: 'About'),
        ],
      ),
    );
  }
}
