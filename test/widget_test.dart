// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 zerabyte88

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:phantek_video_toolkit/main.dart';
import 'package:phantek_video_toolkit/models/encoding_options.dart';
import 'package:phantek_video_toolkit/models/video_info.dart';
import 'package:phantek_video_toolkit/screens/home_screen.dart';
import 'package:phantek_video_toolkit/services/localization_service.dart';
import 'package:phantek_video_toolkit/widgets/conversion_options_card.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const VideoDownscalerApp());

    expect(find.text('Phantek'), findsOneWidget);
    expect(find.text('Select Video'), findsWidgets);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
    'ConversionOptionsCard renders presets, badge, and interactive CRF reset',
    (WidgetTester tester) async {
      final l10n = AppLocalizations('id');
      const sourceVideo = VideoInfo(
        filePath: '/storage/sample.mp4',
        fileName: 'sample.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 120,
        bitrate: 10000000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 50000000,
      );

      EncodingOptions currentOpts = const EncodingOptions(
        speedPreset: SpeedPreset.normal,
        crfValue: 22,
      );

      VideoResolution currentRes = const VideoResolution(
        label: '720p',
        width: 1280,
        height: 720,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: ConversionOptionsCard(
                    sourceVideo: sourceVideo,
                    resolutions: sourceVideo.availableDownscaleTargets,
                    selectedResolution: currentRes,
                    onResolutionChanged: (res) =>
                        setState(() => currentRes = res),
                    encodingOptions: currentOpts,
                    onOptionsChanged: (opts) =>
                        setState(() => currentOpts = opts),
                    l10n: l10n,
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify Active Speed Preset indicator is rendered
      expect(find.byIcon(Icons.speed_rounded), findsOneWidget);
      expect(find.textContaining('Normal'), findsOneWidget);

      // Initial state: Normal preset -> default CRF 22, no custom indicator, no reset button
      expect(find.text('22'), findsOneWidget);
      expect(find.byKey(const Key('crf_reset_button')), findsNothing);
      expect(find.byKey(const Key('crf_custom_badge')), findsNothing);

      // Verify CRF label text is removed from ConversionOptionsCard
      expect(find.text(l10n.t('crf_label')), findsNothing);

      // Simulate custom low CRF (16) on Normal preset -> triggers custom tag, reset button, and low CRF warning
      currentOpts = currentOpts.copyWith(
        speedPreset: SpeedPreset.normal,
        crfValue: 16,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: ConversionOptionsCard(
                    sourceVideo: sourceVideo,
                    resolutions: sourceVideo.availableDownscaleTargets,
                    selectedResolution: currentRes,
                    onResolutionChanged: (res) =>
                        setState(() => currentRes = res),
                    encodingOptions: currentOpts,
                    onOptionsChanged: (opts) =>
                        setState(() => currentOpts = opts),
                    l10n: l10n,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('crf_custom_badge')), findsOneWidget);
      expect(find.byKey(const Key('crf_reset_button')), findsOneWidget);
      expect(find.textContaining('Pada CRF ≤ 17'), findsOneWidget);

      // Scroll into view & tap "Reset" button -> resets CRF to Normal preset default (22)
      await tester.ensureVisible(find.byKey(const Key('crf_reset_button')));
      await tester.tap(find.byKey(const Key('crf_reset_button')));
      await tester.pumpAndSettle();
      expect(currentOpts.crfValue, equals(22));
    },
  );

  testWidgets(
    'ConversionOptionsCard displays warning banner for 4K and >30 min videos',
    (WidgetTester tester) async {
      final l10n = const AppLocalizations('id');

      // 1. Standard video (1080p, 2 min) -> No banner
      const standardVid = VideoInfo(
        filePath: '/storage/sample.mp4',
        fileName: 'sample.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 120,
        bitrate: 10000000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 50000000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ConversionOptionsCard(
                sourceVideo: standardVid,
                resolutions: standardVid.availableDownscaleTargets,
                selectedResolution: standardVid.availableDownscaleTargets.first,
                onResolutionChanged: (_) {},
                encodingOptions: const EncodingOptions(),
                onOptionsChanged: (_) {},
                l10n: l10n,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('heavy_process_warning_banner')), findsNothing);

      // 2. 4K video (3840x2160, 2 min) -> Banner appears with 4K text
      const vid4K = VideoInfo(
        filePath: '/storage/4k.mp4',
        fileName: '4k.mp4',
        width: 3840,
        height: 2160,
        durationSeconds: 120,
        bitrate: 20000000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 300000000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ConversionOptionsCard(
                sourceVideo: vid4K,
                resolutions: vid4K.availableDownscaleTargets,
                selectedResolution: vid4K.availableDownscaleTargets.first,
                onResolutionChanged: (_) {},
                encodingOptions: const EncodingOptions(),
                onOptionsChanged: (_) {},
                l10n: l10n,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('heavy_process_warning_banner')), findsOneWidget);
      expect(find.text(l10n.t('heavy_process_banner_4k')), findsOneWidget);

      // 3. Long duration video (1080p, 12 min = 720s) -> Banner appears with long duration text
      const vidLong = VideoInfo(
        filePath: '/storage/long.mp4',
        fileName: 'long.mp4',
        width: 1920,
        height: 1080,
        durationSeconds: 720,
        bitrate: 5000000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 500000000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ConversionOptionsCard(
                sourceVideo: vidLong,
                resolutions: vidLong.availableDownscaleTargets,
                selectedResolution: vidLong.availableDownscaleTargets.first,
                onResolutionChanged: (_) {},
                encodingOptions: const EncodingOptions(),
                onOptionsChanged: (_) {},
                l10n: l10n,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('heavy_process_warning_banner')), findsOneWidget);
      expect(
        find.text(l10n.t('heavy_process_banner_long', args: {'duration': vidLong.formattedDuration})),
        findsOneWidget,
      );

      // 4. Combined 4K + Long duration video -> Combined banner
      const vid4KLong = VideoInfo(
        filePath: '/storage/4k_long.mp4',
        fileName: '4k_long.mp4',
        width: 3840,
        height: 2160,
        durationSeconds: 2400,
        bitrate: 20000000,
        fps: 30,
        codec: 'h264',
        fileSizeBytes: 2000000000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ConversionOptionsCard(
                sourceVideo: vid4KLong,
                resolutions: vid4KLong.availableDownscaleTargets,
                selectedResolution: vid4KLong.availableDownscaleTargets.first,
                onResolutionChanged: (_) {},
                encodingOptions: const EncodingOptions(),
                onOptionsChanged: (_) {},
                l10n: l10n,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('heavy_process_warning_banner')), findsOneWidget);
      expect(find.text(l10n.t('heavy_process_banner_4k_long')), findsOneWidget);
    },
  );
}
