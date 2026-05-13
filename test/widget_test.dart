import 'package:flutter_test/flutter_test.dart';
import 'package:mhaydinamaza/app/app.dart';
import 'package:mhaydinamaza/presentation/home/home_screen.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(App), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
