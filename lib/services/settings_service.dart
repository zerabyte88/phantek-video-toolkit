// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 zerabyte88

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/app_settings.dart';
import 'localization_service.dart';
import 'device_spec_helper.dart';

class SettingsService extends ChangeNotifier {
  static const _storageKey = 'phantek_video_toolkit_app_settings';
  static const _legacyStorageKey = 'video_downscaler_app_settings';

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
      final jsonStr =
          prefs.getString(_storageKey) ?? prefs.getString(_legacyStorageKey);
      if (jsonStr != null) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        final rawRamBuffer = data['ramBufferMb'] as int? ?? 512;
        _settings = AppSettings.fromJson(data);
        if (rawRamBuffer > 2048) {
          _settings = _settings.copyWith(ramBufferMb: 2048);
          await _saveSettings();
        }
      } else {
        _settings = const AppSettings();
      }

      if (_settings.isFirstLaunch) {
        await _applyFirstLaunchDefaults();
      }

      await _applyWakelock(_settings.keepScreenAwake);
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Resolves theme from brightness ('oled_pure' or 'light_clean').
  static String resolveInitialTheme([Brightness? brightness]) {
    if (brightness != null) {
      return brightness == Brightness.light ? 'light_clean' : 'oled_pure';
    }
    try {
      final platformBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return platformBrightness == Brightness.light
          ? 'light_clean'
          : 'oled_pure';
    } catch (_) {
      return 'oled_pure';
    }
  }

  /// Resolves language from system locales with 'en' fallback.
  static String resolveInitialLanguage([List<Locale>? locales]) {
    return AppLocalizations.resolveSupportedLanguage(locales);
  }

  Future<void> _applyFirstLaunchDefaults() async {
    final tier = DeviceSpecHelper.getDeviceTier();

    String preset = 'medium';
    if (tier == DeviceTier.highEnd) preset = 'medium';
    if (tier == DeviceTier.lowEnd) preset = 'fast';

    final initialTheme = resolveInitialTheme();
    final initialLang = resolveInitialLanguage();

    _settings = _settings.copyWith(
      isFirstLaunch: false,
      cpuPreset: preset,
      cpuThreads: 0, // Auto
      themeMode: initialTheme,
      languageCode: initialLang,
    );
    await _saveSettings();
  }

  Future<void> _applyWakelock(bool enable) async {
    try {
      await WakelockPlus.toggle(enable: enable);
    } on PlatformException catch (e) {
      if (e.code != 'channel-error') {
        debugPrint('Error toggling wakelock: $e');
      }
    } catch (e) {
      debugPrint('Error toggling wakelock: $e');
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
    final oldWakelock = _settings.keepScreenAwake;
    _settings = newSettings;
    notifyListeners();
    await _saveSettings();

    if (oldWakelock != newSettings.keepScreenAwake) {
      await _applyWakelock(newSettings.keepScreenAwake);
    }
  }

  Future<void> setLanguage(String languageCode) async {
    await updateSettings(_settings.copyWith(languageCode: languageCode));
  }

  Future<void> setThemeMode(String themeMode) async {
    await updateSettings(_settings.copyWith(themeMode: themeMode));
  }

  Future<void> setKeepScreenAwake(bool enable) async {
    await updateSettings(_settings.copyWith(keepScreenAwake: enable));
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

  Future<void> setAudioBitrate(int kbps) async {
    await updateSettings(_settings.copyWith(audioBitrateKbps: kbps));
  }

  Future<void> setOutputDirectory(String path) async {
    await updateSettings(_settings.copyWith(outputDirectory: path.trim()));
  }

  Future<void> setAudioOutputDirectory(String path) async {
    await updateSettings(_settings.copyWith(audioOutputDirectory: path.trim()));
  }

  Future<void> setCardOpacity(double opacity) async {
    final clamped = opacity.clamp(0.5, 1.0);
    await updateSettings(_settings.copyWith(cardOpacity: clamped));
  }

  Future<void> setAdvancedSettingsEnabled(bool enabled) async {
    if (!enabled) {
      await updateSettings(
        _settings.copyWith(
          isAdvancedSettingsEnabled: false,
          customPreset: 'default',
          customScaler: 'default',
        ),
      );
    } else {
      await updateSettings(_settings.copyWith(isAdvancedSettingsEnabled: true));
    }
  }

  Future<void> setCustomPreset(String preset) async {
    await updateSettings(_settings.copyWith(customPreset: preset));
  }

  Future<void> setCustomScaler(String scaler) async {
    await updateSettings(_settings.copyWith(customScaler: scaler));
  }

  void setCardOpacityFast(double opacity) {
    final clamped = opacity.clamp(0.5, 1.0);
    if ((_settings.cardOpacity - clamped).abs() > 0.001) {
      _settings = _settings.copyWith(cardOpacity: clamped);
      notifyListeners();
    }
  }

  Future<void> resetToDefaults() async {
    final currentLang = _settings.languageCode;
    final initialTheme = resolveInitialTheme();
    _settings = AppSettings(languageCode: currentLang, themeMode: initialTheme);
    notifyListeners();
    await _saveSettings();
    await _applyWakelock(_settings.keepScreenAwake);
  }

  // Active job marker for crash recovery

  static const _jobMarkerKey = 'active_conversion_job_marker';

  Future<void> saveJobMarker({
    required String inputPath,
    required String outputPath,
    required int allocatedThreads,
    required bool is4K,
    int retryCount = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'allocatedThreads': allocatedThreads,
        'is4K': is4K,
        'retryCount': retryCount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_jobMarkerKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving job marker: $e');
    }
  }

  Future<Map<String, dynamic>?> getJobMarker() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_jobMarkerKey);
      if (str != null) {
        return jsonDecode(str) as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Error reading job marker: $e');
    }
    return null;
  }

  Future<void> clearJobMarker() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_jobMarkerKey);
    } catch (e) {
      debugPrint('Error clearing job marker: $e');
    }
  }
}
