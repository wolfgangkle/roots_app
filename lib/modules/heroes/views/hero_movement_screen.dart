import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/functions/start_hero_movement.dart';
import 'package:roots_app/modules/heroes/views/hero_details_screen.dart';
import 'package:roots_app/modules/heroes/widgets/hero_mini_map_overlay.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/helpers/responsive_push.dart';

class HeroMovementScreen extends StatefulWidget {
  final HeroModel hero;

  const HeroMovementScreen({super.key, required this.hero});

  @override
  State<HeroMovementScreen> createState() => _HeroMovementScreenState();
}

class _HeroMovementScreenState extends State<HeroMovementScreen> {
  final List<Offset> _waypoints = [];
  late Offset _cursorPos;
  bool _isSending = false;

  Offset get heroStart => Offset(widget.hero.tileX.toDouble(), widget.hero.tileY.toDouble());

  @override
  void initState() {
    super.initState();
    _cursorPos = heroStart;

    if (widget.hero.destinationX != null && widget.hero.destinationY != null) {
      _waypoints.add(Offset(widget.hero.destinationX!.toDouble(), widget.hero.destinationY!.toDouble()));
    }
    if (widget.hero.movementQueue != null) {
      _waypoints.addAll(widget.hero.movementQueue!.map((wp) =>
          Offset((wp['x'] as num).toDouble(), (wp['y'] as num).toDouble())));
    }
  }

  bool isHeroTile(int x, int y) => x == widget.hero.tileX && y == widget.hero.tileY;
  bool isWaypoint(int x, int y) => _waypoints.contains(Offset(x.toDouble(), y.toDouble()));

  void _addWaypoint(int x, int y) {
    final pos = Offset(x.toDouble(), y.toDouble());
    if (pos == _cursorPos || _waypoints.contains(pos)) return;

    setState(() {
      _waypoints.add(pos);
      _cursorPos = pos;
    });
  }

  void _removeLastWaypoint() {
    if (_waypoints.isNotEmpty) {
      setState(() {
        _cursorPos = _waypoints.length == 1 ? heroStart : _waypoints[_waypoints.length - 2];
        _waypoints.removeLast();
      });
    }
  }

  void _clearAllWaypoints() {
    setState(() {
      _waypoints.clear();
      _cursorPos = heroStart;
    });
  }

  void _confirmMovement() async {
    if (_waypoints.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final first = _waypoints.first;
    final queue = _waypoints.skip(1).map((wp) => {
      'x': wp.dx.toInt(),
      'y': wp.dy.toInt(),
    }).toList();

    try {
      final success = await startHeroMovements(
        heroId: widget.hero.id,
        destinationX: first.dx.toInt(),
        destinationY: first.dy.toInt(),
        movementQueue: queue,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚶‍♂️ Hero is on the move!')),
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
          final controller = Provider.of<MainContentController>(context, listen: false);
          controller.setCustomContent(HeroDetailsScreen(hero: updatedHero));
        }
      } else {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to start movement')),
        );
      }
    } catch (e, stackTrace) {
      print('🧨 Exception in startHeroMovements: $e');
      print(stackTrace);

      setState(() => _isSending = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔥 Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileX = _cursorPos.dx.toInt();
    final tileY = _cursorPos.dy.toInt();
    final isMobileLayout = isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Waypoints'),
        automaticallyImplyLeading: isMobileLayout,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          /// 🗺️ Tactical Mini Map (readonly)
          HeroMiniMapOverlay(
            hero: widget.hero,
            waypoints: _waypoints,
          ),

          const SizedBox(height: 16),
          Center(child: Text("Current Grid Center: ($tileX, $tileY)")),
          const SizedBox(height: 8),

          /// 🧭 3x3 Movement Grid
          Table(
            defaultColumnWidth: const FixedColumnWidth(60),
            children: List.generate(3, (row) {
              return TableRow(
                children: List.generate(3, (col) {
                  final x = tileX - 1 + col;
                  final y = tileY - 1 + row;
                  final isHero = isHeroTile(x, y);
                  final isSelected = isWaypoint(x, y);

                  return GestureDetector(
                    onTap: () => _addWaypoint(x, y),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      height: 60,
                      decoration: BoxDecoration(
                        color: isHero
                            ? Colors.blueAccent
                            : isSelected
                            ? Colors.green
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black45),
                      ),
                      child: Center(
                        child: Text(isHero ? "🧙" : "($x, $y)"),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),

          const SizedBox(height: 24),

          /// 📜 Waypoint List in a scrollable container
          if (_waypoints.isNotEmpty)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text("Waypoints:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._waypoints.map((wp) => Text("• (${wp.dx.toInt()}, ${wp.dy.toInt()})")),
                  ],
                ),
              ),
            ),

          /// 🧭 Buttons (always visible)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: (_waypoints.isEmpty || _isSending) ? null : _confirmMovement,
                  icon: const Icon(Icons.check),
                  label: Text(widget.hero.state == 'moving' ? "Update Journey" : "Start Journey"),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: _waypoints.isEmpty ? null : _removeLastWaypoint,
                  icon: const Icon(Icons.undo),
                  label: const Text("Undo"),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _waypoints.isEmpty ? null : _clearAllWaypoints,
                  icon: const Icon(Icons.clear_all),
                  label: const Text("Clear All"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
