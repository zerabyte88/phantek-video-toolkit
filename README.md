# Phantek Video Downscaler

<div align="center">
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/Flutter-3.47.0-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Version-v1.0.7-ff69b4?style=for-the-badge" alt="Version" />
  <img src="https://img.shields.io/badge/License-GPLv3-blue?style=for-the-badge" alt="License" />
</div>

<br/>

**Phantek Video Downscaler** is an advanced, privacy-first, on-device video compression and resolution scaling application built with Flutter and powered by FFmpeg. It is designed to intelligently compress massively oversized videos (4K/2K) into lightweight, highly optimized standard formats (1080p, 720p, etc.) entirely on your local smartphone hardware—no internet required.

---

## 🌟 Key Features

### 🎬 Intelligent Downscaling & Codec Support
- **Resolution Downgrading:** Easily shrink 4K or 2K videos down to 1080p, 720p, 480p, 360p, or 240p. Prevents accidental upscaling of low-res videos.
- **Smart Portrait Detection:** Automatically detects portrait/vertical videos (via rotation metadata) and adjusts target scaling dynamically (e.g., outputs `1080x1920` instead of `1920x1080`), ensuring aspect ratio and orientation are 100% preserved.
- **Advanced Video Codecs:** 
  - **H.264 / AVC:** Universal compatibility.
  - **H.265 / HEVC:** High compression (up to 50% smaller sizes). Injects the Apple/Android compatibility `-tag:v hvc1` specifically for MP4/MOV formats.
  - **VP9:** Extreme compression quality strictly locked to WebM and MKV to prevent Android gallery playback errors.
- **Target Container Formats:** Support for MP4, MKV, MOV, and WebM encoding.

### ⚡ Hardware Acceleration & Resilience
- **MediaCodec Acceleration:** Leverages Android's native silicon encoders (Qualcomm Snapdragon, MediaTek, Exynos) to accelerate H.264 and HEVC exports.
- **Auto-Negotiation & Smart Fallback:** Drops rigid surface formats (using `yuv420p` to let Android auto-negotiate hardware surfaces). If an OEM's hardware encoder crashes or fails to initialize, the app **silently and instantly falls back** to ultra-reliable Software Encoding (`libx264` / `libx265`) without throwing errors.

### 📊 Real-Time Telemetry & UX
- **Live Processing Dashboard:** Shows precise ETA, real-time FPS speed, estimated final file size, and percent progression.
- **Wakelock & Background Persistence:** Powered by `flutter_foreground_task`, transcoding can securely continue even when the phone display turns off or minimizes to the background.
- **Multi-Language Support (6 Languages):** Seamlessly switch between Bahasa Indonesia, English, 日本語, 简体中文, 繁體中文, and 한국어.
- **Modern Adaptive UI:** Deep AMOLED Dark, Standard Dark, and Bright Light themes with fixed bounds and perfect ripple splash handling.

---

## 🛠️ Architecture & FFmpeg Pipeline

```text
┌──────────────────────┐        ┌──────────────────────┐        ┌──────────────────────┐
│    1. Media Input    │ ────> │   2. FFprobe Probe   │ ────> │   3. Media Metadata  │
│   Native Android      │       │  Extract stream specs │       │  Resolution, Codec,   │
│   File Picker         │       │  & container details  │       │  FPS, Bitrate, Audio  │
└──────────────────────┘        └──────────────────────┘        └──────────────────────┘
                                                                            │
                                                                            ▼
┌──────────────────────┐        ┌──────────────────────┐        ┌──────────────────────┐
│   6. Transcoding     │ <──── │   5. Dimension Calc  │ <──── │   4. Configuration   │
│  FFmpeg Engine        │       │  Smart Portrait &    │       │  Target Resolution,   │
│  Auto-Fallback HW/SW  │       │  'mod 2' validation  │       │  Codec, and Bitrate   │
└──────────────────────┘        └──────────────────────┘        └──────────────────────┘
            │
            ▼
┌──────────────────────┐        ┌──────────────────────┐
│   7. Live Telemetry  │ ────> │   8. Complete & Save │
│  Dynamic ETA, Elapsed │       │  Instant open player  │
│  Timer, % Progress    │       │  & Storage statistics │
└──────────────────────┘        └──────────────────────┘
```

### FFmpeg Command Logic

The app strictly optimizes FFmpeg arguments for mobile hardware:
- **Scaling:** Uses `-vf "scale=<W>:<H>:flags=lanczos,format=yuv420p"` enforcing `mod 2` scaling for strict hardware decoding compatibility.
- **VP9 Optimization:** Uses `-deadline good -cpu-used 4 -row-mt 1` to achieve up to 50x faster VP9 encoding speeds compared to default exhaustive single-thread settings.
- **Faststart:** Applies `-movflags +faststart` to MP4 and MOV files for zero-buffering instant web streaming.

---

## 📦 Building the APK (Automated & Optimized)

> [!TIP]  
> Phantek Video Downscaler relies heavily on the `ffmpeg_kit_flutter_new` architecture. To keep the app sizes ultra-compact, we exclusively build and release **Split ABI APKs** for **ARM 32-bit (`armeabi-v7a`)** and **ARM 64-bit (`arm64-v8a`)**. We have entirely removed the bulky "Universal Fat APK" from the build pipeline.

### Method 1: Local Build
```bash
# Build architecture-specific, lightweight APKs:
flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64
```
Outputs are routed to `build/app/outputs/flutter-apk/`.

### Method 2: GitHub Actions CI/CD
This repository is configured with a robust `.github/workflows/build-apk.yml`.
- **Automated Version Tagging:** The workflow automatically reads `pubspec.yaml` (e.g. `1.0.7+7`) and renames the output APKs (e.g., `app-arm64-v8a-v1.0.7.apk`), completely eliminating manual renaming.
- **Triggering Releases:** Simply push a new tag (`git tag v1.0.7 && git push origin v1.0.7`), and GitHub Actions will cleanly compile the split APKs and publish them instantly to your GitHub Releases page!

---

## 📖 License

This project is licensed under the terms of the GNU General Public License v3.0 (GPLv3) to comply with the bundled `ffmpeg_kit_flutter_new` package and `libx264` codec requirements.
