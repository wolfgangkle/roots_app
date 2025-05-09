import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/functions/start_hero_movement.dart';
import 'package:roots_app/modules/heroes/views/hero_details_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/helpers/responsive_push.dart';

class HeroMovementScreen extends StatefulWidget {
  final HeroModel hero;

  const HeroMovementScreen({super.key, required this.hero});

  @override
  State<HeroMovementScreen> createState() => _HeroMovementScreenState();
}

class _HeroMovementScreenState extends State<HeroMovementScreen> {
  final List<Map<String, dynamic>> _waypoints = [];
  bool _isSending = false;

  Offset get heroStart =>
      Offset(widget.hero.tileX.toDouble(), widget.hero.tileY.toDouble());

  @override
  void initState() {
    super.initState();

    if (widget.hero.destinationX != null && widget.hero.destinationY != null) {
      _waypoints.add({
        'x': widget.hero.destinationX,
        'y': widget.hero.destinationY,
      });
    }

    if (widget.hero.movementQueue != null) {
      _waypoints.addAll(widget.hero.movementQueue!);
    }
  }

  void _confirmMovement() async {
    if (_waypoints.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final first = _waypoints.first;
    if (!first.containsKey('x') || !first.containsKey('y')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('🚫 First waypoint must be a tile coordinate.')),
      );
      setState(() => _isSending = false);
      return;
    }

    final destinationX = first['x'] as int;
    final destinationY = first['y'] as int;
    final queue = _waypoints.skip(1).toList();

    try {
      final success = await startHeroMovements(
        heroId: widget.hero.id,
        destinationX: destinationX,
        destinationY: destinationY,
        movementQueue: queue,
      );

      if (!mounted) return;

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚶‍♂️ Hero is on the move!')),
        );

        final updatedDoc = await widget.hero.ref.get();
        if (!mounted) return;

        final updatedHero = HeroModel.fromFirestore(
          updatedDoc.id,
          updatedDoc.data()! as Map<String, dynamic>,
        );

        if (isMobile(context)) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => HeroDetailsScreen(hero: updatedHero)),
          );
        } else {
          final controller =
          Provider.of<MainContentController>(context, listen: false);
          controller.setCustomContent(HeroDetailsScreen(hero: updatedHero));
        }
      } else {
        if (!mounted) return;
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to start movement')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🧨 Exception in startHeroMovements: $e');
      debugPrint(stackTrace.toString());
      setState(() => _isSending = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔥 Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hero Movement')),
      body: Center(
        child: ElevatedButton(
          onPressed: _confirmMovement,
          child: const Text("Send Hero"),
        ),
      ),
    );
  }
}
