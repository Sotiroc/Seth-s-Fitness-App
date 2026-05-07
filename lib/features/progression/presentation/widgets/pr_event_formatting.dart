import '../../../../core/utils/duration_formatter.dart';
import '../../../../core/utils/unit_conversions.dart';
import '../../../../data/models/pr_event.dart';
import '../../../../data/models/unit_system.dart';

/// Display helpers for [PrEvent] — the row label, the formatted value
/// string, and the short type pill caption. Centralised so the summary
/// screen, history flat-list mode, exercise history sheet, and home
/// PR feed card render the same PR identically.
abstract final class PrEventFormatting {
  /// Short caption shown next to the trophy ("Best set", "5RM",
  /// "Longest distance", etc.). Appears as a quiet pill / secondary
  /// line above or beside the value.
  static String typeLabel(PrEvent e) {
    switch (e.type) {
      case PrType.bestSet:
        return 'Best set';
      case PrType.e1rm:
        return 'Est. 1RM';
      case PrType.repMax:
        final int? rc = e.repCountForRepMax;
        return rc == null ? 'Rep max' : '${rc}RM';
      case PrType.mostRepsInSet:
        return 'Most reps';
      case PrType.mostRepsInWorkout:
        return 'Workout reps';
      case PrType.longestDistance:
        return 'Longest distance';
      case PrType.longestDuration:
        return 'Longest duration';
      case PrType.mostLaps:
        return 'Most laps';
      case PrType.mostFloors:
        return 'Most floors';
      case PrType.mostCalories:
        return 'Most calories';
    }
  }

  /// The big number for this PR — "102.5 kg × 5", "5.2 km", "12:34",
  /// "32 reps". Formatted in the user's preferred unit system.
  static String value(PrEvent e, UnitSystem system) {
    switch (e.type) {
      case PrType.bestSet:
      case PrType.repMax:
        final String w =
            UnitConversions.formatWeight(e.weightKg, system) ?? '';
        final int reps = e.reps ?? 0;
        return '$w × $reps';
      case PrType.e1rm:
        return UnitConversions.formatWeight(e.oneRepMaxKg, system) ?? '';
      case PrType.mostRepsInSet:
        return '${e.reps ?? 0} reps';
      case PrType.mostRepsInWorkout:
        return '${e.reps ?? 0} reps';
      case PrType.longestDistance:
        return UnitConversions.formatDistance(e.distanceKm, system) ?? '';
      case PrType.longestDuration:
        return DurationFormatter.formatSeconds(e.durationSeconds ?? 0);
      case PrType.mostLaps:
        return '${e.laps ?? 0} laps';
      case PrType.mostFloors:
        return '${e.floors ?? 0} floors';
      case PrType.mostCalories:
        return '${e.calories ?? 0} cal';
    }
  }

  /// Optional secondary line under the value. For e1RM, shows the
  /// source set ("from 100 kg × 5"). For session-volume reps, returns
  /// null (the value is already self-contained). Some types include
  /// the source set context; others stand alone.
  static String? secondary(PrEvent e, UnitSystem system) {
    switch (e.type) {
      case PrType.e1rm:
        final String? w =
            UnitConversions.formatWeight(e.weightKg, system);
        final int reps = e.reps ?? 0;
        if (w == null || reps == 0) return null;
        return 'from $w × $reps';
      case PrType.bestSet:
      case PrType.repMax:
      case PrType.mostRepsInSet:
      case PrType.mostRepsInWorkout:
      case PrType.longestDistance:
      case PrType.longestDuration:
      case PrType.mostLaps:
      case PrType.mostFloors:
      case PrType.mostCalories:
        return null;
    }
  }

  /// "today", "yesterday", "3d ago", "Mar 14". Shared with the older
  /// PR row layout for consistency.
  static String relativeDate(DateTime achievedAt) {
    final DateTime now = DateTime.now();
    final DateTime localAchieved = achievedAt.toLocal();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime achievedDay = DateTime(
      localAchieved.year,
      localAchieved.month,
      localAchieved.day,
    );
    final int daysAgo = today.difference(achievedDay).inDays;
    if (daysAgo == 0) return 'today';
    if (daysAgo == 1) return 'yesterday';
    if (daysAgo < 7) return '${daysAgo}d ago';
    final String mm = _monthShort(localAchieved.month);
    return '$mm ${localAchieved.day}';
  }

  static String _monthShort(int month) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
