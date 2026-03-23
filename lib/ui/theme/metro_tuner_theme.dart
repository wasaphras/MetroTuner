import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Design tokens for MetroTuner (spacing, radii, pitch UI, tuning feedback,
/// retro rack panel surfaces, motion).
@immutable
class MetroTunerTheme extends ThemeExtension<MetroTunerTheme> {
  /// Creates MetroTuner theme tokens.
  const MetroTunerTheme({
    required this.space4,
    required this.space8,
    required this.space12,
    required this.space16,
    required this.space20,
    required this.space24,
    required this.space32,
    required this.radiusXs,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusStrip,
    required this.tuneInRange,
    required this.tuneClose,
    required this.tuneFar,
    required this.visibleSemitonesStrip,
    required this.pitchStripWidth,
    required this.pitchStripHeight,
    required this.pitchStripGreenCents,
    required this.pitchStripYellowCents,
    required this.panelSurface,
    required this.panelSurfaceRaised,
    required this.bezelHighlight,
    required this.bezelShadow,
    required this.studioAccent,
    required this.vuGlowAlpha,
    required this.scanlineOpacity,
    required this.grainOpacity,
    required this.beatFlashMs,
    required this.readoutCrossFadeMs,
    required this.needleColorMs,
    required this.sliderTrackHeight,
    required this.beatFlashCurve,
    required this.readoutSwitchCurve,
  });

  /// Default dark-stage token set.
  factory MetroTunerTheme.dark() {
    return const MetroTunerTheme(
      space4: 4,
      space8: 8,
      space12: 12,
      space16: 16,
      space20: 20,
      space24: 24,
      space32: 32,
      radiusXs: 10,
      radiusSm: 12,
      radiusMd: 16,
      radiusLg: 20,
      radiusStrip: 14,
      tuneInRange: Color(0xFF6FD4A0),
      tuneClose: Color(0xFFE8C050),
      tuneFar: Color(0xFFE87878),
      visibleSemitonesStrip: 5,
      pitchStripWidth: 104,
      pitchStripHeight: 320,
      pitchStripGreenCents: 5,
      pitchStripYellowCents: 20,
      panelSurface: Color(0xFF0A0514),
      panelSurfaceRaised: Color(0xFF160D1F),
      bezelHighlight: Color(0x33FFFFFF),
      bezelShadow: Color(0x59000000),
      studioAccent: Color(0xFF00F5D4),
      vuGlowAlpha: 0.38,
      scanlineOpacity: 0.04,
      grainOpacity: 0,
      beatFlashMs: 340,
      readoutCrossFadeMs: 220,
      needleColorMs: 280,
      sliderTrackHeight: 5,
      beatFlashCurve: Curves.easeOutCubic,
      readoutSwitchCurve: Curves.easeOutCubic,
    );
  }

  /// 4 logical pixels.
  final double space4;

  /// 8 logical pixels.
  final double space8;

  /// 12 logical pixels.
  final double space12;

  /// 16 logical pixels.
  final double space16;

  /// 20 logical pixels.
  final double space20;

  /// 24 logical pixels.
  final double space24;

  /// 32 logical pixels.
  final double space32;

  /// Small controls (e.g. chip density).
  final double radiusXs;

  /// Inputs, small cards.
  final double radiusSm;

  /// Cards, sheets.
  final double radiusMd;

  /// Hero surfaces, large panels.
  final double radiusLg;

  /// Pitch strip container.
  final double radiusStrip;

  /// |cents| at or below — in tune (primary feedback).
  final Color tuneInRange;

  /// |cents| between green and yellow thresholds.
  final Color tuneClose;

  /// |cents| above yellow threshold.
  final Color tuneFar;

  /// Target number of semitones visible along the vertical ruler.
  final double visibleSemitonesStrip;

  /// Width of the vertical pitch strip.
  final double pitchStripWidth;

  /// Default height of the vertical pitch strip (when not driven by layout).
  final double pitchStripHeight;

  /// Green feedback when |cents| ≤ this value.
  final double pitchStripGreenCents;

  /// Yellow feedback when |cents| ≤ this (and > green).
  final double pitchStripYellowCents;

  /// Flat panel fill (rack background).
  final Color panelSurface;

  /// Raised card / inset panel.
  final Color panelSurfaceRaised;

  /// Top/left bezel highlight for inset panels.
  final Color bezelHighlight;

  /// Bottom/right bezel shadow for inset panels.
  final Color bezelShadow;

  /// Warm studio accent (VU / highlights).
  final Color studioAccent;

  /// Peak glow strength for needles and beat (0–1).
  final double vuGlowAlpha;

  /// Scanline overlay opacity on the pitch strip (0 = off).
  final double scanlineOpacity;

  /// Reserved for future grain overlay (0 = off).
  final double grainOpacity;

  /// Beat flash ripple duration.
  final int beatFlashMs;

  /// Readout value cross-fade duration.
  final int readoutCrossFadeMs;

  /// Tuner needle color ease duration.
  final int needleColorMs;

  /// Rack-style tempo slider track height.
  final double sliderTrackHeight;

  /// Beat dial flash curve.
  final Curve beatFlashCurve;

  /// Readout [AnimatedSwitcher] layout curve.
  final Curve readoutSwitchCurve;

  @override
  MetroTunerTheme copyWith({
    double? space4,
    double? space8,
    double? space12,
    double? space16,
    double? space20,
    double? space24,
    double? space32,
    double? radiusXs,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusStrip,
    Color? tuneInRange,
    Color? tuneClose,
    Color? tuneFar,
    double? visibleSemitonesStrip,
    double? pitchStripWidth,
    double? pitchStripHeight,
    double? pitchStripGreenCents,
    double? pitchStripYellowCents,
    Color? panelSurface,
    Color? panelSurfaceRaised,
    Color? bezelHighlight,
    Color? bezelShadow,
    Color? studioAccent,
    double? vuGlowAlpha,
    double? scanlineOpacity,
    double? grainOpacity,
    int? beatFlashMs,
    int? readoutCrossFadeMs,
    int? needleColorMs,
    double? sliderTrackHeight,
    Curve? beatFlashCurve,
    Curve? readoutSwitchCurve,
  }) {
    return MetroTunerTheme(
      space4: space4 ?? this.space4,
      space8: space8 ?? this.space8,
      space12: space12 ?? this.space12,
      space16: space16 ?? this.space16,
      space20: space20 ?? this.space20,
      space24: space24 ?? this.space24,
      space32: space32 ?? this.space32,
      radiusXs: radiusXs ?? this.radiusXs,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusStrip: radiusStrip ?? this.radiusStrip,
      tuneInRange: tuneInRange ?? this.tuneInRange,
      tuneClose: tuneClose ?? this.tuneClose,
      tuneFar: tuneFar ?? this.tuneFar,
      visibleSemitonesStrip:
          visibleSemitonesStrip ?? this.visibleSemitonesStrip,
      pitchStripWidth: pitchStripWidth ?? this.pitchStripWidth,
      pitchStripHeight: pitchStripHeight ?? this.pitchStripHeight,
      pitchStripGreenCents: pitchStripGreenCents ?? this.pitchStripGreenCents,
      pitchStripYellowCents:
          pitchStripYellowCents ?? this.pitchStripYellowCents,
      panelSurface: panelSurface ?? this.panelSurface,
      panelSurfaceRaised: panelSurfaceRaised ?? this.panelSurfaceRaised,
      bezelHighlight: bezelHighlight ?? this.bezelHighlight,
      bezelShadow: bezelShadow ?? this.bezelShadow,
      studioAccent: studioAccent ?? this.studioAccent,
      vuGlowAlpha: vuGlowAlpha ?? this.vuGlowAlpha,
      scanlineOpacity: scanlineOpacity ?? this.scanlineOpacity,
      grainOpacity: grainOpacity ?? this.grainOpacity,
      beatFlashMs: beatFlashMs ?? this.beatFlashMs,
      readoutCrossFadeMs: readoutCrossFadeMs ?? this.readoutCrossFadeMs,
      needleColorMs: needleColorMs ?? this.needleColorMs,
      sliderTrackHeight: sliderTrackHeight ?? this.sliderTrackHeight,
      beatFlashCurve: beatFlashCurve ?? this.beatFlashCurve,
      readoutSwitchCurve: readoutSwitchCurve ?? this.readoutSwitchCurve,
    );
  }

  @override
  MetroTunerTheme lerp(ThemeExtension<MetroTunerTheme>? other, double t) {
    if (other is! MetroTunerTheme) {
      return this;
    }
    return MetroTunerTheme(
      space4: lerpDouble(space4, other.space4, t)!,
      space8: lerpDouble(space8, other.space8, t)!,
      space12: lerpDouble(space12, other.space12, t)!,
      space16: lerpDouble(space16, other.space16, t)!,
      space20: lerpDouble(space20, other.space20, t)!,
      space24: lerpDouble(space24, other.space24, t)!,
      space32: lerpDouble(space32, other.space32, t)!,
      radiusXs: lerpDouble(radiusXs, other.radiusXs, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusStrip: lerpDouble(radiusStrip, other.radiusStrip, t)!,
      tuneInRange: Color.lerp(tuneInRange, other.tuneInRange, t)!,
      tuneClose: Color.lerp(tuneClose, other.tuneClose, t)!,
      tuneFar: Color.lerp(tuneFar, other.tuneFar, t)!,
      visibleSemitonesStrip: lerpDouble(
        visibleSemitonesStrip,
        other.visibleSemitonesStrip,
        t,
      )!,
      pitchStripWidth: lerpDouble(
        pitchStripWidth,
        other.pitchStripWidth,
        t,
      )!,
      pitchStripHeight: lerpDouble(
        pitchStripHeight,
        other.pitchStripHeight,
        t,
      )!,
      pitchStripGreenCents: lerpDouble(
        pitchStripGreenCents,
        other.pitchStripGreenCents,
        t,
      )!,
      pitchStripYellowCents: lerpDouble(
        pitchStripYellowCents,
        other.pitchStripYellowCents,
        t,
      )!,
      panelSurface: Color.lerp(panelSurface, other.panelSurface, t)!,
      panelSurfaceRaised:
          Color.lerp(panelSurfaceRaised, other.panelSurfaceRaised, t)!,
      bezelHighlight: Color.lerp(bezelHighlight, other.bezelHighlight, t)!,
      bezelShadow: Color.lerp(bezelShadow, other.bezelShadow, t)!,
      studioAccent: Color.lerp(studioAccent, other.studioAccent, t)!,
      vuGlowAlpha: lerpDouble(vuGlowAlpha, other.vuGlowAlpha, t)!,
      scanlineOpacity: lerpDouble(scanlineOpacity, other.scanlineOpacity, t)!,
      grainOpacity: lerpDouble(grainOpacity, other.grainOpacity, t)!,
      beatFlashMs: lerpDouble(
        beatFlashMs.toDouble(),
        other.beatFlashMs.toDouble(),
        t,
      )!.round(),
      readoutCrossFadeMs: lerpDouble(
        readoutCrossFadeMs.toDouble(),
        other.readoutCrossFadeMs.toDouble(),
        t,
      )!.round(),
      needleColorMs: lerpDouble(
        needleColorMs.toDouble(),
        other.needleColorMs.toDouble(),
        t,
      )!.round(),
      sliderTrackHeight: lerpDouble(
        sliderTrackHeight,
        other.sliderTrackHeight,
        t,
      )!,
      beatFlashCurve: t < 0.5 ? beatFlashCurve : other.beatFlashCurve,
      readoutSwitchCurve:
          t < 0.5 ? readoutSwitchCurve : other.readoutSwitchCurve,
    );
  }
}

/// Resolves [MetroTunerTheme] from the ambient [ThemeData], with a safe default.
extension MetroTunerThemeContext on BuildContext {
  /// Design tokens for layout and tuner visuals.
  MetroTunerTheme get mtTheme =>
      Theme.of(this).extension<MetroTunerTheme>() ?? MetroTunerTheme.dark();
}
