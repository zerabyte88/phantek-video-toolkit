# Phantek Video Toolkit

<p align="center">
  <img src="assets/icon/app_icon.jpg" alt="Phantek Video Toolkit Icon" width="128" style="border-radius: 28px; box-shadow: 0 8px 24px rgba(0,0,0,0.3);" />
</p>

<div align="center">
  <img src="https://img.shields.io/badge/Platform-Android-059669?style=for-the-badge&logo=android&logoColor=white&labelColor=0f172a" alt="Platform" />
  <img src="https://img.shields.io/badge/Flutter-3.47.0-0284c7?style=for-the-badge&logo=flutter&logoColor=white&labelColor=0f172a" alt="Flutter" />
  <img src="https://img.shields.io/badge/Version-v1.0.8-4f46e5?style=for-the-badge&logo=github&logoColor=white&labelColor=0f172a" alt="Version" />
  <img src="https://img.shields.io/badge/License-GPLv3-475569?style=for-the-badge&logo=gnu&logoColor=white&labelColor=0f172a" alt="License" />
</div>

<br/>

**Phantek Video Toolkit** is an on-device video compression and resolution scaling application built with Flutter and FFmpeg. It is designed to compress large high-resolution videos (such as 4K and 2K) into optimized standard formats (1080p, 720p, etc.) locally on the device without requiring internet connectivity.

---

## Key Features

### Intelligent Downscaling & Codec Support
- **Resolution Downgrading:** Downscale 4K or 2K videos to 1080p, 720p, 480p, 360p, or 240p. Includes safety checks to prevent upscaling of low-resolution videos.
- **Smart Portrait Detection:** Detects portrait/vertical videos via rotation metadata and adjusts target scaling dynamically (e.g., outputs `1080x1920` instead of `1920x1080`), ensuring aspect ratio and orientation are preserved accurately.
- **Advanced Video Codecs:** 
  - **H.264 / AVC:** Broad compatibility across media players and devices.
  - **H.265 / HEVC:** High compression efficiency. Automatically injects the `-tag:v hvc1` tag for MP4/MOV formats to improve compatibility.
  - **VP9:** High compression efficiency. Container format is restricted to WebM and MKV to ensure compatibility with native Android playback.
- **Target Container Formats:** Support for MP4, MKV, MOV, and WebM encoding.

### High-Stability Software Transcoding
- **Multi-Threaded CPU Optimization:** Utilizes multi-threaded software encoders (`libx264`, `libx265`, `libvpx-vp9`) with configurable thread counts and CPU presets.
- **Universal Stability:** Ensures consistent export stability and video fidelity across various Android chipsets by relying on software encoding, bypassing potential hardware encoder fragmentation.
- **Auto-Collision File Numbering:** Automatically appends an incremental number (e.g., `video4k-1080p-2.mp4`) to the output filename if a file with the same name already exists, preventing accidental overwrites.

### Real-Time Telemetry & UX
- **Live Processing Dashboard:** Displays estimated time of arrival (ETA), processing speed (FPS), estimated output size, and completion percentage.
- **Wakelock & Background Persistence:** Utilizes `flutter_foreground_task` to ensure transcoding continues reliably when the application is minimized or the device screen is off.
- **Multi-Language Support (6 Languages):** Support for Bahasa Indonesia, English, 日本語, 简体中文, 繁體中文, and 한국어.
- **Adaptive UI:** Includes AMOLED Dark, Standard Dark, and Light themes.

---

## Architecture & FFmpeg Pipeline

```mermaid
flowchart TD
    A["1. Media Input (Native File Picker)"] --> B["2. Stream Analysis (FFprobe Extraction)"]
    B --> C["3. Metadata & Bounds Check"]
    C --> D["4. Encoding Config (Resolution, Codec, Bitrate)"]
    D --> E["5. Dimension Engine (Smart Portrait & mod 2)"]
    E --> F["6. Software Transcoding (libx264 / libx265 / VP9)"]
    F --> G["7. Real-Time Telemetry (ETA, Speed & Progress)"]
    G --> H["8. Finalize & Save (Instant Playback & Unique Naming)"]
```

### Pipeline Stages Breakdown

| Stage | Process | Key Responsibility |
| :---: | :--- | :--- |
| **01** | **Media Input** | Streams selected video from device storage via native Android SAF. |
| **02** | **FFprobe Probe** | Extracts metadata: container format, stream specifications, rotation angle, framerate, and audio channels. |
| **03** | **Validation** | Determines eligible downscale targets and prevents upscaling. |
| **04** | **Configuration** | Configures user-selected codec, container, and CRF or target bitrate. |
| **05** | **Dimension Engine** | Adjusts dimensions for portrait videos and enforces `mod 2` alignment. |
| **06** | **Transcoding** | Employs multi-threaded software encoding for consistent stability. |
| **07** | **Live Telemetry** | Calculates elapsed duration, remaining ETA, processing FPS, and live file size. |
| **08** | **Finalization** | Saves output to device Movies folder with automatic collision numbering, cleans cache, and provides playback. |

### FFmpeg Command Logic

The app optimizes FFmpeg arguments for mobile hardware:
- **Scaling:** Uses `-vf "scale=<W>:<H>:flags=lanczos,format=yuv420p"` enforcing `mod 2` scaling for hardware decoding compatibility.
- **VP9 Optimization:** Uses `-deadline good -cpu-used 4 -row-mt 1` to improve VP9 encoding speeds compared to default settings.
- **Faststart:** Applies `-movflags +faststart` to MP4 and MOV files for optimized web streaming.

---

## Building the APK (Automated & Optimized)

> [!TIP]  
> Phantek Video Toolkit utilizes the `ffmpeg_kit_flutter_new` architecture. To maintain compact application sizes, we build and release Split ABI APKs for ARM 32-bit (`armeabi-v7a`) and ARM 64-bit (`arm64-v8a`). The Universal Fat APK is excluded from the build pipeline.

### Method 1: Local Build
```bash
# Build architecture-specific APKs:
flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64
```
Outputs are routed to `build/app/outputs/flutter-apk/`.

### Method 2: GitHub Actions CI/CD
This repository includes a `.github/workflows/build-apk.yml` workflow.
- **Automated Version Tagging:** The workflow reads `pubspec.yaml` (e.g., `1.0.8+8`) and renames the output APKs (e.g., `Phantek-Video-Toolkit-arm64-v8a-v1.0.8.apk`), automating the release naming process.
- **Triggering Releases:** Push a new version tag (`git tag v1.0.8 && git push origin v1.0.8`) or run the workflow manually to compile and publish split APKs to GitHub Releases.

---

## License

This project is licensed under the terms of the GNU General Public License v3.0 (GPLv3) to comply with the bundled `ffmpeg_kit_flutter_new` package and `libx264` codec requirements.
