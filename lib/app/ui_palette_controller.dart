import 'package:flutter/widgets.dart';

import '../core/config/config_registry.dart';
import 'ui_palette_storage.dart';

class UiPaletteController extends ValueNotifier<UiPaletteConfig> {
  final UiPaletteStorage _storage;

  UiPaletteController({UiPaletteStorage? storage})
    : _storage = storage ?? UiPaletteStorage(),
      super(ConfigRegistry.defaultPalette);

  Future<void> load() async {
    value = await _storage.read();
  }

  Future<void> setPalette(UiPaletteConfig palette) async {
    value = palette;
    await _storage.write(palette);
  }

  Future<void> setZeminColor(Color color) async {
    await setPalette(value.copyWith(zeminColor: color));
  }

  Future<void> setCizgiColor(Color color) async {
    await setPalette(value.copyWith(cizgiColor: color));
  }

  Future<void> setCustomPrayerLabelColor(Color color) async {
    await setPalette(value.copyWith(customPrayerLabelColor: color));
  }

  Future<void> setBackgroundZeminColor(Color color) async {
    await setPalette(value.copyWith(backgroundZeminColor: color));
  }

  Future<void> setBackgroundCizgiColor(Color color) async {
    await setPalette(value.copyWith(backgroundCizgiColor: color));
  }

  Future<void> setBackgroundPatternAssetPath(String assetPath) async {
    await setPalette(value.copyWith(backgroundPatternAssetPath: assetPath));
  }

  Future<void> setBackgroundPatternScale(double scale) async {
    await setPalette(value.copyWith(backgroundPatternScale: scale));
  }

  Future<void> setBackgroundPatternOpacity(double opacity) async {
    await setPalette(value.copyWith(backgroundPatternOpacity: opacity));
  }
}
