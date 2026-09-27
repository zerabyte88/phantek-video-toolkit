import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../models/video_info.dart';
import '../services/ffmpeg_service.dart';

class ProcessingScreen extends StatefulWidget {
  final VideoInfo videoInfo;
  final VideoResolution targetResolution;

  const ProcessingScreen({
    super.key,
    required this.videoInfo,
    required this.targetResolution,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _statusText = 'Mempersiapkan...';
  String _statsText = '';
  bool _isProcessing = true;
  bool _isSuccess = false;
  String? _outputPath;
  // ignore: unused_field
  String _log = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _startProcessing();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (_isProcessing) {
      FFmpegService.cancelAll();
    }
    super.dispose();
  }

  Future<void> _startProcessing() async {
    setState(() {
      _statusText = 'Mengkonversi video...';
    });

    final result = await FFmpegService.downscaleVideo(
      sourceVideo: widget.videoInfo,
      targetResolution: widget.targetResolution,
      onProgress: (progress, stats) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _statsText = stats;
            _statusText = 'Mengkonversi... ${(progress * 100).toStringAsFixed(1)}%';
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

    if (mounted) {
      setState(() {
        _isProcessing = false;
        if (result != null) {
          _isSuccess = true;
          _outputPath = result;
          _statusText = 'Selesai!';
        } else {
          _isSuccess = false;
          _statusText = 'Gagal mengkonversi video';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_isProcessing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isProcessing) {
          _showCancelDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Proses Konversi'),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Spacer(flex: 1),
                _buildProgressSection(theme),
                const SizedBox(height: 32),
                _buildInfoSection(theme),
                const Spacer(flex: 2),
                if (!_isProcessing) _buildActionButtons(theme),
                if (_isProcessing) _buildCancelButton(theme),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
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
                            size: 48,
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
                      size: 56,
                      color: _isSuccess
                          ? const Color(0xFF5CD85A)
                          : const Color(0xFFFF6B6B),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _isProcessing
                        ? '${(_progress * 100).toStringAsFixed(0)}%'
                        : (_isSuccess ? '100%' : 'Error'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _isProcessing
                          ? Colors.white
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
        const SizedBox(height: 24),
        Text(
          _statusText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_statsText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _statsText,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              'Sumber',
              widget.videoInfo.resolution,
              '${widget.videoInfo.width}x${widget.videoInfo.height}',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Target',
              widget.targetResolution.label,
              '${widget.targetResolution.width}x${widget.targetResolution.height}',
            ),
            if (_isSuccess && _outputPath != null) ...[
              const Divider(height: 24),
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
                    'Ukuran output',
                    sizeStr,
                    'Hemat $savings%',
                  );
                },
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

  Widget _buildActionButtons(ThemeData theme) {
    if (_isSuccess) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openOutputFile,
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Buka File'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Kembali'),
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
                  _statusText = 'Mempersiapkan...';
                  _statsText = '';
                  _log = '';
                });
                _startProcessing();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Kembali'),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildCancelButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showCancelDialog,
        icon: const Icon(Icons.cancel_rounded),
        label: const Text('Batalkan'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF6B6B),
          side: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Konversi?'),
        content: const Text('Proses konversi sedang berjalan. Yakin ingin membatalkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              FFmpegService.cancelAll();
              Navigator.of(context).pop();
              Navigator.of(this.context).pop();
            },
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(color: Color(0xFFFF6B6B)),
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
