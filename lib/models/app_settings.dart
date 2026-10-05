import 'dart:io';

class AppSettings {
  /// Number of CPU threads for FFmpeg. 0 means auto-detect / use all.
  final int cpuThreads;

  /// RAM buffer size in MB for FFmpeg memory caching / buffer management.
  final int ramBufferMb;

  /// FFmpeg preset for x264/x265 (ultrafast, superfast, veryfast, faster, fast, medium, slow).
  final String cpuPreset;

  /// Audio bitrate in kbps (e.g. 64, 128, 192, 256). 0 means mute / strip audio.
  final int audioBitrateKbps;

  /// Selected language code: 'id', 'en', 'ja', 'zh_CN', 'zh_TW', 'ko'.
  final String languageCode;

  /// App theme mode: 'dark', 'oled', 'light'.
  final String themeMode;

  /// Keep screen awake / prevent display sleeping during encoding or app usage.
  final bool keepScreenAwake;

  /// True if the app is launched for the first time
  final bool isFirstLaunch;

  /// Custom output directory path chosen by the user. If empty, defaults to Movies folder.
  final String outputDirectory;

  /// Custom output directory path for extracted audio files. If empty, defaults to Music folder.
  final String audioOutputDirectory;

  const AppSettings({
    this.cpuThreads = 0,
    this.ramBufferMb = 512,
    this.cpuPreset = 'medium',
    this.audioBitrateKbps = 128,
    this.languageCode = 'id',
    this.themeMode = 'dark',
    this.keepScreenAwake = false,
    this.isFirstLaunch = true,
    this.outputDirectory = '',
    this.audioOutputDirectory = '',
  });

  /// Detected hardware core count of the phone.
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
  }) {
    return AppSettings(
      cpuThreads: cpuThreads ?? this.cpuThreads,
      ramBufferMb: ramBufferMb ?? this.ramBufferMb,
      cpuPreset: cpuPreset ?? this.cpuPreset,
      audioBitrateKbps: audioBitrateKbps ?? this.audioBitrateKbps,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      audioOutputDirectory: audioOutputDirectory ?? this.audioOutputDirectory,
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
    };
  }

  /// Sanitize preset to ensure only fast, medium, or slow are used.
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
      ramBufferMb: json['ramBufferMb'] as int? ?? 512,
      cpuPreset: sanitizePreset(json['cpuPreset'] as String?),
      audioBitrateKbps: json['audioBitrateKbps'] as int? ?? 128,
      languageCode: json['languageCode'] as String? ?? 'id',
      themeMode: json['themeMode'] as String? ?? 'dark',
      keepScreenAwake: json['keepScreenAwake'] as bool? ?? false,
      isFirstLaunch: json['isFirstLaunch'] as bool? ?? true,
      outputDirectory: json['outputDirectory'] as String? ?? '',
      audioOutputDirectory: json['audioOutputDirectory'] as String? ?? '',
    );
  }
}
