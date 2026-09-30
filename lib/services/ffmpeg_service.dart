import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
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
  /// Get or create the output directory for downscaled videos.
  /// Strictly targets `/storage/emulated/0/Movies/Video Downscaler` on Android.
  static Future<Directory> getOutputDirectory() async {
    if (Platform.isAndroid) {
      final moviesDir = Directory('/storage/emulated/0/Movies/Video Downscaler');
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
            final fallback = Directory('${extDirs.first.path}/Video Downscaler');
            if (!await fallback.exists()) {
              await fallback.create(recursive: true);
            }
            return fallback;
          }
        } catch (_) {}

        final appDocDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory('${appDocDir.path}/Movies/Video Downscaler');
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        return fallbackDir;
      }
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDocDir.path}/Movies/Video Downscaler');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }

  /// Transcode and downscale a video to a target resolution.
  /// [onProgress] reports progress from 0.0 to 1.0.
  /// Returns the output file path on success, null on failure.
  static Future<String?> downscaleVideo({
    required VideoInfo sourceVideo,
    required VideoResolution targetResolution,
    EncodingOptions encodingOptions = const EncodingOptions(),
    AppSettings appSettings = const AppSettings(),
    required void Function(double progress, String stats) onProgress,
    required void Function(String log) onLog,
  }) async {
    final outputDir = await getOutputDirectory();

    final ext = encodingOptions.container.extension;
    final sanitizedBase = sourceVideo.fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final cleanLabel = targetResolution.label.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final outputPath = '${outputDir.path}/${sanitizedBase}_${cleanLabel}_${encodingOptions.codec.displayName.split(' ').first}.$ext';

    // Check if output already exists and remove
    final outputFile = File(outputPath);
    if (await outputFile.exists()) {
      await outputFile.delete();
    }

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

    // Video codec selection
    String vCodec = encodingOptions.codec.ffmpegCodec;
    bool isMediaCodec = false;
    
    if (appSettings.hardwareAcceleration) {
      if (encodingOptions.codec == VideoCodec.h264) {
        vCodec = 'h264_mediacodec';
        isMediaCodec = true;
      } else if (encodingOptions.codec == VideoCodec.hevc) {
        vCodec = 'hevc_mediacodec';
        isMediaCodec = true;
      }
      // Note: VP9 has no widely supported MediaCodec encoder, stays software
    }

    final targetBitrateKbps = encodingOptions.calculateTargetBitrateKbps(
      targetWidth: targetW,
      targetHeight: targetH,
      sourceWidth: sourceVideo.width,
      sourceHeight: sourceVideo.height,
      sourceBitrateBps: sourceVideo.bitrate,
    );

    // Rate control, preset, profile, and codec-specific arguments
    String rateControlArg = '';
    String presetArg = '';
    String profileLevelArg = '';
    String codecExtraArgs = '';

    // GOP (keyframe interval) — used by both HW and SW encoders
    final gop = (sourceVideo.fps * 2).round().clamp(24, 250);

    // Determine thread count for parallel encoding
    final int effectiveThreads = appSettings.cpuThreads > 0
        ? appSettings.cpuThreads
        : AppSettings.deviceCoreCount;

    if (isMediaCodec) {
      // ===== HARDWARE (MediaCodec) ENCODING =====
      // Many Android MediaCodec implementations (Snapdragon, MediaTek, Exynos)
      // poorly support -bitrate_mode and silently ignore bitrate params.
      // Strategy: use ABR (-b:v) with explicit maxrate/bufsize, no -bitrate_mode.
      // Enforce a quality floor so the output never drops below a sane bitrate.
      final int hwBitrateKbps = targetBitrateKbps.clamp(1500, 50000);
      final int maxrateKbps = (hwBitrateKbps * 1.5).round();
      final int bufsizeKbps = hwBitrateKbps * 2;

      rateControlArg = '-b:v ${hwBitrateKbps}k -maxrate ${maxrateKbps}k -bufsize ${bufsizeKbps}k -g $gop';

      if (vCodec == 'h264_mediacodec') {
        profileLevelArg = '-profile:v high -level:v 4.1';
      } else if (vCodec == 'hevc_mediacodec') {
        profileLevelArg = '-profile:v main';
        // hvc1 tag is critical for playback on Android/iOS video players
        codecExtraArgs = '-tag:v hvc1';
      }
    } else {
      // ===== SOFTWARE ENCODING =====
      if (vCodec == 'libx264') {
        // H.264 software encoding
        if (encodingOptions.rateControlMode == RateControlMode.crf) {
          rateControlArg = '-crf ${encodingOptions.crfValue}';
        } else {
          rateControlArg = '-b:v ${targetBitrateKbps}k';
        }
        presetArg = '-preset ${appSettings.cpuPreset}';
        profileLevelArg = '-profile:v high -level:v 4.1';

      } else if (vCodec == 'libx265') {
        // H.265 / HEVC software encoding
        if (encodingOptions.rateControlMode == RateControlMode.crf) {
          rateControlArg = '-crf ${encodingOptions.crfValue}';
        } else {
          rateControlArg = '-b:v ${targetBitrateKbps}k';
        }
        presetArg = '-preset ${appSettings.cpuPreset}';
        // hvc1 tag required for MP4/MOV playback on Android/iOS
        codecExtraArgs = '-tag:v hvc1 -x265-params "log-level=error:keyint=$gop:min-keyint=${(gop ~/ 2)}:pools=$effectiveThreads:frame-threads=$effectiveThreads"';

      } else if (vCodec == 'libvpx-vp9') {
        // VP9 software encoding — without these flags, libvpx-vp9 runs in
        // 'best' deadline mode (single-threaded, exhaustive search) which is
        // 10-50x slower than necessary.
        if (encodingOptions.rateControlMode == RateControlMode.crf) {
          // VP9 uses -crf + -b:v 0 for constant quality mode
          rateControlArg = '-crf ${encodingOptions.crfValue} -b:v 0';
        } else {
          rateControlArg = '-b:v ${targetBitrateKbps}k';
        }
        // -deadline good : balanced speed/quality (vs 'best' which is glacially slow)
        // -cpu-used 4    : speed level 0-8, 4 is a good balance
        // -row-mt 1      : enable row-based multi-threading (massive speedup)
        // -tile-columns 2: split frame into 4 tile columns for parallelism
        // -frame-parallel 1: enable frame-level parallelism
        // -auto-alt-ref 1 & -lag-in-frames 25: better compression with look-ahead
        codecExtraArgs = '-deadline good -cpu-used 4 -row-mt 1 -tile-columns 2 -frame-parallel 1 -auto-alt-ref 1 -lag-in-frames 25 -g $gop';
      }
    }

    // Audio options
    String audioArgs = '-c:a aac -b:a ${appSettings.audioBitrateKbps}k';
    if (appSettings.audioBitrateKbps <= 0) {
      audioArgs = '-an';
    } else if (encodingOptions.container == VideoContainer.webm ||
               encodingOptions.codec == VideoCodec.vp9) {
      // VP9 typically pairs with Opus audio, and WebM requires Opus/Vorbis
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

    // Video filters: FPS + Lanczos Scale + pixel format
    // Hardware encoders (MediaCodec) should NOT force yuv420p — they accept
    // the device's native surface format. Forcing yuv420p causes color space
    // conversion overhead and some chipsets reject it entirely, producing
    // garbage output. Software encoders need explicit yuv420p for compatibility.
    final String pixFmtFilter = isMediaCodec ? '' : ',format=yuv420p';
    final vfArg = '-vf "${fpsFilter}scale=$targetW:$targetH:flags=lanczos$pixFmtFilter"';

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
    onLog('Output: ${targetW}x$targetH @ $rateControlArg using $vCodec${isMediaCodec ? ' (HW)' : ' (SW)'}');

    final totalDuration = sourceVideo.durationSeconds * 1000; // in ms

    // Enable statistics callback
    FFmpegKitConfig.enableStatisticsCallback((Statistics stats) {
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
    });

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      onLog('\nEncoding completed successfully!');
      return outputPath;
    } else {
      final logs = await session.getAllLogsAsString();
      onLog('\nEncoding failed: $logs');
      return null;
    }
  }

  /// Cancel any running FFmpeg execution.
  static Future<void> cancelAll() async {
    await FFmpegKit.cancel();
  }
}
