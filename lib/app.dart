import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_splash.dart';
import 'data/database_bootstrap.dart';
import 'features/workouts/application/active_workout_provider.dart';
import 'features/workouts/application/workout_recovery_controller.dart';

class FitnessApp extends ConsumerStatefulWidget {
  const FitnessApp({super.key});

  @override
  ConsumerState<FitnessApp> createState() => _FitnessAppState();
}

class _FitnessAppState extends ConsumerState<FitnessApp>
    with WidgetsBindingObserver {
  bool _coldStartCheckQueued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The active-workout stream is watched in build() and starts emitting
    // once the database has booted. Run the auto-close-stale-workout check
    // exactly once after that first emission so cold-start covers the
    // case where the app was killed mid-workout.
    ref.listenManual<AsyncValue<dynamic>>(activeWorkoutDetailProvider, (
      previous,
      next,
    ) {
      if (_coldStartCheckQueued) return;
      if (next.isLoading) return;
      _coldStartCheckQueued = true;
      _runStaleCheck();
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runStaleCheck();
    }
  }

  void _runStaleCheck() {
    // The controller is idempotent (inFlight + recoveredWorkout guards),
    // so it's safe to fire from both lifecycle and stream listeners.
    ref.read(workoutRecoveryControllerProvider.notifier).checkForStaleWorkout();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> bootstrap = ref.watch(databaseBootstrapProvider);
    // The default route renders ActiveWorkoutScreen, which itself watches
    // activeWorkoutDetailProvider and shows a spinner until it emits. Hold
    // the splash until that first emission lands too so the handoff is a
    // direct cut from animation → ready screen, with no spinner flash.
    final AsyncValue firstScreenData = ref.watch(activeWorkoutDetailProvider);

    final ThemeData lightTheme = AppTheme.light();
    final ThemeData darkTheme = AppTheme.dark();

    if (bootstrap.hasError) {
      return MaterialApp(
        title: 'Fitness App',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not start app: ${bootstrap.error}'),
            ),
          ),
        ),
      );
    }

    // Both bootstrap and the first screen's data must settle (success OR
    // error) before we tear down the splash. Errors fall through to the
    // router so the screen renders its own error UI.
    final bool stillWarmingUp =
        bootstrap.isLoading || firstScreenData.isLoading;
    if (stillWarmingUp) {
      return MaterialApp(
        title: 'Fitness App',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: const AppSplash(),
      );
    }

    return MaterialApp.router(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: ref.watch(appRouterProvider),
    );
    // The recovery dialog is opened via showDialog from inside the router
    // (see HomeShell), not as a Stack overlay here — overlay-rendered
    // dialogs lack a Navigator ancestor and break showDatePicker.
  }
}
