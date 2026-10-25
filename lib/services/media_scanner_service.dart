// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 zerabyte88

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MediaScannerService {
  static const MethodChannel _channel =
      MethodChannel('com.phantek.cygnus.albireo/media_scanner');

  /// Scans [filePath] using Android's MediaScannerConnection so it
  /// immediately indexes in the system MediaStore, Gallery, and Music players.
  static Future<bool> scanFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return false;
    if (!Platform.isAndroid) return false;

    try {
      final result =
          await _channel.invokeMethod<bool>('scanFile', {'path': filePath});
      return result ?? false;
    } catch (e) {
      debugPrint('MediaScannerService.scanFile error: $e');
      return false;
    }
  }
}
