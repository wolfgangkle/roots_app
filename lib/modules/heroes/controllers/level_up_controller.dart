// lib/modules/heroes/controllers/level_up_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:roots_app/modules/heroes/models/hero_model.dart';

// 🔌 Thin callable wrappers:
import 'package:roots_app/modules/heroes/functions/acknowledge_level_up.dart' as fx_ack;
import 'package:roots_app/modules/heroes/functions/spend_attribute_points.dart' as fx_spend;

// 🧮 Preview formulas (read-only, client-side mirror):
import 'package:roots_app/modules/heroes/data/hero_stat_formulas.dart'
    show computeDerivedStatsPreview, DerivedStatsPreview;

/// Small value class for a “before → after” snapshot of key derived stats.
class LevelUpPreview {
  final DerivedStatsPreview before;
  final DerivedStatsPreview after;

  const LevelUpPreview({
    required this.before,
    required this.after,
  });
}

/// Controller that manages inline level-up allocation & preview.
class LevelUpController extends ChangeNotifier {
  LevelUpController({
    required HeroModel hero,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _baseHero = hero {
    _resetFromHero(hero);
  }

  // --- immutable deps ---
  final FirebaseFirestore _firestore;

  // --- base state (from Firestore hero doc) ---
  HeroModel _baseHero;
  HeroModel get hero => _baseHero;

  // Whether server says there’s a level-up to acknowledge.
  bool _pendingLevelUp = false;
  bool get pendingLevelUp => _pendingLevelUp;

  // Local “I clicked acknowledge” latch (optimistic UI).
  bool _acknowledgedLocally = false;
  bool get acknowledgedLocally => _acknowledgedLocally;

  // Points available to allocate (from hero.unspentAttributePoints).
  int _unspentPoints = 0;
  int get unspentPoints => _unspentPoints;

  // --- local allocation model ---
  final Map<String, int> _alloc = {
    'strength': 0,
    'dexterity': 0,
    'intelligence': 0,
    'constitution': 0,
  };
  Map<String, int> get allocation => Map.unmodifiable(_alloc);

  int get allocatedTotal =>
      _alloc.values.fold<int>(0, (acc, v) => acc + (v < 0 ? 0 : v));

  int get pointsLeft => (_unspentPoints - allocatedTotal).clamp(0, 1 << 30);

  // --- preview ---
  LevelUpPreview? _preview;
  LevelUpPreview? get preview => _preview;

  // --- busy & error ---
  bool _busy = false;
  bool get isBusy => _busy;

  String? _error;
  String? get errorText => _error;

  // ------------- public API -------------

  /// Call when entering the tab (or when parent updated hero).
  void updateHero(HeroModel fresh) {
    _baseHero = fresh;
    _resetFromHero(fresh);
    notifyListeners();
  }

  /// Increment an attribute by 1 (if points remain).
  void increment(String attr) {
    if (!_isValidAttr(attr)) return;
    if (isSpendLocked) return; // must acknowledge first
    if (pointsLeft <= 0) return;

    _alloc[attr] = (_alloc[attr] ?? 0) + 1;
    _recomputePreview();
    notifyListeners();
  }

  /// Decrement an attribute by 1 (but not below 0).
  void decrement(String attr) {
    if (!_isValidAttr(attr)) return;
    if (isSpendLocked) return; // even undo requires ack, keep UX simple

    final current = _alloc[attr] ?? 0;
    if (current <= 0) return;

    _alloc[attr] = current - 1;
    _recomputePreview();
    notifyListeners();
  }

  /// Reset all local changes.
  void reset() {
    _alloc.updateAll((_, __) => 0);
    _recomputePreview();
    _error = null;
    notifyListeners();
  }

  /// True if user must acknowledge level-up before spending.
  bool get isSpendLocked => _pendingLevelUp && !_acknowledgedLocally;

  /// Acknowledge the level-up on the server, then unlock spending.
  Future<void> acknowledgeLevelUp() async {
    if (!pendingLevelUp) {
      _acknowledgedLocally = true;
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      _error = null;
      await fx_ack.acknowledgeLevelUp(hero.id);
      _acknowledgedLocally = true;
      // Keep _pendingLevelUp true until we refetch; lock lifts via local latch.
    });
  }

  /// Confirm spend: calls server, then reloads hero and clears allocation.
  Future<void> confirmSpend() async {
    if (isSpendLocked) {
      _error = 'Please acknowledge the level-up first.';
      notifyListeners();
      return;
    }

    // Clean positive deltas only
    final clean = <String, int>{
      for (final e in _alloc.entries)
        if (e.value > 0) e.key: e.value,
    };

    if (clean.isEmpty) {
      _error = 'Select at least one point to spend.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      _error = null;

      // ⬇️ Positional call matches your shim signature
      await fx_spend.spendAttributePoints(hero.id, clean);

      // Refresh + clear local allocation
      await _reloadHero();
      _alloc.updateAll((_, __) => 0);
      _recomputePreview();
    });
  }


  // ------------- internals -------------

  bool _isValidAttr(String key) =>
      key == 'strength' ||
          key == 'dexterity' ||
          key == 'intelligence' ||
          key == 'constitution';

  void _resetFromHero(HeroModel h) {
    _unspentPoints = h.unspentAttributePoints ?? 0;
    _pendingLevelUp = h.pendingLevelUp == true;
    _acknowledgedLocally = !_pendingLevelUp; // unlock if none pending
    _alloc.updateAll((_, __) => 0);
    _recomputePreview();
  }

  Future<void> _reloadHero() async {
    final snap = await _firestore.collection('heroes').doc(_baseHero.id).get();
    if (!snap.exists) return;

    final fresh = HeroModel.fromFirestore(snap.id, snap.data()!);
    _baseHero = fresh;

    // Sync flags from fresh hero
    _unspentPoints = fresh.unspentAttributePoints ?? 0;
    _pendingLevelUp = fresh.pendingLevelUp == true;
    if (!_pendingLevelUp) _acknowledgedLocally = false;

    // Recompute preview with the newly fetched base
    _recomputePreview();
    notifyListeners();
  }

  void _recomputePreview() {
    try {
      final before = DerivedStatsPreview.fromHeroModel(_baseHero);

      // Compute “after” based on local allocation.
      final after = computeDerivedStatsPreview(
        baseHero: _baseHero,
        allocation: _alloc,
      );

      _preview = LevelUpPreview(before: before, after: after);
    } catch (e) {
      // Fail-safe: still provide a “no-change” preview if formulas aren’t ready yet.
      final before = DerivedStatsPreview.fromHeroModel(_baseHero);
      _preview = LevelUpPreview(before: before, after: before);
      if (kDebugMode) {
        // ignore: avoid_print
        print('LevelUpController preview error: $e');
      }
    }
  }

  Future<void> _runBusy(Future<void> Function() fn) async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      await fn();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
