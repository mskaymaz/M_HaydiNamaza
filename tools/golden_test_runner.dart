import 'dart:convert';
import 'dart:io';

// Minimal runner to validate golden test data schema.
// TODO: Wire into PrayerEngine once calculation is implemented.

void main(List<String> args) {
  final dir = Directory('testdata/adhan');
  if (!dir.existsSync()) {
    stderr.writeln('Missing testdata/adhan');
    exit(1);
  }

  var files = dir.listSync().whereType<File>().toList();
  files.sort((a, b) => a.path.compareTo(b.path));

  var total = 0;
  for (final f in files) {
    final text = f.readAsStringSync();
    final data = json.decode(text);
    if (data is! List) {
      stderr.writeln('Invalid format: ${f.path}');
      exit(2);
    }
    for (final item in data) {
      if (item is! Map) {
        stderr.writeln('Invalid item: ${f.path}');
        exit(3);
      }
      // Basic required fields check.
      for (final key in ['date','times','method','madhab','high_latitude_rule']) {
        if (!item.containsKey(key)) {
          stderr.writeln('Missing $key in ${f.path}');
          exit(4);
        }
      }
      total++;
    }
  }

  stdout.writeln('Golden data OK. Records: $total');
}
