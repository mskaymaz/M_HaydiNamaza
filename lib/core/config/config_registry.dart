import 'package:flutter/material.dart';

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
  const SettingsPanelsConfig();
}

@immutable
class HelpPanelsConfig {
  const HelpPanelsConfig();
}

@immutable
class DataSourcesConfig {
  const DataSourcesConfig();
}

@immutable
class AppBehaviorConfig {
  const AppBehaviorConfig();
}

class ConfigRegistry {
  static const MainUiConfig mainUi = MainUiConfig(
    screenPadding: EdgeInsets.fromLTRB(18, 14, 18, 18),
    topPanelPadding: EdgeInsets.fromLTRB(10, 6, 10, 8),
    sectionGap: 12,
    settingsIconSize: 16,
    settingsIconBoxSize: 28,
    settingsIconOpacity: 0.45,
    topPanel: SurfaceStyle(
      color: Color(0xFF1F7A3E),
      borderRadius: BorderRadius.all(Radius.circular(18)),
      shadows: [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    ),
    listPanel: SurfaceStyle(
      color: Color(0xFF0E3B22),
      borderRadius: BorderRadius.all(Radius.circular(20)),
      shadows: [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    ),
    listPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    rowGap: 8,
    iconToggle: InlineIconStyle(
      size: 26,
      iconSize: 15,
      backgroundColor: Color(0x14FFFFFF),
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    reminderChip: InlineChipStyle(
      width: 36,
      verticalPadding: 5,
      fontSize: 12,
      backgroundColor: Color(0x14FFFFFF),
      borderColor: Color(0x33FFFFFF),
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    typography: HomeTypography(
      locationSize: 16,
      methodSize: 12,
      nextLabelSize: 20,
      nextTimeSize: 29,
      listLabelSize: 14,
      listTimeSize: 14,
      chipSize: 12,
    ),
  );

  static const SettingsPanelsConfig settingsPanels = SettingsPanelsConfig();
  static const HelpPanelsConfig helpPanels = HelpPanelsConfig();
  static const DataSourcesConfig dataSources = DataSourcesConfig();
  static const AppBehaviorConfig appBehavior = AppBehaviorConfig();
}
