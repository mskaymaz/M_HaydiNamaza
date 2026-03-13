import 'astronomical.dart';
import 'rounding.dart';

DateTime dateByAddingDays(DateTime date, int days) {
  return DateTime.utc(
    date.year,
    date.month,
    date.day + days,
    date.hour,
    date.minute,
    date.second,
  );
}

DateTime dateByAddingMinutes(DateTime date, int minutes) {
  return dateByAddingSeconds(date, minutes * 60);
}

DateTime dateByAddingSeconds(DateTime date, int seconds) {
  return date.add(Duration(seconds: seconds));
}

DateTime roundedMinute(DateTime date, [Rounding rounding = Rounding.nearest]) {
  final seconds = date.second;
  var offset = seconds >= 30 ? 60 - seconds : -seconds;
  if (rounding == Rounding.up) {
    offset = 60 - seconds;
  } else if (rounding == Rounding.none) {
    offset = 0;
  }
  return dateByAddingSeconds(date, offset);
}

int dayOfYear(DateTime date) {
  var returnedDayOfYear = 0;
  final feb = Astronomical.isLeapYear(date.year) ? 29 : 28;
  final months = [31, feb, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  for (var i = 0; i < date.month - 1; i++) {
    returnedDayOfYear += months[i];
  }
  returnedDayOfYear += date.day;
  return returnedDayOfYear;
}

bool isValidDate(DateTime date) {
  // DateTime is always valid in Dart; keep for parity.
  return true;
}
