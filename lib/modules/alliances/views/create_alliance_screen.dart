import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'package:roots_app/modules/alliances/views/alliance_members_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart'; // <-- tokenized buttons

class CreateAllianceScreen extends StatefulWidget {
  const CreateAllianceScreen({super.key});

  @override
  State<CreateAllianceScreen> createState() => _CreateAllianceScreenState();
}

class _CreateAllianceScreenState extends State<CreateAllianceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _descController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final tag = _tagController.text.trim(); // preserve case
    final desc = _descController.text.trim();

    final style = context.read<StyleManager>().currentStyle;
    final glass = style.glass;
    final text = style.textOnGlass;

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createAlliance');
      final result = await callable.call({
        'name': name,
        'tag': tag,
        'description': desc,
      });

      final data = result.data;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        buildTokenSnackBar(
          message: "Alliance '${data['name']}' created!",
          glass: glass,
          text: text,
        ),
      );

      final controller = context.read<MainContentController>();
      controller.setCustomContent(const AllianceMembersScreen());
    } catch (e) {
      debugPrint("🔥 Error creating alliance: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildTokenSnackBar(
            message: "Failed to create alliance: $e",
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
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = context.watch<StyleManager>().currentStyle;
    final glass = style.glass;
    final text = style.textOnGlass;
    final buttons = style.buttons; // <-- theme button tokens

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text("Create Alliance", style: TextStyle(color: text.primary)),
        iconTheme: IconThemeData(color: text.primary),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        children: [
          TokenPanel(
            glass: glass,
            text: text,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      "Create an Alliance",
                      style: TextStyle(
                        color: text.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Alliance Name
                    Text("Alliance Name",
                        style: TextStyle(color: text.secondary, fontSize: 14)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isSubmitting,
                      maxLength: 40,
                      decoration: _inputDecoration(
                        context,
                        hint: "Enter alliance name",
                        glass: glass,
                        text: text,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Alliance name is required";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Tag
                    Text("Alliance Tag (2–4 letters)",
                        style: TextStyle(color: text.secondary, fontSize: 14)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _tagController,
                      enabled: !_isSubmitting,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(4),
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                      ],
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDecoration(
                        context,
                        hint: "TAG",
                        glass: glass,
                        text: text,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Alliance tag is required";
                        }
                        if (value.length < 2 || value.length > 4) {
                          return "Tag must be 2 to 4 letters (a–z or A–Z)";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Description
                    Text("Description (optional)",
                        style: TextStyle(color: text.secondary, fontSize: 14)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descController,
                      enabled: !_isSubmitting,
                      maxLines: 4,
                      maxLength: 300,
                      decoration: _inputDecoration(
                        context,
                        hint: "Tell others what your alliance is about",
                        glass: glass,
                        text: text,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TokenIconButton(
                        variant: TokenButtonVariant.primary,
                        glass: glass,
                        text: text,
                        buttons: buttons, // <-- themed size/colors/radius
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
                        label: Text(_isSubmitting ? "Creating..." : "Create Alliance"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tokenized input decoration (local helper).
/// If you want this app-wide, we can extract into `token_panels.dart` or a new `token_inputs.dart`.
InputDecoration _inputDecoration(
    BuildContext context, {
      required String hint,
      required GlassTokens glass,
      required TextOnGlassTokens text,
    }) {
  final fillAlpha = glass.mode == SurfaceMode.solid
      ? 1.0
      : (glass.opacity <= 0.02 ? 0.06 : glass.opacity * 0.5);

  final baseBorderColor =
      glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity);

  OutlineInputBorder border([double width = 1.0]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: baseBorderColor, width: width),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: text.subtle),
    counterStyle: TextStyle(color: text.subtle),
    filled: true,
    fillColor: glass.baseColor.withValues(alpha: fillAlpha),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    enabledBorder: border(),
    focusedBorder: border(1.2),
    disabledBorder: border(),
    errorBorder: border(1.0),
    focusedErrorBorder: border(1.2),
  );
}
