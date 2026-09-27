import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets(
    'Vehicle Assistance App loads',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const VehicleAssistanceApp(),
      );

      expect(
        find.text('Vehicle Assistance App'),
        findsOneWidget,
      );
    },
  );
}