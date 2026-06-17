part of 'home_screen.dart';

extension _HomeCustomTimeHelpers on _HomeScreenState {
  DateTime? _resolveCustomPrayerTime(
    _CustomPrayerTimeRule rule,
    PrayerTimes times,
  ) {
    return _resolveCustomPrayerTimeForDate(rule, times, _now);
  }

  DateTime? _resolveCustomPrayerTimeForDate(
    _CustomPrayerTimeRule rule,
    PrayerTimes times,
    DateTime date,
  ) {
    final targetDate = DateTime(date.year, date.month, date.day);
    switch (rule.mode) {
      case _CustomPrayerTimeMode.manual:
        final manualTime = rule.manualTime;
        if (manualTime == null) return null;
        return _timeOfDayOnDate(manualTime, targetDate);
      case _CustomPrayerTimeMode.beforePrayer:
        final anchor = rule.anchorPrayer;
        if (anchor == null) return null;
        return _prayerTimeForDate(
          anchor,
          times,
          targetDate,
        ).subtract(Duration(minutes: rule.offsetMinutes.abs()));
      case _CustomPrayerTimeMode.afterPrayer:
        final anchor = rule.anchorPrayer;
        if (anchor == null) return null;
        return _prayerTimeForDate(
          anchor,
          times,
          targetDate,
        ).add(Duration(minutes: rule.offsetMinutes.abs()));
    }
  }
}
