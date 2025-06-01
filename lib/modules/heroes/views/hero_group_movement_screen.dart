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
import 'package:roots_app/modules/heroes/widgets/hero_group_movement_controls.dart';

class HeroGroupMovementScreen extends StatefulWidget {
  final HeroModel hero;
  final HeroGroupModel group;

  const HeroGroupMovementScreen({
    super.key,
    required this.hero,
    required this.group,
  });

  @override
  State<HeroGroupMovementScreen> createState() =>
      _HeroGroupMovementScreenState();
}

class _HeroGroupMovementScreenState extends State<HeroGroupMovementScreen> {
  final List<Map<String, dynamic>> _waypoints = [];
  bool _isSending = false;
  Set<String> _villageTiles = {};

  late int _gridCenterX;
  late int _gridCenterY;

  @override
  void initState() {
    super.initState();
    _waypoints.addAll(widget.group.movementQueue ?? []);
    _gridCenterX = widget.group.tileX;
    _gridCenterY = widget.group.tileY;
    _fetchVillageTiles();
  }

  Future<void> _fetchVillageTiles() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('mapTiles')
        .where('villageId', isGreaterThan: '')
        .get();

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
  }

  void _clearWaypoints() {
    setState(() {
      _waypoints.clear();
      _gridCenterX = widget.group.tileX;
      _gridCenterY = widget.group.tileY;
    });
  }

  Future<void> _sendMovement() async {
    if (_waypoints.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final callable =
      FirebaseFunctions.instance.httpsCallable('startHeroGroupMovement');
      final result = await callable.call({
        'groupId': widget.group.id,
        'movementQueue': _waypoints,
      });

      final success = result.data['success'] == true;

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚶‍♂️ Hero group is on the move!')),
        );

        final updatedDoc = await widget.hero.ref.get();
        final updatedHero = HeroModel.fromFirestore(
          updatedDoc.id,
          updatedDoc.data()! as Map<String, dynamic>,
        );

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
          const SnackBar(content: Text('❌ Failed to start movement')),
        );
      }
    } catch (e) {
      debugPrint('🧨 Error starting group movement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔥 Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hero Group Movement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroGroupMovementMiniMap(group: widget.group),
            const SizedBox(height: 12),

            HeroGroupMovementGrid(
              currentX: _gridCenterX,
              currentY: _gridCenterY,
              waypoints: _waypoints,
              insideVillage: widget.group.insideVillage == true,
              onTapTile: _addStep,
              villageTiles: _villageTiles,
            ),

            const SizedBox(height: 16),

            HeroGroupMovementControls(
              onClear: _clearWaypoints,
              onSend: _sendMovement,
              isSending: _isSending,
              waypointCount: _waypoints.length,
            ),
          ],
        ),
      ),
    );
  }
}
