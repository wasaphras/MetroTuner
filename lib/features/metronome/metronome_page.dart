import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/core/metronome/metronome_models.dart';
import 'package:metrotuner/core/metronome/metronome_scheduler.dart';
import 'package:metrotuner/features/metronome/metronome_notifier.dart';
import 'package:metrotuner/features/metronome/metronome_sound_page.dart';
import 'package:metrotuner/features/settings/settings_page.dart';
import 'package:metrotuner/ui/layout/adaptive_breakpoints.dart';
import 'package:metrotuner/ui/layout/phone_layout.dart';
import 'package:metrotuner/ui/theme/metro_tuner_theme.dart';

/// Keeps metronome controls grouped on wide vs narrow viewports.
const double _kMetronomeBodyMaxWidth = 640;

/// Wall-clock presets for timed practice sessions.
const List<Duration> _kSessionPresetDurations = [
  Duration(minutes: 5),
  Duration(minutes: 10),
  Duration(minutes: 15),
  Duration(minutes: 30),
];

/// Formats [d] as `MM:SS`, or `H:MM:SS` when an hour or more (tabular digits).
String _formatSessionClock(Duration d) {
  if (d.isNegative) {
    return _formatSessionClock(Duration.zero);
  }
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String _sessionPresetChipLabel(Duration d) {
  final mins = d.inMinutes;
  if (Duration(minutes: mins) == d) {
    return '$mins min';
  }
  return _formatSessionClock(d);
}

/// Section label for tempo / meter cards (consistent inset and rhythm).
Widget _metronomeSectionTitle(
  String text, {
  required ThemeData theme,
  required ColorScheme scheme,
  required MetroTunerTheme t,
  required PhoneLayoutMetrics m,
  bool dense = false,
}) {
  final base = dense ? theme.textTheme.labelMedium : theme.textTheme.labelLarge;
  final baseSize = base?.fontSize;
  final style = base?.copyWith(
    color: scheme.onSurfaceVariant,
    fontWeight: FontWeight.w600,
    letterSpacing: dense ? 0.35 : 0.45,
    fontSize: baseSize != null ? baseSize * m.density : null,
  );
  return Padding(
    padding: EdgeInsets.only(
      bottom: m.scale(dense ? t.space4 : t.space12),
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: style),
    ),
  );
}

/// Metronome screen: BPM, time signature, start/stop, tap tempo, beat flash.
class MetronomePage extends ConsumerWidget {
  /// Creates the metronome page.
  const MetronomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Exclude beatFlashGeneration so the page does not rebuild every beat (was janking the UI).
    final layout = ref.watch(
      metronomeProvider.select(
        (s) => (bpm: s.bpm, meter: s.meter, isRunning: s.isRunning),
      ),
    );
    final notifier = ref.read(metronomeProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = context.mtTheme;

    final metronomeTheme = theme.copyWith(
      cardTheme: theme.cardTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusMd),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
      ),
    );

    return Theme(
      data: metronomeTheme,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: kToolbarHeight,
          title: const Text('Metronome'),
          actions: const [AppSettingsButton()],
          actionsPadding: const EdgeInsetsDirectional.only(end: 4),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
          final compact = AdaptiveBreakpoints.useCompactVerticalLayout(
            constraints: constraints,
          );
          final narrow = constraints.maxWidth < 360;
          final m = PhoneLayoutMetrics.fromConstraints(constraints);
          final pad = EdgeInsets.fromLTRB(
            narrow ? m.scale(t.space12) : m.scale(t.space24),
            compact ? m.scale(t.space4) : m.scale(t.space8),
            narrow ? m.scale(t.space12) : m.scale(t.space24),
            m.scale(t.space24),
          );
          final cardPad = m.cardPadding(t, compact: compact);

          final availableH = constraints.maxHeight - pad.vertical;
          final availableW = constraints.maxWidth - pad.horizontal;
          final bodyW = math.min(availableW, _kMetronomeBodyMaxWidth);
          return SafeArea(
            bottom: false,
            child: Padding(
              padding: pad,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _kMetronomeBodyMaxWidth,
                    maxHeight: math.max(0, availableH),
                  ),
                  child: SizedBox(
                    width: bodyW,
                    height: math.max(0, availableH),
                    child: _metronomeColumn(
                      context: context,
                      bpm: layout.bpm,
                      meter: layout.meter,
                      isRunning: layout.isRunning,
                      notifier: notifier,
                      theme: theme,
                      scheme: scheme,
                      t: t,
                      cardPad: cardPad,
                      contentWidth: bodyW,
                      compact: compact,
                      m: m,
                    ),
                  ),
                ),
              ),
            ),
          );
          },
        ),
      ),
    );
  }
}

/// Pendulum sweep: dot oscillates L↔R each beat; clicks align with center (phase).
///
/// Paint and flash are split so only the flash subscribes to [MetronomeState.beatFlashGeneration];
/// the rest of the metronome page watches BPM/meter/isRunning only (avoids rebuild jank each beat).
class BeatSweepBar extends StatelessWidget {
  /// Creates the beat sweep bar.
  const BeatSweepBar({
    required this.beatH,
    required this.trackHeight,
    super.key,
  });

  /// Total height of the widget (slot or preferred size).
  final double beatH;

  /// Painted rail thickness from [PhoneLayoutMetrics.metronomeTrackHeight].
  final double trackHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Beat indicator',
      child: SizedBox(
        height: beatH,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              alignment: Alignment.center,
              children: [
                RepaintBoundary(
                  child: _PendulumPaintLayer(
                    beatH: beatH,
                    width: w,
                    trackHeight: trackHeight,
                  ),
                ),
                RepaintBoundary(
                  child: _BeatFlashLayer(
                    beatH: beatH,
                    width: w,
                    trackHeight: trackHeight,
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

class _PendulumPaintLayer extends ConsumerStatefulWidget {
  const _PendulumPaintLayer({
    required this.beatH,
    required this.width,
    required this.trackHeight,
  });

  final double beatH;
  final double width;
  final double trackHeight;

  @override
  ConsumerState<_PendulumPaintLayer> createState() =>
      _PendulumPaintLayerState();
}

class _PendulumPaintLayerState extends ConsumerState<_PendulumPaintLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ref.read(metronomeProvider).isRunning) {
        unawaited(_ticker.start());
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      metronomeProvider.select((s) => s.isRunning),
      (prev, next) {
        if (next) {
          unawaited(_ticker.start());
        } else {
          _ticker.stop();
        }
      },
    );

    final transport = ref.watch(
      metronomeProvider.select((s) => (s.bpm, s.isRunning)),
    );
    final bpm = transport.$1;
    final isRunning = transport.$2;

    final notifier = ref.read(metronomeProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final t = context.mtTheme;
    final interval = MetronomeScheduler.beatIntervalMicros(bpm);
    final elapsed = notifier.transportElapsedMicros;
    final frac = isRunning && interval > 0
        ? MetronomeScheduler.pendulumSweep01(
            elapsedMicros: elapsed,
            beatIntervalMicros: interval,
          )
        : 0.0;

    final w = widget.width;
    final h = widget.beatH;
    return CustomPaint(
      size: Size(w, h),
      painter: _BeatSweepPainter(
        width: w,
        height: h,
        trackHeight: widget.trackHeight,
        fraction: frac,
        isRunning: isRunning,
        scheme: scheme,
        studioAccent: t.studioAccent,
        vuGlow: t.vuGlowAlpha.clamp(0.0, 1.0),
        trackCornerRadius: t.radiusXs,
      ),
    );
  }
}

class _BeatFlashLayer extends ConsumerWidget {
  const _BeatFlashLayer({
    required this.beatH,
    required this.width,
    required this.trackHeight,
  });

  final double beatH;
  final double width;
  final double trackHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flash = ref.watch(
      metronomeProvider.select((s) => (s.beatFlashGeneration, s.isRunning)),
    );
    final gen = flash.$1;
    final isRunning = flash.$2;
    final scheme = Theme.of(context).colorScheme;
    final t = context.mtTheme;

    if (!isRunning) {
      return const SizedBox.shrink();
    }

    final w = width;
    final h = beatH;
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(gen),
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: t.beatFlashMs),
      curve: t.beatFlashCurve,
      builder: (context, pulse, _) {
        final a = (1 - pulse) * 0.55;
        return IgnorePointer(
          child: CustomPaint(
            size: Size(w, h),
            painter: _CenterFlashPainter(
              width: w,
              height: h,
              trackHeight: trackHeight,
              opacity: a.clamp(0.0, 1.0),
              color: scheme.primary,
            ),
          ),
        );
      },
    );
  }
}

class _BeatSweepPainter extends CustomPainter {
  _BeatSweepPainter({
    required this.width,
    required this.height,
    required this.trackHeight,
    required this.fraction,
    required this.isRunning,
    required this.scheme,
    required this.studioAccent,
    required this.vuGlow,
    required this.trackCornerRadius,
  });

  final double width;
  final double height;
  final double trackHeight;
  final double fraction;
  final bool isRunning;
  final ColorScheme scheme;
  final Color studioAccent;
  final double vuGlow;
  final double trackCornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final trackH = math.min(trackHeight, size.height * 0.92);
    final top = (size.height - trackH) / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, top, size.width, trackH),
      Radius.circular(trackCornerRadius),
    );
    final trackPaint = Paint()
      ..color = scheme.surfaceContainerHighest.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, trackPaint);
    final borderPaint = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rrect, borderPaint);

    final cx = size.width / 2;
    final linePaint = Paint()
      ..color = scheme.onSurface.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, top - 4),
      Offset(cx, top + trackH + 4),
      linePaint,
    );

    if (isRunning) {
      const glowPad = 26.0;
      final travel = (size.width - 2 * glowPad).clamp(0.0, double.infinity);
      final x =
          glowPad + (fraction.clamp(0.0, 1.0)) * travel;
      final cy = top + trackH / 2;
      final glow =
          Paint()
            ..color = studioAccent.withValues(alpha: 0.35 * vuGlow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(x, cy), 14, glow);
      final corePaint =
          Paint()
            ..color = studioAccent.withValues(alpha: 0.95)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, cy), 7, corePaint);
      final rimPaint =
          Paint()
            ..color = scheme.surface.withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(x, cy), 7, rimPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BeatSweepPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.trackHeight != trackHeight ||
        oldDelegate.scheme != scheme ||
        oldDelegate.studioAccent != studioAccent ||
        oldDelegate.trackCornerRadius != trackCornerRadius;
  }
}

class _CenterFlashPainter extends CustomPainter {
  _CenterFlashPainter({
    required this.width,
    required this.height,
    required this.trackHeight,
    required this.opacity,
    required this.color,
  });

  final double width;
  final double height;
  final double trackHeight;
  final double opacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) {
      return;
    }
    final trackH = math.min(trackHeight, size.height * 0.92);
    final top = (size.height - trackH) / 2;
    final cy = top + trackH / 2;
    final cx = size.width / 2;
    final p =
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(cx, cy), 22, p);
  }

  @override
  bool shouldRepaint(covariant _CenterFlashPainter oldDelegate) {
    return oldDelegate.opacity != opacity ||
        oldDelegate.color != color ||
        oldDelegate.trackHeight != trackHeight ||
        oldDelegate.width != width ||
        oldDelegate.height != height;
  }
}

Widget _animatedBpmDigits({
  required int bpm,
  required MetroTunerTheme t,
  required ThemeData theme,
  double density = 1,
}) {
  final base = theme.textTheme.displayLarge;
  final fs = base?.fontSize;
  return AnimatedSwitcher(
    duration: Duration(milliseconds: t.readoutCrossFadeMs),
    switchInCurve: t.readoutSwitchCurve,
    switchOutCurve: t.readoutSwitchCurve,
    transitionBuilder: (child, animation) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
          child: child,
        ),
      );
    },
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '$bpm',
        key: ValueKey<int>(bpm),
        textAlign: TextAlign.center,
        maxLines: 1,
        style: base?.copyWith(
          fontSize: fs != null ? fs * density : null,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}

Widget _tempoFullCard({
  required ThemeData theme,
  required ColorScheme scheme,
  required int bpm,
  required MetronomeNotifier notifier,
  required MetroTunerTheme t,
  required double cardPad,
  required PhoneLayoutMetrics m,
  required bool compact,
  required bool fillHeight,
  bool dense = false,
}) {
  final pad = dense ? cardPad * 0.62 : cardPad;
  final gapMd = m.scale(compact || dense ? t.space12 : t.space16);
  final iconStyle = IconButton.styleFrom(
    backgroundColor: scheme.surfaceContainerHigh,
    foregroundColor: scheme.onSurface,
    disabledBackgroundColor: scheme.surfaceContainerHighest.withValues(
      alpha: 0.5,
    ),
    disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
    visualDensity: VisualDensity.compact,
  );
  return Card(
    child: Padding(
      padding: EdgeInsets.all(pad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dec = IconButton(
            style: iconStyle,
            onPressed: bpm > MetronomeScheduler.minBpm
                ? notifier.decrementBpm
                : null,
            icon: const Icon(Icons.remove),
            tooltip: 'Decrease BPM',
          );
          final inc = IconButton(
            style: iconStyle,
            onPressed: bpm < MetronomeScheduler.maxBpm
                ? notifier.incrementBpm
                : null,
            icon: const Icon(Icons.add),
            tooltip: 'Increase BPM',
          );
          final sliderPad = m.scale(t.space8);
          final slider = Padding(
            padding: EdgeInsets.symmetric(horizontal: sliderPad),
            child: Semantics(
              label: 'Tempo, $bpm BPM',
              child: Slider(
                value: bpm.toDouble(),
                min: MetronomeScheduler.minBpm.toDouble(),
                max: MetronomeScheduler.maxBpm.toDouble(),
                divisions:
                    MetronomeScheduler.maxBpm - MetronomeScheduler.minBpm,
                label: '$bpm',
                onChanged: (v) => notifier.setBpm(v.round()),
              ),
            ),
          );
          final bpmLabelStyle = theme.textTheme.titleMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
            fontSize: theme.textTheme.titleMedium?.fontSize != null
                ? theme.textTheme.titleMedium!.fontSize! * m.density
                : null,
          );
          final bpmBlock = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _animatedBpmDigits(bpm: bpm, t: t, theme: theme, density: m.density),
              Text('BPM', textAlign: TextAlign.center, style: bpmLabelStyle),
            ],
          );
          final bpmStepGap = m.scale(dense ? t.space8 : t.space12);
          final bpmRow = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              bpmBlock,
              SizedBox(width: bpmStepGap),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [dec, inc],
              ),
            ],
          );
          final readoutAndSteppers = Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: bpmRow,
            ),
          );
          final sectionTitle = _metronomeSectionTitle(
            'Tempo',
            theme: theme,
            scheme: scheme,
            t: t,
            m: m,
            dense: dense,
          );
          final contentBelowTitle = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              readoutAndSteppers,
              SizedBox(height: gapMd),
              slider,
            ],
          );
          final column = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              sectionTitle,
              contentBelowTitle,
            ],
          );
          if (fillHeight && constraints.hasBoundedHeight) {
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle,
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: contentBelowTitle,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          if (!constraints.hasBoundedHeight) {
            return column;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sectionTitle,
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: contentBelowTitle,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

Future<void> _showCustomSessionDurationDialog({
  required BuildContext context,
  required MetronomeNotifier notifier,
}) async {
  final minCtrl = TextEditingController(text: '10');
  final secCtrl = TextEditingController(text: '0');
  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Custom session length'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Minutes',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  TextField(
                    controller: minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0–1439',
                    ),
                    onChanged: (_) => setLocal(() => errorText = null),
                  ),
                  SizedBox(height: MediaQuery.textScalerOf(context).scale(12)),
                  Text(
                    'Seconds',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  TextField(
                    controller: secCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0–59',
                    ),
                    onChanged: (_) => setLocal(() => errorText = null),
                  ),
                  if (errorText != null) ...[
                    SizedBox(height: MediaQuery.textScalerOf(context).scale(8)),
                    Text(
                      errorText!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final m = int.tryParse(minCtrl.text.trim()) ?? 0;
                    final s = int.tryParse(secCtrl.text.trim()) ?? 0;
                    if (m < 0 || s < 0 || s > 59) {
                      setLocal(() {
                        errorText = 'Use minutes 0–1439 and seconds 0–59.';
                      });
                      return;
                    }
                    final total = Duration(minutes: m, seconds: s);
                    if (total < kMetronomeSessionTargetMin) {
                      setLocal(() {
                        errorText =
                            'Session must be at least 1 second.';
                      });
                      return;
                    }
                    notifier.setSessionTargetDuration(total);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    minCtrl.dispose();
    secCtrl.dispose();
  }
}

Future<void> _showCustomMeterDialog({
  required BuildContext context,
  required Meter meter,
  required void Function(Meter) onApply,
}) async {
  var beats = meter.beatsPerBar;
  var unit = meter.beatUnit;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocal) {
        return AlertDialog(
          title: const Text('Custom time signature'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Beats per bar',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              DropdownButton<int>(
                value: beats,
                isExpanded: true,
                items: [
                  for (
                    var i = Meter.minBeatsPerBar;
                    i <= Meter.maxBeatsPerBar;
                    i++
                  )
                    DropdownMenuItem(value: i, child: Text('$i')),
                ],
                onChanged: (v) => setLocal(() => beats = v ?? beats),
              ),
              Text(
                'Beat unit',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              DropdownButton<int>(
                value: unit,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 4, child: Text('4')),
                  DropdownMenuItem(value: 8, child: Text('8')),
                  DropdownMenuItem(value: 16, child: Text('16')),
                ],
                onChanged: (v) => setLocal(() => unit = v ?? unit),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                onApply(Meter(beats, unit));
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    ),
  );
}

Widget _meterCard({
  required BuildContext context,
  required ThemeData theme,
  required Meter meter,
  required MetronomeNotifier notifier,
  required MetroTunerTheme t,
  required double cardPad,
  required PhoneLayoutMetrics m,
  required bool compact,
  required bool fillHeight,
  bool dense = false,
}) {
  final chipGap = m.scale(compact || dense ? t.space4 : t.space8);
  final pad = dense ? cardPad * 0.62 : cardPad;
  return Card(
    child: Padding(
      padding: EdgeInsets.all(pad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final presetChips = Wrap(
            spacing: chipGap,
            runSpacing: chipGap,
            alignment: WrapAlignment.center,
            children: [
              for (final meterPreset in Meter.presets)
                Semantics(
                  label: 'Time signature ${meterPreset.label}',
                  selected: meter == meterPreset,
                  child: ChoiceChip(
                    label: Text(meterPreset.label),
                    selected: meter == meterPreset,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => notifier.setMeter(meterPreset),
                  ),
                ),
            ],
          );
          final customMeterChip = Semantics(
            label: 'Custom time signature',
            child: ActionChip(
              avatar: Icon(Icons.tune, size: dense ? 16 : 18),
              visualDensity: VisualDensity.compact,
              label: Text(
                Meter.presets.contains(meter) ? 'Custom…' : meter.label,
              ),
              onPressed: () => _showCustomMeterDialog(
                context: context,
                meter: meter,
                onApply: notifier.setMeter,
              ),
            ),
          );
          final column = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _metronomeSectionTitle(
                'Time signature',
                theme: theme,
                scheme: theme.colorScheme,
                t: t,
                m: m,
                dense: dense,
              ),
              presetChips,
              SizedBox(height: chipGap),
              Center(child: customMeterChip),
            ],
          );
          if (fillHeight && constraints.hasBoundedHeight) {
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: column,
                ),
              ),
            );
          }
          if (!constraints.hasBoundedHeight) {
            return column;
          }
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: column,
            ),
          );
        },
      ),
    ),
  );
}

/// Elapsed uses [MetronomeNotifier.transportElapsedMicros] (0 when stopped).
/// With a session target, shows remaining while running and target when stopped.
class _SessionClockReadout extends ConsumerStatefulWidget {
  const _SessionClockReadout({this.compact = false});

  final bool compact;

  @override
  ConsumerState<_SessionClockReadout> createState() =>
      _SessionClockReadoutState();
}

class _SessionClockReadoutState extends ConsumerState<_SessionClockReadout> {
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _armTicker(bool running) {
    _tick?.cancel();
    _tick = null;
    if (running) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ref.read(metronomeProvider).isRunning) {
        _armTicker(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      metronomeProvider.select((s) => s.isRunning),
      (prev, next) {
        _armTicker(next);
        setState(() {});
      },
    );

    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final target = ref.watch(
      metronomeProvider.select((s) => s.sessionTargetDuration),
    );
    final isRunning = ref.watch(
      metronomeProvider.select((s) => s.isRunning),
    );
    final notifier = ref.read(metronomeProvider.notifier);
    final elapsed = Duration(
      microseconds: notifier.transportElapsedMicros,
    );
    final monoBase =
        widget.compact ? theme.textTheme.titleSmall : theme.textTheme.titleMedium;
    final mono = monoBase?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w600,
    );
    final subtleBase =
        widget.compact ? theme.textTheme.labelSmall : theme.textTheme.bodySmall;
    final subtle = subtleBase?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Elapsed ${_formatSessionClock(elapsed)}',
          child: Text(
            _formatSessionClock(elapsed),
            textAlign: TextAlign.center,
            style: mono,
          ),
        ),
        if (target != null) ...[
          SizedBox(height: MediaQuery.textScalerOf(context).scale(2)),
          if (isRunning)
            Semantics(
              label:
                  'Remaining ${_formatSessionClock(notifier.sessionRemainingOrNull ?? Duration.zero)}',
              child: Text(
                'Remaining ${_formatSessionClock(notifier.sessionRemainingOrNull ?? Duration.zero)}',
                textAlign: TextAlign.center,
                style: subtle,
              ),
            )
          else
            Semantics(
              label: 'Session target ${_formatSessionClock(target)}',
              child: Text(
                'Target ${_formatSessionClock(target)}',
                textAlign: TextAlign.center,
                style: subtle,
              ),
            ),
        ],
      ],
    );
  }
}

class _MetronomeSessionBody extends ConsumerWidget {
  const _MetronomeSessionBody({
    required this.scheme,
    required this.t,
    required this.m,
    this.dense = false,
  });

  final ColorScheme scheme;
  final MetroTunerTheme t;
  final PhoneLayoutMetrics m;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(
      metronomeProvider.select((s) => s.sessionTargetDuration),
    );
    final notifier = ref.read(metronomeProvider.notifier);
    final chipGap = m.scale(dense ? t.space4 : t.space8);
    final presetCustom =
        target != null &&
        !_kSessionPresetDurations.any((d) => d == target);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _metronomeSectionTitle(
          'Session',
          theme: Theme.of(context),
          scheme: scheme,
          t: t,
          m: m,
          dense: dense,
        ),
        SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SessionClockReadout(compact: dense),
              if (target != null) ...[
                SizedBox(height: m.scale(t.space4)),
                Semantics(
                  button: true,
                  label: 'Clear session limit',
                  child: TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.symmetric(
                        horizontal: m.scale(t.space8),
                        vertical: dense ? m.scale(t.space4) : m.scale(t.space8),
                      ),
                    ),
                    onPressed: notifier.clearSessionTarget,
                    child: const Text('No limit'),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: m.scale(dense ? t.space4 : t.space12)),
        Wrap(
          spacing: chipGap,
          runSpacing: chipGap,
          alignment: WrapAlignment.center,
          children: [
            for (final d in _kSessionPresetDurations)
              Semantics(
                label: 'Session ${_sessionPresetChipLabel(d)}',
                selected: target == d,
                child: ChoiceChip(
                  label: Text(_sessionPresetChipLabel(d)),
                  selected: target == d,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => notifier.setSessionTargetDuration(d),
                ),
              ),
          ],
        ),
        SizedBox(height: chipGap),
        Center(
          child: Semantics(
            label: 'Custom session length',
            selected: presetCustom,
            child: ActionChip(
              avatar: Icon(Icons.schedule, size: dense ? 16 : 18),
              visualDensity: VisualDensity.compact,
              label: Text(
                presetCustom ? _formatSessionClock(target) : 'Custom length…',
              ),
              onPressed: () => _showCustomSessionDurationDialog(
                context: context,
                notifier: notifier,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget _metronomeSessionStrip({
  required ColorScheme scheme,
  required MetroTunerTheme t,
  required double cardPad,
  required PhoneLayoutMetrics m,
  bool dense = false,
}) {
  final pad = dense ? cardPad * 0.62 : cardPad;
  return Material(
    color: scheme.surfaceContainer,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(t.radiusMd),
      side: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.32),
      ),
    ),
    child: Padding(
      padding: EdgeInsets.all(pad),
      child: _MetronomeSessionBody(
        scheme: scheme,
        t: t,
        m: m,
        dense: dense,
      ),
    ),
  );
}

/// Transport (tap tempo + start) on a single surface — grouped above tempo/meter.
Widget _transportStrip({
  required ColorScheme scheme,
  required MetroTunerTheme t,
  required bool isRunning,
  required MetronomeNotifier notifier,
  required double cardPad,
  required PhoneLayoutMetrics m,
}) {
  return Material(
    color: scheme.surfaceContainer,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(t.radiusMd),
      side: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.32),
      ),
    ),
    child: Padding(
      padding: EdgeInsets.all(cardPad),
      child: _TransportRow(
        scheme: scheme,
        isRunning: isRunning,
        notifier: notifier,
        t: t,
        m: m,
      ),
    ),
  );
}

/// Secondary action: sound design (below session on the metronome tab).
Widget _metronomeSoundControl(
  BuildContext context,
  ColorScheme scheme,
  MetroTunerTheme t,
  PhoneLayoutMetrics m, {
  bool dense = false,
}) {
  final minH = (dense ? 40.0 : 46.0) * m.density;
  return Semantics(
    button: true,
    label: 'Metronome sound, change click pitch and timbre',
    child: Tooltip(
      message: 'Change metronome click sound, pitch, and effects',
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: Size.fromHeight(minH),
            padding: EdgeInsets.symmetric(
              horizontal: m.scale(dense ? t.space12 : t.space16),
              vertical: dense ? m.scale(t.space4) : m.scale(t.space8),
            ),
            foregroundColor: scheme.onSurfaceVariant,
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(t.radiusSm),
            ),
          ),
          onPressed: () => openMetronomeSound(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.graphic_eq,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              SizedBox(width: m.scale(t.space8)),
              const Flexible(
                child: Text(
                  'Metronome sound',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TransportRow extends StatefulWidget {
  const _TransportRow({
    required this.scheme,
    required this.isRunning,
    required this.notifier,
    required this.t,
    required this.m,
  });

  final ColorScheme scheme;
  final bool isRunning;
  final MetronomeNotifier notifier;
  final MetroTunerTheme t;
  final PhoneLayoutMetrics m;

  @override
  State<_TransportRow> createState() => _TransportRowState();
}

class _TransportRowState extends State<_TransportRow> {
  bool _tapDown = false;
  bool _runDown = false;

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final t = widget.t;
    final m = widget.m;
    final btnMinH = 44 * m.density;
    final tap = Tooltip(
      message: 'Tap tempo',
      child: Listener(
        onPointerDown: (_) => setState(() => _tapDown = true),
        onPointerUp: (_) => setState(() => _tapDown = false),
        onPointerCancel: (_) => setState(() => _tapDown = false),
        child: AnimatedScale(
          scale: _tapDown ? 0.98 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: Size(0, btnMinH),
              padding: EdgeInsets.symmetric(
                horizontal: m.scale(t.space16),
                vertical: m.scale(t.space8),
              ),
              foregroundColor: scheme.onSurface,
              side: BorderSide(
                color: scheme.outline.withValues(alpha: 0.55),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radiusSm),
              ),
            ),
            onPressed: widget.notifier.registerTapTempo,
            child: const Text('Tap tempo'),
          ),
        ),
      ),
    );
    final run = Tooltip(
      message: widget.isRunning
          ? 'Stop metronome'
          : 'Start metronome',
      child: Listener(
        onPointerDown: (_) => setState(() => _runDown = true),
        onPointerUp: (_) => setState(() => _runDown = false),
        onPointerCancel: (_) => setState(() => _runDown = false),
        child: AnimatedScale(
          scale: _runDown ? 0.98 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: Size(0, btnMinH),
              padding: EdgeInsets.symmetric(
                horizontal: m.scale(t.space16),
                vertical: m.scale(t.space8),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radiusSm),
              ),
            ),
            onPressed: widget.isRunning
                ? widget.notifier.stop
                : widget.notifier.start,
            child: Text(widget.isRunning ? 'Stop' : 'Start'),
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 300) {
          final column = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tap,
              SizedBox(height: m.scale(t.space8)),
              run,
            ],
          );
          if (!c.hasBoundedHeight) {
            return column;
          }
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: c.maxWidth),
              child: column,
            ),
          );
        }
        return Row(
          children: [
            Expanded(child: tap),
            SizedBox(width: m.scale(t.space16)),
            Expanded(child: run),
          ],
        );
      },
    );
  }
}

Widget _metronomeColumn({
  required BuildContext context,
  required int bpm,
  required Meter meter,
  required bool isRunning,
  required MetronomeNotifier notifier,
  required ThemeData theme,
  required ColorScheme scheme,
  required MetroTunerTheme t,
  required double cardPad,
  required double contentWidth,
  required bool compact,
  required PhoneLayoutMetrics m,
}) {
  final transport = _transportStrip(
    scheme: scheme,
    t: t,
    isRunning: isRunning,
    notifier: notifier,
    cardPad: cardPad,
    m: m,
  );
  const bottomDense = true;
  final sessionStrip = _metronomeSessionStrip(
    scheme: scheme,
    t: t,
    cardPad: cardPad,
    m: m,
    dense: bottomDense,
  );
  final soundControl = _metronomeSoundControl(
    context,
    scheme,
    t,
    m,
    dense: bottomDense,
  );

  final gap = m.sectionGap(t, compact: compact);
  final topInset = m.scale(compact ? t.space12 : t.space16);
  final soundTransportGap = m.scale(compact ? t.space8 : t.space12);

  return LayoutBuilder(
    builder: (context, c) {
      final w = contentWidth;
      final trackH = m.metronomeTrackHeight(w);
      final beatH = m.metronomeBeatSweepBarHeight(
        w,
        c.maxHeight,
      );
      final controlsAvailable =
          (c.maxHeight - beatH).clamp(0.0, double.infinity);
      final sideBySideCards = controlsAvailable <
              AdaptiveBreakpoints.compactControlsHeightThreshold &&
          contentWidth >= 340;

      /// Room for tempo + meter [Expanded] halves *after* the fixed bottom block
      /// (session, sound, transport). If too tight, [FittedBox] in the cards can
      /// hit degenerate sizes — use scroll + intrinsic-height cards instead.
      /// Very narrow widths also use scroll + stack (side-by-side Row needs height).
      final fillCards = controlsAvailable >= 580 && contentWidth > 280;

      final tempo = _tempoFullCard(
        theme: theme,
        scheme: scheme,
        bpm: bpm,
        notifier: notifier,
        t: t,
        cardPad: cardPad,
        m: m,
        compact: compact,
        fillHeight: fillCards,
        dense: bottomDense,
      );
      final meterCard = _meterCard(
        context: context,
        theme: theme,
        meter: meter,
        notifier: notifier,
        t: t,
        cardPad: cardPad,
        m: m,
        compact: compact,
        fillHeight: fillCards,
        dense: bottomDense,
      );

      final bottomBlock = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: contentWidth, child: sessionStrip),
          SizedBox(height: soundTransportGap),
          SizedBox(width: contentWidth, child: soundControl),
          SizedBox(height: soundTransportGap),
          SizedBox(width: contentWidth, child: transport),
        ],
      );

      Widget controlsStack() {
        if (!fillCards) {
          // Unbounded height: always stack cards (no side-by-side Row + Expanded here).
          return SingleChildScrollView(
            padding: EdgeInsets.only(top: topInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: contentWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      tempo,
                      SizedBox(height: gap),
                      meterCard,
                    ],
                  ),
                ),
                SizedBox(height: m.scale(compact ? t.space8 : t.space12)),
                bottomBlock,
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topInset),
            Expanded(
              child: SizedBox(
                width: contentWidth,
                child: sideBySideCards
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: tempo),
                          SizedBox(width: gap),
                          Expanded(child: meterCard),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: tempo),
                          SizedBox(height: gap),
                          Expanded(child: meterCard),
                        ],
                      ),
              ),
            ),
            SizedBox(height: m.scale(compact ? t.space8 : t.space12)),
            bottomBlock,
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            height: beatH,
            child: BeatSweepBar(
              beatH: beatH,
              trackHeight: trackH,
            ),
          ),
          Expanded(
            flex: m.metronomeControlsFlex,
            child: controlsStack(),
          ),
        ],
      );
    },
  );
}
