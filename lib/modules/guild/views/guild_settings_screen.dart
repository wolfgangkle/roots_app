import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/profile/models/user_profile_model.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';



class GuildSettingsScreen extends StatefulWidget {
  const GuildSettingsScreen({super.key});

  @override
  State<GuildSettingsScreen> createState() => _GuildSettingsScreenState();
}

class _GuildSettingsScreenState extends State<GuildSettingsScreen> {
  final _descController = TextEditingController();
  bool _isSaving = false;
  bool _isEditing = false;
  String _currentDescription = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentDescription();
  }

  Future<void> _loadCurrentDescription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .doc('users/${user.uid}/profile/main')
        .get();

    final guildId = userDoc.data()?['guildId'];
    if (guildId == null) return;

    final guildDoc = await FirebaseFirestore.instance.doc('guilds/$guildId').get();
    final description = (guildDoc.data()?['description'] ?? '') as String;

    if (!mounted) return;
    setState(() {
      _currentDescription = description;
      _descController.text = description;
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 Live-reactive tokens
    context.watch<StyleManager>();
    final glass   = kStyle.glass;
    final text    = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final cardPad = kStyle.card.padding;

    final profile  = context.watch<UserProfileModel>();
    final isLeader = profile.guildRole == 'leader';
    final guildId  = profile.guildId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text("Guild Settings", style: TextStyle(color: text.primary)),
        iconTheme: IconThemeData(color: text.primary),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        children: [
          // Header
          TokenPanel(
            glass: glass,
            text: text,
            padding: EdgeInsets.fromLTRB(cardPad.left, 16, cardPad.right, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "⚙️ Manage Guild Settings",
                  style: TextStyle(color: text.primary, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  "Update the public description of your guild.",
                  style: TextStyle(color: text.secondary, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Description panel
          TokenPanel(
            glass: glass,
            text: text,
            padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("📝 Guild Description", style: TextStyle(color: text.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                if (!_isEditing) ...[
                  // read-only view
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: glass.baseColor.withValues(
                        alpha: glass.mode == SurfaceMode.solid
                            ? 1.0
                            : (glass.opacity <= 0.02 ? 0.06 : glass.opacity),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: glass.showBorder
                          ? Border.all(
                        color: (glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity))
                            .withValues(alpha: 0.6),
                        width: 1,
                      )
                          : null,
                    ),
                    child: Text(
                      _currentDescription.isEmpty ? "(No description set)" : _currentDescription,
                      style: TextStyle(color: text.secondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isLeader)
                    TokenIconButton(
                      variant: TokenButtonVariant.primary,
                      glass: glass,
                      text: text,
                      buttons: buttons,
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Description"),
                    ),
                ] else ...[
                  // edit view
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    maxLength: 500,
                    style: TextStyle(color: text.primary),
                    cursorColor: text.primary,
                    decoration: _inputDecoration("Enter a new guild description…", glass, text),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TokenIconButton(
                        variant: TokenButtonVariant.primary,
                        glass: glass,
                        text: text,
                        buttons: buttons,
                        onPressed: _isSaving ? null : () => _saveDescription(guildId),
                        icon: _isSaving
                            ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(text.primary),
                          ),
                        )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? "Saving..." : "Save"),
                      ),
                      const SizedBox(width: 8),
                      TokenTextButton(
                        variant: TokenButtonVariant.outline,
                        glass: glass,
                        text: text,
                        buttons: buttons,
                        onPressed: () {
                          _descController.text = _currentDescription;
                          setState(() => _isEditing = false);
                        },
                        child: const Text("Cancel"),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Danger zone
          if (isLeader)
            TokenPanel(
              glass: glass,
              text: text,
              padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Danger Zone", style: TextStyle(color: text.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TokenIconButton(
                    variant: TokenButtonVariant.danger,
                    glass: glass,
                    text: text,
                    buttons: buttons,
                    onPressed: _confirmDisbandGuild,
                    icon: const Icon(Icons.warning),
                    label: const Text("Disband Guild"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Save description (pre-grab messenger; no BuildContext after await)
  Future<void> _saveDescription(String? guildId) async {
    final messenger = ScaffoldMessenger.of(context);
    final glass = kStyle.glass;
    final text  = kStyle.textOnGlass;

    final newDescription = _descController.text.trim();
    if (newDescription.length > 500) {
      messenger.showSnackBar(
        buildTokenSnackBar(message: "Max 500 characters.", glass: glass, text: text),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('updateGuildDescription')
          .call({'guildId': guildId, 'description': newDescription});

      if (!mounted) return;
      setState(() {
        _currentDescription = newDescription;
        _isEditing = false;
      });

      messenger.showSnackBar(
        buildTokenSnackBar(message: "Description updated!", glass: glass, text: text),
      );
    } catch (e) {
      messenger.showSnackBar(
        buildTokenSnackBar(message: "Error: $e", glass: glass, text: text),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDisbandGuild() async {
    final messenger = ScaffoldMessenger.of(context);
    final glass = kStyle.glass;
    final text  = kStyle.textOnGlass;

    // tokenized dialog styling
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

    bool isProcessing = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              shape: dialogShape,
              title: Text("Disband Guild?", style: TextStyle(color: text.primary)),
              content: Text(
                "This will permanently delete your guild. Cannot be undone.",
                style: TextStyle(color: text.secondary),
              ),
              actions: [
                TokenTextButton(
                  variant: TokenButtonVariant.outline,
                  glass: glass,
                  text: text,
                  buttons: kStyle.buttons,
                  onPressed: isProcessing ? null : () => Navigator.of(dialogContext).pop(false),
                  child: const Text("Cancel"),
                ),
                TokenButton(
                  variant: TokenButtonVariant.danger,
                  glass: glass,
                  text: text,
                  buttons: kStyle.buttons,
                  onPressed: isProcessing
                      ? null
                      : () async {
                    setState(() => isProcessing = true);
                    try {
                      await FirebaseFunctions.instance
                          .httpsCallable('disbandGuild')
                          .call();

                      // ✅ Correct: guard with the SAME context you’ll use
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop(true);

                      messenger.showSnackBar(
                        buildTokenSnackBar(message: "Guild disbanded.", glass: glass, text: text),
                      );
                    } catch (e) {
                      setState(() => isProcessing = false);
                      messenger.showSnackBar(
                        buildTokenSnackBar(message: "Error: $e", glass: glass, text: text),
                      );
                    }
                  },
                  child: isProcessing
                      ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(text.primary),
                    ),
                  )
                      : const Text("Disband"),
                ),
              ],
            );
          },
        );
      },
    );

    // handled inside the dialog
    if (confirmed != true) return;
  }


  // Input decoration respecting tokens
  InputDecoration _inputDecoration(String hint, GlassTokens glass, TextOnGlassTokens text) {
    final borderColor = (glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity));

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
        borderSide: glass.showBorder
            ? BorderSide(color: borderColor.withValues(alpha: 0.6), width: 1)
            : BorderSide.none,
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
