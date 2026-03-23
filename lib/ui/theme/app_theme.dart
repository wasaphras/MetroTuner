import 'package:flutter/material.dart';
import 'package:metrotuner/ui/theme/metro_tuner_theme.dart';

/// Dark-first Material 3 theme: cyberpunk stage + user [accentSeed].
ThemeData buildAppTheme({required Color accentSeed}) {
  final baseTokens = MetroTunerTheme.dark();
  final tokens = baseTokens.copyWith(
    studioAccent: accentSeed,
    bezelHighlight: Color.lerp(
      accentSeed,
      const Color(0xFFFFFFFF),
      0.15,
    ) ?? const Color(0x33FFFFFF),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentSeed,
      brightness: Brightness.dark,
      primary: accentSeed,
      secondary: const Color(0xFFFF2D95),
      tertiary: const Color(0xFF18FFFF),
    ).copyWith(
      surface: tokens.panelSurface,
      surfaceContainerLowest: const Color(0xFF050210),
      surfaceContainerLow: const Color(0xFF0E0818),
      surfaceContainer: tokens.panelSurfaceRaised,
      surfaceContainerHigh: const Color(0xFF241838),
      surfaceContainerHighest: const Color(0xFF32244A),
    ),
  );
  final scheme = base.colorScheme;

  final textTheme = base.textTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  final readoutFont = textTheme.headlineMedium?.copyWith(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  final displayHero = textTheme.displayLarge?.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: -0.8,
    height: 1.05,
    fontFamily: 'monospace',
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    extensions: [tokens],
    textTheme: textTheme.copyWith(
      displayLarge: displayHero,
      displayMedium: textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontFamily: 'monospace',
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      headlineMedium: readoutFont,
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.12,
      ),
      titleSmall: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.35,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.45,
      ),
      labelMedium: textTheme.labelMedium?.copyWith(
        letterSpacing: 0.35,
      ),
      labelSmall: textTheme.labelSmall?.copyWith(
        letterSpacing: 0.25,
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: tokens.bezelShadow,
      shape: Border(
        bottom: BorderSide(
          color: scheme.outline.withValues(alpha: 0.22),
        ),
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
        letterSpacing: 0.8,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shadowColor: tokens.bezelShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(tokens.radiusMd)),
        side: BorderSide(
          color: tokens.bezelHighlight.withValues(alpha: 0.45),
        ),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.surfaceContainerHighest,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.12),
      trackHeight: tokens.sliderTrackHeight,
      trackShape: const RoundedRectSliderTrackShape(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.secondaryContainer,
      disabledColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      labelStyle: textTheme.labelLarge,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusXs),
      ),
      side: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
      showCheckmark: false,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusLg),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        side: BorderSide(
          color: tokens.bezelHighlight.withValues(alpha: 0.35),
        ),
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        height: 1.45,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusSm),
      ),
      elevation: 2,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: scheme.secondaryContainer.withValues(alpha: 0.65),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected
              ? scheme.onSecondaryContainer
              : scheme.onSurfaceVariant,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelMedium?.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          letterSpacing: 0.2,
          color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
        );
      }),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      textStyle: textTheme.labelSmall?.copyWith(
        color: scheme.onInverseSurface,
      ),
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(tokens.radiusXs),
      ),
    ),
  );
}
