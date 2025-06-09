// src/types/heroGroupData.ts

export interface HeroGroupData {
  tileX: number;
  tileY: number;
  tileKey: string;

  state: 'idle' | 'moving' | 'arrived' | 'inCombat' | string;
  returning?: boolean;

  waypoints?: Array<{ x: number; y: number }>;

  members: string[]; // Hero document IDs
  createdAt: FirebaseFirestore.Timestamp;

  movementSpeed: number;         // current movement speed (after weight calc)
  baseMovementSpeed?: number;    // original base speed before weight

  insideVillage?: boolean;
  lastMovedAt?: FirebaseFirestore.Timestamp;
  leaderHeroId?: string;

  // Meta or expansion fields
  guildId?: string;
  allianceId?: string;
  userIds?: string[]; // optional if you're enriching the group with user data
}
