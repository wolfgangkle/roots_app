// lib/modules/settings/screens/settings_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/settings/models/user_settings_model.dart';
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/l10n/l10n_x.dart'; // <- context.l10n helper

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<UserSettingsModel>();
    final styleMgr = context.watch<StyleManager>();

    final style = styleMgr.currentStyle;
    final glass = style.glass;
    final text = style.textOnGlass;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(context.l10n.settings_title, style: TextStyle(color: text.primary)),
        iconTheme: IconThemeData(color: text.primary),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        children: [
          // 🎨 Theme panel
          TokenPanel(
            glass: glass,
            text: text,
            useBlur: true, // set to false on very low-end devices
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: context.l10n.settings_appStyle,
                  subtitle: context.l10n.settings_appStyle_sub,
                  text: text,
                ),
                const SizedBox(height: 8),
                _RadioTile<AppTheme>(
                  glass: glass,
                  text: text,
                  title: context.l10n.theme_darkForge,
                  subtitle: context.l10n.theme_darkForge_sub,
                  value: AppTheme.darkForge,
                  groupValue: styleMgr.current,
                  onChanged: (v) => context.read<StyleManager>().setTheme(v!),
                ),
                _Divider(glass: glass, text: text),
                _RadioTile<AppTheme>(
                  glass: glass,
                  text: text,
                  title: context.l10n.theme_silverGrove,
                  subtitle: context.l10n.theme_silverGrove_sub,
                  value: AppTheme.silverGrove,
                  groupValue: styleMgr.current,
                  onChanged: (v) => context.read<StyleManager>().setTheme(v!),
                ),
                _Divider(glass: glass, text: text),
                _RadioTile<AppTheme>(
                  glass: glass,
                  text: text,
                  title: context.l10n.theme_ironKeep,
                  subtitle: context.l10n.theme_ironKeep_sub,
                  value: AppTheme.ironKeep,
                  groupValue: styleMgr.current,
                  onChanged: (v) => context.read<StyleManager>().setTheme(v!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 🗣️ Language panel
          TokenPanel(
            glass: glass,
            text: text,
            useBlur: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: context.l10n.settings_language,
                  subtitle: context.l10n.settings_language_sub,
                  text: text,
                ),
                const SizedBox(height: 8),
                _RadioTile<Locale?>(
                  glass: glass,
                  text: text,
                  title: context.l10n.lang_system,
                  subtitle: null,
                  value: null, // follow system
                  groupValue: settings.locale,
                  onChanged: (loc) {
                    settings.setLocale(loc);
                    // Nudge this screen to rebuild immediately in case parent rebuild lands next frame
                    Future.microtask(() {
                      (context as Element).markNeedsBuild();
                    });
                  },
                ),
                _Divider(glass: glass, text: text),
                _RadioTile<Locale?>(
                  glass: glass,
                  text: text,
                  title: context.l10n.lang_english,
                  subtitle: null,
                  value: const Locale('en'),
                  groupValue: settings.locale,
                  onChanged: (loc) => settings.setLocale(loc),
                ),
                _Divider(glass: glass, text: text),
                _RadioTile<Locale?>(
                  glass: glass,
                  text: text,
                  title: context.l10n.lang_german,
                  subtitle: null,
                  value: const Locale('de'),
                  groupValue: settings.locale,
                  onChanged: (loc) => settings.setLocale(loc),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 💬 Other toggles
          TokenPanel(
            glass: glass,
            text: text,
            useBlur: true,
            child: Column(
              children: [
                _SwitchTile(
                  glass: glass,
                  text: text,
                  title: context.l10n.toggle_chatOverlay,
                  value: settings.showChatOverlay,
                  onChanged: settings.setShowChatOverlay,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TokenPanel extends StatelessWidget {
  final GlassTokens glass;
  final TextOnGlassTokens text;
  final Widget child;
  final bool useBlur;

  const TokenPanel({
    super.key,
    required this.glass,
    required this.text,
    required this.child,
    this.useBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity);

    // Never fully invisible in glass mode
    final double fillOpacity = glass.mode == SurfaceMode.solid
        ? 1.0
        : (glass.opacity <= 0.02 ? 0.06 : glass.opacity);

    return RepaintBoundary(
      child: ClipRRect(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.passthrough, // size driven by DecoratedBox (content)
          children: [
            // ✅ Safe blur: fill the panel’s own bounds (finite), not the scroll viewport.
            if (glass.mode == SurfaceMode.glass && useBlur)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: glass.blurSigma,
                      sigmaY: glass.blurSigma,
                    ),
                    child: const SizedBox.shrink(),
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: glass.baseColor.withValues(alpha: fillOpacity),
                borderRadius: BorderRadius.circular(16),
                border: glass.showBorder ? Border.all(color: borderColor) : null,
                boxShadow: glass.mode == SurfaceMode.solid && glass.elevation > 0
                    ? [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextOnGlassTokens text;
  const _SectionHeader({required this.title, this.subtitle, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: text.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle!,
                  style: TextStyle(color: text.subtle, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final GlassTokens glass;
  final TextOnGlassTokens text;

  const _Divider({required this.glass, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = (glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity)).withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(height: 1, thickness: 1, color: c),
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  final GlassTokens glass;
  final TextOnGlassTokens text;
  final String title;
  final String? subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;
  const _RadioTile({
    required this.glass,
    required this.text,
    required this.title,
    this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            // Radio dot styled by tokens
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: text.secondary.withValues(alpha: 0.9), width: 2),
              ),
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: selected ? 10 : 0,
                height: selected ? 10 : 0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: text.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: text.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!,
                          style: TextStyle(color: text.subtle, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final GlassTokens glass;
  final TextOnGlassTokens text;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.glass,
    required this.text,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: TextStyle(
                    color: text.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              switchTheme: SwitchThemeData(
                trackColor: WidgetStateProperty.resolveWith((states) {
                  final on = states.contains(WidgetState.selected);
                  return (on ? text.primary : text.subtle).withValues(alpha: 0.25);
                }),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  final on = states.contains(WidgetState.selected);
                  return on ? text.primary : text.secondary;
                }),
              ),
            ),
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
