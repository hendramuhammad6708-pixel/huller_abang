import 'package:flutter/material.dart';

/// Palet "hijau sawah segar": hijau emerald + aksen kuning padi.
/// Pakai konstanta ini, jangan kode warna mentah.
class AppColors {
  static const primary = Color(0xFF15803D);
  static const primaryLight = Color(0xFF22C55E);
  static const primaryDark = Color(0xFF14532D);
  static const mint = Color(0xFFDCFCE7);
  static const mintText = Color(0xFF15803D);
  static const background = Color(0xFFF6F8F4);
  static const surface = Colors.white;
  static const textDark = Color(0xFF14231B);
  static const textMuted = Color(0xFF66756B);
  static const border = Color(0xFFE4EBE5);
  static const blueSoft = Color(0xFFDBEAFE);
  static const blue = Color(0xFF2563EB);

  /// Kuning padi: aksen hangat untuk sorotan dan kelas padi.
  static const aksen = Color(0xFFF59E0B);
  static const goldSoft = Color(0xFFFEF3C7);
  static const gold = Color(0xFFB45309);

  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const dangerLine = Color(0xFFFECACA);
}

/// Ukuran sudut yang dipakai seragam di seluruh aplikasi.
class AppRadius {
  static const kecil = 12.0;
  static const sedang = 16.0;
  static const besar = 22.0;
}

/// Bayangan lembut berwarna hijau tipis untuk kartu yang "melayang".
class AppShadows {
  static final kartu = [
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: 0.04),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static final hero = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.30),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];
}

/// Gradasi hijau untuk panel sorotan (sambutan, ringkasan).
const gradienHero = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF166534), AppColors.primary, Color(0xFF16A34A)],
  stops: [0, 0.55, 1],
);

class AppTheme {
  static const fontFamily = 'PlusJakartaSans';

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.aksen,
      surface: AppColors.surface,
      onSurface: AppColors.textDark,
      error: AppColors.danger,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
    );
    final teks = base.textTheme.apply(
      bodyColor: AppColors.textDark,
      displayColor: AppColors.textDark,
    );

    OutlineInputBorder garis(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sedang),
          borderSide: BorderSide(color: c, width: w),
        );
    final sudut = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sedang));
    const teksTombol = TextStyle(
        fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: teks.copyWith(
        headlineSmall: teks.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        titleLarge: teks.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: teks.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyMedium: teks.bodyMedium?.copyWith(height: 1.35),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
          letterSpacing: -0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        floatingLabelStyle: const TextStyle(
            color: AppColors.primary, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.8)),
        helperStyle: const TextStyle(color: AppColors.textMuted),
        prefixIconColor: WidgetStateColor.resolveWith((s) =>
            s.contains(WidgetState.focused)
                ? AppColors.primary
                : AppColors.textMuted),
        suffixIconColor: AppColors.textMuted,
        border: garis(AppColors.border),
        enabledBorder: garis(AppColors.border),
        focusedBorder: garis(AppColors.primary, 1.8),
        errorBorder: garis(AppColors.danger),
        focusedErrorBorder: garis(AppColors.danger, 1.8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: sudut,
          textStyle: teksTombol,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          side: const BorderSide(color: AppColors.border, width: 1.4),
          shape: sudut,
          textStyle: teksTombol,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: sudut,
          textStyle: const TextStyle(
              fontFamily: fontFamily, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 6,
        extendedTextStyle: teksTombol,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        color: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : Colors.white),
        side: WidgetStateBorderSide.resolveWith((s) => BorderSide(
            color: s.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.border)),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          color: WidgetStateColor.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? Colors.white
                  : AppColors.textDark),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: const StadiumBorder(),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.white,
          selectedBackgroundColor: AppColors.mint,
          selectedForegroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(0, 48),
          textStyle: const TextStyle(
              fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : AppColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primaryLight : AppColors.border),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
        elevation: 6,
        contentTextStyle: const TextStyle(
            fontFamily: fontFamily,
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sedang)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: AppColors.primaryDark.withValues(alpha: 0.25),
        textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sedang)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.mint,
        elevation: 0,
        height: 70,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted)),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontFamily: fontFamily,
              fontSize: 12,
              fontWeight: s.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: s.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.textMuted,
            )),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.mint,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.textMuted),
        selectedLabelTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.primary),
        unselectedLabelTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.textMuted),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.primary),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textDark,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
            fontFamily: fontFamily, color: Colors.white, fontSize: 12),
      ),
    );
  }
}
