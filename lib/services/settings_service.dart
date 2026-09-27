import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import 'localization_service.dart';

class SettingsService extends ChangeNotifier {
  static const _storageKey = 'video_downscaler_app_settings';

  AppSettings _settings = const AppSettings();
  bool _isLoaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _isLoaded;

  AppLocalizations get l10n => AppLocalizations(_settings.languageCode);

  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        _settings = AppSettings.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_settings.toJson());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setLanguage(String languageCode) async {
    await updateSettings(_settings.copyWith(languageCode: languageCode));
  }

  Future<void> setCpuThreads(int threads) async {
    await updateSettings(_settings.copyWith(cpuThreads: threads));
  }

  Future<void> setRamBuffer(int ramBufferMb) async {
    await updateSettings(_settings.copyWith(ramBufferMb: ramBufferMb));
  }

  Future<void> setCpuPreset(String preset) async {
    await updateSettings(_settings.copyWith(cpuPreset: preset));
  }

  Future<void> setHardwareAcceleration(bool enabled) async {
    await updateSettings(_settings.copyWith(hardwareAcceleration: enabled));
  }

  Future<void> setAudioBitrate(int kbps) async {
    await updateSettings(_settings.copyWith(audioBitrateKbps: kbps));
  }

  Future<void> resetToDefaults() async {
    // Preserve current language when resetting hardware defaults or reset all
    final currentLang = _settings.languageCode;
    _settings = AppSettings(languageCode: currentLang);
    notifyListeners();
    await _saveSettings();
  }
}
