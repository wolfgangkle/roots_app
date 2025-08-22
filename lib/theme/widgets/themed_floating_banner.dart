// lib/theme/widgets/themed_floating_banner.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/themed_top_bar.dart';

/// Shows ThemedTopBar as a floating panoramic card with rounded corners,
/// outer margins, optional actions/leading, and an optional onTap.
class ThemedFloatingBanner extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final double? heightOverride;
  final bool centerTitle;
  final EdgeInsets margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const ThemedFloatingBanner({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.heightOverride,
    this.centerTitle = false,
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = context.watch<StyleManager>().currentStyle;
    final h = heightOverride ?? style.banner.height;
    final bottomH = bottom?.preferredSize.height ?? 0;
    final totalH = h + bottomH;

    return Padding(
      padding: margin,
      child: SizedBox(
        height: totalH,
        width: double.infinity,
        child: Stack(
          children: [
            // Soft shadow behind the rounded card
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // Transparent fill + shadow → gives a floating look
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
            // Rounded clipping + clickable surface
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  // If you want a ripple inside the banner image:
                  splashColor: Colors.white.withValues(alpha: 0.06),
                  highlightColor: Colors.white.withValues(alpha: 0.02),
                  child: ThemedTopBar(
                    title: title,
                    actions: actions,
                    leading: leading,
                    bottom: bottom,
                    centerTitle: centerTitle,
                    heightOverride: h,
                    safeAreaTop: false, // we’re already floating inside the body
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
