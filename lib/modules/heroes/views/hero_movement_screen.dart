import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  final List<Map<String, dynamic>> _waypoints = [];
  Set<String> _villageTileKeys = {};
  late Offset _cursorPos;
  bool _isSending = false;

  Offset get heroStart =>
      Offset(widget.hero.tileX.toDouble(), widget.hero.tileY.toDouble());

  @override
  void initState() {
    super.initState();
    _cursorPos = heroStart;
    _loadVillageTiles();

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

  Future<void> _loadVillageTiles() async {
    final snap = await FirebaseFirestore.instance
        .collection('mapTiles')
        .where('villageId', isGreaterThan: '')
        .get();

    setState(() {
      _villageTileKeys = snap.docs.map((doc) => doc.id).toSet();
    });
  }

  bool isHeroTile(int x, int y) =>
      x == widget.hero.tileX && y == widget.hero.tileY;
  bool isWaypoint(int x, int y) =>
      _waypoints.any((wp) => wp['x'] == x && wp['y'] == y);
  bool isVillageTile(int x, int y) => _villageTileKeys.contains('${x}_$y');

  void _addWaypoint(int x, int y) {
    setState(() {
      _waypoints.add({'x': x, 'y': y});
      _cursorPos = Offset(x.toDouble(), y.toDouble());
    });
  }

  void _addActionStep(String action) {
    setState(() {
      _waypoints.add({'action': action});
    });
  }

  void _removeLastWaypoint() {
    if (_waypoints.isNotEmpty) {
      setState(() {
        _waypoints.removeLast();
        if (_waypoints.isNotEmpty) {
          final last = _waypoints.last;
          _cursorPos = last.containsKey('x') && last.containsKey('y')
              ? Offset(
                  (last['x'] as num).toDouble(), (last['y'] as num).toDouble())
              : heroStart;
        } else {
          _cursorPos = heroStart;
        }
      });
    }
  }

  void _clearAllWaypoints() {
    setState(() {
      _waypoints.clear();
      _cursorPos = heroStart;
    });
  }

  void _centerOnHero() {
    setState(() {
      _cursorPos = heroStart;
    });
  }

  Future<void> _triggerHeroArrival(String action) async {
    setState(() => _isSending = true);

    try {
      await widget.hero.ref.update({
        'state': 'moving',
        'movementQueue': [
          {'action': action}
        ],
        'destinationX': widget.hero.tileX,
        'destinationY': widget.hero.tileY,
        'arrivesAt': Timestamp.fromMillisecondsSinceEpoch(0),
      });

      final callable = FirebaseFunctions.instance
          .httpsCallable('processHeroArrivalCallable');
      await callable.call({'heroId': widget.hero.id});

      final updatedDoc = await widget.hero.ref.get();
      final updatedHero = HeroModel.fromFirestore(
          updatedDoc.id, updatedDoc.data()! as Map<String, dynamic>);

      if (!mounted) return;

      if (isMobile(context)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) =>
                  HeroMovementScreen(hero: updatedHero)), // ✅ Stay here
        );
      } else {
        final controller =
            Provider.of<MainContentController>(context, listen: false);
        controller.setCustomContent(
            HeroMovementScreen(hero: updatedHero)); // ✅ Stay here
      }
    } catch (e) {
      print('🔥 Error calling processHeroArrival: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _confirmMovement() async {
    if (_waypoints.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final first = _waypoints.first;
    if (!first.containsKey('x') || !first.containsKey('y')) {
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
                builder: (_) => HeroDetailsScreen(hero: updatedHero)),
          );
        } else {
          final controller =
              Provider.of<MainContentController>(context, listen: false);
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
            constraints:
                BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                HeroMiniMapOverlay(
                  hero: widget.hero,
                  waypoints: _waypoints,
                  centerTileOffset: _cursorPos,
                ),
                const SizedBox(height: 16),
                Center(child: Text("Current Grid Center: ($tileX, $tileY)")),
                const SizedBox(height: 8),

                // 🔁 Always show the 3x3 grid below
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final calculatedTileSize = (maxWidth - 32) / 3;
                      final tileSize = calculatedTileSize.clamp(60.0, 100.0);

                      TerrainTypeModel? getTerrain(int x, int y) {
                        final key = '${x}_$y';
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
                              final isWaypointTile = isWaypoint(x, y);
                              final terrain = getTerrain(x, y);
                              final isVillage = isVillageTile(x, y);
                              final isCenter = x == tileX && y == tileY;

                              final isCurrentHeroTile = isHero && isCenter;
                              final isVillageCenter = isVillage && isCenter;

                              final showExit = isCurrentHeroTile &&
                                  widget.hero.insideVillage;
                              final showEnterImmediate = isCurrentHeroTile &&
                                  !widget.hero.insideVillage &&
                                  _waypoints.isEmpty;
                              final queueEnter =
                                  isVillageCenter && !widget.hero.insideVillage;
                              final showCenterEnterOption = isCenter &&
                                  isVillage &&
                                  !widget.hero.insideVillage;

                              final label = showExit
                                  ? 'Exit Village'
                                  : showEnterImmediate
                                      ? 'Enter Village'
                                      : showCenterEnterOption
                                          ? 'Enter Village'
                                          : '';

                              final shouldFireImmediately = isHero &&
                                  isCenter &&
                                  label == 'Enter Village' &&
                                  _waypoints.isEmpty;
                              final shouldExitImmediately = isHero &&
                                  isCenter &&
                                  label == 'Exit Village' &&
                                  _waypoints.isEmpty;

                              final action = showExit
                                  ? () => _triggerHeroArrival('exitVillage')
                                  : showEnterImmediate
                                      ? () =>
                                          _triggerHeroArrival('enterVillage')
                                      : showCenterEnterOption
                                          ? () => _addActionStep('enterVillage')
                                          : () => _addWaypoint(x, y);

                              final isLockedWhileInsideVillage =
                                  widget.hero.insideVillage &&
                                      !(isCenter && isHero);
                              final clickable = !isLockedWhileInsideVillage &&
                                  (showExit ||
                                      showEnterImmediate ||
                                      showCenterEnterOption ||
                                      (terrain?.walkable ?? false && !isHero));

                              return GestureDetector(
                                onTap: _isSending || !clickable ? null : action,
                                child: Container(
                                  width: tileSize,
                                  height: tileSize,
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color:
                                        terrain?.color ?? Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCenter
                                          ? Colors.blueAccent
                                          : isLockedWhileInsideVillage
                                              ? Colors.redAccent
                                              : Colors.black26,
                                      width: isCenter ? 2 : 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      if (terrain?.icon != null)
                                        Center(
                                            child: Icon(terrain!.icon,
                                                size: 28,
                                                color: Colors.black87)),

                                      if (isVillage)
                                        const Positioned(
                                          top: 4,
                                          left: 4,
                                          child: Text("🏰",
                                              style: TextStyle(fontSize: 16)),
                                        ),

                                      if (isHero)
                                        const Positioned(
                                          bottom: 4,
                                          child: Text("🧙",
                                              style: TextStyle(fontSize: 20)),
                                        ),

                                      // 🔼 Coordinates at top
                                      Positioned(
                                        top: 4,
                                        left: 0,
                                        right: 0,
                                        child: Text(
                                          "($x, $y)",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),

                                      // 🔽 Waypoint marker at bottom-right
                                      if (isWaypointTile)
                                        const Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: Icon(Icons.circle,
                                              size: 8, color: Colors.orange),
                                        ),

                                      // 🧭 Center action (e.g. Enter/Exit Village)
                                      if (label.isNotEmpty)
                                        Center(
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 20),
                                            child: Text(
                                              label,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
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

                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: (_waypoints.isEmpty || _isSending)
                            ? null
                            : _confirmMovement,
                        icon: const Icon(Icons.check),
                        label: Text(widget.hero.state == 'moving'
                            ? "Update Journey"
                            : "Start Journey"),
                      ),
                      TextButton.icon(
                        onPressed: _waypoints.isEmpty || _isSending
                            ? null
                            : _removeLastWaypoint,
                        icon: const Icon(Icons.undo),
                        label: const Text("Undo"),
                      ),
                      TextButton.icon(
                        onPressed: _waypoints.isEmpty || _isSending
                            ? null
                            : _clearAllWaypoints,
                        icon: const Icon(Icons.clear_all),
                        label: const Text("Clear All"),
                      ),
                      TextButton.icon(
                        onPressed: _centerOnHero,
                        icon: const Icon(Icons.my_location),
                        label: const Text("Center on Hero"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_waypoints.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Waypoints:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._waypoints.map((wp) {
                          if (wp.containsKey('action')) {
                            return Text("• Action: ${wp['action']}");
                          } else {
                            return Text("• (${wp['x']}, ${wp['y']})");
                          }
                        }),
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
