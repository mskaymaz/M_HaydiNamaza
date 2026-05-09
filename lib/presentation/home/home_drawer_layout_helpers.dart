part of 'home_screen.dart';

const double _kHomeDrawerPanelOverlap = 15.0;
const double _kHomeDrawerHandleAreaHeight = 22.0;
const double _kHomeDrawerMaxHeightLimit = 320.0;
const double _kHomeDrawerLocationPaddingCompensation = 8.0;
const double _kHomeDrawerTopPanelExtraSpacing = 15.0; // 4 + 1 + 10
const double _kHomeDrawerLowerSectionExtraSpacing = 20.0;

class _HomeDrawerLayoutMetrics {
  final double panelOverlap;
  final double handleAreaHeight;
  final double minDrawerHeight;
  final double maxDrawerHeight;
  final double topPanelHeight;
  final double drawerTop;
  final double drawerHeight;

  const _HomeDrawerLayoutMetrics({
    required this.panelOverlap,
    required this.handleAreaHeight,
    required this.minDrawerHeight,
    required this.maxDrawerHeight,
    required this.topPanelHeight,
    required this.drawerTop,
    required this.drawerHeight,
  });
}

_HomeDrawerLayoutMetrics _computeDrawerLayout({
  required double settingsIconBoxSize,
  required double locationTextSize,
  required double nextTimeTextSize,
  required double nextLabelTextSize,
  required double topPanelVerticalPadding,
  required double constraintsMaxHeight,
  required double drawerProgress,
}) {
  final minDrawerHeight = _kHomeDrawerHandleAreaHeight;
  final topRowHeight = math.max(
    settingsIconBoxSize,
    locationTextSize + _kHomeDrawerLocationPaddingCompensation,
  );
  final lowerSectionHeight =
      nextTimeTextSize + nextLabelTextSize + _kHomeDrawerLowerSectionExtraSpacing;
  final topPanelHeight =
      topPanelVerticalPadding +
      topRowHeight +
      _kHomeDrawerTopPanelExtraSpacing +
      lowerSectionHeight;
  final drawerTop = topPanelHeight - _kHomeDrawerPanelOverlap;
  final availableDrawerSpace = constraintsMaxHeight - drawerTop;
  final maxDrawerHeight = math.max(
    minDrawerHeight,
    math.min(availableDrawerSpace, _kHomeDrawerMaxHeightLimit),
  );
  final drawerHeight =
      minDrawerHeight + ((maxDrawerHeight - minDrawerHeight) * drawerProgress);

  return _HomeDrawerLayoutMetrics(
    panelOverlap: _kHomeDrawerPanelOverlap,
    handleAreaHeight: _kHomeDrawerHandleAreaHeight,
    minDrawerHeight: minDrawerHeight,
    maxDrawerHeight: maxDrawerHeight,
    topPanelHeight: topPanelHeight,
    drawerTop: drawerTop,
    drawerHeight: drawerHeight,
  );
}
