import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 👈 listen for theme changes
import 'package:roots_app/screens/home/panels/navigation_list_content.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/theme/app_style_manager.dart';

GlassTokens get _glass => kStyle.glass;
TextOnGlassTokens get _text => kStyle.textOnGlass;

class NavigationDrawerPanel extends StatelessWidget {
  final void Function({required String title, required Widget content})? onSelectDynamicTab;

  const NavigationDrawerPanel({super.key, this.onSelectDynamicTab});

  @override
  Widget build(BuildContext context) {
    // 👇 Rebuild when StyleManager notifies (theme switch)
    context.watch<StyleManager>();

    final bg = _glass.baseColor.withValues(alpha: _glass.opacity);
    final borderColor = _glass.borderColor ?? _text.subtle.withValues(alpha: _glass.strokeOpacity);
    final sigma = _glass.mode == SurfaceMode.glass ? _glass.blurSigma : 0.0;

    return Drawer(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
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
                child: NavigationListContent(
                  onSelectDynamicTab: onSelectDynamicTab,
                  isInDrawer: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
