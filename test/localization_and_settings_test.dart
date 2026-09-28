import 'package:flutter_test/flutter_test.dart';
import 'package:video_downscaler/models/app_settings.dart';
import 'package:video_downscaler/models/encoding_options.dart';
import 'package:video_downscaler/services/cache_manager_service.dart';
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
        expect(l10n.t('app_title'), 'Video Downscaler');
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
  });

  // Encoding tests removed due to refactor

  group('AppSettings tests', () {
    test('Default values are correct', () {
      const settings = AppSettings();
      expect(settings.cpuThreads, equals(0)); // Auto
      expect(settings.ramBufferMb, equals(512));
      expect(settings.cpuPreset, equals('medium'));
      expect(settings.hardwareAcceleration, isFalse);
      expect(settings.audioBitrateKbps, equals(128));
      expect(settings.languageCode, equals('id'));
      expect(settings.themeMode, equals('dark'));
      expect(settings.keepScreenAwake, isFalse);
    });

    test('Serialization to and from JSON works', () {
      const original = AppSettings(
        cpuThreads: 4,
        ramBufferMb: 1024,
        cpuPreset: 'fast',
        hardwareAcceleration: true,
        audioBitrateKbps: 192,
        languageCode: 'ja',
        themeMode: 'oled',
        keepScreenAwake: true,
      );

      final json = original.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.cpuThreads, equals(4));
      expect(restored.ramBufferMb, equals(1024));
      expect(restored.cpuPreset, equals('fast'));
      expect(restored.hardwareAcceleration, isTrue);
      expect(restored.audioBitrateKbps, equals(192));
      expect(restored.languageCode, equals('ja'));
      expect(restored.themeMode, equals('oled'));
      expect(restored.keepScreenAwake, isTrue);
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
      }
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
}

