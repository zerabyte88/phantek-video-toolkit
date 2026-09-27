import 'package:flutter_test/flutter_test.dart';
import 'package:video_downscaler/models/app_settings.dart';
import 'package:video_downscaler/models/encoding_options.dart';
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

  group('EncodingOptions and Bitrate Calculation tests', () {
    test('Calculates auto bitrate properly based on resolution', () {
      const options = EncodingOptions(
        codec: VideoCodec.h264,
        bitratePreset: BitratePreset.auto,
      );

      final bitrate1080p = options.calculateTargetBitrateKbps(
        targetWidth: 1920,
        targetHeight: 1080,
        sourceWidth: 3840,
        sourceHeight: 2160,
        sourceBitrateBps: 20000000,
      );

      expect(bitrate1080p, greaterThanOrEqualTo(3000));
      expect(bitrate1080p, lessThanOrEqualTo(12000));

      final bitrate720p = options.calculateTargetBitrateKbps(
        targetWidth: 1280,
        targetHeight: 720,
        sourceWidth: 3840,
        sourceHeight: 2160,
        sourceBitrateBps: 20000000,
      );

      expect(bitrate720p, lessThan(bitrate1080p));
    });

    test('HEVC / H.265 uses reduced bitrate for equivalent quality', () {
      const h264Options = EncodingOptions(codec: VideoCodec.h264);
      const hevcOptions = EncodingOptions(codec: VideoCodec.hevc);

      final h264Bitrate = h264Options.calculateTargetBitrateKbps(
        targetWidth: 1920,
        targetHeight: 1080,
        sourceWidth: 3840,
        sourceHeight: 2160,
        sourceBitrateBps: 20000000,
      );

      final hevcBitrate = hevcOptions.calculateTargetBitrateKbps(
        targetWidth: 1920,
        targetHeight: 1080,
        sourceWidth: 3840,
        sourceHeight: 2160,
        sourceBitrateBps: 20000000,
      );

      expect(hevcBitrate, lessThan(h264Bitrate));
    });

    test('Custom bitrate is respected', () {
      const options = EncodingOptions(
        bitratePreset: BitratePreset.custom,
        customBitrateKbps: 5000,
      );

      final bitrate = options.calculateTargetBitrateKbps(
        targetWidth: 1920,
        targetHeight: 1080,
        sourceWidth: 1920,
        sourceHeight: 1080,
        sourceBitrateBps: 8000000,
      );

      expect(bitrate, equals(5000));
    });
  });

  group('AppSettings tests', () {
    test('Default values are correct', () {
      const settings = AppSettings();
      expect(settings.cpuThreads, equals(0)); // Auto
      expect(settings.ramBufferMb, equals(512));
      expect(settings.cpuPreset, equals('medium'));
      expect(settings.hardwareAcceleration, isFalse);
      expect(settings.audioBitrateKbps, equals(128));
      expect(settings.languageCode, equals('id'));
    });

    test('Serialization to and from JSON works', () {
      const original = AppSettings(
        cpuThreads: 4,
        ramBufferMb: 1024,
        cpuPreset: 'fast',
        hardwareAcceleration: true,
        audioBitrateKbps: 192,
        languageCode: 'ja',
      );

      final json = original.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.cpuThreads, equals(4));
      expect(restored.ramBufferMb, equals(1024));
      expect(restored.cpuPreset, equals('fast'));
      expect(restored.hardwareAcceleration, isTrue);
      expect(restored.audioBitrateKbps, equals(192));
      expect(restored.languageCode, equals('ja'));
    });
  });
}
