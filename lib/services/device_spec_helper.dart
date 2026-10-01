import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

enum DeviceTier {
  highEnd,  // Tier 1
  midRange, // Tier 2
  lowEnd,   // Tier 3
}

class DeviceSpecHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static int getTotalRamMb() {
    try {
      if (!Platform.isAndroid) return 8192; // Fallback for tests/desktop
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
    } catch (_) {}
    return 4096; // Fallback to 4GB
  }

  static int getMarketedRamGb(int ramMb) {
    if (ramMb <= 0) return 4;
    final gb = ramMb / 1024.0;
    if (gb <= 1.3) return 1;
    if (gb <= 2.4) return 2;
    if (gb <= 3.4) return 3;
    if (gb <= 4.5) return 4;
    if (gb <= 6.5) return 6;
    if (gb <= 8.8) return 8;
    if (gb <= 12.8) return 12;
    if (gb <= 16.8) return 16;
    if (gb <= 24.8) return 24;
    if (gb <= 32.8) return 32;
    return gb.round();
  }

  static Future<Map<String, dynamic>> getStorageInfo() async {
    int totalMb = 0;
    int freeMb = 0;

    try {
      if (Platform.isAndroid) {
        // Run df on user data partition
        final result = await Process.run('df', ['-k', '/data']);
        if (result.exitCode == 0) {
          final lines = (result.stdout as String).trim().split('\n');
          for (final line in lines.skip(1)) {
            final parts = line.trim().split(RegExp(r'\s+'));
            if (parts.length >= 4) {
              final t = int.tryParse(parts[1]) ?? 0;
              final f = int.tryParse(parts[3]) ?? 0;
              if (t > 0) {
                totalMb = t ~/ 1024;
                freeMb = f ~/ 1024;
                break;
              }
            }
          }
        }
      }
    } catch (_) {}

    // Categorize to marketed storage sizes (32, 64, 128, 256, 512, 1024 GB)
    int marketedGb;
    if (totalMb <= 0) {
      marketedGb = 256;
      freeMb = 142 * 1024;
    } else {
      final tGb = totalMb / 1024.0;
      if (tGb <= 34) {
        marketedGb = 32;
      } else if (tGb <= 66) {
        marketedGb = 64;
      } else if (tGb <= 130) {
        marketedGb = 128;
      } else if (tGb <= 260) {
        marketedGb = 256;
      } else if (tGb <= 520) {
        marketedGb = 512;
      } else if (tGb <= 1040) {
        marketedGb = 1024;
      } else {
        marketedGb = tGb.round();
      }
    }

    final freeGb = freeMb / 1024.0;
    final freeStr = freeGb >= 1.0 ? '${freeGb.toStringAsFixed(0)} GB' : '$freeMb MB';

    return {
      'totalGb': marketedGb,
      'freeStr': freeStr,
      'storage': '$marketedGb GB',
      'storageDisplay': '$marketedGb GB ($freeStr)',
    };
  }

  static int _getMaxCpuFreqKHz() {
    try {
      if (Platform.isAndroid) {
        for (final cpu in ['cpu7', 'cpu4', 'cpu0']) {
          final file = File('/sys/devices/system/cpu/$cpu/cpufreq/cpuinfo_max_freq');
          if (file.existsSync()) {
            final freq = int.tryParse(file.readAsStringSync().trim()) ?? 0;
            if (freq > 0) return freq;
          }
        }
      }
    } catch (_) {}
    return 0;
  }

  static String detectSocName({
    required String hardware,
    required String board,
    required String manufacturer,
    String? socModel,
  }) {
    final hwLower = hardware.toLowerCase();
    final boardLower = board.toLowerCase();
    final socLower = (socModel ?? '').toLowerCase();

    // 1. Explicit Snapdragon 685 (SM6225-AD)
    if (hwLower.contains('sm6225-ad') ||
        hwLower.contains('sm6225_ad') ||
        socLower.contains('sm6225-ad') ||
        socLower.contains('sm6225_ad') ||
        socLower.contains('685')) {
      return 'Qualcomm Snapdragon 685';
    }

    // Qualcomm Snapdragon SoCs
    if (hwLower.contains('sm8650') || boardLower.contains('pineapple')) return 'Qualcomm Snapdragon 8 Gen 3';
    if (hwLower.contains('sm8550') || boardLower.contains('kalama')) return 'Qualcomm Snapdragon 8 Gen 2';
    if (hwLower.contains('sm8475')) return 'Qualcomm Snapdragon 8+ Gen 1';
    if (hwLower.contains('sm8450') || boardLower.contains('taro')) return 'Qualcomm Snapdragon 8 Gen 1';
    if (hwLower.contains('sm8350') || boardLower.contains('lahaina')) return 'Qualcomm Snapdragon 888';
    if (hwLower.contains('sm8250') || boardLower.contains('kona')) return 'Qualcomm Snapdragon 865 / 870';
    if (hwLower.contains('sm8150')) return 'Qualcomm Snapdragon 855';
    if (hwLower.contains('sm7550')) return 'Qualcomm Snapdragon 7 Gen 3';
    if (hwLower.contains('sm7475')) return 'Qualcomm Snapdragon 7+ Gen 2';
    if (hwLower.contains('sm7450')) return 'Qualcomm Snapdragon 7 Gen 1';
    if (hwLower.contains('sm7435') || hwLower.contains('sm6450') || boardLower.contains('crow')) {
      return 'Qualcomm Snapdragon 7s Gen 2';
    }
    if (hwLower.contains('sm7325') || boardLower.contains('yupik')) return 'Qualcomm Snapdragon 778G';
    if (hwLower.contains('sm6375') || boardLower.contains('holi')) return 'Qualcomm Snapdragon 695 5G';

    // Multi-signal Android hardware detection (soc_id, machine, GPU model, clock speed)
    if (Platform.isAndroid) {
      // Check kgsl gpu model (Adreno610v2 is exclusive to Snapdragon 685)
      try {
        final gpuFile = File('/sys/class/kgsl/kgsl-3d0/gpu_model');
        if (gpuFile.existsSync()) {
          final gpuContent = gpuFile.readAsStringSync().toLowerCase();
          if (gpuContent.contains('610v2') || gpuContent.contains('610_v2')) {
            return 'Qualcomm Snapdragon 685';
          }
        }
      } catch (_) {}

      // Check soc0 soc_id (574 = 685, 486 = 680, 444 = 662)
      try {
        final socIdFile = File('/sys/devices/soc0/soc_id');
        if (socIdFile.existsSync()) {
          final id = int.tryParse(socIdFile.readAsStringSync().trim()) ?? 0;
          if (id == 574 || id == 575 || id == 576) {
            return 'Qualcomm Snapdragon 685';
          } else if (id == 486) {
            return 'Qualcomm Snapdragon 680';
          } else if (id == 444) {
            return 'Qualcomm Snapdragon 662';
          }
        }
      } catch (_) {}

      // Check soc0 machine
      try {
        final machineFile = File('/sys/devices/soc0/machine');
        if (machineFile.existsSync()) {
          final machine = machineFile.readAsStringSync().toLowerCase().trim();
          if (machine.contains('sm6225-ad') || machine.contains('sm6225_ad') || machine.contains('685')) {
            return 'Qualcomm Snapdragon 685';
          } else if (machine.contains('sm6225') || machine.contains('680')) {
            return 'Qualcomm Snapdragon 680';
          }
        }
      } catch (_) {}

      // Check CPU max frequency on performance cores (685 = 2.8 GHz, 680 = 2.4 GHz, 662 = 2.0 GHz)
      final maxFreq = _getMaxCpuFreqKHz();
      if (maxFreq >= 2600000 &&
          (boardLower.contains('bengal') || boardLower.contains('khaje') || hwLower.contains('qcom'))) {
        return 'Qualcomm Snapdragon 685';
      }
    }

    if (hwLower.contains('sm6225') || boardLower.contains('khaje')) return 'Qualcomm Snapdragon 680';
    if (hwLower.contains('sm6125') || boardLower.contains('trinket')) return 'Qualcomm Snapdragon 665';
    if (hwLower.contains('sm6115')) return 'Qualcomm Snapdragon 662';

    // If board is generic 'bengal' (shared platform for 662, 680, 685)
    if (boardLower.contains('bengal')) {
      if (Platform.isAndroid) {
        final maxFreq = _getMaxCpuFreqKHz();
        if (maxFreq >= 2600000) return 'Qualcomm Snapdragon 685';
        if (maxFreq >= 2200000) return 'Qualcomm Snapdragon 680';
      }
      return 'Qualcomm Snapdragon 662';
    }

    if (hwLower.contains('sm4450')) return 'Qualcomm Snapdragon 4 Gen 2';
    if (hwLower.contains('sm4375')) return 'Qualcomm Snapdragon 4 Gen 1';

    // MediaTek Dimensity & Helio SoCs
    if (hwLower.contains('mt6991')) return 'MediaTek Dimensity 9400';
    if (hwLower.contains('mt6989')) return 'MediaTek Dimensity 9300';
    if (hwLower.contains('mt6985')) return 'MediaTek Dimensity 9200';
    if (hwLower.contains('mt6983')) return 'MediaTek Dimensity 9000';
    if (hwLower.contains('mt6897')) return 'MediaTek Dimensity 8300';
    if (hwLower.contains('mt6895')) return 'MediaTek Dimensity 8100';
    if (hwLower.contains('mt6893')) return 'MediaTek Dimensity 1200';
    if (hwLower.contains('mt6877')) return 'MediaTek Dimensity 1080 / 900';
    if (hwLower.contains('mt6853')) return 'MediaTek Dimensity 720';
    if (hwLower.contains('mt6833')) return 'MediaTek Dimensity 700 / 6020';
    if (hwLower.contains('mt6789')) return 'MediaTek Helio G99';
    if (hwLower.contains('mt6785')) return 'MediaTek Helio G90 / G95';
    if (hwLower.contains('mt6769')) return 'MediaTek Helio G80 / G85';
    if (hwLower.contains('mt6768')) return 'MediaTek Helio P65';
    if (hwLower.contains('mt6765')) return 'MediaTek Helio P35';
    if (hwLower.contains('mt6762')) return 'MediaTek Helio P22';

    // Samsung Exynos SoCs
    if (hwLower.contains('s5e9945')) return 'Samsung Exynos 2400';
    if (hwLower.contains('s5e9925') || boardLower.contains('erd9925')) return 'Samsung Exynos 2200';
    if (hwLower.contains('s5e9840')) return 'Samsung Exynos 2100';
    if (hwLower.contains('s5e8835')) return 'Samsung Exynos 1380';
    if (hwLower.contains('s5e8825')) return 'Samsung Exynos 1280';
    if (hwLower.contains('universal990')) return 'Samsung Exynos 990';
    if (hwLower.contains('universal9820')) return 'Samsung Exynos 9820';
    if (hwLower.contains('universal9810')) return 'Samsung Exynos 9810';

    // Google Tensor SoCs
    if (boardLower.contains('zumapro')) return 'Google Tensor G4';
    if (boardLower.contains('zuma')) return 'Google Tensor G3';
    if (boardLower.contains('gs201') || boardLower.contains('cloudripper')) return 'Google Tensor G2';
    if (boardLower.contains('gs101') || boardLower.contains('whitechapel')) return 'Google Tensor';

    // Android device sysfs / procfs fallback for unlisted chipsets
    if (Platform.isAndroid) {
      // 1. Try reading /sys/devices/soc0/machine
      try {
        final machineFile = File('/sys/devices/soc0/machine');
        if (machineFile.existsSync()) {
          final machine = machineFile.readAsStringSync().trim();
          if (machine.isNotEmpty && !machine.toLowerCase().contains('unknown')) {
            return machine;
          }
        }
      } catch (_) {}

      // 2. Try reading /proc/cpuinfo Hardware line
      try {
        final lines = File('/proc/cpuinfo').readAsLinesSync();
        for (final line in lines) {
          final lower = line.toLowerCase();
          if (lower.startsWith('hardware')) {
            final parts = line.split(':');
            if (parts.length > 1) {
              final hw = parts[1].trim();
              if (hw.isNotEmpty && !hw.toLowerCase().contains('unknown')) {
                return hw;
              }
            }
          }
        }
      } catch (_) {}
    }

    if (hwLower.startsWith('sdm') || hwLower.startsWith('msm') || hwLower.startsWith('sm')) {
      return 'Qualcomm Snapdragon ${hardware.toUpperCase()}';
    }
    if (hwLower.contains('qcom')) return 'Qualcomm Snapdragon';
    if (hwLower.startsWith('mt')) return 'MediaTek ${hardware.toUpperCase()}';
    if (hwLower.contains('exynos') || boardLower.contains('exynos')) return 'Samsung Exynos';

    if (hardware.isNotEmpty && hardware.toLowerCase() != 'unknown') {
      return hardware.toUpperCase();
    }
    if (board.isNotEmpty && board.toLowerCase() != 'unknown') {
      return board.toUpperCase();
    }

    return 'Standard Processor';
  }

  static String detectGpuName({
    required String hardware,
    required String board,
    required String socName,
  }) {
    // 1. Try reading Qualcomm kgsl sysfs on Android
    if (Platform.isAndroid) {
      try {
        final gpuFile = File('/sys/class/kgsl/kgsl-3d0/gpu_model');
        if (gpuFile.existsSync()) {
          var model = gpuFile.readAsStringSync().trim();
          if (model.isNotEmpty) {
            model = model
                .replaceAll('(TM)', '')
                .replaceAll('(tm)', '')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();

            // Format Adreno models: e.g. "Adreno610v2" or "Adreno610" -> "Adreno 610"
            final adrenoMatch =
                RegExp(r'^adreno\s*(\d+)(.*)$', caseSensitive: false)
                    .firstMatch(model);
            if (adrenoMatch != null) {
              final num = adrenoMatch.group(1)!;
              return 'Adreno $num';
            }
            return model;
          }
        }
      } catch (_) {}
    }

    // 2. Correlate with detected SoC / chipset
    final s = socName.toLowerCase();
    final h = hardware.toLowerCase();
    final b = board.toLowerCase();

    // Qualcomm Adreno GPU series
    if (s.contains('8 gen 3') || h.contains('sm8650') || b.contains('pineapple')) return 'Adreno 750';
    if (s.contains('8 gen 2') || h.contains('sm8550') || b.contains('kalama')) return 'Adreno 740';
    if (s.contains('8+ gen 1') || s.contains('8 gen 1') || h.contains('sm8475') || h.contains('sm8450')) return 'Adreno 730';
    if (s.contains('888') || h.contains('sm8350')) return 'Adreno 660';
    if (s.contains('865') || s.contains('870') || h.contains('sm8250')) return 'Adreno 650';
    if (s.contains('855') || h.contains('sm8150')) return 'Adreno 640';
    if (s.contains('7 gen 3') || h.contains('sm7550')) return 'Adreno 720';
    if (s.contains('7+ gen 2') || h.contains('sm7475')) return 'Adreno 725';
    if (s.contains('7s gen 2') || h.contains('sm7435') || h.contains('sm6450') || b.contains('crow')) return 'Adreno 710';
    if (s.contains('778g') || h.contains('sm7325')) return 'Adreno 642L';
    if (s.contains('695') || h.contains('sm6375') || h.contains('sm4375')) return 'Adreno 619';
    if (s.contains('685') || s.contains('680') || s.contains('665') || h.contains('sm6225') || h.contains('sm6125')) {
      return 'Adreno 610';
    }
    if (s.contains('4 gen 2') || h.contains('sm4450')) return 'Adreno 613';
    if (s.contains('adreno') || h.contains('qcom')) return 'Qualcomm Adreno GPU';

    // MediaTek Dimensity & Helio Mali / Immortalis
    if (s.contains('9400') || h.contains('mt6991')) return 'Immortalis-G925';
    if (s.contains('9300') || h.contains('mt6989')) return 'Immortalis-G720 MC12';
    if (s.contains('9200') || h.contains('mt6985')) return 'Immortalis-G715 MC11';
    if (s.contains('9000') || h.contains('mt6983')) return 'Mali-G710 MC10';
    if (s.contains('8300') || h.contains('mt6897')) return 'Mali-G615 MC6';
    if (s.contains('8100') || s.contains('8200') || h.contains('mt6895')) return 'Mali-G610 MC6';
    if (s.contains('1200') || s.contains('1100') || h.contains('mt6893')) return 'Mali-G77 MC9';
    if (s.contains('1080') || s.contains('900') || s.contains('7050') || h.contains('mt6877')) return 'Mali-G68 MC4';
    if (s.contains('700') || s.contains('6020') || s.contains('g99') || h.contains('mt6833') || h.contains('mt6789')) return 'Mali-G57 MC2';
    if (s.contains('g90') || s.contains('g95') || h.contains('mt6785')) return 'Mali-G76 MC4';
    if (s.contains('g80') || s.contains('g85') || s.contains('g88') || h.contains('mt6769')) return 'Mali-G52 MC2';
    if (s.contains('p35') || s.contains('g35') || h.contains('mt6765')) return 'PowerVR GE8320';
    if (h.startsWith('mt') || s.contains('mediatek') || s.contains('dimensity')) return 'ARM Mali GPU';

    // Samsung Exynos (AMD RDNA Xclipse / Mali)
    if (s.contains('2400') || h.contains('s5e9945')) return 'Samsung Xclipse 940';
    if (s.contains('2200') || h.contains('s5e9925')) return 'Samsung Xclipse 920';
    if (s.contains('2100') || h.contains('s5e9840')) return 'Mali-G78 MP14';
    if (s.contains('1380') || h.contains('s5e8835')) return 'Mali-G68 MP5';
    if (s.contains('1280') || h.contains('s5e8825')) return 'Mali-G68 MP4';
    if (s.contains('exynos')) return 'ARM Mali / Xclipse GPU';

    // Google Tensor
    if (b.contains('zumapro') || s.contains('tensor g4')) return 'Mali-G715';
    if (b.contains('zuma') || s.contains('tensor g3')) return 'Immortalis-G715s';
    if (b.contains('gs201') || s.contains('tensor g2')) return 'Mali-G710 MP7';
    if (b.contains('gs101') || s.contains('tensor')) return 'Mali-G78 MP20';

    return 'Hardware Graphics Accelerator';
  }

  static Future<Map<String, dynamic>> getHardwareInfo() async {
    String model = 'Unknown';
    String manufacturer = 'Unknown';
    String hardware = 'Unknown';
    String board = 'Unknown';
    String brand = 'Unknown';
    String device = 'Unknown';
    String? socModel;

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      model = info.model;
      manufacturer = info.manufacturer;
      hardware = info.hardware;
      board = info.board;
      brand = info.brand;
      device = info.device;
      try {
        socModel = (info.data['socModel'] ?? info.data['soc_model']) as String?;
      } catch (_) {}
      if (socModel == null || socModel.isEmpty) {
        try {
          final res = await Process.run('getprop', ['ro.soc.model']);
          if (res.exitCode == 0 && (res.stdout as String).trim().isNotEmpty) {
            socModel = (res.stdout as String).trim();
          }
        } catch (_) {}
      }
    }

    // 1. Device Name (Nama HP)
    String effectiveBrand = brand.isNotEmpty && brand.toLowerCase() != 'unknown'
        ? brand
        : (manufacturer.isNotEmpty && manufacturer.toLowerCase() != 'unknown' ? manufacturer : '');
    final capBrand = _capitalize(effectiveBrand);

    String deviceName;
    if (Platform.isAndroid) {
      if (model.toLowerCase().startsWith(effectiveBrand.toLowerCase()) && effectiveBrand.isNotEmpty) {
        deviceName = model;
      } else if (model.isNotEmpty && model.toLowerCase() != 'unknown') {
        deviceName = capBrand.isNotEmpty ? '$capBrand $model' : model;
      } else {
        deviceName = capBrand.isNotEmpty ? capBrand : 'Android Device';
      }
    } else {
      deviceName = 'Desktop System';
    }

    // 2. Model HP (Model Code)
    String modelCode;
    if (Platform.isAndroid) {
      modelCode = model.isNotEmpty && model.toLowerCase() != 'unknown'
          ? model
          : (device.isNotEmpty ? device.toUpperCase() : 'Standard Model');
    } else {
      modelCode = 'PC / Workstation';
    }

    // 3. CPU (Processor)
    final cpuSoc = detectSocName(
      hardware: hardware,
      board: board,
      manufacturer: manufacturer,
      socModel: socModel,
    );

    // 4. GPU (Graphics)
    final gpu = detectGpuName(
      hardware: hardware,
      board: board,
      socName: cpuSoc,
    );

    // 5. RAM
    final ramMb = getTotalRamMb();
    final marketedRamGb = getMarketedRamGb(ramMb);

    // 6. Storage
    final storageData = await getStorageInfo();

    return {
      'deviceName': deviceName,
      'modelCode': modelCode,
      'cpu': cpuSoc,
      'gpu': gpu,
      'ram': '$marketedRamGb GB',
      'ramMb': ramMb,
      'storage': storageData['storage'] as String? ?? '256 GB',
      'storageFree': storageData['freeStr'] as String? ?? '142 GB',
      'storageDisplay': storageData['storageDisplay'] as String? ?? '256 GB',
      'cores': Platform.numberOfProcessors,
      // Backwards-compatible keys
      'model': model,
      'manufacturer': manufacturer,
      'hardware': hardware,
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
    try {
      if (Platform.isAndroid) {
        for (int i = 0; i < 5; i++) {
          final typeFile = File('/sys/class/thermal/thermal_zone$i/type');
          if (typeFile.existsSync()) {
            final type = typeFile.readAsStringSync().trim().toLowerCase();
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
    } catch (_) {}
    return 35.0; // Fallback normal temp
  }
}
