import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitnessapp/app.dart';
import 'package:fitnessapp/data/db/app_database.dart';
import 'package:fitnessapp/data/db/database_providers.dart';

void main() {
  testWidgets('loads the phase 2 debug route with seeded exercises', (
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

    expect(find.text('Workouts'), findsWidgets);

    await tester.tap(find.byIcon(Icons.developer_board_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Phase 2 Debug Data'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Seeded exercises'), findsOneWidget);
  });
}
