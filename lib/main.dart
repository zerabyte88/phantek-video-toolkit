import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF11111B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const VideoDownscalerApp());
}

class VideoDownscalerApp extends StatelessWidget {
  const VideoDownscalerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, child) {
        final themeMode = SettingsService().settings.themeMode;
        return MaterialApp(
          title: 'Video Downscaler',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(themeMode),
          home: const HomeScreen(),
        );
      },
    );
  }
}
