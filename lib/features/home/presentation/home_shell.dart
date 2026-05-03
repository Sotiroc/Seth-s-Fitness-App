import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../workouts/application/workout_recovery_controller.dart';
import '../../workouts/presentation/workout_recovery_dialog.dart';
import '../application/home_scaffold_key_provider.dart';
import 'widgets/app_drawer.dart';
import 'widgets/indicator_line_nav_bar.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    // Subsequent transitions (e.g. resume → cold-start check fires while
    // the user is already in-app) are caught here.
    ref.listenManual<bool>(
      workoutRecoveryControllerProvider.select(
        (s) => s.recoveredWorkout != null,
      ),
      (prev, next) {
        if (next && !(prev ?? false)) {
          _maybeShowRecoveryDialog();
        }
      },
    );
    // The cold-start check often resolves before HomeShell mounts, so the
    // listener above misses the initial transition. Run a one-shot post-
    // frame check to catch that case.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowRecoveryDialog();
    });
  }

  Future<void> _maybeShowRecoveryDialog() async {
    if (!mounted || _dialogShowing) return;
    final bool hasRecovered = ref.read(
      workoutRecoveryControllerProvider.select(
        (s) => s.recoveredWorkout != null,
      ),
    );
    if (!hasRecovered) return;
    _dialogShowing = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const WorkoutRecoveryDialog(),
      );
    } finally {
      _dialogShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ref.watch(homeScaffoldKeyProvider),
      drawer: const AppDrawer(),
      body: widget.navigationShell,
      bottomNavigationBar: IndicatorLineNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTabSelected: _goBranch,
      ),
    );
  }

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
