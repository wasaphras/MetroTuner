import 'package:flutter/material.dart';
import 'package:metrotuner/ui/theme/metro_tuner_theme.dart';

/// Labeled value panel for tuner readouts (note, cents, Hz).
class ReadoutCard extends StatelessWidget {
  /// Creates a readout card.
  const ReadoutCard({
    required this.label,
    required this.value,
    required this.emphasize,
    this.padding,
    this.labelValueGap,
    this.textScale = 1,
    this.labelScaleFactor = 0.88,
    super.key,
  });

  /// Short heading (e.g. Note, Cents).
  final String label;

  /// Displayed value string.
  final String value;

  /// Whether to use the larger headline style for the value.
  final bool emphasize;

  /// Overrides default symmetric padding when using layout density scaling.
  final EdgeInsetsGeometry? padding;

  /// Gap between label row and value; defaults to [MetroTunerTheme.space8].
  final double? labelValueGap;

  /// Multiplier for the value text size (viewport density).
  final double textScale;

  /// Label size relative to [textScale].
  final double labelScaleFactor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = context.mtTheme;

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
      label: '$label $value',
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
          padding: padding ??
              EdgeInsets.symmetric(
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
                  SizedBox(height: labelValueGap ?? t.space8),
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
                ],
              );
              final boxed = ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: column,
              );
              if (!constraints.hasBoundedHeight) {
                return boxed;
              }
              final tightVertical = constraints.maxHeight < 88;
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
