import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/views/hero_details_screen.dart';

import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';
import 'package:roots_app/theme/tokens.dart';

class CreateCompanionScreen extends StatefulWidget {
  const CreateCompanionScreen({super.key});

  @override
  State<CreateCompanionScreen> createState() => _CreateCompanionScreenState();
}

class _CreateCompanionScreenState extends State<CreateCompanionScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedVillageId;
  List<Map<String, dynamic>> _villages = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadVillages();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadVillages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _villages = [];
      });
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .get();

    final villages = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    setState(() {
      _villages = villages;
      _selectedVillageId = villages.isNotEmpty ? villages.first['id'] : null;
      _isLoading = false;
    });
  }

  Future<void> _createCompanion() async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = Provider.of<MainContentController>(context, listen: false);

    final name = _nameController.text.trim();

    if (_selectedVillageId == null || name.length < 3) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Please enter a valid name and select a village.")),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final village = _villages.firstWhere((v) => v['id'] == _selectedVillageId);
      final callable = FirebaseFunctions.instance.httpsCallable('createCompanion');
      final result = await callable.call({
        'tileX': village['tileX'],
        'tileY': village['tileY'],
        'name': name,
      });

      final heroId = result.data['heroId'];
      final heroDoc = await FirebaseFirestore.instance.collection('heroes').doc(heroId).get();

      if (!mounted) return;

      if (heroDoc.exists) {
        final hero = HeroModel.fromFirestore(heroDoc.id, heroDoc.data()!);
        controller.setCustomContent(HeroDetailsScreen(hero: hero));
        messenger.showSnackBar(const SnackBar(content: Text("Companion created successfully!")));
      } else {
        messenger.showSnackBar(const SnackBar(content: Text("Companion created, but not found.")));
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      messenger.showSnackBar(SnackBar(content: Text("Failed to create companion: $e")));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔁 live tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final pad = kStyle.card.padding;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final header = Text(
      'Create Companion',
      style: TextStyle(
        color: text.primary,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
    );

    final nameField = TextField(
      controller: _nameController,
      style: TextStyle(color: text.primary), // ensure readable text color
      decoration: InputDecoration(
        labelText: "Companion name",
        hintText: "Enter companion name",
        labelStyle: TextStyle(color: text.secondary),
        hintStyle: TextStyle(color: text.subtle),
        border: const OutlineInputBorder(),
      ),
    );

    // 🔽 Tokenized popup (same style as the 3-dot menu)
    final villageSelect = _VillagePopupSelect(
      villages: _villages,
      selectedVillageId: _selectedVillageId,
      onSelected: (id) => setState(() => _selectedVillageId = id),
      glass: glass,
      text: text,
    );

    final actionBar = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TokenIconButton(
          glass: glass,
          text: text,
          buttons: buttons,
          variant: TokenButtonVariant.primary,
          icon: _isCreating
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.group_add),
          label: Text(_isCreating ? 'Creating...' : 'Create Companion'),
          onPressed: _isCreating ? null : _createCompanion,
        ),
      ],
    );

    final content = _villages.isEmpty
        ? Center(
      child: TokenPanel(
        glass: glass,
        text: text,
        padding: EdgeInsets.fromLTRB(pad.left, 16, pad.right, 16),
        child: Text(
          "No villages available. Found or claim a village first.",
          textAlign: TextAlign.center,
          style: TextStyle(color: text.secondary),
        ),
      ),
    )
        : TokenPanel(
      glass: glass,
      text: text,
      padding: EdgeInsets.fromLTRB(pad.left, 16, pad.right, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          nameField,
          const SizedBox(height: 16),

          // 🧭 Tokenized village select
          villageSelect,
          const SizedBox(height: 20),

          TokenDivider(glass: glass, text: text),
          const SizedBox(height: 12),
          actionBar,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: text.primary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad.left, pad.top, pad.right, pad.bottom),
            child: SingleChildScrollView(child: content),
          ),
        ),
      ),
    );
  }
}

/// Tokenized popup select, styled like the alliance 3-dot menu.
class _VillagePopupSelect extends StatelessWidget {
  final List<Map<String, dynamic>> villages;
  final String? selectedVillageId;
  final ValueChanged<String> onSelected;
  final GlassTokens glass;
  final TextOnGlassTokens text;

  const _VillagePopupSelect({
    required this.villages,
    required this.selectedVillageId,
    required this.onSelected,
    required this.glass,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    // Popup surface like _LeaderMenuButton
    final double fillAlpha = glass.mode == SurfaceMode.solid
        ? 1.0
        : (glass.opacity <= 0.02 ? 0.06 : glass.opacity);

    final Color menuBg = glass.baseColor.withValues(alpha: fillAlpha);
    final ShapeBorder menuShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: glass.showBorder
          ? BorderSide(
        color: (glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity))
            .withValues(alpha: 0.6),
        width: 1,
      )
          : BorderSide.none,
    );

    final popupTheme = PopupMenuThemeData(
      color: menuBg,
      surfaceTintColor: Colors.transparent,
      elevation: glass.mode == SurfaceMode.solid ? 1.0 : 0.0,
      shape: menuShape,
      textStyle: TextStyle(color: text.primary, fontSize: 14),
    );

    final selected = villages.where((v) => v['id'] == selectedVillageId).cast<Map<String, dynamic>?>().firstOrNull;

    return Theme(
      data: Theme.of(context).copyWith(popupMenuTheme: popupTheme),
      child: PopupMenuButton<String>(
        tooltip: 'Select spawn village',
        onSelected: onSelected,
        itemBuilder: (context) => villages.map((v) {
          final isSel = v['id'] == selectedVillageId;
          return PopupMenuItem<String>(
            value: v['id'],
            child: Row(
              children: [
                Icon(isSel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 16, color: isSel ? text.primary : text.subtle),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${v['name']} (${v['tileX']}, ${v['tileY']})",
                    style: TextStyle(
                      color: isSel ? text.primary : text.secondary,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        // Make the whole row look like an "input"
        child: TokenPanel(
          glass: glass,
          text: text,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected == null
                      ? "Select spawn village"
                      : "${selected['name']} (${selected['tileX']}, ${selected['tileY']})",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected == null ? text.subtle : text.primary, // ✅ readable color
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_drop_down, color: text.primary),
            ],
          ),
        ),
      ),
    );
  }
}

