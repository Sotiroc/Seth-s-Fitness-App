import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/utils/duration_formatter.dart';
import '../../../../core/utils/unit_conversions.dart';
import '../../../../data/models/unit_system.dart';
import '../../../../data/models/weekly_recap.dart';

/// Pure formatting + chart-painting helpers for the weekly recap surface.
/// Pulled out of the widget file so the card and the off-screen export
/// can share identical strings and visuals.
abstract final class WeeklyRecapVisuals {
  /// Formats a stored kilogram volume for the recap header — "9.2 t" in
  /// metric or "20,287 lb" in imperial. Tonnes kick in at 1000 kg so the
  /// header line stays compact.
  static String formatVolume(double kg, UnitSystem system) {
    switch (system) {
      case UnitSystem.metric:
        if (kg >= 1000) {
          final double tonnes = kg / 1000;
          return '${_oneDecimal(tonnes)} t';
        }
        return '${_oneDecimal(kg)} kg';
      case UnitSystem.imperial:
        final double lb = UnitConversions.kgToLb(kg);
        if (lb >= 2000) {
          // US ton (2000 lb).
          return '${_oneDecimal(lb / 2000)} t';
        }
        return '${_thousandSep(lb.round())} lb';
    }
  }

  /// Formats a duration in seconds as "3h 14m" / "47m" / "30s".
  static String formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0m';
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    if (hours == 0 && minutes == 0) return '${totalSeconds}s';
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// "Deadlift 142.5 kg × 3" / "Pull-up × 14" / "Run 5.0 km" — same
  /// surface used in the on-screen card and the shared image so the PNG
  /// matches the screenshot the user took.
  static String formatPr(WeeklyRecapPr pr, UnitSystem system) {
    final String name = pr.exerciseName;
    final String? weight = UnitConversions.formatWeight(pr.weightKg, system);
    final String? distance = UnitConversions.formatDistance(
      pr.distanceKm,
      system,
    );
    final String? duration = pr.durationSeconds == null
        ? null
        : DurationFormatter.formatSeconds(pr.durationSeconds!);
    if (weight != null && pr.reps != null) {
      return '$name  $weight × ${pr.reps}';
    }
    if (pr.reps != null) {
      return '$name  × ${pr.reps}';
    }
    if (distance != null && duration != null) {
      return '$name  $distance · $duration';
    }
    if (distance != null) return '$name  $distance';
    if (duration != null) return '$name  $duration';
    return name;
  }

  /// "↑ 12% volume" / "↓ 4% volume". Returns null when the previous
  /// value is missing or zero (no useful percentage to compute).
  static String? formatVolumeDelta({
    required double current,
    required double? previous,
  }) {
    if (previous == null || previous <= 0) return null;
    final double pct = ((current - previous) / previous) * 100;
    if (pct.abs() < 1) return '· volume flat';
    final String arrow = pct >= 0 ? '↑' : '↓';
    return '$arrow ${pct.abs().round()}% volume';
  }

  /// "↑ 1 workout" / "↓ 2 workouts". Returns null when there's nothing
  /// meaningful to say (no previous data, or the count was unchanged).
  static String? formatWorkoutDelta({
    required int current,
    required int? previous,
  }) {
    if (previous == null) return null;
    final int delta = current - previous;
    if (delta == 0) return null;
    final String arrow = delta > 0 ? '↑' : '↓';
    final int abs = delta.abs();
    return '$arrow $abs workout${abs == 1 ? '' : 's'}';
  }

  static String _oneDecimal(double value) {
    final String formatted = value.toStringAsFixed(1);
    if (formatted.endsWith('.0')) {
      return formatted.substring(0, formatted.length - 2);
    }
    return formatted;
  }

  static String _thousandSep(int value) {
    final String s = value.toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final int fromEnd = s.length - i;
      out.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) out.write(',');
    }
    return out.toString();
  }
}

/// Hand-rolled line chart so the recap card stays free of the (heavier)
/// fl_chart wrapper. Renders a smooth area + line + dot per day, with
/// Mon/Wed/Fri/Sun day labels along the baseline.
class WeeklyRecapDailyVolumePainter extends CustomPainter {
  WeeklyRecapDailyVolumePainter({
    required this.dailyVolumeKg,
    required this.lineColor,
    required this.fillColor,
    required this.dotColor,
    required this.gridColor,
    required this.labelColor,
    required this.labelSize,
  });

  final List<double> dailyVolumeKg;
  final Color lineColor;
  final Color fillColor;
  final Color dotColor;
  final Color gridColor;
  final Color labelColor;
  final double labelSize;

  static const List<String> _dayLabels = <String>[
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (dailyVolumeKg.isEmpty) return;
    const double labelGutter = 18;
    final double chartHeight = size.height - labelGutter;
    if (chartHeight <= 0) return;

    final double maxValue = dailyVolumeKg.fold<double>(
      0,
      (double acc, double v) => v > acc ? v : acc,
    );
    final double effectiveMax = maxValue <= 0 ? 1 : maxValue;

    // Baseline.
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      gridPaint,
    );

    final List<Offset> points = <Offset>[
      for (int i = 0; i < dailyVolumeKg.length; i++)
        Offset(
          (size.width / (dailyVolumeKg.length - 1)) * i,
          chartHeight - (dailyVolumeKg[i] / effectiveMax) * chartHeight * 0.9,
        ),
    ];

    if (points.length >= 2) {
      final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final Offset prev = points[i - 1];
        final Offset curr = points[i];
        final double midX = (prev.dx + curr.dx) / 2;
        linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
      }
      final Path fillPath = Path.from(linePath)
        ..lineTo(size.width, chartHeight)
        ..lineTo(0, chartHeight)
        ..close();

      canvas.drawPath(fillPath, Paint()..color = fillColor);
      canvas.drawPath(
        linePath,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    final Paint dotFill = Paint()..color = dotColor;
    for (final Offset p in points) {
      canvas.drawCircle(p, 3.0, dotFill);
    }

    // Day-of-week labels along the baseline.
    final TextStyle labelStyle = TextStyle(
      color: labelColor,
      fontSize: labelSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );
    for (int i = 0; i < _dayLabels.length; i++) {
      final TextPainter tp = TextPainter(
        text: TextSpan(text: _dayLabels[i], style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      final double x = points.length > 1
          ? (size.width / (_dayLabels.length - 1)) * i - tp.width / 2
          : size.width / 2 - tp.width / 2;
      tp.paint(canvas, Offset(x, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyRecapDailyVolumePainter old) {
    return old.dailyVolumeKg != dailyVolumeKg ||
        old.lineColor != lineColor ||
        old.fillColor != fillColor ||
        old.dotColor != dotColor ||
        old.labelColor != labelColor;
  }
}
