import 'package:flutter/material.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../../core/config/config_registry.dart';

const double _locationSettingsIconSize = 27.0;
const double _locationSettingsTapSize = 50.0;
const double _locationSettingsOffsetX = 3.0;
const double _topActionIconGap = 12.0;
const double _topActionReservedWidth = 118.0;
const double _lowerSectionHeight = 110.0;
const double _dateTextSize = 16.0;
const double _lowerContentOffsetY = -2.0;
const double _lowerContentHorizontalInset = 32.0;
const double _lowerContentColumnGap = 16.0;
const double _nextInfoOffsetX = -8.0;
const double _countdownHorizontalScale = 0.9;
const double _nextTimeGap = 6.0;
const String _nextSuffixText = 'vaktine';

class HomeTopPanel extends StatelessWidget {
  final String provinceLabel;
  final String districtLabel;
  final String nextLabel;
  final String nextTime;
  final String countdown;
  final String dateLabel;
  final VoidCallback onLocationTap;
  final VoidCallback onQibla;
  final VoidCallback onSettings;
  final SurfaceStyle style;
  final EdgeInsets padding;
  final double settingsIconSize;
  final double settingsIconBoxSize;
  final double settingsIconOpacity;
  final HomeTypography typography;
  final Color cizgiColor;

  const HomeTopPanel({
    super.key,
    required this.provinceLabel,
    required this.districtLabel,
    required this.nextLabel,
    required this.nextTime,
    required this.countdown,
    required this.dateLabel,
    required this.onLocationTap,
    required this.onQibla,
    required this.onSettings,
    required this.style,
    required this.padding,
    required this.settingsIconSize,
    required this.settingsIconBoxSize,
    required this.settingsIconOpacity,
    required this.typography,
    required this.cizgiColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topRowHeight = _locationSettingsTapSize > typography.locationSize + 8
        ? _locationSettingsTapSize
        : typography.locationSize + 8;
    final locationTextStyle = theme.textTheme.titleMedium?.copyWith(
      color: cizgiColor,
      fontWeight: FontWeight.w500,
      fontSize: typography.locationSize,
    );
    final dateTextStyle = theme.textTheme.titleSmall?.copyWith(
      color: cizgiColor,
      fontWeight: FontWeight.w600,
      fontSize: _dateTextSize,
      letterSpacing: 0,
    );
    final nextLabelTextStyle = theme.textTheme.titleSmall?.copyWith(
      color: cizgiColor,
      fontWeight: FontWeight.w600,
      fontSize: typography.nextLabelSize + 2,
    );
    final nextTimeTextStyle = theme.textTheme.titleSmall?.copyWith(
      color: cizgiColor.withValues(alpha: 0.85),
      fontWeight: FontWeight.w300,
      fontSize: typography.nextLabelSize + 2,
    );
    final nextSuffixTextStyle = nextLabelTextStyle?.copyWith(
      fontWeight: FontWeight.w300,
    );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: style.borderRadius,
        boxShadow: style.shadows,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: topRowHeight,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: _topActionReservedWidth,
                    ),
                    child: GestureDetector(
                      onTap: onLocationTap,
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: cizgiColor,
                            size: typography.locationSize + 1,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: provinceLabel,
                                    style: locationTextStyle,
                                  ),
                                  if (districtLabel.trim().isNotEmpty) ...[
                                    TextSpan(
                                      text: ' / ',
                                      style: locationTextStyle,
                                    ),
                                    TextSpan(
                                      text: districtLabel,
                                      style: locationTextStyle?.copyWith(
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Transform.translate(
                    offset: const Offset(_locationSettingsOffsetX, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: onQibla,
                          icon: Icon(
                            Icons.explore_outlined,
                            color: cizgiColor.withValues(alpha: 0.92),
                            size: settingsIconSize * 2.16,
                          ),
                          tooltip: 'Kible Yonu',
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: _locationSettingsTapSize,
                            minHeight: _locationSettingsTapSize,
                          ),
                        ),
                        const SizedBox(width: _topActionIconGap),
                        IconButton(
                          onPressed: onSettings,
                          icon: Icon(
                            Icons.settings_outlined,
                            color: cizgiColor.withValues(
                              alpha: settingsIconOpacity,
                            ),
                            size: _locationSettingsIconSize,
                          ),
                          tooltip: AppLocalizations.of(context)!.settingsTitle,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: _locationSettingsTapSize,
                            minHeight: _locationSettingsTapSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: _lowerSectionHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: Transform.translate(
                    offset: const Offset(0, _lowerContentOffsetY),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              dateLabel,
                              textAlign: TextAlign.center,
                              style: dateTextStyle,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _lowerContentHorizontalInset,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Transform.translate(
                                    offset: const Offset(_nextInfoOffsetX, 0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              nextLabel,
                                              style: nextLabelTextStyle,
                                            ),
                                            const SizedBox(width: _nextTimeGap),
                                            Text(
                                              nextTime,
                                              style: nextTimeTextStyle,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          _nextSuffixText,
                                          style: nextSuffixTextStyle,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: _lowerContentColumnGap),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Transform.scale(
                                    scaleX: _countdownHorizontalScale,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      countdown,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            color: cizgiColor,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                            fontSize:
                                                typography.nextTimeSize + 5,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
