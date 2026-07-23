import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsService extends ChangeNotifier {
  static const String _box = 'threadcraft_db';

  // ── Keys ──
  static const String _keyHaptic = 'setting_haptic';
  static const String _keyAutoSave = 'setting_autosave';
  static const String _keyStepHistory = 'setting_stephistory';
  static const String _keyDarkCanvas = 'setting_darkcanvas';
  static const String _keyDefaultShape = 'setting_shape';
  static const String _keyDefaultDensity = 'setting_density';
  static const String _keyDefaultNails = 'setting_nails';
  static const String _keyVoiceEnabled = 'setting_voice';
  static const String _keyVoiceSpeed = 'setting_speed';
  static const String _keyVoiceGender = 'setting_gender';
  static const String _keyAutoAdvance = 'setting_autoadvance';
  static const String _keyAutoDelay = 'setting_autodelay';

  // ── Settings values ──
  bool _hapticFeedback = true;
  bool _autoSave = true;
  bool _showStepHistory = true;
  bool _darkCanvas = true;
  String _defaultShape = 'Circle';
  String _defaultDensity = 'Medium';
  int _defaultNails = 200;
  bool _voiceEnabled = false;
  double _voiceSpeed = 1.0;
  String _voiceGender = 'Female';
  bool _autoAdvance = false;
  int _autoDelay = 4;

  // ── Getters ──
  bool get hapticFeedback => _hapticFeedback;
  bool get autoSave => _autoSave;
  bool get showStepHistory => _showStepHistory;
  bool get darkCanvas => _darkCanvas;
  String get defaultShape => _defaultShape;
  String get defaultDensity => _defaultDensity;
  int get defaultNails => _defaultNails;
  bool get voiceEnabled => _voiceEnabled;
  double get voiceSpeed => _voiceSpeed;
  String get voiceGender => _voiceGender;
  bool get autoAdvance => _autoAdvance;
  int get autoDelay => _autoDelay;

  SettingsService() {
    _load();
  }

  // ── Load all settings from Hive ──
  void _load() {
    final box = Hive.box(_box);
    _hapticFeedback = box.get(_keyHaptic, defaultValue: true);
    _autoSave = box.get(_keyAutoSave, defaultValue: true);
    _showStepHistory = box.get(_keyStepHistory, defaultValue: true);
    _darkCanvas = box.get(_keyDarkCanvas, defaultValue: true);
    _defaultShape = box.get(_keyDefaultShape, defaultValue: 'Circle');
    _defaultDensity = box.get(_keyDefaultDensity, defaultValue: 'Medium');
    _defaultNails = box.get(_keyDefaultNails, defaultValue: 200);
    _voiceEnabled = box.get(_keyVoiceEnabled, defaultValue: false);
    _voiceSpeed = box.get(_keyVoiceSpeed, defaultValue: 1.0);
    _voiceGender = box.get(_keyVoiceGender, defaultValue: 'Female');
    _autoAdvance = box.get(_keyAutoAdvance, defaultValue: false);
    _autoDelay = box.get(_keyAutoDelay, defaultValue: 4);
    notifyListeners();
  }

  // ── Save one key ──
  Future<void> _save(String key, dynamic value) async {
    await Hive.box(_box).put(key, value);
  }

  // ── Setters (each saves immediately) ──
  Future<void> setHaptic(bool v) async {
    _hapticFeedback = v;
    await _save(_keyHaptic, v);
    notifyListeners();
  }

  Future<void> setAutoSave(bool v) async {
    _autoSave = v;
    await _save(_keyAutoSave, v);
    notifyListeners();
  }

  Future<void> setStepHistory(bool v) async {
    _showStepHistory = v;
    await _save(_keyStepHistory, v);
    notifyListeners();
  }

  Future<void> setDarkCanvas(bool v) async {
    _darkCanvas = v;
    await _save(_keyDarkCanvas, v);
    notifyListeners();
  }

  Future<void> setDefaultShape(String v) async {
    _defaultShape = v;
    await _save(_keyDefaultShape, v);
    notifyListeners();
  }

  Future<void> setDefaultDensity(String v) async {
    _defaultDensity = v;
    await _save(_keyDefaultDensity, v);
    notifyListeners();
  }

  Future<void> setDefaultNails(int v) async {
    _defaultNails = v;
    await _save(_keyDefaultNails, v);
    notifyListeners();
  }

  Future<void> setVoiceEnabled(bool v) async {
    _voiceEnabled = v;
    await _save(_keyVoiceEnabled, v);
    notifyListeners();
  }

  Future<void> setVoiceSpeed(double v) async {
    _voiceSpeed = v;
    await _save(_keyVoiceSpeed, v);
    notifyListeners();
  }

  Future<void> setVoiceGender(String v) async {
    _voiceGender = v;
    await _save(_keyVoiceGender, v);
    notifyListeners();
  }

  Future<void> setAutoAdvance(bool v) async {
    _autoAdvance = v;
    await _save(_keyAutoAdvance, v);
    notifyListeners();
  }

  Future<void> setAutoDelay(int v) async {
    _autoDelay = v;
    await _save(_keyAutoDelay, v);
    notifyListeners();
  }
}