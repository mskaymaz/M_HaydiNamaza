import 'dart:convert';
import 'dart:io';

import '../lib/core/prayer_engine/calculation_method.dart';
import '../lib/core/prayer_engine/calculation_parameters.dart';
import '../lib/core/prayer_engine/coordinates.dart';
import '../lib/core/prayer_engine/high_latitude_rule.dart';
import '../lib/core/prayer_engine/madhab.dart';
import '../lib/core/prayer_engine/prayer_engine.dart';

CalculationParameters _methodToParams(String method) {
  switch (method) {
    case 'Turkey':
      return CalculationMethod.turkey();
    case 'Qatar':
      return CalculationMethod.qatar();
    case 'Dubai':
      return CalculationMethod.dubai();
    case 'Kuwait':
      return CalculationMethod.kuwait();
    case 'MoonsightingCommittee':
      return CalculationMethod.moonsightingCommittee();
    case 'Singapore':
      return CalculationMethod.singapore();
    case 'Tehran':
      return CalculationMethod.tehran();
    case 'UmmAlQura':
      return CalculationMethod.ummAlQura();
    case 'MuslimWorldLeague':
      return CalculationMethod.muslimWorldLeague();
    case 'Egyptian':
      return CalculationMethod.egyptian();
    case 'Karachi':
      return CalculationMethod.karachi();
    case 'NorthAmerica':
      return CalculationMethod.northAmerica();
    default:
      return CalculationMethod.other();
  }
}

HighLatitudeRule _ruleFromString(String value) {
  switch (value) {
    case 'seventh_of_the_night':
      return HighLatitudeRule.seventhOfTheNight;
    case 'twilight_angle':
      return HighLatitudeRule.twilightAngle;
    case 'middle_of_the_night':
    default:
      return HighLatitudeRule.middleOfTheNight;
  }
}

String _offsetToTz(int minutes) {
  final sign = minutes < 0 ? '-' : '+';
  final total = minutes.abs();
  final hours = (total ~/ 60).toString().padLeft(2, '0');
  final mins = (total % 60).toString().padLeft(2, '0');
  return '$sign$hours:$mins';
}

String _hhmm(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

int _toMinutes(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

void main(List<String> args) {
  final dir = Directory('testdata/adhan');
  if (!dir.existsSync()) {
    stderr.writeln('Missing testdata/adhan');
    exit(1);
  }

  final files = dir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final engine = PrayerEngine();
  var total = 0;
  var tested = 0;
  var skipped = 0;
  var failed = 0;

  for (final f in files) {
    final text = f.readAsStringSync();
    final data = json.decode(text);
    if (data is! List) {
      stderr.writeln('Invalid format: ${f.path}');
      exit(2);
    }

    for (final item in data) {
      if (item is! Map) {
        stderr.writeln('Invalid item: ${f.path}');
        exit(3);
      }

      for (final key in ['date', 'times', 'method', 'madhab', 'high_latitude_rule']) {
        if (!item.containsKey(key)) {
          stderr.writeln('Missing $key in ${f.path}');
          exit(4);
        }
      }

      total++;
      final offset = item['utc_offset_minutes'];
      if (offset == null) {
        skipped++;
        continue;
      }

      final dateParts = (item['date'] as String).split('-');
      final date = DateTime.utc(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );

      final params = _methodToParams(item['method'] as String);
      final madhab = (item['madhab'] as String).toLowerCase();
      params.madhab = madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
      params.highLatitudeRule = _ruleFromString(item['high_latitude_rule'] as String);

      final adjustments = item['adjustments'];
      if (adjustments is Map) {
        params.adjustments = {
          'fajr': (adjustments['fajr'] ?? 0) as int,
          'sunrise': (adjustments['sunrise'] ?? 0) as int,
          'dhuhr': (adjustments['dhuhr'] ?? 0) as int,
          'asr': (adjustments['asr'] ?? 0) as int,
          'maghrib': (adjustments['maghrib'] ?? 0) as int,
          'isha': (adjustments['isha'] ?? 0) as int,
        };
      }

      final coords = Coordinates(
        (item['lat'] as num).toDouble(),
        (item['lon'] as num).toDouble(),
      );

      final timeZone = _offsetToTz((offset as num).toInt());
      final result = engine.calculate(
        date: date,
        coordinates: coords,
        timeZone: timeZone,
        params: params,
      );

      final expected = item['times'] as Map;
      final variance = (item['variance'] ?? 2) as int;

      final actualTimes = {
        'fajr': _hhmm(result.fajr),
        'sunrise': _hhmm(result.sunrise),
        'dhuhr': _hhmm(result.dhuhr),
        'asr': _hhmm(result.asr),
        'maghrib': _hhmm(result.maghrib),
        'isha': _hhmm(result.isha),
      };

      for (final key in actualTimes.keys) {
        final expectedStr = expected[key] as String;
        final actualStr = actualTimes[key]!;
        final diff = (_toMinutes(actualStr) - _toMinutes(expectedStr)).abs();
        if (diff > variance) {
          failed++;
          stderr.writeln('Mismatch ${f.path} ${item['date']} $key exp=$expectedStr got=$actualStr diff=$diff');
        }
      }

      tested++;
    }
  }

  stdout.writeln('Golden data checked. total=$total tested=$tested skipped=$skipped failed=$failed');
  if (failed > 0) {
    exit(5);
  }
}
