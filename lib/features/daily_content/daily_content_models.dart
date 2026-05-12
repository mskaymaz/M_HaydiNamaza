class DailyContentApproval {
  final String approvedBy;
  final String approvedAt;
  final String reviewNote;

  const DailyContentApproval({
    required this.approvedBy,
    required this.approvedAt,
    required this.reviewNote,
  });
}

class DailyAyahRecord {
  final String id;
  final String type;
  final String surahName;
  final int surahNumber;
  final int ayahNumber;
  final String text;
  final String translation;
  final String mealSource;
  final String sourceNote;
  final List<String> topics;
  final String status;
  final DailyContentApproval approval;

  const DailyAyahRecord({
    required this.id,
    required this.type,
    required this.surahName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
    required this.translation,
    required this.mealSource,
    required this.sourceNote,
    required this.topics,
    required this.status,
    required this.approval,
  });
}

class DailyHadithRecord {
  final String id;
  final String type;
  final String collection;
  final String book;
  final String hadithNumber;
  final String narrator;
  final String text;
  final String translation;
  final String grade;
  final String sourceNote;
  final List<String> topics;
  final String status;
  final DailyContentApproval approval;

  const DailyHadithRecord({
    required this.id,
    required this.type,
    required this.collection,
    required this.book,
    required this.hadithNumber,
    required this.narrator,
    required this.text,
    required this.translation,
    required this.grade,
    required this.sourceNote,
    required this.topics,
    required this.status,
    required this.approval,
  });
}

