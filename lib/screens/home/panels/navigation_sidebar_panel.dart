import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 👈 listen for theme changes
import 'package:roots_app/screens/home/panels/navigation_list_content.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/theme/app_style_manager.dart';

GlassTokens get _glass => kStyle.glass;
TextOnGlassTokens get _text => kStyle.textOnGlass;

class NavigationSidebarPanel extends StatelessWidget {
  final void Function({required String title, required Widget content})? onSelectDynamicTab;

  const NavigationSidebarPanel({super.key, this.onSelectDynamicTab});

  @override
  Widget build(BuildContext context) {
    // 👇 Rebuild when StyleManager changes (theme switch)
    context.watch<StyleManager>();

    final bg = _glass.baseColor.withOpacity(_glass.opacity);
    final borderColor = _glass.borderColor ?? _text.subtle.withOpacity(_glass.strokeOpacity);
    final sigma = _glass.mode == SurfaceMode.glass ? _glass.blurSigma : 0.0;

    return SizedBox(
      width: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              border: _glass.showBorder
                  ? Border(right: BorderSide(color: borderColor, width: 1))
                  : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: NavigationListContent(onSelectDynamicTab: onSelectDynamicTab),
            ),
          ),
        ),
      ),
    );
  }
}
