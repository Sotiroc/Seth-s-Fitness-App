import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_bootstrap.dart';
import '../../../data/models/weight_entry.dart';
import '../../../data/repositories/weight_entry_repository.dart';
import 'progression_range.dart';

part 'weight_entries_provider.g.dart';

/// Streams every body-weight entry in the database, ordered by
/// `measuredAt` ascending. Powers the Progression body-weight chart.
@Riverpod(keepAlive: true)
Stream<List<WeightEntry>> weightEntries(Ref ref) async* {
  await ref.watch(databaseBootstrapProvider.future);
  yield* ref.watch(weightEntryRepositoryProvider).watchAll();
}

/// Body-weight entries scoped to the currently-selected
/// [BodyWeightRangeFilter]. Re-emits when the user changes range OR when
/// new entries are inserted/deleted.
@Riverpod(keepAlive: true)
AsyncValue<List<WeightEntry>> filteredWeightEntries(Ref ref) {
  final AsyncValue<List<WeightEntry>> all = ref.watch(weightEntriesProvider);
  final ProgressionRange range = ref.watch(bodyWeightRangeFilterProvider);
  return all.whenData((List<WeightEntry> entries) {
    final DateTime? cutoff = range.cutoffFrom(DateTime.now().toUtc());
    if (cutoff == null) return entries;
    return entries
        .where((WeightEntry e) => !e.measuredAt.isBefore(cutoff))
        .toList(growable: false);
  });
}

/// The single most recent weight entry, or null when the log is empty.
/// Derived from [weightEntriesProvider] so it stays live as the user logs
/// new measurements (or any time the chart's data changes).
///
/// Used by the Profile screen's weight card so its current value and
/// "Logged today / N days ago" caption track the same source of truth as
/// the Progression chart.
@Riverpod(keepAlive: true)
AsyncValue<WeightEntry?> latestWeightEntry(Ref ref) {
  return ref
      .watch(weightEntriesProvider)
      .whenData(
        (List<WeightEntry> entries) => entries.isEmpty ? null : entries.last,
      );
}

/// Weight delta over a fixed look-back window for the Profile weight card.
/// Compares the latest entry to the entry closest to (now - window) inside
/// the window. `hasComparison` is false until at least two entries exist
/// inside the window (or when the log is empty).
class WeightTrend {
  const WeightTrend({
    this.deltaKg,
    this.referenceEntry,
    this.hasComparison = false,
  });

  /// Signed difference: latest.weightKg - reference.weightKg.
  /// Positive = the user gained since the reference; negative = lost.
  final double? deltaKg;

  /// The entry the delta is measured against — the oldest entry inside
  /// `window` that's still ≤ `now - window` away from latest.
  final WeightEntry? referenceEntry;

  /// True when both `deltaKg` and `referenceEntry` are populated.
  final bool hasComparison;

  static const WeightTrend empty = WeightTrend();
}

/// 30-day weight trend used by the Profile weight card's chip. The window is
/// hardcoded for now; if Profile and Progression ever need different windows
/// this can become a parameterised family provider.
@Riverpod(keepAlive: true)
WeightTrend weightTrend(Ref ref) {
  const Duration window = Duration(days: 30);
  final AsyncValue<List<WeightEntry>> async = ref.watch(weightEntriesProvider);
  final List<WeightEntry>? entries = async.asData?.value;
  if (entries == null || entries.length < 2) return WeightTrend.empty;

  final WeightEntry latest = entries.last;
  final DateTime windowStart = latest.measuredAt.subtract(window);

  // Earliest entry that's still inside the look-back window. Falls back to
  // the oldest available entry when none exists exactly at the window start
  // — gives the chip something useful to show as soon as there are two
  // points in the log, not just after a full 30 days have passed.
  WeightEntry? reference;
  for (final WeightEntry entry in entries) {
    if (entry.id == latest.id) break;
    if (!entry.measuredAt.isBefore(windowStart)) {
      reference = entry;
      break;
    }
  }
  reference ??= entries.first;
  if (reference.id == latest.id) return WeightTrend.empty;

  return WeightTrend(
    deltaKg: latest.weightKg - reference.weightKg,
    referenceEntry: reference,
    hasComparison: true,
  );
}
