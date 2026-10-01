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
      );
    } catch (e) {
      return null;
    }
  }

  /// Downscale and transcode video to the target resolution, codec, container, and bitrate.
  /// Get or create the output directory for converted videos.
  /// If [customPath] is provided and valid, uses it.
  /// Otherwise strictly targets `/storage/emulated/0/Movies` directly on Android without subfolders.
  static Future<Directory> getOutputDirectory({String? customPath}) async {
    if (customPath != null && customPath.trim().isNotEmpty) {
      final customDir = Directory(customPath.trim());
      try {
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }
        return customDir;
      } catch (_) {
        // Fallback to default Movies directory
      }
    }

    if (Platform.isAndroid) {
      final moviesDir = Directory('/storage/emulated/0/Movies');
      try {
        if (!await moviesDir.exists()) {
          await moviesDir.create(recursive: true);
        }
        return moviesDir;
      } catch (e) {
        // Fallback for devices with different mount points or restricted paths
        try {
          final extDirs = await getExternalStorageDirectories(type: StorageDirectory.movies);
          if (extDirs != null && extDirs.isNotEmpty) {
            final fallback = extDirs.first;
            if (!await fallback.exists()) {
              await fallback.create(recursive: true);
            }
            return fallback;
          }
        } catch (_) {}

        final appDocDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory('${appDocDir.path}/Movies');
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        return fallbackDir;
      }
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDocDir.path}/Movies');
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
    final String resSuffix = targetResolution.label.toLowerCase().startsWith('original')
        ? '${targetResolution.height}p'
        : targetResolution.label.toLowerCase();

    final dirPath = outputDir.path.endsWith('/') || outputDir.path.endsWith('\\')
        ? outputDir.path.substring(0, outputDir.path.length - 1)
        : outputDir.path;
    final sep = Platform.pathSeparator;

    final basePath = '$dirPath$sep$sanitizedBase-$resSuffix.$ext';
    if (!await File(basePath).exists()) {
      return basePath;
    }

    int counter = 2;
    while (true) {
      final candidatePath = '$dirPath$sep$sanitizedBase-$resSuffix-$counter.$ext';
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
    final dirPath = outputDir.path.endsWith('/') || outputDir.path.endsWith('\\')
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

  /// Transcode and downscale a video to a target resolution.
  /// [onProgress] reports progress from 0.0 to 1.0.
  /// Returns the output file path on success, null on failure.
  static Future<String?> processVideo({
    required VideoInfo sourceVideo,
    required VideoResolution targetResolution,
    EncodingOptions encodingOptions = const EncodingOptions(),
    AppSettings appSettings = const AppSettings(),
    required void Function(double progress, String stats) onProgress,
    required void Function(String log) onLog,
  }) async {
    final outputDir = await getOutputDirectory(customPath: appSettings.outputDirectory);

    final outputPath = await generateUniqueOutputPath(
      outputDir: outputDir,
      fileName: sourceVideo.fileName,
      targetResolution: targetResolution,
      container: encodingOptions.container,
    );

    // Calculate target dimensions (must be even numbers)
    int targetW = targetResolution.width;
    int targetH = targetResolution.height;

    // Handle portrait videos: if source is portrait, swap target dimensions
    if (sourceVideo.height > sourceVideo.width) {
      targetW = targetResolution.height;
      targetH = targetResolution.width;
    }

    final sourceAspect = sourceVideo.width / (sourceVideo.height > 0 ? sourceVideo.height : 1);
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

    // Video codec selection (pure software encoding)
    final String vCodec = encodingOptions.codec.ffmpegCodec;

    final targetBitrateKbps = encodingOptions.calculateTargetBitrateKbps(
      targetWidth: targetW,
      targetHeight: targetH,
      sourceWidth: sourceVideo.width,
      sourceHeight: sourceVideo.height,
      sourceBitrateBps: sourceVideo.bitrate,
    );

    // GOP (keyframe interval)
    final gop = (sourceVideo.fps * 2).round().clamp(24, 250);

    // Rate control, preset, profile, and codec-specific arguments
    String rateControlArg = '';
    String presetArg = '';
    String profileLevelArg = '';
    String codecExtraArgs = '';

    if (vCodec == 'libx264') {
      if (encodingOptions.rateControlMode == RateControlMode.crf) {
        rateControlArg = '-crf ${encodingOptions.crfValue}';
      } else {
        rateControlArg = '-b:v ${targetBitrateKbps}k';
      }
      presetArg = '-preset ${appSettings.cpuPreset}';
      profileLevelArg = '-profile:v high -level:v 4.1';

    } else if (vCodec == 'libx265') {
      if (encodingOptions.rateControlMode == RateControlMode.crf) {
        rateControlArg = '-crf ${encodingOptions.crfValue}';
      } else {
        rateControlArg = '-b:v ${targetBitrateKbps}k';
      }
      presetArg = '-preset ${appSettings.cpuPreset}';
      profileLevelArg = ''; // libx265 does not accept -profile:v main directly as a CLI flag
      
      String hvc1Tag = '';
      if (encodingOptions.container == VideoContainer.mp4 || encodingOptions.container == VideoContainer.mov) {
        hvc1Tag = '-tag:v hvc1 ';
      }
      codecExtraArgs = '$hvc1Tag-x265-params log-level=error:keyint=$gop:min-keyint=${(gop ~/ 2)}';

    } else if (vCodec == 'libvpx-vp9') {
      if (encodingOptions.rateControlMode == RateControlMode.crf) {
        rateControlArg = '-crf ${encodingOptions.crfValue} -b:v 0';
      } else {
        rateControlArg = '-b:v ${targetBitrateKbps}k';
      }
      profileLevelArg = ''; // libvpx-vp9 automatically uses Profile 0 for 8-bit yuv420p
      codecExtraArgs = '-deadline good -cpu-used 4 -row-mt 1 -tile-columns 2 -auto-alt-ref 1 -lag-in-frames 25 -g $gop';
    }

    // Audio options
    String audioArgs = '-c:a aac -b:a ${appSettings.audioBitrateKbps}k';
    if (appSettings.audioBitrateKbps <= 0) {
      audioArgs = '-an';
    } else if (encodingOptions.container == VideoContainer.webm ||
              encodingOptions.codec == VideoCodec.vp9) {
      audioArgs = '-c:a libopus -b:a ${appSettings.audioBitrateKbps}k';
    }

    // Threads argument
    String threadsArg = '';
    if (appSettings.cpuThreads > 0) {
      threadsArg = '-threads ${appSettings.cpuThreads}';
    }

    // Container specific flags
    String containerFlags = '';
    if (encodingOptions.container == VideoContainer.mp4 ||
        encodingOptions.container == VideoContainer.mov) {
      containerFlags = '-movflags +faststart';
    }
    
    // FPS filter
    String fpsFilter = '';
    if (encodingOptions.targetFps > 0) {
      fpsFilter = 'fps=fps=${encodingOptions.targetFps},';
    }

    // Detect Mode
    final isOriginalResolution = targetW == sourceVideo.width && targetH == sourceVideo.height;

    // Build video filter (-vf)
    String vfArg = '';
    
    if (isOriginalResolution) {
      vfArg = '-vf "${fpsFilter}format=yuv420p"';
    } else {
      // Upscale / Downscale
      vfArg = '-vf "${fpsFilter}scale=$targetW:$targetH:flags=lanczos,format=yuv420p"';
    }

    // Construct full command
    final cmdParts = <String>[
      '-i "${sourceVideo.filePath}"',
      threadsArg,
      vfArg,
      '-c:v $vCodec',
      presetArg,
      profileLevelArg,
      rateControlArg,
      codecExtraArgs,
      audioArgs,
      containerFlags,
      '-y "$outputPath"',
    ]..removeWhere((element) => element.trim().isEmpty);

    final command = cmdParts.join(' ');

    onLog('Command: ffmpeg $command');
    onLog('Output: ${targetW}x$targetH @ $rateControlArg using $vCodec');

    final totalDuration = sourceVideo.durationSeconds * 1000; // in ms
    final completer = Completer<FFmpegSession>();

    await FFmpegKit.executeAsync(
      command,
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
  /// If [audioBitrateKbps] is 0, uses stream copy (-c:a copy) where applicable.
  static Future<String?> extractAudio({
    required VideoInfo sourceVideo,
    required AudioFormat audioFormat,
    int audioBitrateKbps = 192,
    AppSettings appSettings = const AppSettings(),
    required void Function(double progress, String stats) onProgress,
    required void Function(String log) onLog,
  }) async {
    final outputDir = await getOutputDirectory(customPath: appSettings.outputDirectory);
    final outputPath = await generateUniqueAudioOutputPath(
      outputDir: outputDir,
      fileName: sourceVideo.fileName,
      audioFormat: audioFormat,
    );

    String audioCodecArg;
    if (audioBitrateKbps <= 0) {
      audioCodecArg = '-c:a copy';
    } else {
      switch (audioFormat) {
        case AudioFormat.mp3:
          audioCodecArg = '-c:a libmp3lame -b:a ${audioBitrateKbps}k';
          break;
        case AudioFormat.m4a:
          audioCodecArg = '-c:a aac -b:a ${audioBitrateKbps}k';
          break;
        case AudioFormat.wav:
          audioCodecArg = '-c:a pcm_s16le';
          break;
      }
    }

    final command = '-i "${sourceVideo.filePath}" -vn $audioCodecArg -y "$outputPath"';

    onLog('Command: ffmpeg $command');
    onLog('Output: Extracting audio as ${audioFormat.displayName} @ ${audioBitrateKbps > 0 ? "$audioBitrateKbps kbps" : "Original Copy"}');

    final totalDuration = sourceVideo.durationSeconds * 1000; // in ms
    final completer = Completer<FFmpegSession>();

    await FFmpegKit.executeAsync(
      command,
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
          final sizeMb = (stats.getSize() / (1024 * 1024)).toStringAsFixed(1);
          final speed = stats.getSpeed();
          final speedStr = speed > 0 ? '${speed.toStringAsFixed(1)}x' : '1.0x';
          onProgress(progress, 'Size: $sizeMb MB | Speed: $speedStr');
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
