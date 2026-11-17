// University Bus Tracking – Basic Smoke Test
// Verifies the root widget can be instantiated without errors.

import 'package:flutter_test/flutter_test.dart';
import 'package:bus_tracking/app.dart';

void main() {
  testWidgets('App smoke test – UniversityBusApp mounts', (WidgetTester tester) async {
    // Pump only the root widget without running navigation / async init
    await tester.pumpWidget(const UniversityBusApp());
    // If no exception is thrown the test passes
    expect(find.byType(UniversityBusApp), findsOneWidget);
  });
}
