// lib/theme/widgets/themed_top_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/theme/app_style_manager.dart';

class ThemedTopBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final double? heightOverride;
  final bool centerTitle;

  /// Supports TabBar or any PreferredSizeWidget below the title row
  final PreferredSizeWidget? bottom;

  /// NEW: allow disabling the internal SafeArea when used as a floating card
  final bool safeAreaTop;

  const ThemedTopBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.heightOverride,
    this.centerTitle = false,
    this.bottom,
    this.safeAreaTop = true, // NEW
  });

  @override
  Size get preferredSize {
    // AppBar height (excludes status bar); Scaffold will position body below this
    final base = heightOverride ?? kToolbarHeight;
    final bottomH = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(base + bottomH);
  }

  @override
  Widget build(BuildContext context) {
    final style = context.watch<StyleManager>().currentStyle;
    final b = style.banner;
    final h = heightOverride ?? b.height;
    final bottomH = bottom?.preferredSize.height ?? 0;

    // Status bar icon color based on title color
    final isLightText = style.textOnGlass.primary.computeLuminance() < 0.5;
    final overlay =
    isLightText ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    // Inner content (without SafeArea) so we can optionally wrap it
    final inner = AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: h,
            child: Padding(
              padding: b.padding,
              child: Row(
                children: [
                  if (leading != null) leading!,
                  if (leading != null) const SizedBox(width: 8),
                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: style.textOnGlass.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      child: centerTitle
                          ? Center(child: title ?? const SizedBox())
                          : (title ?? const SizedBox()),
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );

    return SizedBox(
      // 👇 Match preferredSize exactly: no status-bar padding here
      height: h + bottomH,
      // Constrain blur to the bar rectangle
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (b.assetPath != null)
              Image.asset(b.assetPath!, fit: b.fit, alignment: b.alignment),

            if (b.blurSigma > 0)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: b.blurSigma, sigmaY: b.blurSigma),
                child: const SizedBox.expand(),
              ),

            if (b.lightenAdd > 0)
              Container(color: Colors.white.withValues(alpha: b.lightenAdd)),
            if (b.darken > 0)
              Container(color: Colors.black.withValues(alpha: b.darken)),

            // 👉 Apply SafeArea only when we're not in "floating" mode
            safeAreaTop ? SafeArea(bottom: false, child: inner) : inner,
          ],
        ),
      ),
    );
  }
}
