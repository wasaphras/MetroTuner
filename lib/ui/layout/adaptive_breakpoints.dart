import 'package:flutter/material.dart';

/// Viewport helpers for adaptive layouts (no magic numbers in widgets).
abstract final class AdaptiveBreakpoints {
  /// Height below which vertical sections should use compact spacing (foldables, split view).
  static const double compactHeightThreshold = 520;

  /// Height below which main-tab control regions prefer compact layout (e.g. side‑by‑side
  /// metronome cards, FittedBox in tuner) instead of tall stacked flex.
  static const double compactControlsHeightThreshold = 420;

  /// Min width (logical px) for tablet / wide portrait split layouts (not landscape).
  static const double wideLayoutMinWidth = 600;

  /// Use tighter vertical rhythm on short viewports.
  static bool useCompactVerticalLayout({
    required BoxConstraints constraints,
  }) {
    return constraints.maxHeight < compactHeightThreshold;
  }

  /// Wide viewport (e.g. tablet portrait): enough space for two metronome columns.
  static bool isWideLayout({
    required BoxConstraints constraints,
  }) {
    return constraints.maxWidth >= wideLayoutMinWidth;
  }
}
