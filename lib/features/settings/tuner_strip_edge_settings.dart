import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/ui/theme/metro_tuner_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key for tuner pitch strip side.
const String kTunerStripEdgePrefsKey = 'tuner_strip_edge';

/// Which screen edge the vertical pitch strip sits on.
enum TunerStripEdge {
  /// Strip on the left; readouts and controls on the right.
  left,

  /// Strip on the right; readouts and controls on the left.
  right,
}

int _tunerStripEdgeToPrefs(TunerStripEdge edge) => edge.index;

TunerStripEdge _tunerStripEdgeFromPrefs(int? v) {
  if (v == TunerStripEdge.right.index) {
    return TunerStripEdge.right;
  }
  return TunerStripEdge.left;
}

final tunerStripEdgeProvider =
    NotifierProvider<TunerStripEdgeNotifier, TunerStripEdge>(
      TunerStripEdgeNotifier.new,
    );

/// Persists pitch strip horizontal placement (local only).
class TunerStripEdgeNotifier extends Notifier<TunerStripEdge> {
  @override
  TunerStripEdge build() => TunerStripEdge.left;

  Future<void> loadFromPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getInt(kTunerStripEdgePrefsKey);
      state = _tunerStripEdgeFromPrefs(v);
    } on Exception {
      // Tests / platforms without prefs: keep default.
    }
  }

  Future<void> setEdge(TunerStripEdge edge) async {
    state = edge;
    final p = await SharedPreferences.getInstance();
    await p.setInt(kTunerStripEdgePrefsKey, _tunerStripEdgeToPrefs(edge));
  }
}

/// Segmented control for [TunerStripEdge].
class TunerStripEdgePicker extends ConsumerWidget {
  /// Creates a strip edge picker.
  const TunerStripEdgePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.mtTheme;
    final edge = ref.watch(tunerStripEdgeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pitch strip',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: t.space8),
        SegmentedButton<TunerStripEdge>(
          segments: const [
            ButtonSegment<TunerStripEdge>(
              value: TunerStripEdge.left,
              label: Text('Left'),
              icon: Icon(Icons.align_horizontal_left),
            ),
            ButtonSegment<TunerStripEdge>(
              value: TunerStripEdge.right,
              label: Text('Right'),
              icon: Icon(Icons.align_horizontal_right),
            ),
          ],
          selected: {edge},
          onSelectionChanged: (s) {
            if (s.isEmpty) {
              return;
            }
            unawaited(
              ref.read(tunerStripEdgeProvider.notifier).setEdge(s.first),
            );
          },
        ),
      ],
    );
  }
}
