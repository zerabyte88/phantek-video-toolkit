class VideoResolution {
  final String label;
  final int width;
  final int height;

  const VideoResolution({
    required this.label,
    required this.width,
    required this.height,
  });

  String get displayName => '$label (${width}x$height)';

  static const List<VideoResolution> standardResolutions = [
    VideoResolution(label: '4K', width: 3840, height: 2160),
    VideoResolution(label: '2K', width: 2560, height: 1440),
    VideoResolution(label: '1080p', width: 1920, height: 1080),
    VideoResolution(label: '720p', width: 1280, height: 720),
    VideoResolution(label: '480p', width: 854, height: 480),
    VideoResolution(label: '360p', width: 640, height: 360),
  ];
}

class VideoInfo {
  final String filePath;
  final String fileName;
  final int width;
  final int height;
  final double durationSeconds;
  final int bitrate;
  final double fps;
  final String codec;
  final int fileSizeBytes;
  final bool hasAudio;
  final String? audioCodec;

  const VideoInfo({
    required this.filePath,
    required this.fileName,
    required this.width,
    required this.height,
    required this.durationSeconds,
    required this.bitrate,
    required this.fps,
    required this.codec,
    required this.fileSizeBytes,
    this.hasAudio = true,
    this.audioCodec,
  });

  String get resolution {
    if (height >= 2160) return '4K';
    if (height >= 1440) return '2K';
    if (height >= 1080) return '1080p';
    if (height >= 720) return '720p';
    if (height >= 480) return '480p';
    return '${height}p';
  }

  String get formattedDuration {
    final duration = Duration(seconds: durationSeconds.toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  String get formattedFileSize {
    if (fileSizeBytes >= 1073741824) {
      return '${(fileSizeBytes / 1073741824).toStringAsFixed(2)} GB';
    }
    if (fileSizeBytes >= 1048576) {
      return '${(fileSizeBytes / 1048576).toStringAsFixed(1)} MB';
    }
    return '${(fileSizeBytes / 1024).toStringAsFixed(0)} KB';
  }

  String get formattedBitrate {
    if (bitrate >= 1000000) {
      return '${(bitrate / 1000000).toStringAsFixed(1)} Mbps';
    }
    return '${(bitrate / 1000).toStringAsFixed(0)} Kbps';
  }

  List<VideoResolution> get availableDownscaleTargets {
    final targets = <VideoResolution>[
      VideoResolution(
        label: 'Original ($resolution)',
        width: width,
        height: height,
      ),
      ...VideoResolution.standardResolutions.where((r) => r.height < height),
    ];
    return targets;
  }
}
