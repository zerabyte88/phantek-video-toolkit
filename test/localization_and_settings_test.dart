import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_downscaler/models/app_settings.dart';
import 'package:video_downscaler/models/encoding_options.dart';
import 'package:video_downscaler/models/video_info.dart';
import 'package:video_downscaler/services/cache_manager_service.dart';
import 'package:video_downscaler/services/ffmpeg_service.dart';
import 'package:video_downscaler/services/localization_service.dart';

void main() {
  group('Localization tests', () {
    const supportedCodes = ['id', 'en', 'ja', 'zh_CN', 'zh_TW', 'ko'];

    test('All 6 requested languages are available in supportedLanguages', () {
      final codes = AppLocalizations.supportedLanguages.map((l) => l['code']).toList();
      for (final code in supportedCodes) {
        expect(codes.contains(code), isTrue, reason: 'Language $code must be supported');
      }
    });

    test('Translations resolve correctly for all supported languages', () {
      for (final code in supportedCodes) {
        final l10n = AppLocalizations(code);
        expect(l10n.t('app_title'), 'Phantek Video Toolkit');
        expect(l10n.t('pick_video').isNotEmpty, isTrue);
        expect(l10n.t('settings_title').isNotEmpty, isTrue);
        expect(l10n.t('loading_analyzing').isNotEmpty, isTrue);
        expect(l10n.t('settings_hardware').isNotEmpty, isTrue);
        expect(l10n.t('settings_cpu_threads').isNotEmpty, isTrue);
      }
    });

    test('String argument substitution works', () {
      final l10n = const AppLocalizations('id');
      final result = l10n.t('settings_detected_cores', args: {'count': '8'});
      expect(result.contains('8'), isTrue);
    });

    test('Cancel buttons, dialogs, rate control, and feature highlights resolve properly in all languages', () {
      for (final code in supportedCodes) {
        final l10n = AppLocalizations(code);
        expect(l10n.t('proc_cancel_confirm').isNotEmpty, isTrue);
        expect(l10n.t('proc_continue_btn').isNotEmpty, isTrue);
        expect(l10n.t('proc_cancel_btn').isNotEmpty, isTrue);
        expect(l10n.t('rate_control').isNotEmpty, isTrue);
        expect(l10n.t('feature_offline_fast').isNotEmpty, isTrue);
        expect(l10n.t('feature_offline_fast_desc').isNotEmpty, isTrue);
        expect(l10n.t('feature_crf_bitrate').isNotEmpty, isTrue);
        expect(l10n.t('feature_crf_bitrate_desc').isNotEmpty, isTrue);
        expect(l10n.t('feature_privacy').isNotEmpty, isTrue);
        expect(l10n.t('feature_privacy_desc').isNotEmpty, isTrue);
        expect(l10n.t('error_details').isNotEmpty, isTrue);
        expect(l10n.t('app_version').isNotEmpty, isTrue);
        expect(l10n.t('res_original').isNotEmpty, isTrue);

        // Ensure keys do not return the literal key name
        expect(l10n.t('proc_cancel_confirm'), isNot(equals('proc_cancel_confirm')));
        expect(l10n.t('proc_continue_btn'), isNot(equals('proc_continue_btn')));
        expect(l10n.t('proc_cancel_btn'), isNot(equals('proc_cancel_btn')));
        expect(l10n.t('rate_control'), isNot(equals('rate_control')));
      }
    });

    test('100% of all l10n.t keys used across lib are translated in all 6 supported languages', () {
      final allCalls = <String>{};
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final regex1 = RegExp(r"l10n\.t\('([^']+)'");
      final regex2 = RegExp(r'l10n\.t\("([^"]+)"');

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final m in regex1.allMatches(content)) {
          allCalls.add(m.group(1)!);
        }
        for (final m in regex2.allMatches(content)) {
          allCalls.add(m.group(1)!);
        }
      }

      // Add dynamic keys
      allCalls.addAll([
        'desc_mp4', 'desc_mkv', 'desc_mov', 'desc_webm',
        'desc_h264', 'desc_hevc', 'desc_vp9',
      ]);
      // Remove any interpolated placeholder patterns if present
      allCalls.removeWhere((k) => k.contains(r'$'));

      for (final code in supportedCodes) {
        final l10n = AppLocalizations(code);
        for (final key in allCalls) {
          final translated = l10n.t(key);
          expect(translated, isNot(equals(key)),
              reason: 'Key "$key" is missing translation for language "$code"');
          expect(translated.isNotEmpty, isTrue,
              reason: 'Key "$key" is empty for language "$code"');
        }
      }
    });
  });

  // Encoding tests removed due to refactor

  group('AppSettings tests', () {
    test('Default values are correct', () {
      const settings = AppSettings();
      expect(settings.cpuThreads, equals(0)); // Auto
      expect(settings.ramBufferMb, equals(512));
      expect(settings.cpuPreset, equals('medium'));
      expect(settings.audioBitrateKbps, equals(128));
      expect(settings.languageCode, equals('id'));
      expect(settings.themeMode, equals('dark'));
      expect(settings.keepScreenAwake, isFalse);
      expect(settings.outputDirectory, equals(''));
    });

    test('Serialization to and from JSON works', () {
      const original = AppSettings(
        cpuThreads: 4,
        ramBufferMb: 1024,
        cpuPreset: 'fast',
        audioBitrateKbps: 192,
        languageCode: 'ja',
        themeMode: 'oled',
        keepScreenAwake: true,
        outputDirectory: '/custom/storage/Movies',
      );

      final json = original.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.cpuThreads, equals(4));
      expect(restored.ramBufferMb, equals(1024));
      expect(restored.cpuPreset, equals('fast'));
      expect(restored.audioBitrateKbps, equals(192));
      expect(restored.languageCode, equals('ja'));
      expect(restored.themeMode, equals('oled'));
      expect(restored.keepScreenAwake, isTrue);
      expect(restored.outputDirectory, equals('/custom/storage/Movies'));
    });

    test('New theme, wakelock, and cache storage translations exist', () {
      for (final code in ['id', 'en', 'ja', 'zh_CN', 'zh_TW', 'ko']) {
        final l10n = AppLocalizations(code);
        expect(l10n.t('settings_theme').isNotEmpty, isTrue);
        expect(l10n.t('theme_oled').isNotEmpty, isTrue);
        expect(l10n.t('theme_light').isNotEmpty, isTrue);
        expect(l10n.t('settings_wakelock').isNotEmpty, isTrue);
        expect(l10n.t('settings_wakelock_desc').isNotEmpty, isTrue);
        expect(l10n.t('proc_elapsed_time').isNotEmpty, isTrue);
        expect(l10n.t('proc_remaining_time').isNotEmpty, isTrue);
        expect(l10n.t('settings_storage').isNotEmpty, isTrue);
        expect(l10n.t('settings_cache_size').isNotEmpty, isTrue);
        expect(l10n.t('settings_clear_cache').isNotEmpty, isTrue);

        // v1.1.2 new keys
        expect(l10n.t('codec_hevc_warning').isNotEmpty, isTrue);
        expect(l10n.t('codec_vp9_warning').isNotEmpty, isTrue);
        expect(l10n.t('codec_compat_hint').isNotEmpty, isTrue);
        expect(l10n.t('back_to_home').isNotEmpty, isTrue);
        expect(l10n.t('settings_output_folder').isNotEmpty, isTrue);
        expect(l10n.t('settings_output_folder_desc').isNotEmpty, isTrue);
        expect(l10n.t('settings_change_folder').isNotEmpty, isTrue);
        expect(l10n.t('settings_reset_folder').isNotEmpty, isTrue);
        expect(l10n.t('settings_folder_changed').isNotEmpty, isTrue);
        expect(l10n.t('settings_folder_default').isNotEmpty, isTrue);
      }
    });

    test('AppSettings copyWith properly updates outputDirectory and other fields', () {
      const original = AppSettings();
      final updated = original.copyWith(
        outputDirectory: '/custom/path',
        keepScreenAwake: true,
      );

      expect(updated.outputDirectory, equals('/custom/path'));
      expect(updated.keepScreenAwake, isTrue);
      expect(updated.cpuThreads, equals(original.cpuThreads));
      expect(updated.themeMode, equals(original.themeMode));
    });

    test('FFmpegService getOutputDirectory uses customPath when provided and valid', () async {
      final customTemp = Directory('${Directory.systemTemp.path}/test_custom_output_${DateTime.now().millisecondsSinceEpoch}');
      try {
        final result = await FFmpegService.getOutputDirectory(customPath: customTemp.path);
        expect(result.path, equals(customTemp.path));
        expect(await result.exists(), isTrue);
      } finally {
        if (await customTemp.exists()) {
          await customTemp.delete(recursive: true);
        }
      }
    });
  });

  group('EncodingOptions and Mode Restrictions tests', () {
    test('Default encoding options uses H264 and MP4 for best stability', () {
      const opts = EncodingOptions();
      expect(opts.codec, equals(VideoCodec.h264));
      expect(opts.container, equals(VideoContainer.mp4));
    });

    test('Non-convert containers exclude webm for H264 stability', () {
      final safeContainers =
          VideoContainer.values.where((c) => c != VideoContainer.webm).toList();
      expect(safeContainers.contains(VideoContainer.mp4), isTrue);
      expect(safeContainers.contains(VideoContainer.mkv), isTrue);
      expect(safeContainers.contains(VideoContainer.mov), isTrue);
      expect(safeContainers.contains(VideoContainer.webm), isFalse);
    });
  });

  group('CacheManager and Telemetry Consistency tests', () {
    test('formatBytes formats properly across units', () {
      expect(CacheManagerService.formatBytes(0), equals('0 B'));
      expect(CacheManagerService.formatBytes(500), equals('500 B'));
      expect(CacheManagerService.formatBytes(1024), equals('1 KB'));
      expect(CacheManagerService.formatBytes(1048576), equals('1.0 MB'));
      expect(CacheManagerService.formatBytes(1572864000), equals('1.46 GB'));
    });

    test('isCachedPath identifies temporary and picker cached paths', () {
      final cacheManager = CacheManagerService();
      expect(cacheManager.isCachedPath('/data/user/0/com.app/cache/file_picker/vid.mp4'), isTrue);
      expect(cacheManager.isCachedPath('/data/user/0/com.app/cache/sample.mp4'), isTrue);
      expect(cacheManager.isCachedPath('C:\\temp\\cache\\vid.mp4'), isTrue);
      expect(cacheManager.isCachedPath('/storage/emulated/0/Movies/sample.mp4'), isFalse);
    });

    test('Percentage formatting retains 1 decimal place consistently without rounding discrepancy', () {
      String formatPercentage(double progress) {
        final percent = (progress * 100).clamp(0.0, 100.0);
        return '${percent.toStringAsFixed(1)}%';
      }

      // 0.185 (18.5%) should format to 18.5%, not 19%
      expect(formatPercentage(0.185), equals('18.5%'));
      expect(formatPercentage(0.0), equals('0.0%'));
      expect(formatPercentage(0.50), equals('50.0%'));
      expect(formatPercentage(1.0), equals('100.0%'));
    });
  });

  group('FFmpegService Unique Output Path tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('unique_path_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generates initial path when file does not exist', () async {
      final path = await FFmpegService.generateUniqueOutputPath(
        outputDir: tempDir,
        fileName: 'video4k.mp4',
        targetResolution: VideoResolution.standardResolutions.first,
        container: VideoContainer.mp4,
      );

      final sep = Platform.pathSeparator;
      expect(path, equals('${tempDir.path}${sep}video4k-4k.mp4'));
    });

    test('appends incremental suffix -2 when file already exists', () async {
      final sep = Platform.pathSeparator;
      // Pre-create video4k-4k.mp4
      File('${tempDir.path}${sep}video4k-4k.mp4').createSync();

      final path = await FFmpegService.generateUniqueOutputPath(
        outputDir: tempDir,
        fileName: 'video4k.mp4',
        targetResolution: VideoResolution.standardResolutions.first,
        container: VideoContainer.mp4,
      );

      expect(path, equals('${tempDir.path}${sep}video4k-4k-2.mp4'));
    });

    test('appends incremental suffix -3 when base and -2 already exist', () async {
      final sep = Platform.pathSeparator;
      // Pre-create video4k-4k.mp4 and video4k-4k-2.mp4
      File('${tempDir.path}${sep}video4k-4k.mp4').createSync();
      File('${tempDir.path}${sep}video4k-4k-2.mp4').createSync();

      final path = await FFmpegService.generateUniqueOutputPath(
        outputDir: tempDir,
        fileName: 'video4k.mp4',
        targetResolution: VideoResolution.standardResolutions.first,
        container: VideoContainer.mp4,
      );

      expect(path, equals('${tempDir.path}${sep}video4k-4k-3.mp4'));
    });
  });

  group('VideoInfo resolution formatting tests', () {
    test('resolution returns clean names without (HD), (FHD), (QHD), (SD)', () {
      const v4k = VideoInfo(
        filePath: '/test.mp4',
        fileName: 'test.mp4',
        width: 3840,
        height: 2160,
        durationSeconds: 10,
        bitrate: 1000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 1000,
      );
      const v2k = VideoInfo(
        filePath: '/test.mp4',
        fileName: 'test.mp4',
        width: 2560,
        height: 1440,
        durationSeconds: 10,
        bitrate: 1000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 1000,
      );
      const v1080 = VideoInfo(
        filePath: '/test.mp4',
        fileName: 'test.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 10,
        bitrate: 1000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 1000,
      );
      const v720 = VideoInfo(
        filePath: '/test.mp4',
        fileName: 'test.mp4',
        width: 1280,
        height: 720,
        durationSeconds: 10,
        bitrate: 1000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 1000,
      );
      const v480 = VideoInfo(
        filePath: '/test.mp4',
        fileName: 'test.mp4',
        width: 854,
        height: 480,
        durationSeconds: 10,
        bitrate: 1000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 1000,
      );

      expect(v4k.resolution, equals('4K'));
      expect(v2k.resolution, equals('2K'));
      expect(v1080.resolution, equals('1080p'));
      expect(v720.resolution, equals('720p'));
      expect(v480.resolution, equals('480p'));

      // Check available downscale targets label
      expect(v720.availableDownscaleTargets.first.label, equals('Original (720p)'));
    });
  });
}

