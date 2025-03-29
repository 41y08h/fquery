// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:basic/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // TODO: Mock the request for the API call under the query key `['posts']` (see [home.dart])
  testWidgets('Todos page is rendered', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Navigate to the Todos page
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle(); // Wait for the navigation to complete

    expect(find.text('Todos'), findsOneWidget);
  });
}
