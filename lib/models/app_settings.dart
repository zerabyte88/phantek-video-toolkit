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

  /// True if Sakura theme is unlocked.
  final bool isEasterEggUnlocked;

  /// Card surface opacity (0.50 to 1.00).
  final double cardOpacity;

  const AppSettings({
    this.cpuThreads = 0,
    this.ramBufferMb = 512,
    this.cpuPreset = 'medium',
    this.audioBitrateKbps = 128,
    this.languageCode = 'en',
    this.themeMode = 'oled_snowfall',
    this.keepScreenAwake = false,
    this.isFirstLaunch = true,
    this.outputDirectory = '',
    this.audioOutputDirectory = '',
    this.isEasterEggUnlocked = false,
    this.cardOpacity = 1.0,
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
    bool? isEasterEggUnlocked,
    double? cardOpacity,
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
      isEasterEggUnlocked: isEasterEggUnlocked ?? this.isEasterEggUnlocked,
      cardOpacity: cardOpacity != null
          ? cardOpacity.clamp(0.5, 1.0)
          : this.cardOpacity,
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
      'isEasterEggUnlocked': isEasterEggUnlocked,
      'cardOpacity': cardOpacity,
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
      themeMode: json['themeMode'] as String? ?? 'oled_snowfall',
      keepScreenAwake: json['keepScreenAwake'] as bool? ?? false,
      isFirstLaunch: json['isFirstLaunch'] as bool? ?? true,
      outputDirectory: json['outputDirectory'] as String? ?? '',
      audioOutputDirectory: json['audioOutputDirectory'] as String? ?? '',
      isEasterEggUnlocked:
          json['isEasterEggUnlocked'] as bool? ??
          (json['themeMode'] == 'oled_sakura' || json['themeMode'] == 'sakura'),
      cardOpacity:
          (json['cardOpacity'] as num?)?.toDouble().clamp(0.5, 1.0) ?? 1.0,
    );
  }
}
