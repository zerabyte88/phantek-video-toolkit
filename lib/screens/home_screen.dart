import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/video_info.dart';
import '../services/ffmpeg_service.dart';
import '../widgets/video_info_card.dart';
import '../widgets/resolution_selector.dart';
import 'processing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  VideoInfo? _videoInfo;
  VideoResolution? _selectedResolution;
  bool _isLoading = false;

  Future<void> _pickVideo() async {
    final files = await FilePicker.pickFiles(
      type: FileType.video,
    );

    if (files.isNotEmpty) {
      final file = files.first;
      if (file.path == null) return;

      setState(() {
        _isLoading = true;
        _videoInfo = null;
        _selectedResolution = null;
      });

      final info = await FFmpegService.getVideoInfo(file.path!);

      setState(() {
        _isLoading = false;
        _videoInfo = info;
        if (info != null && info.availableDownscaleTargets.isNotEmpty) {
          _selectedResolution = info.availableDownscaleTargets.first;
        }
      });

      if (info == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membaca informasi video'),
          ),
        );
      }
    }
  }

  void _startProcessing() {
    if (_videoInfo == null || _selectedResolution == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProcessingScreen(
          videoInfo: _videoInfo!,
          targetResolution: _selectedResolution!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Downscaler'),
        actions: [
          if (_videoInfo != null)
            IconButton(
              onPressed: () {
                setState(() {
                  _videoInfo = null;
                  _selectedResolution = null;
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset',
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Membaca info video...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              )
            : _videoInfo == null
                ? _buildEmptyState(theme)
                : _buildContent(theme),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.video_settings_rounded,
                size: 64,
                color: theme.colorScheme.primary.withAlpha(180),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Video Downscaler',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Konversi video 4K/2K ke resolusi\nyang lebih kecil dengan mudah',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.video_library_rounded),
                label: const Text('Pilih Video'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FeatureChip(icon: Icons.hd_rounded, label: '4K → 1080p'),
                SizedBox(width: 8),
                _FeatureChip(icon: Icons.speed_rounded, label: 'Cepat'),
                SizedBox(width: 8),
                _FeatureChip(icon: Icons.high_quality_rounded, label: 'Berkualitas'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VideoInfoCard(videoInfo: _videoInfo!),
          const SizedBox(height: 16),
          if (_videoInfo!.availableDownscaleTargets.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 48,
                      color: const Color(0xFF5CD85A).withAlpha(180),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Video sudah beresolusi rendah',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tidak perlu di-downscale',
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_library_rounded),
                      label: const Text('Pilih Video Lain'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ResolutionSelector(
              resolutions: _videoInfo!.availableDownscaleTargets,
              selected: _selectedResolution,
              onSelected: (res) {
                setState(() {
                  _selectedResolution = res;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed:
                    _selectedResolution != null ? _startProcessing : null,
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('Mulai Konversi'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Ganti Video'),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white54),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
