import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../application/rest_timer_controller.dart';
import 'rest_time_picker_sheet.dart';

/// Non-modal bottom-sheet overlay shown while a rest timer is running.
/// Mounted in a `Stack` over the active workout content so the user can
/// continue editing other sets while resting. Returns `SizedBox.shrink()`
/// when the controller is inactive.
class RestTimerSheet extends ConsumerWidget {
  const RestTimerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RestTimerState state = ref.watch(restTimerControllerProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: state.isActive
          ? _RestTimerSheetBody(key: const ValueKey<String>('rest-timer-sheet'))
          : const SizedBox.shrink(key: ValueKey<String>('rest-timer-empty')),
    );
  }
}

class _RestTimerSheetBody extends ConsumerStatefulWidget {
  const _RestTimerSheetBody({super.key});

  @override
  ConsumerState<_RestTimerSheetBody> createState() =>
      _RestTimerSheetBodyState();
}

class _RestTimerSheetBodyState extends ConsumerState<_RestTimerSheetBody>
    with WidgetsBindingObserver {
  Timer? _ticker;
  bool _dismissScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncTicker(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker(TickerMode.of(context));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Backgrounded tabs may have throttled the controller's internal
      // ticker; nudge it so resume-past-zero still fires the haptic.
      ref.read(restTimerControllerProvider.notifier).onMaybeZero();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker(bool enabled) {
    if (!enabled) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      // Computed from the wall clock each tick — survives tab sleeps.
      ref.read(restTimerControllerProvider.notifier).onMaybeZero();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final RestTimerState state = ref.watch(restTimerControllerProvider);
    if (!state.isActive) return const SizedBox.shrink();

    final JellyBeanPalette palette = context.jellyBeanPalette;
    final DateTime now = DateTime.now().toUtc();
    final Duration remaining = state.targetEndUtc!.difference(now);
    final int remainingSeconds = remaining.inSeconds < 0
        ? 0
        : remaining.inSeconds;
    final double progress = state.totalSeconds == 0
        ? 1.0
        : (1 - remainingSeconds / state.totalSeconds).clamp(0.0, 1.0);

    if (state.didFireZero && !_dismissScheduled) {
      _dismissScheduled = true;
      Future<void>.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        ref.read(restTimerControllerProvider.notifier).clear();
      });
    }
    if (!state.didFireZero && _dismissScheduled) {
      _dismissScheduled = false;
    }

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onLongPress: () => _openEditor(state),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              0,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: palette.shade200.withValues(alpha: 0.6),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: palette.shade950.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  _DragHandle(
                    palette: palette,
                    onTap: () => ref
                        .read(restTimerControllerProvider.notifier)
                        .clear(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    (state.exerciseName ?? 'Rest').toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (state.didFireZero)
                    _DonePill(palette: palette)
                  else
                    Text(
                      DurationFormatter.formatSeconds(remainingSeconds),
                      style: TextStyle(
                        color: palette.shade950,
                        fontSize: 56,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: progress,
                      backgroundColor: palette.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(
                          palette.shade500,
                          const Color(0xFFE05A4A),
                          progress,
                        )!,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (!state.didFireZero)
                    _ButtonRow(palette: palette, ref: ref),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Hold to edit this exercise',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.shade700.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor(RestTimerState state) async {
    final String? exerciseId = state.exerciseId;
    final String? exerciseName = state.exerciseName;
    if (exerciseId == null || exerciseName == null) return;
    await showRestTimePickerSheet(
      context: context,
      ref: ref,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      initialSeconds: state.totalSeconds,
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.palette, required this.onTap});

  final JellyBeanPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: palette.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _DonePill extends StatelessWidget {
  const _DonePill({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: palette.shade500,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'DONE!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _ButtonRow extends StatelessWidget {
  const _ButtonRow({required this.palette, required this.ref});

  final JellyBeanPalette palette;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _AdjustButton(
            palette: palette,
            label: '-15s',
            onPressed: () =>
                ref.read(restTimerControllerProvider.notifier).extend(-15),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          flex: 2,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.shade900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () =>
                ref.read(restTimerControllerProvider.notifier).clear(),
            child: const Text(
              'Skip',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _AdjustButton(
            palette: palette,
            label: '+15s',
            onPressed: () =>
                ref.read(restTimerControllerProvider.notifier).extend(15),
          ),
        ),
      ],
    );
  }
}

class _AdjustButton extends StatelessWidget {
  const _AdjustButton({
    required this.palette,
    required this.label,
    required this.onPressed,
  });

  final JellyBeanPalette palette;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.shade900,
        side: BorderSide(color: palette.shade300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}
