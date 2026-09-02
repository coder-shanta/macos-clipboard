import 'package:flutter/material.dart';

import '../theme.dart';

/// The Flutter-side half of the app's "liquid glass" look.
///
/// The actual blur comes from a native `NSVisualEffectView` sitting behind
/// the Flutter window (see `WindowController`); this widget adds the tint,
/// a soft top-down sheen, and a hairline highlight border on top of it so
/// the glass reads with depth instead of being a flat translucent panel.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = cardRadius,
    this.elevated = true,
  });

  final Widget child;
  final double borderRadius;

  /// Whether to draw the drop shadow (used for floating cards; the root
  /// window panel skips it since the OS already draws a window shadow).
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);

    final tint = isDark
        ? Colors.black.withValues(alpha: 0.30)
        : Colors.white.withValues(alpha: 0.46);
    final sheenTop = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.55);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.75);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: elevated ? cardShadow(theme.brightness) : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(child: ColoredBox(color: tint)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.55],
                    colors: [sheenTop, sheenTop.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: borderColor, width: 1),
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
