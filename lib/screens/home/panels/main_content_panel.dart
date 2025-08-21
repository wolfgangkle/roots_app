import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/home/welcome_screen.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/theme/app_style_manager.dart';

// Live tokens (no caching)
GlassTokens get _glass => kStyle.glass;
TextOnGlassTokens get _text => kStyle.textOnGlass;

class MainContentPanel extends StatelessWidget {
  const MainContentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild when theme switches
    context.watch<StyleManager>();

    final controller = context.watch<MainContentController>();
    final content = controller.currentContent;

    debugPrint('[MainContentPanel] build() called');
    debugPrint('[MainContentPanel] currentContent is: ${content != null ? content.runtimeType : 'null'}');

    // Token-based surface
    final sigma = _glass.mode == SurfaceMode.glass ? _glass.blurSigma : 0.0;
    final bg = _glass.baseColor.withOpacity(_glass.opacity);
    final borderColor = _glass.borderColor ?? _text.subtle.withOpacity(_glass.strokeOpacity);

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg, // transparent or solid per theme
            border: _glass.showBorder ? Border.all(color: borderColor, width: 1) : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: content ?? const WelcomeScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
