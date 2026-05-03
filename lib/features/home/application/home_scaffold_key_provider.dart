import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the [GlobalKey] for [HomeShell]'s outer [Scaffold] so descendant
/// widgets (the per-tab `MenuIconButton`) can call `openDrawer()` on the
/// shell-level scaffold rather than the tab's inner one.
final Provider<GlobalKey<ScaffoldState>> homeScaffoldKeyProvider =
    Provider<GlobalKey<ScaffoldState>>(
      (Ref ref) => GlobalKey<ScaffoldState>(debugLabel: 'HomeShellScaffold'),
    );
