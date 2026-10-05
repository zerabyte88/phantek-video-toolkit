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

  static int _prevProcessTicks = 0;
  static int _prevSystemTimeMs = 0;

  /// Read real physical process memory usage (VmRSS) from Linux /proc filesystem on Android,
  /// falling back to ProcessInfo.currentRss.
  static int getProcessRssMb() {
    try {
      if (Platform.isAndroid) {
        final lines = File('/proc/self/status').readAsLinesSync();
        for (final line in lines) {
          if (line.startsWith('VmRSS:')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length > 1) {
              final kb = int.tryParse(parts[1]) ?? 0;
              if (kb > 0) return kb ~/ 1024;
            }
          }
        }
      }
    } catch (_) {}
    try {
      final rss = ProcessInfo.currentRss;
      if (rss > 0) return rss ~/ (1024 * 1024);
    } catch (_) {}
    return 0;
  }

  /// Calculate real CPU usage percentage of the current process (0.0 - 100.0%)
  /// by inspecting process utime + stime from Linux /proc/self/stat.
  static double getProcessCpuUsagePercent() {
    try {
      if (Platform.isAndroid) {
        final statStr = File('/proc/self/stat').readAsStringSync();
        final parts = statStr.trim().split(RegExp(r'\s+'));
        if (parts.length > 15) {
          final utime = int.tryParse(parts[13]) ?? 0;
          final stime = int.tryParse(parts[14]) ?? 0;
          final currentProcessTicks = utime + stime;
          final nowMs = DateTime.now().millisecondsSinceEpoch;

          if (_prevSystemTimeMs > 0 && _prevProcessTicks > 0) {
            final deltaTicks = currentProcessTicks - _prevProcessTicks;
            final deltaTimeMs = nowMs - _prevSystemTimeMs;
            if (deltaTimeMs > 0) {
              final cores =
                  Platform.numberOfProcessors > 0 ? Platform.numberOfProcessors : 8;
              // Linux USER_HZ is standard 100 ticks per second (1 tick = 10ms)
              final cpuPercent =
                  (deltaTicks / ((deltaTimeMs / 10.0) * cores)) * 100.0;
              _prevProcessTicks = currentProcessTicks;
              _prevSystemTimeMs = nowMs;
              return cpuPercent.clamp(0.0, 100.0);
            }
          }
          _prevProcessTicks = currentProcessTicks;
          _prevSystemTimeMs = nowMs;
        }
      }
    } catch (_) {}
    return 0.0;
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

  static String detectSocName({
    required String hardware,
    required String board,
    required String manufacturer,
    String? socModel,
  }) {
    final hwLower = hardware.toLowerCase();
    final boardLower = board.toLowerCase();
    final socLower = (socModel ?? '').toLowerCase();

    // ----------------------------------------------------
    // Qualcomm Snapdragon SoCs
    // ----------------------------------------------------
    // Snapdragon 8 Series (Flagship)
    if (hwLower.contains('sm8850') || socLower.contains('sm8850') || socLower.contains('8 elite gen 5')) {
      return 'Qualcomm Snapdragon 8 Elite Gen 5';
    }
    if (hwLower.contains('sm8750') || socLower.contains('sm8750') || boardLower.contains('sun') || socLower.contains('8 elite')) {
      return 'Qualcomm Snapdragon 8 Elite';
    }
    if (hwLower.contains('sm8635') || socLower.contains('sm8635') || boardLower.contains('volcano')) {
      return 'Qualcomm Snapdragon 8s Gen 3';
    }
    if (hwLower.contains('sm8650') || socLower.contains('sm8650') || boardLower.contains('pineapple')) {
      return 'Qualcomm Snapdragon 8 Gen 3';
    }
    if (hwLower.contains('sm8550') || socLower.contains('sm8550') || boardLower.contains('kalama')) {
      return 'Qualcomm Snapdragon 8 Gen 2';
    }
    if (hwLower.contains('sm8475') || socLower.contains('sm8475')) return 'Qualcomm Snapdragon 8+ Gen 1';
    if (hwLower.contains('sm8450') || socLower.contains('sm8450') || boardLower.contains('taro')) return 'Qualcomm Snapdragon 8 Gen 1';
    if (hwLower.contains('sm8350') || socLower.contains('sm8350') || boardLower.contains('lahaina')) return 'Qualcomm Snapdragon 888';
    if (hwLower.contains('sm8250') || socLower.contains('sm8250') || boardLower.contains('kona')) return 'Qualcomm Snapdragon 865 / 870';
    if (hwLower.contains('sm8150-cf') || hwLower.contains('sm8150_cf') || socLower.contains('860')) return 'Qualcomm Snapdragon 860';
    if (hwLower.contains('sm8150') || socLower.contains('sm8150')) return 'Qualcomm Snapdragon 855';
    if (hwLower.contains('sdm845') || socLower.contains('sdm845')) return 'Qualcomm Snapdragon 845';
    if (hwLower.contains('msm8998') || socLower.contains('msm8998')) return 'Qualcomm Snapdragon 835';
    if (hwLower.contains('msm8996') || socLower.contains('msm8996')) return 'Qualcomm Snapdragon 820 / 821';

    // Snapdragon 7 Series (Upper Midrange)
    if (hwLower.contains('sm7675') || socLower.contains('sm7675')) return 'Qualcomm Snapdragon 7+ Gen 3';
    if (hwLower.contains('sm7635') || socLower.contains('sm7635')) return 'Qualcomm Snapdragon 7s Gen 3';
    if (hwLower.contains('sm7550') || socLower.contains('sm7550')) return 'Qualcomm Snapdragon 7 Gen 3';
    if (hwLower.contains('sm7475') || socLower.contains('sm7475')) return 'Qualcomm Snapdragon 7+ Gen 2';
    if (hwLower.contains('sm7450') || socLower.contains('sm7450')) return 'Qualcomm Snapdragon 7 Gen 1';
    if (hwLower.contains('sm7435') ||
        socLower.contains('sm7435') ||
        hwLower.contains('sm6450') ||
        socLower.contains('sm6450') ||
        boardLower.contains('crow')) {
      return 'Qualcomm Snapdragon 7s Gen 2';
    }
    if (hwLower.contains('sm7350') || socLower.contains('sm7350')) return 'Qualcomm Snapdragon 780G';
    if (hwLower.contains('sm7325-af') || socLower.contains('782g')) return 'Qualcomm Snapdragon 782G';
    if (hwLower.contains('sm7325') || socLower.contains('sm7325') || boardLower.contains('yupik')) return 'Qualcomm Snapdragon 778G';
    if (hwLower.contains('sm7250-ac') || socLower.contains('768g')) return 'Qualcomm Snapdragon 768G';
    if (hwLower.contains('sm7250') || socLower.contains('sm7250') || boardLower.contains('lito')) return 'Qualcomm Snapdragon 765G';
    if (hwLower.contains('sm7225') || socLower.contains('sm7225')) return 'Qualcomm Snapdragon 750G';
    if (hwLower.contains('sm7150-ac') || socLower.contains('732g')) return 'Qualcomm Snapdragon 732G';
    if (hwLower.contains('sm7150') || socLower.contains('sm7150')) return 'Qualcomm Snapdragon 730G';
    if (hwLower.contains('sm7125') || socLower.contains('sm7125') || boardLower.contains('atoll')) return 'Qualcomm Snapdragon 720G';
    if (hwLower.contains('sdm712') || socLower.contains('sdm712')) return 'Qualcomm Snapdragon 712';
    if (hwLower.contains('sdm710') || socLower.contains('sdm710')) return 'Qualcomm Snapdragon 710';

    // Snapdragon 6 Series (Midrange)
    if (hwLower.contains('sm6475') || socLower.contains('sm6475')) return 'Qualcomm Snapdragon 6 Gen 3';
    if (socLower.contains('6s gen 3')) return 'Qualcomm Snapdragon 6s Gen 3';
    if (hwLower.contains('sm6375') || socLower.contains('sm6375') || boardLower.contains('holi')) return 'Qualcomm Snapdragon 695 5G';
    if (hwLower.contains('sm6350') || socLower.contains('sm6350')) return 'Qualcomm Snapdragon 690 5G';
    if (hwLower.contains('sm6225-ad') ||
        hwLower.contains('sm6225_ad') ||
        socLower.contains('sm6225-ad') ||
        socLower.contains('sm6225_ad') ||
        socLower.contains('685')) {
      return 'Qualcomm Snapdragon 685';
    }
    if (hwLower.contains('sm6225') || socLower.contains('sm6225') || boardLower.contains('khaje')) return 'Qualcomm Snapdragon 680';
    if (hwLower.contains('sm6150') || socLower.contains('sm6150')) return 'Qualcomm Snapdragon 675';
    if (hwLower.contains('sdm670') || socLower.contains('sdm670')) return 'Qualcomm Snapdragon 670';
    if (hwLower.contains('sm6125') || socLower.contains('sm6125') || boardLower.contains('trinket')) return 'Qualcomm Snapdragon 665';
    if (hwLower.contains('sm6115') || socLower.contains('sm6115')) {
      if (socLower.contains('678')) return 'Qualcomm Snapdragon 678';
      return 'Qualcomm Snapdragon 662';
    }
    if (boardLower.contains('bengal')) return 'Qualcomm Snapdragon 662';
    if (hwLower.contains('sdm660') || socLower.contains('sdm660')) return 'Qualcomm Snapdragon 660';
    if (hwLower.contains('sdm636') || socLower.contains('sdm636')) return 'Qualcomm Snapdragon 636';
    if (hwLower.contains('sdm632') || socLower.contains('sdm632')) return 'Qualcomm Snapdragon 632';
    if (hwLower.contains('sdm630') || socLower.contains('sdm630')) return 'Qualcomm Snapdragon 630';
    if (hwLower.contains('msm8953-pro') || socLower.contains('626')) return 'Qualcomm Snapdragon 626';
    if (hwLower.contains('msm8953') || socLower.contains('msm8953')) return 'Qualcomm Snapdragon 625';

    // Snapdragon 4 Series (Budget)
    if (hwLower.contains('sm4635') || socLower.contains('sm4635')) return 'Qualcomm Snapdragon 4s Gen 2';
    if (hwLower.contains('sm4450') || socLower.contains('sm4450')) return 'Qualcomm Snapdragon 4 Gen 2';
    if (hwLower.contains('sm4375') || socLower.contains('sm4375')) return 'Qualcomm Snapdragon 4 Gen 1';
    if (hwLower.contains('sm4350') || socLower.contains('sm4350')) return 'Qualcomm Snapdragon 480 5G';
    if (hwLower.contains('sm4250') || socLower.contains('sm4250')) return 'Qualcomm Snapdragon 460';
    if (hwLower.contains('sdm450') || socLower.contains('sdm450')) return 'Qualcomm Snapdragon 450';
    if (hwLower.contains('sdm439') || socLower.contains('sdm439')) return 'Qualcomm Snapdragon 439';
    if (hwLower.contains('msm8940') || hwLower.contains('msm8937') || socLower.contains('msm8937')) {
      return 'Qualcomm Snapdragon 430 / 435';
    }

    // ----------------------------------------------------
    // MediaTek Dimensity & Helio SoCs
    // ----------------------------------------------------
    if (hwLower.contains('mt6995') || socLower.contains('mt6995') || socLower.contains('9600')) {
      return 'MediaTek Dimensity 9600';
    }
    if (hwLower.contains('mt6993') || socLower.contains('mt6993') || socLower.contains('9500')) {
      return 'MediaTek Dimensity 9500';
    }
    if (hwLower.contains('mt6991') || socLower.contains('mt6991') || boardLower.contains('mt6991')) {
      return 'MediaTek Dimensity 9400';
    }
    if (hwLower.contains('mt6989') || socLower.contains('mt6989') || boardLower.contains('mt6989')) {
      return 'MediaTek Dimensity 9300';
    }
    if (hwLower.contains('mt6985') || socLower.contains('mt6985') || boardLower.contains('mt6985')) {
      return 'MediaTek Dimensity 9200';
    }
    if (hwLower.contains('mt6983') || socLower.contains('mt6983') || boardLower.contains('mt6983')) {
      return 'MediaTek Dimensity 9000';
    }
    if (hwLower.contains('mt6899') || socLower.contains('mt6899') || boardLower.contains('mt6899')) {
      return 'MediaTek Dimensity 8400';
    }
    if (hwLower.contains('mt6897') || socLower.contains('mt6897') || boardLower.contains('mt6897')) {
      return 'MediaTek Dimensity 8300';
    }
    if (hwLower.contains('mt6896') || socLower.contains('mt6896') || boardLower.contains('mt6896')) {
      return 'MediaTek Dimensity 8200';
    }
    if (hwLower.contains('mt6895') || socLower.contains('mt6895') || boardLower.contains('mt6895')) {
      return 'MediaTek Dimensity 8100';
    }
    if (hwLower.contains('mt6893') || socLower.contains('mt6893') || boardLower.contains('mt6893')) {
      return 'MediaTek Dimensity 1200 / 8050';
    }
    if (hwLower.contains('mt6891') || socLower.contains('mt6891') || boardLower.contains('mt6891')) {
      return 'MediaTek Dimensity 1100 / 8020';
    }
    if (hwLower.contains('mt6886') || socLower.contains('mt6886') || boardLower.contains('mt6886')) {
      return 'MediaTek Dimensity 7200';
    }
    if (hwLower.contains('mt6878') || socLower.contains('mt6878') || boardLower.contains('mt6878')) {
      return 'MediaTek Dimensity 7300';
    }
    if (hwLower.contains('mt6877v') || socLower.contains('7050')) {
      return 'MediaTek Dimensity 7050';
    }
    if (hwLower.contains('mt6877') || socLower.contains('mt6877') || boardLower.contains('mt6877')) {
      return 'MediaTek Dimensity 7050 / 1080 / 900';
    }
    if (hwLower.contains('mt6855') || socLower.contains('mt6855') || boardLower.contains('mt6855')) {
      return 'MediaTek Dimensity 7020 / 7025';
    }
    if (hwLower.contains('mt6853') || socLower.contains('mt6853') || boardLower.contains('mt6853')) {
      return 'MediaTek Dimensity 720';
    }
    if (hwLower.contains('mt6835') || socLower.contains('mt6835') || boardLower.contains('mt6835')) {
      return 'MediaTek Dimensity 6300 / 6100+';
    }
    if (hwLower.contains('mt6833p') || socLower.contains('6080') || socLower.contains('810')) {
      return 'MediaTek Dimensity 6080 / 810';
    }
    if (hwLower.contains('mt6833') || socLower.contains('mt6833') || boardLower.contains('mt6833')) {
      return 'MediaTek Dimensity 700 / 6020';
    }
    if (hwLower.contains('mt6789') || socLower.contains('mt6789') || boardLower.contains('mt6789')) {
      return 'MediaTek Helio G99 / G100';
    }
    if (hwLower.contains('mt6785') || hwLower.contains('mt6781') || socLower.contains('mt6785')) {
      return 'MediaTek Helio G90 / G95';
    }
    if (hwLower.contains('mt6769') || socLower.contains('mt6769')) return 'MediaTek Helio G80 / G85';
    if (hwLower.contains('mt6768') || socLower.contains('mt6768')) return 'MediaTek Helio P65';
    if (hwLower.contains('mt6765') || socLower.contains('mt6765')) return 'MediaTek Helio P35 / G35';
    if (hwLower.contains('mt6762') || socLower.contains('mt6762')) return 'MediaTek Helio P22 / G25';

    // ----------------------------------------------------
    // Samsung Exynos SoCs
    // ----------------------------------------------------
    if (hwLower.contains('s5e9955') || socLower.contains('s5e9955') || boardLower.contains('erd9955')) {
      return 'Samsung Exynos 2500';
    }
    if (hwLower.contains('s5e9945') || socLower.contains('s5e9945') || boardLower.contains('erd9945')) {
      return 'Samsung Exynos 2400';
    }
    if (hwLower.contains('s5e9925') || socLower.contains('s5e9925') || boardLower.contains('erd9925')) {
      return 'Samsung Exynos 2200';
    }
    if (hwLower.contains('s5e9840') || socLower.contains('s5e9840')) return 'Samsung Exynos 2100';
    if (hwLower.contains('s5e8855') || socLower.contains('s5e8855')) return 'Samsung Exynos 1580';
    if (hwLower.contains('s5e8845') || socLower.contains('s5e8845')) return 'Samsung Exynos 1480';
    if (hwLower.contains('s5e8835') || socLower.contains('s5e8835')) return 'Samsung Exynos 1380';
    if (hwLower.contains('s5e8535') || socLower.contains('s5e8535')) return 'Samsung Exynos 1330';
    if (hwLower.contains('s5e8825') || socLower.contains('s5e8825')) return 'Samsung Exynos 1280';
    if (hwLower.contains('s5e3830') || socLower.contains('s5e3830')) return 'Samsung Exynos 850';
    if (hwLower.contains('universal990') || socLower.contains('universal990')) return 'Samsung Exynos 990';
    if (hwLower.contains('universal9825') || hwLower.contains('universal9820') || socLower.contains('universal9820')) {
      return 'Samsung Exynos 9820';
    }
    if (hwLower.contains('universal9810') || socLower.contains('universal9810')) return 'Samsung Exynos 9810';
    if (hwLower.contains('universal9611') || hwLower.contains('universal9610') || socLower.contains('universal9611')) {
      return 'Samsung Exynos 9611';
    }

    // ----------------------------------------------------
    // Google Tensor SoCs
    // ----------------------------------------------------
    if (boardLower.contains('laguna') || boardLower.contains('frankel') || socLower.contains('tensor g5')) {
      return 'Google Tensor G5';
    }
    if (boardLower.contains('zumapro') || socLower.contains('tensor g4')) return 'Google Tensor G4';
    if (boardLower.contains('zuma') || socLower.contains('tensor g3')) return 'Google Tensor G3';
    if (boardLower.contains('gs201') || boardLower.contains('cloudripper') || socLower.contains('tensor g2')) {
      return 'Google Tensor G2';
    }
    if (boardLower.contains('gs101') || boardLower.contains('whitechapel') || socLower.contains('tensor')) {
      return 'Google Tensor';
    }

    // ----------------------------------------------------
    // Unisoc SoCs (64-bit)
    // ----------------------------------------------------
    if (hwLower.contains('ums9620') ||
        socLower.contains('ums9620') ||
        boardLower.contains('t820') ||
        socLower.contains('t820') ||
        socLower.contains('t8200')) {
      return 'Unisoc T820';
    }
    if (hwLower.contains('ums512t') || socLower.contains('t770') || boardLower.contains('t770')) {
      return 'Unisoc T770';
    }
    if (hwLower.contains('t765') || socLower.contains('t765') || boardLower.contains('t765')) {
      return 'Unisoc T765';
    }
    if (hwLower.contains('t760') || socLower.contains('t760') || boardLower.contains('t760')) {
      return 'Unisoc T760';
    }
    if (hwLower.contains('t7510') || socLower.contains('t7510') || boardLower.contains('t7510')) {
      return 'Unisoc T7510';
    }
    if (hwLower.contains('t750') || socLower.contains('t750') || boardLower.contains('t750')) {
      return 'Unisoc T750';
    }
    if (hwLower.contains('t620') || socLower.contains('t620') || boardLower.contains('t620')) {
      return 'Unisoc T620';
    }
    if (hwLower.contains('t619') || socLower.contains('t619') || boardLower.contains('t619')) {
      return 'Unisoc T619';
    }
    if (hwLower.contains('t618') || socLower.contains('t618') || boardLower.contains('t618')) {
      return 'Unisoc T618';
    }
    if (hwLower.contains('t616') || socLower.contains('t616') || boardLower.contains('t616')) {
      return 'Unisoc T616';
    }
    if (hwLower.contains('t612') || socLower.contains('t612') || boardLower.contains('t612')) {
      return 'Unisoc T612';
    }
    if (hwLower.contains('t610') || socLower.contains('t610') || boardLower.contains('t610')) {
      return 'Unisoc T610';
    }
    if (hwLower.contains('t606') || socLower.contains('t606') || boardLower.contains('t606')) {
      return 'Unisoc T606';
    }
    if (hwLower.contains('t603') || socLower.contains('t603') || boardLower.contains('t603')) {
      return 'Unisoc T603';
    }
    if (hwLower.contains('sc9863a') || hwLower.contains('sp9863a') || socLower.contains('sc9863a')) {
      return 'Unisoc SC9863A';
    }
    if (hwLower.contains('ums9230') || socLower.contains('ums9230')) {
      return 'Unisoc T606 / T616';
    }
    if (hwLower.contains('ums512') || socLower.contains('ums512')) {
      return 'Unisoc T618 / T610';
    }

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

    // --- Samsung Exynos Family ---
    if (s.contains('exynos') || h.contains('s5e') || h.contains('universal')) {
      if (s.contains('2500') || h.contains('s5e9955')) return 'Samsung Xclipse 950';
      if (s.contains('2400') || h.contains('s5e9945')) return 'Samsung Xclipse 940';
      if (s.contains('2200') || h.contains('s5e9925')) return 'Samsung Xclipse 920';
      if (s.contains('2100') || h.contains('s5e9840')) return 'Mali-G78 MP14';
      if (s.contains('1580') || h.contains('s5e8855')) return 'Samsung Xclipse 540';
      if (s.contains('1480') || h.contains('s5e8845')) return 'Samsung Xclipse 530';
      if (s.contains('1380') || h.contains('s5e8835')) return 'Mali-G68 MP5';
      if (s.contains('1330') || h.contains('s5e8535')) return 'Mali-G68 MP2';
      if (s.contains('1280') || h.contains('s5e8825')) return 'Mali-G68 MP4';
      if (s.contains('850') || h.contains('s5e3830')) return 'Mali-G52 MP1';
      if (s.contains('990') || h.contains('universal990')) return 'Mali-G77 MP11';
      if (s.contains('9820') || s.contains('9825') || h.contains('universal9820') || h.contains('universal9825')) {
        return 'Mali-G76 MP12';
      }
      if (s.contains('9810') || h.contains('universal9810')) return 'Mali-G72 MP18';
      if (s.contains('9611') || s.contains('9610') || h.contains('universal9611') || h.contains('universal9610')) {
        return 'Mali-G72 MP3';
      }
      return 'ARM Mali / Xclipse GPU';
    }

    // --- Google Tensor Family ---
    if (s.contains('tensor') || b.contains('laguna') || b.contains('frankel') || b.contains('zuma') || b.contains('gs')) {
      if (b.contains('laguna') || b.contains('frankel') || s.contains('tensor g5')) return 'IMG D-Series GPU';
      if (b.contains('zumapro') || s.contains('tensor g4')) return 'Mali-G715';
      if (b.contains('zuma') || s.contains('tensor g3')) return 'Immortalis-G715s';
      if (b.contains('gs201') || s.contains('tensor g2')) return 'Mali-G710 MP7';
      if (b.contains('gs101') || s.contains('tensor')) return 'Mali-G78 MP20';
      return 'ARM Mali GPU';
    }

    // --- Unisoc Family ---
    if (s.contains('unisoc') || h.contains('ums') || b.contains('t820') || b.contains('t760') || b.contains('t750')) {
      if (s.contains('t820') ||
          s.contains('t770') ||
          s.contains('t765') ||
          s.contains('t760') ||
          h.contains('ums9620') ||
          h.contains('ums512t')) {
        return 'Mali-G57 MP4';
      }
      if (s.contains('t7510') || s.contains('t750')) return 'Mali-G57 MP2';
      if (s.contains('sc9863a') || s.contains('sp9863a')) return 'PowerVR Rogue GE8322';
      return 'Mali-G57 MP1';
    }

    // --- MediaTek Dimensity & Helio Family ---
    if (s.contains('mediatek') || s.contains('dimensity') || s.contains('helio') || h.startsWith('mt')) {
      if (s.contains('9600') || s.contains('9500') || s.contains('9400') || h.contains('mt6995') || h.contains('mt6993') || h.contains('mt6991')) {
        return 'Immortalis-G925 MC12';
      }
      if (s.contains('9300') || h.contains('mt6989')) return 'Immortalis-G720 MC12';
      if (s.contains('9200') || h.contains('mt6985')) return 'Immortalis-G715 MC11';
      if (s.contains('9000') || h.contains('mt6983')) return 'Mali-G710 MC10';
      if (s.contains('8400') || h.contains('mt6899')) return 'Mali-G720 MC7';
      if (s.contains('8300') || h.contains('mt6897')) return 'Mali-G615 MC6';
      if (s.contains('8100') || s.contains('8200') || h.contains('mt6895') || h.contains('mt6896')) return 'Mali-G610 MC6';
      if (s.contains('8050') || s.contains('8020') || s.contains('1300') || s.contains('1200') || s.contains('1100') || h.contains('mt6893') || h.contains('mt6891')) {
        return 'Mali-G77 MC9';
      }
      if (s.contains('7300') || h.contains('mt6878')) return 'Mali-G615 MC2';
      if (s.contains('7200') || h.contains('mt6886')) return 'Mali-G610 MC4';
      if (s.contains('7050') || s.contains('1080') || s.contains('920') || s.contains('900') || h.contains('mt6877')) {
        return 'Mali-G68 MC4';
      }
      if (s.contains('7020') || s.contains('7025') || s.contains('930') || h.contains('mt6855')) return 'IMG BXM-8-256';
      if (s.contains('720') || h.contains('mt6853')) return 'Mali-G57 MC3';
      if (s.contains('700') ||
          s.contains('6080') ||
          s.contains('6020') ||
          s.contains('6300') ||
          s.contains('6100') ||
          s.contains('810') ||
          s.contains('g99') ||
          s.contains('g100') ||
          h.contains('mt6833') ||
          h.contains('mt6835') ||
          h.contains('mt6789')) {
        return 'Mali-G57 MC2';
      }
      if (s.contains('g96') || s.contains('g95') || s.contains('g90') || h.contains('mt6785') || h.contains('mt6781')) {
        return 'Mali-G76 MC4';
      }
      if (s.contains('g88') || s.contains('g85') || s.contains('g80') || h.contains('mt6769')) return 'Mali-G52 MC2';
      if (s.contains('p35') || s.contains('g35') || s.contains('g37') || s.contains('g36') || s.contains('g25') || s.contains('p22') || h.contains('mt6765') || h.contains('mt6762')) {
        return 'PowerVR GE8320';
      }
      return 'ARM Mali GPU';
    }

    // --- Qualcomm Snapdragon Family ---
    if (s.contains('snapdragon') || h.contains('sm') || h.contains('sdm') || h.contains('msm') || h.contains('qcom')) {
      if (s.contains('8 elite') || h.contains('sm8850') || h.contains('sm8750') || b.contains('sun')) return 'Adreno 830';
      if (s.contains('8s gen 3') || h.contains('sm8635') || b.contains('volcano')) return 'Adreno 735';
      if (s.contains('8 gen 3') || h.contains('sm8650') || b.contains('pineapple')) return 'Adreno 750';
      if (s.contains('8 gen 2') || h.contains('sm8550') || b.contains('kalama')) return 'Adreno 740';
      if (s.contains('8+ gen 1') || s.contains('8 gen 1') || h.contains('sm8475') || h.contains('sm8450')) return 'Adreno 730';
      if (s.contains('888') || h.contains('sm8350')) return 'Adreno 660';
      if (s.contains('865') || s.contains('870') || h.contains('sm8250')) return 'Adreno 650';
      if (s.contains('860') || s.contains('855') || h.contains('sm8150')) return 'Adreno 640';
      if (s.contains('845') || h.contains('sdm845')) return 'Adreno 630';
      if (s.contains('835') || h.contains('msm8998')) return 'Adreno 540';
      if (s.contains('820') || s.contains('821') || h.contains('msm8996')) return 'Adreno 530';
      if (s.contains('7+ gen 3') || h.contains('sm7675')) return 'Adreno 732';
      if (s.contains('7s gen 3') || h.contains('sm7635')) return 'Adreno 810';
      if (s.contains('7 gen 3') || h.contains('sm7550')) return 'Adreno 720';
      if (s.contains('7+ gen 2') || h.contains('sm7475')) return 'Adreno 725';
      if (s.contains('7s gen 2') || h.contains('sm7435') || h.contains('sm6450') || b.contains('crow')) return 'Adreno 710';
      if (s.contains('782g') || s.contains('780g') || s.contains('778g') || h.contains('sm7350') || h.contains('sm7325')) {
        return 'Adreno 642L';
      }
      if (s.contains('768g') || s.contains('765g') || h.contains('sm7250')) return 'Adreno 620';
      if (s.contains('750g') || h.contains('sm7225')) return 'Adreno 619';
      if (s.contains('732g') || s.contains('730g') || s.contains('730') || h.contains('sm7150')) return 'Adreno 618';
      if (s.contains('720g') || h.contains('sm7125')) return 'Adreno 618';
      if (s.contains('712') || s.contains('710') || h.contains('sdm712') || h.contains('sdm710')) return 'Adreno 616';
      if (s.contains('6 gen 3') || s.contains('6 gen 1') || h.contains('sm6475')) return 'Adreno 710';
      if (s.contains('6s gen 3') || s.contains('695') || s.contains('690') || h.contains('sm6375') || h.contains('sm6350')) {
        return 'Adreno 619';
      }
      if (s.contains('685') ||
          s.contains('680') ||
          s.contains('665') ||
          s.contains('662') ||
          h.contains('sm6225') ||
          h.contains('sm6125') ||
          h.contains('sm6115') ||
          b.contains('bengal')) {
        return 'Adreno 610';
      }
      if (s.contains('678') || s.contains('675') || h.contains('sm6150')) return 'Adreno 612';
      if (s.contains('670') || h.contains('sdm670')) return 'Adreno 615';
      if (s.contains('660') || h.contains('sdm660')) return 'Adreno 512';
      if (s.contains('636') || h.contains('sdm636')) return 'Adreno 509';
      if (s.contains('632') || s.contains('630') || s.contains('626') || s.contains('625') || h.contains('msm8953')) {
        return 'Adreno 506';
      }
      if (s.contains('4s gen 2') || h.contains('sm4635')) return 'Adreno 611';
      if (s.contains('4 gen 2') || h.contains('sm4450')) return 'Adreno 613';
      if (s.contains('4 gen 1') || s.contains('480') || h.contains('sm4375') || h.contains('sm4350')) return 'Adreno 619';
      if (s.contains('460') || h.contains('sm4250')) return 'Adreno 610';
      if (s.contains('450') || h.contains('sdm450')) return 'Adreno 506';
      if (s.contains('439') || s.contains('435') || s.contains('430')) return 'Adreno 505';
      return 'Qualcomm Adreno GPU';
    }

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
