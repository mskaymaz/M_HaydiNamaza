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
    final dhuhr = _atToday(times.dhuhr, now);
    final asr = _atToday(times.asr, now);
    final maghrib = _atToday(times.maghrib, now);
    final isha = _atToday(times.isha, now);
    if (now.isBefore(fajr)) {
      return _PrayerNext(label: l10n.prayerFajr, time: fajr);
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
    return DateTime(
      now.year,
      now.month,
      now.day,
      source.hour,
      source.minute,
      source.second,
    );
  }

  DateTime _prayerTimeFor(Prayer prayer, PrayerTimes times) {
    switch (prayer) {
      case Prayer.fajr:
        return _atToday(times.fajr, _now);
      case Prayer.sunrise:
        return _atToday(times.sunrise, _now);
      case Prayer.dhuhr:
        return _atToday(times.dhuhr, _now);
      case Prayer.asr:
        return _atToday(times.asr, _now);
      case Prayer.maghrib:
        return _atToday(times.maghrib, _now);
      case Prayer.isha:
        return _atToday(times.isha, _now);
      case Prayer.none:
        return _now;
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
