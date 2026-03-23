import 'dart:async';

import 'package:flutter/material.dart';
import 'package:metrotuner/features/metronome/metronome_page.dart';
import 'package:metrotuner/features/tuner/tuner_page.dart';

/// Bottom navigation shell: Tuner and Metronome (both kept alive; tuner is default).
class AppShell extends StatefulWidget {
  /// Creates the app shell.
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _navEdgeFlash;

  @override
  void initState() {
    super.initState();
    _navEdgeFlash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _navEdgeFlash.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int i) {
    setState(() => _index = i);
    unawaited(_navEdgeFlash.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseDivider = scheme.outlineVariant.withValues(alpha: 0.28);
    final flash = scheme.primary.withValues(alpha: 0.38);

    return Scaffold(
      // Horizontal insets for notches; top/status bar and bottom nav + home indicator are handled by each
      // [Scaffold] / [NavigationBar]. Avoid stacking bottom padding on tab bodies.
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(
          index: _index,
          // Index 0: Tuner (default), 1: Metronome — matches [NavigationBar] order below.
          children: const [
            TunerPage(),
            MetronomePage(),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _navEdgeFlash,
            builder: (context, child) {
              final t = Curves.easeOutCubic.transform(_navEdgeFlash.value);
              final mix = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Divider(
                height: 1,
                thickness: 1,
                color: Color.lerp(baseDivider, flash, mix),
              );
            },
          ),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _onDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune),
                label: 'Tuner',
              ),
              NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer),
                label: 'Metronome',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
