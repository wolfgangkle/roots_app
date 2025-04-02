class VillageModel {
  final String id;
  final String name;
  final int tileX;
  final int tileY;
  final int wood;
  final int stone;
  final int food;

  VillageModel({
    required this.id,
    required this.name,
    required this.tileX,
    required this.tileY,
    required this.wood,
    required this.stone,
    required this.food,
  });

  factory VillageModel.fromMap(String id, Map<String, dynamic> data) {
    final resources = data['resources'] ?? {};

    return VillageModel(
      id: id,
      name: data['name'] ?? 'Unnamed',
      tileX: data['tileX'] ?? 0,
      tileY: data['tileY'] ?? 0,
      wood: resources['wood'] ?? 0,
      stone: resources['stone'] ?? 0,
      food: resources['food'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tileX': tileX,
      'tileY': tileY,
      'resources': {
        'wood': wood,
        'stone': stone,
        'food': food,
      }
    };
  }
}
