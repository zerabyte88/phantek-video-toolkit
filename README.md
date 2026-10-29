<p align="center">
  <img src="assets/icon/app_icon.png" width="120" height="120" alt="Phantek Logo" />
</p>

<h1 align="center">Phantek - Video Toolkit</h1>

<p align="center">
  <strong>Offline, on-device video transcoding, downscaling, and audio extraction for Android.</strong>
</p>

<p align="center">
  <a href="https://github.com/zerabyte88/phantek-video-toolkit/releases/latest"><img src="https://img.shields.io/github/v/release/zerabyte88/phantek-video-toolkit?style=flat-square&color=E11D48" alt="Version" /></a>
  <img src="https://img.shields.io/badge/Platform-Android%207.0%2B-059669?style=flat-square&logo=android&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/Arch-arm64--v8a-2563eb?style=flat-square" alt="Architecture" />
  <img src="https://img.shields.io/badge/Engine-Flutter%20%7C%20FFmpeg-6366f1?style=flat-square" alt="Engine" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL--3.0-334155?style=flat-square" alt="License" /></a>
</p>

<p align="center">
  <a href="https://github.com/zerabyte88/phantek-video-toolkit/releases/latest"><b>Download APK</b></a> •
  <a href="#features">Features</a> •
  <a href="#supported-formats">Formats</a> •
  <a href="#installation">Installation</a> •
  <a href="#building-from-source">Build</a> •
  <a href="#privacy--security">Privacy</a> •
  <a href="#license">License</a>
</p>

---

## Overview

**Phantek** is an offline Android media utility built with Flutter and native FFmpeg (`ffmpeg-kit-full-gpl`). It performs video transcoding, downscaling, compression, and audio extraction directly on your device—requiring zero network access, no accounts, and no background tracking.

---

## Features

### Video Processing & Downscaling
- **Resolution Downscaling:** Scale from 4K down to 360p with aspect-ratio preservation and automatic even-dimension alignment (`trunc(iw/2)*2`).
- **Rate Control Modes:** Constant Rate Factor (CRF 16–28) for visual fidelity or deterministic Target Bitrate (1–35 Mbps) for exact file sizes.
- **Encoding Presets:** Fast (`veryfast` / `area`), Normal (`faster` / `bicubic`), and Maximum (`fast` / `lanczos`).
- **Framerate Clamping:** Preserve source FPS or clamp to standard rates (24, 25, 30, 48, 50, 60 FPS).
- **Audio Handling:** Direct stream copy (`copy`), high-efficiency AAC re-encoding, or audio stripping (`-an`).
- **Web-Optimized Output:** Exports to `.mp4` (with `-movflags +faststart` for instant web streaming), `.mkv`, and `.mov`.

### Audio Extraction
- **Outputs:** Extract to **MP3** (`libmp3lame`), **M4A / AAC** (`aac`), or lossless uncompressed **WAV** (`pcm_s16le`).
- **Direct Bitstream Copy:** Preserves original audio streams without re-encoding when formats match.
- **Bitrate Options:** Selectable bitrates from 64 to 320 kbps.

### Hardware & Performance
- **Adaptive Thread Allocation:** Dynamically bounds CPU threads based on RAM capacity, SoC tier, and video resolution to eliminate Out-Of-Memory (OOM) aborts.
- **Foreground Reliability:** Runs as an Android Foreground Service with CPU WakeLock to prevent termination when the screen is locked.
- **Real-Time Telemetry:** Monitors encoding FPS, elapsed/remaining time, output size estimate, CPU utilization, and RSS memory usage.

---

## Supported Formats

| Type | Container | Codec | Notes |
| :--- | :--- | :--- | :--- |
| **Video** | `.mp4` | H.264 (`libx264`) | Optimized with `+faststart` |
| **Video** | `.mkv` | H.264 (`libx264`) | Wide container compatibility |
| **Video** | `.mov` | H.264 (`libx264`) | Compatible with standard mobile & desktop editors |
| **Audio** | `.mp3` | MP3 (`libmp3lame`) | 64–320 kbps |
| **Audio** | `.m4a` | AAC (`aac`) | 64–320 kbps |
| **Audio** | `.wav` | PCM (`pcm_s16le`) | 16-bit linear uncompressed PCM |

---

## Installation

Download the signed APK from [GitHub Releases](https://github.com/zerabyte88/phantek-video-toolkit/releases/latest).

* **Architecture:** `arm64-v8a` (64-bit ARM)
* **Minimum Android Version:** Android 7.0 (API Level 24) or higher

---

## Building from Source

### Prerequisites
* [Flutter SDK](https://flutter.dev) (v3.13+)
* Android SDK & NDK
* Java 17+

### Build

```bash
# Clone the repository
git clone https://github.com/zerabyte88/phantek-video-toolkit.git
cd phantek-video-toolkit

# Get dependencies
flutter pub get

# Build release APK (arm64-v8a)
flutter build apk --release --split-per-abi --target-platform android-arm64
```

The output APK will be generated at:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

---

## Privacy & Security

* **No Network Access:** The app does not request `android.permission.INTERNET`. No network traffic can leave the device.
* **100% Local:** All operations, temporary caches, and output files stay strictly on local storage.
* **Zero Telemetry:** No analytics, advertising frameworks, or user trackers.

---

## License

This project is licensed under the **GNU General Public License v3.0 or later (GPL-3.0-or-later)**. See [LICENSE](LICENSE) for details.

### Third-Party Licenses & Acknowledgments

* **FFmpeg:** Uses libraries from the [FFmpeg](https://ffmpeg.org) project under the GNU General Public License v3.0 (compiled with `libx264` support). FFmpeg is a trademark of Fabrice Bellard, originator of the FFmpeg project.
* **FFmpegKit:** Built using [ffmpeg-kit](https://github.com/arthenica/ffmpeg-kit) / `ffmpeg_kit_flutter_new` under GPLv3 (see [LICENSE.ffmpegkit](LICENSE.ffmpegkit) and [LICENSE.ffmpegkit.GPLv3](LICENSE.ffmpegkit.GPLv3)).
* **Flutter & Dependencies:** Third-party Dart/Flutter packages are licensed under their respective open-source licenses (BSD, MIT, Apache 2.0). Complete open-source licenses can be inspected directly in the app under **Settings > About > License**.