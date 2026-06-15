part of 'home_screen.dart';

const double _kHomeDrawerPanelOverlap = 0.0;
const double _kHomeDrawerPanelGap = 3.0;
const double _kHomeDrawerMinCollapsedHeight = 22.0;
const double _kHomeDrawerMaxHeightLimit = 260.0;
const double _kHomeDrawerLocationPaddingCompensation = 8.0;
const double _kHomeDrawerLocationSettingsMinTapSize = 50.0;
const double _kHomeDrawerTopPanelExtraSpacing = 0.0;
const double _kHomeDrawerLowerSectionExtraSpacing = 61.0;

class _HomeDrawerLayoutMetrics {
  final double panelOverlap;
  final double minDrawerHeight;
  final double maxDrawerHeight;
  final double topPanelHeight;
  final double drawerTop;
  final double drawerHeight;

  const _HomeDrawerLayoutMetrics({
    required this.panelOverlap,
    required this.minDrawerHeight,
    required this.maxDrawerHeight,
    required this.topPanelHeight,
    required this.drawerTop,
    required this.drawerHeight,
  });
}

_HomeDrawerLayoutMetrics _computeDrawerLayout({
  required double locationTextSize,
  required double nextTimeTextSize,
  required double nextLabelTextSize,
  required double topPanelVerticalPadding,
  required double constraintsMaxHeight,
  required double drawerProgress,
}) {
  final minDrawerHeight = _kHomeDrawerMinCollapsedHeight;
  final topRowHeight = math.max(
    _kHomeDrawerLocationSettingsMinTapSize,
    locationTextSize + _kHomeDrawerLocationPaddingCompensation,
  );
  final lowerSectionHeight =
      nextTimeTextSize + nextLabelTextSize + _kHomeDrawerLowerSectionExtraSpacing;
  final topPanelHeight =
      topPanelVerticalPadding +
      topRowHeight +
      _kHomeDrawerTopPanelExtraSpacing +
      lowerSectionHeight;
  final drawerTop = topPanelHeight + _kHomeDrawerPanelGap;
  final availableDrawerSpace = constraintsMaxHeight - drawerTop;
  final maxDrawerHeight = math.max(
    minDrawerHeight,
    math.min(availableDrawerSpace, _kHomeDrawerMaxHeightLimit),
  );
  final drawerHeight =
      minDrawerHeight + ((maxDrawerHeight - minDrawerHeight) * drawerProgress);

  return _HomeDrawerLayoutMetrics(
    panelOverlap: _kHomeDrawerPanelOverlap,
    minDrawerHeight: minDrawerHeight,
    maxDrawerHeight: maxDrawerHeight,
    topPanelHeight: topPanelHeight,
    drawerTop: drawerTop,
    drawerHeight: drawerHeight,
  );
}
