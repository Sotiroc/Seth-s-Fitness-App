import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_filter.g.dart';

/// Date-range presets for the History "Date" chip.
///
/// `custom` is special-cased: it carries an arbitrary
/// (`customStart`, `customEnd`) range stored separately on
/// [HistoryFilter] rather than encoded into the enum value itself.
enum HistoryDateRangePreset {
  thisWeek(label: 'This week'),
  thisMonth(label: 'This month'),
  last3Months(label: 'Last 3 months'),
  thisYear(label: 'This year'),
  allTime(label: 'All time'),
  custom(label: 'Custom range');

  const HistoryDateRangePreset({required this.label});

  final String label;
}

/// Resolved [start, end) instant pair for a date-range filter, in local
/// time. `null` means "no upper or lower bound."
@immutable
class HistoryDateBounds {
  const HistoryDateBounds({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  bool contains(DateTime instant) {
    final DateTime local = instant.toLocal();
    if (start != null && local.isBefore(start!)) return false;
    if (end != null && !local.isBefore(end!)) return false;
    return true;
  }
}

/// Immutable snapshot of the current History search/filter state.
///
/// Held by [HistoryFilterController] (kept alive across navigation) and
/// reduced into the visible workout list by `filteredHistory`.
/// Equality is value-based so the controller only emits when something
/// actually changes — avoids spurious rebuilds of the list on irrelevant
/// keystrokes.
@immutable
class HistoryFilter {
  const HistoryFilter({
    this.query = '',
    this.exerciseIds = const <String>{},
    this.datePreset = HistoryDateRangePreset.allTime,
    this.customStart,
    this.customEnd,
    this.prsOnly = false,
    this.hasNotes = false,
  });

  /// Free-text search. Matched against workout names and exercise names
  /// (case-insensitive substring). Numbers like weights/reps are never
  /// matched — the search box is intentionally text-only.
  final String query;

  /// Set of exercise ids the user picked from the multi-select sheet.
  /// Multiple selections OR together: a workout matches if it contains
  /// any of these exercises. Empty set means "no exercise filter."
  final Set<String> exerciseIds;

  final HistoryDateRangePreset datePreset;

  /// Lower bound for [HistoryDateRangePreset.custom]. Inclusive, local
  /// midnight on the chosen day. Null when not in custom mode.
  final DateTime? customStart;

  /// Upper bound for [HistoryDateRangePreset.custom]. Exclusive — set to
  /// the local midnight of the day *after* the user's chosen end date so
  /// the picked end day itself is included. Null when not in custom mode.
  final DateTime? customEnd;

  final bool prsOnly;

  /// True when only workouts that have at least one non-empty note (at
  /// the workout, exercise, or set level) should be shown.
  final bool hasNotes;

  /// True when at least one filter (search text included) is active. Drives
  /// the "X filters active · Clear all" strip and the empty-state message.
  bool get hasAnyFilter =>
      query.trim().isNotEmpty ||
      exerciseIds.isNotEmpty ||
      datePreset != HistoryDateRangePreset.allTime ||
      prsOnly ||
      hasNotes;

  /// Count of *chips* that are active (search box is excluded — it's its
  /// own surface). Used to label the "N filters active" strip.
  int get activeChipCount {
    int count = 0;
    if (exerciseIds.isNotEmpty) count++;
    if (datePreset != HistoryDateRangePreset.allTime) count++;
    if (prsOnly) count++;
    if (hasNotes) count++;
    return count;
  }

  /// Resolves the date filter into an absolute, local-time bounds pair
  /// using [now] as the anchor for "this week"/"this month"/etc.
  HistoryDateBounds dateBounds(DateTime now) {
    final DateTime localNow = now.toLocal();
    final DateTime startOfToday = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
    );
    switch (datePreset) {
      case HistoryDateRangePreset.thisWeek:
        // Week starts Monday; matches the rest of the app (heatmap,
        // weekly volume strip).
        final DateTime monday = startOfToday.subtract(
          Duration(days: localNow.weekday - 1),
        );
        return HistoryDateBounds(
          start: monday,
          end: monday.add(const Duration(days: 7)),
        );
      case HistoryDateRangePreset.thisMonth:
        final DateTime first = DateTime(localNow.year, localNow.month, 1);
        final DateTime nextMonth = DateTime(
          localNow.year,
          localNow.month + 1,
          1,
        );
        return HistoryDateBounds(start: first, end: nextMonth);
      case HistoryDateRangePreset.last3Months:
        // Rolling 3-month window ending tomorrow at midnight (so today is
        // included). Anchored to start-of-day so the boundary is stable
        // across the day.
        final DateTime threeMonthsAgo = DateTime(
          localNow.year,
          localNow.month - 3,
          localNow.day,
        );
        return HistoryDateBounds(
          start: threeMonthsAgo,
          end: startOfToday.add(const Duration(days: 1)),
        );
      case HistoryDateRangePreset.thisYear:
        return HistoryDateBounds(
          start: DateTime(localNow.year, 1, 1),
          end: DateTime(localNow.year + 1, 1, 1),
        );
      case HistoryDateRangePreset.allTime:
        return const HistoryDateBounds();
      case HistoryDateRangePreset.custom:
        return HistoryDateBounds(start: customStart, end: customEnd);
    }
  }

  /// Short human-readable summary of the date chip's current state. Used
  /// as the chip label when active.
  String dateChipLabel() {
    if (datePreset == HistoryDateRangePreset.custom) {
      if (customStart == null || customEnd == null) {
        return HistoryDateRangePreset.custom.label;
      }
      return _formatCustomRange(customStart!, customEnd!);
    }
    return datePreset.label;
  }

  HistoryFilter copyWith({
    String? query,
    Set<String>? exerciseIds,
    HistoryDateRangePreset? datePreset,
    DateTime? customStart,
    DateTime? customEnd,
    bool? prsOnly,
    bool? hasNotes,
    bool clearCustomRange = false,
  }) {
    return HistoryFilter(
      query: query ?? this.query,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      datePreset: datePreset ?? this.datePreset,
      customStart: clearCustomRange ? null : customStart ?? this.customStart,
      customEnd: clearCustomRange ? null : customEnd ?? this.customEnd,
      prsOnly: prsOnly ?? this.prsOnly,
      hasNotes: hasNotes ?? this.hasNotes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryFilter &&
        other.query == query &&
        setEquals(other.exerciseIds, exerciseIds) &&
        other.datePreset == datePreset &&
        other.customStart == customStart &&
        other.customEnd == customEnd &&
        other.prsOnly == prsOnly &&
        other.hasNotes == hasNotes;
  }

  @override
  int get hashCode => Object.hash(
    query,
    Object.hashAllUnordered(exerciseIds),
    datePreset,
    customStart,
    customEnd,
    prsOnly,
    hasNotes,
  );
}

String _formatCustomRange(DateTime start, DateTime endExclusive) {
  // The end is stored exclusive (midnight after the picked day) so the
  // user-visible label uses end - 1 day.
  final DateTime endInclusive = endExclusive.subtract(const Duration(days: 1));
  if (start.year == endInclusive.year &&
      start.month == endInclusive.month &&
      start.day == endInclusive.day) {
    return _formatCompactDate(start);
  }
  return '${_formatCompactDate(start)} – ${_formatCompactDate(endInclusive)}';
}

String _formatCompactDate(DateTime d) {
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
  final DateTime now = DateTime.now();
  final String suffix = d.year == now.year ? '' : ' ${d.year}';
  return '${d.day} ${months[d.month - 1]}$suffix';
}

/// Holds the persistent History search/filter state. `keepAlive` so the
/// user's filters survive popping into a workout detail and back, per the
/// spec: "Search and filters persist across navigation. Reset only via
/// 'Clear all.'"
@Riverpod(keepAlive: true)
class HistoryFilterController extends _$HistoryFilterController {
  @override
  HistoryFilter build() => const HistoryFilter();

  void setQuery(String value) {
    if (value == state.query) return;
    state = state.copyWith(query: value);
  }

  void setExerciseIds(Set<String> ids) {
    state = state.copyWith(
      exerciseIds: Set<String>.unmodifiable(ids),
    );
  }

  void setDatePreset(HistoryDateRangePreset preset) {
    if (preset == HistoryDateRangePreset.custom) {
      state = state.copyWith(datePreset: preset);
      return;
    }
    state = state.copyWith(datePreset: preset, clearCustomRange: true);
  }

  /// Sets a custom range. [start] is inclusive (local midnight of the
  /// chosen first day); [endInclusive] is the picked last day — this
  /// stores it as exclusive midnight + 1 internally so containment checks
  /// stay half-open like every other range in the app.
  void setCustomRange({
    required DateTime start,
    required DateTime endInclusive,
  }) {
    final DateTime startMidnight = DateTime(start.year, start.month, start.day);
    final DateTime endExclusive = DateTime(
      endInclusive.year,
      endInclusive.month,
      endInclusive.day,
    ).add(const Duration(days: 1));
    state = state.copyWith(
      datePreset: HistoryDateRangePreset.custom,
      customStart: startMidnight,
      customEnd: endExclusive,
    );
  }

  void setPrsOnly(bool value) {
    state = state.copyWith(prsOnly: value);
  }

  void setHasNotes(bool value) {
    state = state.copyWith(hasNotes: value);
  }

  void clear() {
    state = const HistoryFilter();
  }
}
