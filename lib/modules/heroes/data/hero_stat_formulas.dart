// lib/modules/heroes/data/hero_stat_formulas.dart
//
// Read-only, client-side preview helpers for inline Level Up.
// Mirrors the *spirit* of your server formulas without being authoritative.
//
// How to align with backend:
// - Adjust the coefficients in `_Coeffs` to match your TS `heroStatFormulas.ts`.
// - Keep this file free of I/O. It should be safe to run every keystroke/frame.

import 'dart:math' as math;
import 'package:roots_app/modules/heroes/models/hero_model.dart';

/// Tunable coefficients to approximate server-side stat impacts.
/// Adjust these to better mirror your `heroStatFormulas.ts`.
class _Coeffs {
  // Per-point contributions (heuristic defaults; refine as needed)
  static const double strAttackMin = 0.5;
  static const double strAttackMax = 1.0;
  static const double strCarryCap   = 5.0;

  static const double dexAT = 1.0;           // attack rating
  static const double dexSpeedPct = 0.5;     // % faster per point (applied on ms, capped)

  static const double intDEF = 0.4;
  static const double intManaMax = 2.0;
  static const double intRegenPerTick = 0.04;

  static const double conHPMax = 5.0;
  static const double conDEF = 0.6;
  static const double conRegenPerTick = 0.06;

  // Movement tuning
  static const double dexMovePct = 0.2;      // % faster base move per DEX point
  static const double minSpeedMultiplier = 0.25; // never drop below 25% due to weight

  // Global caps / clamps for saner previews
  static const double maxAttackSpeedGainPct = 60.0; // cap total DEX speed up
}

/// Snapshot of derived stats we care about for the preview.
class DerivedStatsPreview {
  // Attributes (final values used to compute deriveds)
  final int strength;
  final int dexterity;
  final int intelligence;
  final int constitution;

  // Core combat
  final double attackMin;
  final double attackMax;
  final int attackSpeedMs;
  final double attackRating; // at
  final double defenseRating; // def
  final double regenPerTick; // HP per tick (10s in your UI)

  // Extra context
  final double dps;
  final int hpMax;
  final int manaMax;
  final int carryCapacity;
  final double baseMovementSpeed;
  final double adjustedMovementSpeed;
  final int combatLevel; // kept from hero (server-owned)

  const DerivedStatsPreview({
    required this.strength,
    required this.dexterity,
    required this.intelligence,
    required this.constitution,
    required this.attackMin,
    required this.attackMax,
    required this.attackSpeedMs,
    required this.attackRating,
    required this.defenseRating,
    required this.regenPerTick,
    required this.dps,
    required this.hpMax,
    required this.manaMax,
    required this.carryCapacity,
    required this.baseMovementSpeed,
    required this.adjustedMovementSpeed,
    required this.combatLevel,
  });

  /// Build a "before" snapshot straight from the HeroModel.
  factory DerivedStatsPreview.fromHeroModel(HeroModel hero) {
    final combat = hero.combat ?? const {};
    final atMin = _asDouble(combat['attackMin'], fallback: 0);
    final atMax = _asDouble(combat['attackMax'], fallback: 0);
    final spdMs = _asInt(combat['attackSpeedMs'], fallback: 1000);
    final at = _asDouble(combat['at'], fallback: 0);
    final def = _asDouble(combat['def'], fallback: 0);
    final regenTick = _asDouble(combat['regenPerTick'], fallback: 0);

    final dps = _computeDps(atMin, atMax, spdMs);

    final stats = hero.stats ?? const {};
    final str = _asInt(stats['strength']);
    final dex = _asInt(stats['dexterity']);
    final intl = _asInt(stats['intelligence']);
    final con = _asInt(stats['constitution']);

    final hpMax = _asInt(hero.hpMax, fallback: 0);
    final manaMax = _asInt(hero.manaMax, fallback: 0);
    final carryCap = _asInt(hero.carryCapacity, fallback: 0);

    // Movement: if you store base speed on hero, use it; otherwise derive 1.0 as neutral.
    final baseMove = _asDouble(hero.baseMovementSpeed ?? 1.0, fallback: 1.0);

    final currentWeight = (hero.currentWeight ?? 0).toDouble();
    final adjustedMove =
    _applyWeightToSpeed(baseMove, currentWeight, carryCap.toDouble());

    return DerivedStatsPreview(
      strength: str,
      dexterity: dex,
      intelligence: intl,
      constitution: con,
      attackMin: atMin,
      attackMax: atMax,
      attackSpeedMs: spdMs,
      attackRating: at,
      defenseRating: def,
      regenPerTick: regenTick,
      dps: dps,
      hpMax: hpMax,
      manaMax: manaMax,
      carryCapacity: carryCap,
      baseMovementSpeed: baseMove,
      adjustedMovementSpeed: adjustedMove,
      combatLevel: hero.combatLevel ?? 0,
    );
  }

  DerivedStatsPreview copyWith({
    int? strength,
    int? dexterity,
    int? intelligence,
    int? constitution,
    double? attackMin,
    double? attackMax,
    int? attackSpeedMs,
    double? attackRating,
    double? defenseRating,
    double? regenPerTick,
    double? dps,
    int? hpMax,
    int? manaMax,
    int? carryCapacity,
    double? baseMovementSpeed,
    double? adjustedMovementSpeed,
    int? combatLevel,
  }) {
    return DerivedStatsPreview(
      strength: strength ?? this.strength,
      dexterity: dexterity ?? this.dexterity,
      intelligence: intelligence ?? this.intelligence,
      constitution: constitution ?? this.constitution,
      attackMin: attackMin ?? this.attackMin,
      attackMax: attackMax ?? this.attackMax,
      attackSpeedMs: attackSpeedMs ?? this.attackSpeedMs,
      attackRating: attackRating ?? this.attackRating,
      defenseRating: defenseRating ?? this.defenseRating,
      regenPerTick: regenPerTick ?? this.regenPerTick,
      dps: dps ?? this.dps,
      hpMax: hpMax ?? this.hpMax,
      manaMax: manaMax ?? this.manaMax,
      carryCapacity: carryCapacity ?? this.carryCapacity,
      baseMovementSpeed: baseMovementSpeed ?? this.baseMovementSpeed,
      adjustedMovementSpeed: adjustedMovementSpeed ?? this.adjustedMovementSpeed,
      combatLevel: combatLevel ?? this.combatLevel,
    );
  }
}

/// Compute an "after" snapshot based on the hero and a local allocation map.
/// allocation keys: strength, dexterity, intelligence, constitution
DerivedStatsPreview computeDerivedStatsPreview({
  required HeroModel baseHero,
  required Map<String, int> allocation,
}) {
  final before = DerivedStatsPreview.fromHeroModel(baseHero);

  final addStr = math.max(0, allocation['strength'] ?? 0);
  final addDex = math.max(0, allocation['dexterity'] ?? 0);
  final addInt = math.max(0, allocation['intelligence'] ?? 0);
  final addCon = math.max(0, allocation['constitution'] ?? 0);

  // --- Attributes after
  final strength = before.strength + addStr;
  final dexterity = before.dexterity + addDex;
  final intelligence = before.intelligence + addInt;
  final constitution = before.constitution + addCon;

  // --- Attack min/max (scale with STR)
  final attackMin = before.attackMin + addStr * _Coeffs.strAttackMin;
  final attackMax = before.attackMax + addStr * _Coeffs.strAttackMax;

  // --- Attack rating (AT) (scale with DEX)
  final attackRating = before.attackRating + addDex * _Coeffs.dexAT;

  // --- Defense rating (DEF) (scale with CON & INT)
  final defenseRating =
      before.defenseRating + addCon * _Coeffs.conDEF + addInt * _Coeffs.intDEF;

  // --- Regen per tick (HP per 10s) (scale with CON & INT)
  final regenPerTick = before.regenPerTick +
      addCon * _Coeffs.conRegenPerTick +
      addInt * _Coeffs.intRegenPerTick;

  // --- Attack speed (ms) (DEX speeds up; cap total gain)
  final totalSpeedGainPct =
  math.min(addDex * _Coeffs.dexSpeedPct, _Coeffs.maxAttackSpeedGainPct);
  final attackSpeedMs = _applyPercentDecreaseMs(
    before.attackSpeedMs,
    totalSpeedGainPct,
  );

  // --- EHP pools
  final hpMax = (before.hpMax + (addCon * _Coeffs.conHPMax)).round();
  final manaMax = (before.manaMax + (addInt * _Coeffs.intManaMax)).round();

  // --- Carry capacity (STR)
  final carryCapacity =
  (before.carryCapacity + addStr * _Coeffs.strCarryCap).round();

  // --- Base movement (DEX adds small %)
  final baseMovementSpeed = _applyPercentIncrease(
    before.baseMovementSpeed,
    addDex * _Coeffs.dexMovePct,
  );

  // --- Adjusted movement (weight penalty)
  final currentWeight = (baseHero.currentWeight ?? 0).toDouble();
  final adjustedMovementSpeed = _applyWeightToSpeed(
    baseMovementSpeed,
    currentWeight,
    carryCapacity.toDouble(),
  );

  // --- DPS
  final dps = _computeDps(attackMin, attackMax, attackSpeedMs);

  // --- Combat level (server-owned; keep it stable in preview)
  final combatLevel = before.combatLevel;

  return before.copyWith(
    strength: strength,
    dexterity: dexterity,
    intelligence: intelligence,
    constitution: constitution,
    attackMin: attackMin,
    attackMax: attackMax,
    attackSpeedMs: attackSpeedMs,
    attackRating: attackRating,
    defenseRating: defenseRating,
    regenPerTick: regenPerTick,
    hpMax: hpMax,
    manaMax: manaMax,
    carryCapacity: carryCapacity,
    baseMovementSpeed: baseMovementSpeed,
    adjustedMovementSpeed: adjustedMovementSpeed,
    dps: dps,
    combatLevel: combatLevel,
  );
}

// ------------------------ helpers ------------------------

double _computeDps(double minDmg, double maxDmg, int attackSpeedMs) {
  final avg = (minDmg + maxDmg) / 2.0;
  final sec = (attackSpeedMs <= 0) ? 1.0 : (attackSpeedMs / 1000.0);
  return sec <= 0 ? 0 : (avg / sec);
}

int _applyPercentDecreaseMs(int ms, double pct) {
  final factor = math.max(0.01, 1.0 - pct / 100.0);
  final val = (ms * factor).round();
  return val.clamp(1, 1 << 30);
}

double _applyPercentIncrease(double base, double pct) {
  final factor = 1.0 + (pct / 100.0);
  return base * factor;
}

double _applyWeightToSpeed(double baseSpeed, double currentWeight, double carryCap) {
  if (carryCap <= 0) return baseSpeed * _Coeffs.minSpeedMultiplier;
  final load = currentWeight / carryCap;
  // Simple penalty curve: from 0% at empty to -50% at full load; clamp to minSpeedMultiplier
  final penalty = (load * 0.5).clamp(0.0, 0.9);
  final result = baseSpeed * (1.0 - penalty);
  return math.max(result, baseSpeed * _Coeffs.minSpeedMultiplier);
}

double _asDouble(dynamic v, {double fallback = 0}) {
  if (v is num) return v.toDouble();
  return fallback;
}

int _asInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return fallback;
}
