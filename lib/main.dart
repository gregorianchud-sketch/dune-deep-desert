import 'package:flutter/material.dart';

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
  DesertData? _data;
  Object? _error;

  @override
  void initState() {
    super.initState();
    Future.wait([DesertData.loadBundled(), Future.delayed(const Duration(milliseconds: 1400))]).then(
      (r) => mounted ? setState(() => _data = r[0] as DesertData) : null,
      onError: (Object e) => mounted ? setState(() => _error = e) : null,
    );
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
      child: _data != null
          ? HomeShell(data: _data!)
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
                  if (_error != null)
                    Text('Failed to load data: $_error')
                  else
                    const SizedBox(width: 140, child: LinearProgressIndicator(color: Spice.orange)),
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
          child: IndexedStack(index: _tab, children: pages),
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
