import 'daily_content_models.dart';

class DailyContentFileParseResult<T> {
  final List<T> records;
  final int skippedCount;
  final List<String> warnings;

  const DailyContentFileParseResult({
    required this.records,
    required this.skippedCount,
    required this.warnings,
  });
}

class DailyContentLoadResult {
  final List<DailyAyahRecord> ayahs;
  final List<DailyHadithRecord> hadiths;
  final int skippedCount;
  final List<String> warnings;

  const DailyContentLoadResult({
    required this.ayahs,
    required this.hadiths,
    required this.skippedCount,
    required this.warnings,
  });
}
