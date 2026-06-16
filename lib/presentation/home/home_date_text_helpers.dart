import 'package:intl/intl.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

String homeFormatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String homeFormatGregorianYear(DateTime dt, AppLocalizations l10n) {
  return DateFormat.y(l10n.localeName).format(dt);
}

String homeFormatGregorianDayMonth(DateTime dt, AppLocalizations l10n) {
  return DateFormat.MMMMd(l10n.localeName).format(dt);
}

String homeFormatHijriYear(DateTime dt) {
  final hijri = _toHijri(dt);
  return hijri.year.toString();
}

String homeFormatHijriDayMonth(DateTime dt, AppLocalizations l10n) {
  final hijri = _toHijri(dt);
  final months = _hijriMonths(l10n.localeName);
  final monthName =
      (hijri.month >= 1 && hijri.month <= 12) ? months[hijri.month - 1] : '';
  return '${hijri.day} $monthName';
}

String homeTitleCase(String input, String locale) {
  final isTr = locale.startsWith('tr');
  final lower = _lowerLocale(input.trim(), isTr);
  if (lower.isEmpty) return lower;
  final buffer = StringBuffer();
  var capitalizeNext = true;
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    if (_isWordChar(ch)) {
      if (capitalizeNext) {
        buffer.write(_upperLocale(ch, isTr));
        capitalizeNext = false;
      } else {
        buffer.write(ch);
      }
    } else {
      buffer.write(ch);
      capitalizeNext = ch == ' ' || ch == '/' || ch == '-' || ch == '.';
    }
  }
  return buffer.toString();
}

String _lowerLocale(String value, bool isTr) {
  if (!isTr) return value.toLowerCase();
  return value.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
}

String _upperLocale(String value, bool isTr) {
  if (!isTr) return value.toUpperCase();
  if (value == 'i') return 'İ';
  if (value == 'ı') return 'I';
  return value.toUpperCase();
}

bool _isWordChar(String ch) {
  return RegExp(r'[0-9A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(ch);
}

List<String> _hijriMonths(String locale) {
  if (locale.startsWith('ar')) {
    return const [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];
  }
  if (locale.startsWith('tr')) {
    return const [
      'Muharrem',
      'Safer',
      'Rebiülevvel',
      'Rebiülahir',
      'Cemaziyelevvel',
      'Cemaziyelahir',
      'Recep',
      'Şaban',
      'Ramazan',
      'Şevval',
      'Zilkade',
      'Zilhicce',
    ];
  }
  return const [
    'Muharram',
    'Safar',
    'Rabiʿ al-awwal',
    'Rabiʿ al-thani',
    'Jumada al-awwal',
    'Jumada al-thani',
    'Rajab',
    'Shaʿban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qadah',
    'Dhu al-Hijjah',
  ];
}

const int _diyanetHijriCorrectionDays = 1;

_HijriDate _toHijri(DateTime date) {
  final correctedDate = date.add(
    const Duration(days: _diyanetHijriCorrectionDays),
  );
  final y = correctedDate.year;
  final m = correctedDate.month;
  final d = correctedDate.day;
  final a = ((14 - m) / 12).floor();
  final y2 = y + 4800 - a;
  final m2 = m + 12 * a - 3;
  final jd =
      d +
      ((153 * m2 + 2) / 5).floor() +
      365 * y2 +
      (y2 / 4).floor() -
      (y2 / 100).floor() +
      (y2 / 400).floor() -
      32045;
  var l = jd - 1948440 + 10632;
  final n = ((l - 1) / 10631).floor();
  l = l - 10631 * n + 354;
  final j =
      (((10985 - l) / 5316).floor()) * (((50 * l) / 17719).floor()) +
      (((l / 5670).floor()) * (((43 * l) / 15238).floor()));
  l =
      l -
      (((30 - j) / 15).floor()) * (((17719 * j) / 50).floor()) -
      ((j / 16).floor()) * (((15238 * j) / 43).floor()) +
      29;
  final month = ((24 * l) / 709).floor();
  final day = l - ((709 * month) / 24).floor();
  final year = 30 * n + j - 30;
  return _HijriDate(year: year, month: month, day: day);
}

class _HijriDate {
  final int year;
  final int month;
  final int day;

  const _HijriDate({
    required this.year,
    required this.month,
    required this.day,
  });
}
