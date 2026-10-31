<div align="center">
  <img src="assets/icon/app_icon.png" alt="Phantek Logo" width="120" />

  # Phantek - Video Toolkit

  **Offline video transcoding, downscaling, and audio extraction for Android.**

  [![Release](https://img.shields.io/github/v/release/zerabyte88/phantek-video-toolkit?style=flat-square&color=f97316&logo=github&logoColor=white)](https://github.com/zerabyte88/phantek-video-toolkit/releases)
  [![Platform](https://img.shields.io/badge/Platform-Android%207.0+-10b981?style=flat-square&logo=android&logoColor=white)](https://github.com/zerabyte88/phantek-video-toolkit/releases)
  [![Architecture](https://img.shields.io/badge/Arch-arm64--v8a-8b5cf6?style=flat-square&logo=arm&logoColor=white)](https://github.com/zerabyte88/phantek-video-toolkit/releases)
  [![Engine](https://img.shields.io/badge/Engine-Flutter%20%7C%20FFmpeg-6366f1?style=flat-square)](https://ffmpeg.org)
  [![License](https://img.shields.io/badge/License-GPL--3.0-f59e0b?style=flat-square&logo=open-source-initiative&logoColor=white)](LICENSE)

  [Download APK](https://github.com/zerabyte88/phantek-video-toolkit/releases/latest) • [Features](#features) • [Supported Formats](#supported-formats) • [Tech Stack](#tech-stack) • [Build](#build-from-source) • [License](#license)
</div>

---

**Phantek - Video Toolkit** uses software encoding via `libx264` and native FFmpeg. For hardware-accelerated transcoding via native `MediaCodec` and AndroidX Media3 Transformer, see [phantek-video-toolkit-vega](https://github.com/zerabyte88/phantek-video-toolkit-vega).

---

## Features

- **Software Transcoding** : Encode H.264 (`libx264`) via native FFmpeg (`ffmpeg-kit-full-gpl`).
- **Resolution Downscaling** : Scale 4K down to 1080p, 720p, 480p, or 360p with aspect-ratio preservation and even-pixel alignment (`trunc(iw/2)*2`).
- **Rate Control & Presets** : Constant Rate Factor (CRF 16–28) or target bitrate (1–35 Mbps) with fast, normal, or maximum encoding presets.
- **Framerate Clamping** : Preserve source FPS or clamp to standard rates (24–60 FPS).
- **Audio Extraction** : Extract audio streams to MP3 (64–320 kbps), M4A/AAC, or uncompressed 16-bit PCM WAV, with direct bitstream copy.
- **Adaptive Thread Allocation** : Dynamically bounds CPU threads based on RAM capacity, SoC tier, and video resolution to prevent OOM aborts.
- **Foreground Execution** : Android Foreground Service with CPU `WakeLock` to prevent background termination.
- **Real-Time Telemetry** : Live encoding FPS, elapsed/remaining time, output size estimate, CPU utilization, and RSS memory usage.
- **AMOLED Themes** : Multiple visual themes (*AMOLED Pure*, *Midnight*, *Snowfall*, *Sakura*, *Light*).
- **100% Offline** : Zero network permissions (`android.permission.INTERNET` omitted), no telemetry, and no external trackers.

---

## Supported Formats

<div align="center">

| Type | Container | Codec / Format | Notes |
| :---: | :---: | :---: | :---: |
| **Video** | `.mp4` | H.264 (`libx264`) | Web-optimized with `+faststart` |
| **Video** | `.mkv` | H.264 (`libx264`) | Matroska container |
| **Video** | `.mov` | H.264 (`libx264`) | QuickTime container |
| **Audio** | `.mp3` | MP3 (`libmp3lame`) | 64–320 kbps |
| **Audio** | `.m4a` | AAC (`aac`) | 64–320 kbps |
| **Audio** | `.wav` | PCM (`pcm_s16le`) | 16-bit linear uncompressed PCM |

</div>

---

## Tech Stack

<div align="center">

| Layer | Package / Tool | Role |
| :---: | :---: | :---: |
| **Framework** | Flutter (Dart SDK `^3.13`) | Core UI and state management |
| **Media Engine** | FFmpeg (`ffmpeg_kit_flutter_new`) | Software transcoding, filtering, and muxing pipeline |
| **Background** | `flutter_foreground_task`, `wakelock_plus` | Foreground service execution and CPU wake lock |
| **System Info** | `device_info_plus` | Hardware tier detection and adaptive thread allocation |
| **Storage & I/O** | `shared_preferences`, `file_picker` | Settings persistence, file selection, and media scanning |

</div>

---

## Build from Source

### Prerequisites

- Flutter SDK `^3.13`
- Android SDK, NDK & Java 17+

### Steps

```bash
# Clone repository
git clone https://github.com/zerabyte88/phantek-video-toolkit.git
cd phantek-video-toolkit

# Install dependencies
flutter pub get

# Build release APK (arm64-v8a)
flutter build apk --release --split-per-abi --target-platform android-arm64
```

Compiled binary : `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

---

## License

This project is licensed under the **GNU General Public License v3.0 or later (GPL-3.0-or-later)**. See [LICENSE](LICENSE) for details.

### Third-Party Licenses & Acknowledgments

- **FFmpeg:** Uses libraries from the [FFmpeg](https://ffmpeg.org) project under the GNU General Public License v3.0 (compiled with `libx264` support). FFmpeg is a trademark of Fabrice Bellard, originator of the FFmpeg project.
- **FFmpegKit:** Built using [ffmpeg-kit](https://github.com/arthenica/ffmpeg-kit) / `ffmpeg_kit_flutter_new` under GPLv3 (see [LICENSE.ffmpegkit](LICENSE.ffmpegkit) and [LICENSE.ffmpegkit.GPLv3](LICENSE.ffmpegkit.GPLv3)).
- **Flutter & Dependencies:** Third-party Dart/Flutter packages are licensed under their respective open-source licenses (BSD, MIT, Apache 2.0). Complete open-source licenses can be inspected directly in the app under **Settings > About > License**.
