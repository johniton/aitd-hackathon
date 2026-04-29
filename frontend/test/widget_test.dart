import 'package:flutter_test/flutter_test.dart';
import 'package:aitd_hackathon/main.dart';

void main() {
  testWidgets('Smoke test: app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const GoaGreenApp());
    expect(find.byType(GoaGreenApp), findsOneWidget);
  });
}
