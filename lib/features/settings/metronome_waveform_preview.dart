import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:metrotuner/core/audio/metronome_click_sound_settings.dart';
import 'package:metrotuner/core/audio/metronome_echo_mapping.dart';
import 'package:metrotuner/core/audio/soloud_waveform_math.dart';

/// One-cycle sample in ±1, matching SoLoud `generateWaveform` (scaled for display).
double metronomeWaveformSample(int index, double t) {
  final u = t - t.floorToDouble();
  return soloudWaveformSampleNormalized(index, u);
}

/// Waveform over click duration + optional echo schematic (qualitative).
class MetronomeWaveformPreview extends StatelessWidget {
  /// Creates a waveform preview for metronome click settings.
  const MetronomeWaveformPreview({
    required this.waveformIndex,
    required this.clickDurationMs,
    required this.beatHz,
    required this.downbeatHz,
    required this.reverb,
    required this.echo,
    required this.colorScheme,
    super.key,
  });

  final int waveformIndex;
  final double clickDurationMs;
  final double beatHz;
  final double downbeatHz;
  final double reverb;
  final double echo;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final scheme = colorScheme;
    final tt = Theme.of(context).textTheme;
    final wi = waveformIndex.clamp(0, 8);
    final durMs = clickDurationMs;
    final beatCycles = durMs / 1000 * beatHz;
    final downDurMs = (durMs * 1.12).clamp(
      kMetronomeClickDurationMsMin,
      kMetronomeClickDurationMsMax,
    );
    final downCycles = downDurMs / 1000 * downbeatHz;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Waveform over click duration at beat pitch',
            child: SizedBox(
              height: 132,
              width: double.infinity,
              child: CustomPaint(
                painter: _WaveformPreviewPainter(
                  waveformIndex: wi,
                  clickDurationMs: durMs,
                  hz: beatHz,
                  reverb: reverb,
                  echo: echo,
                  lineColor: scheme.primary,
                  fillColor: scheme.primary.withValues(alpha: 0.12),
                  axisColor: scheme.outlineVariant.withValues(alpha: 0.45),
                  echoLineColor: scheme.tertiary.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Beat: ~${beatCycles.toStringAsFixed(1)} cycles in '
            '${durMs.round()} ms at ${beatHz.toStringAsFixed(1)} Hz',
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'Downbeat: ~${downCycles.toStringAsFixed(1)} cycles in '
            '${downDurMs.round()} ms at ${downbeatHz.toStringAsFixed(1)} Hz '
            '(longer gate)',
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'Downbeat plays louder than beat.',
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (!kIsWeb && (reverb > 0.01 || echo > 0.01)) ...[
            const SizedBox(height: 4),
            Text(
              'Echo schematic (qualitative): delay and taps from Room + Echo.',
              style: tt.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WaveformPreviewPainter extends CustomPainter {
  _WaveformPreviewPainter({
    required this.waveformIndex,
    required this.clickDurationMs,
    required this.hz,
    required this.reverb,
    required this.echo,
    required this.lineColor,
    required this.fillColor,
    required this.axisColor,
    required this.echoLineColor,
  });

  final int waveformIndex;
  final double clickDurationMs;
  final double hz;
  final double reverb;
  final double echo;
  final Color lineColor;
  final Color fillColor;
  final Color axisColor;
  final Color echoLineColor;

  static const int _kSamples = 256;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final waveH = size.height * 0.72;
    final echoH = size.height * 0.22;
    final gap = size.height * 0.06;
    final midY = gap + waveH / 2;
    final amp = waveH * 0.38;

    final axis = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, midY), Offset(w, midY), axis);

    final durationSec = (clickDurationMs / 1000).clamp(1e-9, double.infinity);

    double sampleYAtTime(double tSec) {
      final cycles = tSec * hz;
      final phase = cycles - cycles.floorToDouble();
      final y = metronomeWaveformSample(waveformIndex, phase);
      return midY - y * amp;
    }

    final fill = Path()..moveTo(0, midY);
    for (var i = 0; i <= _kSamples; i++) {
      final t = i / _kSamples * durationSec;
      fill.lineTo(t / durationSec * w, sampleYAtTime(t));
    }
    fill
      ..lineTo(w, midY)
      ..lineTo(0, midY)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    final stroke = Path()..moveTo(0, sampleYAtTime(0));
    for (var i = 1; i <= _kSamples; i++) {
      final t = i / _kSamples * durationSec;
      stroke.lineTo(t / durationSec * w, sampleYAtTime(t));
    }
    canvas.drawPath(
      stroke,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (!kIsWeb && (reverb > 0.01 || echo > 0.01)) {
      _paintEchoSchematic(
        canvas: canvas,
        width: w,
        topY: gap + waveH + gap * 0.5,
        height: echoH,
        durationSec: durationSec,
        params: metronomeEchoParamsFromSliders(reverb: reverb, echo: echo),
      );
    }
  }

  void _paintEchoSchematic({
    required Canvas canvas,
    required double width,
    required double topY,
    required double height,
    required double durationSec,
    required MetronomeEchoMappedParams params,
  }) {
    final baseY = topY + height * 0.62;
    final axis = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseY), Offset(width, baseY), axis);

    final wet = params.wet;
    final delay = params.delaySeconds;
    final decay = params.decay;
    if (wet < 1e-6 || durationSec <= 0) {
      return;
    }

    final barPaint = Paint()
      ..color = echoLineColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Direct (dry) tap.
    final h0 = height * 0.45;
    canvas.drawLine(
      Offset(0, baseY),
      Offset(0, baseY - h0),
      barPaint,
    );

    for (var k = 1; k <= 4; k++) {
      final t = delay * k;
      if (t >= durationSec) {
        break;
      }
      final x = t / durationSec * width;
      final amp = wet * math.pow(decay, k).toDouble();
      final h = height * 0.45 * amp.clamp(0.0, 1.0);
      if (h < 0.5) {
        break;
      }
      canvas.drawLine(
        Offset(x, baseY),
        Offset(x, baseY - h),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPreviewPainter oldDelegate) {
    return oldDelegate.waveformIndex != waveformIndex ||
        oldDelegate.clickDurationMs != clickDurationMs ||
        oldDelegate.hz != hz ||
        oldDelegate.reverb != reverb ||
        oldDelegate.echo != echo ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.axisColor != axisColor ||
        oldDelegate.echoLineColor != echoLineColor;
  }
}
