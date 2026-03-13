import 'astronomical.dart';
import 'calculation_parameters.dart';
import 'coordinates.dart';
import 'date_utils.dart';
import 'madhab.dart';
import 'polar_circle_resolution.dart';
import 'prayer.dart';
import 'solar_time.dart';
import 'time_components.dart';

class PrayerTimes {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime sunset;
  final DateTime maghrib;
  final DateTime isha;

  final Coordinates coordinates;
  final DateTime date;
  final CalculationParameters calculationParameters;

  PrayerTimes._(
    this.coordinates,
    this.date,
    this.calculationParameters,
    this.fajr,
    this.sunrise,
    this.dhuhr,
    this.asr,
    this.sunset,
    this.maghrib,
    this.isha,
  );

  factory PrayerTimes(
    Coordinates coordinates,
    DateTime date,
    CalculationParameters calculationParameters,
  ) {
    var solarTime = SolarTime(date, coordinates);

    DateTime fajrTime;
    DateTime sunriseTime;
    DateTime dhuhrTime;
    DateTime asrTime;
    DateTime sunsetTime;
    DateTime maghribTime;
    DateTime ishaTime;

    dhuhrTime = TimeComponents(solarTime.transit).utcDate(
      date.year,
      date.month,
      date.day,
    );
    sunriseTime = TimeComponents(solarTime.sunrise).utcDate(
      date.year,
      date.month,
      date.day,
    );
    sunsetTime = TimeComponents(solarTime.sunset).utcDate(
      date.year,
      date.month,
      date.day,
    );

    final tomorrow = dateByAddingDays(date, 1);
    var tomorrowSolarTime = SolarTime(tomorrow, coordinates);

    final polarCircleResolver = calculationParameters.polarCircleResolution;
    if ((tomorrowSolarTime.sunrise.isNaN) &&
        polarCircleResolver != PolarCircleResolution.unresolved) {
      final resolved = polarCircleResolvedValues(
        polarCircleResolver,
        date,
        coordinates,
      );
      solarTime = resolved.solarTime;
      tomorrowSolarTime = resolved.tomorrowSolarTime;

      dhuhrTime = TimeComponents(solarTime.transit).utcDate(
        date.year,
        date.month,
        date.day,
      );
      sunriseTime = TimeComponents(solarTime.sunrise).utcDate(
        date.year,
        date.month,
        date.day,
      );
      sunsetTime = TimeComponents(solarTime.sunset).utcDate(
        date.year,
        date.month,
        date.day,
      );
    }

    asrTime = TimeComponents(
      solarTime.afternoon(shadowLength(calculationParameters.madhab)),
    ).utcDate(date.year, date.month, date.day);

    final tomorrowSunrise = TimeComponents(tomorrowSolarTime.sunrise).utcDate(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
    );
    final night = (tomorrowSunrise.millisecondsSinceEpoch -
            sunsetTime.millisecondsSinceEpoch) /
        1000;

    fajrTime = TimeComponents(
      solarTime.hourAngle(-1 * calculationParameters.fajrAngle, false),
    ).utcDate(date.year, date.month, date.day);

    if (calculationParameters.method == 'MoonsightingCommittee' &&
        coordinates.latitude >= 55) {
      final nightFraction = night / 7;
      fajrTime = dateByAddingSeconds(sunriseTime, -nightFraction.round());
    }

    final safeFajr = () {
      if (calculationParameters.method == 'MoonsightingCommittee') {
        return Astronomical.seasonAdjustedMorningTwilight(
          coordinates.latitude,
          dayOfYear(date),
          date.year,
          sunriseTime,
        );
      } else {
        final portion = calculationParameters.nightPortions()['fajr'] ?? 0;
        final nightFraction = portion * night;
        return dateByAddingSeconds(sunriseTime, -nightFraction.round());
      }
    }();

    if (fajrTime.isAfter(safeFajr)) {
      fajrTime = safeFajr;
    }

    if (calculationParameters.ishaInterval > 0) {
      ishaTime = dateByAddingMinutes(sunsetTime, calculationParameters.ishaInterval);
    } else {
      ishaTime = TimeComponents(
        solarTime.hourAngle(-1 * calculationParameters.ishaAngle, true),
      ).utcDate(date.year, date.month, date.day);

      if (calculationParameters.method == 'MoonsightingCommittee' &&
          coordinates.latitude >= 55) {
        final nightFraction = night / 7;
        ishaTime = dateByAddingSeconds(sunsetTime, nightFraction.round());
      }

      final safeIsha = () {
        if (calculationParameters.method == 'MoonsightingCommittee') {
          return Astronomical.seasonAdjustedEveningTwilight(
            coordinates.latitude,
            dayOfYear(date),
            date.year,
            sunsetTime,
            calculationParameters.shafaq,
          );
        } else {
          final portion = calculationParameters.nightPortions()['isha'] ?? 0;
          final nightFraction = portion * night;
          return dateByAddingSeconds(sunsetTime, nightFraction.round());
        }
      }();

      if (ishaTime.isBefore(safeIsha)) {
        ishaTime = safeIsha;
      }
    }

    maghribTime = sunsetTime;
    if (calculationParameters.maghribAngle != 0) {
      final angleBasedMaghrib = TimeComponents(
        solarTime.hourAngle(-1 * calculationParameters.maghribAngle, true),
      ).utcDate(date.year, date.month, date.day);
      if (sunsetTime.isBefore(angleBasedMaghrib) &&
          ishaTime.isAfter(angleBasedMaghrib)) {
        maghribTime = angleBasedMaghrib;
      }
    }

    final fajrAdjustment =
        (calculationParameters.adjustments['fajr'] ?? 0) +
            (calculationParameters.methodAdjustments['fajr'] ?? 0);
    final sunriseAdjustment =
        (calculationParameters.adjustments['sunrise'] ?? 0) +
            (calculationParameters.methodAdjustments['sunrise'] ?? 0);
    final dhuhrAdjustment =
        (calculationParameters.adjustments['dhuhr'] ?? 0) +
            (calculationParameters.methodAdjustments['dhuhr'] ?? 0);
    final asrAdjustment =
        (calculationParameters.adjustments['asr'] ?? 0) +
            (calculationParameters.methodAdjustments['asr'] ?? 0);
    final maghribAdjustment =
        (calculationParameters.adjustments['maghrib'] ?? 0) +
            (calculationParameters.methodAdjustments['maghrib'] ?? 0);
    final ishaAdjustment =
        (calculationParameters.adjustments['isha'] ?? 0) +
            (calculationParameters.methodAdjustments['isha'] ?? 0);

    return PrayerTimes._(
      coordinates,
      date,
      calculationParameters,
      roundedMinute(dateByAddingMinutes(fajrTime, fajrAdjustment), calculationParameters.rounding),
      roundedMinute(dateByAddingMinutes(sunriseTime, sunriseAdjustment), calculationParameters.rounding),
      roundedMinute(dateByAddingMinutes(dhuhrTime, dhuhrAdjustment), calculationParameters.rounding),
      roundedMinute(dateByAddingMinutes(asrTime, asrAdjustment), calculationParameters.rounding),
      roundedMinute(sunsetTime, calculationParameters.rounding),
      roundedMinute(dateByAddingMinutes(maghribTime, maghribAdjustment), calculationParameters.rounding),
      roundedMinute(dateByAddingMinutes(ishaTime, ishaAdjustment), calculationParameters.rounding),
    );
  }

  Prayer currentPrayer([DateTime? now]) {
    final dateTime = now ?? DateTime.now().toUtc();
    if (dateTime.isAfter(isha) || dateTime.isAtSameMomentAs(isha)) {
      return Prayer.isha;
    } else if (dateTime.isAfter(maghrib) || dateTime.isAtSameMomentAs(maghrib)) {
      return Prayer.maghrib;
    } else if (dateTime.isAfter(asr) || dateTime.isAtSameMomentAs(asr)) {
      return Prayer.asr;
    } else if (dateTime.isAfter(dhuhr) || dateTime.isAtSameMomentAs(dhuhr)) {
      return Prayer.dhuhr;
    } else if (dateTime.isAfter(sunrise) || dateTime.isAtSameMomentAs(sunrise)) {
      return Prayer.sunrise;
    } else if (dateTime.isAfter(fajr) || dateTime.isAtSameMomentAs(fajr)) {
      return Prayer.fajr;
    } else {
      return Prayer.none;
    }
  }

  PrayerTimes withOffset(Duration offset) {
    return PrayerTimes._(
      coordinates,
      date,
      calculationParameters,
      fajr.add(offset),
      sunrise.add(offset),
      dhuhr.add(offset),
      asr.add(offset),
      sunset.add(offset),
      maghrib.add(offset),
      isha.add(offset),
    );
  }
}
