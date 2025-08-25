import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:roots_app/modules/heroes/models/hero_group_model.dart';
import 'package:roots_app/modules/heroes/widgets/hero_group_movement_minimap.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';
import 'package:roots_app/theme/tokens.dart';

class FoundVillageScreen extends StatefulWidget {
  final HeroGroupModel group;

  const FoundVillageScreen({super.key, required this.group});

  @override
  State<FoundVillageScreen> createState() => _FoundVillageScreenState();
}

class _FoundVillageScreenState extends State<FoundVillageScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final mainContentController = Provider.of<MainContentController>(context, listen: false);

    if (name.length < 3) {
      messenger.showSnackBar(const SnackBar(content: Text('Village name must be at least 3 characters.')));
      return;
    }

    final heroId = widget.group.leaderHeroId ?? widget.group.members.first;

    // Ask for confirmation if a companion will be converted
    if (heroId.startsWith('companion_')) {
      final ok = await _showConvertCompanionDialog();
      if (ok != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createVillage');
      final result = await callable.call({
        'heroId': heroId,
        'villageName': name,
      });

      messenger.showSnackBar(SnackBar(content: Text(result.data['message'] ?? 'Village created.')));

      // Reset back to your default content area
      mainContentController.reset();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showConvertCompanionDialog() async {
    final style   = context.read<StyleManager>().currentStyle;
    final glass   = style.glass;
    final text    = style.textOnGlass;
    final buttons = style.buttons;

    final outlinePalette = ButtonPalette(outlineBorder: buttons.primaryBg);

    // glass/solid aware background
    final double fillAlpha = glass.mode == SurfaceMode.solid
        ? 1.0
        : (glass.opacity <= 0.02 ? 0.06 : glass.opacity);

    final Color dialogBg = glass.baseColor.withValues(alpha: fillAlpha);
    final ShapeBorder dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: glass.showBorder
          ? BorderSide(
        color: (glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity))
            .withValues(alpha: 0.6),
        width: 1,
      )
          : BorderSide.none,
    );

    return showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: dialogBg,
          surfaceTintColor: Colors.transparent,
          shape: dialogShape,
          title: Text(
            'Convert Companion to Village',
            style: TextStyle(color: text.primary),
          ),
          content: Text(
            'Are you sure you want to found a village with this companion?\n\n'
                'This will permanently remove them.',
            style: TextStyle(color: text.secondary),
          ),
          actions: [
            TokenTextButton(
              variant: TokenButtonVariant.outline,
              palette: outlinePalette,
              glass: glass,
              text: text,
              buttons: buttons,
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TokenButton(
              variant: TokenButtonVariant.danger,
              glass: glass,
              text: text,
              buttons: buttons,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, Convert'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔁 tokens
    context.watch<StyleManager>();
    final glass   = kStyle.glass;
    final text    = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final pad     = kStyle.card.padding;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Found New Village', style: TextStyle(color: text.primary)),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: text.primary),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
            child: SingleChildScrollView(
              child: TokenPanel(
                glass: glass,
                text: text,
                padding: EdgeInsets.fromLTRB(pad.left, 16, pad.right, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mini header line
                    Text(
                      'Choose a name and confirm.',
                      style: TextStyle(color: text.secondary),
                    ),
                    const SizedBox(height: 12),

                    // Mini-map panel — sized like movement screen (square, full panel width)
                    TokenPanel(
                      glass: glass,
                      text: text,
                      padding: EdgeInsets.fromLTRB(pad.left, 8, pad.right, 8),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final side = c.maxWidth; // use full available width
                          return SizedBox(
                            height: side, // square: height == width
                            child: HeroGroupMovementMiniMap(group: widget.group),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Name field (token-friendly)
                    Text(
                      'Village Name',
                      style: TextStyle(
                        color: text.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _controller,
                      maxLength: 24,
                      style: TextStyle(color: text.primary),
                      decoration: InputDecoration(
                        hintText: 'Enter village name',
                        hintStyle: TextStyle(color: text.subtle),
                        labelStyle: TextStyle(color: text.secondary),
                        counterStyle: TextStyle(color: text.subtle),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: text.subtle.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: text.primary.withValues(alpha: 0.7)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: false,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),

                    if ((widget.group.leaderHeroId ?? widget.group.members.first).startsWith('companion_')) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: Colors.orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Using a companion will permanently convert them into a village.',
                              style: TextStyle(fontSize: 12, color: Colors.orange.shade300),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                    TokenDivider(glass: glass, text: text),
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TokenIconButton(
                        glass: glass,
                        text: text,
                        buttons: buttons,
                        variant: TokenButtonVariant.primary,
                        icon: _isLoading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.flag),
                        label: Text(_isLoading ? 'Founding Village...' : 'Found Village'),
                        onPressed: _isLoading ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
