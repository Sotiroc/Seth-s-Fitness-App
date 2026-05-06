import 'package:flutter/material.dart';

/// Animated logo with a "thump-thump" cardiac pulse — two beats per loop
/// with a small dip between them, ending in a rest before the next cycle.
/// A radial glow expands and fades in sync, giving the logo presence on a
/// neutral background.
///
/// Used by [AppSplash] during cold start; safe to drop anywhere a branded
/// loading moment is wanted (e.g. while a workout session is being created).
class HeartbeatLogo extends StatefulWidget {
  const HeartbeatLogo({
    super.key,
    this.size = 160,
    this.assetPath = 'assets/branding/FitnessApp-Transparent.png',
    this.glowColor,
  });

  final double size;
  final String assetPath;

  /// Falls back to the active [ColorScheme.primary] when null.
  final Color? glowColor;

  @override
  State<HeartbeatLogo> createState() => _HeartbeatLogoState();
}

class _HeartbeatLogoState extends State<HeartbeatLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();

    _scale = TweenSequence<double>(<TweenSequenceItem<double>>[
      // Beat 1 — quick contraction
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      // Small dip between beats (the "lub" → "dub" gap)
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.08,
          end: 1.02,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 8,
      ),
      // Beat 2 — slightly stronger
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.02,
          end: 1.11,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      // Relax back to rest
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.11,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 32,
      ),
      // Quiet pause before the next pulse — gives the rhythm space
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1.0),
        weight: 40,
      ),
    ]).animate(_controller);

    _glow = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 0.55),
        weight: 10,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.55, end: 0.25),
        weight: 8,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.25, end: 0.7),
        weight: 10,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.7, end: 0.0),
        weight: 32,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0.0),
        weight: 40,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color glow =
        widget.glowColor ?? Theme.of(context).colorScheme.primary;
    final double haloMax = widget.size * 1.55;

    return SizedBox(
      width: haloMax,
      height: haloMax,
      // Image.asset is passed as the `child:` argument of AnimatedBuilder
      // and re-used inside the builder via the `child` parameter. This
      // means the image widget is constructed ONCE and only the animated
      // transforms (scale + halo gradient) are rebuilt per frame. Keep
      // the image outside the builder closure — moving it inside would
      // re-decode/reconstruct the asset at ~60fps.
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double haloSize =
              widget.size * (1.0 + _glow.value * 0.3);
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: haloSize,
                height: haloSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      glow.withValues(alpha: 0.18 * _glow.value),
                      glow.withValues(alpha: 0.0),
                    ],
                    stops: const <double>[0.35, 1.0],
                  ),
                ),
              ),
              Transform.scale(scale: _scale.value, child: child),
            ],
          );
        },
        child: Image.asset(
          widget.assetPath,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          // Source PNG is high-res; cap decode size to roughly 2x display.
          cacheWidth: (widget.size * 2).round(),
          cacheHeight: (widget.size * 2).round(),
        ),
      ),
    );
  }
}
