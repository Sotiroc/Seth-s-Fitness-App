import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/repositories/app_settings_repository.dart';

/// Configures the global rest timer. The timer is uniform across the
/// app: this single value applies to every exercise unless cleared, in
/// which case each exercise type's built-in default applies (weighted
/// 2:00, bodyweight 1:00, cardio off).
class TimerSettingsScreen extends ConsumerWidget {
  const TimerSettingsScreen({super.key});

  static const List<int> _presets = <int>[0, 60, 90, 120, 180];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final int? userDefault =
        ref.watch(defaultRestSecondsProvider).asData?.value;

    return Scaffold(
      backgroundColor: palette.shade50,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _Header(palette: palette, userDefault: userDefault),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            sliver: SliverList.list(
              children: <Widget>[
                _SectionLabel(
                  text: 'Choose a default',
                  palette: palette,
                ),
                const SizedBox(height: AppSpacing.sm),
                _PresetGrid(
                  palette: palette,
                  presets: _presets,
                  selected: userDefault,
                  onPick: (int? value) async {
                    HapticFeedback.selectionClick();
                    await ref
                        .read(appSettingsRepositoryProvider)
                        .setDefaultRestSeconds(value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _CustomCard(
                  palette: palette,
                  current: userDefault,
                  presets: _presets,
                  onChange: (int? value) async {
                    await ref
                        .read(appSettingsRepositoryProvider)
                        .setDefaultRestSeconds(value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _ExplanationCard(palette: palette),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero header — gradient teal slab with back button, eyebrow label,
/// title, and a big "current value" readout that mirrors the rest
/// timer's runtime tabular figures so the screen feels like a direct
/// preview of what the user is configuring.
class _Header extends StatelessWidget {
  const _Header({required this.palette, required this.userDefault});

  final JellyBeanPalette palette;
  final int? userDefault;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double topPadding = MediaQuery.paddingOf(context).top;
    final bool isAuto = userDefault == null;
    final bool isOff = userDefault == 0;
    final String bigText = isAuto
        ? 'AUTO'
        : DurationFormatter.formatSeconds(userDefault!);
    final String subtitle = isAuto
        ? 'using each exercise type\'s default'
        : isOff
        ? 'rest timer disabled'
        : 'between every set';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.shade950, palette.shade800, palette.shade600],
          stops: const <double>[0.0, 0.55, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topPadding + AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: AppSpacing.xs),
              _GlassPill(
                palette: palette,
                icon: Icons.timer_rounded,
                label: 'TIMER',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Rest between sets',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      bigText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isAuto ? 56 : 64,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: isAuto ? 4 : -2,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: palette.shade200.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isOff
                      ? Icons.timer_off_rounded
                      : isAuto
                      ? Icons.auto_awesome_rounded
                      : Icons.timer_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.palette,
    required this.icon,
    required this.label,
  });

  final JellyBeanPalette palette;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: palette.shade100),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: palette.shade100,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.palette});

  final String text;
  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: palette.shade700,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}

/// 2×3 tile grid of preset durations, plus a leading "Auto" tile that
/// clears the override. Tap-to-select is immediate; the hero readout
/// updates via the watched provider.
class _PresetGrid extends StatelessWidget {
  const _PresetGrid({
    required this.palette,
    required this.presets,
    required this.selected,
    required this.onPick,
  });

  final JellyBeanPalette palette;
  final List<int> presets;
  final int? selected;
  final Future<void> Function(int?) onPick;

  @override
  Widget build(BuildContext context) {
    final List<_TileData> tiles = <_TileData>[
      const _TileData(value: null, label: 'Auto', icon: Icons.auto_awesome_rounded),
      for (final int preset in presets)
        _TileData(
          value: preset,
          label: preset == 0
              ? 'Off'
              : DurationFormatter.formatSeconds(preset),
          icon: preset == 0
              ? Icons.timer_off_rounded
              : Icons.timer_outlined,
        ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.xs,
      mainAxisSpacing: AppSpacing.xs,
      childAspectRatio: 1.4,
      children: <Widget>[
        for (final _TileData tile in tiles)
          _PresetTile(
            palette: palette,
            data: tile,
            selected: tile.value == selected ||
                (tile.value == null && selected == null),
            onTap: () => onPick(tile.value),
          ),
      ],
    );
  }
}

class _TileData {
  const _TileData({required this.value, required this.label, required this.icon});
  final int? value;
  final String label;
  final IconData icon;
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.palette,
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final JellyBeanPalette palette;
  final _TileData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? palette.shade900 : Colors.white;
    final Color fg = selected ? Colors.white : palette.shade950;
    final Color subFg = selected
        ? palette.shade200.withValues(alpha: 0.8)
        : palette.shade700.withValues(alpha: 0.7);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? palette.shade900 : palette.shade100,
              width: 1.2,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: palette.shade900.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(data.icon, color: subFg, size: 16),
              const Spacer(),
              Text(
                data.label,
                style: TextStyle(
                  color: fg,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A subtle "or set a custom value" affordance below the preset grid,
/// styled as a card with a caption and a compact mm:ss input. Treats
/// any current value not in the preset list as already-custom and pre-
/// fills the field. Saving happens on each valid keystroke.
class _CustomCard extends StatefulWidget {
  const _CustomCard({
    required this.palette,
    required this.current,
    required this.presets,
    required this.onChange,
  });

  final JellyBeanPalette palette;
  final int? current;
  final List<int> presets;
  final Future<void> Function(int?) onChange;

  @override
  State<_CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<_CustomCard> {
  late TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _initialText());
  }

  @override
  void didUpdateWidget(covariant _CustomCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) {
      // Sync only when the current value isn't already what we display —
      // typing keeps the field in control and shouldn't be clobbered by
      // intermediate saves.
      final String next = _initialText();
      if (_controller.text != next) {
        _controller.text = next;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _initialText() {
    final int? c = widget.current;
    if (c == null || widget.presets.contains(c)) return '';
    return DurationFormatter.formatSeconds(c);
  }

  bool get _isCustom =>
      widget.current != null && !widget.presets.contains(widget.current);

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = widget.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCustom ? palette.shade300 : palette.shade100,
          width: _isCustom ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: palette.shade800,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Custom duration',
                  style: TextStyle(
                    color: palette.shade950,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.text,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
            ],
            style: TextStyle(
              color: palette.shade950,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              hintText: '01:30',
              hintStyle: TextStyle(
                color: palette.shade700.withValues(alpha: 0.4),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
              suffixText: 'mm:ss',
              suffixStyle: TextStyle(
                color: palette.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              errorText: _error,
              filled: true,
              fillColor: palette.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.shade100),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.shade100),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.shade500, width: 1.5),
              ),
            ),
            onChanged: (String raw) async {
              final String trimmed = raw.trim();
              if (trimmed.isEmpty) {
                setState(() => _error = null);
                return;
              }
              final int? parsed = DurationFormatter.parseSeconds(trimmed);
              if (parsed == null || parsed > 3600) {
                setState(() => _error = 'Up to 60:00');
                return;
              }
              setState(() => _error = null);
              await widget.onChange(parsed);
            },
          ),
        ],
      ),
    );
  }
}

/// Compact info card explaining how the global default interacts with
/// the rest timer. Sits below the picker so the picker stays the
/// dominant element on the screen.
class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.palette});

  final JellyBeanPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.shade100.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: palette.shade800,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Per-exercise rest still wins. Set this for everything that '
              'doesn\'t have its own rest. Auto = each type\'s default '
              '(weighted 2:00, bodyweight 1:00, cardio off).',
              style: TextStyle(
                color: palette.shade900,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
