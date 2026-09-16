import 'package:flutter_test/flutter_test.dart';
import 'package:menifest_app/my_app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('MANIFEST'), findsOneWidget);
  });
}

