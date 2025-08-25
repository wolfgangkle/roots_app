import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/models/hero_group_model.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/heroes/views/hero_details_screen.dart';
import 'package:roots_app/screens/helpers/responsive_push.dart';
import 'package:roots_app/modules/heroes/widgets/hero_group_movement_minimap.dart';
import 'package:roots_app/modules/heroes/widgets/hero_group_movement_grid.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

class HeroGroupMovementScreen extends StatefulWidget {
  final HeroModel hero;
  final HeroGroupModel group;

  const HeroGroupMovementScreen({
    super.key,
    required this.hero,
    required this.group,
  });

  @override
  State<HeroGroupMovementScreen> createState() => HeroGroupMovementScreenState();
}

class HeroGroupMovementScreenState extends State<HeroGroupMovementScreen> {
  final List<Map<String, dynamic>> _waypoints = [];
  final _minimapKey = GlobalKey<HeroGroupMovementMiniMapState>();

  bool _isSending = false;
  Set<String> _villageTiles = {};

  late int _gridCenterX;
  late int _gridCenterY;

  @override
  void initState() {
    super.initState();

    _waypoints.addAll(widget.group.movementQueue);

    if (_waypoints.isNotEmpty) {
      final Map<String, dynamic> last = _waypoints.last;
      _gridCenterX = (last['x'] as int?) ?? widget.group.tileX;
      _gridCenterY = (last['y'] as int?) ?? widget.group.tileY;
    } else {
      _gridCenterX = widget.group.tileX;
      _gridCenterY = widget.group.tileY;
    }

    _fetchVillageTiles();
  }

  Future<void> _fetchVillageTiles() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('mapTiles')
        .where('villageId', isGreaterThan: '')
        .get();

    if (!mounted) return;

    setState(() {
      _villageTiles = snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  void _addStep(int x, int y) {
    setState(() {
      _waypoints.add({
        'action': 'walk',
        'x': x,
        'y': y,
      });
      _gridCenterX = x;
      _gridCenterY = y;
    });

    _minimapKey.currentState?.centerOnTile(x, y);
  }

  void _clearWaypoints() {
    if (_waypoints.isNotEmpty) {
      final Map<String, dynamic> currentStep = _waypoints.first;

      setState(() {
        _waypoints
          ..clear()
          ..add(currentStep);

        _gridCenterX = (currentStep['x'] as int?) ?? widget.group.tileX;
        _gridCenterY = (currentStep['y'] as int?) ?? widget.group.tileY;
      });

      _minimapKey.currentState?.centerOnTile(_gridCenterX, _gridCenterY);
    } else {
      setState(() {
        _gridCenterX = widget.group.tileX;
        _gridCenterY = widget.group.tileY;
      });

      _minimapKey.currentState?.centerOnTile(_gridCenterX, _gridCenterY);
    }
  }

  Future<void> _sendMovement() async {
    if (_waypoints.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final isMoving = widget.group.arrivesAt != null;
      final callable = FirebaseFunctions.instance.httpsCallable(
        isMoving ? 'editHeroGroupMovement' : 'startHeroGroupMovement',
      );

      final result = await callable.call({
        'groupId': widget.group.id,
        'movementQueue': _waypoints,
      });

      if (!mounted) return;

      final success = result.data['success'] == true;

      if (success) {
        final style = kStyle;
        final glass = style.glass;
        final text = style.textOnGlass;

        ScaffoldMessenger.of(context).showSnackBar(
          buildTokenSnackBar(
            message: isMoving
                ? '✅ Movement queue updated!'
                : '🚶‍♂️ Hero group is on the move!',
            glass: glass,
            text: text,
          ),
        );

        final updatedDoc = await widget.hero.ref.get();
        if (!mounted) return;

        final updatedHero = HeroModel.fromFirestore(
          updatedDoc.id,
          updatedDoc.data()! as Map<String, dynamic>,
        );

        if (!mounted) return;

        if (isMobile(context)) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HeroDetailsScreen(hero: updatedHero),
            ),
          );
        } else {
          final controller =
          Provider.of<MainContentController>(context, listen: false);
          controller.setCustomContent(HeroDetailsScreen(hero: updatedHero));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to update movement')),
        );
      }
    } catch (e) {
      debugPrint('🧨 Error updating group movement: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔥 Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _cancelMovement() async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      final callable =
      FirebaseFunctions.instance.httpsCallable('cancelHeroGroupMovement');
      final result = await callable.call({
        'groupId': widget.group.id,
      });

      if (!mounted) return;

      final arrivesBackAt = result.data['arrivesBackAt'];

      final style = kStyle;
      final glass = style.glass;
      final text = style.textOnGlass;

      ScaffoldMessenger.of(context).showSnackBar(
        buildTokenSnackBar(
          message: '↩️ Returning to origin (ETA: $arrivesBackAt)',
          glass: glass,
          text: text,
        ),
      );

      final updatedDoc = await widget.hero.ref.get();
      if (!mounted) return;

      final updatedHero = HeroModel.fromFirestore(
        updatedDoc.id,
        updatedDoc.data()! as Map<String, dynamic>,
      );

      if (!mounted) return;

      if (isMobile(context)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HeroDetailsScreen(hero: updatedHero),
          ),
        );
      } else {
        final controller =
        Provider.of<MainContentController>(context, listen: false);
        controller.setCustomContent(HeroDetailsScreen(hero: updatedHero));
      }
    } catch (e) {
      debugPrint('🧨 Error canceling movement: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔥 Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
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

    final isCurrentlyMoving = widget.group.arrivesAt != null;
    final eta = widget.group.arrivesAt;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: text.primary),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 8,
          16,
          16,
        ),
        children: [
          // ── Status / Location panel
          TokenPanel(
            glass: glass,
            text: text,
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, 12),
              child: Row(
                children: [
                  const Icon(Icons.route),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tile: (${widget.group.tileX}, ${widget.group.tileY})'
                              '${widget.group.insideVillage == true ? " • In Village" : ""}',
                          style: TextStyle(
                            color: text.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCurrentlyMoving
                              ? 'Moving • ETA: ${eta?.toLocal().toIso8601String().substring(11, 19)}'
                              : 'Idle',
                          style: TextStyle(color: text.secondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrentlyMoving
                          ? Colors.orange.withValues(alpha: 0.18)
                          : Colors.green.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: (isCurrentlyMoving ? Colors.orange : Colors.green)
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      isCurrentlyMoving ? 'Moving' : 'Idle',
                      style: TextStyle(
                        color:
                        isCurrentlyMoving ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Mini-map panel
          TokenPanel(
            glass: glass,
            text: text,
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad.left, 10, pad.right, 10),
              child: LayoutBuilder(
                builder: (context, c) {
                  final side = c.maxWidth; // use full panel width
                  return SizedBox(
                    height: side, // square: height == width
                    child: HeroGroupMovementMiniMap(
                      key: _minimapKey,
                      group: widget.group,
                      waypoints: _waypoints,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Grid panel
          TokenPanel(
            glass: glass,
            text: text,
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad.left, 10, pad.right, 10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 280),
                child: HeroGroupMovementGrid(
                  currentX: _gridCenterX,
                  currentY: _gridCenterY,
                  waypoints: _waypoints,
                  insideVillage: widget.group.insideVillage == true,
                  onTapTile: _addStep,
                  villageTiles: _villageTiles,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Controls panel (tokenized buttons)
          TokenPanel(
            glass: glass,
            text: text,
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad.left, 10, pad.right, 10),
              child: Row(
                children: [
                  // Clear (outline)
                  TokenTextButton(
                    variant: TokenButtonVariant.outline,
                    glass: glass,
                    text: text,
                    buttons: buttons,
                    onPressed: _isSending ? null : _clearWaypoints,
                    child: const Text('Clear Path'),
                  ),
                  const Spacer(),
                  // Cancel (danger) if currently moving
                  if (isCurrentlyMoving) ...[
                    TokenButton(
                      variant: TokenButtonVariant.danger,
                      glass: glass,
                      text: text,
                      buttons: buttons,
                      onPressed: _isSending ? null : _cancelMovement,
                      child: _isSending
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation(text.primary),
                        ),
                      )
                          : const Text('Cancel Movement'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Send / Update (primary)
                  TokenIconButton(
                    variant: TokenButtonVariant.primary,
                    glass: glass,
                    text: text,
                    buttons: buttons,
                    onPressed:
                    (_isSending || _waypoints.isEmpty) ? null : _sendMovement,
                    icon: _isSending
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.send),
                    label: Text(_isSending
                        ? 'Sending...'
                        : (isCurrentlyMoving ? 'Update Path' : 'Start Movement')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
