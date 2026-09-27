import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:path_provider/path_provider.dart';

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

      final width = videoStream.getWidth() ?? 0;
      final height = videoStream.getHeight() ?? 0;

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

  /// Downscale video to the target resolution.
  /// [onProgress] reports progress from 0.0 to 1.0.
  /// Returns the output file path on success, null on failure.
  static Future<String?> downscaleVideo({
    required VideoInfo sourceVideo,
    required VideoResolution targetResolution,
    required void Function(double progress, String stats) onProgress,
    required void Function(String log) onLog,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${dir.path}/VideoDownscaler');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }


    final ext = sourceVideo.fileName.split('.').last;
    final outputPath =
        '${outputDir.path}/${sourceVideo.fileName.replaceAll('.$ext', '')}_${targetResolution.label}.$ext';

    // Check if output already exists and remove
    final outputFile = File(outputPath);
    if (await outputFile.exists()) {
      await outputFile.delete();
    }

    // Calculate target dimensions (must be even numbers)
    int targetW = targetResolution.width;
    int targetH = targetResolution.height;

    // Maintain aspect ratio
    final sourceAspect = sourceVideo.width / sourceVideo.height;
    final targetAspect = targetW / targetH;

    if (sourceAspect > targetAspect) {
      // Source is wider, limit by width
      targetH = (targetW / sourceAspect).round();
    } else {
      // Source is taller, limit by height
      targetW = (targetH * sourceAspect).round();
    }

    // Ensure even dimensions
    targetW = (targetW ~/ 2) * 2;
    targetH = (targetH ~/ 2) * 2;

    // Calculate target bitrate (proportional to pixel count reduction)
    final sourcePixels = sourceVideo.width * sourceVideo.height;
    final targetPixels = targetW * targetH;
    final ratio = targetPixels / sourcePixels;
    var targetBitrate = (sourceVideo.bitrate * ratio * 1.2).toInt();

    // Set reasonable min/max bitrates
    if (targetResolution.height >= 1080) {
      targetBitrate = targetBitrate.clamp(4000000, 12000000);
    } else if (targetResolution.height >= 720) {
      targetBitrate = targetBitrate.clamp(2000000, 6000000);
    } else if (targetResolution.height >= 480) {
      targetBitrate = targetBitrate.clamp(1000000, 3000000);
    } else {
      targetBitrate = targetBitrate.clamp(500000, 2000000);
    }

    final bitrateStr = '${(targetBitrate / 1000).round()}k';

    final command = '-i "${sourceVideo.filePath}" '
        '-vf "scale=$targetW:$targetH" '
        '-c:v libx264 -preset medium '
        '-b:v $bitrateStr '
        '-c:a aac -b:a 128k '
        '-movflags +faststart '
        '-y "$outputPath"';

    onLog('Command: ffmpeg $command');
    onLog('Output: ${targetW}x$targetH @ $bitrateStr');

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
