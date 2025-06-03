import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/map/constants/tier1_map.dart';
import 'package:roots_app/modules/map/constants/terrain_definitions.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset? _initialFocalPoint;
  Offset _initialOffset = Offset.zero;
  double _initialScale = 1.0;

  List<Map<String, dynamic>> _villages = [];
  late int minX, maxX, minY, maxY;

  @override
  void initState() {
    super.initState();
    _computeMapBounds();
    _loadVillages();
  }

  void _computeMapBounds() {
    final keys = tier1Map.keys;
    final coords = keys.map((k) => k.split('_').map(int.parse).toList()).toList();
    minX = coords.map((c) => c[0]).reduce(min);
    maxX = coords.map((c) => c[0]).reduce(max);
    minY = coords.map((c) => c[1]).reduce(min);
    maxY = coords.map((c) => c[1]).reduce(max);
  }

  Future<void> _loadVillages() async {
    final snapshot = await FirebaseFirestore.instance.collectionGroup('villages').get();
    setState(() {
      _villages = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _initialFocalPoint = details.focalPoint;
    _initialOffset = _offset;
    _initialScale = _scale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final delta = details.focalPoint - _initialFocalPoint!;
    setState(() {
      _scale = (_initialScale * details.scale).clamp(0.2, 4.0);
      _offset = _initialOffset + delta / _scale;
    });
  }

  void _handleScroll(PointerScrollEvent event) {
    const double zoomStep = 0.1;
    final zoomDirection = event.scrollDelta.dy > 0 ? -1 : 1;
    final zoomFactor = 1 + zoomStep * zoomDirection;

    final mouseX = event.localPosition.dx;
    final mouseY = event.localPosition.dy;

    final worldX = (mouseX - _offset.dx) / _scale;
    final worldY = (mouseY - _offset.dy) / _scale;

    final newScale = (_scale * zoomFactor).clamp(0.2, 4.0);
    final newOffsetX = mouseX - worldX * newScale;
    final newOffsetY = mouseY - worldY * newScale;

    setState(() {
      _scale = newScale;
      _offset = Offset(newOffsetX, newOffsetY);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text('🌍 World Map')),
      body: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) _handleScroll(event);
        },
        child: GestureDetector(
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          child: CustomPaint(
            painter: MapPainter(
              offset: _offset,
              scale: _scale,
              screenSize: size,
              minX: minX,
              minY: minY,
              villages: _villages,
            ),
            size: size,
          ),
        ),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  static const double tileSize = 24;
  final Offset offset;
  final double scale;
  final Size screenSize;
  final int minX;
  final int minY;
  final List<Map<String, dynamic>> villages;

  MapPainter({
    required this.offset,
    required this.scale,
    required this.screenSize,
    required this.minX,
    required this.minY,
    required this.villages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final entry in tier1Map.entries) {
      final parts = entry.key.split('_');
      final x = int.parse(parts[0]);
      final y = int.parse(parts[1]);
      final terrain = entry.value;

      final def = terrainDefinitions[terrain];
      paint.color = def?.color ?? Colors.green[400]!;

      final left = (x - minX) * tileSize * scale + offset.dx;
      final top = (y - minY) * tileSize * scale + offset.dy;

      final rect = Rect.fromLTWH(left, top, tileSize * scale, tileSize * scale);
      canvas.drawRect(rect, paint);

      // Only draw icons when zoomed in enough
      if (scale > 1.2 && def?.icon != null) {
        final icon = def!.icon!;
        final textPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              fontSize: 12 * scale,
              color: Colors.black87,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final centerX = left + (tileSize * scale - textPainter.width) / 2;
        final centerY = top + (tileSize * scale - textPainter.height) / 2;
        textPainter.paint(canvas, Offset(centerX, centerY));
      }
    }

    // 🏰 Draw villages (as emoji) if scale is safe
    if (scale > 1.2) {
      for (final village in villages) {
        final int x = village['x'] ?? 0;
        final int y = village['y'] ?? 0;

        final left = (x - minX) * tileSize * scale + offset.dx;
        final top = (y - minY) * tileSize * scale + offset.dy;

        final tp = TextPainter(
          text: TextSpan(
            text: '🏰',
            style: TextStyle(
              fontSize: 12 * scale,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final centerX = left + (tileSize * scale - tp.width) / 2;
        final centerY = top + (tileSize * scale - tp.height) / 2;
        tp.paint(canvas, Offset(centerX, centerY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
