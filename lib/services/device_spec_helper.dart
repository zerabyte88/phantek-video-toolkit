import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

enum DeviceTier {
  highEnd, // Tier 1
  midRange, // Tier 2
  lowEnd, // Tier 3
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
              final cores = Platform.numberOfProcessors > 0
                  ? Platform.numberOfProcessors
                  : 8;
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
    final freeStr = freeGb >= 1.0
        ? '${freeGb.toStringAsFixed(0)} GB'
        : '$freeMb MB';

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
    final c = '$hwLower $boardLower $socLower';
    bool has(String k) => c.contains(k);

    // Qualcomm Snapdragon SoCs
    if (has('sm8850') || has('8 elite gen 5')) {
      return 'Qualcomm Snapdragon 8 Elite Gen 5';
    }
    if (has('sm8750') || has('sun') || has('8 elite')) {
      return 'Qualcomm Snapdragon 8 Elite';
    }
    if (has('sm8635') || has('volcano')) return 'Qualcomm Snapdragon 8s Gen 3';
    if (has('sm8650') || has('pineapple')) return 'Qualcomm Snapdragon 8 Gen 3';
    if (has('sm8550') || has('kalama')) return 'Qualcomm Snapdragon 8 Gen 2';
    if (has('sm8475')) return 'Qualcomm Snapdragon 8+ Gen 1';
    if (has('sm8450') || has('taro')) return 'Qualcomm Snapdragon 8 Gen 1';
    if (has('sm8350') || has('lahaina')) return 'Qualcomm Snapdragon 888';
    if (has('sm8250') || has('kona')) return 'Qualcomm Snapdragon 865 / 870';
    if (has('sm8150-cf') || has('sm8150_cf') || has('860')) {
      return 'Qualcomm Snapdragon 860';
    }
    if (has('sm8150')) return 'Qualcomm Snapdragon 855';
    if (has('sdm845')) return 'Qualcomm Snapdragon 845';
    if (has('msm8998')) return 'Qualcomm Snapdragon 835';
    if (has('msm8996')) return 'Qualcomm Snapdragon 820 / 821';

    if (has('sm7675')) return 'Qualcomm Snapdragon 7+ Gen 3';
    if (has('sm7635')) return 'Qualcomm Snapdragon 7s Gen 3';
    if (has('sm7550')) return 'Qualcomm Snapdragon 7 Gen 3';
    if (has('sm7475')) return 'Qualcomm Snapdragon 7+ Gen 2';
    if (has('sm7450')) return 'Qualcomm Snapdragon 7 Gen 1';
    if (has('sm7435') || has('sm6450') || has('crow')) {
      return 'Qualcomm Snapdragon 7s Gen 2';
    }
    if (has('sm7350')) return 'Qualcomm Snapdragon 780G';
    if (has('sm7325-af') || has('782g')) return 'Qualcomm Snapdragon 782G';
    if (has('sm7325') || has('yupik')) return 'Qualcomm Snapdragon 778G';
    if (has('sm7250-ac') || has('768g')) return 'Qualcomm Snapdragon 768G';
    if (has('sm7250') || has('lito')) return 'Qualcomm Snapdragon 765G';
    if (has('sm7225')) return 'Qualcomm Snapdragon 750G';
    if (has('sm7150-ac') || has('732g')) return 'Qualcomm Snapdragon 732G';
    if (has('sm7150')) return 'Qualcomm Snapdragon 730G';
    if (has('sm7125') || has('atoll')) return 'Qualcomm Snapdragon 720G';
    if (has('sdm712')) return 'Qualcomm Snapdragon 712';
    if (has('sdm710')) return 'Qualcomm Snapdragon 710';

    if (has('sm6475')) return 'Qualcomm Snapdragon 6 Gen 3';
    if (has('6s gen 3')) return 'Qualcomm Snapdragon 6s Gen 3';
    if (has('sm6375') || has('holi')) return 'Qualcomm Snapdragon 695 5G';
    if (has('sm6350')) return 'Qualcomm Snapdragon 690 5G';
    if (has('sm6225-ad') || has('sm6225_ad') || has('685')) {
      return 'Qualcomm Snapdragon 685';
    }
    if (has('sm6225') || has('khaje')) return 'Qualcomm Snapdragon 680';
    if (has('sm6150')) return 'Qualcomm Snapdragon 675';
    if (has('sdm670')) return 'Qualcomm Snapdragon 670';
    if (has('sm6125') || has('trinket')) return 'Qualcomm Snapdragon 665';
    if (has('sm6115')) {
      return has('678') ? 'Qualcomm Snapdragon 678' : 'Qualcomm Snapdragon 662';
    }
    if (has('bengal')) return 'Qualcomm Snapdragon 662';
    if (has('sdm660')) return 'Qualcomm Snapdragon 660';
    if (has('sdm636')) return 'Qualcomm Snapdragon 636';
    if (has('sdm632')) return 'Qualcomm Snapdragon 632';
    if (has('sdm630')) return 'Qualcomm Snapdragon 630';
    if (has('msm8953-pro') || has('626')) return 'Qualcomm Snapdragon 626';
    if (has('msm8953')) return 'Qualcomm Snapdragon 625';

    if (has('sm4635')) return 'Qualcomm Snapdragon 4s Gen 2';
    if (has('sm4450')) return 'Qualcomm Snapdragon 4 Gen 2';
    if (has('sm4375')) return 'Qualcomm Snapdragon 4 Gen 1';
    if (has('sm4350')) return 'Qualcomm Snapdragon 480 5G';
    if (has('sm4250')) return 'Qualcomm Snapdragon 460';
    if (has('sdm450')) return 'Qualcomm Snapdragon 450';
    if (has('sdm439')) return 'Qualcomm Snapdragon 439';
    if (has('msm8940') || has('msm8937')) {
      return 'Qualcomm Snapdragon 430 / 435';
    }

    // MediaTek Dimensity & Helio SoCs
    if (has('mt6995') || has('9600')) return 'MediaTek Dimensity 9600';
    if (has('mt6993') || has('9500')) return 'MediaTek Dimensity 9500';
    if (has('mt6991')) return 'MediaTek Dimensity 9400';
    if (has('mt6989')) return 'MediaTek Dimensity 9300';
    if (has('mt6985')) return 'MediaTek Dimensity 9200';
    if (has('mt6983')) return 'MediaTek Dimensity 9000';
    if (has('mt6899')) return 'MediaTek Dimensity 8400';
    if (has('mt6897')) return 'MediaTek Dimensity 8300';
    if (has('mt6896')) return 'MediaTek Dimensity 8200';
    if (has('mt6895')) return 'MediaTek Dimensity 8100';
    if (has('mt6893')) return 'MediaTek Dimensity 1200 / 8050';
    if (has('mt6891')) return 'MediaTek Dimensity 1100 / 8020';
    if (has('mt6886')) return 'MediaTek Dimensity 7200';
    if (has('mt6878')) return 'MediaTek Dimensity 7300';
    if (has('mt6877v') || has('7050')) return 'MediaTek Dimensity 7050';
    if (has('mt6877')) return 'MediaTek Dimensity 7050 / 1080 / 900';
    if (has('mt6855')) return 'MediaTek Dimensity 7020 / 7025';
    if (has('mt6853')) return 'MediaTek Dimensity 720';
    if (has('mt6835')) return 'MediaTek Dimensity 6300 / 6100+';
    if (has('mt6833p') || has('6080') || has('810')) {
      return 'MediaTek Dimensity 6080 / 810';
    }
    if (has('mt6833')) return 'MediaTek Dimensity 700 / 6020';
    if (has('mt6789')) return 'MediaTek Helio G99 / G100';
    if (has('mt6785') || has('mt6781')) return 'MediaTek Helio G90 / G95';
    if (has('mt6769')) return 'MediaTek Helio G80 / G85';
    if (has('mt6768')) return 'MediaTek Helio P65';
    if (has('mt6765')) return 'MediaTek Helio P35 / G35';
    if (has('mt6762')) return 'MediaTek Helio P22 / G25';

    // Samsung Exynos SoCs
    if (has('s5e9955') || has('erd9955')) return 'Samsung Exynos 2500';
    if (has('s5e9945') || has('erd9945')) return 'Samsung Exynos 2400';
    if (has('s5e9925') || has('erd9925')) return 'Samsung Exynos 2200';
    if (has('s5e9840')) return 'Samsung Exynos 2100';
    if (has('s5e8855')) return 'Samsung Exynos 1580';
    if (has('s5e8845')) return 'Samsung Exynos 1480';
    if (has('s5e8835')) return 'Samsung Exynos 1380';
    if (has('s5e8535')) return 'Samsung Exynos 1330';
    if (has('s5e8825')) return 'Samsung Exynos 1280';
    if (has('s5e3830')) return 'Samsung Exynos 850';
    if (has('universal990')) return 'Samsung Exynos 990';
    if (has('universal9825') || has('universal9820')) {
      return 'Samsung Exynos 9820';
    }
    if (has('universal9810')) return 'Samsung Exynos 9810';
    if (has('universal9611') || has('universal9610')) {
      return 'Samsung Exynos 9611';
    }

    // Google Tensor SoCs
    if (has('laguna') || has('frankel') || has('tensor g5')) {
      return 'Google Tensor G5';
    }
    if (has('zumapro') || has('tensor g4')) return 'Google Tensor G4';
    if (has('zuma') || has('tensor g3')) return 'Google Tensor G3';
    if (has('gs201') || has('cloudripper') || has('tensor g2')) {
      return 'Google Tensor G2';
    }
    if (has('gs101') || has('whitechapel') || has('tensor')) {
      return 'Google Tensor';
    }

    // Unisoc SoCs (64-bit)
    if (has('ums9620') || has('t820') || has('t8200')) return 'Unisoc T820';
    if (has('ums512t') || has('t770')) return 'Unisoc T770';
    if (has('t765')) return 'Unisoc T765';
    if (has('t760')) return 'Unisoc T760';
    if (has('t7510')) return 'Unisoc T7510';
    if (has('t750')) return 'Unisoc T750';
    if (has('t620')) return 'Unisoc T620';
    if (has('t619')) return 'Unisoc T619';
    if (has('t618')) return 'Unisoc T618';
    if (has('t616')) return 'Unisoc T616';
    if (has('t612')) return 'Unisoc T612';
    if (has('t610')) return 'Unisoc T610';
    if (has('t606')) return 'Unisoc T606';
    if (has('t603')) return 'Unisoc T603';
    if (has('sc9863a') || has('sp9863a')) return 'Unisoc SC9863A';
    if (has('ums9230')) return 'Unisoc T606 / T616';
    if (has('ums512')) return 'Unisoc T618 / T610';

    // Android device sysfs / procfs fallback for unlisted chipsets
    if (Platform.isAndroid) {
      // 1. Try reading /sys/devices/soc0/machine
      try {
        final machineFile = File('/sys/devices/soc0/machine');
        if (machineFile.existsSync()) {
          final machine = machineFile.readAsStringSync().trim();
          if (machine.isNotEmpty &&
              !machine.toLowerCase().contains('unknown')) {
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

    if (hwLower.startsWith('sdm') ||
        hwLower.startsWith('msm') ||
        hwLower.startsWith('sm')) {
      return 'Qualcomm Snapdragon ${hardware.toUpperCase()}';
    }
    if (hwLower.contains('qcom')) return 'Qualcomm Snapdragon';
    if (hwLower.startsWith('mt')) return 'MediaTek ${hardware.toUpperCase()}';
    if (hwLower.contains('exynos') || boardLower.contains('exynos')) {
      return 'Samsung Exynos';
    }

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

            final adrenoMatch = RegExp(
              r'^adreno\s*(\d+)(.*)$',
              caseSensitive: false,
            ).firstMatch(model);
            if (adrenoMatch != null) {
              return 'Adreno ${adrenoMatch.group(1)}';
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
    final c = '$s $h $b';
    bool has(String k) => c.contains(k);

    // --- Samsung Exynos Family ---
    if (s.contains('exynos') || h.contains('s5e') || h.contains('universal')) {
      if (has('2500') || has('s5e9955')) return 'Samsung Xclipse 950';
      if (has('2400') || has('s5e9945')) return 'Samsung Xclipse 940';
      if (has('2200') || has('s5e9925')) return 'Samsung Xclipse 920';
      if (has('2100') || has('s5e9840')) return 'Mali-G78 MP14';
      if (has('1580') || has('s5e8855')) return 'Samsung Xclipse 540';
      if (has('1480') || has('s5e8845')) return 'Samsung Xclipse 530';
      if (has('1380') || has('s5e8835')) return 'Mali-G68 MP5';
      if (has('1330') || has('s5e8535')) return 'Mali-G68 MP2';
      if (has('1280') || has('s5e8825')) return 'Mali-G68 MP4';
      if (has('850') || has('s5e3830')) return 'Mali-G52 MP1';
      if (has('990') || has('universal990')) return 'Mali-G77 MP11';
      if (has('9820') ||
          has('9825') ||
          has('universal9820') ||
          has('universal9825')) {
        return 'Mali-G76 MP12';
      }
      if (has('9810') || has('universal9810')) return 'Mali-G72 MP18';
      if (has('9611') ||
          has('9610') ||
          has('universal9611') ||
          has('universal9610')) {
        return 'Mali-G72 MP3';
      }
      return 'ARM Mali / Xclipse GPU';
    }

    // --- Google Tensor Family ---
    if (s.contains('tensor') ||
        b.contains('laguna') ||
        b.contains('frankel') ||
        b.contains('zuma') ||
        b.contains('gs')) {
      if (has('laguna') || has('frankel') || has('tensor g5')) {
        return 'IMG D-Series GPU';
      }
      if (has('zumapro') || has('tensor g4')) return 'Mali-G715';
      if (has('zuma') || has('tensor g3')) return 'Immortalis-G715s';
      if (has('gs201') || has('tensor g2')) return 'Mali-G710 MP7';
      if (has('gs101') || has('tensor')) return 'Mali-G78 MP20';
      return 'ARM Mali GPU';
    }

    // --- Unisoc Family ---
    if (s.contains('unisoc') ||
        h.contains('ums') ||
        b.contains('t820') ||
        b.contains('t760') ||
        b.contains('t750')) {
      if (has('t820') ||
          has('t770') ||
          has('t765') ||
          has('t760') ||
          has('ums9620') ||
          has('ums512t')) {
        return 'Mali-G57 MP4';
      }
      if (has('t7510') || has('t750')) return 'Mali-G57 MP2';
      if (has('sc9863a') || has('sp9863a')) return 'PowerVR Rogue GE8322';
      return 'Mali-G57 MP1';
    }

    // --- MediaTek Dimensity & Helio Family ---
    if (s.contains('mediatek') ||
        s.contains('dimensity') ||
        s.contains('helio') ||
        h.startsWith('mt')) {
      if (has('9600') ||
          has('9500') ||
          has('9400') ||
          has('mt6995') ||
          has('mt6993') ||
          has('mt6991')) {
        return 'Immortalis-G925 MC12';
      }
      if (has('9300') || has('mt6989')) return 'Immortalis-G720 MC12';
      if (has('9200') || has('mt6985')) return 'Immortalis-G715 MC11';
      if (has('9000') || has('mt6983')) return 'Mali-G710 MC10';
      if (has('8400') || has('mt6899')) return 'Mali-G720 MC7';
      if (has('8300') || has('mt6897')) return 'Mali-G615 MC6';
      if (has('8100') || has('8200') || has('mt6895') || has('mt6896')) {
        return 'Mali-G610 MC6';
      }
      if (has('8050') ||
          has('8020') ||
          has('1300') ||
          has('1200') ||
          has('1100') ||
          has('mt6893') ||
          has('mt6891')) {
        return 'Mali-G77 MC9';
      }
      if (has('7300') || has('mt6878')) return 'Mali-G615 MC2';
      if (has('7200') || has('mt6886')) return 'Mali-G610 MC4';
      if (has('7050') ||
          has('1080') ||
          has('920') ||
          has('900') ||
          has('mt6877')) {
        return 'Mali-G68 MC4';
      }
      if (has('7020') || has('7025') || has('930') || has('mt6855')) {
        return 'IMG BXM-8-256';
      }
      if (has('720') || has('mt6853')) return 'Mali-G57 MC3';
      if (has('700') ||
          has('6080') ||
          has('6020') ||
          has('6300') ||
          has('6100') ||
          has('810') ||
          has('g99') ||
          has('g100') ||
          has('mt6833') ||
          has('mt6835') ||
          has('mt6789')) {
        return 'Mali-G57 MC2';
      }
      if (has('g96') ||
          has('g95') ||
          has('g90') ||
          has('mt6785') ||
          has('mt6781')) {
        return 'Mali-G76 MC4';
      }
      if (has('g88') || has('g85') || has('g80') || has('mt6769')) {
        return 'Mali-G52 MC2';
      }
      if (has('p35') ||
          has('g35') ||
          has('g37') ||
          has('g36') ||
          has('g25') ||
          has('p22') ||
          has('mt6765') ||
          has('mt6762')) {
        return 'PowerVR GE8320';
      }
      return 'ARM Mali GPU';
    }

    // --- Qualcomm Snapdragon Family ---
    if (s.contains('snapdragon') ||
        h.contains('sm') ||
        h.contains('sdm') ||
        h.contains('msm') ||
        h.contains('qcom')) {
      if (has('8 elite') ||
          has('sm8850') ||
          has('sm8750') ||
          b.contains('sun')) {
        return 'Adreno 830';
      }
      if (has('8s gen 3') || has('sm8635') || b.contains('volcano')) {
        return 'Adreno 735';
      }
      if (has('8 gen 3') || has('sm8650') || b.contains('pineapple')) {
        return 'Adreno 750';
      }
      if (has('8 gen 2') || has('sm8550') || b.contains('kalama')) {
        return 'Adreno 740';
      }
      if (has('8+ gen 1') || has('8 gen 1') || has('sm8475') || has('sm8450')) {
        return 'Adreno 730';
      }
      if (has('888') || has('sm8350')) return 'Adreno 660';
      if (has('865') || has('870') || has('sm8250')) return 'Adreno 650';
      if (has('860') || has('855') || has('sm8150')) return 'Adreno 640';
      if (has('845') || has('sdm845')) return 'Adreno 630';
      if (has('835') || has('msm8998')) return 'Adreno 540';
      if (has('820') || has('821') || has('msm8996')) return 'Adreno 530';
      if (has('7+ gen 3') || has('sm7675')) return 'Adreno 732';
      if (has('7s gen 3') || has('sm7635')) return 'Adreno 810';
      if (has('7 gen 3') || has('sm7550')) return 'Adreno 720';
      if (has('7+ gen 2') || has('sm7475')) return 'Adreno 725';
      if (has('7s gen 2') ||
          has('sm7435') ||
          has('sm6450') ||
          b.contains('crow')) {
        return 'Adreno 710';
      }
      if (has('782g') ||
          has('780g') ||
          has('778g') ||
          has('sm7350') ||
          has('sm7325')) {
        return 'Adreno 642L';
      }
      if (has('768g') || has('765g') || has('sm7250')) return 'Adreno 620';
      if (has('750g') || has('sm7225')) return 'Adreno 619';
      if (has('732g') || has('730g') || has('730') || has('sm7150')) {
        return 'Adreno 618';
      }
      if (has('720g') || has('sm7125')) return 'Adreno 618';
      if (has('712') || has('710') || has('sdm712') || has('sdm710')) {
        return 'Adreno 616';
      }
      if (has('6 gen 3') || has('6 gen 1') || has('sm6475')) {
        return 'Adreno 710';
      }
      if (has('6s gen 3') ||
          has('695') ||
          has('690') ||
          has('sm6375') ||
          has('sm6350')) {
        return 'Adreno 619';
      }
      if (has('685') ||
          has('680') ||
          has('665') ||
          has('662') ||
          has('sm6225') ||
          has('sm6125') ||
          has('sm6115') ||
          b.contains('bengal')) {
        return 'Adreno 610';
      }
      if (has('678') || has('675') || has('sm6150')) return 'Adreno 612';
      if (has('670') || has('sdm670')) return 'Adreno 615';
      if (has('660') || has('sdm660')) return 'Adreno 512';
      if (has('636') || has('sdm636')) return 'Adreno 509';
      if (has('632') ||
          has('630') ||
          has('626') ||
          has('625') ||
          has('msm8953')) {
        return 'Adreno 506';
      }
      if (has('4s gen 2') || has('sm4635')) return 'Adreno 611';
      if (has('4 gen 2') || has('sm4450')) return 'Adreno 613';
      if (has('4 gen 1') || has('480') || has('sm4375') || has('sm4350')) {
        return 'Adreno 619';
      }
      if (has('460') || has('sm4250')) return 'Adreno 610';
      if (has('450') || has('sdm450')) return 'Adreno 506';
      if (has('439') || has('435') || has('430')) return 'Adreno 505';
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
        : (manufacturer.isNotEmpty && manufacturer.toLowerCase() != 'unknown'
              ? manufacturer
              : '');
    final capBrand = _capitalize(effectiveBrand);

    String deviceName;
    if (Platform.isAndroid) {
      if (model.toLowerCase().startsWith(effectiveBrand.toLowerCase()) &&
          effectiveBrand.isNotEmpty) {
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
