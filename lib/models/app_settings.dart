import 'dart:io';

class AppSettings {
  /// Number of CPU threads for FFmpeg. 0 means auto-detect / use all.
  final int cpuThreads;

  /// RAM buffer size in MB for FFmpeg memory caching / buffer management.
  final int ramBufferMb;

  /// FFmpeg preset for x264/x265 (ultrafast, superfast, veryfast, faster, fast, medium, slow).
  final String cpuPreset;

  /// Whether to attempt hardware-accelerated encoding (MediaCodec on Android).
  final bool hardwareAcceleration;

  /// Audio bitrate in kbps (e.g. 64, 128, 192, 256). 0 means mute / strip audio.
  final int audioBitrateKbps;

  /// Selected language code: 'id', 'en', 'ja', 'zh_CN', 'zh_TW', 'ko'.
  final String languageCode;

  const AppSettings({
    this.cpuThreads = 0,
    this.ramBufferMb = 512,
    this.cpuPreset = 'medium',
    this.hardwareAcceleration = false,
    this.audioBitrateKbps = 128,
    this.languageCode = 'id',
  });

  /// Detected hardware core count of the phone.
  static int get deviceCoreCount => Platform.numberOfProcessors;

  AppSettings copyWith({
    int? cpuThreads,
    int? ramBufferMb,
    String? cpuPreset,
    bool? hardwareAcceleration,
    int? audioBitrateKbps,
    String? languageCode,
  }) {
    return AppSettings(
      cpuThreads: cpuThreads ?? this.cpuThreads,
      ramBufferMb: ramBufferMb ?? this.ramBufferMb,
      cpuPreset: cpuPreset ?? this.cpuPreset,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
      audioBitrateKbps: audioBitrateKbps ?? this.audioBitrateKbps,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cpuThreads': cpuThreads,
      'ramBufferMb': ramBufferMb,
      'cpuPreset': cpuPreset,
      'hardwareAcceleration': hardwareAcceleration,
      'audioBitrateKbps': audioBitrateKbps,
      'languageCode': languageCode,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      cpuThreads: json['cpuThreads'] as int? ?? 0,
      ramBufferMb: json['ramBufferMb'] as int? ?? 512,
      cpuPreset: json['cpuPreset'] as String? ?? 'medium',
      hardwareAcceleration: json['hardwareAcceleration'] as bool? ?? false,
      audioBitrateKbps: json['audioBitrateKbps'] as int? ?? 128,
      languageCode: json['languageCode'] as String? ?? 'id',
    );
  }
}
