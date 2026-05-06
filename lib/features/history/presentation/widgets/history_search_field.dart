import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Inline search field promoted into the History hero. Live-as-you-type
/// with a 200 ms debounce so each keystroke doesn't trigger a full list
/// rebuild.
///
/// Stateless from the parent's perspective: it holds its own controller
/// and surfaces only the debounced value via [onDebouncedChanged]. The
/// parent passes the current canonical query in [initialValue] so the
/// field stays in sync if the user clears all filters from elsewhere
/// (e.g. the active-filter strip's "Clear all" link).
class HistorySearchField extends StatefulWidget {
  const HistorySearchField({
    super.key,
    required this.initialValue,
    required this.onDebouncedChanged,
    this.debounceDuration = const Duration(milliseconds: 200),
  });

  final String initialValue;
  final ValueChanged<String> onDebouncedChanged;
  final Duration debounceDuration;

  @override
  State<HistorySearchField> createState() => _HistorySearchFieldState();
}

class _HistorySearchFieldState extends State<HistorySearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(HistorySearchField old) {
    super.didUpdateWidget(old);
    if (widget.initialValue != old.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onDebouncedChanged(value);
    });
    setState(() {}); // Refresh suffix-icon visibility.
  }

  void _clearText() {
    _debounce?.cancel();
    _controller.clear();
    widget.onDebouncedChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        textInputAction: TextInputAction.search,
        cursorColor: Colors.white,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          isDense: true,
          hintText: 'Search workouts',
          hintStyle: TextStyle(
            color: palette.shade100.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: palette.shade100.withValues(alpha: 0.85),
            size: 20,
          ),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: palette.shade100,
                  onPressed: _clearText,
                  tooltip: 'Clear search',
                ),
        ),
      ),
    );
  }
}
