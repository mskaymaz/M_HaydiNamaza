part of 'home_screen.dart';

extension _HomePrayerTimeHelpers on _HomeScreenState {
  Prayer _activePrayer(PrayerTimes times, DateTime now) {
    final fajr = _atToday(times.fajr, now);
    final sunrise = _atToday(times.sunrise, now);
    final dhuhr = _atToday(times.dhuhr, now);
    final asr = _atToday(times.asr, now);
    final maghrib = _atToday(times.maghrib, now);
    final isha = _atToday(times.isha, now);
    if (!now.isBefore(isha)) {
      return Prayer.isha;
    }
    if (!now.isBefore(maghrib)) {
      return Prayer.maghrib;
    }
    if (!now.isBefore(asr)) {
      return Prayer.asr;
    }
    if (!now.isBefore(dhuhr)) {
      return Prayer.dhuhr;
    }
    if (!now.isBefore(sunrise)) {
      return Prayer.sunrise;
    }
    if (!now.isBefore(fajr)) {
      return Prayer.fajr;
    }
    return Prayer.fajr;
  }

  _PrayerNext _nextPrayer(
    PrayerTimes times,
    DateTime now,
    AppLocalizations l10n,
  ) {
    final fajr = _atToday(times.fajr, now);
    final sunrise = _atToday(times.sunrise, now);
    final dhuhr = _atToday(times.dhuhr, now);
    final asr = _atToday(times.asr, now);
    final maghrib = _atToday(times.maghrib, now);
    final isha = _atToday(times.isha, now);
    if (now.isBefore(fajr)) {
      return _PrayerNext(label: l10n.prayerFajr, time: fajr);
    }
    if (now.isBefore(sunrise)) {
      return _PrayerNext(label: l10n.prayerSunrise, time: sunrise);
    }
    if (now.isBefore(dhuhr)) {
      return _PrayerNext(label: l10n.prayerDhuhr, time: dhuhr);
    }
    if (now.isBefore(asr)) {
      return _PrayerNext(label: l10n.prayerAsr, time: asr);
    }
    if (now.isBefore(maghrib)) {
      return _PrayerNext(label: l10n.prayerMaghrib, time: maghrib);
    }
    if (now.isBefore(isha)) {
      return _PrayerNext(label: l10n.prayerIsha, time: isha);
    }
    return _PrayerNext(
      label: l10n.prayerFajr,
      time: fajr.add(const Duration(days: 1)),
    );
  }

  String _formatCountdown(DateTime now, DateTime nextTime) {
    final diff = nextTime.difference(now);
    final totalSeconds = diff.inSeconds.clamp(0, 86400);
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  DateTime _atToday(DateTime source, DateTime now) {
    return _clockTimeOnDate(source, now);
  }

  DateTime _clockTimeOnDate(DateTime source, DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      source.hour,
      source.minute,
      source.second,
      source.millisecond,
      source.microsecond,
    );
  }


  DateTime _timeOfDayOnDate(TimeOfDay source, DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      source.hour,
      source.minute,
    );
  }

  int _compareClockTimes(DateTime left, DateTime right) {
    final leftValue =
        left.hour * 3600000000 +
        left.minute * 60000000 +
        left.second * 1000000 +
        left.millisecond * 1000 +
        left.microsecond;
    final rightValue =
        right.hour * 3600000000 +
        right.minute * 60000000 +
        right.second * 1000000 +
        right.millisecond * 1000 +
        right.microsecond;
    return leftValue.compareTo(rightValue);
  }


  DateTime _prayerTimeForDate(
    Prayer prayer,
    PrayerTimes times,
    DateTime date,
  ) {
    switch (prayer) {
      case Prayer.fajr:
        return _clockTimeOnDate(times.fajr, date);
      case Prayer.sunrise:
        return _clockTimeOnDate(times.sunrise, date);
      case Prayer.dhuhr:
        return _clockTimeOnDate(times.dhuhr, date);
      case Prayer.asr:
        return _clockTimeOnDate(times.asr, date);
      case Prayer.maghrib:
        return _clockTimeOnDate(times.maghrib, date);
      case Prayer.isha:
        return _clockTimeOnDate(times.isha, date);
      case Prayer.none:
        return _clockTimeOnDate(_now, date);
    }
  }

  String _prayerLabel(Prayer prayer, AppLocalizations l10n) {
    switch (prayer) {
      case Prayer.none:
        return '';
      case Prayer.fajr:
        return l10n.prayerFajr;
      case Prayer.sunrise:
        return l10n.prayerSunrise;
      case Prayer.dhuhr:
        return l10n.prayerDhuhr;
      case Prayer.asr:
        return l10n.prayerAsr;
      case Prayer.maghrib:
        return l10n.prayerMaghrib;
      case Prayer.isha:
        return l10n.prayerIsha;
    }
  }
}
