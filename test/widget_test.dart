import 'package:flutter_test/flutter_test.dart';
import 'package:mhaydinamaza/app/app.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('MHaydiNamaza'), findsOneWidget);
  });
}
