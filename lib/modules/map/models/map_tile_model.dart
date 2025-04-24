class MapTileModel {
  final int x;
  final int y;
  final String terrainId;

  MapTileModel({
    required this.x,
    required this.y,
    required this.terrainId,
  });

  factory MapTileModel.fromMap(Map<String, dynamic> data) {
    return MapTileModel(
      x: data['x'],
      y: data['y'],
      terrainId: data['terrain'],
    );
  }

  String get id => '${x}_$y';
}
