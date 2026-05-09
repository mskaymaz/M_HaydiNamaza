import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../../core/config/config_registry.dart';

class HomeTopPanel extends StatelessWidget {
  final String provinceLabel;
  final String districtLabel;
  final String nextLabel;
  final String nextTime;
  final String countdown;
  final String dateYearLabel;
  final String dateDayMonthLabel;
  final String timeLabel;
  final VoidCallback onToggleDate;
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
    required this.dateYearLabel,
    required this.dateDayMonthLabel,
    required this.timeLabel,
    required this.onToggleDate,
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
    final lowerSectionHeight =
        typography.nextTimeSize + typography.nextLabelSize + 20;
    final topRowHeight = settingsIconBoxSize > typography.locationSize + 8
        ? settingsIconBoxSize
        : typography.locationSize + 8;
    final locationTextStyle = theme.textTheme.titleMedium?.copyWith(
      color: cizgiColor,
      fontWeight: FontWeight.w500,
      fontSize: typography.locationSize,
    );
    final dateTextStyle = theme.textTheme.titleSmall?.copyWith(
      color: cizgiColor,
      fontWeight: FontWeight.w600,
      fontSize: (typography.methodSize + 1) * 1.2,
      letterSpacing: -0.2,
    );
    final clockTextStyle = theme.textTheme.titleSmall?.copyWith(
      color: cizgiColor.withValues(alpha: 0.85),
      fontWeight: FontWeight.w300,
      fontSize: typography.nextLabelSize * 1.2,
      letterSpacing: -0.6,
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
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: onLocationTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: cizgiColor,
                          size: typography.locationSize + 1,
                        ),
                        const SizedBox(width: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: provinceLabel,
                                style: locationTextStyle,
                              ),
                              if (districtLabel.trim().isNotEmpty) ...[
                                TextSpan(text: ' / ', style: locationTextStyle),
                                TextSpan(
                                  text: districtLabel,
                                  style: locationTextStyle?.copyWith(
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Transform.translate(
                    offset: const Offset(13, 0),
                    child: IconButton(
                      onPressed: onSettings,
                      icon: Icon(
                        Icons.settings_outlined,
                        color: cizgiColor.withValues(
                          alpha: settingsIconOpacity,
                        ),
                        size: settingsIconSize * 1.3,
                      ),
                      tooltip: AppLocalizations.of(context)!.settingsTitle,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: settingsIconBoxSize,
                        minHeight: settingsIconBoxSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 1, color: cizgiColor.withValues(alpha: 0.18)),
          const SizedBox(height: 10),
          SizedBox(
            height: lowerSectionHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompactWidth = constraints.maxWidth < 420;
                final leftSlotWidth = isCompactWidth
                    ? 88.0
                    : math.min(
                        math.max(constraints.maxWidth * 0.27, 108.0),
                        160.0,
                      );
                final rightSlotWidth = isCompactWidth
                    ? 64.0
                    : leftSlotWidth;
                final qiblaOffsetX = isCompactWidth ? 4.0 : 13.0;

                return Row(
                  children: [
                    SizedBox(
                      width: leftSlotWidth,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: leftSlotWidth,
                              child: GestureDetector(
                                onTap: onToggleDate,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '$dateDayMonthLabel $dateYearLabel',
                                    style: dateTextStyle,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              timeLabel,
                              style: clockTextStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  nextLabel,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: cizgiColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: typography.nextLabelSize,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  nextTime,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: cizgiColor.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w300,
                                    fontSize: typography.nextLabelSize,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              countdown,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: cizgiColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontSize: typography.nextTimeSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: rightSlotWidth,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Transform.translate(
                          offset: Offset(qiblaOffsetX, 0),
                          child: IconButton(
                            onPressed: onQibla,
                            icon: Icon(
                              Icons.explore_outlined,
                              color: cizgiColor.withValues(alpha: 0.92),
                              size: settingsIconSize * 2.16,
                            ),
                            tooltip: 'Kıble Yönü',
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: settingsIconBoxSize * 1.5,
                              minHeight: settingsIconBoxSize * 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
