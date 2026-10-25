// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 zerabyte88

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/foreground_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().init();
  await ForegroundServiceManager().init();

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
        final settings = SettingsService().settings;
        final theme = AppTheme.getTheme(
          settings.themeMode,
          cardOpacity: settings.cardOpacity,
        );

        // Sync system nav bar color with active theme
        final navBarColor = theme.scaffoldBackgroundColor;
        final isDark = theme.brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarColor: navBarColor,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
        );

        return MaterialApp(
          title: 'Video Downscaler',
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: const HomeScreen(),
        );
      },
    );
  }
}
