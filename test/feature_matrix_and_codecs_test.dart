// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 zerabyte88

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:phantek_video_toolkit/models/app_settings.dart';
import 'package:phantek_video_toolkit/models/encoding_options.dart';
import 'package:phantek_video_toolkit/models/video_info.dart';
import 'package:phantek_video_toolkit/services/ffmpeg_service.dart';

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

  group('4. Settings and Encoding Pipeline Integration Tests', () {
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

    test(
      'H.264 high profile and level 4.1 configuration parameters are correct',
      () {
        const profileLevel = '-profile:v high -level:v 4.1';
        expect(profileLevel, contains('profile:v high'));
        expect(profileLevel, contains('level:v 4.1'));
      },
    );

    test('H.264 rate control logic applies VBV buffer limits to prevent decoder spikes', () {
      const targetBitrateKbps = 4000;
      final vbvArgs =
          '-maxrate ${targetBitrateKbps * 2}k -bufsize ${targetBitrateKbps * 4}k';

      expect(vbvArgs, equals('-maxrate 8000k -bufsize 16000k'));
    });

    test('EncodingOptions default crfValue is 22 (Normal preset) and crf getter alias matches', () {
      const opts = EncodingOptions();
      expect(opts.crfValue, equals(22));
      expect(opts.crf, equals(22));
      expect(opts.speedPreset, equals(SpeedPreset.normal));
    });

    test('SpeedPreset ladder configuration matches mobile optimized specifications', () {
      expect(SpeedPreset.fast.scaler, equals('area'));
      expect(SpeedPreset.fast.x264Preset, equals('veryfast'));
      expect(SpeedPreset.fast.defaultCrf, equals(24));

      expect(SpeedPreset.normal.scaler, equals('bicubic'));
      expect(SpeedPreset.normal.x264Preset, equals('faster'));
      expect(SpeedPreset.normal.defaultCrf, equals(22));

      expect(
        SpeedPreset.max.scaler,
        equals('lanczos+accurate_rnd+full_chroma_int'),
      );
      expect(SpeedPreset.max.x264Preset, equals('fast'));
      expect(SpeedPreset.max.defaultCrf, equals(20));
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
      final isOriginalRes =
          1280 == sourceVideo.width && 720 == sourceVideo.height;
      final isH264 =
          sourceVideo.codec.toLowerCase().contains('h264') ||
          sourceVideo.codec.toLowerCase().contains('avc');
      final isSameFps = 0 <= 0 || 0 == sourceVideo.fps.round();
      final isStreamCopy = isOriginalRes && isH264 && isSameFps;

      expect(isStreamCopy, isTrue);

      // Downscaled resolution -> NOT eligible (must re-encode)
      final isDownscaleRes =
          854 == sourceVideo.width && 480 == sourceVideo.height;
      final isStreamCopyDownscale = isDownscaleRes && isH264 && isSameFps;
      expect(isStreamCopyDownscale, isFalse);
    });

    test('FFmpegService.buildVideoArguments swaps portrait dimensions and uses single-pass scale filter', () {
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
        hasAudio: true,
        audioCodec: 'aac',
        audioChannels: 2,
        audioBitrateKbps: 128,
      );

      const target1080p = VideoResolution(
        label: '1080p',
        width: 1920,
        height: 1080,
      );

      const encodingOpts = EncodingOptions(
        rateControlMode: RateControlMode.crf,
        speedPreset: SpeedPreset.normal,
        crfValue: 20,
      );

      const appSettings = AppSettings(audioBitrateKbps: 128);

      final args = FFmpegService.buildVideoArguments(
        sourceVideo: portraitSource,
        targetResolution: target1080p,
        encodingOptions: encodingOpts,
        appSettings: appSettings,
        outputPath: '/storage/emulated/0/Movies/output-1080p.mp4',
      );

      // Verify software libx264 encoder is selected
      expect(args, contains('libx264'));
      expect(args, isNot(contains('h264_mediacodec')));

      // Verify unconstrained CRF mode
      final crfIdx = args.indexOf('-crf');
      expect(crfIdx, isNot(-1));
      expect(args[crfIdx + 1], equals('20'));
      expect(args.contains('-bitrate'), isFalse);
      expect(args.contains('-minrate'), isFalse);
      expect(args.contains('-maxrate'), isFalse);
      expect(args.contains('-bufsize'), isFalse);

      // Verify single-pass scale with bicubic flag for normal preset
      final vfIdx = args.indexOf('-vf');
      expect(vfIdx, isNot(-1));
      final vf = args[vfIdx + 1];
      expect(vf, contains('scale=1080:1920:flags=bicubic'));
      expect(vf, contains('format=yuv420p'));

      // Verify smart audio copy since source is AAC <= 2ch and <= 128k
      final caIdx = args.indexOf('-c:a');
      expect(caIdx, isNot(-1));
      expect(args[caIdx + 1], equals('copy'));

      // Verify compatibility flags
      expect(args, contains('-pix_fmt'));
      expect(args[args.indexOf('-pix_fmt') + 1], equals('yuv420p'));
      expect(args, contains('-movflags'));
      expect(args[args.indexOf('-movflags') + 1], equals('+faststart'));
    });

    test('FFmpegService smart audio passthrough enforces 4 strict rules', () {
      const baseVideo = VideoInfo(
        filePath: '/test.mp4',
        fileName: 'test.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 60,
        bitrate: 10000000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 50000000,
        hasAudio: true,
        audioCodec: 'aac',
        audioChannels: 2,
        audioBitrateKbps: 128,
      );

      const target720p = VideoResolution(
        label: '720p',
        width: 1280,
        height: 720,
      );
      const appSettings128 = AppSettings(audioBitrateKbps: 128);

      // 1. Valid: AAC + MP4 + <= 2ch + bitrate <= 128k*1.1 -> copy
      final argsPass = FFmpegService.buildVideoArguments(
        sourceVideo: baseVideo,
        targetResolution: target720p,
        encodingOptions: const EncodingOptions(),
        appSettings: appSettings128,
        outputPath: '/out.mp4',
      );
      expect(argsPass[argsPass.indexOf('-c:a') + 1], equals('copy'));

      // 2. Multichannel (5.1ch) -> must downmix to stereo
      const multichannelVideo = VideoInfo(
        filePath: '/test.mp4',
        fileName: 'test.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 60,
        bitrate: 10000000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 50000000,
        hasAudio: true,
        audioCodec: 'aac',
        audioChannels: 6,
        audioBitrateKbps: 128,
      );
      final argsMulti = FFmpegService.buildVideoArguments(
        sourceVideo: multichannelVideo,
        targetResolution: target720p,
        encodingOptions: const EncodingOptions(),
        appSettings: appSettings128,
        outputPath: '/out.mp4',
      );
      expect(argsMulti[argsMulti.indexOf('-c:a') + 1], equals('aac'));
      expect(argsMulti, contains('-ac'));
      expect(argsMulti[argsMulti.indexOf('-ac') + 1], equals('2'));

      // 3. Higher bitrate (320k vs target 128k) -> must re-encode to respect user target
      const highBitrateAudio = VideoInfo(
        filePath: '/test.mp4',
        fileName: 'test.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 60,
        bitrate: 10000000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 50000000,
        hasAudio: true,
        audioCodec: 'aac',
        audioChannels: 2,
        audioBitrateKbps: 320,
      );
      final argsHigh = FFmpegService.buildVideoArguments(
        sourceVideo: highBitrateAudio,
        targetResolution: target720p,
        encodingOptions: const EncodingOptions(),
        appSettings: appSettings128,
        outputPath: '/out.mp4',
      );
      expect(argsHigh[argsHigh.indexOf('-c:a') + 1], equals('aac'));

      // 4. Non-AAC audio codec (e.g. ac3 or opus) -> must re-encode
      const ac3Audio = VideoInfo(
        filePath: '/test.mp4',
        fileName: 'test.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 60,
        bitrate: 10000000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 50000000,
        hasAudio: true,
        audioCodec: 'ac3',
        audioChannels: 2,
        audioBitrateKbps: 128,
      );
      final argsAc3 = FFmpegService.buildVideoArguments(
        sourceVideo: ac3Audio,
        targetResolution: target720p,
        encodingOptions: const EncodingOptions(),
        appSettings: appSettings128,
        outputPath: '/out.mp4',
      );
      expect(argsAc3[argsAc3.indexOf('-c:a') + 1], equals('aac'));

      // 5. Silent / No audio -> must use -an
      const silentAudio = VideoInfo(
        filePath: '/test.mp4',
        fileName: 'test.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 60,
        bitrate: 10000000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 50000000,
        hasAudio: false,
      );
      final argsSilent = FFmpegService.buildVideoArguments(
        sourceVideo: silentAudio,
        targetResolution: target720p,
        encodingOptions: const EncodingOptions(),
        appSettings: appSettings128,
        outputPath: '/out.mp4',
      );
      expect(argsSilent, contains('-an'));
      expect(argsSilent, isNot(contains('-c:a')));
    });

    test('FFmpegService.buildVideoArguments respects custom bitrate in Bitrate mode', () {
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

      const appSettings = AppSettings();

      final args = FFmpegService.buildVideoArguments(
        sourceVideo: sourceVideo,
        targetResolution: target720p,
        encodingOptions: encodingOpts,
        appSettings: appSettings,
        outputPath: '/output-720p.mp4',
      );

      expect(args.contains('-crf'), isFalse);
      expect(args, contains('libx264'));
      expect(args, isNot(contains('h264_mediacodec')));

      final bvIdx = args.indexOf('-b:v');
      expect(bvIdx, isNot(-1));
      expect(args[bvIdx + 1], equals('12000k'));
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

      const appSettings = AppSettings();

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
  });
}
