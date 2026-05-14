import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mhaydinamaza/features/daily_content/daily_content_models.dart';
import 'package:mhaydinamaza/features/daily_content/daily_content_selection_models.dart';
import 'package:mhaydinamaza/presentation/home/widgets/home_daily_content_panel.dart';

void main() {
  testWidgets('HomeDailyContentPanel renders loading state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        home: Scaffold(
          body: HomeDailyContentPanel(
            result: null,
            isLoading: true,
            hasError: false,
            cizgiColor: Colors.white,
            panelColor: Colors.black,
          ),
        ),
      ),
    );

    expect(find.byType(HomeDailyContentPanel), findsOneWidget);
    expect(find.text('TR'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
  });

  testWidgets('HomeDailyContentPanel renders ayah and hadith content', (
    WidgetTester tester,
  ) async {
    const approval = DailyContentApproval(
      approvedBy: 'editor',
      approvedAt: '2026-05-13T09:00:00Z',
      reviewNote: 'ok',
    );
    const state = DailyContentSelectionState(
      schemaVersion: '1.0.0',
      dayKey: '2026-05-13',
      contentVersion: 'test',
      ayahId: 'a1',
      hadithId: 'h1',
      recentAyahIds: <String>[],
      recentHadithIds: <String>[],
      seenAyahIds: <String>[],
      seenHadithIds: <String>[],
      ayahCycleId: 0,
      hadithCycleId: 0,
      updatedAt: '2026-05-13T09:00:00Z',
    );
    const result = DailyContentSelectionResult(
      ayah: DailyAyahRecord(
        id: 'a1',
        type: 'ayah',
        surahName: 'Fatiha',
        surahNumber: 1,
        ayahNumber: 1,
        textAr: 'Bismillah',
        textTr: 'Rahman ve Rahim',
        textEn: 'In the name of Allah',
        sourceAr: 'test',
        sourceTr: 'test',
        sourceEn: 'test',
        mealSource: 'test',
        sourceNote: 'test',
        topics: <String>['baslangic'],
        status: 'approved',
        approval: approval,
      ),
      hadith: DailyHadithRecord(
        id: 'h1',
        type: 'hadith',
        collection: 'Buhari',
        book: 'Iman',
        hadithNumber: '1',
        narrator: 'Omer',
        textAr: 'Ameller niyetlere goredir',
        textTr: 'Ameller niyetlere gore deger kazanir',
        textEn: 'Actions are by intentions',
        sourceAr: 'test',
        sourceTr: 'test',
        sourceEn: 'test',
        grade: 'sahih',
        sourceNote: 'test',
        topics: <String>['niyet'],
        status: 'approved',
        approval: approval,
      ),
      state: state,
      warnings: <String>[],
      skippedCount: 0,
    );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        home: Scaffold(
          body: HomeDailyContentPanel(
            result: result,
            isLoading: false,
            hasError: false,
            cizgiColor: Colors.white,
            panelColor: Colors.black,
          ),
        ),
      ),
    );

    expect(find.text('Rahman ve Rahim'), findsOneWidget);
    expect(find.text('Fatiha 1'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Ameller niyetlere gore deger kazanir'), findsOneWidget);
    expect(find.text('Buhari 1'), findsOneWidget);
  });
}
