import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class VoiceService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();

  static const String _box = 'threadcraft_db';
  static const String _keyEnabled = 'setting_voice';
  static const String _keySpeed = 'setting_speed';
  static const String _keyGender = 'setting_gender';

  bool _isEnabled = false;
  double _speed = 1.0;
  String _voice = 'Female';
  bool _isSpeaking = false;
  bool _isInitialized = false;

  bool get isEnabled => _isEnabled;
  double get speed => _speed;
  String get voice => _voice;

  VoiceService() {
    _init();
  }

  Future<void> _init() async {
    try {
      // Load saved settings
      final box = Hive.box(_box);
      _isEnabled =
          box.get(_keyEnabled, defaultValue: false);
      _speed =
          (box.get(_keySpeed, defaultValue: 1.0) as num)
              .toDouble();
      _voice =
          box.get(_keyGender, defaultValue: 'Female');

      // Basic TTS setup — works on ALL devices
      await _tts.setLanguage('en-US');
      await _tts.setVolume(1.0);

      // When done speaking → allow next speech
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((_) {
        _isSpeaking = false;
      });

      // Apply gender/speed
      await _applySettings();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('TTS init error: $e');
      _isInitialized = false;
    }
  }

  // ── Apply voice settings ──
  // Simple pitch approach — works on EVERY device
  Future<void> _applySettings() async {
    try {
      // Speed: map 0.5x→0.25, 1x→0.45, 1.5x→0.60, 2x→0.75
      final rate = (_speed * 0.45).clamp(0.2, 0.8);
      await _tts.setSpeechRate(rate);

      if (_voice == 'Male') {
        // Noticeably deep male voice
        await _tts.setPitch(0.55);
      } else {
        // Clear bright female voice
        await _tts.setPitch(1.25);
      }
    } catch (e) {
      debugPrint('TTS settings error: $e');
    }
  }

  // ── Speak step — one at a time, no overlap ──
  Future<void> speakStep(int from, int to) async {
    if (!_isEnabled) return;
    if (_isSpeaking) return;
    if (!_isInitialized) return;

    try {
      _isSpeaking = true;
      await _tts.stop();

      // Small delay ensures TTS is ready on real phones
      await Future.delayed(
          const Duration(milliseconds: 100));

      final result = await _tts
          .speak('Nail ${from + 1} to ${to + 1}');

      // If speak returned 0 = failed on this device
      if (result == 0) {
        _isSpeaking = false;
      }
    } catch (e) {
      _isSpeaking = false;
      debugPrint('TTS speak error: $e');
    }
  }
// ── Speak any custom text ──
  Future<void> speak(String text) async {
    if (!_isEnabled) return;
    if (_isSpeaking) return;
    try {
      _isSpeaking = true;
      await _tts.stop();
      await Future.delayed(
          const Duration(milliseconds: 100));
      await _tts.speak(text);
    } catch (e) {
      _isSpeaking = false;
    }
  }
  // ── Test voice (always plays) ──
  Future<void> testSpeak() async {
    if (!_isInitialized) await _init();

    try {
      _isSpeaking = false;
      await _tts.stop();
      await Future.delayed(
          const Duration(milliseconds: 150));
      _isSpeaking = true;
      await _tts.speak(
          'Going from nail 47 to nail 312');
    } catch (e) {
      _isSpeaking = false;
      debugPrint('Test speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      _isSpeaking = false;
      await _tts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  // ── Toggle voice on/off ──
  void toggleVoice() {
    _isEnabled = !_isEnabled;
    if (!_isEnabled) stop();
    _saveEnabled();
    notifyListeners();
  }

  void setEnabled(bool val) {
    _isEnabled = val;
    if (!_isEnabled) stop();
    _saveEnabled();
    notifyListeners();
  }

  // ── Change speed ──
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _applySettings();
    await Hive.box(_box).put(_keySpeed, speed);
    notifyListeners();
  }

  // ── Change gender ──
  Future<void> setVoice(String gender) async {
    _voice = gender;
    await _applySettings();
    await Hive.box(_box).put(_keyGender, gender);
    notifyListeners();
  }

  void _saveEnabled() {
    try {
      Hive.box(_box).put(_keyEnabled, _isEnabled);
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  @override
  void dispose() {
    try {
      _isSpeaking = false;
      _tts.stop();
    } catch (_) {}
    super.dispose();
  }
}