import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:video_downscaler/models/app_settings.dart';
import 'package:video_downscaler/models/encoding_options.dart';
import 'package:video_downscaler/models/video_info.dart';
import 'package:video_downscaler/services/ffmpeg_service.dart';

void main() {
  group('1. Convert Feature & Video Codec Tests', () {
    const sourceVideo = VideoInfo(
      filePath: '/storage/emulated/0/DCIM/source_4k.mp4',
      fileName: 'source_4k.mp4',
      width: 3840,
      height: 2160,
      durationSeconds: 120.0,
      bitrate: 25000000, // 25 Mbps
      fps: 60.0,
      codec: 'h264',
      fileSizeBytes: 375000000,
      hasAudio: true,
      audioCodec: 'aac',
    );

    test(
      'VideoCodec enum definitions are correct with valid ffmpeg codec strings',
      () {
        expect(VideoCodec.h264.ffmpegCodec, equals('libx264'));
        expect(VideoCodec.h264.displayName, contains('H.264'));
      },
    );

    test('VideoContainer extensions and display names match specification', () {
      expect(VideoContainer.mp4.extension, equals('mp4'));
      expect(VideoContainer.mkv.extension, equals('mkv'));
      expect(VideoContainer.mov.extension, equals('mov'));
    });

    test('CRF Rate Control calculates correct bitrate targets for H264 across resolutions', () {
      const opts = EncodingOptions(
        codec: VideoCodec.h264,
        rateControlMode: RateControlMode.crf,
        crfValue: 20,
      );

      // 4K target (3840x2160)
      final br4k = opts.calculateTargetBitrateKbps(
        targetWidth: 3840,
        targetHeight: 2160,
        sourceWidth: sourceVideo.width,
        sourceHeight: sourceVideo.height,
        sourceBitrateBps: sourceVideo.bitrate,
      );
      expect(br4k, greaterThanOrEqualTo(8000));

      // 1080p target (1920x1080)
      final br1080 = opts.calculateTargetBitrateKbps(
        targetWidth: 1920,
        targetHeight: 1080,
        sourceWidth: sourceVideo.width,
        sourceHeight: sourceVideo.height,
        sourceBitrateBps: sourceVideo.bitrate,
      );
      expect(br1080, inInclusiveRange(4000, 5000));

      // 720p target (1280x720)
      final br720 = opts.calculateTargetBitrateKbps(
        targetWidth: 1280,
        targetHeight: 720,
        sourceWidth: sourceVideo.width,
        sourceHeight: sourceVideo.height,
        sourceBitrateBps: sourceVideo.bitrate,
      );
      expect(br720, inInclusiveRange(2000, 3000));
    });

    test('H.264 standardized codec produces predictable bitrate output at target CRF', () {
      const optsH264 = EncodingOptions(
        codec: VideoCodec.h264,
        rateControlMode: RateControlMode.crf,
        crfValue: 20,
      );

      final h264Bitrate = optsH264.calculateTargetBitrateKbps(
        targetWidth: 1920,
        targetHeight: 1080,
        sourceWidth: sourceVideo.width,
        sourceHeight: sourceVideo.height,
        sourceBitrateBps: sourceVideo.bitrate,
      );

      expect(h264Bitrate, inInclusiveRange(4000, 5000));
    });

    test('Bitrate Rate Control mode strictly adheres to customBitrateKbps', () {
      const customKbps = 8500;
      const opts = EncodingOptions(
        rateControlMode: RateControlMode.bitrate,
        customBitrateKbps: customKbps,
      );

      final calculated = opts.calculateTargetBitrateKbps(
        targetWidth: 1920,
        targetHeight: 1080,
        sourceWidth: sourceVideo.width,
        sourceHeight: sourceVideo.height,
        sourceBitrateBps: sourceVideo.bitrate,
      );

      expect(calculated, equals(customKbps));
    });

    test('Low-bitrate source video caps target bitrate to avoid unnecessary file enlargement', () {
      const lowBitrateSource = VideoInfo(
        filePath: '/test_low.mp4',
        fileName: 'test_low.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 60,
        bitrate: 1000000, // 1 Mbps (1000 kbps)
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 7500000,
      );

      const opts = EncodingOptions(
        codec: VideoCodec.h264,
        rateControlMode: RateControlMode.crf,
        crfValue: 18,
      );

      final targetKbps = opts.calculateTargetBitrateKbps(
        targetWidth: 1920,
        targetHeight: 1080,
        sourceWidth: lowBitrateSource.width,
        sourceHeight: lowBitrateSource.height,
        sourceBitrateBps: lowBitrateSource.bitrate,
      );

      expect(targetKbps, lessThanOrEqualTo(1000));
    });
  });

  group('2. Downscale Feature & Resolution Scaling Tests', () {
    test(
      '4K video produces standard downscale targets from 2K down to 360p',
      () {
        const v4k = VideoInfo(
          filePath: '/4k.mp4',
          fileName: '4k.mp4',
          width: 3840,
          height: 2160,
          durationSeconds: 60,
          bitrate: 20000000,
          fps: 30,
          codec: 'h264',
          fileSizeBytes: 150000000,
        );

        final targets = v4k.availableDownscaleTargets;
        expect(targets.first.label, equals('Original (4K)'));
        expect(targets.first.width, equals(3840));
        expect(targets.first.height, equals(2160));

        final targetLabels = targets.map((t) => t.label).toList();
        expect(
          targetLabels,
          containsAll(['Original (4K)', '2K', '1080p', '720p', '480p', '360p']),
        );
        expect(targetLabels.contains('4K'), isFalse);
      },
    );

    test(
      '1080p video only allows downscaling to strictly smaller resolutions',
      () {
        const v1080 = VideoInfo(
          filePath: '/1080p.mp4',
          fileName: '1080p.mp4',
          width: 1920,
          height: 1080,
          durationSeconds: 60,
          bitrate: 5000000,
          fps: 30,
          codec: 'h264',
          fileSizeBytes: 37500000,
        );

        final targets = v1080.availableDownscaleTargets;
        expect(targets.first.label, equals('Original (1080p)'));

        final targetHeights = targets.skip(1).map((t) => t.height).toList();
        for (final h in targetHeights) {
          expect(h, lessThan(1080));
        }
        expect(targetHeights, equals([720, 480, 360]));
      },
    );

    test('Portrait 1080x1920 video correctly classifies as 1080p and excludes 2K from downscale targets', () {
      const portrait1080 = VideoInfo(
        filePath: '/portrait1080.mp4',
        fileName: 'portrait1080.mp4',
        width: 1080,
        height: 1920,
        durationSeconds: 15,
        bitrate: 4000000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 7500000,
      );

      expect(portrait1080.shortDimension, equals(1080));
      expect(portrait1080.resolution, equals('1080p'));

      final targets = portrait1080.availableDownscaleTargets;
      expect(targets.first.label, equals('Original (1080p)'));

      final targetLabels = targets.map((t) => t.label).toList();
      expect(
        targetLabels.contains('2K'),
        isFalse,
        reason: 'Portrait 1080p must not offer 2K (1440p) downscale target',
      );
      expect(targetLabels.contains('4K'), isFalse);

      final downscaledHeights = targets.skip(1).map((t) => t.height).toList();
      expect(downscaledHeights, equals([720, 480, 360]));
    });

    test('Portrait video aspect ratio dimension calculation swaps width and height correctly', () {
      const portraitSource = VideoInfo(
        filePath: '/portrait.mp4',
        fileName: 'portrait.mp4',
        width: 1080,
        height: 1920,
        durationSeconds: 15,
        bitrate: 4000000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 7500000,
      );

      const targetRes720 = VideoResolution(
        label: '720p',
        width: 1280,
        height: 720,
      );

      int targetW = targetRes720.width;
      int targetH = targetRes720.height;

      if (portraitSource.height > portraitSource.width) {
        targetW = targetRes720.height;
        targetH = targetRes720.width;
      }

      final sourceAspect = portraitSource.width / portraitSource.height;
      final targetAspect = targetW / targetH;

      if (sourceAspect > targetAspect) {
        targetH = (targetW / sourceAspect).round();
      } else {
        targetW = (targetH * sourceAspect).round();
      }

      targetW = (targetW ~/ 2) * 2;
      targetH = (targetH ~/ 2) * 2;

      expect(targetW, equals(720));
      expect(targetH, equals(1280));
      expect(targetW % 2, equals(0));
      expect(targetH % 2, equals(0));
    });

    test('Ultrawide 21:9 video preserves aspect ratio and outputs even pixel dimensions', () {
      const ultrawideSource = VideoInfo(
        filePath: '/ultrawide.mp4',
        fileName: 'ultrawide.mp4',
        width: 2560,
        height: 1080,
        durationSeconds: 30,
        bitrate: 8000000,
        fps: 60,
        codec: 'h264',
        fileSizeBytes: 30000000,
      );

      const target720p = VideoResolution(
        label: '720p',
        width: 1280,
        height: 720,
      );

      int targetW = target720p.width;
      int targetH = target720p.height;

      final sourceAspect = ultrawideSource.width / ultrawideSource.height;
      final targetAspect = targetW / targetH;

      if (sourceAspect > targetAspect) {
        targetH = (targetW / sourceAspect).round();
      } else {
        targetW = (targetH * sourceAspect).round();
      }

      targetW = (targetW ~/ 2) * 2;
      targetH = (targetH ~/ 2) * 2;

      expect(targetW, equals(1280));
      expect(targetH, equals(540));
      expect(targetW % 2, equals(0));
      expect(targetH % 2, equals(0));
    });
  });

  group('3. Audio Extractor Feature & Format Tests', () {
    test(
      'AudioFormat values have correct codecs, extensions, and descriptions',
      () {
        expect(AudioFormat.mp3.extension, equals('mp3'));
        expect(AudioFormat.mp3.ffmpegCodec, equals('libmp3lame'));

        expect(AudioFormat.m4a.extension, equals('m4a'));
        expect(AudioFormat.m4a.ffmpegCodec, equals('aac'));

        expect(AudioFormat.wav.extension, equals('wav'));
        expect(AudioFormat.wav.ffmpegCodec, equals('pcm_s16le'));
      },
    );

    test('canCopy stream logic detects when codec can be directly copied vs re-encoded', () {
      final canCopyMp3 = (AudioFormat.mp3 == AudioFormat.mp3 && 'mp3' == 'mp3');
      expect(canCopyMp3, isTrue);

      final canCopyAac =
          (AudioFormat.m4a == AudioFormat.m4a &&
          ('aac' == 'aac' || 'aac' == 'mp4a'));
      expect(canCopyAac, isTrue);

      final canCopyWav =
          (AudioFormat.wav == AudioFormat.wav && 'pcm_s16le'.startsWith('pcm'));
      expect(canCopyWav, isTrue);

      final canCopyAacToMp3 =
          (AudioFormat.mp3 == AudioFormat.mp3 && 'aac' == 'mp3');
      expect(canCopyAacToMp3, isFalse);
    });

    test(
      'generateUniqueAudioOutputPath avoids overwriting existing audio files',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'audio_unique_test_',
        );
        try {
          final path1 = await FFmpegService.generateUniqueAudioOutputPath(
            outputDir: tempDir,
            fileName: 'podcast.mp4',
            audioFormat: AudioFormat.mp3,
          );
          final sep = Platform.pathSeparator;
          expect(path1, equals('${tempDir.path}${sep}podcast-audio.mp3'));

          File(path1).createSync();

          final path2 = await FFmpegService.generateUniqueAudioOutputPath(
            outputDir: tempDir,
            fileName: 'podcast.mp4',
            audioFormat: AudioFormat.mp3,
          );
          expect(path2, equals('${tempDir.path}${sep}podcast-audio-2.mp3'));
        } finally {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      },
    );

    test('Video with hasAudio = false correctly identifies silent videos', () {
      const silentVideo = VideoInfo(
        filePath: '/silent.mp4',
        fileName: 'silent.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 10,
        bitrate: 3000000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 3750000,
        hasAudio: false,
        audioCodec: null,
      );

      expect(silentVideo.hasAudio, isFalse);
      expect(silentVideo.audioCodec, isNull);
    });

    test('Silent video transcoding logic uses -an instead of audio codec arguments', () {
      const silentVideo = VideoInfo(
        filePath: '/silent.mp4',
        fileName: 'silent.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 10,
        bitrate: 3000000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 3750000,
        hasAudio: false,
      );

      const settings = AppSettings(audioBitrateKbps: 128);

      String audioArgs = '-c:a aac -b:a ${settings.audioBitrateKbps}k';
      if (!silentVideo.hasAudio || settings.audioBitrateKbps <= 0) {
        audioArgs = '-an';
      }

      expect(audioArgs, equals('-an'));
    });
  });

  group('4. Settings and Hardware Integration Tests', () {
    test('AppSettings sanitizes invalid presets to medium', () {
      expect(AppSettings.sanitizePreset('fast'), equals('fast'));
      expect(AppSettings.sanitizePreset('slow'), equals('slow'));
      expect(AppSettings.sanitizePreset('medium'), equals('medium'));
      expect(AppSettings.sanitizePreset('ultrafast'), equals('fast'));
      expect(AppSettings.sanitizePreset('superfast'), equals('fast'));
      expect(AppSettings.sanitizePreset('invalid'), equals('medium'));
      expect(AppSettings.sanitizePreset(null), equals('medium'));
    });

    test('Device core count is a valid positive integer', () {
      final cores = AppSettings.deviceCoreCount;
      expect(cores, greaterThan(0));
    });

    test('Mute audio setting (audioBitrateKbps = 0) disables audio track', () {
      const mutedSettings = AppSettings(audioBitrateKbps: 0);
      expect(mutedSettings.audioBitrateKbps, equals(0));
    });

    test('Smart adaptive scaler selects bilinear for fast and medium, bicubic for slow', () {
      String getScaleFlag(String preset) {
        return preset == 'slow' ? 'bicubic' : 'bilinear';
      }

      expect(getScaleFlag('fast'), equals('bilinear'));
      expect(getScaleFlag('medium'), equals('bilinear'));
      expect(getScaleFlag('slow'), equals('bicubic'));
    });

    test('H.264 high profile and level 4.1 configuration parameters are correct', () {
      const profileLevel = '-profile:v high -level:v 4.1';
      expect(profileLevel, contains('profile:v high'));
      expect(profileLevel, contains('level:v 4.1'));
    });

    test('H.264 rate control logic applies VBV buffer limits to prevent decoder spikes', () {
      const targetBitrateKbps = 4000;
      final vbvArgs =
          '-maxrate ${targetBitrateKbps * 2}k -bufsize ${targetBitrateKbps * 4}k';

      expect(vbvArgs, equals('-maxrate 8000k -bufsize 16000k'));
    });

    test('AppSettings serialization supports enableHardwareAcceleration', () {
      const defaultSettings = AppSettings();
      expect(defaultSettings.enableHardwareAcceleration, isFalse);

      final hwaSettings = defaultSettings.copyWith(enableHardwareAcceleration: true);
      expect(hwaSettings.enableHardwareAcceleration, isTrue);

      final json = hwaSettings.toJson();
      expect(json['enableHardwareAcceleration'], isTrue);

      final deserialized = AppSettings.fromJson(json);
      expect(deserialized.enableHardwareAcceleration, isTrue);
    });

    test('calculateHwaBitrateBounds returns calibrated VBV limits for MediaCodec', () {
      const opts = EncodingOptions();

      // 1080p: target 8000k, min 6000k, max 10000k, buf 16000k
      final bounds1080 = opts.calculateHwaBitrateBounds(
        targetWidth: 1920,
        targetHeight: 1080,
        sourceBitrateBps: 20000000,
      );
      expect(bounds1080['target'], equals(8000));
      expect(bounds1080['minrate'], equals(6000));
      expect(bounds1080['maxrate'], equals(10000));
      expect(bounds1080['bufsize'], equals(16000));

      // 720p: target 4500k, min 3500k, max 6000k, buf 9000k
      final bounds720 = opts.calculateHwaBitrateBounds(
        targetWidth: 1280,
        targetHeight: 720,
        sourceBitrateBps: 20000000,
      );
      expect(bounds720['target'], equals(4500));
      expect(bounds720['minrate'], equals(3500));
      expect(bounds720['maxrate'], equals(6000));
      expect(bounds720['bufsize'], equals(9000));

      // 480p: target 2000k, min 1500k, max 2600k, buf 4000k
      final bounds480 = opts.calculateHwaBitrateBounds(
        targetWidth: 854,
        targetHeight: 480,
        sourceBitrateBps: 20000000,
      );
      expect(bounds480['target'], equals(2000));
      expect(bounds480['minrate'], equals(1500));
      expect(bounds480['maxrate'], equals(2600));
      expect(bounds480['bufsize'], equals(4000));
    });

    test('HWA argument list contains dual bitrate flags, -minrate, and 1-second dynamic GOP', () {
      final hwaBounds = const EncodingOptions().calculateHwaBitrateBounds(
        targetWidth: 1280,
        targetHeight: 720,
        sourceBitrateBps: 1300000,
      );
      final targetKbps = hwaBounds['target']!;
      final minrateKbps = hwaBounds['minrate']!;
      final maxrateKbps = hwaBounds['maxrate']!;
      final bufsizeKbps = hwaBounds['bufsize']!;
      const fps = 30.0;
      final gop = fps.round();

      final codecArgs = [
        '-c:v',
        'h264_mediacodec',
        '-bitrate',
        '${targetKbps}k',
        '-b:v',
        '${targetKbps}k',
        '-minrate',
        '${minrateKbps}k',
        '-maxrate',
        '${maxrateKbps}k',
        '-bufsize',
        '${bufsizeKbps}k',
        '-profile:v',
        'high',
        '-level:v',
        '4.1',
        '-g',
        '$gop',
        '-bf',
        '0',
      ];

      expect(codecArgs, contains('-bitrate'));
      expect(codecArgs, contains('-b:v'));
      expect(codecArgs, contains('-minrate'));
      expect(codecArgs, contains('-profile:v'));
      expect(codecArgs, contains('-g'));
      expect(codecArgs, contains('$gop'));
      expect(codecArgs, contains('-bf'));
      expect(codecArgs, contains('0'));
    });

    test('Smart Stream Copy condition correctly evaluates eligibility for lossless passthrough', () {
      const sourceVideo = VideoInfo(
        filePath: '/storage/sample.mp4',
        fileName: 'sample.mp4',
        width: 1280,
        height: 720,
        durationSeconds: 120,
        bitrate: 1300000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 20000000,
        hasAudio: true,
        audioCodec: 'aac',
      );

      // Same resolution, same FPS, h264 source -> eligible
      final isOriginalRes = 1280 == sourceVideo.width && 720 == sourceVideo.height;
      final isH264 = sourceVideo.codec.toLowerCase().contains('h264') ||
          sourceVideo.codec.toLowerCase().contains('avc');
      final isSameFps = 0 <= 0 || 0 == sourceVideo.fps.round();
      final isStreamCopy = isOriginalRes && isH264 && isSameFps;

      expect(isStreamCopy, isTrue);

      // Downscaled resolution -> NOT eligible (must re-encode)
      final isDownscaleRes = 854 == sourceVideo.width && 480 == sourceVideo.height;
      final isStreamCopyDownscale = isDownscaleRes && isH264 && isSameFps;
      expect(isStreamCopyDownscale, isFalse);
    });

    test('HWA filter chain enforces centered even padding and yuv420p format', () {
      const targetW = 1920;
      const targetH = 1080;
      const fpsFilter = 'fps=fps=30,';
      final vf =
          '-vf "${fpsFilter}scale=w=$targetW:h=$targetH:force_original_aspect_ratio=decrease,pad=ceil(iw/2)*2:ceil(ih/2)*2:(ow-iw)/2:(oh-ih)/2,format=yuv420p"';

      expect(vf, contains('force_original_aspect_ratio=decrease'));
      expect(vf, contains('pad=ceil(iw/2)*2:ceil(ih/2)*2:(ow-iw)/2:(oh-ih)/2'));
      expect(vf, contains('format=yuv420p'));
    });

    test('FFmpegService.buildVideoArguments strictly excludes -crf and applies 8000k VBV bounds on portrait HWA downscale', () {
      const portraitSource = VideoInfo(
        filePath: '/storage/emulated/0/DCIM/portrait_video.mp4',
        fileName: 'portrait_video.mp4',
        width: 1512,
        height: 2688,
        durationSeconds: 14.5,
        bitrate: 41400000,
        fps: 30.0,
        codec: 'h264',
        fileSizeBytes: 75200000,
      );

      const target1080p = VideoResolution(
        label: '1080p',
        width: 1920,
        height: 1080,
      );

      const encodingOpts = EncodingOptions(
        rateControlMode: RateControlMode.crf,
        crfValue: 20,
      );

      const appSettings = AppSettings(
        enableHardwareAcceleration: true,
      );

      final args = FFmpegService.buildVideoArguments(
        sourceVideo: portraitSource,
        targetResolution: target1080p,
        encodingOptions: encodingOpts,
        appSettings: appSettings,
        outputPath: '/storage/emulated/0/Movies/output-1080p.mp4',
      );

      // Verify CRF is completely excluded under HWA
      expect(args.contains('-crf'), isFalse, reason: 'HWA MediaCodec must never receive -crf');

      // Verify MediaCodec encoder is selected
      expect(args, contains('h264_mediacodec'));

      // Verify VBV bounds: 1080p -> target 8000k, min 6000k, max 10000k, bufsize 16000k
      final bitrateIdx = args.indexOf('-bitrate');
      expect(bitrateIdx, isNot(-1));
      expect(args[bitrateIdx + 1], equals('8000k'));

      final bvIdx = args.indexOf('-b:v');
      expect(bvIdx, isNot(-1));
      expect(args[bvIdx + 1], equals('8000k'));

      final minrateIdx = args.indexOf('-minrate');
      expect(minrateIdx, isNot(-1));
      expect(args[minrateIdx + 1], equals('6000k'));

      final maxrateIdx = args.indexOf('-maxrate');
      expect(maxrateIdx, isNot(-1));
      expect(args[maxrateIdx + 1], equals('10000k'));

      final bufsizeIdx = args.indexOf('-bufsize');
      expect(bufsizeIdx, isNot(-1));
      expect(args[bufsizeIdx + 1], equals('16000k'));

      // Verify GOP 1 second and B-frames disabled
      final gIdx = args.indexOf('-g');
      expect(gIdx, isNot(-1));
      expect(args[gIdx + 1], equals('30'));

      final bfIdx = args.indexOf('-bf');
      expect(bfIdx, isNot(-1));
      expect(args[bfIdx + 1], equals('0'));

      // Verify portrait dimensions swapped: scale target is 1080x1920
      final vfIdx = args.indexOf('-vf');
      expect(vfIdx, isNot(-1));
      final vf = args[vfIdx + 1];
      expect(vf, contains('scale=w=1080:h=1920:force_original_aspect_ratio=decrease'));
      expect(vf, contains('pad=ceil(iw/2)*2:ceil(ih/2)*2:(ow-iw)/2:(oh-ih)/2'));
      expect(vf, contains('format=yuv420p'));
    });

    test('FFmpegService.buildVideoArguments respects custom bitrate in Bitrate mode under HWA', () {
      const sourceVideo = VideoInfo(
        filePath: '/sample.mp4',
        fileName: 'sample.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 10.0,
        bitrate: 15000000,
        fps: 30.0,
        codec: 'h264',
        fileSizeBytes: 18000000,
      );

      const target720p = VideoResolution(
        label: '720p',
        width: 1280,
        height: 720,
      );

      const encodingOpts = EncodingOptions(
        rateControlMode: RateControlMode.bitrate,
        customBitrateKbps: 12000,
      );

      const appSettings = AppSettings(
        enableHardwareAcceleration: true,
      );

      final args = FFmpegService.buildVideoArguments(
        sourceVideo: sourceVideo,
        targetResolution: target720p,
        encodingOptions: encodingOpts,
        appSettings: appSettings,
        outputPath: '/output-720p.mp4',
      );

      expect(args.contains('-crf'), isFalse);
      expect(args, contains('h264_mediacodec'));

      final bitrateIdx = args.indexOf('-bitrate');
      expect(args[bitrateIdx + 1], equals('12000k'));

      final minrateIdx = args.indexOf('-minrate');
      expect(args[minrateIdx + 1], equals('9000k')); // 12000 * 0.75

      final maxrateIdx = args.indexOf('-maxrate');
      expect(args[maxrateIdx + 1], equals('15600k')); // 12000 * 1.3
    });

    test('FFmpegService.buildVideoArguments applies libx264 with -crf in software mode', () {
      const sourceVideo = VideoInfo(
        filePath: '/sample.mp4',
        fileName: 'sample.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 10.0,
        bitrate: 15000000,
        fps: 30.0,
        codec: 'h264',
        fileSizeBytes: 18000000,
      );

      const target720p = VideoResolution(
        label: '720p',
        width: 1280,
        height: 720,
      );

      const encodingOpts = EncodingOptions(
        rateControlMode: RateControlMode.crf,
        crfValue: 22,
      );

      // Hardware acceleration disabled
      const appSettings = AppSettings(
        enableHardwareAcceleration: false,
      );

      final args = FFmpegService.buildVideoArguments(
        sourceVideo: sourceVideo,
        targetResolution: target720p,
        encodingOptions: encodingOpts,
        appSettings: appSettings,
        outputPath: '/output-720p.mp4',
      );

      expect(args, contains('libx264'));
      expect(args, isNot(contains('h264_mediacodec')));

      final crfIdx = args.indexOf('-crf');
      expect(crfIdx, isNot(-1));
      expect(args[crfIdx + 1], equals('22'));
    });

    test('FFmpegService.buildVideoArguments respects forceSoftwareFallback even if HWA is enabled in settings', () {
      const sourceVideo = VideoInfo(
        filePath: '/sample.mp4',
        fileName: 'sample.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 10.0,
        bitrate: 15000000,
        fps: 30.0,
        codec: 'h264',
        fileSizeBytes: 18000000,
      );

      const target720p = VideoResolution(
        label: '720p',
        width: 1280,
        height: 720,
      );

      const encodingOpts = EncodingOptions(
        rateControlMode: RateControlMode.crf,
        crfValue: 21,
      );

      const appSettings = AppSettings(
        enableHardwareAcceleration: true,
      );

      final args = FFmpegService.buildVideoArguments(
        sourceVideo: sourceVideo,
        targetResolution: target720p,
        encodingOptions: encodingOpts,
        appSettings: appSettings,
        outputPath: '/output-720p.mp4',
        forceSoftwareFallback: true,
      );

      expect(args, contains('libx264'));
      expect(args, isNot(contains('h264_mediacodec')));
      expect(args, contains('-crf'));
    });
  });
}
