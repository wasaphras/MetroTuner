import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/ui/layout/phone_layout.dart';
import 'package:metrotuner/ui/theme/metro_tuner_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key for persisted accent (32-bit ARGB).
const String kAccentPrefsKey = 'accent_seed_argb';

/// Default cyberpunk accent (neon cyan).
const Color kDefaultAccentSeed = Color(0xFF00F5D4);

(int, int, int) _rgbFromColor(Color c) {
  final v = c.toARGB32();
  return ((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF);
}

bool _isPresetAccent(Color c) {
  final id = c.toARGB32();
  for (final p in kAccentPresets) {
    if (p.toARGB32() == id) {
      return true;
    }
  }
  return false;
}

/// Preset accents for the settings sheet.
const List<Color> kAccentPresets = <Color>[
  Color(0xFF00F5D4),
  Color(0xFFFF00E5),
  Color(0xFF7C4DFF),
  Color(0xFF00E676),
  Color(0xFFFFB74D),
  Color(0xFF18FFFF),
  Color(0xFFFF4081),
  Color(0xFF64FFDA),
];

final accentSeedProvider = NotifierProvider<AccentSeedNotifier, Color>(
  AccentSeedNotifier.new,
);

/// Persists user-selected accent color (local only).
class AccentSeedNotifier extends Notifier<Color> {
  @override
  Color build() => kDefaultAccentSeed;

  Future<void> loadFromPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getInt(kAccentPrefsKey);
      if (v != null) {
        state = Color(v);
      }
    } on Exception {
      // Tests / platforms without prefs: keep default.
    }
  }

  Future<void> setAccent(Color c) async {
    state = c;
    final p = await SharedPreferences.getInstance();
    await p.setInt(kAccentPrefsKey, c.toARGB32());
  }
}

Future<void> _showCustomAccentDialog(
  BuildContext context,
  WidgetRef ref,
  Color initial,
) async {
  final rgb = _rgbFromColor(initial);
  var r = rgb.$1;
  var g = rgb.$2;
  var b = rgb.$3;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocal) {
        final preview = Color.fromRGBO(r, g, b, 1);
        final scheme = Theme.of(context).colorScheme;
        final t = context.mtTheme;
        final previewSize = t.space32 + t.space20;
        return AlertDialog(
          title: const Text('Custom accent'),
          content: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: previewSize,
                      height: previewSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: preview,
                        border: Border.all(color: scheme.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: preview.withValues(alpha: 0.45),
                            blurRadius: t.space8 + t.space4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: t.space16),
                    Expanded(
                      child: Text(
                        '#${r.toRadixString(16).padLeft(2, '0')}'
                                '${g.toRadixString(16).padLeft(2, '0')}'
                                '${b.toRadixString(16).padLeft(2, '0')}'
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: t.space16),
                Semantics(
                  label: 'Red $r',
                  child: Slider(
                    value: r.toDouble(),
                    max: 255,
                    divisions: 255,
                    label: 'Red $r',
                    onChanged: (v) => setLocal(() => r = v.round()),
                  ),
                ),
                Semantics(
                  label: 'Green $g',
                  child: Slider(
                    value: g.toDouble(),
                    max: 255,
                    divisions: 255,
                    label: 'Green $g',
                    onChanged: (v) => setLocal(() => g = v.round()),
                  ),
                ),
                Semantics(
                  label: 'Blue $b',
                  child: Slider(
                    value: b.toDouble(),
                    max: 255,
                    divisions: 255,
                    label: 'Blue $b',
                    onChanged: (v) => setLocal(() => b = v.round()),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                unawaited(
                  ref
                      .read(accentSeedProvider.notifier)
                      .setAccent(
                        Color.fromRGBO(r, g, b, 1),
                      ),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    ),
  );
}

/// Accent swatches and custom color (under **General** on the settings screen).
class AccentColorSection extends ConsumerWidget {
  /// Creates the accent color block.
  const AccentColorSection({super.key, this.layout});

  /// When set, spacing and swatch size follow viewport [PhoneLayoutMetrics].
  final PhoneLayoutMetrics? layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = context.mtTheme;
    final current = ref.watch(accentSeedProvider);
    final gap = layout?.scale(t.space12) ?? t.space12;
    final swatchSize = layout?.scale(44) ?? 44;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Accent color',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: gap),
        Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < kAccentPresets.length; i++)
              _AccentSwatch(
                index: i,
                c: kAccentPresets[i],
                current: current,
                scheme: scheme,
                size: swatchSize,
                onTap: () {
                  unawaited(
                    ref.read(accentSeedProvider.notifier).setAccent(
                      kAccentPresets[i],
                    ),
                  );
                },
              ),
          ],
        ),
        SizedBox(height: gap),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => unawaited(
              _showCustomAccentDialog(
                context,
                ref,
                ref.read(accentSeedProvider),
              ),
            ),
            icon: const Icon(Icons.palette_outlined),
            label: const Text('Custom color…'),
            style: !_isPresetAccent(current)
                ? TextButton.styleFrom(
                    foregroundColor: scheme.primary,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.index,
    required this.c,
    required this.current,
    required this.scheme,
    required this.size,
    required this.onTap,
  });

  final int index;
  final Color c;
  final Color current;
  final ColorScheme scheme;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = c.toARGB32() == current.toARGB32();
    return Semantics(
      button: true,
      label: 'Accent swatch ${index + 1}',
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c,
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outline.withValues(alpha: 0.4),
              width: selected ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: c.withValues(alpha: 0.45),
                blurRadius: selected ? 12 : 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
