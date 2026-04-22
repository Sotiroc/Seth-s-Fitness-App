import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitnessapp/app.dart';
import 'package:fitnessapp/data/db/app_database.dart';
import 'package:fitnessapp/data/db/database_providers.dart';

void main() {
  testWidgets('loads the active workout empty state', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase.forTesting(
      NativeDatabase.memory(),
    );
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((ref) => database)],
        child: const FitnessApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No active workout'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);
  });
}
