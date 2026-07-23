import 'package:flutter_test/flutter_test.dart';
import 'package:threadcraft/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ThreadCraftApp());
    expect(find.byType(ThreadCraftApp), findsOneWidget);
  });
}