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
  final String? esmaSchemaVersion;
  final String? ayahContentVersion;
  final String? hadithContentVersion;
  final String? esmaContentVersion;
  final List<DailyAyahRecord> ayahs;
  final List<DailyHadithRecord> hadiths;
  final List<DailyEsmaRecord> esmas;
  final List<DailyEsmaRecord> sifats;
  final List<String> ayahOrderIds;
  final List<String> hadithOrderIds;
  final List<String> esmaOrderIds;
  final List<String> sifatOrderIds;
  final String sequenceStartDate;
  final int skippedCount;
  final List<String> warnings;

  const DailyContentLoadResult({
    required this.ayahSchemaVersion,
    required this.hadithSchemaVersion,
    this.esmaSchemaVersion,
    required this.ayahContentVersion,
    required this.hadithContentVersion,
    this.esmaContentVersion,
    required this.ayahs,
    required this.hadiths,
    this.esmas = const <DailyEsmaRecord>[],
    this.sifats = const <DailyEsmaRecord>[],
    required this.ayahOrderIds,
    required this.hadithOrderIds,
    this.esmaOrderIds = const <String>[],
    this.sifatOrderIds = const <String>[],
    required this.sequenceStartDate,
    required this.skippedCount,
    required this.warnings,
  });
}
