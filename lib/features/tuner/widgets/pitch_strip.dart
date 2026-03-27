import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:metrotuner/core/pitch/note_math.dart';
import 'package:metrotuner/core/pitch/pitch_types.dart';
import 'package:metrotuner/ui/theme/metro_tuner_theme.dart';

/// Chromatic ruler C2–C8 with cent subdivisions; [latestPitch] drives color and
/// scroll position (smoothly interpolated).
class PitchStrip extends StatefulWidget {
  /// Creates the pitch strip.
  const PitchStrip({
    required this.latestPitch,
    required this.isActive,
    this.stripHeight,
    super.key,
  });

  /// Last detector sample; null when gated or inactive.
  final PitchResult? latestPitch;

  /// Whether the tuner transport is running (affects idle vs. listening tint).
  final bool isActive;

  /// When set, vertical ruler uses this height instead of the theme default so
  /// the strip fills the body.
  final double? stripHeight;

  @override
  State<PitchStrip> createState() => _PitchStripState();
}

class _PitchStripState extends State<PitchStrip>
    with SingleTickerProviderStateMixin {
  static const double _minMidi = 36;
  static const double _maxMidi = 108;
  static const double _restMidi = 60;

  late Ticker _ticker;

  /// When true, the frame ticker is stopped because the needle reached target.
  bool _tickerIdle = false;

  double _displayMidi = _restMidi;

  /// Last measured pitch (while listening); held when the detector returns null but active.
  double _lastHeldMidi = _restMidi;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    unawaited(_ticker.start());
  }

  void _onTick(Duration elapsed) {
    if (!mounted) {
      return;
    }
    final target = _targetMidi();
    final next = _displayMidi + (target - _displayMidi) * 0.16;
    if ((target - next).abs() < 0.002) {
      if (_displayMidi != target) {
        setState(() {
          _displayMidi = target;
        });
      }
      if (!_tickerIdle) {
        _ticker.stop();
        _tickerIdle = true;
      }
      return;
    }
    if (_tickerIdle) {
      _tickerIdle = false;
    }
    setState(() {
      _displayMidi = next;
    });
  }

  @override
  void didUpdateWidget(PitchStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive && oldWidget.isActive) {
      _lastHeldMidi = _restMidi;
    }
    final target = _targetMidi();
    if (_tickerIdle && (target - _displayMidi).abs() > 0.01) {
      unawaited(_ticker.start());
      _tickerIdle = false;
    }
  }

  double _targetMidi() {
    final p = widget.latestPitch;
    if (p != null) {
      final m = NoteMath.hzToMidi(p.frequencyHz).clamp(_minMidi, _maxMidi);
      _lastHeldMidi = m;
      return m;
    }
    if (widget.isActive) {
      return _lastHeldMidi;
    }
    return _restMidi;
  }

  /// Always-visible center marker (idle / no pitch yet).
  Color _staticCenterColor(ColorScheme scheme) {
    return scheme.onSurface.withValues(alpha: 0.42);
  }

  Color _tuneColor(ColorScheme scheme, MetroTunerTheme mt) {
    final p = widget.latestPitch;
    if (!widget.isActive || p == null) {
      return _staticCenterColor(scheme);
    }
    final c = p.centsFromNearest.abs();
    if (c <= mt.pitchStripGreenCents) {
      return mt.tuneInRange;
    }
    if (c <= mt.pitchStripYellowCents) {
      return mt.tuneClose;
    }
    return mt.tuneFar;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mt = context.mtTheme;
    final tune = _tuneColor(scheme, mt);
    final glow = mt.vuGlowAlpha.clamp(0.0, 1.0);

    final span = mt.visibleSemitonesStrip;
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      fontSize: 15,
      height: 1.1,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final h =
        (widget.stripHeight ?? mt.pitchStripHeight).clamp(200.0, 2000.0);
    final w = mt.pitchStripWidth;
    final pxPerSemitone = (h / span).clamp(14.0, 200.0);
    final centerY = h / 2;

    return RepaintBoundary(
      child: Semantics(
        label: 'Pitch strip, chromatic ruler from C2 through C8',
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(mt.radiusStrip),
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _stripBackground(mt, scheme, w, h),
                  CustomPaint(
                    size: Size(w, h),
                    painter: _RulerPainter(
                      displayMidi: _displayMidi,
                      centerY: centerY,
                      minMidi: _minMidi,
                      maxMidi: _maxMidi,
                      pxPerSemitone: pxPerSemitone,
                      labelStyle: labelStyle,
                      majorTickColor: scheme.outlineVariant,
                      minorTickColor: scheme.outlineVariant,
                      baselineColor: scheme.outline.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  if (mt.scanlineOpacity > 0.001)
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size(w, h),
                        painter: _ScanlinePainter(
                          opacity: mt.scanlineOpacity,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 6,
                    right: 6,
                    top: centerY - 2,
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _staticCenterColor(scheme),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    right: 6,
                    top: centerY - 2,
                    height: 4,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: mt.needleColorMs),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: widget.isActive && widget.latestPitch != null
                            ? tune
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          if (widget.isActive && widget.latestPitch != null)
                            BoxShadow(
                              color: tune.withValues(alpha: 0.45 * glow),
                              blurRadius: 8,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _stripBackground(
  MetroTunerTheme mt,
  ColorScheme scheme,
  double w,
  double h,
) {
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          mt.panelSurfaceRaised,
          scheme.surfaceContainerHighest.withValues(alpha: 0.65),
          mt.panelSurface,
        ],
      ),
      border: Border.all(
        color: mt.bezelHighlight.withValues(alpha: 0.35),
      ),
    ),
    child: SizedBox(width: w, height: h),
  );
}

class _ScanlinePainter extends CustomPainter {
  _ScanlinePainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: opacity)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.displayMidi,
    required this.centerY,
    required this.minMidi,
    required this.maxMidi,
    required this.pxPerSemitone,
    required this.labelStyle,
    required this.majorTickColor,
    required this.minorTickColor,
    required this.baselineColor,
  });

  final double displayMidi;
  final double centerY;
  final double minMidi;
  final double maxMidi;
  final double pxPerSemitone;
  final TextStyle? labelStyle;
  final Color majorTickColor;
  final Color minorTickColor;
  final Color baselineColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 10.0;
    final right = size.width - 10;
    final centerX = size.width / 2;
    final maxLabelW = math.max<double>(12, centerX - left - 8);

    canvas.drawLine(
      Offset(centerX - 1.5, 0),
      Offset(centerX - 1.5, size.height),
      Paint()
        ..color = baselineColor
        ..strokeWidth = 1,
    );

    final major = Paint()
      ..color = majorTickColor
      ..strokeWidth = 1.2;
    final minor = Paint()
      ..color = minorTickColor.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    final minorMid = Paint()
      ..color = minorTickColor.withValues(alpha: 0.28)
      ..strokeWidth = 1;

    canvas
      ..save()
      ..translate(0, centerY - (displayMidi - minMidi) * pxPerSemitone);

    for (var m = minMidi.toInt(); m <= maxMidi.toInt(); m++) {
      final y = (m - minMidi) * pxPerSemitone;
      canvas.drawLine(Offset(left, y), Offset(right, y), major);

      for (var t = 1; t < 10; t++) {
        final cy = y + (t / 10) * pxPerSemitone;
        final isHalf = t == 5;
        canvas.drawLine(
          Offset(isHalf ? left + 6 : left + 10, cy),
          Offset(right - 6, cy),
          isHalf ? minor : minorMid,
        );
      }

      final label = NoteMath.midiToChromaticLabel(m);
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      tp
        ..layout(maxWidth: maxLabelW)
        ..paint(canvas, Offset(left, y - tp.height / 2));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return oldDelegate.displayMidi != displayMidi ||
        oldDelegate.centerY != centerY ||
        oldDelegate.pxPerSemitone != pxPerSemitone ||
        oldDelegate.labelStyle != labelStyle;
  }
}
