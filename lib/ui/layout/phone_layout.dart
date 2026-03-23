import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:metrotuner/ui/theme/metro_tuner_theme.dart';

/// Per-screen layout metrics for phone-sized viewports: one density signal drives
/// padding, gaps, and metronome region flex so areas scale together (not FittedBox blobs).
@immutable
class PhoneLayoutMetrics {
  /// Creates metrics (use [PhoneLayoutMetrics.fromConstraints] with layout constraints).
  const PhoneLayoutMetrics({
    required this.density,
    required this.shortestSide,
    required this.stripWidthFraction,
    required this.metronomeSweepFlex,
    required this.metronomeControlsFlex,
  });

  /// Builds metrics from the current layout box (phones; works for any logical size).
  factory PhoneLayoutMetrics.fromConstraints(BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    if (w <= 0 || h <= 0) {
      return _phoneLayoutMetricsDefaults;
    }
    final shortest = math.min(w, h);
    const refShort = 390.0;
    const minDensity = 0.82;
    const maxDensity = 1.0;
    final density = (shortest / refShort).clamp(minDensity, maxDensity);

    const fracLo = 0.26;
    const fracHi = 0.34;
    final stripFrac = lerpDouble(
          fracLo,
          fracHi,
          ((w - 280) / 220).clamp(0.0, 1.0),
        ) ??
        fracLo;

    // Metronome: favor controls; sweep height is capped by [metronomeBeatSweepBarHeight], not flex alone.
    var sweepFlex = 2;
    var controlsFlex = 5;
    if (h > 640) {
      sweepFlex = 3;
      controlsFlex = 4;
    }

    return PhoneLayoutMetrics(
      density: density,
      shortestSide: shortest,
      stripWidthFraction: stripFrac,
      metronomeSweepFlex: sweepFlex,
      metronomeControlsFlex: controlsFlex,
    );
  }

  /// 0.82–1.0 from shortest side vs reference; scales gaps and padding together.
  final double density;

  /// `min(layout width, height)` for the current constraints (beat rail mins, etc.).
  final double shortestSide;

  /// Tuner: strip uses this fraction of row width (clamped when applied).
  final double stripWidthFraction;

  /// Metronome: [Expanded] flex for beat sweep vs control stack.
  final int metronomeSweepFlex;
  final int metronomeControlsFlex;

  /// Scale a token-sized length (e.g. [MetroTunerTheme.space16]).
  double scale(double base) => base * density;

  /// Horizontal + vertical padding for readout cards at this density.
  EdgeInsets readoutCardPadding(MetroTunerTheme t) {
    return EdgeInsets.symmetric(
      vertical: scale(t.space16),
      horizontal: scale(t.space12),
    );
  }

  /// Gap between stacked controls (tuner/metronome).
  double sectionGap(MetroTunerTheme t, {required bool compact}) {
    final base = compact ? t.space8 : t.space16;
    return scale(base);
  }

  /// Card interior padding for metronome cards.
  double cardPadding(MetroTunerTheme t, {required bool compact}) {
    final base = compact ? t.space12 : t.space16;
    return scale(base);
  }

  /// Tuner strip width from available row width.
  double tunerStripWidth(double rowWidth) {
    final raw = rowWidth * stripWidthFraction;
    return raw.clamp(72, 132);
  }

  /// Thickness of the metronome beat rail from bar width (not from raw flex height).
  ///
  /// Caps width-proportional rail so it does not read as a huge slab.
  double metronomeTrackHeight(double barWidth) {
    final w = barWidth.clamp(120.0, 640.0);
    final fromWidth = w * 0.068;
    return fromWidth.clamp(30 * density, 52);
  }

  /// Total height for the beat sweep bar widget inside a slot of at most [slotMaxHeight].
  /// Tight to the painted rail (no large flex padding).
  double metronomeBeatSweepBarHeight(
    double barWidth,
    double slotMaxHeight,
  ) {
    final track = metronomeTrackHeight(barWidth);
    final linePad = scale(10);
    final glowPad = scale(16);
    final preferred = track + linePad + glowPad;
    return math.min(math.max(preferred, scale(32)), slotMaxHeight);
  }
}

/// Fallback when constraints are empty or invalid.
const PhoneLayoutMetrics _phoneLayoutMetricsDefaults = PhoneLayoutMetrics(
  density: 1,
  shortestSide: 390,
  stripWidthFraction: 0.3,
  metronomeSweepFlex: 2,
  metronomeControlsFlex: 5,
);
