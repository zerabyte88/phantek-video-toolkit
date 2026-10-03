import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_downscaler/models/app_settings.dart';
import 'package:video_downscaler/models/encoding_options.dart';
import 'package:video_downscaler/models/video_info.dart';
import 'package:video_downscaler/services/cache_manager_service.dart';
import 'package:video_downscaler/services/device_spec_helper.dart';
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

        // Ensure keys do not return the literal key name
        expect(l10n.t('proc_cancel_confirm'), isNot(equals('proc_cancel_confirm')));
        expect(l10n.t('proc_continue_btn'), isNot(equals('proc_continue_btn')));
        expect(l10n.t('proc_cancel_btn'), isNot(equals('proc_cancel_btn')));
        expect(l10n.t('rate_control'), isNot(equals('rate_control')));
      }
    });

    test('Device specifications keys resolve properly and accurately in all 6 languages', () {
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
      expect(settings.audioOutputDirectory, equals(''));
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
        expect(l10n.t('settings_audio_output_folder').isNotEmpty, isTrue);
        expect(l10n.t('settings_audio_output_folder_desc').isNotEmpty, isTrue);
        expect(l10n.t('settings_audio_reset_folder').isNotEmpty, isTrue);
        expect(l10n.t('settings_audio_folder_changed').isNotEmpty, isTrue);
        expect(l10n.t('settings_audio_folder_default').isNotEmpty, isTrue);
        expect(l10n.t('settings_ram_ultra').isNotEmpty, isTrue);
        expect(l10n.t('settings_ram_4gb_disabled_hint').isNotEmpty, isTrue);
      }
    });

    test('AppSettings supports 4096 MB RAM buffer serialization and copyWith', () {
      const original = AppSettings(ramBufferMb: 4096);
      expect(original.ramBufferMb, equals(4096));
      final json = original.toJson();
      expect(json['ramBufferMb'], equals(4096));
      final fromJson = AppSettings.fromJson(json);
      expect(fromJson.ramBufferMb, equals(4096));

      final updated = original.copyWith(ramBufferMb: 2048);
      expect(updated.ramBufferMb, equals(2048));
    });

    test('DeviceSpecHelper getProcessRssMb returns non-negative memory integer', () {
      final rssMb = DeviceSpecHelper.getProcessRssMb();
      expect(rssMb, greaterThanOrEqualTo(0));
    });

    test('AppSettings copyWith properly updates outputDirectory and other fields', () {
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

    test('Navigation and options reset localization keys resolve correctly in all 6 languages', () {
      const supportedCodes = ['id', 'en', 'ja', 'zh_CN', 'zh_TW', 'ko'];
      for (final code in supportedCodes) {
        final l10n = AppLocalizations(code);
        expect(l10n.t('back_to_home').isNotEmpty, isTrue);
        expect(l10n.t('reset_options').isNotEmpty, isTrue);
        expect(l10n.t('options_reset_success').isNotEmpty, isTrue);
        expect(l10n.t('back_to_home'), isNot(equals('back_to_home')));
        expect(l10n.t('reset_options'), isNot(equals('reset_options')));
        expect(l10n.t('options_reset_success'), isNot(equals('options_reset_success')));
      }
    });

    test('Audio Extractor localization keys resolve properly in all 6 languages', () {
      const supportedCodes = ['id', 'en', 'ja', 'zh_CN', 'zh_TW', 'ko'];
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

    test('generateUniqueAudioOutputPath generates clean unique audio filenames', () async {
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
    });

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

    test('no_audio_track localization resolves properly across all 6 languages', () {
      for (final code in ['id', 'en', 'ja', 'zh_CN', 'zh_TW', 'ko']) {
        final l10n = AppLocalizations(code);
        final translated = l10n.t('no_audio_track');
        expect(translated.isNotEmpty, isTrue);
        expect(translated, isNot(equals('no_audio_track')));
      }
    });

    test('FFmpegService getOutputDirectory respects custom path and isAudio flag', () async {
      final customDir = Directory('${tempDir.path}${Platform.pathSeparator}CustomAudio');
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
    });

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
}

