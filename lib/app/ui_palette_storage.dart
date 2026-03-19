import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/config_registry.dart';

class UiPaletteStorage {
  static const String _zeminKey = 'ui_palette_zemin';
  static const String _cizgiKey = 'ui_palette_cizgi';
  static const String _backgroundZeminKey = 'ui_palette_background_zemin';
  static const String _backgroundCizgiKey = 'ui_palette_background_cizgi';

  Future<UiPaletteConfig> read() async {
    final prefs = await SharedPreferences.getInstance();
    final zeminValue = prefs.getInt(_zeminKey);
    final cizgiValue = prefs.getInt(_cizgiKey);
    final backgroundZeminValue = prefs.getInt(_backgroundZeminKey);
    final backgroundCizgiValue = prefs.getInt(_backgroundCizgiKey);
    return ConfigRegistry.defaultPalette.copyWith(
      zeminColor: zeminValue == null ? null : Color(zeminValue),
      cizgiColor: cizgiValue == null ? null : Color(cizgiValue),
      backgroundZeminColor: backgroundZeminValue == null
          ? null
          : Color(backgroundZeminValue),
      backgroundCizgiColor: backgroundCizgiValue == null
          ? null
          : Color(backgroundCizgiValue),
    );
  }

  Future<void> write(UiPaletteConfig palette) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_zeminKey, palette.zeminColor.toARGB32());
    await prefs.setInt(_cizgiKey, palette.cizgiColor.toARGB32());
    await prefs.setInt(
      _backgroundZeminKey,
      palette.backgroundZeminColor.toARGB32(),
    );
    await prefs.setInt(
      _backgroundCizgiKey,
      palette.backgroundCizgiColor.toARGB32(),
    );
  }
}
