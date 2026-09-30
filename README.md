# Video Downscaler

<p align="center">
  <img src="assets/icon/app_icon.jpg" alt="Video Downscaler Icon" width="128" style="border-radius: 28px; box-shadow: 0 8px 24px rgba(0,0,0,0.3);" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Android%20(ARM32%20%7C%20ARM64)-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/Engine-FFmpeg%20GPL-007808?style=for-the-badge&logo=ffmpeg&logoColor=white" alt="FFmpeg" />
  <img src="https://img.shields.io/badge/Version-v1.0.7-ff69b4?style=for-the-badge" alt="Version" />
  <img src="https://img.shields.io/github/actions/workflow/status/zerabyte88/video_downscaler/build-apk.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=Build%20APK" alt="Build Status" />
</p>

<p align="center">
  <strong>A modern, offline mobile application to downscale and compress high-resolution videos directly on your Android device.</strong>
</p>

<p align="center">
  <em>Preserve storage space and compress 4K / 2K videos into shareable HD formats without uploading private files to third-party cloud servers.</em>
</p>

---

## Overview

Modern smartphones record stunning 4K and 2K videos, but these files are often hundreds of megabytes or even gigabytes in size. Sharing them over messaging platforms (like WhatsApp, Discord, or Telegram) or via email frequently fails due to strict file-size limits.

Furthermore, many smartphones—especially **mid-range and budget (low-end) devices**—lack the dedicated hardware decoders, CPU/GPU throughput, or memory bandwidth required to decode and smoothly play ultra-high-resolution 2K and 4K media. When attempting to open these heavy files, users often experience severe frame stuttering, audio/video desynchronization, app freezing, or outright "Cannot play video" errors. Solving this playback bottleneck and making videos universally accessible across all devices is one of the primary reasons **Video Downscaler** was created.

**Video Downscaler** is an open-source Flutter mobile utility powered by the full GPL build of **FFmpeg** (`ffmpeg_kit_flutter_new`). It runs **100% locally on your device**, performing hardware-accelerated and software transcoding without requiring an internet connection. Your videos never leave your phone, guaranteeing absolute privacy and zero mobile data consumption.

---

## Key Features

- **100% Offline & Private Processing**
  - No cloud uploads, no external APIs, and no telemetry. All FFprobe media inspection and FFmpeg transcoding occur locally on the device storage.

- **Intelligent Downscale Targets & FPS Control**
  - Automatically analyzes input media and exposes only valid downscaling target resolutions (e.g., 4K $\rightarrow$ 1080p, 720p, 480p, or 360p).
  - Target FPS options: Original, 30 FPS, or 24 FPS for cinematic look.

- **Aspect Ratio & Lanczos Scaling**
  - Automatically calculates target dimensions while strictly preserving original aspect ratios, including auto-detecting and handling Portrait rotation metadata from smartphone cameras.
  - Enforces even-dimension constraints (`mod 2`) and uses high-quality **Lanczos Resampling** (`scale=W:H:flags=lanczos`).
  - Colors are forced to standard 8-bit (`yuv420p`) with `high` profile and `4.1` level for maximum Android/iOS compatibility.

- **Rate Control: CRF & Bitrate**
  - **Constant Rate Factor (CRF):** Set target visual quality (CRF 18-28) for intelligent bitrate allocation. Smartly translates to strict bitrate limits when Android Hardware Acceleration (MediaCodec) is engaged to prevent bitrate starvation.
  - **Custom Bitrate:** Optionally define an exact target bitrate via an interactive slider (1–30 Mbps).
  - Includes a real-time **Estimated Output Size Calculator** in the UI.

- **Real-time Telemetry & Auto-Detection**
  - **Hardware Auto-Detection:** Automatically detects device specifications (RAM, SoC, Cores) and sets CPU threads based on hardware tiers.
  - **Thermal Warning:** Monitors battery temperature every 10 seconds; displays a red warning banner if device hits $\geq$ 45°C.
  - **Live Progress:** Accurately calculates elapsed duration and projected ETA matching the exact processing percentage.

- **File Management & Smart Cache**
  - Saves videos to `/storage/emulated/0/Movies/Video Downscaler/`.
  - **Smart Cache Manager:** Automatically deletes massive temporary files cached by the Android OS (`file_picker`) after conversion is done/cancelled, preventing gigabytes of storage bloat.
  - **Summary Bottom Sheet:** Displays final saved storage %, Original vs New Size, and options to Play, **Share (via SharePlus)**, and Delete Original Video.

- **Engine Configuration**
  - Container Format: MP4, MKV, MOV, and WebM.
  - Video Codec: H.264 / AVC (`libx264`), H.265 / HEVC (`libx265`), and VP9 (`libvpx-vp9`).
  - CPU Preset: Streamlined to 3 clear choices: `fast` (quick, light compression), `normal` (balanced speed & size), and `slow` (maximum compression).

- **Multi-Language Support (6 Languages)**
  - Seamless in-app switching between **Bahasa Indonesia**, **English**, **日本語**, **简体中文**, **繁體中文**, and **한국어**.

- **Hardware & Display Features**
  - **Display Themes**: Standard Dark, OLED Black, and Light Mode.
  - **Background Execution & Lock Screen Persistence**: Powered by Android Foreground Service (`flutter_foreground_task`) with partial CPU wakelock and ongoing notification progress, allowing encoding to complete uninterrupted even if the screen turns off due to inactivity or is manually locked.
  - **Seamless In-Place APK Upgrades**: Consistent release signing keystore and monotonic version coding enable instant updates across releases (e.g., from v1.0.6 to v1.0.7) without ever having to uninstall.
  - **Keep Screen Awake (Wakelock)**: Optional display wakelock keeps the phone display illuminated throughout encoding.
  - Dynamic App Version display driven by `package_info_plus`.

---

## Architecture & How It Works

```text
┌───────────────────────┐       ┌───────────────────────┐       ┌───────────────────────┐
│    1. Media Input   │ ────> │   2. FFprobe Probe  │ ────> │   3. Media Metadata │
│   Native Android      │       │  Extract stream specs │       │  Resolution, Codec,   │
│   File Picker         │       │  & container details  │       │  FPS, Bitrate, Audio  │
└───────────────────────┘       └───────────────────────┘       └───────────────────────┘
                                                                            │
                                                                            ▼
┌───────────────────────┐       ┌───────────────────────┐       ┌───────────────────────┐
│   6. Transcoding    │ <──── │   5. Dimension Calc │ <──── │   4. Configuration  │
│  FFmpeg Engine        │       │  Aspect ratio clamp   │       │  Target Resolution,   │
│  Software / Hardware  │       │  & 'mod 2' validation │       │  Codec, and Bitrate   │
└───────────────────────┘       └───────────────────────┘       └───────────────────────┘
            │
            ▼
┌───────────────────────┐       ┌───────────────────────┐
│   7. Live Telemetry │ ────> │   8. Complete & Save│
│  Dynamic ETA, Elapsed │       │  Instant open player  │
│  Timer, % Progress    │       │  & Storage statistics │
└───────────────────────┘       └───────────────────────┘
```

### Pipeline Stages Breakdown

| Stage | Component | Technical Role |
|:---|:---|:---|
| **1. File Selection & Ingestion** | `file_picker` | Picks local videos via native Android storage access framework without memory overhead. |
| **2. Media Stream Inspection** | `FFprobe` | Extracts exact container specs, video stream dimensions, framerate, audio tracks, and bitrate. |
| **3. UI Configuration & Bounds** | `VideoInfoCard` & `ConversionOptionsCard` | Computes eligible downscale targets (e.g. 4K $\rightarrow$ 1080p, 720p), prevents accidental upscaling, and exposes codec/bitrate presets. |
| **4. Dimension & Bitrate Engine** | `EncodingOptions` | Enforces exact aspect ratio scaling and even `mod 2` width/height constraints required by H.264/HEVC encoders. |
| **5. Hardware/Software Transcoding** | `FFmpeg` (`ffmpeg_kit_flutter_new`) | Executes the optimized command line pipeline using selected threads, memory buffer limits, and optional Android `MediaCodec` acceleration. |
| **6. Real-time Telemetry & Launch** | `ProcessingScreen` & `open_file` | Continuously calculates elapsed duration and projected ETA. Finalizes output into `/storage/emulated/0/Movies/Video Downscaler/` and triggers direct playback. |

### FFmpeg Transcoding Command Breakdown

The application executes an optimized FFmpeg command configured for mobile efficiency and universal playback compatibility:

```bash
ffmpeg -i "<input_path>" \
  -vf "scale=<target_width>:<target_height>" \
  -c:v libx264 \
  -preset medium \
  -b:v <computed_bitrate>k \
  -c:a aac \
  -b:a 128k \
  -movflags +faststart \
  -y "<output_path>"
```

#### Parameter Highlights:
- `-vf "scale=<target_width>:<target_height>"`: Scales the video to the target resolution while strictly preserving the original aspect ratio and enforcing even dimensions (`mod 2`) required by mobile hardware decoders.
- `-c:v libx264 -preset medium`: Balances fast encoding speed with high compression density. Automatically switches to `-c:v h264_mediacodec` or `-c:v hevc_mediacodec` when Hardware Acceleration is enabled.
- `-c:a aac -b:a 128k`: Delivers clear, high-fidelity stereo audio compression (or strips audio with `-an` if Mute is selected).
- `-movflags +faststart`: Relocates the `moov` atom to the beginning of the MP4 file for zero-buffering instant streaming and immediate playback.

---

## Project Structure

```
video_downscaler/
├── .github/
│   └── workflows/
│       └── build-apk.yml          # GitHub Actions CI/CD workflow for automated APK builds
├── android/
│   ├── app/
│   │   ├── build.gradle.kts       # Android app build configuration (minSdk 24, Java 17)
│   │   └── src/main/
│   │       └── AndroidManifest.xml # Storage & media permissions
│   └── build.gradle.kts           # Root gradle configuration
├── lib/
│   ├── main.dart                  # Application entry point & theme initialization
│   ├── models/
│   │   └── video_info.dart        # Video metadata models & resolution presets
│   ├── screens/
│   │   ├── home_screen.dart       # Main dashboard: file picker & resolution selection
│   │   └── processing_screen.dart # Real-time transcoding progress, cancel, & results
│   ├── services/
│   │   └── ffmpeg_service.dart    # FFprobe info extractor & FFmpeg transcoding engine
│   ├── theme/
│   │   └── app_theme.dart         # Material 3 dark theme definitions
│   └── widgets/
│       ├── resolution_selector.dart # Interactive resolution options with quality badges
│       └── video_info_card.dart     # Formatted media details grid
├── test/
│   └── widget_test.dart           # UI & widget tests
└── pubspec.yaml                   # Dependencies & package configuration
```

---

## Tech Stack & Dependencies

| Package | Version | Purpose |
|:---|:---|:---|
| **[Flutter SDK](https://flutter.dev)** | `^3.47.0` | Cross-platform UI toolkit |
| **[ffmpeg_kit_flutter_new](https://pub.dev/packages/ffmpeg_kit_flutter_new)** | `^4.6.0` | Full FFmpeg + FFprobe engine with GPL codecs (libx264) |
| **[file_picker](https://pub.dev/packages/file_picker)** | `^13.1.0` | Native file picker for selecting device video files |
| **[video_player](https://pub.dev/packages/video_player)** | `^2.14.0` | Video playback backend support |
| **[path_provider](https://pub.dev/packages/path_provider)** | `^2.1.6` | Accessing standard Android document storage paths |
| **[open_file](https://pub.dev/packages/open_file)** | `^4.0.0` | Launching output videos via default Android media player |
| **[intl](https://pub.dev/packages/intl)** | `^0.20.3` | Formatting utilities |

---

## Getting Started

### Prerequisites

Ensure your development environment meets the following requirements:
- **Flutter SDK**: `3.13.0` or higher (tested on `3.47.4`)
- **Dart SDK**: `^3.13.3`
- **JDK**: Java 17 (Temurin recommended)
- **Android SDK**: `minSdkVersion 24` (Android 7.0 Nougat) or higher

### Local Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/zerabyte88/video_downscaler.git
   cd video_downscaler
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify analyzer and tests:**
   ```bash
   flutter analyze
   flutter test
   ```

4. **Run the application:**
   Connect an Android device with USB debugging enabled, then execute:
   ```bash
   flutter run
   ```

---

## Building the APK (ARM 32-bit & 64-bit Exclusive)

> [!TIP]
> This application is specifically tailored for **real Android devices** utilizing **ARM 32-bit (`armeabi-v7a`)** and **ARM 64-bit (`arm64-v8a`)** architectures. All support for emulator-only `x86` and `x86_64` binaries has been completely stripped out to prevent binary bloat, ensuring both individual APKs and the release `.zip` artifact remain exceptionally compact.

### Method 1: Local Build

To build release APKs locally on your machine:

```bash
# Build universal release APK (ARM 32 & 64-bit only):
flutter build apk --release --target-platform android-arm,android-arm64

# OR build architecture-specific APKs:
flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64
```

The compiled APKs will be located at:
`build/app/outputs/flutter-apk/`
- `app-arm64-v8a-release.apk` (Modern 64-bit ARM smartphones — recommended, smallest size)
- `app-armeabi-v7a-release.apk` (Legacy 32-bit ARM smartphones)
- `app-release.apk` (Universal ARM dual-architecture binary)

---

### Method 2: Automated CI/CD via GitHub Actions 

This repository includes a fully configured automated GitHub Actions workflow [`.github/workflows/build-apk.yml`](.github/workflows/build-apk.yml).

#### How the GitHub Automation Works:

1. **Automatic Build on Push & PR:**
   - Every push to `main` and pull request automatically triggers Flutter static analysis (`flutter analyze`), unit/widget tests (`flutter test`), and builds the release APK.
   - You can download the generated APK directly from the **Actions** tab $\rightarrow$ select the workflow run $\rightarrow$ scroll to **Artifacts** $\rightarrow$ download `video-downscaler-apk`.

2. **Manual Build (Workflow Dispatch):**
   - Navigate to the **Actions** tab on your GitHub repository.
   - Select **Build Android APK** from the left sidebar.
   - Click **Run workflow** and choose your branch. You can toggle whether to generate split-per-ABI APKs.

3. **Automated GitHub Releases (Git Tag):**
   - Push a version tag (e.g. `v1.0.0`) to trigger an automated release:
     ```bash
     git tag v1.0.0
     git push origin v1.0.0
     ```
   - GitHub Actions will build the release APKs, automatically draft a GitHub Release with auto-generated release notes, and attach the APK files for public download.

---

## License & Attribution

This project is licensed under the terms of the GNU General Public License v3.0 (GPLv3) to comply with the bundled `ffmpeg_kit_flutter_new` package and `libx264` codec requirements.
