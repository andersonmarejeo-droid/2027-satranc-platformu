import 'package:flutter/material.dart';

enum AppColorTheme {
  fresh('Ferah Turkuaz'),
  forest('Klasik Orman');

  const AppColorTheme(this.label);
  final String label;
}

abstract final class AppColors {
  static const forest = Color(0xFF244C3E);
  static const brass = Color(0xFFB3905C);
  static const ivory = Color(0xFFF5F2EB);
  static const ink = Color(0xFF202A25);
  static const turquoise = Color(0xFF007F73);
  static const orange = Color(0xFFF2A844);
  static const cloud = Color(0xFFF3F7FA);
  static const slate = Color(0xFF263747);
}

abstract final class AppTheme {
  static ThemeData build(
    Brightness brightness, {
    AppColorTheme colorTheme = AppColorTheme.fresh,
  }) {
    final dark = brightness == Brightness.dark;
    final fresh = colorTheme == AppColorTheme.fresh;
    final background = fresh
        ? (dark ? const Color(0xFF101F27) : AppColors.cloud)
        : (dark ? const Color(0xFF141C17) : AppColors.ivory);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: fresh ? AppColors.turquoise : AppColors.forest,
          brightness: brightness,
        ).copyWith(
          primary: fresh
              ? (dark ? const Color(0xFF7AD7C9) : AppColors.turquoise)
              : (dark ? const Color(0xFFA4C8B7) : AppColors.forest),
          onPrimary: dark ? const Color(0xFF073A34) : Colors.white,
          primaryContainer: fresh
              ? (dark ? const Color(0xFF1C4C47) : const Color(0xFFD9F4EE))
              : null,
          onPrimaryContainer: fresh
              ? (dark ? const Color(0xFFC9F7EE) : const Color(0xFF124B44))
              : null,
          secondary: fresh
              ? (dark ? const Color(0xFFF4B568) : const Color(0xFFA95812))
              : AppColors.brass,
          onSecondary: fresh
              ? (dark ? const Color(0xFF472D13) : Colors.white)
              : null,
          secondaryContainer: fresh
              ? (dark ? const Color(0xFF493A29) : const Color(0xFFFFEBCD))
              : null,
          onSecondaryContainer: fresh
              ? (dark ? const Color(0xFFFFDFB3) : const Color(0xFF754008))
              : null,
          tertiary: fresh ? AppColors.orange : null,
          onTertiary: fresh ? const Color(0xFF493513) : null,
          surface: fresh
              ? (dark ? const Color(0xFF1B2C35) : Colors.white)
              : (dark ? const Color(0xFF202823) : const Color(0xFFFFFDF8)),
          surfaceContainerLowest: fresh
              ? (dark ? const Color(0xFF0A171E) : Colors.white)
              : null,
          surfaceContainerLow: fresh
              ? (dark ? const Color(0xFF172730) : const Color(0xFFF8FBFC))
              : null,
          surfaceContainer: fresh
              ? (dark ? const Color(0xFF21343D) : const Color(0xFFEDF3F6))
              : null,
          surfaceContainerHigh: fresh
              ? (dark ? const Color(0xFF2A4049) : const Color(0xFFE8EFF3))
              : null,
          surfaceContainerHighest: fresh
              ? (dark ? const Color(0xFF344C56) : const Color(0xFFDFE9ED))
              : null,
          onSurface: fresh
              ? (dark ? const Color(0xFFEBF3F6) : AppColors.slate)
              : (dark ? const Color(0xFFE9EAE4) : AppColors.ink),
          onSurfaceVariant: dark
              ? (fresh ? const Color(0xFFADC1C9) : const Color(0xFFA7B3A9))
              : (fresh ? const Color(0xFF596E7B) : const Color(0xFF68766E)),
          outlineVariant: dark
              ? (fresh ? const Color(0xFF3A515C) : const Color(0xFF39473D))
              : (fresh ? const Color(0xFFDCE6ED) : const Color(0xFFE3E6DD)),
        );
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: brightness,
      colorScheme: scheme,
    );
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          letterSpacing: -.6,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -.8,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -.5,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: .12),
        height: 64,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 16,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        minVerticalPadding: 6,
        minLeadingWidth: 24,
        horizontalTitleGap: 12,
        minTileHeight: 56,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          color: scheme.onSurface,
        ),
        subtitleTextStyle: base.textTheme.bodySmall?.copyWith(
          fontSize: 13,
          height: 1.3,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
