import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'heartbeat_logo.dart';

/// Full-screen branded splash shown on cold start while the database
/// bootstrap completes (and during any future long-running session-creation
/// flows). Pairs the [HeartbeatLogo] with a soft radial backdrop and a
/// fading-in tagline.
class AppSplash extends StatefulWidget {
  const AppSplash({super.key, this.message});

  final String? message;

  @override
  State<AppSplash> createState() => _AppSplashState();
}

class _AppSplashState extends State<AppSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    return Material(
      color: Colors.white,
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              HeartbeatLogo(size: 180, glowColor: palette.shade300),
              const SizedBox(height: 24),
              Text(
                widget.message ?? 'Warming up',
                style: TextStyle(
                  color: palette.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
