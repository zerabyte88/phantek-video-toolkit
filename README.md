<p align="center">
  <img src="assets/icon/app_icon.png" width="130" height="130" alt="Phantek Logo" />
</p>

<h1 align="center">Phantek - Video Toolkit</h1>

<p align="center">
  <strong>Offline on-device mobile video transcoding, resolution downscaling, and audio extraction.</strong>
</p>

<div align="center">
  <a href="https://github.com/zerabyte88/phantek-video-toolkit/releases"><img src="https://img.shields.io/static/v1?label=Version&message=v2.9.3&color=E11D48&style=flat-square&logo=github&logoColor=white" alt="Version" /></a>
  <img src="https://img.shields.io/static/v1?label=Platform&message=Android%20(arm64-v8a)&color=059669&style=flat-square&logo=android&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/static/v1?label=Engine&message=Flutter%20%2B%20FFmpeg&color=2563eb&style=flat-square&logo=flutter&logoColor=white" alt="Engine" />
  <img src="https://img.shields.io/static/v1?label=Privacy&message=100%25%20Offline&color=7c3aed&style=flat-square" alt="Privacy" />
  <a href="LICENSE"><img src="https://img.shields.io/static/v1?label=License&message=GPL-3.0%20or%20later&color=334155&style=flat-square&logo=gnu&logoColor=white" alt="License" /></a>

  <p>
    <a href="https://github.com/zerabyte88/phantek-video-toolkit/releases/latest"><b>Download APK</b></a> •
    <a href="#overview">Overview</a> •
    <a href="#features">Features</a> •
    <a href="#format--codec-matrix">Formats</a> •
    <a href="#building-from-source">Build</a> •
    <a href="#privacy--security">Privacy</a>
  </p>
</div>

---

## Overview

**Phantek** is an offline Android utility designed for video transcoding, downscaling, compression, and audio extraction. Built with Flutter and native FFmpeg libraries, it processes all media locally on the device without requiring network access, accounts, or background telemetry.

---

## Features

### 1. Video Processing & Downscaling
* **Native Single-File Selection:** Seamlessly integrated with Android's visual media picker in single-selection mode (`FilePicker.pickFile`). Tapping any video selects it immediately without confusing checkboxes or accidental multi-file selection.
* **Resolution Scaling:** Downscale videos (4K, 1440p 2K, 1080p, 720p, 480p, 360p) with aspect ratio preservation and automatic even-dimension alignment to prevent encoder errors.
* **Processing Safeguard:** Automatically detects intensive encoding tasks and presents a safety confirmation dialog to prevent accidental battery drain or thermal throttling.
* **Encoding Speed Presets:** Configured globally in Settings and synchronized to the conversion options card:
  * **Fast:** Uses `area` scaling filter, `veryfast` encoder preset, and default CRF 24.
  * **Normal:** Uses `bicubic` scaling filter, `faster` encoder preset, and default CRF 22.
  * **Maximum:** Uses `lanczos` scaling filter, `fast` encoder preset, and default CRF 20.
* **Rate Control:** Configurable Constant Rate Factor (CRF 16-28) with an interactive reset button to restore the active preset default, or custom target bitrate limits (1-20 Mbps).
* **Framerate Selection:** Frame rate adjustments (Original, 60, 50, 48, 30, 25, 24 FPS, or custom FPS) with source-rate clamping to avoid exceeding the input video frame rate.
* **Audio Handling:** Stream copy (`-c:a copy`) when the source audio format is compatible with the target container, automatic AAC re-encoding when incompatible or when custom bitrate is set, or audio track removal (`-an`).
* **Container Support:** MP4 (with `-movflags +faststart` for streaming and web playback compatibility), MKV, and MOV.

### 2. Audio Extraction
* **Output Formats:** Extract audio tracks directly to **MP3** (`libmp3lame`), **M4A** (`aac`), or uncompressed **WAV** (`pcm_s16le`).
* **Stream Copy:** Copies the original audio stream directly without re-encoding when the source stream matches the target container.
* **Audio Bitrates:** Selectable bitrates (64, 128, 192, 256, 320 kbps) for compressed audio outputs.

### 3. Hardware & Resource Management
* **Adaptive Thread Allocation:** Calculates recommended CPU thread usage based on available RAM, processor hierarchy, and video resolution. Locks allocation to 4 threads on entry-level SoCs or RAM <= 4 GB to eliminate out-of-memory (OOM) crashes, while scaling adaptively up to 7 threads for 4K on high-end chipsets.
* **Android SoC & GPU Detection:** Built-in hardware detection covering 64-bit ARM chipsets across Qualcomm Snapdragon, MediaTek Dimensity & Helio, Samsung Exynos, Google Tensor, HiSilicon Kirin, Xiaomi XRING/Surge, Unisoc, and JLQ.
* **Out-Of-Memory (OOM) Crash Recovery:** Detects memory pressure or process aborts during encoding, records failure markers, and alerts the user to adjust thread count, resolution, or buffer settings upon restart.
* **CPU Thread Selection:** Auto-allocation or manual selection (1, 2, 4, 6, 8 cores clamped to physical core count) with warnings if core selection exceeds safe RAM limits.
* **RAM Buffer Configuration:** Selectable caching buffer limits (256 MB, 512 MB, 1024 MB, 2048 MB) in Settings.
* **Default Audio Bitrate:** Global video audio quality setting in Settings (Mute, 64, 128, 192, 256, 320 kbps).

### 4. Background Execution & Telemetry
* **Foreground Service:** Uses Android's `mediaProcessing` foreground service type with a persistent notification to keep the task running when the app is minimized.
* **CPU WakeLock:** Keeps the processor active while the display is turned off during encoding tasks.
* **Live System Telemetry:** Real-time monitoring of encoding progress (%), current FPS, elapsed time, estimated remaining time, CPU load (%), RSS resident memory (read from `/proc/self/status`), and disk write speed (MB/s).
* **Task Cancellation:** Halts the active FFmpeg session cleanly and removes incomplete temporary files.

### 5. Interface & Customization
* **Theme Selection:**
  * **Dynamic Themes:**
    * *Snowfall*: Deep pure black AMOLED canvas with drifting snowflakes, 7 medieval kingdom cottages with glowing warm lantern windows, and lush evergreen pines.
    * *Midnight*: Pure black AMOLED canvas with glowing celestial moon, twinkling stars, and shooting meteors.
    * *Sakura*: Deep dark AMOLED canvas with falling cherry blossom petals.
    * *Daylight*: Bright daytime theme with floating sunlight particle dynamics.
  * **Static Themes:**
    * *Pure AMOLED*: Solid pitch black AMOLED canvas with animation ticker disabled for maximum battery conservation.
    * *Clean Light*: Minimalist light canvas without background animations.
* **Theme Card Layout:** Elegant centered card titles and badges (`AMOLED`, `LIGHT`, `STATIC`) with intuitive theme icons.
* **Card Opacity:** Adjustable card transparency slider using direct alpha blending.
* **Multilingual:** Complete UI localizations for 22 languages with adaptive layouts to prevent text clipping.

---

## Format & Codec Matrix

| Type | Container | Codec | Configuration Notes |
| :--- | :--- | :--- | :--- |
| **Video** | `.mp4` | H.264 (`libx264`) | Injects `-movflags +faststart` for web and streaming playback |
| **Video** | `.mkv` | H.264 (`libx264`) | General-purpose container with broad metadata support |
| **Video** | `.mov` | H.264 (`libx264`) | Compatible with desktop and mobile video editors |
| **Audio** | `.mp3` | MP3 (`libmp3lame`) | Standard audio format (64-320 kbps) |
| **Audio** | `.m4a` | AAC (`aac`) | AAC audio encoding (64-320 kbps) |
| **Audio** | `.wav` | PCM (`pcm_s16le`) | Uncompressed 16-bit linear PCM audio |

---

## Download & Installation

Download the standalone release APK directly from GitHub Releases:

* **Latest Release:** [Phantek Video Toolkit v2.9.3](https://github.com/zerabyte88/phantek-video-toolkit/releases)
* **File:** `Phantek-Video-Toolkit-arm64-v8a-v2.9.3.apk`
* **Architecture:** `arm64-v8a` (64-bit ARM)
* **Minimum Android Version:** Android 8.0 (API Level 26) or higher

---

## Building from Source

### Prerequisites
* [Flutter SDK](https://flutter.dev) (v3.13 or higher)
* Android SDK & NDK configured
* Java 17 or higher

### Build Instructions

```bash
# Clone the repository
git clone https://github.com/zerabyte88/phantek-video-toolkit.git
cd phantek-video-toolkit

# Fetch dependencies
flutter pub get

# Build release APK for 64-bit ARM devices
flutter build apk --release --split-per-abi --target-platform android-arm64
```

The compiled APK will be located at:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

---

## Privacy & Security

* **No Internet Permission:** The application does not declare or request `android.permission.INTERNET`. No network requests or telemetry can leave the device.
* **Local Processing:** All media conversions and temporary files remain strictly on the local file system.
* **No Third-Party SDKs:** Contains zero analytics, advertising libraries, or user tracking components.

---

## License

This project is licensed under the **GNU General Public License v3.0 or later (GPL-3.0-or-later)**. See the [LICENSE](LICENSE) file for complete details. A full list of third-party components and their licenses is in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Third-Party Licenses & Acknowledgments

* **FFmpeg:** This software uses libraries from the [FFmpeg](https://ffmpeg.org) project under the GNU General Public License v3.0 (compiled with `libx264` support). FFmpeg is a trademark of Fabrice Bellard, originator of the FFmpeg project.
* **FFmpegKit:** Built using [ffmpeg-kit](https://github.com/arthenica/ffmpeg-kit) / `ffmpeg_kit_flutter_new` under GPLv3 (see [LICENSE.ffmpegkit](LICENSE.ffmpegkit) and [LICENSE.ffmpegkit.GPLv3](LICENSE.ffmpegkit.GPLv3)).
* **Flutter & Dependencies:** Third-party Dart/Flutter packages are licensed under their respective open-source licenses (BSD, MIT, Apache 2.0). Complete open-source licenses can be inspected directly in the app under **Settings > About > License**.
