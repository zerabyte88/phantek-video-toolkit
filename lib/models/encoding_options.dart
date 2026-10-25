// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 zerabyte88

import 'dart:math' as math;

enum VideoCodec {
  h264(
    'H.264 / AVC',
    'libx264',
    'Live Streaming, Video Web, Rekaman HP standar. Kompatibilitas Luar Biasa.',
  );

  final String displayName;
  final String ffmpegCodec;
  final String description;

  const VideoCodec(this.displayName, this.ffmpegCodec, this.description);
}

enum VideoContainer {
  mp4(
    'MP4',
    'mp4',
    'Ringan dan universal. Media Sosial, Rekaman HP, Berbagi video.',
  ),
  mkv(
    'MKV',
    'mkv',
    'Banyak audio & subtitle dalam 1 file. Menyimpan Film, Anime, Seri TV.',
  ),
  mov(
    'MOV',
    'mov',
    'Kualitas visual mentah (tinggi). Editing Video Profesional (Premiere/FCPX).',
  );

  final String displayName;
  final String extension;
  final String description;

  const VideoContainer(this.displayName, this.extension, this.description);
}

enum RateControlMode {
  crf(
    'Constant Rate Factor (CRF)',
    'Mempertahankan kualitas visual yang konsisten tanpa memedulikan ukuran akhir file. Sangat direkomendasikan.',
  ),
  bitrate(
    'Bitrate (CBR/VBR)',
    'Memaksa video untuk mencapai ukuran target MB yang pasti, kualitas visual akan menyesuaikan.',
  );

  final String displayName;
  final String description;

  const RateControlMode(this.displayName, this.description);
}

enum AudioFormat {
  mp3(
    'MP3',
    'mp3',
    'libmp3lame',
    'Universal (Kompatibel dengan semua perangkat dan pemutar)',
  ),
  m4a(
    'M4A / AAC',
    'm4a',
    'aac',
    'Kualitas Tinggi & Efisiensi Terbaik (Apple & Android)',
  ),
  wav(
    'WAV',
    'wav',
    'pcm_s16le',
    'Lossless Uncompressed (Kualitas Audio Studio Mentah)',
  );

  final String displayName;
  final String extension;
  final String ffmpegCodec;
  final String description;

  const AudioFormat(
    this.displayName,
    this.extension,
    this.ffmpegCodec,
    this.description,
  );
}

enum SpeedPreset {
  fast(
    'Cepat',
    'area',
    'veryfast',
    24,
    'Kecepatan maksimal & anti-moiré, interpolasi area',
  ),
  normal(
    'Normal',
    'bicubic',
    'faster',
    22,
    'Keseimbangan ideal kecepatan dan kualitas visual',
  ),
  max(
    'Maksimal',
    'lanczos+accurate_rnd+full_chroma_int',
    'fast',
    20,
    'Detail & warna paling tajam, kompresi efisien',
  );

  final String displayName;
  final String scaler;
  final String x264Preset;
  final int defaultCrf;
  final String description;

  const SpeedPreset(
    this.displayName,
    this.scaler,
    this.x264Preset,
    this.defaultCrf,
    this.description,
  );

  String get cleanScaler {
    switch (this) {
      case SpeedPreset.fast:
        return 'Area';
      case SpeedPreset.normal:
        return 'Bicubic';
      case SpeedPreset.max:
        return 'Lanczos';
    }
  }

  static SpeedPreset fromCpuPreset(String? preset) {
    switch (preset) {
      case 'fast':
        return SpeedPreset.fast;
      case 'slow':
        return SpeedPreset.max;
      case 'medium':
      default:
        return SpeedPreset.normal;
    }
  }

  String toCpuPreset() {
    switch (this) {
      case SpeedPreset.fast:
        return 'fast';
      case SpeedPreset.max:
        return 'slow';
      case SpeedPreset.normal:
        return 'medium';
    }
  }
}

class EncodingOptions {
  final VideoCodec codec;
  final VideoContainer container;

  // Rate control
  final RateControlMode rateControlMode;
  final SpeedPreset speedPreset;
  final int crfValue;
  final int customBitrateKbps;

  // Target FPS (0: original)
  final int targetFps;

  // Audio extraction
  final AudioFormat audioFormat;
  final int audioExtractBitrateKbps; // 0 for stream copy, or target kbps

  /// Convenience alias for [crfValue].
  int get crf => crfValue;

  const EncodingOptions({
    this.codec = VideoCodec.h264,
    this.container = VideoContainer.mp4,
    this.rateControlMode = RateControlMode.crf,
    this.speedPreset = SpeedPreset.normal,
    this.crfValue = 22,
    this.customBitrateKbps = 10000,
    this.targetFps = 0,
    this.audioFormat = AudioFormat.mp3,
    this.audioExtractBitrateKbps = 192,
  });

  EncodingOptions copyWith({
    VideoCodec? codec,
    VideoContainer? container,
    RateControlMode? rateControlMode,
    SpeedPreset? speedPreset,
    int? crfValue,
    int? customBitrateKbps,
    int? targetFps,
    AudioFormat? audioFormat,
    int? audioExtractBitrateKbps,
  }) {
    return EncodingOptions(
      codec: codec ?? this.codec,
      container: container ?? this.container,
      rateControlMode: rateControlMode ?? this.rateControlMode,
      speedPreset: speedPreset ?? this.speedPreset,
      crfValue: crfValue ?? this.crfValue,
      customBitrateKbps: customBitrateKbps ?? this.customBitrateKbps,
      targetFps: targetFps ?? this.targetFps,
      audioFormat: audioFormat ?? this.audioFormat,
      audioExtractBitrateKbps:
          audioExtractBitrateKbps ?? this.audioExtractBitrateKbps,
    );
  }

  /// Estimates target video bitrate in kbps.
  ///
  /// When [isHardware] is true, applies dedicated hardware bitrate allocation and safe quality floors
  /// because mobile ASIC hardware encoders (MediaCodec) lack libx264's advanced
  /// psychovisual rate control and require higher bitrate to prevent pixelation.
  int calculateTargetBitrateKbps({
    required int targetWidth,
    required int targetHeight,
    required int sourceWidth,
    required int sourceHeight,
    required int sourceBitrateBps,
    bool isHardware = false,
  }) {
    final maxDim = targetWidth > targetHeight ? targetWidth : targetHeight;

    if (rateControlMode == RateControlMode.bitrate) {
      if (isHardware && customBitrateKbps > 0) {
        // Safe bitrate floors for MediaCodec hardware encoders to prevent macroblocking
        final minHwKbps = maxDim >= 2560
            ? 28000
            : (maxDim >= 1920
                ? 14000
                : (maxDim >= 1280 ? 8500 : 4000));
        return math.max(customBitrateKbps, minHwKbps);
      }
      return customBitrateKbps;
    }

    // Baseline bitrate by target resolution.
    // Hardware encoders on mobile SoCs lack libx264's deep psychovisual optimizations (psy-rd, aq-mode)
    // and require ~2x to 2.5x the bitrate to deliver sharp, artifact-free video.
    final double baseMbps;
    if (isHardware) {
      if (maxDim >= 2560) {
        baseMbps = 32.0;
      } else if (maxDim >= 1920) {
        baseMbps = 15.0;
      } else if (maxDim >= 1280) {
        baseMbps = 9.0;
      } else if (maxDim >= 854) {
        baseMbps = 5.0;
      } else {
        baseMbps = 3.0;
      }
    } else {
      if (maxDim >= 2560) {
        baseMbps = 8.5;
      } else if (maxDim >= 1920) {
        baseMbps = 4.5;
      } else if (maxDim >= 1280) {
        baseMbps = 2.5;
      } else if (maxDim >= 854) {
        baseMbps = 1.3;
      } else {
        baseMbps = 0.8;
      }
    }

    // Scale factor: ±6 CRF halves or doubles bitrate
    final diff = crfValue - 20;
    final factor = diff / 6.0;
    double estimatedBitrateMbps = baseMbps * math.pow(0.5, factor);

    // Minimum safe quality floor for hardware encoders per resolution tier
    final minFloorKbps = isHardware
        ? (maxDim >= 2560
            ? 25000
            : (maxDim >= 1920
                ? 12000
                : (maxDim >= 1280 ? 7500 : 3500)))
        : 300;

    // Avoid upscaling bitrate beyond source video unless hardware encoder needs minimal quality floor
    if (sourceBitrateBps > 0) {
      final sourceKbps = sourceBitrateBps ~/ 1000;
      final maxMultiplier = isHardware ? 1.25 : 0.95;
      if (sourceKbps > 500 && (estimatedBitrateMbps * 1000) > sourceKbps) {
        final cappedMbps = (sourceKbps / 1000.0) * maxMultiplier;
        estimatedBitrateMbps = isHardware
            ? math.max(cappedMbps, minFloorKbps / 1000.0)
            : cappedMbps;
      }
    }

    return (estimatedBitrateMbps * 1000).round().clamp(minFloorKbps, 50000);
  }
}
