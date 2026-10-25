<p align="center">
  <img src="assets/icon/app_icon.png" width="130" height="130" alt="Phantek Logo" />
</p>

<h1 align="center">Phantek - Video Toolkit</h1>

<p align="center">
  <strong>Offline on-device mobile video transcoding, resolution downscaling, and audio extraction.</strong>
</p>

<div align="center">
  <a href="https://github.com/zerabyte88/phantek-video-toolkit/releases"><img src="https://img.shields.io/static/v1?label=Version&message=v2.9.4&color=E11D48&style=flat-square&logo=github&logoColor=white" alt="Version" /></a>
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
    <a href="#privacy--security">Privacy</a> •
    <a href="#license">License</a>
  </p>
</div>

---

## Overview

**Phantek** is an offline Android media utility engineered for on-device video transcoding, downscaling, compression, and audio extraction. Built with Flutter and native FFmpeg libraries (`ffmpeg-kit-full-gpl`), it executes all media transformations locally on your hardware without network access, user registration, or background telemetry.

---

## Features

### 1. Video Processing & Downscaling
* **Single-File Media Picker:** Native integration with Android's visual media picker (`FilePicker.pickFile`) in single-selection mode. Tap any video to select and configure it immediately.
* **Resolution Downscaling:** Scale high-resolution videos (4K 2160p, 1440p 2K, 1080p, 720p, 480p, 360p) with aspect ratio preservation and automatic even-dimension alignment (`trunc(iw/2)*2`) to prevent encoder odd-dimension errors.
* **Intensive Task Safeguards:** Automatically analyzes input resolution and duration, presenting a confirmation safeguard on heavy tasks (e.g., 4K or >30 min videos) to prevent unintended battery depletion.
* **Encoding Speed Presets:**
  * **Fast:** Uses `area` scaling filter, `veryfast` encoder preset, and baseline CRF 24 for swift encoding.
  * **Normal:** Uses `bicubic` scaling filter, `faster` encoder preset, and baseline CRF 22 for balanced quality and speed.
  * **Maximum:** Uses `lanczos` scaling filter, `fast` encoder preset, and baseline CRF 20 for sharp detail and chroma accuracy.
* **Rate Control Modes:**
  * **Constant Rate Factor (CRF 16–28):** Visual quality-focused rate control with an instant reset button to revert to the preset default.
  * **Custom Target Bitrate (1–35 Mbps):** Enforces a deterministic bitrate ceiling for file size targeting.
* **Framerate Configuration:** Adjustable framerate (Original, 60, 50, 48, 30, 25, 24 FPS, or custom slider) clamped to the source framerate to prevent redundant duplicate frames.
* **Audio Track Handling:** Direct stream copy (`-c:a copy`) when compatible with target container, automatic high-efficiency AAC re-encoding when custom bitrate is specified, or audio track stripping (`-an`).
* **Container Compatibility:** Output to `.mp4` (with `-movflags +faststart` for instant streaming and web playback), `.mkv`, and `.mov`.

### 2. Audio Extraction
* **Output Formats:** Extract audio tracks to **MP3** (`libmp3lame`), **M4A / AAC** (`aac`), or lossless uncompressed **WAV** (`pcm_s16le` 16-bit linear PCM).
* **Stream Copy:** Copies the original audio bitstream directly without recompression when the stream matches the output container format.
* **Bitrate Selection:** Selectable bitrates for compressed outputs (64, 128, 192, 256, 320 kbps).

### 3. Hardware & Resource Optimization
* **Adaptive Thread Allocation:** Calculates recommended CPU encoding threads based on available device RAM, SoC tier, and video resolution. Automatically constrains entry-level chipsets or devices with <= 4 GB RAM to 4 threads to eliminate Out-Of-Memory (OOM) aborts, while scaling up to 7 threads for 4K on high-end hardware.
* **Comprehensive 64-bit SoC & GPU Detection:** Built-in hardware profiler recognizing ARM chipsets across Qualcomm Snapdragon, MediaTek Dimensity & Helio, Samsung Exynos, Google Tensor, HiSilicon Kirin, Xiaomi Surge/XRING, Unisoc, and JLQ.
* **OOM Crash Recovery:** Automatically identifies unexpected process aborts, records recovery markers, and suggests safer thread count or buffer thresholds upon restart.
* **RAM Buffer Limit:** Selectable caching buffer limits (256 MB, 512 MB, 1024 MB, 2048 MB).
* **Custom Storage Locations:** Configurable target output folders for video and extracted audio, with one-tap reset to default Movies and Music folders.

### 4. Advanced Settings (Deep Encoder Customization)
* **Granular x264 Presets:** Optional override supporting `ultrafast`, `superfast`, `veryfast`, `faster`, `fast`, `medium`, `slow`, `slower`, and `veryslow`.
* **Granular Scaler Algorithms:** Selectable software scaling filters: `fast_bilinear`, `bilinear`, `bicubic`, `area`, `lanczos`, `spline`, and `gauss`.
* **Visual Encoder Badges:** Interactive badges in the conversion card dynamically reflect effective active preset and scaler parameters.

### 5. Background Execution & Live Telemetry
* **Foreground Service:** Compliant with Android 14+ (`mediaProcessing` & `dataSync` service types) with persistent progress notifications to prevent process termination in the background.
* **CPU WakeLock:** Keeps the CPU actively processing while the device screen is off.
* **Live System Telemetry:** Real-time stats during conversion: progress (%), current encoding FPS, elapsed and remaining time, estimated file size, CPU load (%), RSS resident memory (read from `/proc/self/status`), and disk write speed (MB/s).
* **Clean Cancellation:** Immediately stops the active FFmpeg session and cleans up temporary partial files.

### 6. Interface & Customization
* **Dynamic Themes:**
  * *Snowfall:* AMOLED deep black canvas with falling snow particles, glowing medieval cottages, and pine trees.
  * *Midnight:* AMOLED canvas with a glowing celestial moon, twinkling stars, and shooting meteors.
  * *Sakura:* AMOLED canvas with falling cherry blossom petals and branches.
  * *Daylight:* Bright theme with floating sunlight particle dynamics.
* **Static Themes (Zero Background Overhead):**
  * *Pure AMOLED:* Solid pitch-black AMOLED canvas with animation ticker disabled for maximum battery conservation.
  * *Clean Light:* Minimalist clean light canvas without background particle rendering.
* **Card Opacity:** Adjustable surface opacity slider (50% to 100%) for card translucency.
* **Multilingual (22 Languages):** Complete UI translations for Bahasa Indonesia, Bahasa Melayu, Dansk, Deutsch, English, Español, Français, Italiano, Nederlands, Norsk, Português, Suomi, Svenska, Tiếng Việt, Русский, العربية (with RTL support), हिन्दी, ไทย, 日本語, 简体中文, 繁體中文, and 한국어. *(Note: Most translations are generated using AI translators and may contain minor phrasing or contextual inaccuracies. Corrections and contributions are always welcome!)*

---

## Format & Codec Matrix

| Type | Container | Codec | Configuration Notes |
| :--- | :--- | :--- | :--- |
| **Video** | `.mp4` | H.264 (`libx264`) | Injects `-movflags +faststart` for web and streaming playback |
| **Video** | `.mkv` | H.264 (`libx264`) | General-purpose container with broad metadata support |
| **Video** | `.mov` | H.264 (`libx264`) | Compatible with desktop and mobile video editors |
| **Audio** | `.mp3` | MP3 (`libmp3lame`) | Standard audio format (64–320 kbps) |
| **Audio** | `.m4a` | AAC (`aac`) | AAC audio encoding (64–320 kbps) |
| **Audio** | `.wav` | PCM (`pcm_s16le`) | Uncompressed 16-bit linear PCM audio |

---

## Download & Installation

Download the standalone release APK directly from GitHub Releases:

* **Latest Release:** [Phantek Video Toolkit v2.9.4](https://github.com/zerabyte88/phantek-video-toolkit/releases)
* **File:** `Phantek-Video-Toolkit-arm64-v8a-v2.9.4.apk`
* **Architecture:** `arm64-v8a` (64-bit ARM)
* **Minimum Android Version:** Android 7.0 (API Level 24) or higher (Android 8.0+ recommended)

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

* **No Internet Permission:** The application does not declare or request `android.permission.INTERNET`. Zero network requests or telemetry can leave the device.
* **Local Processing:** All media conversions and temporary files remain strictly on the local device file system.
* **No Third-Party SDKs:** Contains zero analytics, advertising libraries, or user tracking components.

---

## License

This project is licensed under the **GNU General Public License v3.0 or later (GPL-3.0-or-later)**. See the [LICENSE](LICENSE) file for complete details. A full list of third-party components and their licenses is available in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Third-Party Licenses & Acknowledgments

* **FFmpeg:** Uses libraries from the [FFmpeg](https://ffmpeg.org) project under the GNU General Public License v3.0 (compiled with `libx264` support). FFmpeg is a trademark of Fabrice Bellard, originator of the FFmpeg project.
* **FFmpegKit:** Built using [ffmpeg-kit](https://github.com/arthenica/ffmpeg-kit) / `ffmpeg_kit_flutter_new` under GPLv3 (see [LICENSE.ffmpegkit](LICENSE.ffmpegkit) and [LICENSE.ffmpegkit.GPLv3](LICENSE.ffmpegkit.GPLv3)).
* **Flutter & Dependencies:** Third-party Dart/Flutter packages are licensed under their respective open-source licenses (BSD, MIT, Apache 2.0). Complete open-source licenses can be inspected directly in the app under **Settings > About > License**.
