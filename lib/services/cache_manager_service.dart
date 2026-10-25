// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 zerabyte88

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CacheManagerService {
  static final CacheManagerService _instance = CacheManagerService._internal();
  factory CacheManagerService() => _instance;
  CacheManagerService._internal();

  /// Recursively calculates directory size.
  Future<int> _getDirSize(Directory dir) async {
    int size = 0;
    try {
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          try {
            size += entity.lengthSync();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error listing dir ${dir.path}: $e');
    }
    return size;
  }

  /// Formats byte counts into human-readable strings.
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    }
    if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }

  /// Cleans cache files and optionally a specific input file.
  Future<int> clearAllCache({String? specificInputPath}) async {
    int bytesFreed = 0;

    // Specific input file
    if (specificInputPath != null && isCachedPath(specificInputPath)) {
      try {
        final f = File(specificInputPath);
        if (await f.exists()) {
          final len = await f.length();
          await f.delete();
          bytesFreed += len;
          debugPrint(
            'Deleted specific cached input file: $specificInputPath ($len bytes)',
          );
        }
      } catch (e) {
        debugPrint('Error deleting specific input file: $e');
      }
    }

    // Native FilePicker temp files
    try {
      await FilePicker.clearTemporaryFiles();
    } catch (e) {
      debugPrint('FilePicker.clearTemporaryFiles error: $e');
    }

    // Internal cache files
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final entities = tempDir.listSync(followLinks: false);
        for (final entity in entities) {
          try {
            if (entity is File) {
              final len = await entity.length();
              await entity.delete();
              bytesFreed += len;
            } else if (entity is Directory) {
              bytesFreed += await _getDirSize(entity);
              await entity.delete(recursive: true);
            }
          } catch (e) {
            debugPrint('Error deleting ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing tempDir: $e');
    }

    // External cache files
    try {
      final extCacheDirs = await getExternalCacheDirectories();
      if (extCacheDirs != null) {
        for (final dir in extCacheDirs) {
          if (await dir.exists()) {
            final entities = dir.listSync(followLinks: false);
            for (final entity in entities) {
              try {
                if (entity is File) {
                  final len = await entity.length();
                  await entity.delete();
                  bytesFreed += len;
                } else if (entity is Directory) {
                  bytesFreed += await _getDirSize(entity);
                  await entity.delete(recursive: true);
                }
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing extCacheDirs: $e');
    }

    debugPrint('Cache cleared! Total freed: ${formatBytes(bytesFreed)}');
    return bytesFreed;
  }

  /// Returns true if [filePath] resides in a cache or temp directory.
  bool isCachedPath(String path) {
    final lower = path.toLowerCase().replaceAll('\\', '/');
    return lower.contains('/cache/') ||
        lower.contains('/file_picker/') ||
        lower.contains('/tmp/') ||
        lower.contains('/temp/');
  }
}
