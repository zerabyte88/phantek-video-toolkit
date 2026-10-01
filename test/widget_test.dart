import 'package:flutter_test/flutter_test.dart';

import 'package:video_downscaler/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const VideoDownscalerApp());

    expect(find.text('Phantek Video Toolkit'), findsOneWidget);
    expect(find.text('Pilih Video'), findsWidgets);
  });
}
