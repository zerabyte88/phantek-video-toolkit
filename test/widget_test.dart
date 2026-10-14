import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:video_downscaler/main.dart';
import 'package:video_downscaler/models/encoding_options.dart';
import 'package:video_downscaler/models/video_info.dart';
import 'package:video_downscaler/screens/home_screen.dart';
import 'package:video_downscaler/services/localization_service.dart';
import 'package:video_downscaler/widgets/conversion_options_card.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const VideoDownscalerApp());

    expect(find.text('Phantek'), findsOneWidget);
    expect(find.text('Pilih Video'), findsWidgets);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('ConversionOptionsCard renders presets, badge, and interactive CRF reset', (WidgetTester tester) async {
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
                  onResolutionChanged: (res) => setState(() => currentRes = res),
                  encodingOptions: currentOpts,
                  onOptionsChanged: (opts) => setState(() => currentOpts = opts),
                  l10n: l10n,
                ),
              );
            },
          ),
        ),
      ),
    );

    // Verify Speed preset chips are present
    expect(find.text('Cepat'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Maksimal'), findsOneWidget);

    // Initial state: Normal preset -> default CRF 22, no custom indicator, no reset button
    expect(find.text('22'), findsOneWidget);
    expect(find.byKey(const Key('crf_reset_button')), findsNothing);
    expect(find.byKey(const Key('crf_custom_badge')), findsNothing);

    // Tap "Cepat" preset -> updates to fast and default CRF 24
    await tester.tap(find.text('Cepat'));
    await tester.pumpAndSettle();
    expect(currentOpts.speedPreset, equals(SpeedPreset.fast));
    expect(currentOpts.crfValue, equals(24));
    expect(find.text('24'), findsOneWidget);

    // Tap "Maksimal" preset -> shows orange warning badge and default CRF 20
    await tester.tap(find.text('Maksimal'));
    await tester.pumpAndSettle();
    expect(currentOpts.speedPreset, equals(SpeedPreset.max));
    expect(currentOpts.crfValue, equals(20));
    expect(find.text('20'), findsOneWidget);
    expect(find.text('Lebih lama & daya CPU tinggi'), findsOneWidget);

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
                  onResolutionChanged: (res) => setState(() => currentRes = res),
                  encodingOptions: currentOpts,
                  onOptionsChanged: (opts) => setState(() => currentOpts = opts),
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
  });
}
