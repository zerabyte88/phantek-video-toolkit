enum VideoCodec {
  h264('H.264 / AVC', 'libx264', 'Universal, kompatibilitas tertinggi'),
  hevc('H.265 / HEVC', 'libx265', 'Kompresi ~50% lebih efisien'),
  vp9('VP9', 'libvpx-vp9', 'Standar WebM / YouTube'),
  mpeg4('MPEG-4', 'mpeg4', 'Kompatibilitas perangkat lawas');

  final String displayName;
  final String ffmpegCodec;
  final String description;

  const VideoCodec(this.displayName, this.ffmpegCodec, this.description);
}

enum VideoContainer {
  mp4('MP4', 'mp4', 'Paling kompatibel di semua HP dan pemutar'),
  mkv('MKV', 'mkv', 'Kontainer fleksibel untuk berbagai codec'),
  mov('MOV', 'mov', 'Format standar Apple QuickTime'),
  webm('WebM', 'webm', 'Format terbuka, optimal untuk web');

  final String displayName;
  final String extension;
  final String description;

  const VideoContainer(this.displayName, this.extension, this.description);
}

enum BitratePreset {
  auto('Auto (Rekomendasi)', 'Otomatis dihitung sesuai resolusi sasaran'),
  high('Kualitas Tinggi', 'Bitrate tinggi untuk mempertahankan detail maksimal'),
  medium('Seimbang', 'Keseimbangan terbaik antara ukuran dan kejernihan'),
  low('Hemat Ukuran', 'Kompresi agresif untuk ukuran file paling hemat'),
  custom('Kustom', 'Tentukan nilai bitrate secara manual');

  final String displayName;
  final String description;

  const BitratePreset(this.displayName, this.description);
}

class EncodingOptions {
  final VideoCodec codec;
  final VideoContainer container;
  final BitratePreset bitratePreset;
  final int? customBitrateKbps;

  const EncodingOptions({
    this.codec = VideoCodec.h264,
    this.container = VideoContainer.mp4,
    this.bitratePreset = BitratePreset.auto,
    this.customBitrateKbps,
  });

  EncodingOptions copyWith({
    VideoCodec? codec,
    VideoContainer? container,
    BitratePreset? bitratePreset,
    int? customBitrateKbps,
  }) {
    return EncodingOptions(
      codec: codec ?? this.codec,
      container: container ?? this.container,
      bitratePreset: bitratePreset ?? this.bitratePreset,
      customBitrateKbps: customBitrateKbps ?? this.customBitrateKbps,
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
    if (bitratePreset == BitratePreset.custom && customBitrateKbps != null && customBitrateKbps! > 0) {
      return customBitrateKbps!;
    }

    final sourcePixels = sourceWidth * sourceHeight;
    final targetPixels = targetWidth * targetHeight;
    final ratio = sourcePixels > 0 ? (targetPixels / sourcePixels) : 1.0;

    int baseBitrate;
    if (sourceBitrateBps > 0) {
      baseBitrate = (sourceBitrateBps * ratio * 1.15).toInt();
    } else {
      // Fallback base estimates
      if (targetHeight >= 2160) {
        baseBitrate = 18000000;
      } else if (targetHeight >= 1440) {
        baseBitrate = 10000000;
      } else if (targetHeight >= 1080) {
        baseBitrate = 6000000;
      } else if (targetHeight >= 720) {
        baseBitrate = 3000000;
      } else if (targetHeight >= 480) {
        baseBitrate = 1500000;
      } else {
        baseBitrate = 800000;
      }
    }

    // Apply preset multipliers
    double multiplier;
    switch (bitratePreset) {
      case BitratePreset.high:
        multiplier = 1.4;
        break;
      case BitratePreset.medium:
        multiplier = 1.0;
        break;
      case BitratePreset.low:
        multiplier = 0.65;
        break;
      case BitratePreset.auto:
      case BitratePreset.custom:
        multiplier = 1.0;
        break;
    }

    int calculated = (baseBitrate * multiplier).toInt();

    // Clamp within reasonable limits per resolution
    if (targetHeight >= 2160) {
      calculated = calculated.clamp(8000000, 30000000);
    } else if (targetHeight >= 1440) {
      calculated = calculated.clamp(5000000, 18000000);
    } else if (targetHeight >= 1080) {
      calculated = calculated.clamp(3000000, 12000000);
    } else if (targetHeight >= 720) {
      calculated = calculated.clamp(1500000, 6000000);
    } else if (targetHeight >= 480) {
      calculated = calculated.clamp(800000, 3000000);
    } else {
      calculated = calculated.clamp(400000, 1500000);
    }

    // HEVC / H.265 requires ~35% less bitrate for same quality
    if (codec == VideoCodec.hevc) {
      calculated = (calculated * 0.70).toInt();
    } else if (codec == VideoCodec.vp9) {
      calculated = (calculated * 0.75).toInt();
    }

    return (calculated / 1000).round();
  }
}
