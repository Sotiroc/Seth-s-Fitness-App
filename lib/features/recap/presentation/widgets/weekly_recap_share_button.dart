import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_share.dart';
import '../../../../data/models/unit_system.dart';
import '../../../../data/models/weekly_recap.dart';
import 'weekly_recap_card.dart';

/// Share affordance for the weekly recap card. Tap → captures the
/// portrait-format render off-screen, encodes it as PNG, and hands the
/// bytes to the system share sheet (or a download on web).
class WeeklyRecapShareButton extends StatefulWidget {
  const WeeklyRecapShareButton({
    super.key,
    required this.recap,
    required this.unitSystem,
    this.userName,
  });

  final WeeklyRecap recap;
  final UnitSystem unitSystem;
  final String? userName;

  @override
  State<WeeklyRecapShareButton> createState() => _WeeklyRecapShareButtonState();
}

class _WeeklyRecapShareButtonState extends State<WeeklyRecapShareButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: _busy ? null : _handleTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (_busy)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(palette.shade100),
                  ),
                )
              else
                const Icon(
                  Icons.ios_share_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              const SizedBox(width: 6),
              const Text(
                'Share',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap() async {
    setState(() => _busy = true);
    try {
      final Uint8List png = await _renderPortraitPng(context: context);
      final String filename = _filenameFor(widget.recap);
      final bool shared = await shareImagePng(
        bytes: png,
        filename: filename,
        title: 'Weekly recap',
      );
      if (!mounted) return;
      if (!shared) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sharing isn\'t supported on this device.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not share recap: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List> _renderPortraitPng({required BuildContext context}) async {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mq = MediaQuery.of(context);
    // Instagram story aspect ratio (1080×1920). Logical pixel scale
    // chosen so the captured image lands at 1080×1920 device pixels.
    const double logicalWidth = 540;
    const double logicalHeight = 960;
    const double pixelRatio = 2.0;

    final Widget tree = MediaQuery(
      data: mq.copyWith(
        size: const Size(logicalWidth, logicalHeight),
        textScaler: TextScaler.noScaling,
      ),
      child: Theme(
        data: theme,
        child: Directionality(
          textDirection: ui.TextDirection.ltr,
          child: SizedBox(
            width: logicalWidth,
            height: logicalHeight,
            child: WeeklyRecapShareableSurface(
              recap: widget.recap,
              unitSystem: widget.unitSystem,
              userName: widget.userName,
              orientation: WeeklyRecapOrientation.portrait,
            ),
          ),
        ),
      ),
    );

    return _captureWidgetToPng(
      tree: tree,
      logicalSize: const Size(logicalWidth, logicalHeight),
      pixelRatio: pixelRatio,
    );
  }
}

String _filenameFor(WeeklyRecap recap) {
  final DateFormat fmt = DateFormat('yyyy-MM-dd');
  return 'weekly-recap-${fmt.format(recap.weekStart.toLocal())}.png';
}

/// Renders [tree] into an off-screen pipeline at [logicalSize] and
/// returns a PNG snapshot scaled by [pixelRatio]. The widget never
/// attaches to the live render tree, so it doesn't disturb the visible
/// frame.
Future<Uint8List> _captureWidgetToPng({
  required Widget tree,
  required Size logicalSize,
  required double pixelRatio,
}) async {
  final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
  final RenderView renderView = RenderView(
    view: WidgetsBinding.instance.platformDispatcher.views.first,
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(logicalSize),
      physicalConstraints: BoxConstraints.tight(logicalSize * pixelRatio),
      devicePixelRatio: pixelRatio,
    ),
    child: RenderPositionedBox(
      alignment: Alignment.center,
      child: repaintBoundary,
    ),
  );
  final PipelineOwner pipelineOwner = PipelineOwner()
    ..rootNode = renderView;
  renderView.prepareInitialFrame();

  final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());
  final RenderObjectToWidgetElement<RenderBox> rootElement =
      RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: tree,
      ).attachToRenderTree(buildOwner);

  buildOwner.buildScope(rootElement);
  buildOwner.finalizeTree();

  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();

  final ui.Image image = await repaintBoundary.toImage(
    pixelRatio: pixelRatio,
  );
  try {
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (data == null) {
      throw StateError('Failed to encode recap PNG.');
    }
    return data.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
