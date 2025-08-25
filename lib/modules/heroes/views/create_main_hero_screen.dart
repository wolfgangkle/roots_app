import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/heroes/functions/create_hero.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/views/hero_details_screen.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';
import 'package:roots_app/theme/tokens.dart';

class CreateMainHeroScreen extends StatefulWidget {
  const CreateMainHeroScreen({super.key});

  @override
  State<CreateMainHeroScreen> createState() => _CreateMainHeroScreenState();
}

class _CreateMainHeroScreenState extends State<CreateMainHeroScreen> {
  String? _selectedVillageId;
  List<Map<String, dynamic>> _villages = [];
  bool _isLoading = true;
  bool _isCreatingHero = false;

  @override
  void initState() {
    super.initState();
    _loadVillages();
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

  Future<void> _createHero() async {
    if (_selectedVillageId == null || _isCreatingHero) return;

    setState(() => _isCreatingHero = true);

    final village = _villages.firstWhere((v) => v['id'] == _selectedVillageId);
    final tileX = village['tileX'];
    final tileY = village['tileY'];

    final heroId = await createHero(
      heroName: 'Main Hero',
      race: 'Human',
      tileX: tileX,
      tileY: tileY,
    );

    setState(() => _isCreatingHero = false);

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final controller = Provider.of<MainContentController>(context, listen: false);

    if (heroId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('heroes')
            .doc(heroId)
            .get();
        final data = doc.data();

        if (data != null) {
          final hero = HeroModel.fromFirestore(doc.id, data);
          controller.setCustomContent(HeroDetailsScreen(hero: hero));
          messenger.showSnackBar(const SnackBar(content: Text('Main hero created!')));
        } else {
          messenger.showSnackBar(const SnackBar(content: Text('Hero created, but data not found.')));
        }
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Error loading hero: $e')));
      }
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('Failed to create hero.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔁 tokens
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
      'Create Main Hero',
      style: TextStyle(
        color: text.primary,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
    );

    final info = Text(
      "Choose a village as the spawn location for your Main Hero (Mage).",
      style: TextStyle(color: text.secondary, fontSize: 14),
    );

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
          icon: _isCreatingHero
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.auto_awesome),
          label: Text(_isCreatingHero ? 'Creating...' : 'Create Main Hero'),
          onPressed: _isCreatingHero ? null : _createHero,
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
          "No villages found. Found or claim a village first.",
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
          const SizedBox(height: 8),
          info,
          const SizedBox(height: 16),
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

/// Same tokenized popup select used in CreateCompanion screen.
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
    // glass/solid aware menu surface (matches your 3-dot menu)
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

    final selected = villages
        .where((v) => v['id'] == selectedVillageId)
        .cast<Map<String, dynamic>?>()
        .firstOrNull;

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
                Icon(
                  isSel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 16,
                  color: isSel ? text.primary : text.subtle,
                ),
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
        // “Input-like” trigger
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
                    color: selected == null ? text.subtle : text.primary,
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
