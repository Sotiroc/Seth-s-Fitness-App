/// Formatting helpers for workout durations.
abstract final class DurationFormatter {
  /// Formats a duration as `hh:mm:ss` once it reaches an hour, otherwise `mm:ss`.
  /// Always zero-padded.
  static String elapsed(Duration duration) {
    final int totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    String two(int v) => v.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    }
    return '${two(minutes)}:${two(seconds)}';
  }

  /// Parses a user-entered cardio time into whole seconds.
  /// Accepts `mm:ss`, `hh:mm:ss`, or a plain minutes number. Returns null on parse failure or zero.
  static int? parseSeconds(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.contains(':')) {
      final List<String> parts = trimmed.split(':');
      if (parts.length > 3) return null;
      final List<int> nums = <int>[];
      for (final String p in parts) {
        final int? n = int.tryParse(p);
        if (n == null || n < 0) return null;
        nums.add(n);
      }
      int total = 0;
      if (nums.length == 3) {
        total = nums[0] * 3600 + nums[1] * 60 + nums[2];
      } else if (nums.length == 2) {
        total = nums[0] * 60 + nums[1];
      } else {
        total = nums[0];
      }
      return total <= 0 ? null : total;
    }

    final num? minutes = num.tryParse(trimmed);
    if (minutes == null || minutes <= 0) return null;
    return (minutes * 60).round();
  }

  /// Formats seconds as `mm:ss` or `hh:mm:ss` for display.
  static String formatSeconds(int seconds) {
    return elapsed(Duration(seconds: seconds));
  }
}
