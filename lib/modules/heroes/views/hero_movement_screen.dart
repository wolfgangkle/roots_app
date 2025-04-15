import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/functions/start_hero_movement.dart';
import 'package:roots_app/modules/heroes/views/hero_details_screen.dart';
import 'package:roots_app/modules/heroes/widgets/hero_mini_map_overlay.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/helpers/responsive_push.dart';
import 'package:roots_app/modules/map/constants/terrain_definitions.dart';
import 'package:roots_app/modules/map/models/terrain_type_model.dart';
import 'package:roots_app/modules/map/constants/tier1_map.dart';

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
    if (pos == _cursorPos) return;

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                HeroMiniMapOverlay(hero: widget.hero, waypoints: _waypoints),
                const SizedBox(height: 16),
                Center(child: Text("Current Grid Center: ($tileX, $tileY)")),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final calculatedTileSize = (maxWidth - 32) / 3;
                      final tileSize = calculatedTileSize.clamp(60.0, 100.0);

                      TerrainTypeModel? getTerrain(int x, int y) {
                        final key = '${x}_${y}';
                        final terrainId = tier1Map[key];
                        if (terrainId == null) return null;
                        return terrainDefinitions[terrainId];
                      }

                      return Column(
                        children: List.generate(3, (row) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (col) {
                              final x = tileX - 1 + col;
                              final y = tileY - 1 + row;
                              final isHero = isHeroTile(x, y);
                              final isSelected = isWaypoint(x, y);
                              final terrain = getTerrain(x, y);
                              final isWalkable = terrain?.walkable ?? false;

                              return GestureDetector(
                                onTap: isWalkable ? () => _addWaypoint(x, y) : null,
                                child: Container(
                                  width: tileSize,
                                  height: tileSize,
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: terrain?.color ?? Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: !isWalkable ? Colors.redAccent : Colors.black45,
                                      width: !isWalkable ? 2 : 1,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (terrain?.icon != null)
                                        Icon(terrain!.icon, size: 28, color: Colors.black87),
                                      Positioned(
                                        top: 4,
                                        left: 0,
                                        right: 0,
                                        child: Text(
                                          "($x, $y)",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isHero)
                                        const Positioned(
                                          bottom: 4,
                                          child: Text("🧙", style: TextStyle(fontSize: 20)),
                                        ),
                                      if (isSelected && !isHero)
                                        const Positioned(
                                          bottom: 4,
                                          child: Icon(Icons.location_on, size: 20, color: Colors.redAccent),
                                        ),
                                      if (!isWalkable)
                                        const Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Icon(Icons.lock, size: 16, color: Colors.redAccent),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: (_waypoints.isEmpty || _isSending) ? null : _confirmMovement,
                        icon: const Icon(Icons.check),
                        label: Text(widget.hero.state == 'moving' ? "Update Journey" : "Start Journey"),
                      ),
                      TextButton.icon(
                        onPressed: _waypoints.isEmpty ? null : _removeLastWaypoint,
                        icon: const Icon(Icons.undo),
                        label: const Text("Undo"),
                      ),
                      TextButton.icon(
                        onPressed: _waypoints.isEmpty ? null : _clearAllWaypoints,
                        icon: const Icon(Icons.clear_all),
                        label: const Text("Clear All"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
