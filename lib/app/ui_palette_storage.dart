import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/config_registry.dart';

class UiPaletteStorage {
  static const String _zeminKey = 'ui_palette_zemin';
  static const String _cizgiKey = 'ui_palette_cizgi';
  static const String _customPrayerLabelKey =
      'ui_palette_custom_prayer_label';
  static const String _backgroundZeminKey = 'ui_palette_background_zemin';
  static const String _backgroundCizgiKey = 'ui_palette_background_cizgi';
  static const String _backgroundPatternAssetPathKey =
      'ui_palette_background_pattern_asset_path';
  static const String _backgroundPatternScaleKey =
      'ui_palette_background_pattern_scale';
  static const String _backgroundPatternOpacityKey =
      'ui_palette_background_pattern_opacity';

  Future<UiPaletteConfig> read() async {
    final prefs = await SharedPreferences.getInstance();
    final zeminValue = prefs.getInt(_zeminKey);
    final cizgiValue = prefs.getInt(_cizgiKey);
    final customPrayerLabelValue = prefs.getInt(_customPrayerLabelKey);
    final backgroundZeminValue = prefs.getInt(_backgroundZeminKey);
    final backgroundCizgiValue = prefs.getInt(_backgroundCizgiKey);
    final backgroundPatternAssetPath = prefs.getString(
      _backgroundPatternAssetPathKey,
    );
    final backgroundPatternScale = prefs.getDouble(_backgroundPatternScaleKey);
    final backgroundPatternOpacity = prefs.getDouble(
      _backgroundPatternOpacityKey,
    );
    return ConfigRegistry.defaultPalette.copyWith(
      zeminColor: zeminValue == null ? null : Color(zeminValue),
      cizgiColor: cizgiValue == null ? null : Color(cizgiValue),
      customPrayerLabelColor: customPrayerLabelValue == null
          ? null
          : Color(customPrayerLabelValue),
      backgroundZeminColor: backgroundZeminValue == null
          ? null
          : Color(backgroundZeminValue),
      backgroundCizgiColor: backgroundCizgiValue == null
          ? null
          : Color(backgroundCizgiValue),
      backgroundPatternAssetPath: backgroundPatternAssetPath,
      backgroundPatternScale: backgroundPatternScale,
      backgroundPatternOpacity: backgroundPatternOpacity,
    );
  }

  Future<void> write(UiPaletteConfig palette) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_zeminKey, palette.zeminColor.toARGB32());
    await prefs.setInt(_cizgiKey, palette.cizgiColor.toARGB32());
    await prefs.setInt(
      _customPrayerLabelKey,
      palette.customPrayerLabelColor.toARGB32(),
    );
    await prefs.setInt(
      _backgroundZeminKey,
      palette.backgroundZeminColor.toARGB32(),
    );
    await prefs.setInt(
      _backgroundCizgiKey,
      palette.backgroundCizgiColor.toARGB32(),
    );
    await prefs.setString(
      _backgroundPatternAssetPathKey,
      palette.backgroundPatternAssetPath,
    );
    await prefs.setDouble(
      _backgroundPatternScaleKey,
      palette.backgroundPatternScale,
    );
    await prefs.setDouble(
      _backgroundPatternOpacityKey,
      palette.backgroundPatternOpacity,
    );
  }
}
