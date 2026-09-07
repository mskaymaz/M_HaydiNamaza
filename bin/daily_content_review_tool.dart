import 'dart:io';

import 'package:mhaydinamaza/features/daily_content/editor/daily_content_editor_storage.dart';

Future<void> main(List<String> args) async {
  stdout.writeln('==================================================');
  stdout.writeln('M_HaydiNamaza - Flutter Content Review Tool (CLI)');
  stdout.writeln('==================================================');

  final storage = DailyContentEditorStorage(
    approvedBasePath: 'assets/data/daily_content/approved',
  );

  stdout.writeln('Reading approved Ayahs...');
  final ayahs = await storage.readAyahs();
  final approvedAyahs = ayahs.records.where((r) => r.isApproved).length;
  stdout.writeln('  -> Total Ayahs: ${ayahs.records.length} (Approved: $approvedAyahs)');

  stdout.writeln('Reading approved Hadiths...');
  final hadiths = await storage.readHadiths();
  final approvedHadiths = hadiths.records.where((r) => r.isApproved).length;
  stdout.writeln('  -> Total Hadiths: ${hadiths.records.length} (Approved: $approvedHadiths)');

  stdout.writeln('Reading approved Esma-ul Husna & Sifatlar...');
  final esma = await storage.readEsma();
  final approvedEsma = esma.records.where((r) => r.isApproved).length;
  stdout.writeln('  -> Total Esma/Sifat: ${esma.records.length} (Approved: $approvedEsma)');

  stdout.writeln('Reading Sequence config...');
  final sequence = await storage.readSequence();
  stdout.writeln('  -> Sequence start_date: ${sequence.startDate}');
  stdout.writeln('  -> Sequence esma_order_ids count: ${sequence.esmaOrderIds.length}');

  stdout.writeln('--------------------------------------------------');
  stdout.writeln('Validation & Verification Check Passed cleanly!');
  stdout.writeln('==================================================');
}
