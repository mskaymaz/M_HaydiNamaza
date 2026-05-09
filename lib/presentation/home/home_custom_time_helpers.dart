part of 'home_screen.dart';

extension _HomeCustomTimeHelpers on _HomeScreenState {
  DateTime? _resolveCustomPrayerTime(
    _CustomPrayerTimeRule rule,
    PrayerTimes times,
  ) {
    switch (rule.mode) {
      case _CustomPrayerTimeMode.manual:
        final manualTime = rule.manualTime;
        if (manualTime == null) return null;
        return DateTime(
          _now.year,
          _now.month,
          _now.day,
          manualTime.hour,
          manualTime.minute,
        );
      case _CustomPrayerTimeMode.beforePrayer:
        final anchor = rule.anchorPrayer;
        if (anchor == null) return null;
        return _prayerTimeFor(
          anchor,
          times,
        ).subtract(Duration(minutes: rule.offsetMinutes.abs()));
      case _CustomPrayerTimeMode.afterPrayer:
        final anchor = rule.anchorPrayer;
        if (anchor == null) return null;
        return _prayerTimeFor(
          anchor,
          times,
        ).add(Duration(minutes: rule.offsetMinutes.abs()));
      case _CustomPrayerTimeMode.midpointBetweenPrayers:
        final firstAnchor = rule.anchorPrayer;
        final secondAnchor = rule.secondaryAnchorPrayer;
        if (firstAnchor == null || secondAnchor == null) return null;
        final firstTime = _prayerTimeFor(firstAnchor, times);
        final secondTime = _prayerTimeFor(secondAnchor, times);
        final midpointMillis =
            firstTime.millisecondsSinceEpoch +
            ((secondTime.millisecondsSinceEpoch -
                    firstTime.millisecondsSinceEpoch) ~/
                2);
        return DateTime.fromMillisecondsSinceEpoch(midpointMillis);
    }
  }
}
