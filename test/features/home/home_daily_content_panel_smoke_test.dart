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
        home: Scaffold(
          body: HomeDailyContentPanel(
            result: null,
            isLoading: true,
            hasError: false,
            cizgiColor: Colors.white,
          ),
        ),
      ),
    );

    expect(find.text('Gunluk Ayet ve Hadis'), findsOneWidget);
    expect(find.text('Gunluk icerik yukleniyor...'), findsOneWidget);
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
        text: 'Bismillah',
        translation: 'Rahman ve Rahim',
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
        text: 'Ameller niyetlere goredir',
        translation: 'Ameller niyetlere gore deger kazanir',
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
        home: Scaffold(
          body: HomeDailyContentPanel(
            result: result,
            isLoading: false,
            hasError: false,
            cizgiColor: Colors.white,
          ),
        ),
      ),
    );

    expect(find.text('Ayet'), findsOneWidget);
    expect(find.text('Hadis'), findsOneWidget);
    expect(find.text('Bismillah'), findsOneWidget);
    expect(find.text('Ameller niyetlere goredir'), findsOneWidget);
  });
}
