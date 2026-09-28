enum VideoCodec {
  h264('H.264 / AVC', 'libx264', 'Live Streaming, Video Web, Rekaman HP standar. Kompatibilitas Luar Biasa.'),
  hevc('H.265 / HEVC', 'libx265', 'Streaming 4K, Film Kualitas Tinggi. Efisiensi Kompresi Sangat Tinggi.'),
  vp9('VP9', 'libvpx-vp9', 'YouTube, Google Products. Efisiensi Kompresi Sangat Tinggi.');

  final String displayName;
  final String ffmpegCodec;
  final String description;

  const VideoCodec(this.displayName, this.ffmpegCodec, this.description);
}

enum VideoContainer {
  mp4('MP4', 'mp4', 'Ringan dan universal. Media Sosial, Rekaman HP, Berbagi video.'),
  mkv('MKV', 'mkv', 'Banyak audio & subtitle dalam 1 file. Menyimpan Film, Anime, Seri TV.'),
  mov('MOV', 'mov', 'Kualitas visual mentah (tinggi). Editing Video Profesional (Premiere/FCPX).'),
  webm('WebM', 'webm', 'Mendukung video transparan. Animasi Web, Konten Streaming Online.');

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

class EncodingOptions {
  final VideoCodec codec;
  final VideoContainer container;
  
  // Rate control
  final RateControlMode rateControlMode;
  final int crfValue;
  final int customBitrateKbps;

  // Target FPS (0 means original)
  final int targetFps;

  const EncodingOptions({
    this.codec = VideoCodec.h264,
    this.container = VideoContainer.mp4,
    this.rateControlMode = RateControlMode.crf,
    this.crfValue = 20, // Default for 1080p
    this.customBitrateKbps = 6000,
    this.targetFps = 0,
  });

  EncodingOptions copyWith({
    VideoCodec? codec,
    VideoContainer? container,
    RateControlMode? rateControlMode,
    int? crfValue,
    int? customBitrateKbps,
    int? targetFps,
  }) {
    return EncodingOptions(
      codec: codec ?? this.codec,
      container: container ?? this.container,
      rateControlMode: rateControlMode ?? this.rateControlMode,
      crfValue: crfValue ?? this.crfValue,
      customBitrateKbps: customBitrateKbps ?? this.customBitrateKbps,
      targetFps: targetFps ?? this.targetFps,
    );
  }

  /// Calculates target video bitrate in kbps based on resolution, source video, and preset.
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
    
    // For CRF mode, it's variable, but we can return an estimate for UI display if needed.
    // Or we just return 0 to indicate CRF is in use.
    return 0;
  }
}
