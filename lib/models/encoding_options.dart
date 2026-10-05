import 'dart:math' as math;

enum VideoCodec {
  h264('H.264 / AVC', 'libx264', 'Live Streaming, Video Web, Rekaman HP standar. Kompatibilitas Luar Biasa.'),
  hevc('H.265 / HEVC', 'libx265', 'Streaming 4K, Film Kualitas Tinggi. Efisiensi Kompresi Sangat Tinggi.');

  final String displayName;
  final String ffmpegCodec;
  final String description;

  const VideoCodec(this.displayName, this.ffmpegCodec, this.description);
}

enum VideoContainer {
  mp4('MP4', 'mp4', 'Ringan dan universal. Media Sosial, Rekaman HP, Berbagi video.'),
  mkv('MKV', 'mkv', 'Banyak audio & subtitle dalam 1 file. Menyimpan Film, Anime, Seri TV.'),
  mov('MOV', 'mov', 'Kualitas visual mentah (tinggi). Editing Video Profesional (Premiere/FCPX).');

  final String displayName;
  final String extension;
  final String description;

  const VideoContainer(this.displayName, this.extension, this.description);
}

enum RateControlMode {
  crf('Constant Rate Factor (CRF)', 'Mempertahankan kualitas visual yang konsisten tanpa memedulikan ukuran akhir file. Sangat direkomendasikan.'),
  bitrate('Bitrate (CBR/VBR)', 'Memaksa video untuk mencapai ukuran target MB yang pasti, kualitas visual akan menyesuaikan.');

  final String displayName;
  final String description;

  const RateControlMode(this.displayName, this.description);
}

enum AudioFormat {
  mp3('MP3', 'mp3', 'libmp3lame', 'Universal (Kompatibel dengan semua perangkat dan pemutar)'),
  m4a('M4A / AAC', 'm4a', 'aac', 'Kualitas Tinggi & Efisiensi Terbaik (Apple & Android)'),
  wav('WAV', 'wav', 'pcm_s16le', 'Lossless Uncompressed (Kualitas Audio Studio Mentah)');

  final String displayName;
  final String extension;
  final String ffmpegCodec;
  final String description;

  const AudioFormat(this.displayName, this.extension, this.ffmpegCodec, this.description);
}

class EncodingOptions {
  final VideoCodec codec;
  final VideoContainer container;
  
  // Rate control
  final RateControlMode rateControlMode;
  final int crfValue;
  final int customBitrateKbps;

  // Target FPS (0 means original)
  final int targetFps;

  // Audio extraction
  final AudioFormat audioFormat;
  final int audioExtractBitrateKbps; // 0 for copy original stream, or 128, 192, 256, 320

  const EncodingOptions({
    this.codec = VideoCodec.h264,
    this.container = VideoContainer.mp4,
    this.rateControlMode = RateControlMode.crf,
    this.crfValue = 20, // Default for 1080p
    this.customBitrateKbps = 6000,
    this.targetFps = 0,
    this.audioFormat = AudioFormat.mp3,
    this.audioExtractBitrateKbps = 192,
  });

  EncodingOptions copyWith({
    VideoCodec? codec,
    VideoContainer? container,
    RateControlMode? rateControlMode,
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
      crfValue: crfValue ?? this.crfValue,
      customBitrateKbps: customBitrateKbps ?? this.customBitrateKbps,
      targetFps: targetFps ?? this.targetFps,
      audioFormat: audioFormat ?? this.audioFormat,
      audioExtractBitrateKbps:
          audioExtractBitrateKbps ?? this.audioExtractBitrateKbps,
    );
  }

  /// Calculates target video bitrate in kbps based on target resolution, CRF/Bitrate mode,
  /// and source video metadata.
  int calculateTargetBitrateKbps({
    required int targetWidth,
    required int targetHeight,
    required int sourceWidth,
    required int sourceHeight,
    required int sourceBitrateBps,
  }) {
    if (rateControlMode == RateControlMode.bitrate) {
      return customBitrateKbps;
    }
    
    // For CRF mode, calculate baseline bitrate based on target resolution
    final maxDim = targetWidth > targetHeight ? targetWidth : targetHeight;
    double baseMbps = 4.5; // High-quality 1080p baseline (~4.5 Mbps)
    if (maxDim >= 2560) {
      baseMbps = 8.5; // 2K/1440p
    } else if (maxDim >= 1920) {
      baseMbps = 4.5; // 1080p
    } else if (maxDim >= 1280) {
      baseMbps = 2.5; // 720p
    } else if (maxDim >= 854) {
      baseMbps = 1.3; // 480p
    } else {
      baseMbps = 0.8; // 360p
    }

    // Every +6 CRF roughly halves the bitrate; every -6 roughly doubles it
    final diff = crfValue - 20;
    final factor = diff / 6.0;
    double estimatedBitrateMbps = baseMbps * math.pow(0.5, factor);

    // If source video bitrate is known and lower than the calculated target,
    // don't unnecessarily upscale the bitrate beyond the source
    if (sourceBitrateBps > 0) {
      final sourceKbps = sourceBitrateBps ~/ 1000;
      if (sourceKbps > 500 && (estimatedBitrateMbps * 1000) > sourceKbps) {
        estimatedBitrateMbps = (sourceKbps / 1000.0) * 0.95;
      }
    }

    // HEVC has ~30% higher compression efficiency, so target bitrate can be slightly leaner
    if (codec == VideoCodec.hevc) {
      estimatedBitrateMbps *= 0.75;
    }

    return (estimatedBitrateMbps * 1000).round().clamp(300, 50000);
  }
}
