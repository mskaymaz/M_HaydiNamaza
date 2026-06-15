import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';
import '../../../core/prayer_engine/prayer.dart';
import 'home_prayer_list_item.dart';
import 'home_prayer_summary_list.dart';
import 'home_presentational_widgets.dart';
export 'home_prayer_list_item.dart';
export 'home_prayer_summary_list.dart';

const double _controlPrayerLabelWidth = 118.0;
const double _controlPrayerTextSize = 20.0;
const double _controlPrayerIconSize = 18.5;
const double _controlPrayerIconBoxSize = 22.0;
const double _controlPrayerChipWidth = 44.0;
const double _controlPrayerChipVerticalPadding = 0.0;
const double _controlPrayerChipFontSize = 16.0;

class HomePrayerList extends StatelessWidget {
  final ScrollController controller;
  final List<HomePrayerListItem> items;
  final Prayer active;
  final SurfaceStyle style;
  final EdgeInsets listPadding;
  final double rowGap;
  final InlineIconStyle iconStyle;
  final InlineChipStyle chipStyle;
  final HomeTypography typography;
  final Color cizgiColor;
  final Color activeColor;
  final Color customPrayerLabelColor;
  final bool showVoiceIcon;
  final bool showVisualIcon;
  final bool showAzanIcon;
  final bool showVibrationIcon;

  const HomePrayerList({
    super.key,
    required this.controller,
    required this.items,
    required this.active,
    required this.style,
    required this.listPadding,
    required this.rowGap,
    required this.iconStyle,
    required this.chipStyle,
    required this.typography,
    required this.cizgiColor,
    required this.activeColor,
    required this.customPrayerLabelColor,
    required this.showVoiceIcon,
    required this.showVisualIcon,
    required this.showAzanIcon,
    required this.showVibrationIcon,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    const rowScale = 0.85;
    const rowTextSize = _controlPrayerTextSize;
    final scaledChipStyle = InlineChipStyle(
      width: _controlPrayerChipWidth,
      verticalPadding: _controlPrayerChipVerticalPadding,
      fontSize: _controlPrayerChipFontSize,
      backgroundColor: chipStyle.backgroundColor,
      borderColor: chipStyle.borderColor,
      borderRadius: chipStyle.borderRadius,
    );
    final scaledIconStyle = InlineIconStyle(
      size: _controlPrayerIconBoxSize,
      iconSize: _controlPrayerIconSize,
      backgroundColor: iconStyle.backgroundColor,
      borderRadius: iconStyle.borderRadius,
    );
    const labelSlotWidth = _controlPrayerLabelWidth;
    final timeSlotWidth = typography.nextLabelSize * 2.8;
    final iconSlotWidth = iconStyle.size * 1.3;
    final activeIndex = items.indexWhere((entry) => entry.prayer == active);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: Column(
        children: [
          Expanded(
            child: PrayerScrollOverflowIndicator(
              controller: controller,
              cizgiColor: cizgiColor,
              child: ListView.separated(
                controller: controller,
                padding: listPadding,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isCustomPrayer = item.prayer == null;
                  final isPast =
                      item.prayer != null &&
                      activeIndex != -1 &&
                      index < activeIndex;
                  final isActive = item.prayer == active;
                  final Color labelColor;
                  if (isActive) {
                    labelColor = cizgiColor;
                  } else if (isPast) {
                    labelColor = cizgiColor.withValues(alpha: 0.45);
                  } else if (isCustomPrayer) {
                    labelColor = customPrayerLabelColor;
                  } else {
                    labelColor = cizgiColor;
                  }
                  final timeColor = isActive
                      ? cizgiColor.withValues(alpha: 0.9)
                      : isPast
                      ? cizgiColor.withValues(alpha: 0.5)
                      : cizgiColor.withValues(alpha: 0.9);
                  final controlColor = cizgiColor;
                  final chipBackgroundColor = isActive
                      ? activeColor.withValues(alpha: 0.12)
                      : chipStyle.backgroundColor;
                  final chipBorderColor = isActive
                      ? activeColor.withValues(alpha: 0.45)
                      : chipStyle.borderColor;
                  final labelStyle = Theme.of(context).textTheme.titleSmall
                      ?.copyWith(
                        color: labelColor,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w300,
                        fontSize: rowTextSize,
                      );
                  final rowWidgets = <Widget>[
                    SizedBox(
                      width: labelSlotWidth,
                      child: item.labelController == null
                          ? Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              softWrap: false,
                              textAlign: TextAlign.right,
                              style: labelStyle,
                            )
                          : TextField(
                              controller: item.labelController,
                              onChanged: item.onLabelChanged,
                              onEditingComplete: () {
                                item.onLabelEditingComplete?.call();
                                FocusScope.of(context).unfocus();
                              },
                              onSubmitted: (_) {
                                item.onLabelEditingComplete?.call();
                              },
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              textInputAction: TextInputAction.done,
                              style: labelStyle?.copyWith(
                                fontWeight: FontWeight.w300,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                    ),
                    SizedBox(
                      width: timeSlotWidth,
                      child: item.onTimeTap == null
                          ? Text(
                              item.timeLabel,
                              maxLines: 1,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: timeColor,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: rowTextSize,
                                  ),
                            )
                          : InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: item.onTimeTap,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  item.timeLabel,
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: timeColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: rowTextSize,
                                        decoration: TextDecoration.underline,
                                      ),
                                ),
                              ),
                            ),
                    ),
                    SizedBox(
                      width: scaledChipStyle.width,
                      child: HomeReminderChip(
                        controller: item.reminderController,
                        style: scaledChipStyle,
                        cizgiColor: controlColor,
                        backgroundColor: chipBackgroundColor,
                        borderColor: chipBorderColor,
                        onTap: item.onReminderTap,
                      ),
                    ),
                    if (showVoiceIcon)
                      SizedBox(
                        width: iconSlotWidth,
                        child: HomeIconToggle(
                          icon: Icons.volume_up_outlined,
                          style: scaledIconStyle,
                          isEnabled: item.voiceEnabled,
                          cizgiColor: controlColor,
                          onTap: item.onVoiceToggle,
                        ),
                      ),
                    if (showVisualIcon)
                      SizedBox(
                        width: iconSlotWidth,
                        child: HomeIconToggle(
                          icon: Icons.desktop_windows_outlined,
                          style: scaledIconStyle,
                          isEnabled: item.visualEnabled,
                          cizgiColor: controlColor,
                          onTap: item.onVisualToggle,
                        ),
                      ),
                    if (showAzanIcon)
                      SizedBox(
                        width: iconSlotWidth,
                        child: HomeIconToggle(
                          icon: Icons.mosque_sharp,
                          style: scaledIconStyle,
                          isEnabled: item.azanEnabled,
                          cizgiColor: controlColor,
                          onTap: item.onAzanToggle,
                        ),
                      ),
                    if (showVibrationIcon)
                      SizedBox(
                        width: iconSlotWidth,
                        child: HomeIconToggle(
                          icon: Icons.vibration_outlined,
                          style: scaledIconStyle,
                          isEnabled: item.vibrationEnabled,
                          cizgiColor: controlColor,
                          onTap: item.onVibrationToggle,
                        ),
                      ),
                    SizedBox(
                      width: iconStyle.iconSize * rowScale + 2,
                      child: item.onDelete == null
                          ? const SizedBox.shrink()
                          : HomeIconToggle(
                              icon: Icons.delete_outline,
                              style: InlineIconStyle(
                                size: scaledIconStyle.iconSize + 2,
                                iconSize: scaledIconStyle.iconSize,
                                backgroundColor:
                                    scaledIconStyle.backgroundColor,
                                borderRadius: scaledIconStyle.borderRadius,
                              ),
                              isEnabled: true,
                              cizgiColor: controlColor,
                              onTap: item.onDelete!,
                            ),
                    ),
                  ];

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: isActive
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.45),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  for (
                                    var i = 0;
                                    i < rowWidgets.length;
                                    i++
                                  ) ...[
                                    if (i > 0)
                                      SizedBox(
                                        width: i == 3
                                            ? 8
                                            : i <= 2
                                            ? 10
                                            : 0,
                                      ),
                                    rowWidgets[i],
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0x22000000)),
                itemCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
