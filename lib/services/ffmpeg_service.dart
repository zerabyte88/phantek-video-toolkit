import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/log.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import '../models/encoding_options.dart';
import '../models/video_info.dart';

class FFmpegService {
  /// Probe a video file and return its info.
  static Future<VideoInfo?> getVideoInfo(String filePath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(filePath);
      final info = session.getMediaInformation();
      if (info == null) return null;

      final streams = info.getStreams();
      final videoStream = streams.firstWhere(
        (s) => s.getType() == 'video',
        orElse: () => streams.first,
      );

      int width = videoStream.getWidth() ?? 0;
      int height = videoStream.getHeight() ?? 0;

      // Check for rotation in stream tags
      final tags = videoStream.getAllProperties()?['tags'];
      if (tags != null && tags is Map) {
        final rotate = tags['rotate'];
        if (rotate == '90' || rotate == '270' || rotate == '-90') {
          final temp = width;
          width = height;
          height = temp;
        }
      }

      // Parse duration
      final durationStr = info.getDuration();
      final duration = double.tryParse(durationStr ?? '0') ?? 0;

      // Parse bitrate
      final bitrateStr = info.getBitrate();
      final bitrate = int.tryParse(bitrateStr ?? '0') ?? 0;

      // Parse FPS
      double fps = 30.0;
      final fpsStr = videoStream.getRealFrameRate();
      if (fpsStr != null && fpsStr.contains('/')) {
        final parts = fpsStr.split('/');
        final num = double.tryParse(parts[0]) ?? 30;
        final den = double.tryParse(parts[1]) ?? 1;
        if (den > 0) fps = num / den;
      } else if (fpsStr != null) {
        fps = double.tryParse(fpsStr) ?? 30.0;
      }

      // Get codec
      final codec = videoStream.getCodec() ?? 'unknown';

      // Parse audio stream info
      final audioStreams = streams
          .where((s) => s.getType() == 'audio')
          .toList();
      final hasAudio = audioStreams.isNotEmpty;
      final audioCodec = hasAudio ? audioStreams.first.getCodec() : null;

      // Get file size
      final file = File(filePath);
      final fileSize = await file.length();

      return VideoInfo(
        filePath: filePath,
        fileName: file.uri.pathSegments.last,
        width: width,
        height: height,
        durationSeconds: duration,
        bitrate: bitrate,
        fps: fps,
        codec: codec,
        fileSizeBytes: fileSize,
        hasAudio: hasAudio,
        audioCodec: audioCodec,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get or create the output directory for converted media.
  /// If [customPath] is provided and valid, uses it.
  /// Otherwise targets `/storage/emulated/0/Music` for audio or `/storage/emulated/0/Movies` for video directly on Android.
  static Future<Directory> getOutputDirectory({
    String? customPath,
    bool isAudio = false,
  }) async {
    if (customPath != null && customPath.trim().isNotEmpty) {
      final customDir = Directory(customPath.trim());
      try {
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }
        return customDir;
      } catch (_) {
        // Fallback to default directory
      }
    }

    if (Platform.isAndroid) {
      final defaultPath = isAudio
          ? '/storage/emulated/0/Music'
          : '/storage/emulated/0/Movies';
      final targetDir = Directory(defaultPath);
      try {
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
        return targetDir;
      } catch (e) {
        // Fallback for devices with different mount points or restricted paths
        try {
          final extDirs = await getExternalStorageDirectories(
            type: isAudio ? StorageDirectory.music : StorageDirectory.movies,
          );
          if (extDirs != null && extDirs.isNotEmpty) {
            final fallback = extDirs.first;
            if (!await fallback.exists()) {
              await fallback.create(recursive: true);
            }
            return fallback;
          }
        } catch (_) {}

        final appDocDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory(
          '${appDocDir.path}/${isAudio ? "Music" : "Movies"}',
        );
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        return fallbackDir;
      }
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dir = Directory(
        '${appDocDir.path}/${isAudio ? "Music" : "Movies"}',
      );
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }

  /// Generates a unique output file path in [outputDir] to avoid collisions.
  /// If `base-res.ext` exists, appends an incremental number: `base-res-2.ext`, `base-res-3.ext`, etc.
  static Future<String> generateUniqueOutputPath({
    required Directory outputDir,
    required String fileName,
    required VideoResolution targetResolution,
    required VideoContainer container,
  }) async {
    final ext = container.extension;
    final sanitizedBase = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final String resSuffix =
        targetResolution.label.toLowerCase().startsWith('original')
        ? '${targetResolution.height}p'
        : targetResolution.label.toLowerCase();

    final dirPath =
        outputDir.path.endsWith('/') || outputDir.path.endsWith('\\')
        ? outputDir.path.substring(0, outputDir.path.length - 1)
        : outputDir.path;
    final sep = Platform.pathSeparator;

    final basePath = '$dirPath$sep$sanitizedBase-$resSuffix.$ext';
    if (!await File(basePath).exists()) {
      return basePath;
    }

    int counter = 2;
    while (true) {
      final candidatePath =
          '$dirPath$sep$sanitizedBase-$resSuffix-$counter.$ext';
      if (!await File(candidatePath).exists()) {
        return candidatePath;
      }
      counter++;
    }
  }

  /// Generates a unique output file path in [outputDir] for audio extraction.
  static Future<String> generateUniqueAudioOutputPath({
    required Directory outputDir,
    required String fileName,
    required AudioFormat audioFormat,
  }) async {
    final ext = audioFormat.extension;
    final sanitizedBase = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final dirPath =
        outputDir.path.endsWith('/') || outputDir.path.endsWith('\\')
        ? outputDir.path.substring(0, outputDir.path.length - 1)
        : outputDir.path;
    final sep = Platform.pathSeparator;

    final basePath = '$dirPath$sep$sanitizedBase-audio.$ext';
    if (!await File(basePath).exists()) {
      return basePath;
    }

    int counter = 2;
    while (true) {
      final candidatePath = '$dirPath$sep$sanitizedBase-audio-$counter.$ext';
      if (!await File(candidatePath).exists()) {
        return candidatePath;
      }
      counter++;
    }
  }

  /// Construct tokenized FFmpeg CLI arguments for video transcoding/downscaling.
  /// Pure method without side-effects, allowing deterministic unit testing.
  static List<String> buildVideoArguments({
    required VideoInfo sourceVideo,
    required VideoResolution targetResolution,
    required EncodingOptions encodingOptions,
    required AppSettings appSettings,
    required String outputPath,
  }) {
    // Calculate target dimensions (must be even numbers)
    int targetW = targetResolution.width;
    int targetH = targetResolution.height;

    // Handle portrait videos: if source is portrait, swap target dimensions
    if (sourceVideo.height > sourceVideo.width) {
      targetW = targetResolution.height;
      targetH = targetResolution.width;
    }

    final sourceAspect =
        sourceVideo.width / (sourceVideo.height > 0 ? sourceVideo.height : 1);
    final targetAspect = targetW / (targetH > 0 ? targetH : 1);

    if (sourceAspect > targetAspect) {
      // Source is wider, limit by width
      targetH = (targetW / sourceAspect).round();
    } else {
      // Source is taller, limit by height
      targetW = (targetH * sourceAspect).round();
    }

    // Ensure even dimensions for encoder requirements
    targetW = (targetW ~/ 2) * 2;
    targetH = (targetH ~/ 2) * 2;

    // Threads argument (calibrated for mobile ARM big.LITTLE processors to prevent thermal throttling)
    final totalCores = Platform.numberOfProcessors > 0
        ? Platform.numberOfProcessors
        : 8;
    final effectiveThreads = appSettings.cpuThreads > 0
        ? appSettings.cpuThreads
        : (totalCores > 4 ? totalCores - 2 : totalCores).clamp(1, 6);

    // FPS filter
    String fpsFilter = '';
    if (encodingOptions.targetFps > 0) {
      fpsFilter = 'fps=fps=${encodingOptions.targetFps},';
    }

    final isOriginalResolution =
        targetW == sourceVideo.width && targetH == sourceVideo.height;

    // Check eligibility for Smart Stream Copy (Lossless Passthrough)
    final isSourceH264 = sourceVideo.codec.toLowerCase().contains('h264') ||
        sourceVideo.codec.toLowerCase().contains('avc');
    final isFpsSame = encodingOptions.targetFps <= 0 ||
        encodingOptions.targetFps == sourceVideo.fps.round();
    final bool isStreamCopy = isOriginalResolution && isFpsSame && isSourceH264;

    String vfFilter = '';
    List<String> codecArgs = [];
    List<String> audioArgs = [];

    if (isStreamCopy) {
      // ─── Smart Stream Copy Pipeline (Lossless Passthrough) ────────────────
      codecArgs = ['-c:v', 'copy'];

      if (!sourceVideo.hasAudio || appSettings.audioBitrateKbps <= 0) {
        audioArgs = ['-an'];
      } else {
        final isSourceAac =
            sourceVideo.audioCodec?.toLowerCase().contains('aac') ?? false;
        if (isSourceAac || encodingOptions.container == VideoContainer.mkv) {
          audioArgs = ['-c:a', 'copy'];
        } else {
          audioArgs = [
            '-c:a',
            'aac',
            '-b:a',
            '${appSettings.audioBitrateKbps}k',
          ];
        }
      }
    } else {
      // ─── Software Encoding Pipeline (libx264 CPU) ──────────────────────────
      final targetBitrateKbps = encodingOptions.calculateTargetBitrateKbps(
        targetWidth: targetW,
        targetHeight: targetH,
        sourceWidth: sourceVideo.width,
        sourceHeight: sourceVideo.height,
        sourceBitrateBps: sourceVideo.bitrate,
      );

      final String x264Preset;
      String? x264Tune;
      switch (appSettings.cpuPreset) {
        case 'fast':
          x264Preset = 'ultrafast';
          x264Tune = 'fastdecode';
          break;
        case 'slow':
          x264Preset = 'faster';
          break;
        case 'medium':
        default:
          x264Preset = 'veryfast';
          break;
      }

      final List<String> rateControlArgs;
      if (encodingOptions.rateControlMode == RateControlMode.crf) {
        rateControlArgs = [
          '-crf',
          '${encodingOptions.crfValue}',
        ];
      } else {
        rateControlArgs = [
          '-b:v',
          '${targetBitrateKbps}k',
        ];
      }

      if (isOriginalResolution) {
        vfFilter =
            '${fpsFilter}pad=ceil(iw/2)*2:ceil(ih/2)*2:(ow-iw)/2:(oh-ih)/2,format=yuv420p';
      } else {
        final scaleFlag =
            appSettings.cpuPreset == 'slow' ? 'bicubic' : 'bilinear';
        vfFilter =
            '${fpsFilter}scale=w=$targetW:h=$targetH:force_original_aspect_ratio=decrease:flags=$scaleFlag,pad=ceil(iw/2)*2:ceil(ih/2)*2:(ow-iw)/2:(oh-ih)/2,format=yuv420p';
      }

      codecArgs = [
        '-c:v',
        'libx264',
        '-preset',
        x264Preset,
        if (x264Tune != null) ...['-tune', x264Tune],
        '-profile:v',
        'high',
        '-level:v',
        '4.1',
        ...rateControlArgs,
        '-pix_fmt',
        'yuv420p',
      ];

      if (!sourceVideo.hasAudio || appSettings.audioBitrateKbps <= 0) {
        audioArgs = ['-an'];
      } else {
        audioArgs = [
          '-c:a',
          'aac',
          '-b:a',
          '${appSettings.audioBitrateKbps}k',
        ];
      }
    }

    // Container specific flags
    final List<String> containerFlags = [];
    if (encodingOptions.container == VideoContainer.mp4 ||
        encodingOptions.container == VideoContainer.mov) {
      containerFlags.addAll(['-movflags', '+faststart']);
    }

    return <String>[
      '-i',
      sourceVideo.filePath,
      '-map',
      '0:v:0',
      '-map',
      '0:a:0?',
      '-threads',
      '$effectiveThreads',
      '-filter_threads',
      '$effectiveThreads',
      if (!isStreamCopy && vfFilter.isNotEmpty) ...['-vf', vfFilter],
      ...codecArgs,
      ...audioArgs,
      ...containerFlags,
      '-y',
      outputPath,
    ];
  }

  /// Transcode and downscale a video to a target resolution.
  /// [onProgress] reports progress from 0.0 to 1.0.
  /// Returns the output file path on success, null on failure.
  static Future<String?> processVideo({
    required VideoInfo sourceVideo,
    required VideoResolution targetResolution,
    EncodingOptions encodingOptions = const EncodingOptions(),
    AppSettings appSettings = const AppSettings(),
    required void Function(double progress, String stats, [int? sizeBytes])
    onProgress,
    required void Function(String log) onLog,
  }) async {
    final outputDir = await getOutputDirectory(
      customPath: appSettings.outputDirectory,
    );

    final outputPath = await generateUniqueOutputPath(
      outputDir: outputDir,
      fileName: sourceVideo.fileName,
      targetResolution: targetResolution,
      container: encodingOptions.container,
    );

    // Calculate target dimensions for logging and metadata
    int targetW = targetResolution.width;
    int targetH = targetResolution.height;
    if (sourceVideo.height > sourceVideo.width) {
      targetW = targetResolution.height;
      targetH = targetResolution.width;
    }
    final sourceAspect =
        sourceVideo.width / (sourceVideo.height > 0 ? sourceVideo.height : 1);
    final targetAspect = targetW / (targetH > 0 ? targetH : 1);
    if (sourceAspect > targetAspect) {
      targetH = (targetW / sourceAspect).round();
    } else {
      targetW = (targetH * sourceAspect).round();
    }
    targetW = (targetW ~/ 2) * 2;
    targetH = (targetH ~/ 2) * 2;

    final isOriginalResolution =
        targetW == sourceVideo.width && targetH == sourceVideo.height;
    final isSourceH264 = sourceVideo.codec.toLowerCase().contains('h264') ||
        sourceVideo.codec.toLowerCase().contains('avc');
    final isFpsSame = encodingOptions.targetFps <= 0 ||
        encodingOptions.targetFps == sourceVideo.fps.round();
    final bool isStreamCopy = isOriginalResolution && isFpsSame && isSourceH264;

    final arguments = buildVideoArguments(
      sourceVideo: sourceVideo,
      targetResolution: targetResolution,
      encodingOptions: encodingOptions,
      appSettings: appSettings,
      outputPath: outputPath,
    );

    if (isStreamCopy) {
      onLog('Smart Stream Copy (Lossless Passthrough) active');
    }

    final commandDebug = arguments.join(' ');
    onLog('Command: ffmpeg $commandDebug');
    onLog(
      isStreamCopy
          ? 'Output: ${targetW}x$targetH via Lossless Stream Copy'
          : 'Output: ${targetW}x$targetH via Software (libx264)',
    );

    final totalDuration = sourceVideo.durationSeconds * 1000; // in ms
    final completer = Completer<FFmpegSession>();

    await FFmpegKit.executeWithArgumentsAsync(
      arguments,
      (FFmpegSession session) {
        if (!completer.isCompleted) {
          completer.complete(session);
        }
      },
      (Log log) {
        onLog(log.getMessage());
      },
      (Statistics stats) {
        final time = stats.getTime().toDouble();
        if (totalDuration > 0) {
          final progress = (time / totalDuration).clamp(0.0, 1.0);
          final speed = stats.getSpeed();
          final size = stats.getSize();
          final sizeStr = size > 1048576
              ? '${(size / 1048576).toStringAsFixed(1)} MB'
              : '${(size / 1024).toStringAsFixed(0)} KB';
          onProgress(
            progress,
            'Size: $sizeStr | Speed: ${speed.toStringAsFixed(1)}x',
            size,
          );
        }
      },
    );

    final session = await completer.future;
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      onLog('\nEncoding completed successfully!');
      return outputPath;
    } else if (ReturnCode.isCancel(returnCode)) {
      onLog('\nEncoding cancelled by user.');
      final partialFile = File(outputPath);
      if (await partialFile.exists()) {
        try {
          await partialFile.delete();
        } catch (_) {}
      }
      return null;
    } else {
      final logs = await session.getAllLogsAsString();
      onLog('\nEncoding failed: $logs');
      final partialFile = File(outputPath);
      if (await partialFile.exists()) {
        try {
          await partialFile.delete();
        } catch (_) {}
      }
      return null;
    }
  }

  /// Extract audio from a video file into MP3, M4A, or WAV format.
  /// If [audioBitrateKbps] is 0, uses stream copy where applicable or high-quality encode.
  static Future<String?> extractAudio({
    required VideoInfo sourceVideo,
    required AudioFormat audioFormat,
    int audioBitrateKbps = 192,
    AppSettings appSettings = const AppSettings(),
    required void Function(double progress, String stats, [int? sizeBytes])
    onProgress,
    required void Function(String log) onLog,
  }) async {
    final outputDir = await getOutputDirectory(
      customPath: appSettings.audioOutputDirectory,
      isAudio: true,
    );
    final outputPath = await generateUniqueAudioOutputPath(
      outputDir: outputDir,
      fileName: sourceVideo.fileName,
      audioFormat: audioFormat,
    );

    final srcCodec = sourceVideo.audioCodec?.toLowerCase() ?? '';
    final canCopy =
        (audioFormat == AudioFormat.mp3 && srcCodec == 'mp3') ||
        (audioFormat == AudioFormat.m4a &&
            (srcCodec == 'aac' || srcCodec == 'mp4a')) ||
        (audioFormat == AudioFormat.wav && srcCodec.startsWith('pcm'));

    final List<String> audioCodecArgs;
    if (audioBitrateKbps <= 0 && canCopy) {
      audioCodecArgs = ['-c:a', 'copy'];
    } else {
      final effectiveBitrate = audioBitrateKbps > 0 ? audioBitrateKbps : 192;
      switch (audioFormat) {
        case AudioFormat.mp3:
          audioCodecArgs = ['-c:a', 'libmp3lame', '-b:a', '${effectiveBitrate}k'];
          break;
        case AudioFormat.m4a:
          audioCodecArgs = ['-c:a', 'aac', '-b:a', '${effectiveBitrate}k'];
          break;
        case AudioFormat.wav:
          audioCodecArgs = ['-c:a', 'pcm_s16le'];
          break;
      }
    }

    final arguments = <String>[
      '-i',
      sourceVideo.filePath,
      if (appSettings.cpuThreads > 0) ...['-threads', '${appSettings.cpuThreads}'],
      '-vn',
      '-sn',
      '-dn',
      '-map',
      '0:a:0?',
      ...audioCodecArgs,
      if (audioFormat == AudioFormat.m4a) ...['-movflags', '+faststart'],
      '-y',
      outputPath,
    ];

    final commandDebug =
        arguments.map((a) => a.contains(' ') ? '"$a"' : a).join(' ');
    onLog('Command: ffmpeg $commandDebug');
    onLog(
      'Output: Extracting audio as ${audioFormat.displayName} @ ${audioBitrateKbps > 0 ? "$audioBitrateKbps kbps" : (canCopy ? "Original Copy" : "Auto 192 kbps")}',
    );

    final totalDuration = sourceVideo.durationSeconds * 1000; // in ms
    final completer = Completer<FFmpegSession>();

    await FFmpegKit.executeWithArgumentsAsync(
      arguments,
      (FFmpegSession session) {
        if (!completer.isCompleted) {
          completer.complete(session);
        }
      },
      (Log log) {
        onLog(log.getMessage());
      },
      (Statistics stats) {
        final time = stats.getTime().toDouble();
        if (totalDuration > 0) {
          final progress = (time / totalDuration).clamp(0.0, 1.0);
          final size = stats.getSize();
          final sizeStr = size > 1048576
              ? '${(size / 1048576).toStringAsFixed(1)} MB'
              : '${(size / 1024).toStringAsFixed(0)} KB';
          final speed = stats.getSpeed();
          final speedStr = speed > 0 ? '${speed.toStringAsFixed(1)}x' : '1.0x';
          onProgress(progress, 'Size: $sizeStr | Speed: $speedStr', size);
        }
      },
    );

    final session = await completer.future;
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      onProgress(1.0, 'Completed');
      return outputPath;
    } else if (ReturnCode.isCancel(returnCode)) {
      onLog('\nExtraction cancelled by user.');
      final partialFile = File(outputPath);
      if (await partialFile.exists()) {
        try {
          await partialFile.delete();
        } catch (_) {}
      }
      return null;
    } else {
      final logs = await session.getAllLogsAsString();
      onLog('\nExtraction failed: $logs');
      final partialFile = File(outputPath);
      if (await partialFile.exists()) {
        try {
          await partialFile.delete();
        } catch (_) {}
      }
      return null;
    }
  }

  /// Cancel any running FFmpeg execution.
  static Future<void> cancelAll() async {
    await FFmpegKit.cancel();
  }
}
