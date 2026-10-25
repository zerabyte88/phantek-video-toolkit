// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 zerabyte88

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void _foregroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_VideoProcessingTaskHandler());
}

class _VideoProcessingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

class ForegroundServiceManager {
  static final ForegroundServiceManager _instance =
      ForegroundServiceManager._internal();
  factory ForegroundServiceManager() => _instance;
  ForegroundServiceManager._internal();

  DateTime? _lastNotificationUpdate;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      FlutterForegroundTask.initCommunicationPort();
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'video_conversion_channel_v4',
          channelName: 'Video Processing',
          channelDescription: 'Background video conversion notification',
          channelImportance: NotificationChannelImportance.HIGH,
          priority: NotificationPriority.HIGH,
          onlyAlertOnce: true,
          showWhen: true,
          visibility: NotificationVisibility.VISIBILITY_PUBLIC,
          enableVibration: false,
          playSound: false,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
          autoRunOnBoot: false,
          autoRunOnMyPackageReplaced: false,
          allowWakeLock: true,
          allowWifiLock: false,
        ),
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing ForegroundServiceManager: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final perm = await FlutterForegroundTask.checkNotificationPermission();
      if (perm != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      // Request battery optimization exemption for background processing
      if (Platform.isAndroid) {
        final isIgnoringBattery =
            await FlutterForegroundTask.isIgnoringBatteryOptimizations;
        if (!isIgnoringBattery) {
          await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error requesting foreground permissions: $e');
      return false;
    }
  }

  Future<void> startService({
    required String title,
    required String text,
  }) async {
    try {
      await init();
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (!isRunning) {
        final result = await FlutterForegroundTask.startService(
          serviceId: 256,
          serviceTypes: [
            ForegroundServiceTypes.dataSync,
            ForegroundServiceTypes.mediaProcessing,
          ],
          notificationTitle: title,
          notificationText: text,
          callback: _foregroundTaskCallback,
        );
        debugPrint('Foreground service started result: $result');
      } else {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
      }
    } catch (e) {
      debugPrint('Error starting foreground service: $e');
    }
  }

  Future<void> updateService({
    required String title,
    required String text,
    bool force = false,
  }) async {
    try {
      final now = DateTime.now();
      if (!force &&
          _lastNotificationUpdate != null &&
          now.difference(_lastNotificationUpdate!).inMilliseconds < 800) {
        return;
      }
      _lastNotificationUpdate = now;

      final isRunning = await FlutterForegroundTask.isRunningService;
      if (isRunning) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
      }
    } catch (e) {
      debugPrint('Error updating foreground service: $e');
    }
  }

  Future<void> stopService() async {
    try {
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (isRunning) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      debugPrint('Error stopping foreground service: $e');
    }
  }
}
