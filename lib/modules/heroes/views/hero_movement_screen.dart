import 'package:flutter/material.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/functions/start_hero_movement.dart';

class HeroMovementScreen extends StatefulWidget {
  final HeroModel hero;

  const HeroMovementScreen({super.key, required this.hero});

  @override
  State<HeroMovementScreen> createState() => _HeroMovementScreenState();
}

class _HeroMovementScreenState extends State<HeroMovementScreen> {
  final List<Offset> _waypoints = [];
  late Offset _cursorPos; // 🧭 Current center of the grid

  Offset get heroStart => Offset(widget.hero.tileX.toDouble(), widget.hero.tileY.toDouble());

  @override
  void initState() {
    super.initState();
    _cursorPos = heroStart;
  }

  bool isHeroTile(int x, int y) => x == widget.hero.tileX && y == widget.hero.tileY;
  bool isWaypoint(int x, int y) => _waypoints.contains(Offset(x.toDouble(), y.toDouble()));

  void _addWaypoint(int x, int y) {
    final pos = Offset(x.toDouble(), y.toDouble());

    if (pos == _cursorPos) return; // Don't add current cursor tile
    if (_waypoints.contains(pos)) return; // Avoid duplicates

    setState(() {
      _waypoints.add(pos);
      _cursorPos = pos; // 🔄 Shift grid center
    });
  }

  void _removeLastWaypoint() {
    if (_waypoints.isNotEmpty) {
      setState(() {
        _cursorPos = _waypoints.length == 1
            ? heroStart
            : _waypoints[_waypoints.length - 2];
        _waypoints.removeLast();
      });
    }
  }

  void _confirmMovement() async {
    if (_waypoints.isEmpty) return;

    final first = _waypoints.first;
    final queue = _waypoints.skip(1).map((wp) => {
      'x': wp.dx.toInt(),
      'y': wp.dy.toInt(),
    }).toList();

    final success = await startHeroMovement(
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
      Navigator.of(context).pop(); // Or use setCustomContent if you're on desktop
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to start movement')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileX = _cursorPos.dx.toInt();
    final tileY = _cursorPos.dy.toInt();

    return Scaffold(
      appBar: AppBar(title: const Text('Select Waypoints')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Center(child: Text("Current Grid Center: ($tileX, $tileY)")),
          const SizedBox(height: 8),

          /// 🗺️ 3x3 Grid
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

          /// 📜 Waypoint List
          if (_waypoints.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Waypoints:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._waypoints.map((wp) => Text("• (${wp.dx.toInt()}, ${wp.dy.toInt()})")),
                ],
              ),
            ),

          const Spacer(),

          /// 🧭 Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _waypoints.isEmpty ? null : _confirmMovement,
                  icon: const Icon(Icons.check),
                  label: const Text("Start Journey"),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: _waypoints.isEmpty ? null : _removeLastWaypoint,
                  icon: const Icon(Icons.undo),
                  label: const Text("Undo"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
