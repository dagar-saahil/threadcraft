import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ── Plan types ──
enum PlanType {
  none,
  colorPass,  // ₹69 — 24 hours — color thread
  rgbPass,    // ₹99 — 24 hours — RGB thread
  monthly,    // ₹199 — 30 days
  yearly,     // ₹999 — 365 days
  lifetime,   // ₹2499 — forever
}

class PremiumService extends ChangeNotifier {
  static const String _box = 'threadcraft_db';
  static const String _keyPlan = 'tc_plan_v2';
  static const String _keyExpiry = 'tc_expiry_v2';

  PlanType _plan = PlanType.none;
  DateTime? _expiryDate;

  PlanType get plan => _plan;
  DateTime? get expiryDate => _expiryDate;

  PremiumService() {
    _load();
  }

  // ── Load saved plan from storage ──
  void _load() {
    try {
      final box = Hive.box(_box);
      final planStr =
      box.get(_keyPlan, defaultValue: 'none')
      as String;
      _plan = PlanType.values.firstWhere(
            (p) => p.name == planStr,
        orElse: () => PlanType.none,
      );
      final expiryMs =
      box.get(_keyExpiry, defaultValue: 0) as int;
      if (expiryMs > 0) {
        _expiryDate =
            DateTime.fromMillisecondsSinceEpoch(
                expiryMs);
      }
      // Auto-expire on load
      _expireIfNeeded();
    } catch (_) {
      _plan = PlanType.none;
    }
    notifyListeners();
  }

  // ── Check if plan has expired ──
  void _expireIfNeeded() {
    if (_plan == PlanType.none ||
        _plan == PlanType.lifetime) return;
    if (_expiryDate != null &&
        DateTime.now().isAfter(_expiryDate!)) {
      _plan = PlanType.none;
      _expiryDate = null;
      _persist();
    }
  }

  // ── Check expiry and return true if JUST expired ──
  // Call this before any access check
  bool checkAndRefresh() {
    if (_plan == PlanType.none ||
        _plan == PlanType.lifetime) return false;
    if (_expiryDate != null &&
        DateTime.now().isAfter(_expiryDate!)) {
      final wasActive = _plan != PlanType.none;
      _plan = PlanType.none;
      _expiryDate = null;
      _persist();
      notifyListeners();
      return wasActive; // ← true = just expired now
    }
    return false;
  }

  // ════════════════════════════════
  // ACCESS CHECKERS
  // ════════════════════════════════

  // Can use Color Thread Art (any color except black)
  bool get hasColorAccess {
    _expireIfNeeded();
    switch (_plan) {
      case PlanType.colorPass:
      case PlanType.rgbPass:
      case PlanType.monthly:
      case PlanType.yearly:
      case PlanType.lifetime:
        return true;
      default:
        return false;
    }
  }

  // Can use RGB Thread Art
  bool get hasRGBAccess {
    _expireIfNeeded();
    switch (_plan) {
      case PlanType.rgbPass:
      case PlanType.monthly:
      case PlanType.yearly:
      case PlanType.lifetime:
        return true;
      default:
        return false;
    }
  }

  // General premium check
  bool get isPremium => hasColorAccess;

  // Is the current plan a timed pass?
  bool get isTimedPlan =>
      _plan == PlanType.colorPass ||
          _plan == PlanType.rgbPass;

  // How much time is left (for display)
  String get timeRemainingString {
    if (_plan == PlanType.lifetime) return 'Lifetime';
    if (_plan == PlanType.none) return 'Free';
    if (_expiryDate == null) return '';

    final rem = _expiryDate!.difference(DateTime.now());
    if (rem.isNegative) return 'Expired';
    if (rem.inDays >= 365) {
      return '${(rem.inDays / 365).floor()}y remaining';
    }
    if (rem.inDays >= 30) {
      return '${(rem.inDays / 30).floor()}mo remaining';
    }
    if (rem.inDays > 0) {
      return '${rem.inDays}d ${rem.inHours % 24}h';
    }
    if (rem.inHours > 0) {
      return '${rem.inHours}h ${rem.inMinutes % 60}m';
    }
    return '${rem.inMinutes}m remaining';
  }

  // Plan display name
  String get planDisplayName {
    switch (_plan) {
      case PlanType.none: return 'Free';
      case PlanType.colorPass: return 'Color Pass';
      case PlanType.rgbPass: return 'RGB Pass';
      case PlanType.monthly: return 'Monthly Pro';
      case PlanType.yearly: return 'Yearly Pro';
      case PlanType.lifetime: return 'Lifetime Pro';
    }
  }

  // ════════════════════════════════
  // UNLOCK / PURCHASE
  // ════════════════════════════════

  Future<void> unlockPlan(PlanType type) async {
    _plan = type;

    switch (type) {
      case PlanType.colorPass:
      case PlanType.rgbPass:
      // 24 hours exactly
        _expiryDate = DateTime.now()
            .add(const Duration(hours: 24));
        break;
      case PlanType.monthly:
        _expiryDate = DateTime.now()
            .add(const Duration(days: 30));
        break;
      case PlanType.yearly:
        _expiryDate = DateTime.now()
            .add(const Duration(days: 365));
        break;
      case PlanType.lifetime:
        _expiryDate = null; // never expires
        break;
      case PlanType.none:
        _expiryDate = null;
        break;
    }

    await _persist();
    notifyListeners();
  }

  // ── Reset (used in settings debug) ──
  Future<void> resetPremium() async {
    _plan = PlanType.none;
    _expiryDate = null;
    await _persist();
    notifyListeners();
  }

  // ── Debug unlock (Monthly) ──
  Future<void> debugUnlock() async {
    await unlockPlan(PlanType.monthly);
  }

  Future<void> _persist() async {
    try {
      final box = Hive.box(_box);
      await box.put(_keyPlan, _plan.name);
      await box.put(
        _keyExpiry,
        _expiryDate?.millisecondsSinceEpoch ?? 0,
      );
    } catch (_) {}
  }
}