import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/core/app/package_info_provider.dart';
import 'package:metrotuner/features/settings/accent_settings.dart';
import 'package:metrotuner/features/settings/concert_pitch_section.dart';
import 'package:metrotuner/features/settings/tuner_strip_edge_settings.dart';
import 'package:metrotuner/ui/layout/adaptive_breakpoints.dart';
import 'package:metrotuner/ui/layout/phone_layout.dart';
import 'package:metrotuner/ui/theme/metro_tuner_theme.dart';

/// Pushes [SettingsPage] on the current navigator.
void openSettings(BuildContext context) {
  unawaited(
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => const SettingsPage(),
      ),
    ),
  );
}

/// App bar action: opens [SettingsPage].
class AppSettingsButton extends StatelessWidget {
  /// Creates the settings button.
  const AppSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Settings',
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 48,
      ),
      onPressed: () => openSettings(context),
    );
  }
}

/// Full-screen settings: general (theme, layout, privacy).
class SettingsPage extends ConsumerWidget {
  /// Creates the settings screen.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.mtTheme;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final m = PhoneLayoutMetrics.fromConstraints(constraints);
            final compact =
                constraints.maxHeight <
                AdaptiveBreakpoints.compactHeightThreshold;
            final sectionGap = m.sectionGap(t, compact: compact);
            final pad = EdgeInsets.fromLTRB(
              m.scale(t.space24),
              m.scale(t.space8),
              m.scale(t.space24),
              m.scale(t.space24),
            );
            final titleFs = (tt.titleLarge?.fontSize ?? 22) * m.density;
            final bodyFs = (tt.bodySmall?.fontSize ?? 12) * m.density;
            final column = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'General',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: titleFs,
                  ),
                ),
                SizedBox(height: m.scale(t.space8)),
                Text(
                  'Theme, tuning reference, and tuner layout.',
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: bodyFs,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: sectionGap),
                AccentColorSection(layout: m),
                SizedBox(height: sectionGap),
                const ConcertPitchSection(),
                SizedBox(height: sectionGap),
                const TunerStripEdgePicker(),
                SizedBox(height: sectionGap),
                Text(
                  'Choices are saved on this device only.',
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: bodyFs,
                    height: 1.4,
                  ),
                ),
              ],
            );
            final maxBodyW =
                (constraints.maxWidth - pad.horizontal).clamp(0.0, 640.0);
            final footerPad = EdgeInsets.fromLTRB(
              pad.left,
              m.scale(t.space8),
              pad.right,
              pad.bottom,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        pad.left,
                        pad.top,
                        pad.right,
                        0,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxBodyW),
                          child: SingleChildScrollView(
                            child: column,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: footerPad,
                  child: const Center(
                    child: _SettingsVersionFooter(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Shows `pubspec.yaml` version via [packageInfoProvider] (build-time metadata).
class _SettingsVersionFooter extends ConsumerWidget {
  const _SettingsVersionFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInfo = ref.watch(packageInfoProvider);
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final base = tt.labelSmall ?? const TextStyle(fontSize: 11);
    return asyncInfo.when(
      data: (info) => Text(
        'Version ${info.version}',
        style: base.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
          fontSize: (base.fontSize ?? 11) * 0.92,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
      loading: () => SizedBox(height: (base.fontSize ?? 11) * 1.2),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
