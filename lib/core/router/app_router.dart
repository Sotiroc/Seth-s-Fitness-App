import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/exercises/presentation/exercise_form_screen.dart';
import '../../features/exercises/presentation/exercise_list_screen.dart';
import '../../features/history/presentation/history_placeholder_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/home/presentation/phase2_debug_screen.dart';
import '../../features/workouts/presentation/active_workout_screen.dart';
import '../../features/workouts/presentation/workout_summary_screen.dart';

part 'app_router.g.dart';

enum AppTab {
  workouts(
    label: 'Workouts',
    icon: Icons.fitness_center_outlined,
    selectedIcon: Icons.fitness_center,
    path: '/workouts',
  ),
  history(
    label: 'History',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights,
    path: '/history',
  ),
  exercises(
    label: 'Exercises',
    icon: Icons.list_alt_outlined,
    selectedIcon: Icons.list_alt,
    path: '/exercises',
  );

  const AppTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppTab.workouts.path,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppTab.workouts.path,
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: ActiveWorkoutScreen()),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'debug',
                    builder: (context, state) => const Phase2DebugScreen(),
                  ),
                  GoRoute(
                    path: 'active',
                    builder: (context, state) => const ActiveWorkoutScreen(),
                  ),
                  GoRoute(
                    path: 'summary/:id',
                    builder: (context, state) => WorkoutSummaryScreen(
                      workoutId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppTab.history.path,
                pageBuilder: (context, state) => const NoTransitionPage<void>(
                  child: HistoryPlaceholderScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppTab.exercises.path,
                pageBuilder: (context, state) =>
                    const NoTransitionPage<void>(child: ExerciseListScreen()),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const ExerciseFormScreen(),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) => ExerciseFormScreen(
                      exerciseId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
