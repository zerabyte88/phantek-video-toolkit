import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import '../models/video_info.dart';

enum DeviceTier {
  highEnd, // Tier 1
  midRange, // Tier 2
  lowEnd, // Tier 3
}

class SocDescription {
  final String displayName;
  final bool isPrecise;
  final String rawName;
  final int coreCount;
  final String? socModel;
  final String? hardware;
  final String? board;
  final String? manufacturer;
  final String? brand;

  const SocDescription({
    required this.displayName,
    required this.isPrecise,
    required this.rawName,
    required this.coreCount,
    this.socModel,
    this.hardware,
    this.board,
    this.manufacturer,
    this.brand,
  });

  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    'isPrecise': isPrecise,
    'rawName': rawName,
    'coreCount': coreCount,
    if (socModel != null) 'socModel': socModel,
    if (hardware != null) 'hardware': hardware,
    if (board != null) 'board': board,
    if (manufacturer != null) 'manufacturer': manufacturer,
    if (brand != null) 'brand': brand,
  };
}

class DeviceSpecHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static const Set<String> _nonInformativeCodes = {
    'qcom',
    'qualcomm',
    'qualcomm snapdragon',
    'mtk',
    'mediatek',
    'unknown',
    'generic',
    'standard processor',
    'default',
    'null',
    'android',
    'arm',
    'arm64',
    'aarch64',
    'exynos',
    'samsung exynos',
    'hisilicon',
    'kirin',
    'hisilicon kirin',
    'huawei',
    'xiaomi',
    'jlq',
    'jlq technology',
  };

  /// Cleans commercial SoC name by stripping manufacturer brand prefixes,
  /// legal trademark symbols, redundant internal codes, and whitespace.
  static String cleanSocDisplayName(String raw) {
    if (raw.isEmpty) return raw;
    var s = raw.trim();

    // 1. Remove trademark / legal notations: (TM), ™, (R), ®
    s = s
        .replaceAll(RegExp(r'\s*\(tm\)', caseSensitive: false), '')
        .replaceAll('™', '')
        .replaceAll(RegExp(r'\s*\(r\)', caseSensitive: false), '')
        .replaceAll('®', '');

    // 2. Remove "Technologies, Inc." or "Technologies, Inc" or "Technologies"
    s = s.replaceAll(
      RegExp(r'\btechnologies,?\s*(inc\.?)?', caseSensitive: false),
      '',
    );

    // 3. Remove leading manufacturer prefixes if followed by a recognizable sub-brand / model
    final prefixes = [
      RegExp(r'^qualcomm\s+(snapdragon\b.*)', caseSensitive: false),
      RegExp(
        r'^mediatek\s+((?:dimensity|helio|mt\d+)\b.*)',
        caseSensitive: false,
      ),
      RegExp(r'^google\s+(tensor\b.*)', caseSensitive: false),
      RegExp(r'^samsung\s+(exynos\b.*)', caseSensitive: false),
      RegExp(
        r'^unisoc\s+((?:tiger|t\d+|sc\d+|ums\d+)\b.*)',
        caseSensitive: false,
      ),
      RegExp(r'^(?:hisilicon|huawei)\s+(kirin\b.*)', caseSensitive: false),
      RegExp(r'^xiaomi\s+((?:xring|surge)\b.*)', caseSensitive: false),
      RegExp(r'^jlq(?:\s+technology)?\s+(jr\d+\b.*)', caseSensitive: false),
    ];

    for (final p in prefixes) {
      final match = p.firstMatch(s);
      if (match != null && match.groupCount >= 1) {
        s = match.group(1)!;
        break;
      }
    }

    // 4. Collapse multiple spaces and trim
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s.isEmpty ? raw.trim() : s;
  }

  /// Describes the detected SoC in a structured [SocDescription] object.
  static SocDescription describeSoc({
    String? socModel,
    String? hardware,
    String? board,
    String? manufacturer,
    String? brand,
    double? maxClockGhz,
    int? physicalCores,
  }) {
    final hw = (hardware ?? '').trim();
    final brd = (board ?? '').trim();
    final mfg = (manufacturer ?? '').trim();
    final bnd = (brand ?? '').trim();
    final mdl = (socModel ?? '').trim();
    final cores =
        physicalCores ??
        (Platform.numberOfProcessors > 0 ? Platform.numberOfProcessors : 8);

    final rawParts = [
      mdl,
      hw,
      brd,
      mfg,
    ].where((x) => x.isNotEmpty && x.toLowerCase() != 'unknown').toList();
    final rawName = rawParts.isNotEmpty
        ? rawParts.join(' ')
        : (hw.isNotEmpty ? hw : 'Standard Processor');

    // Run primary SoC marketing name detection
    final detected = detectSocName(
      hardware: hw,
      board: brd,
      manufacturer: mfg,
      socModel: mdl.isNotEmpty ? mdl : null,
      maxClockGhz: maxClockGhz,
    );

    final cleaned = cleanSocDisplayName(detected);
    final cleanedLower = cleaned.toLowerCase();
    final detectedLower = detected.toLowerCase();

    // Check if detected name is an unmapped vendor prefix or raw hardware code fallback
    final bool isPlatformFallback =
        detectedLower == 'standard processor' ||
        detectedLower == 'qualcomm snapdragon' ||
        detectedLower == 'samsung exynos' ||
        detectedLower == 'hisilicon kirin' ||
        detectedLower == 'hisilicon' ||
        detectedLower == 'kirin' ||
        detectedLower == 'xiaomi' ||
        detectedLower == 'jlq' ||
        (hw.isNotEmpty && detectedLower == hw.toLowerCase()) ||
        (brd.isNotEmpty && detectedLower == brd.toLowerCase()) ||
        (detectedLower.startsWith('mediatek mt') &&
            !detectedLower.contains('dimensity') &&
            !detectedLower.contains('helio') &&
            !RegExp(r'mt67(?:32|35|37|38|39|50|52|53)\b')
                .hasMatch(detectedLower)) ||
        (detectedLower.startsWith('qualcomm snapdragon') &&
            (detectedLower.contains('sm') ||
                detectedLower.contains('sdm') ||
                detectedLower.contains('msm')) &&
            !detectedLower.contains('elite') &&
            !detectedLower.contains('gen') &&
            !detectedLower.contains('pro'));

    // Check if detected name is non-informative or generic
    final bool isGeneric =
        _nonInformativeCodes.contains(cleanedLower) ||
        _nonInformativeCodes.contains(detectedLower) ||
        isPlatformFallback;

    if (isGeneric) {
      // Check if there is an unmapped but meaningful platform code
      String platformCode = '';
      for (final candidate in [mdl, hw, brd]) {
        final cLower = candidate.toLowerCase();
        if (candidate.isNotEmpty && !_nonInformativeCodes.contains(cLower)) {
          platformCode = candidate;
          break;
        }
      }

      return SocDescription(
        displayName: platformCode,
        isPrecise: false,
        rawName: rawName,
        coreCount: cores,
        socModel: mdl.isNotEmpty ? mdl : null,
        hardware: hw.isNotEmpty ? hw : null,
        board: brd.isNotEmpty ? brd : null,
        manufacturer: mfg.isNotEmpty ? mfg : null,
        brand: bnd.isNotEmpty ? bnd : null,
      );
    }

    return SocDescription(
      displayName: cleaned,
      isPrecise: true,
      rawName: rawName,
      coreCount: cores,
      socModel: mdl.isNotEmpty ? mdl : null,
      hardware: hw.isNotEmpty ? hw : null,
      board: brd.isNotEmpty ? brd : null,
      manufacturer: mfg.isNotEmpty ? mfg : null,
      brand: bnd.isNotEmpty ? bnd : null,
    );
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

  static double? getMaxCpuClockGhz() {
    if (!Platform.isAndroid && !Platform.isLinux) return null;
    try {
      int maxKhz = 0;
      for (int i = 0; i < 16; i++) {
        final freqFile = File(
          '/sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq',
        );
        if (freqFile.existsSync()) {
          final val = int.tryParse(freqFile.readAsStringSync().trim());
          if (val != null && val > maxKhz) maxKhz = val;
        } else {
          final scalingFile = File(
            '/sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq',
          );
          if (scalingFile.existsSync()) {
            final val = int.tryParse(scalingFile.readAsStringSync().trim());
            if (val != null && val > maxKhz) maxKhz = val;
          }
        }
      }
      if (maxKhz > 0) {
        return maxKhz / 1000000.0;
      }
    } catch (_) {}
    return null;
  }

  static String detectSocName({
    required String hardware,
    required String board,
    required String manufacturer,
    String? socModel,
    double? maxClockGhz,
  }) {
    final hwLower = hardware.toLowerCase();
    final boardLower = board.toLowerCase();
    final socLower = (socModel ?? '').toLowerCase();
    final mfgLower = manufacturer.toLowerCase();
    final c = '$hwLower $boardLower $socLower $mfgLower';
    bool has(String k) => c.contains(k);
    bool hasWord(String k) =>
        RegExp(r'(?:^|[^\w])' + RegExp.escape(k) + r'(?:[^\w]|$)').hasMatch(c);
    final isQcom = has('qcom') || has('qualcomm') || has('snapdragon');
    final effectiveClockGhz = maxClockGhz ?? getMaxCpuClockGhz();

    // -------------------------------------------------------------
    // 1. HiSilicon Kirin SoCs (ARM 64-bit)
    // -------------------------------------------------------------
    if (has('hi36d0') || has('kirin 9050') || has('kirin9050')) {
      return 'HiSilicon Kirin 9050 Pro';
    }
    if (has('kirin 9035') || has('kirin9035')) {
      return 'HiSilicon Kirin 9035';
    }
    if (has('kirin 9030s') || has('kirin9030s')) {
      return 'HiSilicon Kirin 9030S';
    }
    if (has('hi36b0') || has('kirin 9030') || has('kirin9030')) {
      return 'HiSilicon Kirin 9030 Pro';
    }
    if (has('hi36c0') || has('kirin 9020') || has('kirin9020')) {
      return 'HiSilicon Kirin 9020';
    }
    if (has('hi36a0v121') || has('kirin 9010') || has('kirin9010')) {
      return 'HiSilicon Kirin 9010';
    }
    if (has('hi36a0v120') ||
        has('kirin 9000s') ||
        has('kirin9000s') ||
        has('kirin 9000sl') ||
        has('kirin 9000we') ||
        has('kirin 9000w')) {
      return 'HiSilicon Kirin 9000S';
    }
    if (has('hi36a0') || has('kirin 9000') || has('kirin9000')) {
      return 'HiSilicon Kirin 9000 / 9000E';
    }
    if (has('hi3690-5g') ||
        has('hi3690_5g') ||
        has('kirin 990 5g') ||
        has('kirin 990e')) {
      return 'HiSilicon Kirin 990 5G';
    }
    if (has('hi3690') || has('kirin 990') || has('kirin990')) {
      return 'HiSilicon Kirin 990';
    }
    if (has('hi6290l') ||
        has('hi6290-l') ||
        has('kirin 985') ||
        has('kirin985')) {
      return 'HiSilicon Kirin 985 5G';
    }
    if (has('hi3680') || has('kirin 980') || has('kirin980')) {
      return 'HiSilicon Kirin 980';
    }
    if (has('hi3670') || has('kirin 970') || has('kirin970')) {
      return 'HiSilicon Kirin 970';
    }
    if (has('hi3660') || has('kirin 960') || has('kirin960')) {
      return 'HiSilicon Kirin 960';
    }
    if (has('hi3650') || has('kirin 950') || has('kirin 955')) {
      if (effectiveClockGhz != null && effectiveClockGhz > 2.40) {
        return 'HiSilicon Kirin 955';
      }
      return 'HiSilicon Kirin 950';
    }
    if (has('hi3635') || has('kirin 930') || has('kirin 935')) {
      if (effectiveClockGhz != null && effectiveClockGhz > 2.10) {
        return 'HiSilicon Kirin 935';
      }
      return 'HiSilicon Kirin 930';
    }
    if (has('kirin 8020') || has('kirin8020')) {
      return 'HiSilicon Kirin 8020';
    }
    if (has('kirin 8000') || has('kirin8000')) {
      if (has('8000a')) return 'HiSilicon Kirin 8000A';
      return 'HiSilicon Kirin 8000';
    }
    if (has('hi6290') ||
        has('kirin 820') ||
        has('kirin820') ||
        has('kirin 820e')) {
      return 'HiSilicon Kirin 820 5G';
    }
    if (has('hi6280') || has('kirin 810') || has('kirin810')) {
      return 'HiSilicon Kirin 810';
    }
    if (has('hi6260') || has('kirin 710') || has('kirin710')) {
      if (has('710a')) return 'HiSilicon Kirin 710A';
      return 'HiSilicon Kirin 710 / 710F';
    }
    if (has('hi6250') ||
        has('kirin 659') ||
        has('kirin 658') ||
        has('kirin 655') ||
        has('kirin 650')) {
      if (has('659')) return 'HiSilicon Kirin 659';
      return 'HiSilicon Kirin 650 / 655 / 658 / 659';
    }
    if (has('hi6210') || has('kirin 620') || has('kirin620')) {
      return 'HiSilicon Kirin 620';
    }

    // -------------------------------------------------------------
    // 2. Xiaomi In-House SoCs (XRING & Surge, ARM 64-bit)
    // -------------------------------------------------------------
    if (has('xring o3') ||
        has('xring-o3') ||
        has('xring_o3') ||
        has('xring03')) {
      return 'Xiaomi XRING O3';
    }
    if (has('xring o1') ||
        has('xring-o1') ||
        has('xring_o1') ||
        has('xring01') ||
        has('xring')) {
      return 'Xiaomi XRING O1';
    }
    if (has('surge s1') || has('v670') || has('pinecone')) {
      return 'Xiaomi Surge S1';
    }

    // -------------------------------------------------------------
    // 3. JLQ Technology SoCs (ARM 64-bit)
    // -------------------------------------------------------------
    if (has('jr510') || has('jlq')) {
      return 'JLQ JR510';
    }

    // -------------------------------------------------------------
    // 4. Google Tensor SoCs (ARM 64-bit)
    // -------------------------------------------------------------
    if (has('tensor g6')) return 'Google Tensor G6';
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

    // -------------------------------------------------------------
    // 5. Samsung Exynos SoCs (ARM 64-bit)
    // -------------------------------------------------------------
    if (has('s5e9965') || has('exynos 2600') || has('erd9965')) {
      return 'Samsung Exynos 2600';
    }
    if (has('s5e9955') || has('erd9955') || has('exynos 2500')) {
      return 'Samsung Exynos 2500';
    }
    if (has('s5e9945') || has('erd9945') || has('exynos 2400')) {
      if (has('2400e')) return 'Samsung Exynos 2400e';
      return 'Samsung Exynos 2400';
    }
    if (has('s5e9925') || has('erd9925') || has('exynos 2200')) {
      return 'Samsung Exynos 2200';
    }
    if (has('s5e9840') || has('exynos 2100')) return 'Samsung Exynos 2100';
    if (has('s5e8865') || has('exynos 1680')) return 'Samsung Exynos 1680';
    if (has('s5e8870') || has('exynos 1610')) return 'Samsung Exynos 1610';
    if (has('s5e8855') || has('exynos 1580')) return 'Samsung Exynos 1580';
    if (has('s5e8845') || has('exynos 1480')) return 'Samsung Exynos 1480';
    if (has('s5e8835') || has('exynos 1380')) return 'Samsung Exynos 1380';
    if (has('s5e8535') || has('exynos 1330')) return 'Samsung Exynos 1330';
    if (has('s5e8825') || has('exynos 1280')) return 'Samsung Exynos 1280';
    if (has('s5e9815') || has('exynos 1080')) return 'Samsung Exynos 1080';
    if (has('s5e3830') || has('exynos 850')) return 'Samsung Exynos 850';
    if (has('universal990') || has('s5e9830') || has('exynos 990')) {
      return 'Samsung Exynos 990';
    }
    if (has('s5e9630') || has('exynos 980') || has('exynos 880')) {
      return 'Samsung Exynos 980 / 880';
    }
    if (has('universal9825') ||
        has('universal9820') ||
        has('s5e9820') ||
        has('exynos 9820') ||
        has('exynos 9825')) {
      return 'Samsung Exynos 9820 / 9825';
    }
    if (has('universal9810') || has('exynos 9810')) {
      return 'Samsung Exynos 9810';
    }
    if (has('universal9611') ||
        has('universal9610') ||
        has('exynos 9611') ||
        has('exynos 9610')) {
      return 'Samsung Exynos 9611 / 9610';
    }
    if (has('universal9609') || has('exynos 9609')) {
      return 'Samsung Exynos 9609';
    }
    if (has('universal8895') || has('exynos 8895')) {
      return 'Samsung Exynos 8895';
    }
    if (has('universal8890') || has('exynos 8890')) {
      return 'Samsung Exynos 8890';
    }
    if (has('universal7904') || has('exynos 7904')) {
      return 'Samsung Exynos 7904';
    }
    if (has('universal7885') ||
        has('universal7884') ||
        has('exynos 7885') ||
        has('exynos 7884')) {
      return 'Samsung Exynos 7885 / 7884';
    }
    if (has('universal7880') || has('exynos 7880')) {
      return 'Samsung Exynos 7880';
    }
    if (has('universal7872') || has('exynos 7872')) {
      return 'Samsung Exynos 7872';
    }
    if (has('universal7870') || has('exynos 7870')) {
      return 'Samsung Exynos 7870';
    }
    if (has('universal7580') || has('exynos 7580')) {
      return 'Samsung Exynos 7580';
    }
    if (has('universal7570') || has('exynos 7570')) {
      return 'Samsung Exynos 7570';
    }
    if (has('universal7420') || has('exynos 7420')) {
      return 'Samsung Exynos 7420';
    }
    if (has('universal5433') || has('exynos 5433') || has('exynos 7410')) {
      return 'Samsung Exynos 5433';
    }

    // -------------------------------------------------------------
    // 6. MediaTek Dimensity & Helio SoCs (ARM 64-bit)
    // -------------------------------------------------------------
    if (hasWord('mt6995') || has('dimensity 9600')) {
      if (has('pro')) return 'MediaTek Dimensity 9600 Pro';
      if (has('9600m')) return 'MediaTek Dimensity 9600M';
      return 'MediaTek Dimensity 9600';
    }
    if (hasWord('mt6993') || has('dimensity 9500')) {
      if (has('9500m')) return 'MediaTek Dimensity 9500M';
      if (has('9500s')) return 'MediaTek Dimensity 9500s';
      return 'MediaTek Dimensity 9500';
    }
    if (hasWord('mt6991') || has('dimensity 9400')) {
      if (has('9400+') || has('9400 plus')) return 'MediaTek Dimensity 9400+';
      if (has('9400e')) return 'MediaTek Dimensity 9400e';
      return 'MediaTek Dimensity 9400';
    }
    if (hasWord('mt6989') || has('dimensity 9300')) {
      if (has('9300+') ||
          has('9300 plus') ||
          (effectiveClockGhz != null && effectiveClockGhz > 3.35)) {
        return 'MediaTek Dimensity 9300+';
      }
      return 'MediaTek Dimensity 9300';
    }
    if (hasWord('mt6985') || has('dimensity 9200')) {
      if (has('9200+') ||
          has('9200 plus') ||
          (effectiveClockGhz != null && effectiveClockGhz > 3.30)) {
        return 'MediaTek Dimensity 9200+';
      }
      return 'MediaTek Dimensity 9200';
    }
    if (hasWord('mt6983') || has('dimensity 9000')) {
      if (has('9000+') ||
          has('9000 plus') ||
          (effectiveClockGhz != null && effectiveClockGhz > 3.15)) {
        return 'MediaTek Dimensity 9000+';
      }
      return 'MediaTek Dimensity 9000';
    }
    if (has('dimensity 8550')) return 'MediaTek Dimensity 8550';
    if (has('dimensity 8500')) return 'MediaTek Dimensity 8500';
    if (hasWord('mt6899') || has('dimensity 8400') || has('dimensity 8450')) {
      if (has('8450')) return 'MediaTek Dimensity 8450';
      return 'MediaTek Dimensity 8400';
    }
    if (hasWord('mt6897') || has('dimensity 8300') || has('dimensity 8350')) {
      if (has('ultra')) return 'MediaTek Dimensity 8300-Ultra';
      if (has('8350')) return 'MediaTek Dimensity 8350';
      return 'MediaTek Dimensity 8300';
    }
    if (hasWord('mt6896') || has('dimensity 8200') || has('dimensity 8250')) {
      if (has('ultra')) return 'MediaTek Dimensity 8200-Ultra';
      if (has('8250')) return 'MediaTek Dimensity 8250';
      return 'MediaTek Dimensity 8200';
    }
    if (hasWord('mt6895') || has('dimensity 8100') || has('dimensity 8000')) {
      if (has('8100-max')) return 'MediaTek Dimensity 8100-Max';
      if (has('8000-max')) return 'MediaTek Dimensity 8000-Max';
      return 'MediaTek Dimensity 8100 / 8000';
    }
    if (hasWord('mt6893') ||
        has('dimensity 8050') ||
        has('dimensity 1300') ||
        has('dimensity 1200')) {
      return 'MediaTek Dimensity 1200 / 8050 / 1300';
    }
    if (hasWord('mt6891') || has('dimensity 8020') || has('dimensity 1100')) {
      return 'MediaTek Dimensity 1100 / 8020';
    }
    if (has('dimensity 7500')) return 'MediaTek Dimensity 7500';
    if (has('dimensity 7450')) {
      if (has('7450x')) return 'MediaTek Dimensity 7450X';
      return 'MediaTek Dimensity 7450';
    }
    if (has('dimensity 7400')) {
      if (has('7400x')) return 'MediaTek Dimensity 7400X';
      return 'MediaTek Dimensity 7400';
    }
    if (has('dimensity 7360')) return 'MediaTek Dimensity 7360';
    if (hasWord('mt6886') || has('dimensity 7200')) {
      if (has('ultra')) return 'MediaTek Dimensity 7200-Ultra';
      if (has('pro')) return 'MediaTek Dimensity 7200-Pro';
      return 'MediaTek Dimensity 7200';
    }
    if (hasWord('mt6878') || has('dimensity 7350') || has('dimensity 7300')) {
      if (has('7350')) {
        if (has('pro')) return 'MediaTek Dimensity 7350 Pro';
        return 'MediaTek Dimensity 7350';
      }
      if (has('7300x')) return 'MediaTek Dimensity 7300X';
      if (has('7300e') || has('energy')) {
        return 'MediaTek Dimensity 7300-Energy';
      }
      return 'MediaTek Dimensity 7300';
    }
    if (has('dimensity 7100')) return 'MediaTek Dimensity 7100';
    if (has('dimensity 7060')) return 'MediaTek Dimensity 7060';
    if (hasWord('mt6879') || has('dimensity 7030') || has('dimensity 1050')) {
      return 'MediaTek Dimensity 7030 / 1050';
    }
    if (hasWord('mt6877v') || has('dimensity 7050')) {
      return 'MediaTek Dimensity 7050';
    }
    if (hasWord('mt6877') ||
        has('dimensity 1080') ||
        has('dimensity 920') ||
        has('dimensity 900')) {
      return 'MediaTek Dimensity 7050 / 1080 / 920 / 900';
    }
    if (hasWord('mt6855') ||
        has('dimensity 7025') ||
        has('dimensity 7020') ||
        has('dimensity 930')) {
      return 'MediaTek Dimensity 7020 / 7025 / 930';
    }
    if (hasWord('mt6853t') || has('dimensity 800u')) {
      return 'MediaTek Dimensity 800U';
    }
    if (hasWord('mt6853') || has('dimensity 720')) {
      return 'MediaTek Dimensity 720';
    }
    if (has('dimensity 6500')) return 'MediaTek Dimensity 6500';
    if (has('dimensity 6400')) return 'MediaTek Dimensity 6400';
    if (has('dimensity 6360')) return 'MediaTek Dimensity 6360';
    if (hasWord('mt6835') || has('dimensity 6300') || has('dimensity 6100')) {
      return 'MediaTek Dimensity 6300 / 6100+';
    }
    if (hasWord('mt6833p') || has('dimensity 6080') || has('dimensity 810')) {
      return 'MediaTek Dimensity 6080 / 810';
    }
    if (hasWord('mt6833') || has('dimensity 700') || has('dimensity 6020')) {
      return 'MediaTek Dimensity 700 / 6020';
    }
    if (hasWord('mt6889') || has('dimensity 1000+')) {
      return 'MediaTek Dimensity 1000+';
    }
    if (hasWord('mt6885') || has('dimensity 1000')) {
      return 'MediaTek Dimensity 1000 / 1000L';
    }
    if (hasWord('mt6875') || has('dimensity 820')) {
      return 'MediaTek Dimensity 820';
    }
    if (hasWord('mt6873') || has('dimensity 800')) {
      return 'MediaTek Dimensity 800';
    }

    if (hasWord('mt6789') ||
        has('helio g99') ||
        has('helio g100') ||
        has('helio g200')) {
      if (has('g200')) return 'MediaTek Helio G200';
      if (has('g100')) return 'MediaTek Helio G100';
      if (has('ultimate')) return 'MediaTek Helio G99 Ultimate';
      if (has('ultra')) return 'MediaTek Helio G99-Ultra';
      if (has('plus')) return 'MediaTek Helio G99 Plus';
      return 'MediaTek Helio G99';
    }
    if (hasWord('mt6785') ||
        hasWord('mt6781') ||
        has('helio g96') ||
        has('helio g95') ||
        has('helio g90')) {
      if (has('g96')) return 'MediaTek Helio G96';
      if (has('g90t')) return 'MediaTek Helio G90T';
      return 'MediaTek Helio G90 / G95';
    }
    if (has('helio g92') || has('g92 max')) {
      if (has('max')) return 'MediaTek Helio G92 Max';
      return 'MediaTek Helio G92';
    }
    if (hasWord('mt6769') ||
        has('helio g85') ||
        has('helio g88') ||
        has('helio g91') ||
        has('helio g81') ||
        has('helio g80') ||
        has('helio g70')) {
      if (has('g91')) {
        if (has('ultra')) return 'MediaTek Helio G91-Ultra';
        return 'MediaTek Helio G91';
      }
      if (has('g88')) return 'MediaTek Helio G88';
      if (has('g81')) {
        if (has('ultra')) return 'MediaTek Helio G81-Ultra';
        return 'MediaTek Helio G81';
      }
      if (has('g70')) return 'MediaTek Helio G70';
      return 'MediaTek Helio G80 / G85';
    }
    if (has('helio g50') || has('g50')) return 'MediaTek Helio G50';
    if (hasWord('mt6768') || has('helio p65')) return 'MediaTek Helio P65';
    if (hasWord('mt6765') ||
        has('helio p35') ||
        has('helio g35') ||
        has('helio g36') ||
        has('helio g37')) {
      if (has('g37')) return 'MediaTek Helio G37';
      if (has('g36')) return 'MediaTek Helio G36';
      return 'MediaTek Helio P35 / G35';
    }
    if (hasWord('mt6762d') || has('helio a25')) return 'MediaTek Helio A25';
    if (hasWord('mt6762') || has('helio p22') || has('helio g25')) {
      return 'MediaTek Helio P22 / G25';
    }
    if (hasWord('mt6761') || has('helio a22') || has('helio a20')) {
      return 'MediaTek Helio A22 / A20';
    }
    if (hasWord('mt6779') || has('helio p90') || has('helio p95')) {
      return 'MediaTek Helio P90 / P95';
    }
    if (hasWord('mt6771') || has('helio p60') || has('helio p70')) {
      return 'MediaTek Helio P60 / P70';
    }
    if (hasWord('mt6758') || has('helio p30')) return 'MediaTek Helio P30';
    if (hasWord('mt6763') || has('helio p23')) return 'MediaTek Helio P23';
    if (hasWord('mt6757') || has('helio p20') || has('helio p25')) {
      return 'MediaTek Helio P20 / P25';
    }
    if (hasWord('mt6755t') || has('helio p15')) return 'MediaTek Helio P15';
    if (hasWord('mt6755') || has('helio p10')) return 'MediaTek Helio P10';
    if (hasWord('mt6799') || has('helio x30')) return 'MediaTek Helio X30';
    if (hasWord('mt6797') ||
        has('helio x20') ||
        has('helio x25') ||
        has('helio x27')) {
      return 'MediaTek Helio X20 / X25 / X27';
    }
    if (hasWord('mt6795') || has('helio x10')) return 'MediaTek Helio X10';
    if (hasWord('mt6750')) return 'MediaTek MT6750';
    if (hasWord('mt6753')) return 'MediaTek MT6753';
    if (hasWord('mt6752')) return 'MediaTek MT6752';
    if (hasWord('mt6739')) return 'MediaTek MT6739';
    if (hasWord('mt6738')) return 'MediaTek MT6738';
    if (hasWord('mt6737')) return 'MediaTek MT6737';
    if (hasWord('mt6735')) return 'MediaTek MT6735';
    if (hasWord('mt6732')) return 'MediaTek MT6732';

    // -------------------------------------------------------------
    // 7. Unisoc SoCs (ARM 64-bit)
    // -------------------------------------------------------------
    if (hasWord('t9300') || has('unisoc t9300')) return 'Unisoc T9300';
    if (hasWord('t9100') || has('unisoc t9100')) return 'Unisoc T9100';
    if (hasWord('t8300') || has('unisoc t8300')) return 'Unisoc T8300';
    if (has('ums9620') || hasWord('t820') || hasWord('t8200')) {
      if (hasWord('t8200')) return 'Unisoc T8200';
      return 'Unisoc T820';
    }
    if (has('ums512t') || hasWord('t770')) return 'Unisoc T770';
    if (hasWord('t765')) return 'Unisoc T765';
    if (hasWord('t760') || hasWord('t8100')) return 'Unisoc T760';
    if (hasWord('t7520') || hasWord('t7510')) return 'Unisoc T7510 / T7520';
    if (hasWord('t750')) return 'Unisoc T750';
    if (hasWord('t740')) return 'Unisoc T740';
    if (hasWord('t7300') || has('unisoc t7300')) return 'Unisoc T7300';
    if (hasWord('t700')) return 'Unisoc T700';
    if (hasWord('t620') || hasWord('t7280')) return 'Unisoc T620';
    if (hasWord('t619')) return 'Unisoc T619';
    if (hasWord('t618')) return 'Unisoc T618';
    if (hasWord('t616') || hasWord('t7255')) return 'Unisoc T616';
    if (hasWord('t615') || hasWord('t7250')) return 'Unisoc T615';
    if (hasWord('t612') || hasWord('t7225')) return 'Unisoc T612';
    if (hasWord('t610')) return 'Unisoc T610';
    if (hasWord('t606') || hasWord('t7200')) return 'Unisoc T606';
    if (hasWord('t603')) return 'Unisoc T603';
    if (has('ums312') || hasWord('t310')) return 'Unisoc T310';
    if (has('sc9863a') || has('sp9863a') || has('sc9863')) {
      return 'Unisoc SC9863A';
    }
    if (has('sc9860')) return 'Unisoc SC9860';
    if (has('sc9832e')) return 'Unisoc SC9832E';
    if (has('ums9230')) return 'Unisoc T606 / T616';
    if (has('ums512')) return 'Unisoc T618 / T610';

    // -------------------------------------------------------------
    // 8. Qualcomm Snapdragon SoCs (ARM 64-bit)
    // -------------------------------------------------------------
    if (has('8 elite extreme') || has('8 elite gen 6 pro')) {
      return 'Qualcomm Snapdragon 8 Elite Extreme Gen 6';
    }
    if (has('8 elite gen 6')) {
      return 'Qualcomm Snapdragon 8 Elite Gen 6';
    }
    if (has('sm8850') || has('8 elite gen 5') || has('8 elite 2')) {
      if (has('v series') || has('v-series')) {
        return 'Qualcomm Snapdragon 8 Elite Gen 5 V Series';
      }
      return 'Qualcomm Snapdragon 8 Elite Gen 5';
    }
    if (has('sm8750') ||
        (isQcom && has('sun')) ||
        has('8 elite') ||
        has('snapdragon 8 elite')) {
      return 'Qualcomm Snapdragon 8 Elite';
    }
    if (has('8 gen 5')) {
      return 'Qualcomm Snapdragon 8 Gen 5';
    }
    if (has('8s gen 4') || has('sm8735')) {
      return 'Qualcomm Snapdragon 8s Gen 4';
    }
    if (has('sm8635') || (isQcom && has('volcano')) || has('8s gen 3')) {
      return 'Qualcomm Snapdragon 8s Gen 3';
    }
    if (has('sm8650') || (isQcom && has('pineapple')) || has('8 gen 3')) {
      if (has('sm8650-ac') || (has('sm8650') && has('galaxy'))) {
        return 'Qualcomm Snapdragon 8 Gen 3 for Galaxy';
      }
      return 'Qualcomm Snapdragon 8 Gen 3';
    }
    if (has('sm8550') || (isQcom && has('kalama')) || has('8 gen 2')) {
      if (has('sm8550-ac') ||
          (has('sm8550') && has('galaxy')) ||
          has('leading version')) {
        return 'Qualcomm Snapdragon 8 Gen 2 for Galaxy';
      }
      return 'Qualcomm Snapdragon 8 Gen 2';
    }
    if (has('sm8475') || has('8+ gen 1') || has('8 plus gen 1')) {
      return 'Qualcomm Snapdragon 8+ Gen 1';
    }
    if (has('sm8450') || (isQcom && has('taro')) || has('8 gen 1')) {
      return 'Qualcomm Snapdragon 8 Gen 1';
    }
    if (has('sm8350') || (isQcom && has('lahaina')) || has('snapdragon 888')) {
      if (has('888+') ||
          has('888 plus') ||
          has('sm8350-ac') ||
          has('sm8350_ac')) {
        return 'Qualcomm Snapdragon 888+ 5G';
      }
      return 'Qualcomm Snapdragon 888';
    }
    if (has('sm8250') ||
        (isQcom && has('kona')) ||
        has('snapdragon 870') ||
        has('snapdragon 865')) {
      if (has('870') || has('sm8250-ac') || has('sm8250_ac')) {
        return 'Qualcomm Snapdragon 870';
      }
      if (has('865+') || has('865 plus')) {
        return 'Qualcomm Snapdragon 865+';
      }
      return 'Qualcomm Snapdragon 865 / 870';
    }
    if (has('sm8150-cf') ||
        has('sm8150_cf') ||
        has('snapdragon 860') ||
        (isQcom && hasWord('860'))) {
      return 'Qualcomm Snapdragon 860';
    }
    if (has('sm8150') || (isQcom && has('msmnile')) || has('snapdragon 855')) {
      if (has('855+') ||
          has('855 plus') ||
          has('sm8150-ac') ||
          has('sm8150_ac')) {
        return 'Qualcomm Snapdragon 855+';
      }
      return 'Qualcomm Snapdragon 855';
    }
    if (has('sdm845') || has('snapdragon 845') || (isQcom && hasWord('845'))) {
      return 'Qualcomm Snapdragon 845';
    }
    if (has('msm8998') || has('snapdragon 835') || (isQcom && hasWord('835'))) {
      return 'Qualcomm Snapdragon 835';
    }
    if (has('msm8996') ||
        has('snapdragon 820') ||
        has('snapdragon 821') ||
        (isQcom && (hasWord('820') || hasWord('821')))) {
      return 'Qualcomm Snapdragon 820 / 821';
    }
    if (has('msm8994') || has('snapdragon 810') || (isQcom && hasWord('810'))) {
      return 'Qualcomm Snapdragon 810';
    }
    if (has('msm8992') || has('snapdragon 808') || (isQcom && hasWord('808'))) {
      return 'Qualcomm Snapdragon 808';
    }

    if (has('7s gen 4')) return 'Qualcomm Snapdragon 7s Gen 4';
    if (has('7 gen 4')) return 'Qualcomm Snapdragon 7 Gen 4';
    if (has('sm7675') || has('7+ gen 3') || has('7 plus gen 3')) {
      return 'Qualcomm Snapdragon 7+ Gen 3';
    }
    if (has('sm7635') || has('7s gen 3')) return 'Qualcomm Snapdragon 7s Gen 3';
    if (has('sm7550') || has('7 gen 3')) return 'Qualcomm Snapdragon 7 Gen 3';
    if (has('sm7475') ||
        has('7+ gen 2') ||
        has('7 plus gen 2') ||
        has('7 gen 2')) {
      return 'Qualcomm Snapdragon 7+ Gen 2';
    }
    if (has('sm7450') || has('7 gen 1')) return 'Qualcomm Snapdragon 7 Gen 1';
    if (has('sm7435') || (isQcom && has('crow')) || has('7s gen 2')) {
      return 'Qualcomm Snapdragon 7s Gen 2';
    }
    if (has('sm7350') || has('780g')) return 'Qualcomm Snapdragon 780G';
    if (has('sm7325-af') || has('782g')) return 'Qualcomm Snapdragon 782G';
    if (has('sm7325') || (isQcom && has('yupik')) || has('778g')) {
      if (has('778g+') || has('778g plus') || has('sm7325-ae')) {
        return 'Qualcomm Snapdragon 778G+';
      }
      return 'Qualcomm Snapdragon 778G';
    }
    if (has('sm7250-ac') || has('768g')) return 'Qualcomm Snapdragon 768G';
    if (has('sm7250') ||
        (isQcom && has('lito')) ||
        has('765g') ||
        has('snapdragon 765')) {
      return has('765g')
          ? 'Qualcomm Snapdragon 765G'
          : 'Qualcomm Snapdragon 765 / 765G';
    }
    if (has('sm7225') || has('750g')) return 'Qualcomm Snapdragon 750G';
    if (has('sm7150-ac') || has('732g')) return 'Qualcomm Snapdragon 732G';
    if (has('sm7150') || has('730g') || has('snapdragon 730')) {
      return has('730g')
          ? 'Qualcomm Snapdragon 730G'
          : 'Qualcomm Snapdragon 730 / 730G';
    }
    if (has('sm7125') || (isQcom && has('atoll')) || has('720g')) {
      return 'Qualcomm Snapdragon 720G';
    }
    if (has('sdm712') || has('snapdragon 712') || (isQcom && hasWord('712'))) {
      return 'Qualcomm Snapdragon 712';
    }
    if (has('sdm710') || has('snapdragon 710') || (isQcom && hasWord('710'))) {
      return 'Qualcomm Snapdragon 710';
    }

    if (has('6 gen 5')) return 'Qualcomm Snapdragon 6 Gen 5';
    if (has('6 gen 4')) return 'Qualcomm Snapdragon 6 Gen 4';
    if (has('sm6475') || has('6 gen 3')) return 'Qualcomm Snapdragon 6 Gen 3';
    if (has('6s gen 4')) return 'Qualcomm Snapdragon 6s Gen 4';
    if (has('6s gen 3')) return 'Qualcomm Snapdragon 6s Gen 3';
    if (has('6s 4g gen 2')) return 'Qualcomm Snapdragon 6s 4G Gen 2';
    if (has('6s 4g gen 1')) return 'Qualcomm Snapdragon 6s 4G Gen 1';
    if (has('sm6450') || has('6 gen 1')) return 'Qualcomm Snapdragon 6 Gen 1';
    if (has('sm6375') || (isQcom && has('holi')) || has('695')) {
      if (has('6s gen 3')) return 'Qualcomm Snapdragon 6s Gen 3';
      return 'Qualcomm Snapdragon 695 5G';
    }
    if (has('sm6350') || has('690')) return 'Qualcomm Snapdragon 690 5G';
    if (has('sm6225-ad') ||
        has('sm6225_ad') ||
        has('snapdragon 685') ||
        (isQcom && hasWord('685'))) {
      return 'Qualcomm Snapdragon 685';
    }
    if (has('sm6225') ||
        (isQcom && has('khaje')) ||
        has('snapdragon 680') ||
        (isQcom && hasWord('680'))) {
      if (effectiveClockGhz != null && effectiveClockGhz > 2.60) {
        return 'Qualcomm Snapdragon 685';
      }
      return 'Qualcomm Snapdragon 680';
    }
    if (has('snapdragon 678') || (isQcom && hasWord('678'))) {
      return 'Qualcomm Snapdragon 678';
    }
    if (has('sm6150') || has('snapdragon 675') || (isQcom && hasWord('675'))) {
      return 'Qualcomm Snapdragon 675';
    }
    if (has('sdm670') || has('snapdragon 670') || (isQcom && hasWord('670'))) {
      return 'Qualcomm Snapdragon 670';
    }
    if (has('sm6125') ||
        (isQcom && has('trinket')) ||
        has('snapdragon 665') ||
        (isQcom && hasWord('665'))) {
      return 'Qualcomm Snapdragon 665';
    }
    if (has('sm6115') ||
        (isQcom && has('bengal')) ||
        has('snapdragon 662') ||
        (isQcom && hasWord('662'))) {
      return has('678') ? 'Qualcomm Snapdragon 678' : 'Qualcomm Snapdragon 662';
    }
    if (has('sdm660') || has('snapdragon 660') || (isQcom && hasWord('660'))) {
      return 'Qualcomm Snapdragon 660';
    }
    if (has('msm8976-pro') ||
        has('sdm653') ||
        has('snapdragon 653') ||
        (isQcom && hasWord('653'))) {
      return 'Qualcomm Snapdragon 653';
    }
    if (has('msm8976') ||
        has('sdm652') ||
        has('snapdragon 652') ||
        (isQcom && hasWord('652'))) {
      return 'Qualcomm Snapdragon 652';
    }
    if (has('msm8956') ||
        has('sdm650') ||
        has('snapdragon 650') ||
        (isQcom && hasWord('650'))) {
      return 'Qualcomm Snapdragon 650';
    }
    if (has('sdm636') || has('snapdragon 636') || (isQcom && hasWord('636'))) {
      return 'Qualcomm Snapdragon 636';
    }
    if (has('sdm632') || has('snapdragon 632') || (isQcom && hasWord('632'))) {
      return 'Qualcomm Snapdragon 632';
    }
    if (has('sdm630') || has('snapdragon 630') || (isQcom && hasWord('630'))) {
      return 'Qualcomm Snapdragon 630';
    }
    if (has('msm8953-pro') ||
        has('sdm626') ||
        has('snapdragon 626') ||
        (isQcom && hasWord('626'))) {
      return 'Qualcomm Snapdragon 626';
    }
    if (has('msm8953') ||
        has('sdm625') ||
        has('snapdragon 625') ||
        (isQcom && hasWord('625'))) {
      return 'Qualcomm Snapdragon 625';
    }
    if (has('msm8952') || has('snapdragon 617') || (isQcom && hasWord('617'))) {
      return 'Qualcomm Snapdragon 617';
    }
    if (has('msm8939-v2') ||
        has('msm8939v2') ||
        has('snapdragon 616') ||
        (isQcom && hasWord('616'))) {
      return 'Qualcomm Snapdragon 616';
    }
    if (has('msm8939') || has('snapdragon 615') || (isQcom && hasWord('615'))) {
      return 'Qualcomm Snapdragon 615';
    }

    if (has('4 gen 5')) return 'Qualcomm Snapdragon 4 Gen 5';
    if (has('4 gen 4')) return 'Qualcomm Snapdragon 4 Gen 4';
    if (has('sm4635') || has('4s gen 2')) return 'Qualcomm Snapdragon 4s Gen 2';
    if (has('sm4450-ae') || has('4 gen 2 ae') || has('4 gen 2 accelerated')) {
      return 'Qualcomm Snapdragon 4 Gen 2 AE';
    }
    if (has('sm4450') || has('4 gen 2')) return 'Qualcomm Snapdragon 4 Gen 2';
    if (has('sm4375') || has('4 gen 1')) return 'Qualcomm Snapdragon 4 Gen 1';
    if (has('sm4350-ac') || has('480+')) return 'Qualcomm Snapdragon 480+ 5G';
    if (has('sm4350') || has('snapdragon 480')) {
      return 'Qualcomm Snapdragon 480 5G';
    }
    if (has('sm4250') || has('snapdragon 460') || (isQcom && hasWord('460'))) {
      return 'Qualcomm Snapdragon 460';
    }
    if (has('sdm450') || has('snapdragon 450') || (isQcom && hasWord('450'))) {
      return 'Qualcomm Snapdragon 450';
    }
    if (has('sdm439') || has('snapdragon 439') || (isQcom && hasWord('439'))) {
      return 'Qualcomm Snapdragon 439';
    }
    if (has('msm8940') ||
        has('msm8937') ||
        has('snapdragon 430') ||
        has('snapdragon 435') ||
        (isQcom && (hasWord('430') || hasWord('435')))) {
      return 'Qualcomm Snapdragon 430 / 435';
    }
    if (has('sdm429') || has('snapdragon 429') || (isQcom && hasWord('429'))) {
      return 'Qualcomm Snapdragon 429';
    }
    if (has('msm8920') || has('snapdragon 427') || (isQcom && hasWord('427'))) {
      return 'Qualcomm Snapdragon 427';
    }
    if (has('msm8917') || has('snapdragon 425') || (isQcom && hasWord('425'))) {
      return 'Qualcomm Snapdragon 425';
    }
    if (has('msm8929') || has('snapdragon 415') || (isQcom && hasWord('415'))) {
      return 'Qualcomm Snapdragon 415';
    }
    if (has('msm8916v2') ||
        has('msm8916-v2') ||
        has('snapdragon 412') ||
        (isQcom && hasWord('412'))) {
      return 'Qualcomm Snapdragon 412';
    }
    if (has('msm8916') || has('snapdragon 410') || (isQcom && hasWord('410'))) {
      return 'Qualcomm Snapdragon 410';
    }
    if (has('qm215') || has('snapdragon 215') || (isQcom && hasWord('215'))) {
      return 'Qualcomm Snapdragon 215';
    }

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
    if (hwLower.contains('kirin') ||
        boardLower.contains('kirin') ||
        hwLower.startsWith('hi36') ||
        hwLower.startsWith('hi62')) {
      return 'HiSilicon Kirin';
    }
    if (hwLower.contains('xring') || boardLower.contains('xring')) {
      return 'Xiaomi XRING';
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

    // --- HiSilicon Kirin Family ---
    if (s.contains('kirin') ||
        h.contains('hi36') ||
        h.contains('hi62') ||
        b.contains('kirin')) {
      if (has('9050') || has('hi36d0')) return 'Maleoon 955';
      if (has('9030') || has('hi36b0')) return 'Maleoon 935';
      if (has('9020') || has('8020') || has('hi36c0')) return 'Maleoon 920';
      if (has('9010') ||
          has('9000s') ||
          has('9000sl') ||
          has('9000w') ||
          has('hi36a0v12')) {
        return 'Maleoon 910';
      }
      if (has('9000') || has('hi36a0')) return 'Mali-G78 MP24';
      if (has('990') || has('hi3690')) return 'Mali-G76 MP16';
      if (has('985') || has('hi6290l')) return 'Mali-G77 MP8';
      if (has('980') || has('hi3680')) return 'Mali-G76 MP10';
      if (has('970') || has('hi3670')) return 'Mali-G72 MP12';
      if (has('960') || has('hi3660')) return 'Mali-G71 MP8';
      if (has('955') || has('950') || has('hi3650')) return 'Mali-T880 MP4';
      if (has('935') || has('930') || has('hi3635')) return 'Mali-T628 MP4';
      if (has('8000')) return 'Mali-G610';
      if (has('820') || has('hi6290')) return 'Mali-G57 MP6';
      if (has('810') || has('hi6280')) return 'Mali-G52 MP6';
      if (has('710') || has('hi6260')) return 'Mali-G51 MP4';
      if (has('659') ||
          has('658') ||
          has('655') ||
          has('650') ||
          has('hi6250')) {
        return 'Mali-T830 MP2';
      }
      if (has('620') || has('hi6210')) return 'Mali-450 MP4';
      return 'ARM Mali / Maleoon GPU';
    }

    // --- Xiaomi In-House (XRING & Surge) ---
    if (s.contains('xring') ||
        s.contains('surge') ||
        h.contains('v670') ||
        b.contains('xring')) {
      if (has('xring o3') || has('o3')) return 'Immortalis-G925+';
      if (has('xring')) return 'Immortalis-G925 MC16';
      if (has('surge') || has('v670')) return 'Mali-T860 MP4';
      return 'ARM Immortalis / Mali GPU';
    }

    // --- JLQ Technology ---
    if (s.contains('jlq') ||
        s.contains('jr510') ||
        h.contains('jr510') ||
        b.contains('jr510')) {
      return 'Mali-G57 MC1';
    }

    // --- Samsung Exynos Family ---
    if (s.contains('exynos') || h.contains('s5e') || h.contains('universal')) {
      if (has('2600') || has('s5e9965')) return 'Samsung Xclipse 960';
      if (has('2500') || has('s5e9955')) return 'Samsung Xclipse 950';
      if (has('2400') || has('s5e9945')) return 'Samsung Xclipse 940';
      if (has('2200') || has('s5e9925')) return 'Samsung Xclipse 920';
      if (has('2100') || has('s5e9840')) return 'Mali-G78 MP14';
      if (has('1680') || has('s5e8865')) return 'Samsung Xclipse 550';
      if (has('1610') || has('1580') || has('s5e8870') || has('s5e8855')) {
        return 'Samsung Xclipse 540';
      }
      if (has('1480') || has('s5e8845')) return 'Samsung Xclipse 530';
      if (has('1380') || has('s5e8835')) return 'Mali-G68 MP5';
      if (has('1330') || has('s5e8535')) return 'Mali-G68 MP2';
      if (has('1280') || has('s5e8825')) return 'Mali-G68 MP4';
      if (has('1080') || has('s5e9815')) return 'Mali-G78 MP10';
      if (has('850') || has('s5e3830')) return 'Mali-G52 MP1';
      if (has('990') || has('universal990')) return 'Mali-G77 MP11';
      if (has('980') || has('880') || has('s5e9630')) return 'Mali-G76 MP5';
      if (has('9820') ||
          has('9825') ||
          has('universal9820') ||
          has('universal9825')) {
        return 'Mali-G76 MP12';
      }
      if (has('9810') || has('universal9810')) return 'Mali-G72 MP18';
      if (has('8895') || has('universal8895')) return 'Mali-G71 MP20';
      if (has('8890') || has('universal8890')) return 'Mali-T880 MP12';
      if (has('7420') || has('universal7420')) return 'Mali-T760 MP8';
      if (has('5433') || has('universal5433') || has('7410')) {
        return 'Mali-T760 MP6';
      }
      if (has('9611') ||
          has('9610') ||
          has('universal9611') ||
          has('universal9610')) {
        return 'Mali-G72 MP3';
      }
      if (has('7904') ||
          has('7885') ||
          has('7884') ||
          has('universal7904') ||
          has('universal7885')) {
        return 'Mali-G71 MP2';
      }
      if (has('7880') || has('universal7880')) return 'Mali-T830 MP3';
      if (has('7872') || has('universal7872')) return 'Mali-G71 MP1';
      if (has('7870') || has('universal7870')) return 'Mali-T830 MP1';
      if (has('7580') || has('universal7580')) return 'Mali-T720 MP2';
      if (has('7570') || has('universal7570')) return 'Mali-T720 MP1';
      return 'ARM Mali / Xclipse GPU';
    }

    // --- Google Tensor Family ---
    if (s.contains('tensor') ||
        b.contains('laguna') ||
        b.contains('frankel') ||
        b.contains('zuma') ||
        b.contains('gs')) {
      if (has('tensor g6')) return 'IMG D-Series GPU';
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
        b.contains('t750') ||
        b.contains('t7300') ||
        b.contains('t8300') ||
        b.contains('t9300')) {
      if (has('t9300') || has('t9100')) return 'Mali-G57';
      if (has('t820') ||
          has('t770') ||
          has('t765') ||
          has('t760') ||
          has('ums9620') ||
          has('ums512t')) {
        return 'Mali-G57 MP4';
      }
      if (has('t8300') ||
          has('t8200') ||
          has('t7300') ||
          has('t7510') ||
          has('t7520') ||
          has('t750') ||
          has('t740')) {
        return 'Mali-G57 MP2';
      }
      if (has('sc9863a') || has('sp9863a') || has('sc9863')) {
        return 'PowerVR Rogue GE8322';
      }
      if (has('t310') || has('ums312')) return 'PowerVR GE8300';
      if (has('sc9860')) return 'Mali-T880 MP4';
      if (has('sc9832e')) return 'Mali-T820 MP1';
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
      if (has('8500')) return 'Mali-G720 MC8';
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
      if (has('7500') || has('7450') || has('7400')) return 'Mali-G615 MC4';
      if (has('7360') || has('7350') || has('7300') || has('mt6878')) {
        return 'Mali-G615 MC2';
      }
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
          has('6500') ||
          has('6400') ||
          has('6360') ||
          has('6080') ||
          has('6020') ||
          has('6300') ||
          has('6100') ||
          has('810') ||
          has('g99') ||
          has('g100') ||
          has('g200') ||
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
      if (has('g88') ||
          has('g85') ||
          has('g80') ||
          has('g81') ||
          has('g91') ||
          has('mt6769')) {
        return 'Mali-G52 MC2';
      }
      if (has('p90') || has('p95') || has('mt6779')) return 'PowerVR GM9446';
      if (has('p60') || has('p70') || has('mt6771')) return 'Mali-G72 MP3';
      if (has('p20') || has('p25') || has('mt6757')) return 'Mali-T880 MP2';
      if (has('p23') || has('p10') || has('mt6763') || has('mt6755')) {
        return 'Mali-T860 MP2';
      }
      if (has('x30') || has('mt6799')) return 'PowerVR Series7XT Plus';
      if (has('x20') || has('x25') || has('x27') || has('mt6797')) {
        return 'Mali-T880 MP4';
      }
      if (has('x10') || has('mt6795')) return 'PowerVR G6200';
      if (has('mt6752') || has('mt6732')) return 'Mali-T760 MP2';
      if (has('mt6738')) return 'Mali-T860 MP2';
      if (has('mt6750') || has('mt6753')) {
        return 'Mali-T860 MP2';
      }
      if (has('mt6739')) return 'PowerVR GE8100';
      if (has('mt6737') || has('mt6735')) return 'Mali-T720';
      if (has('p35') ||
          has('g35') ||
          has('g37') ||
          has('g36') ||
          has('g25') ||
          has('p22') ||
          has('a25') ||
          has('mt6762d') ||
          has('mt6765') ||
          has('mt6762')) {
        return 'PowerVR GE8320';
      }
      if (has('a22') || has('a20') || has('mt6761')) return 'PowerVR GE8300';
      return 'ARM Mali GPU';
    }

    // --- Qualcomm Snapdragon Family ---
    if (s.contains('snapdragon') ||
        h.contains('sm') ||
        h.contains('sdm') ||
        h.contains('msm') ||
        h.contains('qcom')) {
      if (has('8 elite extreme') || has('8 elite gen 6')) return 'Adreno 850';
      if (has('8 elite gen 5') || has('8 gen 5') || has('sm8850')) {
        return 'Adreno 840';
      }
      if (has('8 elite') || has('sm8750') || b.contains('sun')) {
        return 'Adreno 830';
      }
      if (has('8s gen 4')) return 'Adreno 825';
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
      if (has('810') || has('msm8994')) return 'Adreno 430';
      if (has('808') || has('msm8992')) return 'Adreno 418';
      if (has('7s gen 4')) return 'Adreno 720';
      if (has('7 gen 4')) return 'Adreno 725';
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
      if (has('6 gen 5') ||
          has('6 gen 4') ||
          has('6 gen 3') ||
          has('6 gen 1') ||
          has('6s gen 4') ||
          has('sm6475') ||
          has('sm6450')) {
        return 'Adreno 710';
      }
      if (has('6s 4g gen 2') || has('6s 4g gen 1')) return 'Adreno 610';
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
      if (has('653') || has('652') || has('650') || has('msm8976')) {
        return 'Adreno 510';
      }
      if (has('636') || has('sdm636')) return 'Adreno 509';
      if (has('632') ||
          has('630') ||
          has('626') ||
          has('625') ||
          has('msm8953')) {
        return 'Adreno 506';
      }
      if (has('617') || has('616') || has('615') || has('msm8939')) {
        return 'Adreno 405';
      }
      if (has('4s gen 2') || has('sm4635')) return 'Adreno 611';
      if (has('4 gen 2') || has('sm4450')) return 'Adreno 613';
      if (has('4 gen 5') ||
          has('4 gen 4') ||
          has('4 gen 1') ||
          has('480+') ||
          has('480') ||
          has('sm4375') ||
          has('sm4350')) {
        return 'Adreno 619';
      }
      if (has('460') || has('sm4250')) return 'Adreno 610';
      if (has('450') || has('sdm450')) return 'Adreno 506';
      if (has('439') || has('435') || has('430')) return 'Adreno 505';
      if (has('429') || has('sdm429')) return 'Adreno 504';
      if (has('427') || has('425') || has('msm8917')) return 'Adreno 308';
      if (has('415') || has('msm8929')) return 'Adreno 405';
      if (has('412') || has('410') || has('msm8916')) return 'Adreno 306';
      if (has('215') || has('qm215')) return 'Adreno 308';
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

      final discoveredProps = <String>[];
      if (socModel != null && socModel.isNotEmpty) {
        discoveredProps.add(socModel);
      }

      final propKeys = [
        'ro.soc.model',
        'ro.board.platform',
        'ro.chipname',
        'ro.hardware.chipname',
        'ro.product.board',
      ];
      for (final key in propKeys) {
        try {
          final res = await Process.run('getprop', [key]);
          if (res.exitCode == 0) {
            final val = (res.stdout as String).trim();
            if (val.isNotEmpty && !val.toLowerCase().contains('unknown')) {
              discoveredProps.add(val);
            }
          }
        } catch (_) {}
      }

      try {
        final soc0Machine = File('/sys/devices/soc0/machine');
        if (soc0Machine.existsSync()) {
          final val = soc0Machine.readAsStringSync().trim();
          if (val.isNotEmpty && !val.toLowerCase().contains('unknown')) {
            discoveredProps.add(val);
          }
        }
      } catch (_) {}

      if (discoveredProps.isNotEmpty) {
        socModel = discoveredProps.toSet().join(' ').trim();
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
    final maxClock = getMaxCpuClockGhz();
    final socDesc = describeSoc(
      hardware: hardware,
      board: board,
      manufacturer: manufacturer,
      brand: brand,
      socModel: socModel,
      maxClockGhz: maxClock,
      physicalCores: Platform.numberOfProcessors,
    );
    final cpuSoc = socDesc.displayName.isNotEmpty
        ? socDesc.displayName
        : (detectSocName(
            hardware: hardware,
            board: board,
            manufacturer: manufacturer,
            socModel: socModel,
            maxClockGhz: maxClock,
          ));

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
      'socDescription': socDesc,
      'gpu': gpu,
      'ram': '$marketedRamGb GB',
      'ramMb': ramMb,
      'storage': storageData['storage'] as String? ?? '256 GB',
      'storageFree': storageData['freeStr'] as String? ?? '142 GB',
      'storageDisplay': storageData['storageDisplay'] as String? ?? '256 GB',
      'cores': socDesc.coreCount,
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

  /// Maximum number of threads that can safely run without high risk of OOM
  /// on the given total RAM capacity.
  static int maxSafeThreadCount(int ramMb, [int? customPhysicalCores]) {
    final physical =
        customPhysicalCores ??
        (Platform.numberOfProcessors > 0 ? Platform.numberOfProcessors : 8);
    if (ramMb <= 4500) {
      return 4.clamp(1, physical); // 4GB RAM or less -> safe up to 4 threads
    } else if (ramMb <= 6500) {
      return 6.clamp(1, physical); // 6GB RAM -> safe up to 6 threads
    } else {
      return physical; // 8GB+ RAM
    }
  }

  /// Check whether the detected SoC falls into entry-level or legacy category
  /// where 4 cores is the maximum safe allocation.
  static bool isEntryOrLegacySoc({
    String? socName,
    String? hardware,
    String? board,
  }) {
    final s = (socName ?? '').toLowerCase();
    final h = (hardware ?? '').toLowerCase();
    final b = (board ?? '').toLowerCase();
    final combined = '$s $h $b';

    // Mid-range & Flagship chips:
    // 1. MediaTek Helio G70 and above (G70, G80, G81, G85, G88, G90, G91, G95, G96, G98, G99, G100, G200)
    if (combined.contains('g70') ||
        combined.contains('g80') ||
        combined.contains('g81') ||
        combined.contains('g85') ||
        combined.contains('g88') ||
        combined.contains('g90') ||
        combined.contains('g91') ||
        combined.contains('g95') ||
        combined.contains('g96') ||
        combined.contains('g98') ||
        combined.contains('g99') ||
        combined.contains('g100') ||
        combined.contains('g200')) {
      return false;
    }

    // 2. Snapdragon 660, 662, 665, 670, 675, 678, 680, 685, 695, 7-series, 8-series, Dimensity, Tensor, Kirin 8/9, XRING
    if (RegExp(r'(?:^|[^\d])6(?:60|62|65|70|75|78|80|85|95)(?:[^\d]|$)')
            .hasMatch(combined) ||
        combined.contains('trinket') ||
        combined.contains('bengal') ||
        combined.contains('snapdragon 7') ||
        combined.contains('snapdragon 8') ||
        combined.contains('dimensity') ||
        combined.contains('tensor') ||
        combined.contains('kirin 9') ||
        combined.contains('kirin 8') ||
        combined.contains('xring')) {
      return false;
    }

    // 3. Modern Snapdragon 4-series (4 Gen 1, 4 Gen 2, 4s Gen 2, 4 Gen 4, 4 Gen 5, 480, 480+, SM4375, SM4450, SM4635, SM4350)
    if (combined.contains('4 gen') ||
        combined.contains('4s gen') ||
        combined.contains('480') ||
        combined.contains('sm4375') ||
        combined.contains('sm4450') ||
        combined.contains('sm4635') ||
        combined.contains('sm4350')) {
      return false;
    }

    // Samsung Exynos entry & legacy (5433, 7410, 7420, 7570, 7580, 7870, 7872, 7880, 7884, 7885, 7904, 850, 9609, 9610, 9611)
    if (combined.contains('exynos 5433') ||
        combined.contains('exynos 7410') ||
        combined.contains('exynos 7420') ||
        combined.contains('exynos 7570') ||
        combined.contains('exynos 7580') ||
        combined.contains('exynos 7870') ||
        combined.contains('exynos 7872') ||
        combined.contains('exynos 7880') ||
        combined.contains('exynos 7884') ||
        combined.contains('exynos 7885') ||
        combined.contains('exynos 7904') ||
        combined.contains('exynos 850') ||
        combined.contains('exynos 9609') ||
        combined.contains('exynos 9610') ||
        combined.contains('exynos 9611') ||
        combined.contains('universal5433') ||
        combined.contains('universal7420') ||
        combined.contains('universal7570') ||
        combined.contains('universal7580') ||
        combined.contains('universal7870') ||
        combined.contains('universal7872') ||
        combined.contains('universal7880') ||
        combined.contains('universal7885') ||
        combined.contains('universal7904') ||
        combined.contains('universal9610') ||
        combined.contains('universal9611') ||
        combined.contains('s5e3830')) {
      return true;
    }

    // HiSilicon Kirin entry & legacy (710, 65x, 620, 930, 935)
    if (combined.contains('kirin 710') ||
        combined.contains('kirin 65') ||
        combined.contains('kirin 620') ||
        combined.contains('kirin 930') ||
        combined.contains('kirin 935') ||
        combined.contains('hi6260') ||
        combined.contains('hi6250') ||
        combined.contains('hi6210') ||
        combined.contains('hi3635')) {
      return true;
    }

    // JLQ Technology entry (JR510)
    if (combined.contains('jr510') || combined.contains('jlq')) {
      return true;
    }

    // Legacy Snapdragon 6-series entry: 615, 616, 617, 625, 626, 630, 632, 636, msm8953
    if (combined.contains('615') ||
        combined.contains('616') ||
        combined.contains('617') ||
        combined.contains('625') ||
        combined.contains('626') ||
        combined.contains('630') ||
        combined.contains('632') ||
        combined.contains('636') ||
        combined.contains('msm8939') ||
        combined.contains('msm8952') ||
        combined.contains('msm8953')) {
      return true;
    }

    // Legacy Snapdragon 4-series (410, 412, 415, 425, 427, 429, 430, 435, 439, 450, 460) & Snapdragon 215
    if (combined.contains('snapdragon 215') ||
        combined.contains('qm215') ||
        combined.contains('sdm4') ||
        combined.contains('sm4250') ||
        combined.contains('msm8916') ||
        combined.contains('msm8917') ||
        combined.contains('msm8920') ||
        combined.contains('msm8929') ||
        combined.contains('msm8937') ||
        combined.contains('msm8940') ||
        combined.contains('410') ||
        combined.contains('412') ||
        combined.contains('415') ||
        combined.contains('425') ||
        combined.contains('427') ||
        combined.contains('429') ||
        combined.contains('430') ||
        combined.contains('435') ||
        combined.contains('439') ||
        combined.contains('450') ||
        combined.contains('460')) {
      return true;
    }

    // Legacy MediaTek Helio (P-series, X-series, A-series, entry G-series below G70, old MT67xx)
    if (combined.contains('helio p') ||
        combined.contains('helio x') ||
        combined.contains('helio a') ||
        combined.contains('g25') ||
        combined.contains('g35') ||
        combined.contains('g36') ||
        combined.contains('g37') ||
        combined.contains('g50') ||
        combined.contains('mt6732') ||
        combined.contains('mt6735') ||
        combined.contains('mt6737') ||
        combined.contains('mt6738') ||
        combined.contains('mt6739') ||
        combined.contains('mt6750') ||
        combined.contains('mt6752') ||
        combined.contains('mt6753') ||
        combined.contains('mt6761') ||
        combined.contains('mt6762') ||
        combined.contains('mt6763') ||
        combined.contains('mt6765')) {
      return true;
    }

    // Unisoc entry (SC9863A, SC9860, SC9832E, T310, T603, T606, T610, T612, T615, T616)
    if (combined.contains('sc9863') ||
        combined.contains('sc9860') ||
        combined.contains('sc9832') ||
        combined.contains('t310') ||
        combined.contains('ums312') ||
        combined.contains('t603') ||
        combined.contains('t606') ||
        combined.contains('t610') ||
        combined.contains('t612') ||
        combined.contains('t615') ||
        combined.contains('t616')) {
      return true;
    }

    return false;
  }

  /// Resolves the effective CPU thread count based on user choice, hardware capability,
  /// RAM tier, and video resolution.
  ///
  /// - If [requestedThreads] > 0 (Manual Selection):
  ///   Always respects the user's manual choice, clamped only to physical core count.
  /// - If [requestedThreads] == 0 (Auto Mode):
  ///   Intelligently allocates cores:
  ///   * RAM <= 4 GB or legacy SoC: baseline 4 cores (including 4K).
  ///   * RAM 6 GB / Mid-Range: baseline 6 cores. If 4K, reduced to 5 cores.
  ///   * RAM >= 8 GB / Flagship: baseline 8 cores. If 4K, reduced to 7 cores.
  ///   * Clamped to physical processors and minimum 1 core.
  static int resolveThreadCount({
    VideoInfo? video,
    int? requestedThreads,
    int? customRamMb,
    int? customPhysicalCores,
    String? customSoc,
  }) {
    final physicalCores =
        customPhysicalCores ??
        (Platform.numberOfProcessors > 0 ? Platform.numberOfProcessors : 8);

    // 1. Manual User Selection: Always respect user choice clamped to physical cores
    if (requestedThreads != null && requestedThreads > 0) {
      return requestedThreads.clamp(1, physicalCores);
    }

    // 2. Auto Mode: Adaptive hardware tiering
    final ramMb = customRamMb ?? getTotalRamMb();
    final soc =
        customSoc ??
        (Platform.isAndroid
            ? detectSocName(hardware: '', board: '', manufacturer: '')
            : '');

    // Check if video is 4K (width >= 3840 or height >= 2160)
    final bool is4K =
        video != null &&
        (video.width >= 3840 ||
            video.height >= 2160 ||
            (video.width >= 2160 && video.height >= 3840));

    final isLegacy = isEntryOrLegacySoc(socName: soc);

    int baseline;
    if (ramMb <= 4500 || isLegacy) {
      baseline = 4;
    } else if (ramMb <= 6500) {
      baseline = 6;
      if (is4K) baseline = 5;
    } else {
      // 8GB+ RAM
      final isFlagship =
          soc.toLowerCase().contains('snapdragon 8') ||
          soc.toLowerCase().contains('dimensity 8') ||
          soc.toLowerCase().contains('dimensity 9') ||
          soc.toLowerCase().contains('tensor') ||
          soc.toLowerCase().contains('exynos 2') ||
          soc.toLowerCase().contains('kirin 9') ||
          soc.toLowerCase().contains('xring');
      if (isFlagship && physicalCores >= 8) {
        baseline = 8;
        if (is4K) baseline = 7;
      } else {
        baseline = 6;
        if (is4K) baseline = 5;
      }
    }

    return baseline.clamp(1, physicalCores);
  }
}
