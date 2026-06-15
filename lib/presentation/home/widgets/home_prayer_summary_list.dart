import 'package:flutter/material.dart';

import '../../../core/prayer_engine/prayer.dart';
import 'home_prayer_list_item.dart';

const EdgeInsets _summaryPrayerRowPadding = EdgeInsets.fromLTRB(0, 1, 0, 1);
const double _summaryPrayerLabelColumnWidth = 96.0;
const double _summaryPrayerTimeColumnWidth = 72.0;
const double _summaryPrayerTextGap = 25.0;
const double _summaryPrayerBellGap = 12.0;
const double _summaryPrayerBellBoxSize = 30.0;
const double _summaryPrayerBellIconSize = 20.0;

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
            final labelStyle = Theme.of(context).textTheme.titleMedium
                ?.copyWith(
                  color: labelColor,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w300,
                  fontSize: 22.0,
                );

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
                child: isCustomPrayer
                    ? _CustomPrayerSummaryRow(
                        label: label,
                        labelStyle: labelStyle,
                        isActive: isActive,
                        timeLabel: item.timeLabel,
                        timeColor: timeColor,
                        hasReminder: hasReminder,
                        bellColor: bellColor,
                        onOpenControls: onOpenControls,
                      )
                    : FittedBox(
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
                                style: labelStyle,
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

class _CustomPrayerSummaryRow extends StatelessWidget {
  final String label;
  final TextStyle? labelStyle;
  final bool isActive;
  final String timeLabel;
  final Color timeColor;
  final bool hasReminder;
  final Color bellColor;
  final VoidCallback onOpenControls;

  const _CustomPrayerSummaryRow({
    required this.label,
    required this.labelStyle,
    required this.isActive,
    required this.timeLabel,
    required this.timeColor,
    required this.hasReminder,
    required this.bellColor,
    required this.onOpenControls,
  });

  @override
  Widget build(BuildContext context) {
    const tailWidth =
        _summaryPrayerTimeColumnWidth +
        _summaryPrayerBellGap +
        _summaryPrayerBellBoxSize;
    const rowWidth =
        _summaryPrayerLabelColumnWidth + _summaryPrayerTextGap + tailWidth;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < rowWidth) {
          return FittedBox(
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
                    style: labelStyle,
                  ),
                ),
                const SizedBox(width: _summaryPrayerTextGap),
                _SummaryTail(
                  timeLabel: timeLabel,
                  timeColor: timeColor,
                  isActive: isActive,
                  hasReminder: hasReminder,
                  bellColor: bellColor,
                  onOpenControls: onOpenControls,
                ),
              ],
            ),
          );
        }

        final sideSpace = (constraints.maxWidth - rowWidth) / 2;

        return Row(
          children: [
            SizedBox(
              width: sideSpace + _summaryPrayerLabelColumnWidth,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: labelStyle,
              ),
            ),
            const SizedBox(width: _summaryPrayerTextGap),
            _SummaryTail(
              timeLabel: timeLabel,
              timeColor: timeColor,
              isActive: isActive,
              hasReminder: hasReminder,
              bellColor: bellColor,
              onOpenControls: onOpenControls,
            ),
            SizedBox(width: sideSpace),
          ],
        );
      },
    );
  }
}

class _SummaryTail extends StatelessWidget {
  final String timeLabel;
  final Color timeColor;
  final bool isActive;
  final bool hasReminder;
  final Color bellColor;
  final VoidCallback onOpenControls;

  const _SummaryTail({
    required this.timeLabel,
    required this.timeColor,
    required this.isActive,
    required this.hasReminder,
    required this.bellColor,
    required this.onOpenControls,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _summaryPrayerTimeColumnWidth,
          child: Text(
            timeLabel,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: timeColor,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
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
    );
  }
}

class PrayerScrollOverflowIndicator extends StatefulWidget {
  final ScrollController controller;
  final Color cizgiColor;
  final Widget child;

  const PrayerScrollOverflowIndicator({
    super.key,
    required this.controller,
    required this.cizgiColor,
    required this.child,
  });

  @override
  State<PrayerScrollOverflowIndicator> createState() =>
      _PrayerScrollOverflowIndicatorState();
}

class _PrayerScrollOverflowIndicatorState
    extends State<PrayerScrollOverflowIndicator> {
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
  void didUpdateWidget(PrayerScrollOverflowIndicator oldWidget) {
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
