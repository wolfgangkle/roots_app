import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

// Define tile types and possible visual variants.
enum TileType { plains, water, mountain, forest, snow, stone }
enum TileVariant {
  full,
  diagonalTopLeft,
  diagonalTopRight,
  diagonalBottomLeft,
  diagonalBottomRight
}

// The tile model stores the type and variant.
class Tile {
  final TileType type;
  final TileVariant variant;
  Tile({required this.type, this.variant = TileVariant.full});

  // Helpful for copying with modifications.
  Tile copyWith({TileType? type, TileVariant? variant}) {
    return Tile(
      type: type ?? this.type,
      variant: variant ?? this.variant,
    );
  }
}

class MapEditorScreen extends StatefulWidget {
  const MapEditorScreen({super.key});

  @override
  State<MapEditorScreen> createState() => _MapEditorScreenState();
}

class _MapEditorScreenState extends State<MapEditorScreen> {
  static const int mapSize = 100;
  static const double tileSize = 20;
  static const double minimapSize = 200;

  final TransformationController _transformController = TransformationController();
  final GlobalKey _canvasKey = GlobalKey();

  late List<List<Tile>> mapGrid;
  TileType selectedTileType = TileType.plains;
  TileVariant selectedVariant = TileVariant.full;
  bool showGrid = true;

  @override
  void initState() {
    super.initState();
    mapGrid = List.generate(
      mapSize,
          (_) => List.generate(mapSize, (_) => Tile(type: TileType.plains)),
    );
  }

  // Returns the base color for tile types that use a solid color.
  Color getBaseColor(TileType type) {
    switch (type) {
      case TileType.plains:
        return Colors.green;
      case TileType.water:
        return Colors.blue;
      case TileType.mountain:
        return Colors.black;
      default:
        return Colors.transparent; // Icon-based tiles handle their background separately.
    }
  }

  // Returns the background color for icon-based tiles.
  Color getIconBackground(TileType type) {
    switch (type) {
      case TileType.forest:
        return Colors.green.shade200;
      case TileType.snow:
        return Colors.white;
      case TileType.stone:
        return Colors.grey.shade300;
      default:
        return Colors.transparent;
    }
  }

  // Returns an icon for icon-based tile types.
  IconData? getTileIcon(TileType type) {
    switch (type) {
      case TileType.forest:
        return Icons.park;
      case TileType.snow:
        return Icons.ac_unit;
      case TileType.stone:
        return Icons.landscape;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ Map Editor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_on),
            tooltip: 'Toggle Grid',
            onPressed: () => setState(() => showGrid = !showGrid),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _importMap,
            tooltip: 'Import Map (placeholder)',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _exportMap,
            tooltip: 'Export Map (placeholder)',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTileSelector(),
          if (selectedTileType == TileType.water || selectedTileType == TileType.mountain)
            _buildVariantSelector(),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                // 🟩 Main Map Area
                Expanded(
                  flex: 4,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest.shortestSide.clamp(600.0, 1600.0);
                      return Center(
                        child: Container(
                          width: size,
                          height: size,
                          color: Colors.black12,
                          child: GestureDetector(
                            key: _canvasKey,
                            onTapDown: (details) {
                              final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                              if (box == null) return;

                              final localPos = box.globalToLocal(details.globalPosition);
                              final scenePos = _transformController.toScene(localPos);

                              final x = (scenePos.dx / _MapEditorScreenState.tileSize).floor();
                              final y = (scenePos.dy / _MapEditorScreenState.tileSize).floor();

                              debugPrint('Tapped scene at $scenePos → tile ($x, $y)');

                              if (x >= 0 && x < mapSize && y >= 0 && y < mapSize) {
                                setState(() {
                                  TileVariant variant = TileVariant.full;
                                  if (selectedTileType == TileType.water || selectedTileType == TileType.mountain) {
                                    variant = selectedVariant;
                                  }
                                  mapGrid[y][x] = Tile(type: selectedTileType, variant: variant);
                                });
                              }
                            },
                            child: InteractiveViewer(
                              transformationController: _transformController,
                              boundaryMargin: const EdgeInsets.all(1000),
                              minScale: 0.1,
                              maxScale: 2.5,
                              child: CustomPaint(
                                size: Size(mapSize * _MapEditorScreenState.tileSize,
                                    mapSize * _MapEditorScreenState.tileSize),
                                painter: MapPainter(
                                  mapGrid: mapGrid,
                                  showGrid: showGrid,
                                  getBaseColor: getBaseColor,
                                  getIconBackground: getIconBackground,
                                  getTileIcon: getTileIcon,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 🧭 Sidebar with Minimap
                SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      SizedBox(
                        width: _MapEditorScreenState.minimapSize,
                        height: _MapEditorScreenState.minimapSize,
                        child: CustomPaint(
                          painter: MinimapPainter(
                            mapGrid: mapGrid,
                            viewTransform: _transformController.value,
                            mapSize: mapSize,
                            tileSize: _MapEditorScreenState.tileSize,
                            minimapSize: _MapEditorScreenState.minimapSize,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Export Map'),
                        onPressed: _exportMap,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload),
                        label: const Text('Import Map'),
                        onPressed: _importMap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build tile selector chips.
  Widget _buildTileSelector() {
    final List<TileType> tileTypes = TileType.values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: tileTypes.map((tileType) {
          String label = tileType.toString().split('.').last;
          IconData? iconData = getTileIcon(tileType);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: iconData != null
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconData, size: 18),
                  const SizedBox(width: 4),
                  Text(label),
                ],
              )
                  : Text(label),
              selected: selectedTileType == tileType,
              selectedColor: Colors.white70,
              onSelected: (_) {
                setState(() {
                  selectedTileType = tileType;
                  // Reset variant selection when switching tile types.
                  selectedVariant = TileVariant.full;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // Build variant selector chips for water and mountain tiles.
  Widget _buildVariantSelector() {
    final variants = TileVariant.values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: variants.map((variant) {
          String label;
          Widget iconWidget;
          switch (variant) {
            case TileVariant.full:
              label = 'Full';
              iconWidget = const Icon(Icons.crop_square, size: 18);
              break;
            case TileVariant.diagonalTopLeft:
              label = 'Top-Left';
              iconWidget = const Icon(Icons.change_history, size: 18);
              break;
            case TileVariant.diagonalTopRight:
              label = 'Top-Right';
              iconWidget = const RotatedBox(
                quarterTurns: 1,
                child: Icon(Icons.change_history, size: 18),
              );
              break;
            case TileVariant.diagonalBottomLeft:
              label = 'Bottom-Left';
              iconWidget = const RotatedBox(
                quarterTurns: 3,
                child: Icon(Icons.change_history, size: 18),
              );
              break;
            case TileVariant.diagonalBottomRight:
              label = 'Bottom-Right';
              iconWidget = const RotatedBox(
                quarterTurns: 2,
                child: Icon(Icons.change_history, size: 18),
              );
              break;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconWidget,
                  const SizedBox(width: 4),
                  Text(label),
                ],
              ),
              selected: selectedVariant == variant,
              selectedColor: Colors.white70,
              onSelected: (_) {
                setState(() {
                  selectedVariant = variant;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _exportMap() {
    debugPrint('🧾 Map Export:');
    for (final row in mapGrid) {
      debugPrint(row
          .map((tile) =>
      '${tile.type.toString().split('.').last}[${tile.variant.toString().split('.').last}]')
          .join(','));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map exported to debug console!')),
    );
  }

  void _importMap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import not yet implemented 😅')),
    );
  }
}

class MapPainter extends CustomPainter {
  final List<List<Tile>> mapGrid;
  final bool showGrid;
  final Color Function(TileType) getBaseColor;
  final Color Function(TileType) getIconBackground;
  final IconData? Function(TileType) getTileIcon;

  MapPainter({
    required this.mapGrid,
    required this.showGrid,
    required this.getBaseColor,
    required this.getIconBackground,
    required this.getTileIcon,
  });

  // Returns the filled triangle path based on the variant.
  Path _getFilledPath(double x, double y, double ts, TileVariant variant) {
    switch (variant) {
      case TileVariant.diagonalTopLeft:
        return Path()..moveTo(x, y)..lineTo(x + ts, y)..lineTo(x, y + ts)..close();
      case TileVariant.diagonalTopRight:
        return Path()..moveTo(x + ts, y)..lineTo(x + ts, y + ts)..lineTo(x, y)..close();
      case TileVariant.diagonalBottomLeft:
        return Path()..moveTo(x, y + ts)..lineTo(x, y)..lineTo(x + ts, y + ts)..close();
      case TileVariant.diagonalBottomRight:
        return Path()..moveTo(x + ts, y + ts)..lineTo(x + ts, y)..lineTo(x, y + ts)..close();
      default:
        return Path();
    }
  }

  // Returns the complementary triangle path.
  Path _getComplementPath(double x, double y, double ts, TileVariant variant) {
    switch (variant) {
      case TileVariant.diagonalTopLeft:
        return Path()..moveTo(x + ts, y)..lineTo(x + ts, y + ts)..lineTo(x, y + ts)..close();
      case TileVariant.diagonalTopRight:
        return Path()..moveTo(x, y)..lineTo(x, y + ts)..lineTo(x + ts, y + ts)..close();
      case TileVariant.diagonalBottomLeft:
        return Path()..moveTo(x, y)..lineTo(x + ts, y)..lineTo(x + ts, y + ts)..close();
      case TileVariant.diagonalBottomRight:
        return Path()..moveTo(x, y)..lineTo(x + ts, y)..lineTo(x, y + ts)..close();
      default:
        return Path();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double ts = _MapEditorScreenState.tileSize;
    final Paint paint = Paint();

    for (int y = 0; y < mapGrid.length; y++) {
      for (int x = 0; x < mapGrid[y].length; x++) {
        final tile = mapGrid[y][x];
        final iconData = getTileIcon(tile.type);

        // For icon-based tiles (forest, snow, stone), draw a background then center the icon.
        if (iconData != null) {
          paint.color = getIconBackground(tile.type);
          canvas.drawRect(Rect.fromLTWH(x * ts, y * ts, ts, ts), paint);

          final textPainter = TextPainter(
            text: TextSpan(
              text: String.fromCharCode(iconData.codePoint),
              style: TextStyle(
                fontSize: ts * 0.8,
                fontFamily: iconData.fontFamily,
                package: iconData.fontPackage,
                color: tile.type == TileType.snow ? Colors.black : Colors.black87,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          final offset = Offset(
            x * ts + (ts - textPainter.width) / 2,
            y * ts + (ts - textPainter.height) / 2,
          );
          textPainter.paint(canvas, offset);
        } else {
          // For regular color-based tiles: plains, water, mountain.
          if (tile.variant != TileVariant.full &&
              (tile.type == TileType.water || tile.type == TileType.mountain)) {
            final baseColor = getBaseColor(tile.type);
            final lighterColor = tile.type == TileType.water
                ? Colors.blue.shade100
                : Colors.grey.shade400;
            final filledPath = _getFilledPath(x * ts, y * ts, ts, tile.variant);
            final complementPath = _getComplementPath(x * ts, y * ts, ts, tile.variant);
            paint.color = baseColor;
            canvas.drawPath(filledPath, paint);
            paint.color = lighterColor;
            canvas.drawPath(complementPath, paint);
          } else {
            // Full tile fill.
            paint.color = getBaseColor(tile.type);
            canvas.drawRect(Rect.fromLTWH(x * ts, y * ts, ts, ts), paint);
          }
        }

        // Optionally draw the grid overlay.
        if (showGrid) {
          final gridPaint = Paint()
            ..color = Colors.white.withOpacity(0.1)
            ..style = PaintingStyle.stroke;
          canvas.drawRect(Rect.fromLTWH(x * ts, y * ts, ts, ts), gridPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.mapGrid != mapGrid || oldDelegate.showGrid != showGrid;
  }
}

class MinimapPainter extends CustomPainter {
  final List<List<Tile>> mapGrid;
  final Matrix4 viewTransform;
  final int mapSize;
  final double tileSize;
  final double minimapSize;

  MinimapPainter({
    required this.mapGrid,
    required this.viewTransform,
    required this.mapSize,
    required this.tileSize,
    required this.minimapSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    final double scale = minimapSize / (mapSize * tileSize);

    for (int y = 0; y < mapSize; y++) {
      for (int x = 0; x < mapSize; x++) {
        final tile = mapGrid[y][x];
        Color color;
        if (tile.type == TileType.plains) {
          color = Colors.green;
        } else if (tile.type == TileType.water) {
          color = Colors.blue;
        } else if (tile.type == TileType.mountain) {
          color = Colors.black;
        } else {
          // For icon-based tiles, use their background color.
          switch (tile.type) {
            case TileType.forest:
              color = Colors.green.shade200;
              break;
            case TileType.snow:
              color = Colors.white;
              break;
            case TileType.stone:
              color = Colors.grey.shade300;
              break;
            default:
              color = Colors.transparent;
          }
        }
        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(x * tileSize * scale, y * tileSize * scale, tileSize * scale, tileSize * scale),
          paint,
        );
      }
    }

    final inv = Matrix4.inverted(viewTransform);
    final topLeft = inv.transform3(Vector3.zero()).xy;
    final bottomRight =
        inv.transform3(Vector3(tileSize * mapSize, tileSize * mapSize, 0)).xy;

    final double left = topLeft.x * scale;
    final double top = topLeft.y * scale;
    final double width = (bottomRight.x - topLeft.x) * scale;
    final double height = (bottomRight.y - topLeft.y) * scale;

    canvas.drawRect(
      Rect.fromLTWH(left, top, width, height),
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant MinimapPainter oldDelegate) => true;
}
