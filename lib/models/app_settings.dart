// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 zerabyte88

import 'dart:io';

class AppSettings {
  /// CPU thread count. 0 triggers auto-detection.
  final int cpuThreads;

  /// RAM buffer size in MB.
  final int ramBufferMb;

  /// Encoding speed preset.
  final String cpuPreset;

  /// Audio bitrate in kbps. 0 mutes audio.
  final int audioBitrateKbps;

  /// Active language code.
  final String languageCode;

  /// Active theme identifier.
  final String themeMode;

  /// Keep screen awake during app usage.
  final bool keepScreenAwake;

  /// True on first launch.
  final bool isFirstLaunch;

  /// Custom video output directory.
  final String outputDirectory;

  /// Custom audio output directory.
  final String audioOutputDirectory;

  /// Card surface opacity (0.50 to 1.00).
  final double cardOpacity;

  /// True if advanced experimental settings are enabled.
  final bool isAdvancedSettingsEnabled;

  /// Custom x264 preset ('default', 'ultrafast', 'superfast', 'veryfast', 'faster', 'fast', 'medium', 'slow', 'slower', 'veryslow').
  final String customPreset;

  /// Custom scaler algorithm ('default', 'fast_bilinear', 'bilinear', 'bicubic', 'area', 'lanczos', 'spline', 'gauss').
  final String customScaler;

  const AppSettings({
    this.cpuThreads = 0,
    this.ramBufferMb = 512,
    this.cpuPreset = 'medium',
    this.audioBitrateKbps = 128,
    this.languageCode = 'en',
    this.themeMode = 'oled_pure',
    this.keepScreenAwake = false,
    this.isFirstLaunch = true,
    this.outputDirectory = '',
    this.audioOutputDirectory = '',
    this.cardOpacity = 1.0,
    this.isAdvancedSettingsEnabled = false,
    this.customPreset = 'default',
    this.customScaler = 'default',
  });

  /// Physical CPU core count.
  static int get deviceCoreCount => Platform.numberOfProcessors;

  AppSettings copyWith({
    int? cpuThreads,
    int? ramBufferMb,
    String? cpuPreset,
    int? audioBitrateKbps,
    String? languageCode,
    String? themeMode,
    bool? keepScreenAwake,
    bool? isFirstLaunch,
    String? outputDirectory,
    String? audioOutputDirectory,
    double? cardOpacity,
    bool? isAdvancedSettingsEnabled,
    String? customPreset,
    String? customScaler,
  }) {
    return AppSettings(
      cpuThreads: cpuThreads ?? this.cpuThreads,
      ramBufferMb: ramBufferMb != null
          ? (ramBufferMb > 2048 ? 2048 : ramBufferMb)
          : this.ramBufferMb,
      cpuPreset: cpuPreset ?? this.cpuPreset,
      audioBitrateKbps: audioBitrateKbps ?? this.audioBitrateKbps,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      audioOutputDirectory: audioOutputDirectory ?? this.audioOutputDirectory,
      cardOpacity: cardOpacity != null
          ? cardOpacity.clamp(0.5, 1.0)
          : this.cardOpacity,
      isAdvancedSettingsEnabled:
          isAdvancedSettingsEnabled ?? this.isAdvancedSettingsEnabled,
      customPreset: customPreset ?? this.customPreset,
      customScaler: customScaler ?? this.customScaler,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cpuThreads': cpuThreads,
      'ramBufferMb': ramBufferMb,
      'cpuPreset': cpuPreset,
      'audioBitrateKbps': audioBitrateKbps,
      'languageCode': languageCode,
      'themeMode': themeMode,
      'keepScreenAwake': keepScreenAwake,
      'isFirstLaunch': isFirstLaunch,
      'outputDirectory': outputDirectory,
      'audioOutputDirectory': audioOutputDirectory,
      'cardOpacity': cardOpacity,
      'isAdvancedSettingsEnabled': isAdvancedSettingsEnabled,
      'customPreset': customPreset,
      'customScaler': customScaler,
    };
  }

  /// Normalizes preset to supported values (fast, medium, slow).
  static String sanitizePreset(String? preset) {
    if (preset == 'fast' || preset == 'slow') return preset!;
    if (preset == 'ultrafast' ||
        preset == 'superfast' ||
        preset == 'veryfast' ||
        preset == 'faster') {
      return 'fast';
    }
    return 'medium';
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      cpuThreads: json['cpuThreads'] as int? ?? 0,
      ramBufferMb: ((json['ramBufferMb'] as int? ?? 512) > 2048)
          ? 2048
          : (json['ramBufferMb'] as int? ?? 512),
      cpuPreset: sanitizePreset(json['cpuPreset'] as String?),
      audioBitrateKbps: json['audioBitrateKbps'] as int? ?? 128,
      languageCode: json['languageCode'] as String? ?? 'en',
      themeMode: json['themeMode'] as String? ?? 'oled_pure',
      keepScreenAwake: json['keepScreenAwake'] as bool? ?? false,
      isFirstLaunch: json['isFirstLaunch'] as bool? ?? true,
      outputDirectory: json['outputDirectory'] as String? ?? '',
      audioOutputDirectory: json['audioOutputDirectory'] as String? ?? '',
      cardOpacity:
          (json['cardOpacity'] as num?)?.toDouble().clamp(0.5, 1.0) ?? 1.0,
      isAdvancedSettingsEnabled:
          json['isAdvancedSettingsEnabled'] as bool? ?? false,
      customPreset: json['customPreset'] as String? ?? 'default',
      customScaler: json['customScaler'] as String? ?? 'default',
    );
  }
}
