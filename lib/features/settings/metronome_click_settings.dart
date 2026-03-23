import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/core/audio/audio_engine.dart';
import 'package:metrotuner/core/audio/metronome_click_preset.dart';
import 'package:metrotuner/core/audio/metronome_click_sound_settings.dart';
import 'package:metrotuner/core/pitch/note_math.dart';
import 'package:metrotuner/features/settings/metronome_click_sound_notifier.dart';
import 'package:metrotuner/features/settings/metronome_waveform_preview.dart';
import 'package:metrotuner/features/settings/reference_concert_pitch_notifier.dart';
import 'package:metrotuner/ui/theme/metro_tuner_theme.dart';

const List<String> _kPitchClassNames = <String>[
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

/// Labels matching waveform order in package `flutter_soloud`.
const List<String> kMetronomeWaveformLabels = <String>[
  'Square',
  'Saw',
  'Sine',
  'Triangle',
  'Bounce',
  'Jaws',
  'Humps',
  'Fourier square',
  'Fourier saw',
];

/// Metronome click pitch, timbre, effects, and preview (settings).
class MetronomeClickSoundSection extends ConsumerWidget {
  /// Creates the metronome click section.
  const MetronomeClickSoundSection({
    this.showHeading = true,
    super.key,
  });

  /// When false, omit the top "Metronome click" title (e.g. parent shows
  /// a section header or an app bar title for metronome sound).
  final bool showHeading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = context.mtTheme;
    final s = ref.watch(metronomeClickSoundProvider);
    final notifier = ref.read(metronomeClickSoundProvider.notifier);
    final refHz = referenceA4HzFromConcert(
      concert: ref.watch(referenceConcertPitchProvider),
    );
    final beatMidi = s.clampedBeatMidi;
    final downMidi = s.clampedDownbeatMidi;

    Future<void> applyBeatMidi(int raw) {
      final m = raw.clamp(
        kMetronomeClickMidiMin,
        kMetronomeClickMidiMax,
      );
      final cur = ref.read(metronomeClickSoundProvider);
      return notifier.setSettings(cur.copyWith(beatMidi: m));
    }

    Future<void> applyDownbeatMidi(int raw) {
      final m = raw.clamp(
        kMetronomeClickMidiMin,
        kMetronomeClickMidiMax,
      );
      final cur = ref.read(metronomeClickSoundProvider);
      return notifier.setSettings(cur.copyWith(downbeatMidi: m));
    }

    final introAlign = showHeading ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeading) ...[
          Text(
            'Metronome click',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: t.space8),
        ],
        Text(
          'Synthesized clicks; waveform preview matches SoLoud. Sharps match '
          'the tuner.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
          textAlign: introAlign,
        ),
        SizedBox(height: t.space8),
        _MetronomeClickPitchCard(
          label: 'Beat',
          value:
              '${NoteMath.midiToChromaticLabel(s.clampedBeatMidi)} · '
              '${s.normalHz(refHz).toStringAsFixed(1)} Hz',
          emphasize: false,
          midi: beatMidi,
          scheme: scheme,
          t: t,
          onMidiChanged: applyBeatMidi,
        ),
        SizedBox(height: t.space16),
        _MetronomeClickPitchCard(
          label: 'Downbeat',
          value:
              '${NoteMath.midiToChromaticLabel(s.clampedDownbeatMidi)} · '
              '${s.accentHz(refHz).toStringAsFixed(1)} Hz',
          emphasize: true,
          midi: downMidi,
          scheme: scheme,
          t: t,
          onMidiChanged: applyDownbeatMidi,
        ),
        SizedBox(height: t.space20),
        Text(
          'Sound type',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: t.space8),
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            isExpanded: true,
            borderRadius: BorderRadius.circular(t.radiusMd),
            itemHeight: 88,
            value: s.preset.index.clamp(
              0,
              MetronomeClickPreset.values.length - 1,
            ),
            items: [
              for (var i = 0; i < MetronomeClickPreset.values.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(kMetronomeClickPresetLabels[i]),
                      Text(
                        kMetronomeClickPresetSubtitles[i],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (i) {
              if (i == null) {
                return;
              }
              final cur = ref.read(metronomeClickSoundProvider);
              unawaited(
                notifier.setSettings(
                  cur.copyWith(preset: MetronomeClickPreset.values[i]),
                ),
              );
            },
          ),
        ),
        SizedBox(height: t.space12),
        Text(
          'Wave preview',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: t.space4),
        Text(
          'Shows the SoLoud waveform across the click length at the beat pitch '
          '(echo schematic is qualitative).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: t.space8),
        MetronomeWaveformPreview(
          waveformIndex: s.effectiveWaveformIndex,
          clickDurationMs: s.clampedClickDurationMs,
          beatHz: s.normalHz(refHz),
          downbeatHz: s.accentHz(refHz),
          reverb: s.clampedReverb,
          echo: s.clampedEcho,
          colorScheme: scheme,
        ),
        SizedBox(height: t.space16),
        Text(
          'Effects',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: t.space4),
        Text(
          kIsWeb
              ? 'Click length applies on web. Room and echo use native audio '
                    '(iOS/Android); they are not applied in web builds.'
              : 'Click length cuts each voice; Room and Echo map to one SoLoud '
                    'echo filter (wet, delay, decay).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: t.space8),
        Text(
          'Click length',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'How long each click sounds before it is stopped.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        Semantics(
          label:
              'Click length ${s.clampedClickDurationMs.round()} milliseconds',
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  value: s.clampedClickDurationMs,
                  min: kMetronomeClickDurationMsMin,
                  max: kMetronomeClickDurationMsMax,
                  divisions: 77,
                  label: '${s.clampedClickDurationMs.round()} ms',
                  onChanged: (v) {
                    final cur = ref.read(metronomeClickSoundProvider);
                    unawaited(
                      notifier.setSettings(cur.copyWith(clickDurationMs: v)),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '${s.clampedClickDurationMs.round()} ms',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        Text(
          'Room',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Smear and tail (echo wet and decay).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        Semantics(
          label: 'Room amount ${(s.clampedReverb * 100).round()} percent',
          child: Slider(
            value: s.clampedReverb,
            divisions: 20,
            label: '${(s.clampedReverb * 100).round()}%',
            onChanged: (v) {
              final cur = ref.read(metronomeClickSoundProvider);
              unawaited(notifier.setSettings(cur.copyWith(reverb: v)));
            },
          ),
        ),
        Text(
          'Echo',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Delay and repeats (echo delay; combines with Room).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        Semantics(
          label: 'Echo amount ${(s.clampedEcho * 100).round()} percent',
          child: Slider(
            value: s.clampedEcho,
            divisions: 20,
            label: '${(s.clampedEcho * 100).round()}%',
            onChanged: (v) {
              final cur = ref.read(metronomeClickSoundProvider);
              unawaited(notifier.setSettings(cur.copyWith(echo: v)));
            },
          ),
        ),
        if (s.preset == MetronomeClickPreset.custom) ...[
          SizedBox(height: t.space16),
          Text(
            'Waveform',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: t.space8),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              borderRadius: BorderRadius.circular(t.radiusMd),
              value: s.waveformIndex.clamp(0, kMetronomeClickWaveformIndexMax),
              items: [
                for (var i = 0; i <= kMetronomeClickWaveformIndexMax; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(kMetronomeWaveformLabels[i]),
                  ),
              ],
              onChanged: (i) {
                if (i == null) {
                  return;
                }
                final cur = ref.read(metronomeClickSoundProvider);
                unawaited(notifier.setSettings(cur.copyWith(waveformIndex: i)));
              },
            ),
          ),
        ],
        SizedBox(height: t.space16),
        Text(
          'Preview',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: t.space8),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                key: const Key('metronome_click_preview_normal'),
                onPressed: () {
                  final cur = ref.read(metronomeClickSoundProvider);
                  final hz = referenceA4HzFromConcert(
                    concert: ref.read(referenceConcertPitchProvider),
                  );
                  AudioEngine.instance.applyClickSoundSettings(
                    cur,
                    referenceA4Hz: hz,
                  );
                  AudioEngine.instance.playMetronomeClick(accent: false);
                },
                icon: const Icon(Icons.music_note_outlined),
                label: const Text('Beat'),
              ),
            ),
            SizedBox(width: t.space12),
            Expanded(
              child: FilledButton.tonalIcon(
                key: const Key('metronome_click_preview_accent'),
                onPressed: () {
                  final cur = ref.read(metronomeClickSoundProvider);
                  final hz = referenceA4HzFromConcert(
                    concert: ref.read(referenceConcertPitchProvider),
                  );
                  AudioEngine.instance.applyClickSoundSettings(
                    cur,
                    referenceA4Hz: hz,
                  );
                  AudioEngine.instance.playMetronomeClick(accent: true);
                },
                icon: const Icon(Icons.looks_one_outlined),
                label: const Text('Downbeat'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Single panel: readout + pitch controls (same gradient shell as tuner readout cards).
class _MetronomeClickPitchCard extends StatelessWidget {
  const _MetronomeClickPitchCard({
    required this.label,
    required this.value,
    required this.emphasize,
    required this.midi,
    required this.scheme,
    required this.t,
    required this.onMidiChanged,
  });

  final String label;
  final String value;
  final bool emphasize;
  final int midi;
  final ColorScheme scheme;
  final MetroTunerTheme t;
  final Future<void> Function(int) onMidiChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const textScale = 1.0;
    const labelScaleFactor = 0.88;

    final baseStyle = emphasize
        ? theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
            fontFeatures: const [FontFeature.tabularFigures()],
          )
        : theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
            fontFamily: 'monospace',
            fontFeatures: const [FontFeature.tabularFigures()],
          );
    final valueStyle = baseStyle?.copyWith(
      fontSize: baseStyle.fontSize != null
          ? baseStyle.fontSize! * textScale
          : null,
    );

    final labelBase = theme.textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.55,
    );
    final labelStyle = labelBase?.copyWith(
      fontSize: labelBase.fontSize != null
          ? labelBase.fontSize! * textScale * labelScaleFactor
          : null,
    );

    return Semantics(
      label: '$label $value. Adjust pitch with the controls below.',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.radiusMd),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surfaceContainerHigh,
              t.panelSurfaceRaised,
            ],
          ),
          border: Border.all(
            color: t.bezelHighlight.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: t.bezelShadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: t.space16,
            horizontal: t.space12,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final column = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: labelStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: t.space8),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: t.readoutCrossFadeMs),
                    switchInCurve: t.readoutSwitchCurve,
                    switchOutCurve: t.readoutSwitchCurve,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.06),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      value,
                      key: ValueKey<String>(value),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: valueStyle,
                    ),
                  ),
                  SizedBox(height: t.space8),
                  _MidiPitchControlRow(
                    midi: midi,
                    t: t,
                    onMidiChanged: onMidiChanged,
                  ),
                ],
              );
              final boxed = ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: column,
              );
              if (!constraints.hasBoundedHeight) {
                return boxed;
              }
              final tightVertical = constraints.maxHeight < 120;
              if (tightVertical) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: boxed,
                );
              }
              return boxed;
            },
          ),
        ),
      ),
    );
  }
}

class _MidiPitchControlRow extends StatelessWidget {
  const _MidiPitchControlRow({
    required this.midi,
    required this.t,
    required this.onMidiChanged,
  });

  final int midi;
  final MetroTunerTheme t;
  final Future<void> Function(int) onMidiChanged;

  @override
  Widget build(BuildContext context) {
    final octave = (midi ~/ 12) - 1;
    final pitchClass = midi % 12;

    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Lower pitch one semitone',
          child: IconButton(
            onPressed: midi > kMetronomeClickMidiMin
                ? () => unawaited(onMidiChanged(midi - 1))
                : null,
            icon: const Icon(Icons.remove_rounded),
            tooltip: 'Semitone down',
          ),
        ),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: pitchClass,
              items: [
                for (var i = 0; i < 12; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(_kPitchClassNames[i]),
                  ),
              ],
              onChanged: (pc) {
                if (pc == null) {
                  return;
                }
                unawaited(onMidiChanged(12 * (octave + 1) + pc));
              },
            ),
          ),
        ),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: octave,
              items: [
                for (var o = 3; o <= 7; o++)
                  DropdownMenuItem(value: o, child: Text('Octave $o')),
              ],
              onChanged: (o) {
                if (o == null) {
                  return;
                }
                var next = 12 * (o + 1) + pitchClass;
                if (next > kMetronomeClickMidiMax) {
                  next = kMetronomeClickMidiMax;
                }
                if (next < kMetronomeClickMidiMin) {
                  next = kMetronomeClickMidiMin;
                }
                unawaited(onMidiChanged(next));
              },
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'Raise pitch one semitone',
          child: IconButton(
            onPressed: midi < kMetronomeClickMidiMax
                ? () => unawaited(onMidiChanged(midi + 1))
                : null,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Semitone up',
          ),
        ),
      ],
    );
  }
}
