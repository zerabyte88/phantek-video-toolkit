import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../models/app_settings.dart';
import '../models/encoding_options.dart';
import '../models/video_info.dart';
import '../services/ffmpeg_service.dart';
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
  // ignore: unused_field
  String _log = '';
  late AnimationController _pulseController;

  DateTime? _startTime;
  Duration _elapsedDuration = Duration.zero;
  Duration? _estimatedRemaining;
  Duration? _totalDuration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _statusText = _settingsService.l10n.t('proc_preparing');
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _startProcessing();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    if (_isProcessing) {
      FFmpegService.cancelAll();
    }
    super.dispose();
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

    setState(() {
      _statusText = l10n.t('proc_converting');
    });

    // Start 1-second elapsed and ETA timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isProcessing) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      final elapsed = now.difference(_startTime!);

      Duration? remaining;
      if (_progress > 0.02 && _progress < 0.99) {
        final totalEstimatedMs = elapsed.inMilliseconds / _progress;
        final remainingMs = (totalEstimatedMs - elapsed.inMilliseconds).clamp(0, 86400000);
        remaining = Duration(milliseconds: remainingMs.round());
      }

      setState(() {
        _elapsedDuration = elapsed;
        _estimatedRemaining = remaining;
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

          setState(() {
            _progress = progress;
            _speedText = speed;
            _currentSizeText = size;
            _statusText = '${l10n.t('proc_converting')} ${(progress * 100).toStringAsFixed(1)}%';
          });
        }
      },
      onLog: (log) {
        if (mounted) {
          setState(() {
            _log += '$log\n';
            debugPrint(log);
          });
        }
      },
    );

    _timer?.cancel();
    if (_startTime != null) {
      _totalDuration = DateTime.now().difference(_startTime!);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = _settingsService.l10n;

    return PopScope(
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
    );
  }

  Widget _buildProgressSection(ThemeData theme, l10n) {
    return Column(
      children: [
        SizedBox(
          width: 170,
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 170,
                height: 170,
                child: CircularProgressIndicator(
                  value: _isProcessing ? (_progress > 0 ? _progress : null) : (_isSuccess ? 1.0 : 0.0),
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white10,
                  color: _isProcessing
                      ? theme.colorScheme.primary
                      : (_isSuccess
                          ? const Color(0xFF5CD85A)
                          : const Color(0xFFFF6B6B)),
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
                            size: 44,
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
                      size: 52,
                      color: _isSuccess
                          ? const Color(0xFF5CD85A)
                          : const Color(0xFFFF6B6B),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    _isProcessing
                        ? '${(_progress * 100).toStringAsFixed(0)}%'
                        : (_isSuccess ? '100%' : 'Error'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _isProcessing
                          ? theme.colorScheme.onSurface
                          : (_isSuccess
                              ? const Color(0xFF5CD85A)
                              : const Color(0xFFFF6B6B)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _statusText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
                  final savings = widget.videoInfo.fileSizeBytes > 0
                      ? ((1 - size / widget.videoInfo.fileSizeBytes) * 100)
                          .toStringAsFixed(0)
                      : '0';
                  return _buildInfoRow(
                    l10n.t('proc_output_size'),
                    sizeStr,
                    l10n.t('proc_savings', args: {'percent': savings}),
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
                  _log = '';
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
              onPressed: () => Navigator.of(context).pop(),
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
              FFmpegService.cancelAll();
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

  void _openOutputFile() {
    if (_outputPath != null) {
      OpenFile.open(_outputPath!);
    }
  }
}
