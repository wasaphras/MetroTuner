import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/features/settings/settings_page.dart';
import 'package:metrotuner/features/settings/tuner_strip_edge_settings.dart';
import 'package:metrotuner/features/tuner/tuner_notifier.dart';
import 'package:metrotuner/features/tuner/widgets/pitch_strip.dart';
import 'package:metrotuner/ui/layout/adaptive_breakpoints.dart';
import 'package:metrotuner/ui/layout/phone_layout.dart';
import 'package:metrotuner/ui/theme/metro_tuner_theme.dart';
import 'package:metrotuner/ui/widgets/readout_card.dart';
import 'package:permission_handler/permission_handler.dart';

/// Chromatic tuner screen: readouts, pitch strip, explicit mic Start/Stop.
class TunerPage extends ConsumerStatefulWidget {
  /// Creates the tuner page.
  const TunerPage({super.key});

  @override
  ConsumerState<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends ConsumerState<TunerPage> {
  bool _explainedMicThisSession = false;

  Future<void> _onStartPressed() async {
    final notifier = ref.read(tunerProvider.notifier);
    if (!_explainedMicThisSession) {
      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Microphone'),
          content: const Text(
            'MetroTuner uses the microphone only while tuning is on, '
            'to measure pitch. Audio is processed on your device and is '
            'not recorded or sent anywhere.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (go != true || !context.mounted) {
        return;
      }
      _explainedMicThisSession = true;
    }
    await notifier.start();
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final s = ref.read(tunerProvider);
    if (s.permissionDenied) {
      await _showMicDeniedMessage();
    } else if (s.startFailed) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not start the microphone input.'),
        ),
      );
      notifier.clearErrors();
    }
  }

  Future<void> _showMicDeniedMessage() async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone access'),
        content: const Text(
          'The tuner needs microphone access to hear your instrument. '
          'You can allow it in system settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('dismiss'),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('settings'),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
    if (!context.mounted) {
      return;
    }
    if (action == 'settings') {
      await openAppSettings();
    }
    ref.read(tunerProvider.notifier).clearErrors();
  }

  String _formatCents(double cents) {
    final sign = cents >= 0 ? '+' : '−';
    return '$sign${cents.abs().toStringAsFixed(0)} ¢';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tunerProvider);
    final stripEdge = ref.watch(tunerStripEdgeProvider);
    final notifier = ref.read(tunerProvider.notifier);
    final t = context.mtTheme;
    final scheme = Theme.of(context).colorScheme;

    final p = state.latestPitch;
    final noteText = p?.noteLabel ?? '—';
    final centsText = p != null ? _formatCents(p.centsFromNearest) : '—';
    final hzText = p != null ? '${p.frequencyHz.toStringAsFixed(1)} Hz' : '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuner'),
        actions: const [AppSettingsButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = AdaptiveBreakpoints.useCompactVerticalLayout(
            constraints: constraints,
          );
          final m = PhoneLayoutMetrics.fromConstraints(constraints);
          final pad = EdgeInsets.fromLTRB(
            m.scale(t.space24),
            compact ? m.scale(t.space4) : m.scale(t.space8),
            m.scale(t.space24),
            m.scale(t.space24),
          );

          Widget readoutRowFor(PhoneLayoutMetrics lm) {
            return Row(
              children: [
                Expanded(
                  child: ReadoutCard(
                    label: 'Note',
                    value: noteText,
                    emphasize: true,
                    padding: lm.readoutCardPadding(t),
                    labelValueGap: lm.scale(t.space8),
                    textScale: lm.density,
                  ),
                ),
                SizedBox(width: lm.scale(t.space12)),
                Expanded(
                  child: ReadoutCard(
                    label: 'Cents',
                    value: centsText,
                    emphasize: true,
                    padding: lm.readoutCardPadding(t),
                    labelValueGap: lm.scale(t.space8),
                    textScale: lm.density,
                  ),
                ),
              ],
            );
          }

          Widget frequencyCardFor(PhoneLayoutMetrics lm) {
            return ReadoutCard(
              label: 'Frequency',
              value: hzText,
              emphasize: false,
              padding: lm.readoutCardPadding(t),
              labelValueGap: lm.scale(t.space8),
              textScale: lm.density,
            );
          }

          Widget meterGroupFor(PhoneLayoutMetrics lm) {
            final gapInner = lm.scale(t.space12);
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(t.radiusLg),
                color: scheme.surfaceContainer.withValues(alpha: 0.65),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(lm.scale(t.space12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    readoutRowFor(lm),
                    SizedBox(height: gapInner),
                    frequencyCardFor(lm),
                  ],
                ),
              ),
            );
          }

          Widget startButtonFor(PhoneLayoutMetrics lm) {
            return Semantics(
              label: state.isRunning
                  ? 'Stop microphone and tuner'
                  : 'Start microphone and tuner',
              button: true,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: Size(0, 48 * lm.density),
                  padding: EdgeInsets.symmetric(
                    horizontal: lm.scale(t.space24),
                    vertical: lm.scale(t.space12),
                  ),
                ),
                onPressed: () async {
                  if (state.isRunning) {
                    await notifier.stop();
                  } else {
                    await _onStartPressed();
                  }
                },
                child: Text(state.isRunning ? 'Stop' : 'Start'),
              ),
            );
          }

          return SafeArea(
            bottom: false,
            child: Padding(
              padding: pad,
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  final innerM =
                      PhoneLayoutMetrics.fromConstraints(innerConstraints);
                  final bodyH = innerConstraints.maxHeight;
                  final stripW = innerM.tunerStripWidth(innerConstraints.maxWidth);
                  final strip = SizedBox(
                    width: stripW,
                    height: bodyH,
                    child: PitchStrip(
                      latestPitch: p,
                      isActive: state.isRunning,
                      stripHeight: bodyH,
                    ),
                  );
                  final gapP = innerM.sectionGap(t, compact: compact);
                  final compactControls =
                      innerConstraints.maxHeight <
                          AdaptiveBreakpoints.compactControlsHeightThreshold;

                  final controls = Expanded(
                    child: compactControls
                        ? LayoutBuilder(
                            builder: (context, lc) {
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: lc.maxWidth,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      meterGroupFor(innerM),
                                      SizedBox(height: gapP),
                                      startButtonFor(innerM),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              meterGroupFor(innerM),
                              const Spacer(),
                              startButtonFor(innerM),
                            ],
                          ),
                  );
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: stripEdge == TunerStripEdge.left
                        ? [
                            strip,
                            SizedBox(width: innerM.scale(t.space16)),
                            controls,
                          ]
                        : [
                            controls,
                            SizedBox(width: innerM.scale(t.space16)),
                            strip,
                          ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
