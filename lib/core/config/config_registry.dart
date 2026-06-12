import 'package:flutter/material.dart';

@immutable
class UiPaletteConfig {
  final Color zeminColor;
  final Color cizgiColor;
  final Color customPrayerLabelColor;
  final Color backgroundZeminColor;
  final Color backgroundCizgiColor;
  final String backgroundPatternAssetPath;
  final double backgroundPatternScale;
  final double backgroundPatternOpacity;

  const UiPaletteConfig({
    required this.zeminColor,
    required this.cizgiColor,
    required this.customPrayerLabelColor,
    required this.backgroundZeminColor,
    required this.backgroundCizgiColor,
    required this.backgroundPatternAssetPath,
    required this.backgroundPatternScale,
    required this.backgroundPatternOpacity,
  });

  UiPaletteConfig copyWith({
    Color? zeminColor,
    Color? cizgiColor,
    Color? customPrayerLabelColor,
    Color? backgroundZeminColor,
    Color? backgroundCizgiColor,
    String? backgroundPatternAssetPath,
    double? backgroundPatternScale,
    double? backgroundPatternOpacity,
  }) {
    return UiPaletteConfig(
      zeminColor: zeminColor ?? this.zeminColor,
      cizgiColor: cizgiColor ?? this.cizgiColor,
      customPrayerLabelColor:
          customPrayerLabelColor ?? this.customPrayerLabelColor,
      backgroundZeminColor: backgroundZeminColor ?? this.backgroundZeminColor,
      backgroundCizgiColor: backgroundCizgiColor ?? this.backgroundCizgiColor,
      backgroundPatternAssetPath:
          backgroundPatternAssetPath ?? this.backgroundPatternAssetPath,
      backgroundPatternScale:
          backgroundPatternScale ?? this.backgroundPatternScale,
      backgroundPatternOpacity:
          backgroundPatternOpacity ?? this.backgroundPatternOpacity,
    );
  }
}

@immutable
class SurfaceStyle {
  final Color color;
  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  const SurfaceStyle({
    required this.color,
    required this.borderRadius,
    required this.shadows,
  });
}

@immutable
class InlineIconStyle {
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final BorderRadius borderRadius;

  const InlineIconStyle({
    required this.size,
    required this.iconSize,
    required this.backgroundColor,
    required this.borderRadius,
  });
}

@immutable
class InlineChipStyle {
  final double width;
  final double verticalPadding;
  final double fontSize;
  final Color backgroundColor;
  final Color borderColor;
  final BorderRadius borderRadius;

  const InlineChipStyle({
    required this.width,
    required this.verticalPadding,
    required this.fontSize,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderRadius,
  });
}

@immutable
class HomeTypography {
  final double locationSize;
  final double methodSize;
  final double nextLabelSize;
  final double nextTimeSize;
  final double listLabelSize;
  final double listTimeSize;
  final double chipSize;

  const HomeTypography({
    required this.locationSize,
    required this.methodSize,
    required this.nextLabelSize,
    required this.nextTimeSize,
    required this.listLabelSize,
    required this.listTimeSize,
    required this.chipSize,
  });
}

@immutable
class MainUiConfig {
  final EdgeInsets screenPadding;
  final EdgeInsets topPanelPadding;
  final double sectionGap;
  final double settingsIconSize;
  final double settingsIconBoxSize;
  final double settingsIconOpacity;
  final SurfaceStyle topPanel;
  final SurfaceStyle listPanel;
  final EdgeInsets listPadding;
  final double rowGap;
  final InlineIconStyle iconToggle;
  final InlineChipStyle reminderChip;
  final HomeTypography typography;

  const MainUiConfig({
    required this.screenPadding,
    required this.topPanelPadding,
    required this.sectionGap,
    required this.settingsIconSize,
    required this.settingsIconBoxSize,
    required this.settingsIconOpacity,
    required this.topPanel,
    required this.listPanel,
    required this.listPadding,
    required this.rowGap,
    required this.iconToggle,
    required this.reminderChip,
    required this.typography,
  });
}

@immutable
class SettingsPanelsConfig {
  final EdgeInsets screenPadding;
  final double sectionGap;
  final double fieldGap;
  final double coordinateGap;
  final EdgeInsets sectionPadding;
  final EdgeInsets favoriteItemPadding;
  final double sectionTitleSize;
  final SurfaceStyle panel;
  final SurfaceStyle itemPanel;
  final SurfaceStyle selectedItemPanel;

  const SettingsPanelsConfig({
    required this.screenPadding,
    required this.sectionGap,
    required this.fieldGap,
    required this.coordinateGap,
    required this.sectionPadding,
    required this.favoriteItemPadding,
    required this.sectionTitleSize,
    required this.panel,
    required this.itemPanel,
    required this.selectedItemPanel,
  });
}

@immutable
class HelpPanelsConfig {
  const HelpPanelsConfig();
}

@immutable
class DataSourcesConfig {
  final DiyanetDataSourceConfig diyanet;
  final AladhanDataSourceConfig aladhan;

  const DataSourcesConfig({required this.diyanet, required this.aladhan});
}

@immutable
class AppBehaviorConfig {
  const AppBehaviorConfig();
}

@immutable
class DiyanetDataSourceConfig {
  final String baseUrl;
  final String countryId;
  final Map<String, int> minuteOffsets;

  const DiyanetDataSourceConfig({
    required this.baseUrl,
    required this.countryId,
    required this.minuteOffsets,
  });
}

@immutable
class AladhanDataSourceConfig {
  final String baseUrl;
  final Map<String, int> methodIds;
  final int school;
  final String timeZone;
  final String tune;
  final String shafaq;

  const AladhanDataSourceConfig({
    required this.baseUrl,
    required this.methodIds,
    required this.school,
    required this.timeZone,
    required this.tune,
    required this.shafaq,
  });
}

class ConfigRegistry {
  static const UiPaletteConfig defaultPalette = UiPaletteConfig(
    zeminColor: Color(0xFF1F7A3E),
    cizgiColor: Color(0xFFFFFFFF),
    customPrayerLabelColor: Color(0xFFF57C00),
    backgroundZeminColor: Color(0xFFF3EFE2),
    backgroundCizgiColor: Color(0xFF7A8F6A),
    backgroundPatternAssetPath: 'img/Desen/DesM01.svg',
    backgroundPatternScale: 1.0,
    backgroundPatternOpacity: 0.16,
  );

  static MainUiConfig mainUiFor(UiPaletteConfig palette) {
    return MainUiConfig(
      screenPadding: const EdgeInsets.fromLTRB(5, 14, 5, 18),
      topPanelPadding: const EdgeInsets.fromLTRB(10, 1, 10, 4),
      sectionGap: 12,
      settingsIconSize: 16,
      settingsIconBoxSize: 28,
      settingsIconOpacity: 0.45,
      topPanel: SurfaceStyle(
        color: palette.zeminColor,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        shadows: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      listPanel: SurfaceStyle(
        color: _blendWithBlack(palette.zeminColor, 0.42),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        shadows: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      listPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      rowGap: 1,
      iconToggle: InlineIconStyle(
        size: 26,
        iconSize: 18,
        backgroundColor: palette.cizgiColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      reminderChip: InlineChipStyle(
        width: 35,
        verticalPadding: 5,
        fontSize: 12,
        backgroundColor: palette.cizgiColor.withValues(alpha: 0.08),
        borderColor: palette.cizgiColor.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      typography: const HomeTypography(
        locationSize: 16,
        methodSize: 12,
        nextLabelSize: 20,
        nextTimeSize: 29,
        listLabelSize: 14,
        listTimeSize: 14,
        chipSize: 12,
      ),
    );
  }

  static SettingsPanelsConfig settingsPanelsFor(UiPaletteConfig palette) {
    final softPanel = _blend(Colors.white, palette.backgroundZeminColor, 0.82);
    final softItem = _blend(Colors.white, palette.backgroundZeminColor, 0.9);
    final softSelected = _blend(Colors.white, palette.zeminColor, 0.9);
    return SettingsPanelsConfig(
      screenPadding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      sectionGap: 10,
      fieldGap: 8,
      coordinateGap: 10,
      sectionPadding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      favoriteItemPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      sectionTitleSize: 14,
      panel: SurfaceStyle(
        color: softPanel,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        shadows: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      itemPanel: SurfaceStyle(
        color: softItem,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        shadows: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      selectedItemPanel: SurfaceStyle(
        color: softSelected,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        shadows: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }

  static const HelpPanelsConfig helpPanels = HelpPanelsConfig();
  static const DataSourcesConfig dataSources = DataSourcesConfig(
    diyanet: DiyanetDataSourceConfig(
      baseUrl: 'https://ezanvakti.imsakiyem.com',
      countryId: '2',
      minuteOffsets: <String, int>{
        'imsak': 0,
        'gunes': 0,
        'ogle': 0,
        'ikindi': 0,
        'aksam': 0,
        'yatsi': 0,
      },
    ),
    aladhan: AladhanDataSourceConfig(
      baseUrl: 'https://api.aladhan.com/v1',
      methodIds: <String, int>{
        'aladhan': 13,
        'karachi': 1,
        'north_america': 2,
        'muslim_world_league': 3,
        'umm_al_qura': 4,
        'egyptian': 5,
        'tehran': 7,
        'dubai': 16,
        'kuwait': 9,
        'qatar': 10,
        'singapore': 11,
        'turkey': 13,
        'moonsighting': 15,
      },
      school: 0,
      timeZone: 'Europe/Istanbul',
      tune: '',
      shafaq: 'general',
    ),
  );
  static const AppBehaviorConfig appBehavior = AppBehaviorConfig();

  static Color _blend(Color a, Color b, double t) {
    return Color.lerp(a, b, t) ?? a;
  }

  static Color _blendWithBlack(Color color, double amount) {
    return _blend(color, Colors.black, amount);
  }
}
