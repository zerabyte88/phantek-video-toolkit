import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

enum DeviceTier {
  highEnd, // Tier 1
  midRange, // Tier 2
  lowEnd,   // Tier 3
}

class DeviceSpecHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static int getTotalRamMb() {
    try {
      if (!Platform.isAndroid) return 4096; // Fallback
      final lines = File('/proc/meminfo').readAsLinesSync();
      for (final line in lines) {
        if (line.startsWith('MemTotal:')) {
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length > 1) {
            final kb = int.tryParse(parts[1]) ?? 0;
            return kb ~/ 1024;
          }
        }
      }
    } catch (e) {
      // Ignore
    }
    return 4096; // Fallback to 4GB
  }

  static Future<Map<String, dynamic>> getHardwareInfo() async {
    String model = 'Unknown';
    String manufacturer = 'Unknown';
    String hardware = 'Unknown';
    
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      model = info.model;
      manufacturer = info.manufacturer;
      hardware = info.hardware;
    }
    
    return {
      'model': model,
      'manufacturer': manufacturer,
      'hardware': hardware, // SoC name typically
      'cores': Platform.numberOfProcessors,
      'ramMb': getTotalRamMb(),
    };
  }

  static DeviceTier getDeviceTier() {
    final cores = Platform.numberOfProcessors;
    final ramMb = getTotalRamMb();

    if (cores >= 8 && ramMb >= 6000) {
      return DeviceTier.highEnd; // Tier 1
    } else if (cores >= 6 && ramMb >= 3000) {
      return DeviceTier.midRange; // Tier 2
    } else {
      return DeviceTier.lowEnd; // Tier 3
    }
  }

  static Future<double> getBatteryTemperature() async {
    // Read from sysfs for thermal zones. Often zone0 is CPU or battery.
    try {
      if (Platform.isAndroid) {
        // Try thermal_zone
        for (int i = 0; i < 5; i++) {
          final typeFile = File('/sys/class/thermal/thermal_zone$i/type');
          if (typeFile.existsSync()) {
            final type = typeFile.readAsStringSync().trim().toLowerCase();
            // We want 'battery' or just rely on zone0
            if (type.contains('battery') || i == 0) {
               final tempFile = File('/sys/class/thermal/thermal_zone$i/temp');
               if (tempFile.existsSync()) {
                  final tempStr = tempFile.readAsStringSync().trim();
                  final temp = int.tryParse(tempStr) ?? 0;
                  if (temp > 1000) {
                    return temp / 1000.0;
                  }
                  return temp.toDouble();
               }
            }
          }
        }
      }
    } catch (e) {
      // Ignore
    }
    return 35.0; // Fallback normal temp
  }
}
