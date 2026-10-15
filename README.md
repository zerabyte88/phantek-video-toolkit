# Phantek Video Toolkit

<p align="center">
  <img src="assets/icon/app_icon.png" alt="Phantek App Icon" width="128" height="128" style="border-radius: 28px; box-shadow: 0 10px 30px rgba(0,0,0,0.4);" />
</p>

<p align="center">
  <strong>Offline on-device mobile video transcoding, resolution downscaling, and audio extraction.</strong>
</p>

<div align="center">
  <a href="https://github.com/zerabyte88/phantek-video-toolkit/releases"><img src="https://img.shields.io/static/v1?label=Version&message=v2.7.0&color=E11D48&style=flat-square&logo=github&logoColor=white" alt="Version" /></a>
  <img src="https://img.shields.io/static/v1?label=Platform&message=Android%20(arm64-v8a)&color=059669&style=flat-square&logo=android&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/static/v1?label=Engine&message=Flutter%20%2B%20FFmpeg&color=2563eb&style=flat-square&logo=flutter&logoColor=white" alt="Engine" />
  <img src="https://img.shields.io/static/v1?label=Privacy&message=100%25%20Offline&color=7c3aed&style=flat-square" alt="Privacy" />
  <a href="LICENSE"><img src="https://img.shields.io/static/v1?label=License&message=GPL-3.0&color=334155&style=flat-square&logo=gnu&logoColor=white" alt="License" /></a>
</div>

---

## Overview

**Phantek** is an offline Android utility designed for video transcoding, downscaling, compression, and audio extraction. Built with Flutter and native FFmpeg libraries, it processes all media locally on the device without requiring network access, accounts, or background telemetry.

---

## Features

### 1. Video Processing & Downscaling
* **Resolution Scaling:** Downscale high-resolution videos (4K, 1080p, 720p, 480p, 360p) with aspect ratio preservation and automatic even-dimension alignment to prevent encoder errors.
* **Calibrated Presets:**
  * **Fast (`area` + `veryfast` + CRF 24):** Anti-aliased downsampling prioritizing speed, lower temperatures, and reduced battery use.
  * **Normal (`bicubic` + `faster` + CRF 22):** A balanced default for everyday conversions.
  * **Maximum (`lanczos` + `fast` + CRF 20):** Lanczos interpolation for high detail preservation.
* **Rate Control:** Configurable Constant Rate Factor (CRF 16–28) with a single-tap reset to preset defaults, or custom target bitrate limits (1–20 Mbps).
* **Framerate Selection:** Frame rate adjustments (60, 50, 48, 30, 25, 24 FPS, or custom) with source-rate clamping to avoid unnecessary frame interpolation.
* **Audio Handling:** Stream copy (`-c:a copy`) when the source audio matches the target container, automatic AAC re-encoding when incompatible, or complete audio track removal (`-an`).
* **Container Support:** MP4 (with `-movflags +faststart` for web playback), MKV, and MOV.

### 2. Audio Extraction
* **Output Formats:** Extract audio tracks directly to **MP3** (`libmp3lame`), **M4A** (`aac`), or uncompressed **WAV** (`pcm_s16le`).
* **Stream Copy:** Bypasses audio re-encoding when source formats match the target container for near-instant exports.
* **Custom Bitrates:** User-selectable audio bitrates from 64 kbps to 320 kbps.

### 3. Adaptive Hardware & Resource Management
* **Smart Thread Allocation:** Automatically calculates CPU thread usage based on device RAM, processor tier, and video resolution (e.g., dynamically stepping down thread allocation during 4K tasks to prevent out-of-memory errors).
* **Android SoC & GPU Detection:** Built-in hardware detection covering 64-bit ARM chipsets across Qualcomm Snapdragon, MediaTek Dimensity & Helio, Samsung Exynos, Google Tensor, HiSilicon Kirin, Xiaomi XRING/Surge, Unisoc, and JLQ.
* **Crash & OOM Recovery:** Detects memory pressure and system aborts, automatically suggesting lower thread configurations for stability.
* **Manual Override:** Option to override thread allocation manually from 1 core up to the physical processor limit.

### 4. Background Execution & Telemetry
* **Foreground Service:** Uses Android's `mediaProcessing` foreground service type with a persistent progress notification to prevent process termination when the app is minimized.
* **CPU WakeLock:** Keeps the processor active while the display is turned off during long encoding jobs.
* **Live System Metrics:** Real-time telemetry monitoring encoding progress, current FPS, elapsed/estimated remaining time, CPU usage (%), RSS resident memory (from Linux `/proc/self/status`), and disk write speed (MB/s).
* **Safe Cancellation:** One-tap cancellation that safely halts the FFmpeg process and removes incomplete temporary files.

### 5. Interface & Customization
* **AMOLED Dark Mode:** Pitch-black background (`#000000`) optimized for OLED power savings.
* **Theme Selection:**
  * **Dynamic:** *Snowfall* (Deep Navy), *Midnight* (Charcoal), *Daylight* (Soft Light), and *Sakura* (Dark Pink).
  * **Static:** *AMOLED Pure Black* (0% pixel power on black areas, animation ticker disabled) and *Clean Light* (Pure static light theme).
* **Card Opacity:** Adjustable card transparency using direct alpha blending without backdrop filter performance penalties.
* **Multilingual:** Complete localizations for 22 languages with adaptive layouts to prevent text clipping.

---

## Format & Codec Matrix

| Type | Container | Codec | Configuration Notes |
| :--- | :--- | :--- | :--- |
| **Video** | `.mp4` | H.264 (`libx264`) | Injects `-movflags +faststart` for immediate playback |
| **Video** | `.mkv` | H.264 (`libx264`) | General-purpose container with broad metadata support |
| **Video** | `.mov` | H.264 (`libx264`) | Compatible with desktop and mobile video editors |
| **Audio** | `.mp3` | MP3 (`libmp3lame`) | Standard audio format (64–320 kbps) |
| **Audio** | `.m4a` | AAC (`aac`) | Efficient modern audio compression (64–320 kbps) |
| **Audio** | `.wav` | PCM (`pcm_s16le`) | Uncompressed 16-bit linear PCM audio |

---

## Download & Installation

Download the standalone release APK directly from GitHub Releases:

* **Latest Release:** [Phantek Video Toolkit v2.7.0](https://github.com/zerabyte88/phantek-video-toolkit/releases)
* **File:** `Phantek-Video-Toolkit-arm64-v8a-v2.7.0.apk`
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

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. See the [LICENSE](LICENSE) file for complete details.

---

<div align="center">
  <br/>
  <a href="https://github.com/zerabyte88">
    <img src="https://github.com/zerabyte88.png" width="48" height="48" style="border-radius: 50%;" alt="zerabyte88" />
  </a>
  <br/>
  <sub>Developed with ❤️ by <a href="https://github.com/zerabyte88">zerabyte88</a></sub>
</div>
