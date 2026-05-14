import 'daily_content_models.dart';

class DailyContentFileParseResult<T> {
  final String? schemaVersion;
  final String? contentVersion;
  final String? type;
  final List<T> records;
  final int skippedCount;
  final List<String> warnings;

  const DailyContentFileParseResult({
    required this.schemaVersion,
    required this.contentVersion,
    required this.type,
    required this.records,
    required this.skippedCount,
    required this.warnings,
  });
}

class DailyContentLoadResult {
  final String? ayahSchemaVersion;
  final String? hadithSchemaVersion;
  final String? ayahContentVersion;
  final String? hadithContentVersion;
  final List<DailyAyahRecord> ayahs;
  final List<DailyHadithRecord> hadiths;
  final List<String> ayahOrderIds;
  final List<String> hadithOrderIds;
  final String sequenceStartDate;
  final int skippedCount;
  final List<String> warnings;

  const DailyContentLoadResult({
    required this.ayahSchemaVersion,
    required this.hadithSchemaVersion,
    required this.ayahContentVersion,
    required this.hadithContentVersion,
    required this.ayahs,
    required this.hadiths,
    required this.ayahOrderIds,
    required this.hadithOrderIds,
    required this.sequenceStartDate,
    required this.skippedCount,
    required this.warnings,
  });
}
