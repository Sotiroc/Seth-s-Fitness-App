import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitnessapp/app.dart';

void main() {
  testWidgets('shows the placeholder shell tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitnessApp()));
    await tester.pumpAndSettle();

    expect(find.text('Workouts'), findsWidgets);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Exercises'), findsOneWidget);
    expect(
      find.text('Train with focus, then layer the logging flow on top.'),
      findsOneWidget,
    );
  });
}
