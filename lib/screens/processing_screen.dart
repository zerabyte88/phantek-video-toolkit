import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/app_settings.dart';
import '../models/encoding_options.dart';
import '../models/video_info.dart';
import '../services/cache_manager_service.dart';
import '../services/device_spec_helper.dart';
import '../services/ffmpeg_service.dart';
import '../services/foreground_service.dart';
import '../services/settings_service.dart';

class ProcessingScreen extends StatefulWidget {
  final VideoInfo videoInfo;
  final VideoResolution targetResolution;
  final EncodingOptions encodingOptions;
  final AppSettings appSettings;

  const ProcessingScreen({
    super.key,
    required this.videoInfo,
    required this.targetResolution,
    this.encodingOptions = const EncodingOptions(),
    this.appSettings = const AppSettings(),
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  final _settingsService = SettingsService();
  double _progress = 0.0;
  String _statusText = '';
  String _speedText = '';
  String _currentSizeText = '';
  bool _isProcessing = true;
  bool _isSuccess = false;
  String? _outputPath;
  String? _errorMessage;
  late AnimationController _pulseController;

  DateTime? _startTime;
  Duration _elapsedDuration = Duration.zero;
  Duration? _estimatedRemaining;
  Duration? _totalDuration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    ForegroundServiceManager().requestPermissions();
    _statusText = _settingsService.l10n.t('proc_preparing');
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    // Force wakelock ON so the screen & CPU stay active during encoding,
    // regardless of the user's global "Keep Screen Awake" setting.
    WakelockPlus.enable();
    _startProcessing();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    ForegroundServiceManager().stopService();
    // Restore wakelock to the user's preference.
    WakelockPlus.toggle(
      enable: _settingsService.settings.keepScreenAwake,
    );
    if (_isProcessing) {
      FFmpegService.cancelAll();
      CacheManagerService().clearAllCache(
        specificInputPath: widget.videoInfo.filePath,
      );
    }
    super.dispose();
  }

  String _formatPercentage(double progress) {
    final percent = (progress * 100).clamp(0.0, 100.0);
    return '${percent.toStringAsFixed(1)}%';
  }

  Duration? _calculateRemainingTime(double progress, Duration elapsed) {
    if (progress < 0.005 || progress >= 0.999) return null;
    final elapsedMs = elapsed.inMilliseconds;
    if (elapsedMs < 1000) return null;
    final totalEstimatedMs = elapsedMs / progress;
    final remainingMs = (totalEstimatedMs - elapsedMs).clamp(0, 86400000);
    return Duration(milliseconds: remainingMs.round());
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startProcessing() async {
    final l10n = _settingsService.l10n;
    _startTime = DateTime.now();
    _elapsedDuration = Duration.zero;
    _estimatedRemaining = null;
    _totalDuration = null;
    _errorMessage = null;

    await ForegroundServiceManager().requestPermissions();

    setState(() {
      _statusText = l10n.t('proc_converting');
    });

    await ForegroundServiceManager().startService(
      title: l10n.t('app_title'),
      text: '${l10n.t('proc_converting')} 0.0%',
    );

    // 1-second timer to update elapsed and remaining time continuously
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || !_isProcessing) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      final elapsed = now.difference(_startTime!);
      final remaining = _calculateRemainingTime(_progress, elapsed);
      
      // Check thermal every 10 seconds
      if (timer.tick % 10 == 0) {
        final temp = await DeviceSpecHelper.getBatteryTemperature();
        if (temp >= 45.0 && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Warning: Device Temperature High (${temp.toStringAsFixed(1)}°C)'),
               backgroundColor: Colors.red,
               duration: const Duration(seconds: 3),
             )
           );
        }
      }

      setState(() {
        _elapsedDuration = elapsed;
        if (remaining != null) {
          _estimatedRemaining = remaining;
        }
      });
    });

    final result = await FFmpegService.downscaleVideo(
      sourceVideo: widget.videoInfo,
      targetResolution: widget.targetResolution,
      encodingOptions: widget.encodingOptions,
      appSettings: widget.appSettings,
      onProgress: (progress, stats) {
        if (mounted) {
          // Parse speed and size from stats
          String speed = '';
          String size = '';
          if (stats.contains('|')) {
            final parts = stats.split('|');
            size = parts[0].replaceAll('Size:', '').trim();
            speed = parts[1].replaceAll('Speed:', '').trim();
          }

          final now = DateTime.now();
          final elapsed = _startTime != null ? now.difference(_startTime!) : Duration.zero;
          final remaining = _calculateRemainingTime(progress, elapsed);
          final etaStr = remaining != null ? ' | ETA: ${_formatDuration(remaining)}' : '';

          ForegroundServiceManager().updateService(
            title: l10n.t('app_title'),
            text: '${l10n.t('proc_converting')} ${_formatPercentage(progress)}$etaStr',
          );

          setState(() {
            _progress = progress;
            _elapsedDuration = elapsed;
            if (remaining != null) {
              _estimatedRemaining = remaining;
            }
            _speedText = speed;
            _currentSizeText = size;
            _statusText = '${l10n.t('proc_converting')} ${_formatPercentage(progress)}';
          });
        }
      },
      onLog: (log) {
        if (mounted) {
          if (log.contains('Encoding failed:') || log.toLowerCase().contains('error')) {
            _errorMessage = log.replaceFirst('\nEncoding failed: ', '').trim();
          }
          debugPrint(log);
        }
      },
    );

    if (result != null) {
      ForegroundServiceManager().updateService(
        title: l10n.t('app_title'),
        text: l10n.t('proc_notif_completed'),
      );
    }
    // Restore wakelock to the user's preference now that encoding is done.
    WakelockPlus.toggle(
      enable: _settingsService.settings.keepScreenAwake,
    );
    Future.delayed(const Duration(seconds: 4), () {
      ForegroundServiceManager().stopService();
    });

    _timer?.cancel();
    if (_startTime != null) {
      _totalDuration = DateTime.now().difference(_startTime!);
    }

    // Auto-clean cached input video from file_picker so app storage doesn't bloat to 1GB+
    if (result != null) {
      await CacheManagerService().clearAllCache(
        specificInputPath: widget.videoInfo.filePath,
      );
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
        if (result != null) {
          _isSuccess = true;
          _outputPath = result;
          _statusText = l10n.t('proc_completed');
        } else {
          _isSuccess = false;
          _statusText = l10n.t('proc_failed');
        }
      });

      if (result != null) {
        _showSuccessBottomSheet();
      }
    }
  }

  void _showSuccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _SuccessBottomSheet(
          originalPath: widget.videoInfo.filePath,
          outputPath: _outputPath!,
          originalSize: widget.videoInfo.fileSizeBytes,
          totalDuration: _totalDuration ?? Duration.zero,
          avgSpeed: _speedText,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = _settingsService.l10n;

    return WithForegroundTask(
      child: PopScope(
        canPop: !_isProcessing,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _isProcessing) {
            _showCancelDialog();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.t('proc_title')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                if (_isProcessing) {
                  _showCancelDialog();
                } else {
                  CacheManagerService().clearAllCache(
                    specificInputPath: widget.videoInfo.filePath,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildProgressSection(theme, l10n),
                  const SizedBox(height: 24),
                  _buildTimeTelemetryCard(theme, l10n),
                  const SizedBox(height: 16),
                  _buildInfoSection(theme, l10n),
                  const SizedBox(height: 28),
                  if (!_isProcessing) _buildActionButtons(theme, l10n),
                  if (_isProcessing) _buildCancelButton(theme, l10n),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme, l10n) {
    final progressColor = _isProcessing
        ? theme.colorScheme.primary
        : (_isSuccess ? const Color(0xFF5CD85A) : const Color(0xFFFF6B6B));

    return Column(
      children: [
        // Main circular progress
        SizedBox(
          width: 190,
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 190,
                height: 190,
                child: CircularProgressIndicator(
                  value: _isProcessing
                      ? (_progress > 0 ? _progress : null)
                      : (_isSuccess ? 1.0 : 0.0),
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  color: progressColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isProcessing)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: 0.5 + (_pulseController.value * 0.5),
                          child: Icon(
                            Icons.movie_filter_rounded,
                            size: 36,
                            color: theme.colorScheme.primary,
                          ),
                        );
                      },
                    )
                  else
                    Icon(
                      _isSuccess
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      size: 48,
                      color: progressColor,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _isProcessing
                        ? _formatPercentage(_progress)
                        : (_isSuccess ? '100%' : 'Error'),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: progressColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (_isProcessing && _speedText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _speedText,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withAlpha(130),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),
        const SizedBox(height: 16),
        Text(
          _statusText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Real-time live Elapsed & Remaining Time Telemetry Card
  Widget _buildTimeTelemetryCard(ThemeData theme, l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.timer_rounded,
                    iconColor: const Color(0xFF54A0FF),
                    label: l10n.t('proc_elapsed_time'),
                    value: _formatDuration(_isProcessing ? _elapsedDuration : (_totalDuration ?? _elapsedDuration)),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white12,
                ),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.hourglass_bottom_rounded,
                    iconColor: const Color(0xFFFF9F43),
                    label: l10n.t('proc_remaining_time'),
                    value: _isProcessing
                        ? (_estimatedRemaining != null
                            ? '~${_formatDuration(_estimatedRemaining!)}'
                            : l10n.t('proc_calculating'))
                        : (_isSuccess ? l10n.t('proc_completed') : '-'),
                  ),
                ),
              ],
            ),
            if (_isProcessing && (_speedText.isNotEmpty || _currentSizeText.isNotEmpty)) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (_speedText.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.speed_rounded, size: 16, color: Color(0xFF5CD85A)),
                        const SizedBox(width: 6),
                        Text(
                          '${l10n.t('fps')}: $_speedText',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  if (_currentSizeText.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.storage_rounded, size: 16, color: Color(0xFF54A0FF)),
                        const SizedBox(width: 6),
                        Text(
                          '${l10n.t('file_size')}: $_currentSizeText',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                ],
              ),
            ],
            if (!_isProcessing && _totalDuration != null && _isSuccess) ...[
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF5CD85A)),
                  const SizedBox(width: 8),
                  Text(
                    l10n.t('proc_total_time', args: {'time': _formatDuration(_totalDuration!)}),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5CD85A),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(ThemeData theme, l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              l10n.t('proc_source'),
              widget.videoInfo.resolution,
              '${widget.videoInfo.width}x${widget.videoInfo.height}',
            ),
            const Divider(height: 20),
            _buildInfoRow(
              l10n.t('proc_target'),
              widget.targetResolution.label,
              '${widget.targetResolution.width}x${widget.targetResolution.height} • ${widget.encodingOptions.codec.displayName.split(' ').first}',
            ),
            const Divider(height: 20),
            _buildInfoRow(
              l10n.t('container_format'),
              widget.encodingOptions.container.displayName,
              widget.encodingOptions.codec.displayName,
            ),
            if (_isSuccess && _outputPath != null) ...[
              const Divider(height: 20),
              FutureBuilder<int>(
                future: File(_outputPath!).length(),
                builder: (context, snapshot) {
                  final size = snapshot.data ?? 0;
                  String sizeStr;
                  if (size >= 1073741824) {
                    sizeStr = '${(size / 1073741824).toStringAsFixed(2)} GB';
                  } else if (size >= 1048576) {
                    sizeStr = '${(size / 1048576).toStringAsFixed(1)} MB';
                  } else {
                    sizeStr = '${(size / 1024).toStringAsFixed(0)} KB';
                  }
                  final isBigger = size > widget.videoInfo.fileSizeBytes;
                  final diffPercent = widget.videoInfo.fileSizeBytes > 0
                      ? ((size - widget.videoInfo.fileSizeBytes).abs() /
                              widget.videoInfo.fileSizeBytes *
                              100)
                          .toStringAsFixed(0)
                      : '0';
                  final savingsBadge = isBigger
                      ? l10n.t('proc_size_increase', args: {'percent': diffPercent})
                      : l10n.t('proc_savings', args: {'percent': diffPercent});
                  return _buildInfoRow(
                    l10n.t('proc_output_size'),
                    sizeStr,
                    savingsBadge,
                  );
                },
              ),
              const Divider(height: 20),
              _buildInfoRow(
                l10n.t('proc_saved_location'),
                l10n.t('proc_saved_path'),
                _outputPath?.split(Platform.pathSeparator).last ?? '',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, l10n) {
    if (_isSuccess) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openOutputFile,
              icon: const Icon(Icons.folder_open_rounded),
              label: Text(l10n.t('proc_open_file')),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(l10n.t('proc_back')),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Detail Error',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _errorMessage!,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isProcessing = true;
                  _progress = 0;
                  _statusText = l10n.t('proc_preparing');
                  _speedText = '';
                  _currentSizeText = '';
                  _errorMessage = null;
                });
                _startProcessing();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.t('proc_retry')),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                CacheManagerService().clearAllCache(
                  specificInputPath: widget.videoInfo.filePath,
                );
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(l10n.t('proc_back')),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildCancelButton(ThemeData theme, l10n) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showCancelDialog,
        icon: const Icon(Icons.cancel_rounded),
        label: Text(l10n.t('proc_cancel')),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF6B6B),
          side: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
      ),
    );
  }

  void _showCancelDialog() {
    final l10n = _settingsService.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('proc_cancel_title')),
        content: Text(l10n.t('proc_cancel_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.t('proc_no')),
          ),
          TextButton(
            onPressed: () {
              ForegroundServiceManager().stopService();
              FFmpegService.cancelAll();
              CacheManagerService().clearAllCache(
                specificInputPath: widget.videoInfo.filePath,
              );
              Navigator.of(context).pop();
              Navigator.of(this.context).pop();
            },
            child: Text(
              l10n.t('proc_yes_cancel'),
              style: const TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }

  static String? getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp4':
        return 'video/mp4';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'video/*';
    }
  }

  void _openOutputFile() {
    if (_outputPath != null) {
      OpenFile.open(_outputPath!, type: getMimeType(_outputPath!));
    }
  }
}

class _SuccessBottomSheet extends StatelessWidget {
  final String originalPath;
  final String outputPath;
  final int originalSize;
  final Duration totalDuration;
  final String avgSpeed;

  const _SuccessBottomSheet({
    required this.originalPath,
    required this.outputPath,
    required this.originalSize,
    required this.totalDuration,
    required this.avgSpeed,
  });

  String _formatSize(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    } else if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = SettingsService().l10n;
    final outputSize = File(outputPath).lengthSync();
    final isBigger = outputSize > originalSize;
    final diffRatio = originalSize > 0
        ? ((outputSize - originalSize).abs() / originalSize * 100).toStringAsFixed(1)
        : '0';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF5CD85A), size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.t('proc_completed'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(l10n.t('proc_source'), _formatSize(originalSize), Icons.folder_rounded, Colors.white54),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white24),
                _buildStatColumn(l10n.t('proc_target'), _formatSize(outputSize), Icons.folder_special_rounded, theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isBigger
                    ? const Color(0xFFFF9F43).withAlpha(20)
                    : const Color(0xFF5CD85A).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isBigger
                      ? const Color(0xFFFF9F43).withAlpha(60)
                      : const Color(0xFF5CD85A).withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isBigger ? Icons.trending_up_rounded : Icons.save_alt_rounded,
                    color: isBigger ? const Color(0xFFFF9F43) : const Color(0xFF5CD85A),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBigger
                              ? l10n.t('proc_size_increase_title', args: {'percent': diffRatio})
                              : l10n.t('proc_savings_title', args: {'percent': diffRatio}),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isBigger ? const Color(0xFFFF9F43) : const Color(0xFF5CD85A),
                          ),
                        ),
                        if (isBigger) ...[
                          const SizedBox(height: 2),
                          Text(
                            l10n.t('proc_size_increase_hint'),
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                OpenFile.open(
                  outputPath,
                  type: _ProcessingScreenState.getMimeType(outputPath),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.t('proc_play_video')),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // ignore: deprecated_member_use
                Share.shareXFiles([XFile(outputPath)]);
              },
              icon: const Icon(Icons.share_rounded),
              label: Text(l10n.t('share')),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.t('close')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
