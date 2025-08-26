import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

class CreateGuildScreen extends StatefulWidget {
  const CreateGuildScreen({super.key});

  @override
  State<CreateGuildScreen> createState() => _CreateGuildScreenState();
}

class _CreateGuildScreenState extends State<CreateGuildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _descController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final tag = _tagController.text.trim();
    final desc = _descController.text.trim();

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createGuild');
      final result = await callable.call({
        'name': name,
        'tag': tag,
        'description': desc,
      });

      final data = result.data as Map<String, dynamic>;
      final String guildId = data['guildId'];

      if (!mounted) return;

      // Tokenized snackbar
      final glass = kStyle.glass;
      final text = kStyle.textOnGlass;
      ScaffoldMessenger.of(context).showSnackBar(
        buildTokenSnackBar(
          message: "Guild '${data['name']}' created!",
          glass: glass,
          text: text,
        ),
      );

      // Desktop vs mobile navigation stays centralized in MainContentController
      final controller = Provider.of<MainContentController>(context, listen: false);
      controller.setCustomContent(GuildProfileScreen(guildId: guildId));
    } catch (e) {
      debugPrint("🔥 Error creating guild: $e");
      if (mounted) {
        final glass = kStyle.glass;
        final text = kStyle.textOnGlass;
        ScaffoldMessenger.of(context).showSnackBar(
          buildTokenSnackBar(
            message: "Failed to create guild: $e",
            glass: glass,
            text: text,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 Live-reactive tokens
    context.watch<StyleManager>();
    final glass   = kStyle.glass;
    final text    = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final cardPad = kStyle.card.padding;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text("Create Guild", style: TextStyle(color: text.primary)),
        iconTheme: IconThemeData(color: text.primary),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
          children: [
            // Header panel
            TokenPanel(
              glass: glass,
              text: text,
              padding: EdgeInsets.fromLTRB(cardPad.left, 16, cardPad.right, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Found your guild",
                    style: TextStyle(
                      color: text.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Pick a memorable name and a short tag. You can update the description later.",
                    style: TextStyle(color: text.secondary, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Form panel
            TokenPanel(
              glass: glass,
              text: text,
              padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Guild Name
                    _LabeledField(
                      label: "Guild Name",
                      labelStyle: TextStyle(color: text.primary, fontSize: 14, fontWeight: FontWeight.w600),
                      child: TextFormField(
                        controller: _nameController,
                        maxLength: 30,
                        style: TextStyle(color: text.primary),
                        cursorColor: text.primary,
                        decoration: _inputDecoration("Enter guild name", glass, text),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Guild name is required";
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Guild Tag
                    _LabeledField(
                      label: "Guild Tag (2–4 letters)",
                      labelStyle: TextStyle(color: text.primary, fontSize: 14, fontWeight: FontWeight.w600),
                      child: TextFormField(
                        controller: _tagController,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(4),
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                        ],
                        textCapitalization: TextCapitalization.characters,
                        style: TextStyle(color: text.primary, letterSpacing: 1.0, fontFeatures: const [FontFeature.enable('smcp')]),
                        cursorColor: text.primary,
                        decoration: _inputDecoration("ABCD", glass, text),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Guild tag is required";
                          }
                          final tag = value.trim();
                          if (tag.length < 2 || tag.length > 4) {
                            return "Tag must be 2 to 4 letters";
                          }
                          if (!RegExp(r'^[a-zA-Z]+$').hasMatch(tag)) {
                            return "Only letters allowed (A–Z)";
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Description
                    _LabeledField(
                      label: "Description (optional)",
                      labelStyle: TextStyle(color: text.primary, fontSize: 14, fontWeight: FontWeight.w600),
                      child: TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        maxLength: 300,
                        style: TextStyle(color: text.primary),
                        cursorColor: text.primary,
                        decoration: _inputDecoration("Tell others what your guild is about…", glass, text),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Submit button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TokenIconButton(
                        variant: TokenButtonVariant.primary,
                        glass: glass,
                        text: text,
                        buttons: buttons,
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(text.primary),
                          ),
                        )
                            : const Icon(Icons.check),
                        label: Text(_isSubmitting ? "Creating..." : "Create Guild"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Input decoration that respects glass/solid tokens
  InputDecoration _inputDecoration(String hint, GlassTokens glass, TextOnGlassTokens text) {
    final borderColor = (glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity));

    // Solid gets elevated fill; glass gets a soft translucent fill
    final double fillAlpha = glass.mode == SurfaceMode.solid
        ? 1.0
        : (glass.opacity <= 0.02 ? 0.06 : glass.opacity.clamp(0.06, 0.18));

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: text.subtle),
      counterStyle: TextStyle(color: text.subtle),
      filled: true,
      fillColor: glass.baseColor.withValues(alpha: fillAlpha),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: glass.showBorder ? BorderSide(color: borderColor.withValues(alpha: 0.6), width: 1) : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor.withValues(alpha: 0.9), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.8), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.9), width: 1.2),
      ),
    );
  }
}

/// Small helper for consistent label spacing
class _LabeledField extends StatelessWidget {
  final String label;
  final TextStyle? labelStyle;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
