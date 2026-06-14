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
  final int? ayahEndNumber;
  final String textAr;
  final String textTr;
  final String textEn;
  final String sourceAr;
  final String sourceTr;
  final String sourceEn;
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
    this.ayahEndNumber,
    required this.textAr,
    required this.textTr,
    required this.textEn,
    required this.sourceAr,
    required this.sourceTr,
    required this.sourceEn,
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
  final String textAr;
  final String textTr;
  final String textEn;
  final String sourceAr;
  final String sourceTr;
  final String sourceEn;
  final String bookReferenceTr;
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
    required this.textAr,
    required this.textTr,
    required this.textEn,
    required this.sourceAr,
    required this.sourceTr,
    required this.sourceEn,
    this.bookReferenceTr = '',
    required this.grade,
    required this.sourceNote,
    required this.topics,
    required this.status,
    required this.approval,
  });
}

class DailyEsmaRecord {
  final String id;
  final String type;
  final String kind;
  final String category;
  final int sourceId;
  final int displayOrder;
  final String ref;
  final String nameArabic;
  final String nameTurkish;
  final String nameTransliteration;
  final String textAr;
  final String textTr;
  final String textEn;
  final String meaningAr;
  final String meaningTr;
  final String meaningEn;
  final String sourceNote;
  final List<String> topics;
  final String status;
  final DailyContentApproval approval;

  const DailyEsmaRecord({
    required this.id,
    required this.type,
    required this.kind,
    required this.category,
    required this.sourceId,
    required this.displayOrder,
    required this.ref,
    required this.nameArabic,
    required this.nameTurkish,
    required this.nameTransliteration,
    required this.textAr,
    required this.textTr,
    required this.textEn,
    required this.meaningAr,
    required this.meaningTr,
    required this.meaningEn,
    required this.sourceNote,
    required this.topics,
    required this.status,
    required this.approval,
  });
}
