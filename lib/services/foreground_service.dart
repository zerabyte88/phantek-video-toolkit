import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundServiceManager {
  static final ForegroundServiceManager _instance = ForegroundServiceManager._internal();
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
          channelId: 'video_conversion_channel_v2',
          channelName: 'Proses Konversi Video',
          channelDescription: 'Pemberitahuan proses konversi video di latar belakang',
          channelImportance: NotificationChannelImportance.HIGH,
          priority: NotificationPriority.HIGH,
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
        final res = await FlutterForegroundTask.requestNotificationPermission();
        return res == NotificationPermission.granted;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
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
        await FlutterForegroundTask.startService(
          serviceId: 256,
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
  }) async {
    try {
      final now = DateTime.now();
      if (_lastNotificationUpdate != null &&
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
