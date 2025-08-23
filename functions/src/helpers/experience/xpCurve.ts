// functions/src/helpers/experience/xpCurve.ts
export function xpForLevel(level: number): number {
  // CUMULATIVE XP needed to reach `level`.
  // Feel free to tune these numbers later.
  const a = 20;
  const b = 5;
  const c = 1.05;
  return Math.floor(a * level + b * level * level * Math.max(1, Math.pow(c, Math.max(0, level - 10))));
}

export function levelFromTotalXp(totalXp: number): number {
  let lo = 1, hi = 1000, ans = 1;
  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    if (xpForLevel(mid) <= totalXp) { ans = mid; lo = mid + 1; }
    else { hi = mid - 1; }
  }
  return ans;
}
