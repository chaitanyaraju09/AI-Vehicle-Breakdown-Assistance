import 'package:flutter_test/flutter_test.dart';

import 'package:mechanic_app/main.dart';

void main() {
  testWidgets('MechanicApp loads login screen smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MechanicApp());

    expect(find.text('Mechanic Portal'), findsOneWidget);
    expect(find.text('Sign In as Partner'), findsOneWidget);
  });
}
