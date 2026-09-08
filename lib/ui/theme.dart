import 'package:flutter/material.dart';

import 'tokens.dart';

/// Tema chiaro compatto. Unico tema della v1.
ThemeData buildAppTheme() {
  const text = TextStyle(
    fontFamily: 'Roboto',
    color: AppColor.ink,
    height: AppDim.lineH,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    visualDensity: VisualDensity.compact,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: AppColor.bg,
    colorScheme: const ColorScheme.light(
      primary: AppColor.green,
      onPrimary: AppColor.card,
      secondary: AppColor.greenDark,
      onSecondary: AppColor.card,
      surface: AppColor.card,
      onSurface: AppColor.ink,
      error: AppColor.red,
      onError: AppColor.card,
    ),
    textTheme: TextTheme(
      displayLarge: text.copyWith(
        fontSize: AppText.display,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: text.copyWith(
        fontSize: AppText.title,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: text.copyWith(
        fontSize: AppText.h2,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: text.copyWith(fontSize: AppText.body),
      bodySmall: text.copyWith(fontSize: AppText.label, color: AppColor.muted),
      labelSmall: text.copyWith(fontSize: AppText.micro, color: AppColor.muted),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColor.bg,
      foregroundColor: AppColor.ink,
      centerTitle: true,
      toolbarHeight: AppDim.appBarH,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: AppText.title,
        fontWeight: FontWeight.w700,
        color: AppColor.ink,
        height: AppDim.lineH,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColor.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDim.radCard),
        side: const BorderSide(color: AppColor.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: AppColor.card,
      contentPadding: AppDim.inputPad,
      hintStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: AppText.body,
        color: AppColor.faint,
        height: AppDim.lineH,
      ),
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: AppText.label,
        color: AppColor.muted,
        height: AppDim.lineH,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDim.radInput),
        borderSide: const BorderSide(color: AppColor.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDim.radInput),
        borderSide: const BorderSide(color: AppColor.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDim.radInput),
        borderSide: const BorderSide(color: AppColor.green),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDim.radInput),
        borderSide: const BorderSide(color: AppColor.red),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      dividerColor: AppColor.line,
      indicatorColor: AppColor.green,
      labelColor: AppColor.green,
      unselectedLabelColor: AppColor.muted,
      labelPadding: EdgeInsets.zero,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: AppText.micro,
        fontWeight: FontWeight.w700,
        height: AppDim.lineH,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: AppText.micro,
        fontWeight: FontWeight.w500,
        height: AppDim.lineH,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColor.neutralSoft,
      selectedColor: AppColor.greenSoft,
      disabledColor: AppColor.line2,
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: AppText.caption,
        color: AppColor.ink,
        height: AppDim.lineH,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDim.gapS,
        vertical: AppDim.gapXs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDim.radChip),
        side: const BorderSide(color: AppColor.line),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      dense: true,
      minVerticalPadding: AppDim.gapXs,
      minLeadingWidth: AppDim.iconBox,
      contentPadding: AppDim.inputPad,
      visualDensity: VisualDensity.compact,
      iconColor: AppColor.ink2,
      textColor: AppColor.ink,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(AppDim.minTouch, AppDim.minTouch),
        padding: AppDim.inputPad,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        backgroundColor: AppColor.green,
        foregroundColor: AppColor.card,
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: AppText.h2,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDim.radInput),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(AppDim.minTouch, AppDim.minTouch),
        padding: AppDim.inputPad,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        foregroundColor: AppColor.green,
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: AppText.h2,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColor.line2,
      space: AppDim.gapM,
      thickness: AppDim.lineH,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColor.ink,
      contentTextStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: AppText.body,
        color: AppColor.card,
        height: AppDim.lineH,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDim.radInput),
      ),
    ),
  );
}
