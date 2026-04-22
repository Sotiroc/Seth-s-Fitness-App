import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';

/// Bottom navigation bar in the "Indicator Line" style from the design spec:
/// a flat white bar with a short teal underline that animates in above the
/// active tab. Icons and labels stack vertically, quiet slate by default,
/// switching to a slightly brighter teal + bolder label when selected.
class IndicatorLineNavBar extends StatelessWidget {
  const IndicatorLineNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final JellyBeanPalette palette = context.jellyBeanPalette;
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: palette.shade100)),
      ),
      child: Padding(
        // The prototype used paddingBottom:14 for home-indicator breathing
        // room. On devices with their own safe-area inset, add the system
        // inset on top of a small fixed minimum.
        padding: EdgeInsets.only(bottom: bottomInset + 6),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < AppTab.values.length; i++)
              Expanded(
                child: _NavItem(
                  tab: AppTab.values[i],
                  selected: i == currentIndex,
                  palette: palette,
                  onTap: () => onTabSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final AppTab tab;
  final bool selected;
  final JellyBeanPalette palette;
  final VoidCallback onTap;

  static const Duration _indicatorDuration = Duration(milliseconds: 250);
  // cubic-bezier(.4, 0, .2, 1) — Material "standard" easing.
  static const Curve _indicatorCurve = Cubic(0.4, 0.0, 0.2, 1.0);

  @override
  Widget build(BuildContext context) {
    final Color activeColor = palette.shade700;
    final Color inactiveColor = palette.shade800;
    final Color itemColor = selected ? activeColor : inactiveColor;

    return InkResponse(
      onTap: onTap,
      highlightShape: BoxShape.rectangle,
      radius: 64,
      containedInkWell: true,
      child: SizedBox(
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Icon + label, vertically centered.
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  selected ? tab.selectedIcon : tab.icon,
                  size: 22,
                  color: itemColor,
                ),
                const SizedBox(height: 4),
                Text(
                  tab.label,
                  style: TextStyle(
                    color: itemColor,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
            // Indicator line pinned to the top edge, centered horizontally.
            // Animates width 0 ↔ 28 so the transition between tabs feels
            // like the line extending/retracting.
            Positioned(
              top: 0,
              child: AnimatedContainer(
                duration: _indicatorDuration,
                curve: _indicatorCurve,
                width: selected ? 28 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: palette.shade500,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
