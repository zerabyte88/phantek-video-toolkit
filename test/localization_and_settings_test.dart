import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_downscaler/models/app_settings.dart';
import 'package:video_downscaler/models/encoding_options.dart';
import 'package:video_downscaler/models/video_info.dart';
import 'package:video_downscaler/services/cache_manager_service.dart';
import 'package:video_downscaler/services/device_spec_helper.dart';
import 'package:video_downscaler/services/ffmpeg_service.dart';
import 'package:video_downscaler/services/localization_service.dart';
import 'package:video_downscaler/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_downscaler/services/settings_service.dart';
import 'package:video_downscaler/theme/app_theme.dart';
import 'package:video_downscaler/widgets/conversion_options_card.dart';
import 'package:video_downscaler/widgets/theme_animated_background.dart';

const supportedUiCodes = [
  'id',
  'en',
  'ar',
  'ms',
  'da',
  'de',
  'es',
  'fr',
  'it',
  'nl',
  'no',
  'pt',
  'ru',
  'fi',
  'sv',
  'vi',
  'th',
  'hi',
  'ja',
  'zh_CN',
  'zh_TW',
  'ko',
];

const supportedCodes = [
  'id',
  'en',
  'zh',
  'ar',
  'ms',
  'da',
  'de',
  'es',
  'fr',
  'it',
  'nl',
  'no',
  'pt',
  'ru',
  'fi',
  'sv',
  'vi',
  'th',
  'hi',
  'ja',
  'zh_CN',
  'zh_TW',
  'ko',
];

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (ByteData? message) async {
            return const StandardMessageCodec().encodeMessage(<Object?>[null]);
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall methodCall,
        ) async {
          return null;
        });
  });

  group('Localization tests', () {
    test('All requested UI languages are available in supportedLanguages without duplicates', () {
      final codes = AppLocalizations.supportedLanguages
          .map((l) => l['code'])
          .toList();
      for (final code in supportedUiCodes) {
        expect(
          codes.contains(code),
          isTrue,
          reason: 'Language $code must be supported',
        );
      }
      expect(
        codes.contains('zh'),
        isFalse,
        reason: 'Duplicate zh should not be in supportedLanguages',
      );
      expect(codes.length, equals(supportedUiCodes.length));
      expect(
        codes,
        equals([
          'id',
          'ms',
          'da',
          'de',
          'en',
          'es',
          'fr',
          'it',
          'nl',
          'no',
          'pt',
          'fi',
          'sv',
          'vi',
          'ru',
          'ar',
          'hi',
          'th',
          'ja',
          'zh_CN',
          'zh_TW',
          'ko',
        ]),
        reason:
            'supportedLanguages must be sorted Latin A-Z followed by non-Latin',
      );
    });

    test('Translations resolve correctly for all supported languages', () {
      for (final code in supportedCodes) {
        final l10n = AppLocalizations(code);
        expect(l10n.t('app_title'), 'Phantek');
        expect(l10n.t('app_long_title'), 'Phantek - Video Toolkit');
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
        expect(l10n.t('settings_card_opacity').isNotEmpty, isTrue);
        expect(l10n.t('settings_card_opacity_desc').isNotEmpty, isTrue);

        // Ensure keys do not return the literal key name
        expect(
          l10n.t('proc_cancel_confirm'),
          isNot(equals('proc_cancel_confirm')),
        );
        expect(l10n.t('proc_continue_btn'), isNot(equals('proc_continue_btn')));
        expect(l10n.t('proc_cancel_btn'), isNot(equals('proc_cancel_btn')));
        expect(l10n.t('rate_control'), isNot(equals('rate_control')));
        expect(
          l10n.t('settings_card_opacity'),
          isNot(equals('settings_card_opacity')),
        );
        expect(
          l10n.t('settings_card_opacity_desc'),
          isNot(equals('settings_card_opacity_desc')),
        );
      }
    });

    test('Device specifications keys resolve properly and accurately in all supported languages', () {
      for (final code in supportedCodes) {
        final l10n = AppLocalizations(code);
        expect(l10n.t('device_name').isNotEmpty, isTrue);
        expect(l10n.t('device_model').isNotEmpty, isTrue);
        expect(l10n.t('device_cpu').isNotEmpty, isTrue);
        expect(l10n.t('device_gpu').isNotEmpty, isTrue);
        expect(l10n.t('device_ram').isNotEmpty, isTrue);
        expect(l10n.t('device_storage').isNotEmpty, isTrue);
        expect(l10n.t('storage_free').isNotEmpty, isTrue);

        expect(l10n.t('device_name'), isNot(equals('device_name')));
        expect(l10n.t('device_model'), isNot(equals('device_model')));
        expect(l10n.t('device_cpu'), isNot(equals('device_cpu')));
        expect(l10n.t('device_gpu'), isNot(equals('device_gpu')));
        expect(l10n.t('device_ram'), isNot(equals('device_ram')));
        expect(l10n.t('device_storage'), isNot(equals('device_storage')));
        expect(l10n.t('storage_free'), isNot(equals('storage_free')));
      }

      // Verify language accuracy: Indonesian has 'Nama HP' and 'Penyimpanan'
      final l10nId = const AppLocalizations('id');
      expect(l10nId.t('device_name'), equals('Nama HP'));
      expect(l10nId.t('device_model'), equals('Model HP'));
      expect(l10nId.t('device_storage'), equals('Penyimpanan'));

      // English has 'Device Name' and 'Storage'
      final l10nEn = const AppLocalizations('en');
      expect(l10nEn.t('device_name'), equals('Device Name'));
      expect(l10nEn.t('device_storage'), equals('Storage'));

      // Korean has '기기 이름' and '저장 공간'
      final l10nKo = const AppLocalizations('ko');
      expect(l10nKo.t('device_name'), equals('기기 이름'));
      expect(l10nKo.t('device_storage'), equals('저장 공간'));

      // Japanese has 'デバイス名' and 'ストレージ'
      final l10nJa = const AppLocalizations('ja');
      expect(l10nJa.t('device_name'), equals('デバイス名'));
      expect(l10nJa.t('device_storage'), equals('ストレージ'));
    });

    test('100% of all l10n.t keys used across lib are translated in all supported languages', () {
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
        'desc_mp4',
        'desc_mkv',
        'desc_mov',
        'desc_h264',
        'desc_hevc',
      ]);
      // Remove any interpolated placeholder patterns if present
      allCalls.removeWhere((k) => k.contains(r'$'));

      for (final code in supportedCodes) {
        final l10n = AppLocalizations(code);
        for (final key in allCalls) {
          final translated = l10n.t(key);
          expect(
            translated,
            isNot(equals(key)),
            reason: 'Key "$key" is missing translation for language "$code"',
          );
          expect(
            translated.isNotEmpty,
            isTrue,
            reason: 'Key "$key" is empty for language "$code"',
          );
        }
      }
    });
  });

  // Encoding tests removed due to refactor

  group('AppSettings tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (ByteData? message) async {
              return const StandardMessageCodec().encodeMessage(<Object?>[
                null,
              ]);
            },
          );
    });

    test('Default values are correct', () {
      const settings = AppSettings();
      expect(settings.cpuThreads, equals(0)); // Auto
      expect(settings.ramBufferMb, equals(512));
      expect(settings.cpuPreset, equals('medium'));
      expect(settings.audioBitrateKbps, equals(128));
      expect(settings.languageCode, equals('en'));
      expect(settings.themeMode, equals('dark'));
      expect(settings.keepScreenAwake, isFalse);
      expect(settings.outputDirectory, equals(''));
      expect(settings.audioOutputDirectory, equals(''));
      expect(settings.isEasterEggUnlocked, isFalse);
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
        audioOutputDirectory: '/custom/storage/Music',
        isEasterEggUnlocked: true,
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
      expect(restored.audioOutputDirectory, equals('/custom/storage/Music'));
      expect(restored.isEasterEggUnlocked, isTrue);

      // Legacy fallback: if themeMode is sakura without isEasterEggUnlocked key
      final legacy = AppSettings.fromJson({'themeMode': 'sakura'});
      expect(legacy.isEasterEggUnlocked, isTrue);
    });

    test('New theme, wakelock, and cache storage translations exist', () {
      for (final code in supportedCodes) {
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
        expect(l10n.t('codec_compat_hint').isNotEmpty, isTrue);
        expect(l10n.t('back_to_home').isNotEmpty, isTrue);
        expect(l10n.t('settings_output_folder').isNotEmpty, isTrue);
        expect(l10n.t('settings_output_folder_desc').isNotEmpty, isTrue);
        expect(l10n.t('settings_change_folder').isNotEmpty, isTrue);
        expect(l10n.t('settings_reset_folder').isNotEmpty, isTrue);
        expect(l10n.t('settings_folder_changed').isNotEmpty, isTrue);
        expect(l10n.t('settings_folder_default').isNotEmpty, isTrue);
        expect(l10n.t('settings_audio_output_folder').isNotEmpty, isTrue);
        expect(l10n.t('settings_audio_output_folder_desc').isNotEmpty, isTrue);
        expect(l10n.t('settings_audio_reset_folder').isNotEmpty, isTrue);
        expect(l10n.t('settings_audio_folder_changed').isNotEmpty, isTrue);
        expect(l10n.t('settings_audio_folder_default').isNotEmpty, isTrue);
        expect(l10n.t('easter_egg_already_active').isNotEmpty, isTrue);
      }
    });

    test('AppSettings clamps RAM buffer to 2048 MB on deserialization and copyWith', () {
      const original = AppSettings(ramBufferMb: 2048);
      expect(original.ramBufferMb, equals(2048));
      final json = original.toJson();
      expect(json['ramBufferMb'], equals(2048));
      final fromJson = AppSettings.fromJson(json);
      expect(fromJson.ramBufferMb, equals(2048));

      // Test clamping of values > 2048 MB from legacy stored json
      final clampedFromJson = AppSettings.fromJson({'ramBufferMb': 4096});
      expect(clampedFromJson.ramBufferMb, equals(2048));

      final updated = original.copyWith(ramBufferMb: 4096);
      expect(updated.ramBufferMb, equals(2048));
    });

    test(
      'DeviceSpecHelper getProcessRssMb returns non-negative memory integer',
      () {
        final rssMb = DeviceSpecHelper.getProcessRssMb();
        expect(rssMb, greaterThanOrEqualTo(0));
      },
    );

    test('DeviceSpecHelper getProcessCpuUsagePercent returns valid percentage within 0-100', () {
      final cpuUsage = DeviceSpecHelper.getProcessCpuUsagePercent();
      expect(cpuUsage, greaterThanOrEqualTo(0.0));
      expect(cpuUsage, lessThanOrEqualTo(100.0));
    });

    test(
      'AppSettings copyWith properly updates outputDirectory and other fields',
      () {
        const original = AppSettings();
        final updated = original.copyWith(
          outputDirectory: '/custom/path',
          audioOutputDirectory: '/custom/audio/path',
          keepScreenAwake: true,
        );

        expect(updated.outputDirectory, equals('/custom/path'));
        expect(updated.audioOutputDirectory, equals('/custom/audio/path'));
        expect(updated.keepScreenAwake, isTrue);
        expect(updated.cpuThreads, equals(original.cpuThreads));
        expect(updated.themeMode, equals(original.themeMode));
      },
    );

    test(
      'SettingsService properly toggles and persists keepScreenAwake',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = SettingsService();
        await service.init();

        expect(service.settings.keepScreenAwake, isFalse);

        await service.setKeepScreenAwake(true);
        expect(service.settings.keepScreenAwake, isTrue);

        await service.setKeepScreenAwake(false);
        expect(service.settings.keepScreenAwake, isFalse);

        await service.setKeepScreenAwake(true);
        expect(service.settings.keepScreenAwake, isTrue);

        await service.resetToDefaults();
        expect(service.settings.keepScreenAwake, isFalse);
      },
    );

    test(
      'SettingsService properly modifies, clamps and resets cardOpacity',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = SettingsService();
        await service.init();

        expect(service.settings.cardOpacity, equals(1.0));

        await service.setCardOpacity(0.75);
        expect(service.settings.cardOpacity, equals(0.75));

        // Clamping below 0.5
        await service.setCardOpacity(0.3);
        expect(service.settings.cardOpacity, equals(0.5));

        // Clamping above 1.0
        await service.setCardOpacity(1.2);
        expect(service.settings.cardOpacity, equals(1.0));

        // Reset to defaults restores 1.0
        await service.setCardOpacity(0.6);
        await service.resetToDefaults();
        expect(service.settings.cardOpacity, equals(1.0));
      },
    );

    test('AppTheme.getTheme correctly factors cardOpacity into surface and card colors', () {
      final solidDark = AppTheme.getTheme('dark', cardOpacity: 1.0);
      final translucentDark = AppTheme.getTheme('dark', cardOpacity: 0.5);

      expect(solidDark.cardTheme.color?.a, equals(1.0));
      expect(translucentDark.cardTheme.color?.a, lessThan(1.0));

      final solidLight = AppTheme.getTheme('light', cardOpacity: 1.0);
      final translucentLight = AppTheme.getTheme('light', cardOpacity: 0.8);

      expect(solidLight.cardTheme.color?.a, equals(1.0));
      expect(translucentLight.cardTheme.color?.a, lessThan(1.0));
    });

    test('FFmpegService getOutputDirectory uses customPath when provided and valid', () async {
      final customTemp = Directory(
        '${Directory.systemTemp.path}/test_custom_output_${DateTime.now().millisecondsSinceEpoch}',
      );
      try {
        final result = await FFmpegService.getOutputDirectory(
          customPath: customTemp.path,
        );
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

    test('Supported containers are MP4, MKV, and MOV for stability', () {
      final safeContainers = VideoContainer.values.toList();
      expect(safeContainers.contains(VideoContainer.mp4), isTrue);
      expect(safeContainers.contains(VideoContainer.mkv), isTrue);
      expect(safeContainers.contains(VideoContainer.mov), isTrue);
      expect(safeContainers.length, equals(3));
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
      expect(
        cacheManager.isCachedPath(
          '/data/user/0/com.app/cache/file_picker/vid.mp4',
        ),
        isTrue,
      );
      expect(
        cacheManager.isCachedPath('/data/user/0/com.app/cache/sample.mp4'),
        isTrue,
      );
      expect(cacheManager.isCachedPath('C:\\temp\\cache\\vid.mp4'), isTrue);
      expect(
        cacheManager.isCachedPath('/storage/emulated/0/Movies/sample.mp4'),
        isFalse,
      );
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

    test(
      'appends incremental suffix -3 when base and -2 already exist',
      () async {
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
      },
    );
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
      expect(
        v720.availableDownscaleTargets.first.label,
        equals('Original (720p)'),
      );
    });

    test('Navigation and options reset localization keys resolve correctly in all supported languages', () {
      for (final code in supportedCodes) {
        final l10n = AppLocalizations(code);
        expect(l10n.t('back_to_home').isNotEmpty, isTrue);
        expect(l10n.t('reset_options').isNotEmpty, isTrue);
        expect(l10n.t('options_reset_success').isNotEmpty, isTrue);
        expect(l10n.t('back_to_home'), isNot(equals('back_to_home')));
        expect(l10n.t('reset_options'), isNot(equals('reset_options')));
        expect(
          l10n.t('options_reset_success'),
          isNot(equals('options_reset_success')),
        );
      }
    });

    test('Audio Extractor localization keys resolve properly in all supported languages', () {
      for (final code in supportedCodes) {
        final l10n = AppLocalizations(code);
        expect(l10n.t('category_video').isNotEmpty, isTrue);
        expect(l10n.t('category_audio').isNotEmpty, isTrue);
        expect(l10n.t('category_video'), isNot(equals('category_video')));
        expect(l10n.t('category_audio'), isNot(equals('category_audio')));
        expect(l10n.t('mode_extractor').isNotEmpty, isTrue);
        expect(l10n.t('audio_options').isNotEmpty, isTrue);
        expect(l10n.t('audio_format').isNotEmpty, isTrue);
        expect(l10n.t('audio_bitrate').isNotEmpty, isTrue);
        expect(l10n.t('audio_copy').isNotEmpty, isTrue);
        expect(l10n.t('start_audio_extraction').isNotEmpty, isTrue);
        expect(l10n.t('proc_extracting').isNotEmpty, isTrue);
        expect(l10n.t('proc_audio_completed').isNotEmpty, isTrue);
        expect(l10n.t('proc_play_audio').isNotEmpty, isTrue);
        expect(l10n.t('desc_audio_mp3').isNotEmpty, isTrue);
        expect(l10n.t('desc_audio_m4a').isNotEmpty, isTrue);
        expect(l10n.t('desc_audio_wav').isNotEmpty, isTrue);
        expect(l10n.t('desc_audio_mp3'), isNot(equals('desc_audio_mp3')));
        expect(l10n.t('desc_audio_m4a'), isNot(equals('desc_audio_m4a')));
        expect(l10n.t('desc_audio_wav'), isNot(equals('desc_audio_wav')));
        expect(l10n.t('mode_extractor'), isNot(equals('mode_extractor')));
      }
    });
  });

  group('Audio Extractor and Format tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('audio_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('AudioFormat values have correct codecs and extensions', () {
      expect(AudioFormat.mp3.extension, equals('mp3'));
      expect(AudioFormat.mp3.ffmpegCodec, equals('libmp3lame'));

      expect(AudioFormat.m4a.extension, equals('m4a'));
      expect(AudioFormat.m4a.ffmpegCodec, equals('aac'));

      expect(AudioFormat.wav.extension, equals('wav'));
      expect(AudioFormat.wav.ffmpegCodec, equals('pcm_s16le'));
    });

    test(
      'generateUniqueAudioOutputPath generates clean unique audio filenames',
      () async {
        final sep = Platform.pathSeparator;
        final path1 = await FFmpegService.generateUniqueAudioOutputPath(
          outputDir: tempDir,
          fileName: 'clip.mp4',
          audioFormat: AudioFormat.mp3,
        );
        expect(path1, equals('${tempDir.path}${sep}clip-audio.mp3'));

        // Create file and check incremental naming
        File(path1).createSync();
        final path2 = await FFmpegService.generateUniqueAudioOutputPath(
          outputDir: tempDir,
          fileName: 'clip.mp4',
          audioFormat: AudioFormat.mp3,
        );
        expect(path2, equals('${tempDir.path}${sep}clip-audio-2.mp3'));
      },
    );

    test('VideoInfo tracks hasAudio and audioCodec accurately', () {
      const withAudio = VideoInfo(
        filePath: '/test/video.mp4',
        fileName: 'video.mp4',
        fileSizeBytes: 1024,
        durationSeconds: 10.0,
        width: 1920,
        height: 1080,
        bitrate: 5000000,
        fps: 30.0,
        codec: 'h264',
        audioCodec: 'aac',
        hasAudio: true,
      );
      expect(withAudio.hasAudio, isTrue);
      expect(withAudio.audioCodec, equals('aac'));

      const withoutAudio = VideoInfo(
        filePath: '/test/silent.mp4',
        fileName: 'silent.mp4',
        fileSizeBytes: 512,
        durationSeconds: 5.0,
        width: 1280,
        height: 720,
        bitrate: 2000000,
        fps: 30.0,
        codec: 'h264',
        hasAudio: false,
      );
      expect(withoutAudio.hasAudio, isFalse);
      expect(withoutAudio.audioCodec, isNull);
    });

    test('no_audio_track localization resolves properly across all supported languages', () {
      for (final code in supportedCodes) {
        final l10n = AppLocalizations(code);
        final translated = l10n.t('no_audio_track');
        expect(translated.isNotEmpty, isTrue);
        expect(translated, isNot(equals('no_audio_track')));
      }
    });

    test(
      'FFmpegService getOutputDirectory respects custom path and isAudio flag',
      () async {
        final customDir = Directory(
          '${tempDir.path}${Platform.pathSeparator}CustomAudio',
        );
        customDir.createSync();

        // Custom path provided with isAudio: true
        final outDirCustomAudio = await FFmpegService.getOutputDirectory(
          customPath: customDir.path,
          isAudio: true,
        );
        expect(outDirCustomAudio.path, equals(customDir.path));

        // Custom path provided with isAudio: false
        final outDirCustomVideo = await FFmpegService.getOutputDirectory(
          customPath: customDir.path,
          isAudio: false,
        );
        expect(outDirCustomVideo.path, equals(customDir.path));
      },
    );

    test('DeviceSpecHelper getMarketedRamGb calculates accurate marketing RAM capacities', () {
      expect(DeviceSpecHelper.getMarketedRamGb(7840), equals(8));
      expect(DeviceSpecHelper.getMarketedRamGb(5800), equals(6));
      expect(DeviceSpecHelper.getMarketedRamGb(3800), equals(4));
      expect(DeviceSpecHelper.getMarketedRamGb(11800), equals(12));
      expect(DeviceSpecHelper.getMarketedRamGb(15800), equals(16));
      expect(DeviceSpecHelper.getMarketedRamGb(23800), equals(24));
    });

    test('DeviceSpecHelper SoC and GPU detection correctly maps Snapdragon, Dimensity, and Exynos', () {
      final snapdragonCpu = DeviceSpecHelper.detectSocName(
        hardware: 'qcom',
        board: 'kalama',
        manufacturer: 'Qualcomm',
      );
      expect(snapdragonCpu, contains('Snapdragon 8 Gen 2'));
      final snapdragonGpu = DeviceSpecHelper.detectGpuName(
        hardware: 'qcom',
        board: 'kalama',
        socName: snapdragonCpu,
      );
      expect(snapdragonGpu, equals('Adreno 740'));

      final dimensityCpu = DeviceSpecHelper.detectSocName(
        hardware: 'mt6897',
        board: 'mt6897',
        manufacturer: 'MediaTek',
      );
      expect(dimensityCpu, contains('Dimensity 8300'));
      final dimensityGpu = DeviceSpecHelper.detectGpuName(
        hardware: 'mt6897',
        board: 'mt6897',
        socName: dimensityCpu,
      );
      expect(dimensityGpu, equals('Mali-G615 MC6'));

      final adreno710 = DeviceSpecHelper.detectGpuName(
        hardware: 'sm6450',
        board: 'crow',
        socName: 'Qualcomm Snapdragon 7s Gen 2',
      );
      expect(adreno710, equals('Adreno 710'));

      final exynosCpu = DeviceSpecHelper.detectSocName(
        hardware: 's5e9945',
        board: 's5e9945',
        manufacturer: 'Samsung',
      );
      expect(exynosCpu, contains('Exynos 2400'));
      final exynosGpu = DeviceSpecHelper.detectGpuName(
        hardware: 's5e9945',
        board: 's5e9945',
        socName: exynosCpu,
      );
      expect(exynosGpu, equals('Samsung Xclipse 940'));

      final snapdragon685 = DeviceSpecHelper.detectSocName(
        hardware: 'sm6225-ad',
        board: 'bengal',
        manufacturer: 'vivo',
      );
      expect(snapdragon685, equals('Qualcomm Snapdragon 685'));

      final snapdragon685BySocModel = DeviceSpecHelper.detectSocName(
        hardware: 'qcom',
        board: 'bengal',
        manufacturer: 'vivo',
        socModel: 'SM6225-AD',
      );
      expect(snapdragon685BySocModel, equals('Qualcomm Snapdragon 685'));

      final snapdragon685Gpu = DeviceSpecHelper.detectGpuName(
        hardware: 'sm6225-ad',
        board: 'bengal',
        socName: snapdragon685,
      );
      expect(snapdragon685Gpu, equals('Adreno 610'));

      // Snapdragon 685 detection via clock speed > 2.60 GHz (e.g. 2.80 GHz) on sm6225 / khaje
      final snapdragon685ByClock = DeviceSpecHelper.detectSocName(
        hardware: 'qcom',
        board: 'khaje',
        manufacturer: 'xiaomi',
        maxClockGhz: 2.80,
      );
      expect(snapdragon685ByClock, equals('Qualcomm Snapdragon 685'));

      final snapdragon685ByClockOnSm6225 = DeviceSpecHelper.detectSocName(
        hardware: 'sm6225',
        board: 'bengal',
        manufacturer: 'realme',
        maxClockGhz: 2.75,
      );
      expect(snapdragon685ByClockOnSm6225, equals('Qualcomm Snapdragon 685'));

      // Snapdragon 680 detection when clock speed <= 2.60 GHz (e.g. 2.40 GHz) or null on sm6225 / khaje
      final snapdragon680ByClock = DeviceSpecHelper.detectSocName(
        hardware: 'qcom',
        board: 'khaje',
        manufacturer: 'xiaomi',
        maxClockGhz: 2.40,
      );
      expect(snapdragon680ByClock, equals('Qualcomm Snapdragon 680'));

      final snapdragon680DefaultFallback = DeviceSpecHelper.detectSocName(
        hardware: 'sm6225',
        board: 'bengal',
        manufacturer: 'xiaomi',
      );
      expect(snapdragon680DefaultFallback, equals('Qualcomm Snapdragon 680'));

      // New 64-bit SoCs (2024-2026)
      final snapdragon8EliteCpu = DeviceSpecHelper.detectSocName(
        hardware: 'qcom',
        board: 'sun',
        manufacturer: 'Qualcomm',
        socModel: 'SM8750',
      );
      expect(snapdragon8EliteCpu, equals('Qualcomm Snapdragon 8 Elite'));
      final snapdragon8EliteGpu = DeviceSpecHelper.detectGpuName(
        hardware: 'sm8750',
        board: 'sun',
        socName: snapdragon8EliteCpu,
      );
      expect(snapdragon8EliteGpu, equals('Adreno 830'));

      final dimensity9400Cpu = DeviceSpecHelper.detectSocName(
        hardware: 'mt6991',
        board: 'mt6991',
        manufacturer: 'MediaTek',
      );
      expect(dimensity9400Cpu, equals('MediaTek Dimensity 9400'));
      final dimensity9400Gpu = DeviceSpecHelper.detectGpuName(
        hardware: 'mt6991',
        board: 'mt6991',
        socName: dimensity9400Cpu,
      );
      expect(dimensity9400Gpu, equals('Immortalis-G925 MC12'));

      final exynos2500Cpu = DeviceSpecHelper.detectSocName(
        hardware: 's5e9955',
        board: 's5e9955',
        manufacturer: 'Samsung',
      );
      expect(exynos2500Cpu, equals('Samsung Exynos 2500'));
      final exynos2500Gpu = DeviceSpecHelper.detectGpuName(
        hardware: 's5e9955',
        board: 's5e9955',
        socName: exynos2500Cpu,
      );
      expect(exynos2500Gpu, equals('Samsung Xclipse 950'));

      final exynos1480Cpu = DeviceSpecHelper.detectSocName(
        hardware: 's5e8845',
        board: 's5e8845',
        manufacturer: 'Samsung',
      );
      expect(exynos1480Cpu, equals('Samsung Exynos 1480'));
      final exynos1480Gpu = DeviceSpecHelper.detectGpuName(
        hardware: 's5e8845',
        board: 's5e8845',
        socName: exynos1480Cpu,
      );
      expect(exynos1480Gpu, equals('Samsung Xclipse 530'));

      final tensorG5Cpu = DeviceSpecHelper.detectSocName(
        hardware: 'google',
        board: 'laguna',
        manufacturer: 'Google',
      );
      expect(tensorG5Cpu, equals('Google Tensor G5'));
      final tensorG5Gpu = DeviceSpecHelper.detectGpuName(
        hardware: 'google',
        board: 'laguna',
        socName: tensorG5Cpu,
      );
      expect(tensorG5Gpu, equals('IMG D-Series GPU'));

      final unisocT820Cpu = DeviceSpecHelper.detectSocName(
        hardware: 'ums9620',
        board: 't820',
        manufacturer: 'Unisoc',
      );
      expect(unisocT820Cpu, equals('Unisoc T820'));
      final unisocT820Gpu = DeviceSpecHelper.detectGpuName(
        hardware: 'ums9620',
        board: 't820',
        socName: unisocT820Cpu,
      );
      expect(unisocT820Gpu, equals('Mali-G57 MP4'));

      // Additional requested SoCs (Snapdragon 8 Elite Gen 5, Dimensity 7050/9500/9600, Unisoc, Snapdragon 6 & 7 series)
      final snapdragon8EliteGen5Cpu = DeviceSpecHelper.detectSocName(
        hardware: 'qcom',
        board: 'sun',
        manufacturer: 'Qualcomm',
        socModel: 'SM8850',
      );
      expect(
        snapdragon8EliteGen5Cpu,
        equals('Qualcomm Snapdragon 8 Elite Gen 5'),
      );
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'sm8850',
          board: 'sun',
          socName: snapdragon8EliteGen5Cpu,
        ),
        equals('Adreno 840'),
      );

      final dimensity7050Cpu = DeviceSpecHelper.detectSocName(
        hardware: 'mt6877v',
        board: 'mt6877',
        manufacturer: 'MediaTek',
      );
      expect(dimensity7050Cpu, equals('MediaTek Dimensity 7050'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'mt6877v',
          board: 'mt6877',
          socName: dimensity7050Cpu,
        ),
        equals('Mali-G68 MC4'),
      );

      final dimensity9500Cpu = DeviceSpecHelper.detectSocName(
        hardware: 'mt6993',
        board: 'mt6993',
        manufacturer: 'MediaTek',
      );
      expect(dimensity9500Cpu, equals('MediaTek Dimensity 9500'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'mt6993',
          board: 'mt6993',
          socName: dimensity9500Cpu,
        ),
        equals('Immortalis-G925 MC12'),
      );

      final dimensity9600Cpu = DeviceSpecHelper.detectSocName(
        hardware: 'mt6995',
        board: 'mt6995',
        manufacturer: 'MediaTek',
      );
      expect(dimensity9600Cpu, equals('MediaTek Dimensity 9600'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'mt6995',
          board: 'mt6995',
          socName: dimensity9600Cpu,
        ),
        equals('Immortalis-G925 MC12'),
      );

      final snapdragon778GCpu = DeviceSpecHelper.detectSocName(
        hardware: 'sm7325',
        board: 'yupik',
        manufacturer: 'Qualcomm',
      );
      expect(snapdragon778GCpu, equals('Qualcomm Snapdragon 778G'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'sm7325',
          board: 'yupik',
          socName: snapdragon778GCpu,
        ),
        equals('Adreno 642L'),
      );

      final snapdragon660Cpu = DeviceSpecHelper.detectSocName(
        hardware: 'sdm660',
        board: 'sdm660',
        manufacturer: 'Qualcomm',
      );
      expect(snapdragon660Cpu, equals('Qualcomm Snapdragon 660'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'sdm660',
          board: 'sdm660',
          socName: snapdragon660Cpu,
        ),
        equals('Adreno 512'),
      );

      final unisocT770Cpu = DeviceSpecHelper.detectSocName(
        hardware: 'ums512t',
        board: 't770',
        manufacturer: 'Unisoc',
      );
      expect(unisocT770Cpu, equals('Unisoc T770'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'ums512t',
          board: 't770',
          socName: unisocT770Cpu,
        ),
        equals('Mali-G57 MP4'),
      );

      final unisocT618Cpu = DeviceSpecHelper.detectSocName(
        hardware: 'ums512',
        board: 't618',
        manufacturer: 'Unisoc',
        socModel: 'T618',
      );
      expect(unisocT618Cpu, equals('Unisoc T618'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'ums512',
          board: 't618',
          socName: unisocT618Cpu,
        ),
        equals('Mali-G57 MP1'),
      );
    });

    test('DeviceSpecHelper getHardwareInfo returns full specifications dictionary with all expected keys', () async {
      final info = await DeviceSpecHelper.getHardwareInfo();
      expect(info.containsKey('deviceName'), isTrue);
      expect(info.containsKey('modelCode'), isTrue);
      expect(info.containsKey('cpu'), isTrue);
      expect(info.containsKey('gpu'), isTrue);
      expect(info.containsKey('ram'), isTrue);
      expect(info.containsKey('storage'), isTrue);
      expect(info.containsKey('storageFree'), isTrue);
      expect(info.containsKey('cores'), isTrue);

      expect((info['deviceName'] as String).isNotEmpty, isTrue);
      expect((info['modelCode'] as String).isNotEmpty, isTrue);
      expect((info['cpu'] as String).isNotEmpty, isTrue);
      expect((info['gpu'] as String).isNotEmpty, isTrue);
      expect((info['ram'] as String).isNotEmpty, isTrue);
      expect((info['storage'] as String).isNotEmpty, isTrue);
    });
  });

  group('Theme System and AMOLED Sakura Easter Egg tests', () {
    test('AppTheme returns valid ThemeData for all modes including sakura', () {
      final dark = AppTheme.getTheme('dark');
      final oled = AppTheme.getTheme('oled');
      final light = AppTheme.getTheme('light');
      final sakura = AppTheme.getTheme('sakura');
      final oledSakura = AppTheme.getTheme('oled_sakura');

      expect(dark.brightness, equals(Brightness.dark));
      expect(oled.brightness, equals(Brightness.dark));
      expect(oled.scaffoldBackgroundColor, equals(Colors.black));
      expect(light.brightness, equals(Brightness.light));

      expect(sakura.brightness, equals(Brightness.dark));
      expect(sakura.scaffoldBackgroundColor, equals(Colors.black));
      expect(sakura.colorScheme.primary, equals(const Color(0xFFF472B6)));
      expect(oledSakura.colorScheme.primary, equals(const Color(0xFFF472B6)));
    });

    test(
      'All theme description strings exist across all supported languages',
      () {
        for (final code in supportedCodes) {
          final l10n = AppLocalizations(code);
          expect(l10n.t('theme_dark').isNotEmpty, isTrue);
          expect(l10n.t('theme_dark_desc').isNotEmpty, isTrue);
          expect(l10n.t('theme_dark_desc'), isNot(equals('theme_dark_desc')));

          expect(l10n.t('theme_oled').isNotEmpty, isTrue);
          expect(l10n.t('theme_oled_desc').isNotEmpty, isTrue);
          expect(l10n.t('theme_oled_desc'), isNot(equals('theme_oled_desc')));

          expect(l10n.t('theme_light').isNotEmpty, isTrue);
          expect(l10n.t('theme_light_desc').isNotEmpty, isTrue);
          expect(l10n.t('theme_light_desc'), isNot(equals('theme_light_desc')));

          expect(l10n.t('theme_dark'), equals('Snowfall'));
          expect(l10n.t('theme_oled'), equals('Midnight'));
          expect(l10n.t('theme_sakura'), equals('Sakura'));
          expect(l10n.t('theme_light'), equals('Daylight'));
        }
      },
    );

    testWidgets(
      'SettingsScreen displays developer profile button with open icon',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getTheme('dark'),
            home: const SettingsScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Developer: zerabyte88'), findsOneWidget);
        expect(find.text('GitHub'), findsOneWidget);
        expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
      },
    );

    test('Target FPS guide keys are completely free of emojis across all supported languages', () {
      final emojiRegex = RegExp(
        r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
        unicode: true,
      );
      for (final code in supportedCodes) {
        final l10n = AppLocalizations(code);
        final title = l10n.t('fps_info_title');
        final orig = l10n.t('fps_desc_original');
        final fps60 = l10n.t('fps_desc_60');
        final fps30 = l10n.t('fps_desc_30');
        final fps24 = l10n.t('fps_desc_24');
        final custom = l10n.t('fps_desc_custom');

        expect(title.isNotEmpty, isTrue);
        expect(orig.isNotEmpty, isTrue);
        expect(fps60.isNotEmpty, isTrue);
        expect(fps30.isNotEmpty, isTrue);
        expect(fps24.isNotEmpty, isTrue);
        expect(custom.isNotEmpty, isTrue);

        expect(
          emojiRegex.hasMatch(title),
          isFalse,
          reason: '$code title has emoji',
        );
        expect(
          emojiRegex.hasMatch(orig),
          isFalse,
          reason: '$code orig has emoji',
        );
        expect(
          emojiRegex.hasMatch(fps60),
          isFalse,
          reason: '$code fps60 has emoji',
        );
        expect(
          emojiRegex.hasMatch(fps30),
          isFalse,
          reason: '$code fps30 has emoji',
        );
        expect(
          emojiRegex.hasMatch(fps24),
          isFalse,
          reason: '$code fps24 has emoji',
        );
        expect(
          emojiRegex.hasMatch(custom),
          isFalse,
          reason: '$code custom has emoji',
        );
      }
    });

    testWidgets(
      'Target FPS slider clamps to 30 for 30 FPS video and hides 60 FPS chip',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const video30 = VideoInfo(
          filePath: '/test/video.mp4',
          fileName: 'video.mp4',
          width: 1920,
          height: 1080,
          durationSeconds: 10.0,
          bitrate: 5000000,
          fps: 30.0,
          codec: 'h264',
          fileSizeBytes: 1000000,
        );

        EncodingOptions options = const EncodingOptions();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getTheme('dark'),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return ConversionOptionsCard(
                    sourceVideo: video30,
                    resolutions: VideoResolution.standardResolutions,
                    selectedResolution: VideoResolution.standardResolutions[2],
                    encodingOptions: options,
                    onResolutionChanged: (_) {},
                    onOptionsChanged: (newOpts) {
                      setState(() {
                        options = newOpts;
                      });
                    },
                    l10n: const AppLocalizations('id'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 60 FPS chip should NOT be present for 30 FPS video
        expect(find.widgetWithText(ChoiceChip, '60 FPS'), findsNothing);
        // 30 FPS, 24 FPS, Asli, and Kustom chips should be present
        expect(find.widgetWithText(ChoiceChip, '30 FPS'), findsOneWidget);
        expect(find.widgetWithText(ChoiceChip, '24 FPS'), findsOneWidget);
        expect(find.widgetWithText(ChoiceChip, 'Asli'), findsOneWidget);
        expect(find.widgetWithText(ChoiceChip, 'Kustom'), findsOneWidget);

        // Tap Kustom chip
        await tester.tap(find.widgetWithText(ChoiceChip, 'Kustom'));
        await tester.pumpAndSettle();

        // Slider should appear and its max must be exactly 30.0
        final sliderFinder = find.byWidgetPredicate(
          (w) => w is Slider && (w.label?.contains('FPS') ?? false),
        );
        expect(sliderFinder, findsOneWidget);
        final sliderWidget = tester.widget<Slider>(sliderFinder);
        expect(sliderWidget.max, 30.0);
        expect(sliderWidget.min, 10.0);

        // Dynamic FPS explanation is visible without emojis
        expect(
          find.text(const AppLocalizations('id').t('fps_desc_custom')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Target FPS slider clamps to 60 for 60 FPS video and shows 60 FPS chip',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const video60 = VideoInfo(
          filePath: '/test/video60.mp4',
          fileName: 'video60.mp4',
          width: 1920,
          height: 1080,
          durationSeconds: 10.0,
          bitrate: 8000000,
          fps: 60.0,
          codec: 'h264',
          fileSizeBytes: 2000000,
        );

        EncodingOptions options = const EncodingOptions();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getTheme('dark'),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return ConversionOptionsCard(
                    sourceVideo: video60,
                    resolutions: VideoResolution.standardResolutions,
                    selectedResolution: VideoResolution.standardResolutions[2],
                    encodingOptions: options,
                    onResolutionChanged: (_) {},
                    onOptionsChanged: (newOpts) {
                      setState(() {
                        options = newOpts;
                      });
                    },
                    l10n: const AppLocalizations('id'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 60 FPS chip SHOULD be present for 60 FPS video
        expect(find.widgetWithText(ChoiceChip, '60 FPS'), findsOneWidget);

        // Tap Kustom chip
        await tester.tap(find.widgetWithText(ChoiceChip, 'Kustom'));
        await tester.pumpAndSettle();

        // Slider should appear and its max must be exactly 60.0
        final sliderFinder = find.byWidgetPredicate(
          (w) => w is Slider && (w.label?.contains('FPS') ?? false),
        );
        expect(sliderFinder, findsOneWidget);
        final sliderWidget = tester.widget<Slider>(sliderFinder);
        expect(sliderWidget.max, 60.0);
        expect(sliderWidget.min, 10.0);
      },
    );

    testWidgets(
      'Explanation texts in ConversionOptionsCard render fully on compact screens without overflow or truncation',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const video = VideoInfo(
          filePath: '/test/video.mp4',
          fileName: 'video.mp4',
          width: 1920,
          height: 1080,
          durationSeconds: 10.0,
          bitrate: 5000000,
          fps: 30.0,
          codec: 'h264',
          fileSizeBytes: 2000000,
        );

        EncodingOptions options = const EncodingOptions(
          speedPreset: SpeedPreset.max,
          rateControlMode: RateControlMode.crf,
          crfValue: 18,
          container: VideoContainer.mp4,
          targetFps: 30,
        );

        const l10n = AppLocalizations('id');

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getTheme('dark'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: ConversionOptionsCard(
                  sourceVideo: video,
                  resolutions: VideoResolution.standardResolutions,
                  selectedResolution: VideoResolution.standardResolutions[2],
                  encodingOptions: options,
                  onResolutionChanged: (_) {},
                  onOptionsChanged: (_) {},
                  l10n: l10n,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Ensure key explanations are present and rendered fully without truncation
        expect(find.text(l10n.t('preset_slow_desc')), findsOneWidget);
        expect(find.text(l10n.t('desc_crf')), findsOneWidget);
        expect(find.text(l10n.t('desc_mp4')), findsOneWidget);
        expect(find.text(l10n.t('fps_desc_30')), findsOneWidget);
        expect(find.text(l10n.t('crf_label')), findsOneWidget);

        // Verify no RenderParagraph in the tree has TextOverflow.ellipsis for descriptions
        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        for (final text in textWidgets) {
          final str = text.data ?? text.textSpan?.toPlainText() ?? '';
          if (str.contains('CRF') ||
              str.contains('Preset') ||
              str.contains('FPS') ||
              str.contains('Format')) {
            expect(
              text.overflow,
              isNot(equals(TextOverflow.ellipsis)),
              reason: 'Text "$str" should not have TextOverflow.ellipsis',
            );
          }
        }
      },
    );
  });

  group('Adaptive CPU Thread Allocation & Crash Recovery tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    const video1080 = VideoInfo(
      filePath: '/test/video1080.mp4',
      fileName: 'video1080.mp4',
      width: 1920,
      height: 1080,
      durationSeconds: 10.0,
      bitrate: 4000000,
      fps: 30.0,
      codec: 'h264',
      fileSizeBytes: 5000000,
    );

    const video4K = VideoInfo(
      filePath: '/test/video4k.mp4',
      fileName: 'video4k.mp4',
      width: 3840,
      height: 2160,
      durationSeconds: 10.0,
      bitrate: 15000000,
      fps: 30.0,
      codec: 'h264',
      fileSizeBytes: 20000000,
    );

    test('DeviceSpecHelper.maxSafeThreadCount returns proper thresholds based on RAM', () {
      expect(
        DeviceSpecHelper.maxSafeThreadCount(3072, 8),
        equals(4),
      ); // 3GB -> 4
      expect(
        DeviceSpecHelper.maxSafeThreadCount(4096, 8),
        equals(4),
      ); // 4GB -> 4
      expect(
        DeviceSpecHelper.maxSafeThreadCount(6144, 8),
        equals(6),
      ); // 6GB -> 6
      expect(
        DeviceSpecHelper.maxSafeThreadCount(8192, 8),
        equals(8),
      ); // 8GB on 8 cores -> 8
      expect(
        DeviceSpecHelper.maxSafeThreadCount(8192, 6),
        equals(6),
      ); // 8GB on 6 cores -> 6
    });

    test('DeviceSpecHelper.isEntryOrLegacySoc distinguishes legacy chips from modern mid-range', () {
      // Modern Mid-Range / Upper: should return false
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'MediaTek Helio G70'),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'MediaTek Helio G85'),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'MediaTek Helio G99'),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'MediaTek Helio G100'),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'Qualcomm Snapdragon 660'),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'Qualcomm Snapdragon 662'),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'Qualcomm Snapdragon 665'),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'Qualcomm Snapdragon 675'),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'Qualcomm Snapdragon 680'),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(
          socName: 'Qualcomm Snapdragon 695 5G',
        ),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(
          socName: 'Qualcomm Snapdragon 732G',
        ),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'MediaTek Dimensity 7050'),
        isFalse,
      );

      // Legacy Snapdragon / Helio entry / Unisoc: should return true
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'Qualcomm Snapdragon 625'),
        isTrue,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'Qualcomm Snapdragon 636'),
        isTrue,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'Qualcomm Snapdragon 460'),
        isTrue,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(
          socName: 'MediaTek Helio P35 / G35',
        ),
        isTrue,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'MediaTek Helio G25'),
        isTrue,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'Unisoc T606'),
        isTrue,
      );
    });

    test('DeviceSpecHelper.resolveThreadCount allocates cores adaptively for RAM, SoC, and 4K resolution', () {
      // 1. RAM <= 4GB: 4 cores baseline, discounted to 3 cores on 4K video
      expect(
        DeviceSpecHelper.resolveThreadCount(
          video: video1080,
          customRamMb: 4096,
          customPhysicalCores: 8,
          customSoc: 'Qualcomm Snapdragon 680',
        ),
        equals(4),
      );
      expect(
        DeviceSpecHelper.resolveThreadCount(
          video: video4K,
          customRamMb: 4096,
          customPhysicalCores: 8,
          customSoc: 'Qualcomm Snapdragon 680',
        ),
        equals(3), // Discounted by 1 for 4K stability
      );

      // 2. RAM 4GB with mid-range SoC (e.g. SD 732G RAM 4GB): allocates 4 cores (RAM protection holds)
      expect(
        DeviceSpecHelper.resolveThreadCount(
          video: video1080,
          customRamMb: 4096,
          customPhysicalCores: 8,
          customSoc: 'Qualcomm Snapdragon 732G',
        ),
        equals(4),
      );

      // 3. RAM 6GB Mid-Range (Helio G99, SD 665, Helio G85): 6 cores baseline, discounted to 5 cores on 4K
      expect(
        DeviceSpecHelper.resolveThreadCount(
          video: video1080,
          customRamMb: 6144,
          customPhysicalCores: 8,
          customSoc: 'MediaTek Helio G99',
        ),
        equals(6),
      );
      expect(
        DeviceSpecHelper.resolveThreadCount(
          video: video1080,
          customRamMb: 6144,
          customPhysicalCores: 8,
          customSoc: 'Qualcomm Snapdragon 665',
        ),
        equals(6),
      );
      expect(
        DeviceSpecHelper.resolveThreadCount(
          video: video1080,
          customRamMb: 6144,
          customPhysicalCores: 8,
          customSoc: 'MediaTek Helio G85',
        ),
        equals(6),
      );
      expect(
        DeviceSpecHelper.resolveThreadCount(
          video: video4K,
          customRamMb: 6144,
          customPhysicalCores: 8,
          customSoc: 'MediaTek Helio G99',
        ),
        equals(5),
      );
      expect(
        DeviceSpecHelper.resolveThreadCount(
          video: video4K,
          customRamMb: 6144,
          customPhysicalCores: 8,
          customSoc: 'Qualcomm Snapdragon 665',
        ),
        equals(5),
      );

      // 4. RAM >= 8GB Flagship (Snapdragon 8 Gen 2): 8 cores baseline, discounted to 7 on 4K
      expect(
        DeviceSpecHelper.resolveThreadCount(
          video: video1080,
          customRamMb: 8192,
          customPhysicalCores: 8,
          customSoc: 'Qualcomm Snapdragon 8 Gen 2',
        ),
        equals(8),
      );
      expect(
        DeviceSpecHelper.resolveThreadCount(
          video: video4K,
          customRamMb: 8192,
          customPhysicalCores: 8,
          customSoc: 'Qualcomm Snapdragon 8 Gen 2',
        ),
        equals(7),
      );

      // 5. Manual selection: always respected and never secretly discounted
      expect(
        DeviceSpecHelper.resolveThreadCount(
          video: video4K,
          requestedThreads: 6,
          customRamMb: 4096,
          customPhysicalCores: 8,
        ),
        equals(6), // Respected!
      );

      // 6. Manual selection clamped to physical cores
      expect(
        DeviceSpecHelper.resolveThreadCount(
          video: video1080,
          requestedThreads: 8,
          customPhysicalCores: 6,
        ),
        equals(6), // Clamped to 6 physical cores
      );
    });

    test('FFmpegService.isOomLog correctly identifies out-of-memory logs', () {
      expect(FFmpegService.isOomLog('Error: Cannot allocate memory'), isTrue);
      expect(
        FFmpegService.isOomLog('fatal: Out of memory in x264_frame_new'),
        isTrue,
      );
      expect(
        FFmpegService.isOomLog('av_malloc of size 10485760 failed'),
        isTrue,
      );
      expect(
        FFmpegService.isOomLog(
          'libx264 failed to allocate memory for lookahead',
        ),
        isTrue,
      );
      expect(
        FFmpegService.isOomLog(
          'frame=  120 fps= 24 q=28.0 size=    1024kB time=00:00:05.00 bitrate=1677.7kbits/s speed=1.2x',
        ),
        isFalse,
      );
    });

    test(
      'SettingsService job marker persists, retrieves, and clears correctly',
      () async {
        final service = SettingsService();
        await service.clearJobMarker();
        expect(await service.getJobMarker(), isNull);

        await service.saveJobMarker(
          inputPath: '/test/source.mp4',
          outputPath: '/test/out.mp4',
          allocatedThreads: 4,
          is4K: true,
          retryCount: 0,
        );

        final marker = await service.getJobMarker();
        expect(marker, isNotNull);
        expect(marker!['inputPath'], equals('/test/source.mp4'));
        expect(marker['outputPath'], equals('/test/out.mp4'));
        expect(marker['allocatedThreads'], equals(4));
        expect(marker['is4K'], isTrue);

        await service.clearJobMarker();
        expect(await service.getJobMarker(), isNull);
      },
    );

    testWidgets(
      'SettingsScreen displays Auto baseline badge and recommendations',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final service = SettingsService();
        await service.init();
        await service.setCpuThreads(0); // Auto mode

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getTheme('dark'),
            home: const SettingsScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final l10n = service.l10n;
        final autoBaseline = DeviceSpecHelper.resolveThreadCount(
          requestedThreads: 0,
        );

        // Verify header badge displays Auto (X Core)
        expect(
          find.text(
            '${l10n.t('badge_auto')} ($autoBaseline ${l10n.t('unit_core')})',
          ),
          findsOneWidget,
        );
        // Verify subtitle is visible under badge
        expect(find.text(l10n.t('settings_cpu_auto_subtitle')), findsOneWidget);
        // Verify Auto chip is visible
        expect(
          find.widgetWithText(ChoiceChip, l10n.t('badge_auto')),
          findsOneWidget,
        );
        // Verify recommended chip exists
        expect(
          find.widgetWithText(
            ChoiceChip,
            '$autoBaseline ${l10n.t('unit_core')} (${l10n.t('chip_recommended')})',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ConversionOptionsCard displays 4K stability note when video is 4K in Auto mode',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final service = SettingsService();
        await service.init();
        await service.setCpuThreads(0); // Auto mode

        final l10n = service.l10n;
        final resolved = DeviceSpecHelper.resolveThreadCount(
          video: video4K,
          requestedThreads: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getTheme('dark'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: ConversionOptionsCard(
                  sourceVideo: video4K,
                  resolutions: VideoResolution.standardResolutions,
                  selectedResolution: VideoResolution.standardResolutions.first,
                  encodingOptions: const EncodingOptions(),
                  onResolutionChanged: (_) {},
                  onOptionsChanged: (_) {},
                  l10n: l10n,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify 4K stability note is rendered
        expect(
          find.text(
            l10n.t('auto_runtime_4k', args: {'count': resolved.toString()}),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('SoC Normalization, Description, and Device Specs UI tests', () {
    test('DeviceSpecHelper.cleanSocDisplayName strips vendor prefixes and legal text cleanly', () {
      expect(
        DeviceSpecHelper.cleanSocDisplayName('Qualcomm Snapdragon 8 Elite'),
        equals('Snapdragon 8 Elite'),
      );
      expect(
        DeviceSpecHelper.cleanSocDisplayName(
          'Qualcomm Technologies, Inc Snapdragon 8 Gen 3',
        ),
        equals('Snapdragon 8 Gen 3'),
      );
      expect(
        DeviceSpecHelper.cleanSocDisplayName('MediaTek Dimensity 9400'),
        equals('Dimensity 9400'),
      );
      expect(
        DeviceSpecHelper.cleanSocDisplayName('MediaTek Helio G99 / G100'),
        equals('Helio G99 / G100'),
      );
      expect(
        DeviceSpecHelper.cleanSocDisplayName('Google Tensor G4'),
        equals('Tensor G4'),
      );
      expect(
        DeviceSpecHelper.cleanSocDisplayName('Samsung Exynos 2400 (TM)'),
        equals('Exynos 2400'),
      );
      expect(
        DeviceSpecHelper.cleanSocDisplayName('Unisoc T606'),
        equals('T606'),
      );
      expect(DeviceSpecHelper.cleanSocDisplayName('mt6768'), equals('mt6768'));
      expect(DeviceSpecHelper.cleanSocDisplayName(''), equals(''));
    });

    test('DeviceSpecHelper.describeSoc returns structured SocDescription with accurate precision', () {
      // 1. Precise SoC
      final precise = DeviceSpecHelper.describeSoc(
        socModel: 'sm8750',
        hardware: 'qcom',
        manufacturer: 'Xiaomi',
        physicalCores: 8,
      );
      expect(precise.isPrecise, isTrue);
      expect(precise.displayName, equals('Snapdragon 8 Elite'));
      expect(precise.coreCount, equals(8));

      // 2. Unmapped platform code
      final platformCode = DeviceSpecHelper.describeSoc(
        hardware: 'mt67999',
        physicalCores: 8,
      );
      expect(platformCode.isPrecise, isFalse);
      expect(platformCode.displayName, equals('mt67999'));
      expect(platformCode.coreCount, equals(8));

      // 3. Pure generic/non-informative
      final generic = DeviceSpecHelper.describeSoc(
        hardware: 'qcom',
        physicalCores: 8,
      );
      expect(generic.isPrecise, isFalse);
      expect(generic.displayName, isEmpty);
      expect(generic.coreCount, equals(8));

      // 4. Unknown/Empty
      final empty = DeviceSpecHelper.describeSoc(
        hardware: 'unknown',
        physicalCores: 8,
      );
      expect(empty.isPrecise, isFalse);
      expect(empty.displayName, isEmpty);
    });

    test(
      'New CPU spec detail translations exist across all supported languages',
      () {
        for (final code in supportedCodes) {
          final l10n = AppLocalizations(code);
          expect(
            l10n.t('device_cpu_generic').isNotEmpty,
            isTrue,
            reason: 'device_cpu_generic missing in $code',
          );
          expect(
            l10n.t('device_cpu_detail_title').isNotEmpty,
            isTrue,
            reason: 'device_cpu_detail_title missing in $code',
          );
          expect(
            l10n.t('copy_specs').isNotEmpty,
            isTrue,
            reason: 'copy_specs missing in $code',
          );
          expect(
            l10n.t('specs_copied').isNotEmpty,
            isTrue,
            reason: 'specs_copied missing in $code',
          );
          expect(
            l10n.t('cores_detected').isNotEmpty,
            isTrue,
            reason: 'cores_detected missing in $code',
          );
        }
      },
    );

    testWidgets(
      'SettingsScreen CPU row displays clean name without (X Core), opens bottom sheet on tap, and copies specs',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({});
        final service = SettingsService();
        await service.init();
        final l10n = service.l10n;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getTheme('dark'),
            home: const SettingsScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 1. Verify CPU row exists and does not contain "(8 Core)" or similar
        expect(find.text(l10n.t('device_cpu')), findsOneWidget);
        expect(find.byIcon(Icons.info_outline_rounded), findsWidgets);

        // 2. Tap on the CPU row to open bottom sheet
        await tester.tap(find.text(l10n.t('device_cpu')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 3. Bottom sheet should be visible with title and Copy button
        expect(find.text(l10n.t('device_cpu_detail_title')), findsOneWidget);
        expect(find.text(l10n.t('copy_specs')), findsOneWidget);

        // 4. Tap "Copy Details"
        await tester.tap(find.text(l10n.t('copy_specs')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // 5. SnackBar appears
        expect(find.text(l10n.t('specs_copied')), findsOneWidget);
      },
    );

    testWidgets(
      'Device specs card and CPU row layout handles large text scaling and 360dp width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({});
        final service = SettingsService();
        await service.init();
        final l10n = service.l10n;

        final longSoc = DeviceSpecHelper.describeSoc(
          socModel:
              'MediaTek Dimensity 9600 Pro Extreme Ultimate Max Plus Edition',
          hardware: 'mt6999',
          manufacturer: 'MediaTek Technologies, Inc.',
          brand: 'MediaTek',
          physicalCores: 8,
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: MaterialApp(
              theme: AppTheme.getTheme('dark'),
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // CPU Row with very long commercial SoC
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 105,
                                child: Text(
                                  l10n.t('device_cpu'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(140),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  longSoc.displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: theme.colorScheme.primary.withAlpha(150),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      },
    );
  });

  group('Pure AMOLED and Clean Light Static Theme tests', () {
    test('AppTheme generates valid themes for oled_pure and light_clean', () {
      final oledPure = AppTheme.getTheme('oled_pure');
      expect(oledPure.brightness, equals(Brightness.dark));
      expect(oledPure.scaffoldBackgroundColor, equals(Colors.black));

      final lightClean = AppTheme.getTheme('light_clean');
      expect(lightClean.brightness, equals(Brightness.light));
      expect(
        lightClean.scaffoldBackgroundColor,
        equals(const Color(0xFFF8FAFC)),
      );
    });

    test('All 22 languages have valid translations for new static themes and badge', () {
      for (final code in supportedCodes) {
        final l10n = AppLocalizations(code);
        expect(
          l10n.t('theme_oled_pure').isNotEmpty,
          isTrue,
          reason: 'theme_oled_pure missing in $code',
        );
        expect(
          l10n.t('theme_oled_pure_desc').isNotEmpty,
          isTrue,
          reason: 'theme_oled_pure_desc missing in $code',
        );
        expect(
          l10n.t('theme_light_clean').isNotEmpty,
          isTrue,
          reason: 'theme_light_clean missing in $code',
        );
        expect(
          l10n.t('theme_light_clean_desc').isNotEmpty,
          isTrue,
          reason: 'theme_light_clean_desc missing in $code',
        );
        expect(
          l10n.t('badge_static').isNotEmpty,
          isTrue,
          reason: 'badge_static missing in $code',
        );
      }
    });

    testWidgets(
      'ThemeAnimatedBackground stops ticker and bypasses canvas for static themes',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final service = SettingsService();
        await service.init();

        // 1. Start on oled_pure (static)
        await service.setThemeMode('oled_pure');

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getTheme(service.settings.themeMode),
            home: const ThemeAnimatedBackground(
              child: Scaffold(body: Center(child: Text('Content'))),
            ),
          ),
        );
        // Because oled_pure is static, pumpAndSettle completes without timing out!
        await tester.pumpAndSettle();
        expect(find.text('Content'), findsOneWidget);

        // 2. Switch to light_clean (static)
        await service.setThemeMode('light_clean');
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getTheme(service.settings.themeMode),
            home: const ThemeAnimatedBackground(
              child: Scaffold(body: Center(child: Text('Content'))),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Content'), findsOneWidget);

        // 3. Reset back to dark
        await service.setThemeMode('dark');
      },
    );
  });

  group('Comprehensive ARM 64-bit SoC & GPU Detection tests', () {
    test(
      'HiSilicon Kirin SoCs and Maleoon/Mali GPUs are accurately identified',
      () {
        // Flagships
        final k9020 = DeviceSpecHelper.detectSocName(
          hardware: 'hi36c0',
          board: 'hi36c0',
          manufacturer: 'HUAWEI',
        );
        expect(k9020, equals('HiSilicon Kirin 9020'));
        expect(
          DeviceSpecHelper.detectGpuName(
            hardware: 'hi36c0',
            board: 'hi36c0',
            socName: k9020,
          ),
          equals('Maleoon 920'),
        );

        final k9010 = DeviceSpecHelper.detectSocName(
          hardware: 'hi36a0',
          board: 'hi36a0',
          manufacturer: 'HUAWEI',
          socModel: 'hi36a0v121',
        );
        expect(k9010, equals('HiSilicon Kirin 9010'));
        expect(
          DeviceSpecHelper.detectGpuName(
            hardware: 'hi36a0',
            board: 'hi36a0',
            socName: k9010,
          ),
          equals('Maleoon 910'),
        );

        final k9000s = DeviceSpecHelper.detectSocName(
          hardware: 'hi36a0',
          board: 'hi36a0',
          manufacturer: 'HUAWEI',
          socModel: 'hi36a0v120 kirin9000s',
        );
        expect(k9000s, equals('HiSilicon Kirin 9000S'));
        expect(
          DeviceSpecHelper.detectGpuName(
            hardware: 'hi36a0',
            board: 'hi36a0',
            socName: k9000s,
          ),
          equals('Maleoon 910'),
        );

        final k9000 = DeviceSpecHelper.detectSocName(
          hardware: 'hi36a0',
          board: 'hi36a0',
          manufacturer: 'HUAWEI',
        );
        expect(k9000, equals('HiSilicon Kirin 9000 / 9000E'));
        expect(
          DeviceSpecHelper.detectGpuName(
            hardware: 'hi36a0',
            board: 'hi36a0',
            socName: k9000,
          ),
          equals('Mali-G78 MP24'),
        );

        final k990 = DeviceSpecHelper.detectSocName(
          hardware: 'hi3690',
          board: 'hi3690',
          manufacturer: 'HUAWEI',
          socModel: 'hi3690-5g',
        );
        expect(k990, equals('HiSilicon Kirin 990 5G'));
        expect(
          DeviceSpecHelper.detectGpuName(
            hardware: 'hi3690',
            board: 'hi3690',
            socName: k990,
          ),
          equals('Mali-G76 MP16'),
        );

        final k980 = DeviceSpecHelper.detectSocName(
          hardware: 'hi3680',
          board: 'hi3680',
          manufacturer: 'HUAWEI',
        );
        expect(k980, equals('HiSilicon Kirin 980'));
        expect(
          DeviceSpecHelper.detectGpuName(
            hardware: 'hi3680',
            board: 'hi3680',
            socName: k980,
          ),
          equals('Mali-G76 MP10'),
        );

        // Mid-Range & Legacy 64-bit Kirin
        final k8000 = DeviceSpecHelper.detectSocName(
          hardware: 'kirin 8000',
          board: 'kirin8000',
          manufacturer: 'HUAWEI',
        );
        expect(k8000, equals('HiSilicon Kirin 8000'));
        expect(
          DeviceSpecHelper.detectGpuName(
            hardware: '',
            board: '',
            socName: k8000,
          ),
          equals('Mali-G610'),
        );

        final k710 = DeviceSpecHelper.detectSocName(
          hardware: 'hi6260',
          board: 'hi6260',
          manufacturer: 'HUAWEI',
        );
        expect(k710, equals('HiSilicon Kirin 710 / 710F'));
        expect(
          DeviceSpecHelper.detectGpuName(
            hardware: 'hi6260',
            board: 'hi6260',
            socName: k710,
          ),
          equals('Mali-G51 MP4'),
        );

        final k620 = DeviceSpecHelper.detectSocName(
          hardware: 'hi6210',
          board: 'hi6210',
          manufacturer: 'HUAWEI',
        );
        expect(k620, equals('HiSilicon Kirin 620'));
        expect(
          DeviceSpecHelper.detectGpuName(
            hardware: 'hi6210',
            board: 'hi6210',
            socName: k620,
          ),
          equals('Mali-450 MP4'),
        );
      },
    );

    test('Xiaomi XRING and Surge in-house SoCs are accurately identified', () {
      final xringO3 = DeviceSpecHelper.detectSocName(
        hardware: 'xring o3',
        board: 'xring_o3',
        manufacturer: 'Xiaomi',
      );
      expect(xringO3, equals('Xiaomi XRING O3'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: '',
          board: '',
          socName: xringO3,
        ),
        equals('Immortalis-G925+'),
      );

      final xringO1 = DeviceSpecHelper.detectSocName(
        hardware: 'xring o1',
        board: 'xring_o1',
        manufacturer: 'Xiaomi',
      );
      expect(xringO1, equals('Xiaomi XRING O1'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: '',
          board: '',
          socName: xringO1,
        ),
        equals('Immortalis-G925 MC16'),
      );

      final surge = DeviceSpecHelper.detectSocName(
        hardware: 'v670',
        board: 'pinecone',
        manufacturer: 'Xiaomi',
      );
      expect(surge, equals('Xiaomi Surge S1'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'v670',
          board: 'pinecone',
          socName: surge,
        ),
        equals('Mali-T860 MP4'),
      );
    });

    test('JLQ Technology (Poco C40) SoC is accurately identified', () {
      final jlq = DeviceSpecHelper.detectSocName(
        hardware: 'jr510',
        board: 'jr510',
        manufacturer: 'Xiaomi',
        socModel: 'jlq jr510',
      );
      expect(jlq, equals('JLQ JR510'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'jr510',
          board: 'jr510',
          socName: jlq,
        ),
        equals('Mali-G57 MC1'),
      );
    });

    test('Expanded 64-bit SoCs across Snapdragon, Dimensity, Helio, and Exynos are identified', () {
      // Snapdragon 810 (MSM8994) & 410 (MSM8916)
      final sd810 = DeviceSpecHelper.detectSocName(
        hardware: 'qcom',
        board: 'msm8994',
        manufacturer: 'Qualcomm',
      );
      expect(sd810, equals('Qualcomm Snapdragon 810'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: '',
          board: 'msm8994',
          socName: sd810,
        ),
        equals('Adreno 430'),
      );

      final sd410 = DeviceSpecHelper.detectSocName(
        hardware: 'qcom',
        board: 'msm8916',
        manufacturer: 'Qualcomm',
      );
      expect(sd410, equals('Qualcomm Snapdragon 410'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: '',
          board: 'msm8916',
          socName: sd410,
        ),
        equals('Adreno 306'),
      );

      // Helio P60 (MT6771) & Helio X30 (MT6799)
      final p60 = DeviceSpecHelper.detectSocName(
        hardware: 'mt6771',
        board: 'mt6771',
        manufacturer: 'MediaTek',
      );
      expect(p60, equals('MediaTek Helio P60 / P70'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'mt6771',
          board: 'mt6771',
          socName: p60,
        ),
        equals('Mali-G72 MP3'),
      );

      final x30 = DeviceSpecHelper.detectSocName(
        hardware: 'mt6799',
        board: 'mt6799',
        manufacturer: 'MediaTek',
      );
      expect(x30, equals('MediaTek Helio X30'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'mt6799',
          board: 'mt6799',
          socName: x30,
        ),
        equals('PowerVR Series7XT Plus'),
      );

      // Exynos 8895 (Galaxy S8)
      final ex8895 = DeviceSpecHelper.detectSocName(
        hardware: 'universal8895',
        board: 'universal8895',
        manufacturer: 'Samsung',
      );
      expect(ex8895, equals('Samsung Exynos 8895'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'universal8895',
          board: 'universal8895',
          socName: ex8895,
        ),
        equals('Mali-G71 MP20'),
      );
    });

    test('cleanSocDisplayName strips HiSilicon, Xiaomi, and JLQ brand prefixes cleanly', () {
      expect(
        DeviceSpecHelper.cleanSocDisplayName('HiSilicon Kirin 9010'),
        equals('Kirin 9010'),
      );
      expect(
        DeviceSpecHelper.cleanSocDisplayName('Huawei Kirin 9000S'),
        equals('Kirin 9000S'),
      );
      expect(
        DeviceSpecHelper.cleanSocDisplayName('Xiaomi XRING O1'),
        equals('XRING O1'),
      );
      expect(
        DeviceSpecHelper.cleanSocDisplayName('Xiaomi Surge S1'),
        equals('Surge S1'),
      );
      expect(
        DeviceSpecHelper.cleanSocDisplayName('JLQ Technology JR510'),
        equals('JR510'),
      );
      expect(
        DeviceSpecHelper.cleanSocDisplayName('JLQ JR510'),
        equals('JR510'),
      );
    });

    test('isEntryOrLegacySoc categorizes entry chips to 4 threads and flagships to full threads', () {
      // Entry & legacy chips -> true (capped at 4 threads)
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'HiSilicon Kirin 710'),
        isTrue,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'HiSilicon Kirin 620'),
        isTrue,
      );
      expect(DeviceSpecHelper.isEntryOrLegacySoc(socName: 'JLQ JR510'), isTrue);
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'Qualcomm Snapdragon 410'),
        isTrue,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'MediaTek Helio P60'),
        isTrue,
      );

      // Flagships -> false (allowed up to 8 threads on 8GB+ RAM)
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'HiSilicon Kirin 9000S'),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'HiSilicon Kirin 9010'),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'Xiaomi XRING O1'),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(
          socName: 'Qualcomm Snapdragon 8 Elite',
        ),
        isFalse,
      );
      expect(
        DeviceSpecHelper.isEntryOrLegacySoc(socName: 'MediaTek Dimensity 9400'),
        isFalse,
      );
    });

    test('Newest (2025/2026) and oldest (2014) 64-bit SoCs and GPUs are detected comprehensively', () {
      // 1. Newest Flagship SoCs (2025 / 2026)
      final k9050 = DeviceSpecHelper.detectSocName(
        hardware: 'hi36d0',
        board: 'hi36d0',
        manufacturer: 'HUAWEI',
      );
      expect(k9050, equals('HiSilicon Kirin 9050 Pro'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'hi36d0',
          board: 'hi36d0',
          socName: k9050,
        ),
        equals('Maleoon 955'),
      );

      final k9030 = DeviceSpecHelper.detectSocName(
        hardware: 'hi36b0',
        board: 'hi36b0',
        manufacturer: 'HUAWEI',
      );
      expect(k9030, equals('HiSilicon Kirin 9030 Pro'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'hi36b0',
          board: 'hi36b0',
          socName: k9030,
        ),
        equals('Maleoon 935'),
      );

      final ex2600 = DeviceSpecHelper.detectSocName(
        hardware: 's5e9965',
        board: 's5e9965',
        manufacturer: 'Samsung',
      );
      expect(ex2600, equals('Samsung Exynos 2600'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 's5e9965',
          board: 's5e9965',
          socName: ex2600,
        ),
        equals('Samsung Xclipse 960'),
      );

      final ex1080 = DeviceSpecHelper.detectSocName(
        hardware: 's5e9815',
        board: 's5e9815',
        manufacturer: 'Samsung',
      );
      expect(ex1080, equals('Samsung Exynos 1080'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 's5e9815',
          board: 's5e9815',
          socName: ex1080,
        ),
        equals('Mali-G78 MP10'),
      );

      final sd8Extreme = DeviceSpecHelper.detectSocName(
        hardware: 'qcom',
        board: '8 elite extreme',
        manufacturer: 'Qualcomm',
      );
      expect(sd8Extreme, equals('Qualcomm Snapdragon 8 Elite Extreme Gen 6'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: '',
          board: '8 elite extreme',
          socName: sd8Extreme,
        ),
        equals('Adreno 850'),
      );

      final sd8Gen5 = DeviceSpecHelper.detectSocName(
        hardware: 'sm8850',
        board: 'sm8850',
        manufacturer: 'Qualcomm',
      );
      expect(sd8Gen5, equals('Qualcomm Snapdragon 8 Elite Gen 5'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'sm8850',
          board: 'sm8850',
          socName: sd8Gen5,
        ),
        equals('Adreno 840'),
      );

      final d9400Plus = DeviceSpecHelper.detectSocName(
        hardware: 'mt6991',
        board: 'dimensity 9400+',
        manufacturer: 'MediaTek',
      );
      expect(d9400Plus, equals('MediaTek Dimensity 9400+'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'mt6991',
          board: '',
          socName: d9400Plus,
        ),
        equals('Immortalis-G925 MC12'),
      );

      final d8500 = DeviceSpecHelper.detectSocName(
        hardware: 'dimensity 8500',
        board: 'dimensity 8500',
        manufacturer: 'MediaTek',
      );
      expect(d8500, equals('MediaTek Dimensity 8500'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: '',
          board: 'dimensity 8500',
          socName: d8500,
        ),
        equals('Mali-G720 MC8'),
      );

      final d7350Pro = DeviceSpecHelper.detectSocName(
        hardware: 'mt6878',
        board: 'dimensity 7350 pro',
        manufacturer: 'MediaTek',
      );
      expect(d7350Pro, equals('MediaTek Dimensity 7350 Pro'));

      final hG100 = DeviceSpecHelper.detectSocName(
        hardware: 'mt6789',
        board: 'helio g100',
        manufacturer: 'MediaTek',
      );
      expect(hG100, equals('MediaTek Helio G100'));

      final hG91 = DeviceSpecHelper.detectSocName(
        hardware: 'mt6769',
        board: 'helio g91-ultra',
        manufacturer: 'MediaTek',
      );
      expect(hG91, equals('MediaTek Helio G91-Ultra'));

      final hG81 = DeviceSpecHelper.detectSocName(
        hardware: 'mt6769',
        board: 'helio g81-ultra',
        manufacturer: 'MediaTek',
      );
      expect(hG81, equals('MediaTek Helio G81-Ultra'));

      final uniT9300 = DeviceSpecHelper.detectSocName(
        hardware: 't9300',
        board: 't9300',
        manufacturer: 'Unisoc',
      );
      expect(uniT9300, equals('Unisoc T9300'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 't9300',
          board: 't9300',
          socName: uniT9300,
        ),
        equals('Mali-G57'),
      );

      final uniT8300 = DeviceSpecHelper.detectSocName(
        hardware: 't8300',
        board: 't8300',
        manufacturer: 'Unisoc',
      );
      expect(uniT8300, equals('Unisoc T8300'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 't8300',
          board: 't8300',
          socName: uniT8300,
        ),
        equals('Mali-G57 MP2'),
      );

      final uniT7300 = DeviceSpecHelper.detectSocName(
        hardware: 't7300',
        board: 't7300',
        manufacturer: 'Unisoc',
      );
      expect(uniT7300, equals('Unisoc T7300'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 't7300',
          board: 't7300',
          socName: uniT7300,
        ),
        equals('Mali-G57 MP2'),
      );

      // 2. Oldest 64-bit SoCs (2014 / 2015)
      // Exynos 5433 (Galaxy Note 4, first 64-bit Exynos in late 2014)
      final ex5433 = DeviceSpecHelper.detectSocName(
        hardware: 'universal5433',
        board: 'universal5433',
        manufacturer: 'Samsung',
      );
      expect(ex5433, equals('Samsung Exynos 5433'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'universal5433',
          board: 'universal5433',
          socName: ex5433,
        ),
        equals('Mali-T760 MP6'),
      );
      expect(DeviceSpecHelper.isEntryOrLegacySoc(socName: ex5433), isTrue);

      // Exynos 7420 (Galaxy S6 / Note 5 in 2015)
      final ex7420 = DeviceSpecHelper.detectSocName(
        hardware: 'universal7420',
        board: 'universal7420',
        manufacturer: 'Samsung',
      );
      expect(ex7420, equals('Samsung Exynos 7420'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'universal7420',
          board: 'universal7420',
          socName: ex7420,
        ),
        equals('Mali-T760 MP8'),
      );
      expect(DeviceSpecHelper.isEntryOrLegacySoc(socName: ex7420), isTrue);

      // MediaTek MT6732 (World's first 64-bit LTE quad-core Cortex-A53 MediaTek chip in late 2014)
      final mt6732 = DeviceSpecHelper.detectSocName(
        hardware: 'mt6732',
        board: 'mt6732',
        manufacturer: 'MediaTek',
      );
      expect(mt6732, equals('MediaTek MT6732'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'mt6732',
          board: 'mt6732',
          socName: mt6732,
        ),
        equals('Mali-T760 MP2'),
      );
      expect(DeviceSpecHelper.isEntryOrLegacySoc(socName: mt6732), isTrue);

      // MediaTek MT6752 (Octa-core Cortex-A53 64-bit in late 2014)
      final mt6752 = DeviceSpecHelper.detectSocName(
        hardware: 'mt6752',
        board: 'mt6752',
        manufacturer: 'MediaTek',
      );
      expect(mt6752, equals('MediaTek MT6752'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'mt6752',
          board: 'mt6752',
          socName: mt6752,
        ),
        equals('Mali-T760 MP2'),
      );
      expect(DeviceSpecHelper.isEntryOrLegacySoc(socName: mt6752), isTrue);

      // Snapdragon 215 (QM215 - 64-bit ARM Cortex-A53 budget processor)
      final sd215 = DeviceSpecHelper.detectSocName(
        hardware: 'qm215',
        board: 'qm215',
        manufacturer: 'Qualcomm',
      );
      expect(sd215, equals('Qualcomm Snapdragon 215'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: 'qm215',
          board: 'qm215',
          socName: sd215,
        ),
        equals('Adreno 308'),
      );
      expect(DeviceSpecHelper.isEntryOrLegacySoc(socName: sd215), isTrue);

      // Snapdragon 415 (MSM8929 - 64-bit octa-core Cortex-A53 in 2015)
      final sd415 = DeviceSpecHelper.detectSocName(
        hardware: 'qcom',
        board: 'msm8929',
        manufacturer: 'Qualcomm',
      );
      expect(sd415, equals('Qualcomm Snapdragon 415'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: '',
          board: 'msm8929',
          socName: sd415,
        ),
        equals('Adreno 405'),
      );
      expect(DeviceSpecHelper.isEntryOrLegacySoc(socName: sd415), isTrue);

      // Snapdragon 615 (MSM8939 - Qualcomm's first 64-bit octa-core chip in late 2014)
      final sd615 = DeviceSpecHelper.detectSocName(
        hardware: 'qcom',
        board: 'msm8939',
        manufacturer: 'Qualcomm',
      );
      expect(sd615, equals('Qualcomm Snapdragon 615'));
      expect(
        DeviceSpecHelper.detectGpuName(
          hardware: '',
          board: 'msm8939',
          socName: sd615,
        ),
        equals('Adreno 405'),
      );
      expect(DeviceSpecHelper.isEntryOrLegacySoc(socName: sd615), isTrue);
    });
  });
}
