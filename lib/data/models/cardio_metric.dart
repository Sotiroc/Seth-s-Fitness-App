/// One configurable input for a cardio exercise. Each cardio exercise
/// stores a list of these in `Exercise.trackedMetrics`; the set row
/// renders an input field per metric in the order listed here.
///
/// Weighted and bodyweight exercises do NOT carry tracked metrics —
/// their inputs are fixed (weight+reps / reps) by `ExerciseType`.
enum CardioMetric {
  /// Decimal kilometres. Treadmill, running, cycling, rowing.
  distance,

  /// mm:ss duration. The most common cardio metric — applies to almost
  /// every cardio activity.
  duration,

  /// Integer count of pool laps. Swimming.
  laps,

  /// Integer count of floors / flights. Stair Master.
  floors,

  /// Integer calorie count, manually entered after the session. Optional
  /// add-on for any cardio exercise.
  calories;

  /// Short user-facing label shown in the metrics checklist on the
  /// exercise editor.
  String get label {
    switch (this) {
      case CardioMetric.distance:
        return 'Distance';
      case CardioMetric.duration:
        return 'Duration';
      case CardioMetric.laps:
        return 'Laps';
      case CardioMetric.floors:
        return 'Floors';
      case CardioMetric.calories:
        return 'Calories';
    }
  }

  /// Hint text rendered inside the empty input field for this metric.
  String get inputHint {
    switch (this) {
      case CardioMetric.distance:
        return 'km';
      case CardioMetric.duration:
        return 'mm:ss';
      case CardioMetric.laps:
        return 'laps';
      case CardioMetric.floors:
        return 'floors';
      case CardioMetric.calories:
        return 'cal';
    }
  }

  /// One-character suffix used in compact summaries (history rows,
  /// previous-set column). Picks the short form ("km", "min", "lap")
  /// versus the wordier label.
  String get summarySuffix {
    switch (this) {
      case CardioMetric.distance:
        return 'km';
      case CardioMetric.duration:
        return '';
      case CardioMetric.laps:
        return ' laps';
      case CardioMetric.floors:
        return ' floors';
      case CardioMetric.calories:
        return ' cal';
    }
  }
}

/// Encode/decode helpers for the comma-separated metric list stored on
/// `Exercises.tracked_metrics`. Null/empty column means "use the cardio
/// default" — distance + duration — which preserves the legacy behaviour
/// for pre-feature rows.
extension CardioMetricListCodec on List<CardioMetric> {
  String encode() => map((CardioMetric m) => m.name).join(',');
}

List<CardioMetric>? decodeCardioMetrics(String? raw) {
  if (raw == null) return null;
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final List<CardioMetric> out = <CardioMetric>[];
  for (final String token in trimmed.split(',')) {
    final String name = token.trim();
    if (name.isEmpty) continue;
    for (final CardioMetric m in CardioMetric.values) {
      if (m.name == name) {
        out.add(m);
        break;
      }
    }
  }
  return out.isEmpty ? null : out;
}

/// Default metric list for cardio exercises whose `trackedMetrics` is
/// null. Matches the historical behaviour where every cardio exercise
/// always took distance + duration.
const List<CardioMetric> defaultCardioMetrics = <CardioMetric>[
  CardioMetric.distance,
  CardioMetric.duration,
];
