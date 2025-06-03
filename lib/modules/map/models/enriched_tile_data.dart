class EnrichedTileData {
  final String tileKey;
  final int x;
  final int y;
  final String terrain;

  final String? villageId;
  final String? villageName;
  final String? ownerId;
  final String? ownerName;

  final String? guildId;
  final String? guildName;
  final String? guildTag;

  final String? allianceId;
  final String? allianceTag;

  final List<Map<String, dynamic>> heroGroups;

  EnrichedTileData({
    required this.tileKey,
    required this.x,
    required this.y,
    required this.terrain,
    this.villageId,
    this.villageName,
    this.ownerId,
    this.ownerName,
    this.guildId,
    this.guildName,
    this.guildTag,
    this.allianceId,
    this.allianceTag,
    this.heroGroups = const [],
  });

  /// 🪄 Create a copy with optionally updated heroGroups
  EnrichedTileData copyWith({
    List<Map<String, dynamic>>? heroGroups,
  }) {
    return EnrichedTileData(
      tileKey: tileKey,
      x: x,
      y: y,
      terrain: terrain,
      villageId: villageId,
      villageName: villageName,
      ownerId: ownerId,
      ownerName: ownerName,
      guildId: guildId,
      guildName: guildName,
      guildTag: guildTag,
      allianceId: allianceId,
      allianceTag: allianceTag,
      heroGroups: heroGroups ?? this.heroGroups,
    );
  }
}
