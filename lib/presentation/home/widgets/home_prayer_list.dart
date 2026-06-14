import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';
import '../../../core/prayer_engine/prayer.dart';
import 'home_presentational_widgets.dart';

const EdgeInsets _summaryPrayerRowPadding = EdgeInsets.fromLTRB(0, 1, 0, 1);
const double _summaryPrayerLabelColumnWidth = 96.0;
const double _summaryPrayerTimeColumnWidth = 72.0;
const double _summaryPrayerTextGap = 25.0;
const double _summaryPrayerBellGap = 12.0;
const double _summaryPrayerBellBoxSize = 30.0;
const double _summaryPrayerBellIconSize = 20.0;
const double _controlPrayerLabelWidth = 118.0;
const double _controlPrayerTextSize = 20.0;
const double _controlPrayerIconSize = 18.5;
const double _controlPrayerIconBoxSize = 22.0;
const double _controlPrayerChipWidth = 44.0;
const double _controlPrayerChipVerticalPadding = 0.0;
const double _controlPrayerChipFontSize = 16.0;

class HomePrayerListItem {
  final String id;
  final Prayer? prayer;
  final String label;
  final DateTime? sortTime;
  final TextEditingController? labelController;
  final ValueChanged<String>? onLabelChanged;
  final VoidCallback? onLabelEditingComplete;
  final String timeLabel;
  final VoidCallback? onTimeTap;
  final TextEditingController reminderController;
  final ValueChanged<String> onReminderChanged;
  final VoidCallback onReminderTap;
  final bool voiceEnabled;
  final bool visualEnabled;
  final bool azanEnabled;
  final bool vibrationEnabled;
  final VoidCallback onVoiceToggle;
  final VoidCallback onVisualToggle;
  final VoidCallback onAzanToggle;
  final VoidCallback onVibrationToggle;
  final VoidCallback? onDelete;

  HomePrayerListItem({
    required this.id,
    required this.prayer,
    required this.label,
    this.sortTime,
    this.labelController,
    this.onLabelChanged,
    this.onLabelEditingComplete,
    required this.timeLabel,
    this.onTimeTap,
    required this.reminderController,
    required this.onReminderChanged,
    required this.onReminderTap,
    required this.voiceEnabled,
    required this.visualEnabled,
    required this.azanEnabled,
    required this.vibrationEnabled,
    required this.onVoiceToggle,
    required this.onVisualToggle,
    required this.onAzanToggle,
    required this.onVibrationToggle,
    this.onDelete,
  });
}

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
            child: _PrayerScrollOverflowIndicator(
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

class HomePrayerSummaryList extends StatelessWidget {
  final ScrollController controller;
  final List<HomePrayerListItem> items;
  final Prayer active;
  final EdgeInsets listPadding;
  final Color cizgiColor;
  final Color activeColor;
  final Color customPrayerLabelColor;
  final VoidCallback onOpenControls;

  const HomePrayerSummaryList({
    super.key,
    required this.controller,
    required this.items,
    required this.active,
    required this.listPadding,
    required this.cizgiColor,
    required this.activeColor,
    required this.customPrayerLabelColor,
    required this.onOpenControls,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final activeIndex = items.indexWhere((entry) => entry.prayer == active);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: _PrayerScrollOverflowIndicator(
        controller: controller,
        cizgiColor: cizgiColor,
        child: ListView.separated(
          controller: controller,
          padding: listPadding,
          itemBuilder: (context, index) {
            final item = items[index];
            final isCustomPrayer = item.prayer == null;
            final isPast =
                item.prayer != null && activeIndex != -1 && index < activeIndex;
            final isActive = item.prayer == active;
            final Color labelColor;
            if (isActive) {
              labelColor = cizgiColor;
            } else if (isPast) {
              labelColor = cizgiColor.withValues(alpha: 0.48);
            } else if (isCustomPrayer) {
              labelColor = customPrayerLabelColor;
            } else {
              labelColor = cizgiColor;
            }
            final timeColor = isActive
                ? cizgiColor
                : isPast
                ? cizgiColor.withValues(alpha: 0.56)
                : cizgiColor.withValues(alpha: 0.92);
            final label = item.labelController?.text.trim().isNotEmpty == true
                ? item.labelController!.text.trim()
                : item.label;
            final hasReminder =
                item.voiceEnabled ||
                item.visualEnabled ||
                item.azanEnabled ||
                item.vibrationEnabled;
            final bellColor = hasReminder
                ? cizgiColor.withValues(alpha: 0.95)
                : cizgiColor.withValues(alpha: 0.34);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: _summaryPrayerRowPadding,
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isActive
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.42),
                        width: 1,
                      )
                    : null,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: _summaryPrayerLabelColumnWidth,
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: labelColor,
                                fontWeight: isActive
                                    ? FontWeight.w500
                                    : FontWeight.w300,
                                fontSize: 22.0,
                              ),
                        ),
                      ),
                      const SizedBox(width: _summaryPrayerTextGap),
                      SizedBox(
                        width: _summaryPrayerTimeColumnWidth,
                        child: Text(
                          item.timeLabel,
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: timeColor,
                                fontWeight: isActive
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 24.0,
                              ),
                        ),
                      ),
                      const SizedBox(width: _summaryPrayerBellGap),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onOpenControls,
                        child: SizedBox(
                          width: _summaryPrayerBellBoxSize,
                          height: _summaryPrayerBellBoxSize,
                          child: Center(
                            child: Icon(
                              hasReminder
                                  ? Icons.notifications_active_outlined
                                  : Icons.notifications_none_outlined,
                              color: bellColor,
                              size: _summaryPrayerBellIconSize,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: Color(0x22000000)),
          itemCount: items.length,
        ),
      ),
    );
  }
}

class _PrayerScrollOverflowIndicator extends StatefulWidget {
  final ScrollController controller;
  final Color cizgiColor;
  final Widget child;

  const _PrayerScrollOverflowIndicator({
    required this.controller,
    required this.cizgiColor,
    required this.child,
  });

  @override
  State<_PrayerScrollOverflowIndicator> createState() =>
      _PrayerScrollOverflowIndicatorState();
}

class _PrayerScrollOverflowIndicatorState
    extends State<_PrayerScrollOverflowIndicator> {
  static const double _threshold = 2.0;
  bool _showTop = false;
  bool _showBottom = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncIndicators);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIndicators());
  }

  @override
  void didUpdateWidget(_PrayerScrollOverflowIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncIndicators);
      widget.controller.addListener(_syncIndicators);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIndicators());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncIndicators);
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      _queueSyncIndicators();
    }
    return false;
  }

  bool _handleMetricsNotification(ScrollMetricsNotification notification) {
    _queueSyncIndicators();
    return false;
  }

  void _queueSyncIndicators() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIndicators());
  }

  void _syncIndicators() {
    if (!mounted) return;
    final positions = widget.controller.positions;
    if (positions.isEmpty) {
      if (!_showTop && !_showBottom) return;
      setState(() {
        _showTop = false;
        _showBottom = false;
      });
      return;
    }
    final position = positions.last;
    final showTop = position.extentBefore > _threshold;
    final showBottom = position.extentAfter > _threshold;
    if (showTop == _showTop && showBottom == _showBottom) return;
    setState(() {
      _showTop = showTop;
      _showBottom = showBottom;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _handleMetricsNotification,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            _PrayerOverflowArrow(
              alignment: Alignment.topCenter,
              icon: Icons.keyboard_arrow_up_rounded,
              visible: _showTop,
              cizgiColor: widget.cizgiColor,
            ),
            _PrayerOverflowArrow(
              alignment: Alignment.bottomCenter,
              icon: Icons.keyboard_arrow_down_rounded,
              visible: _showBottom,
              cizgiColor: widget.cizgiColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerOverflowArrow extends StatelessWidget {
  final Alignment alignment;
  final IconData icon;
  final bool visible;
  final Color cizgiColor;

  const _PrayerOverflowArrow({
    required this.alignment,
    required this.icon,
    required this.visible,
    required this.cizgiColor,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: visible ? 1 : 0,
            child: Container(
              width: 42,
              height: 24,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: cizgiColor.withValues(alpha: 0.22),
                  width: 0.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: cizgiColor.withValues(alpha: 0.92),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
