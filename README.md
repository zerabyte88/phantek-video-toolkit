# Phantek Video Toolkit

<p align="center">
  <img src="assets/icon/app_icon.png" alt="Phantek App Icon" width="128" height="128" style="border-radius: 28px; box-shadow: 0 10px 30px rgba(0,0,0,0.4);" />
</p>

<p align="center">
  <strong>Fast, offline, on-device mobile video transcoding, resolution downscaling, and audio extraction.</strong>
</p>

<div align="center">
  <a href="https://github.com/zerabyte88/phantek-video-toolkit/releases"><img src="https://img.shields.io/static/v1?label=Version&message=v2.6.0&color=E11D48&style=flat-square&logo=github&logoColor=white" alt="Version" /></a>
  <img src="https://img.shields.io/static/v1?label=Platform&message=Android%20(arm64-v8a)&color=059669&style=flat-square&logo=android&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/static/v1?label=Engine&message=Flutter%20%2B%20FFmpeg&color=2563eb&style=flat-square&logo=flutter&logoColor=white" alt="Engine" />
  <img src="https://img.shields.io/static/v1?label=Privacy&message=100%25%20Offline&color=7c3aed&style=flat-square" alt="Privacy" />
  <a href="LICENSE"><img src="https://img.shields.io/static/v1?label=License&message=GPL-3.0&color=334155&style=flat-square&logo=gnu&logoColor=white" alt="License" /></a>
</div>

---

## Overview

**Phantek Video Toolkit** is a lightweight, privacy-first Android utility engineered for local media manipulation without cloud dependencies, subscriptions, or telemetry. Powered by native FFmpeg C/C++ libraries wrapped in Flutter, it delivers studio-grade video transcoding, intelligent downscaling, storage-saving compression, and lossless audio extraction directly on your device.

---

## Core Capabilities

### 1. Video Processing & Downscaling
* **Resolution Ladder:** Downscale high-resolution videos (4K, 1080p, 720p, 480p, 360p) with automatic aspect-ratio preservation and even-dimension alignment to eliminate image distortion.
* **Single-Pass Rescaling:** Pre-calculates target geometry directly on the application layer to minimize CPU overhead and memory bandwidth.
* **Calibrated Mobile Speed Presets:**
  * **Fast (`area` + `veryfast` + CRF 24):** Anti-aliased downsampling prioritizing battery life, minimal heat, and rapid turnaround.
  * **Normal (`bicubic` + `faster` + CRF 22):** The recommended balance between visual fidelity and encoding speed.
  * **Maximum (`lanczos` + `fast` + CRF 20):** High-precision Lanczos sinc interpolation paired with full chroma reconstruction for studio sharpness.
* **Flexible Rate Control:** Interactive CRF slider (with 1-tap preset reset) alongside explicit target bitrate limits (500 kbps to 20,000 kbps).
* **Thermal & Battery Guard:** Automatic high-load warnings and confirmation dialogs when processing 4K or 30+ minute clips on intense presets.
* **Smart Audio Passthrough:** Direct stream copy (`-c:a copy`) when source audio parameters match the target container, eliminating unnecessary audio re-encoding.

### 2. Standalone Audio Extraction
* **Zero-Loss Extraction:** Extract audio tracks directly from videos into **MP3**, **M4A (AAC)**, or uncompressed **WAV (PCM 16-bit)**.
* **Stream Copy:** Bypasses audio re-encoding when the source audio format aligns with the requested container for near-instant exports.
* **Custom Audio Quality:** User-selectable bitrates ranging from 64 kbps up to 320 kbps (Studio Quality).

### 3. Background Persistence & Real-Time Telemetry
* **Foreground Service Execution:** Utilizes Android's official `mediaProcessing` foreground service type to prevent system termination when minimized.
* **CPU Wakelock:** Ensures continuous processing even when the display turns off.
* **Live System Metrics:** Real-time monitoring of CPU utilization (%), physical resident memory (RSS from Linux `/proc/self/status`), and disk write throughput (MB/s).

### 4. Minimalist AMOLED Architecture
* **True Pitch-Black Design:** Battery-saving `#000000` AMOLED canvas with smooth theme modes (*Snowfall*, *Midnight*, *Daylight*, and hidden *Sakura*).
* **Zero-Cost Translucency:** Card opacity slider utilizing native GPU alpha tinting instead of expensive offscreen backdrop filters.
* **Global Localization:** Comprehensive translations across 22 languages without text truncation or awkward layout overflow.

---

## Format & Codec Matrix

| Type | Container | Codec | Features |
| :--- | :--- | :--- | :--- |
| **Video** | `.mp4` | H.264 (`libx264`) | Injects `-movflags +faststart` for instant streaming playback |
| **Video** | `.mkv` | H.264 (`libx264`) | Versatile container supporting rich metadata |
| **Video** | `.mov` | H.264 (`libx264`) | Universal compatibility across mobile & desktop editors |
| **Audio** | `.mp3` | MP3 (`libmp3lame`) | Universal compatibility (64–320 kbps) |
| **Audio** | `.m4a` | AAC (`aac`) | High acoustic fidelity with compact file footprint |
| **Audio** | `.wav` | PCM (`pcm_s16le`) | Uncompressed lossless 16-bit studio acoustics |

---

## Download & Installation

Download the latest standalone release APK directly from GitHub Releases:

* **Latest Release:** [Phantek Video Toolkit v2.6.0](https://github.com/zerabyte88/phantek-video-toolkit/releases)
* **File:** `Phantek-Video-Toolkit-arm64-v8a-v2.6.0.apk`
* **Target Architecture:** `arm64-v8a` (64-bit ARM)
* **Minimum Android Version:** Android 8.0 (API Level 26) or higher

---

## Building from Source

### Prerequisites
* [Flutter SDK](https://flutter.dev) (v3.13+ or later)
* Android SDK & NDK installed and configured
* Java 17+

### Build Command

```bash
# Clone the repository
git clone https://github.com/zerabyte88/phantek-video-toolkit.git
cd phantek-video-toolkit

# Fetch dependencies
flutter pub get

# Compile optimized release APK for 64-bit ARM
flutter build apk --release --split-per-abi --target-platform android-arm64
```

The generated APK will be available under:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

---

## Privacy & Security

Phantek Video Toolkit operates under a strict privacy-first architecture:

* **No Internet Permission:** The application does **not** declare or request `android.permission.INTERNET`. No network calls, telemetry packets, or analytics can leave your device.
* **On-Device File Operations:** All files are ingested, transcoded, and stored locally within your device storage or designated output folders.
* **No Accounts / Trackers:** No registration, third-party advertising SDKs, or tracking libraries are included in the codebase.

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. See the [LICENSE](LICENSE) file for complete details.

---

<p align="center">
  <sub>Engineered with precision by <a href="https://github.com/zerabyte88">zerabyte88</a></sub>
</p>
