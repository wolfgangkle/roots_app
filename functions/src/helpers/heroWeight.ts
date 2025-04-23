type EquippedItem = {
  craftedStats?: { weight?: number };
};

type BackpackItem = {
  itemId: string;
  quantity?: number;
  craftedStats?: { weight?: number };
};

/**
 * Calculates total hero item weight from equipped items, backpack, and carried resources.
 */
export function calculateHeroWeight(
  equipped: Record<string, EquippedItem>,
  backpack: BackpackItem[],
  carriedResources: Record<string, number> = {}
): number {
  let total = 0;

  // Equipped items
  for (const item of Object.values(equipped)) {
    const weight = item?.craftedStats?.weight ?? 0;
    total += weight;
  }

  // Backpack items
  for (const item of backpack) {
    const qty = item.quantity ?? 1;
    const weight = item?.craftedStats?.weight ?? 0;
    total += qty * weight;
  }

  // Carried resources
  const resourceWeights: Record<string, number> = {
    wood: 0.01,
    stone: 0.01,
    iron: 0.01,
    food: 0.01,
    gold: 0.01,
  };

  for (const [res, amount] of Object.entries(carriedResources)) {
    const unitWeight = resourceWeights[res] ?? 0;
    total += (amount ?? 0) * unitWeight;
  }

  return total;
}

/**
 * Adjusts base movement speed based on current carry weight.
 * At 0% capacity => baseSpeed
 * At 100% capacity => baseSpeed * 2
 */
export function calculateAdjustedMovementSpeed(
  baseSpeed: number,
  currentWeight: number,
  carryCapacity: number,
): number {
  if (carryCapacity <= 0) return baseSpeed;

  const loadRatio = Math.min(currentWeight / carryCapacity, 1); // clamp to [0,1]
  const speedMultiplier = 1 + loadRatio; // up to 2x slower
  return Math.floor(baseSpeed * speedMultiplier);
}
