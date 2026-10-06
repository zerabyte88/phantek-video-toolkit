# Phantek - Video Toolkit

<p align="center">
  <img src="assets/icon/app_icon.jpg" alt="Phantek Icon" width="120" style="border-radius: 24px; box-shadow: 0 8px 24px rgba(0,0,0,0.25);" />
</p>

<div align="center">
  <img src="https://img.shields.io/static/v1?label=Platform&message=Android&color=059669&style=for-the-badge&logo=android&logoColor=white&labelColor=0f172a" alt="Platform" />
  <img src="https://img.shields.io/static/v1?label=Architecture&message=arm64-v8a&color=7c3aed&style=for-the-badge&logo=arm&logoColor=white&labelColor=0f172a" alt="Architecture" />
  <a href="https://github.com/zerabyte88/phantek-video-toolkit/releases"><img src="https://img.shields.io/static/v1?label=Version&message=v1.4.0&color=2563eb&style=for-the-badge&logo=github&logoColor=white&labelColor=0f172a" alt="Version" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/static/v1?label=License&message=GPLv3&color=475569&style=for-the-badge&logo=gnu&logoColor=white&labelColor=0f172a" alt="License" /></a>
</div>

<br/>

**Phantek (Phantek - Video Toolkit)** is an offline, on-device mobile video transcoding, resolution downscaling, file compression, and audio extraction toolkit built with Flutter and FFmpeg (`ffmpeg_kit_flutter_new`). It runs 100% locally on Android devices without requiring network connectivity, user accounts, or external cloud infrastructure.

---

## Key Features

### 1. Video Processing (Convert & Downscale)
- **Resolution Downscaling:** Reduces high-resolution videos (4K, 2K) to standard targets (1080p, 720p, 480p, 360p) while preserving original aspect ratios (landscape or portrait) without stretching or letterboxing.
- **Format & Codec Conversion:** Supports container formats **MP4** (with the `+faststart` flag for instant streaming playback), **MKV**, and **MOV**.
- **Video Codec Options:**
  - **H.264 / AVC (`libx264`):** Universal compatibility across all Android devices, desktop media players, and social media platforms.
  - **H.265 / HEVC (`libx265`):** High-efficiency compression that significantly reduces file size while retaining visual quality.
- **Rate Control Modes:**
  - **CRF (Constant Rate Factor):** Ensures consistent, natural visual fidelity throughout the video.
  - **Target Bitrate:** Enforces custom bitrates tailored to targeted file size constraints.
- **Target Frame Rate (FPS):** Option to convert to a target frame rate or retain the original source FPS.
- **Audio Track Management:** Configurable AAC audio bitrate or mute mode (`-an`) to strip audio tracks for even leaner file sizes.

### 2. Dedicated Audio Extractor
- Extracts audio tracks directly from videos into popular audio formats:
  - **MP3 (`libmp3lame`):** Globally compatible with virtually every media player and device.
  - **M4A / AAC (`aac`):** High acoustic clarity with optimal compression efficiency for mobile playback.
  - **WAV (`pcm_s16le`):** Uncompressed studio-grade lossless audio.
- **High-Speed Stream Copy:** Directly copies compatible audio streams without re-encoding for instant extraction.
- **Flexible Bitrate Options:** Configurable audio bitrates from 64 kbps up to 320 kbps (Studio Quality).

### 3. Real-Time Telemetry & Performance Monitoring
- **Live Telemetry Dashboard:** Displays real-time waveform monitoring cards during conversion:
  - **CPU Workload (%):** Live multi-threaded processor utilization during encoding.
  - **Memory Allocation (RAM RSS):** High-precision physical process resident memory (VmRSS) read directly from Linux `/proc/self/status`.
  - **Disk Write Throughput (MB/s):** Real-time measurement of encoder output write velocity to local storage.
- **Accurate Progress Estimator:** Real-time percentage indicator, encoding speed multiplier, elapsed time, calculated remaining time (ETA), and output file size tracking.

### 4. Background Persistence & Screen-Off Execution
- **Android Foreground Service:** Operates under Android's `mediaProcessing` service type to prevent operating system task termination when the app is minimized.
- **Screen-Off Execution (CPU Wakelock):** Employs CPU wakelocks to keep transcoding active when the device display turns off.
- **Notification Tray Updates:** Real-time conversion progress is directly visible from the system notification shade.

### 5. Modern Minimalist Settings & Hardware Management
- **4-Container Surface Architecture:** Clean, comfortable Material 3 cards grouping Appearance & Language, Performance & Hardware, Storage & Cache, and Device Specs & About.
- **Interactive Language Selector:** Displays national flags and opens a sleek rounded modal bottom sheet.
- **2x2 Grid Theme Selector:** Visual cards with contextual color accents and status badges.
- **Comprehensive Hardware Recognition:** Automatically inspects and displays Device Name, Model Code, Processor / SoC (Qualcomm Snapdragon, MediaTek Dimensity/Helio, Samsung Exynos, Google Tensor, Unisoc), Graphics Processor (GPU Adreno, Mali, Xclipse), Physical RAM, and Available Storage.
- **CPU Thread Allocation:** Customize encoding thread count or choose automatic multi-core allocation.
- **RAM Buffer Boundaries:** Configurable memory cache buffer limits (256 MB to 4096 MB) with automatic Out-Of-Memory (OOM) protection disabling the 4GB option on devices with $\le 4\text{ GB}$ physical RAM.
- **Dedicated Video & Audio Output Directories:** Custom folder pickers with one-tap reset defaults.
- **Developer Card:** Offline circular avatar with cyan glow, developer name, role, and direct `[GitHub ↗]` button.
- **Non-Destructive File Naming:** Automatically detects filename collisions and appends incremental identifiers (`-2`, `-3`) to avoid overwriting existing media.
- **Automated Cache Purge:** Cleans up temporary file picker caches with live size feedback to keep device storage clean.

### 6. Dynamic Visual Engine & 11-Language Localization
- **Continuous Looping Background Animations:** Battery-friendly, mathematically seamless animated canvas tailored to each active theme:
  - **Dark Aurora:** Vivid arctic aurora borealis curtains and gentle falling snowflakes ❄️.
  - **OLED Cosmic Moon:** Glowing lunar crescent, twinkling starry sky, and shooting meteor trails 🌙 on true `#000000` pitch black for zero-watt AMOLED pixel efficiency.
  - **Clean Daylight:** Warm morning sunbeams and fresh airy breeze ☀️.
  - **AMOLED Sakura:** Fluttering cherry blossom petals drifting over blooming sakura tree silhouettes and corner branches 🌸.
- **Theme-Adaptive Header Title:** Animated glowing border and iconography dynamically matching the active theme mode (*Emerald Arctic Snowflake*, *Moonlight Starlight*, *Sunburst Gold*, or *Sakura Blossom*).
- **Easter Egg Theme (AMOLED Sakura):** Unlocked by tapping the **"Phantek"** header title 10 times consecutively.
- **100% Dictionary Coverage across 11 Languages (222 Keys Each):**
  - 🇮🇩 Indonesian (Bahasa Indonesia)
  - 🇺🇸 English
  - 🇨🇳 Simplified Chinese (简体中文)
  - 🇹🇼 Traditional Chinese (繁體中文)
  - 🇪🇸 Spanish (Español)
  - 🇵🇹 Portuguese (Português)
  - 🇯🇵 Japanese (日本語)
  - 🇰🇷 Korean (한국어)
  - 🇮🇳 Hindi (हिन्दी)
  - 🇸🇦 Arabic (العربية)
  - 🇫🇷 French (Français)
  - 🇷🇺 Russian (Русский)

---

## Format & Codec Matrix

| Category | Format / Container | Codec | Technical Notes |
| :--- | :--- | :--- | :--- |
| **Video** | `.mp4` | H.264 (`libx264`), H.265 (`libx265`) | Injects `-movflags +faststart` & `-tag:v hvc1` |
| **Video** | `.mkv` | H.264 (`libx264`), H.265 (`libx265`) | Flexible container for multi-audio and subtitles |
| **Video** | `.mov` | H.264 (`libx264`), H.265 (`libx265`) | Standard format for video editing workflows |
| **Audio** | `.mp3` | MP3 (`libmp3lame`) | Bitrates from 64 to 320 kbps or direct stream copy |
| **Audio** | `.m4a` | AAC (`aac`) | High acoustic fidelity optimized for mobile devices |
| **Audio** | `.wav` | PCM (`pcm_s16le`) | Uncompressed lossless studio acoustics |

---

## Build & Compilation

Phantek utilizes native C/C++ shared libraries bundled through `ffmpeg_kit_flutter_new`. The application is built specifically for modern **64-bit ARM (`arm64-v8a`)** architectures to deliver maximum processing performance and memory efficiency.

### Local APK Build Command

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64
```

The compiled release APK will be generated at:
`build/app/outputs/flutter-apk/Phantek-Video-Toolkit-arm64-v8a-v1.4.0.apk`

---

## Version History

- **v2.2.0 (Build 19):**
  - Overhauled Settings Screen into a modern, minimalist 4-container Material 3 surface architecture.
  - Expanded localization support to 11 full languages + aliases with 100% dictionary coverage (222 identical keys each).
  - Completely eliminated all remaining hardcoded text across the entire application.
  - Enhanced continuous particle and celestial background animations across all themes (Aurora, Moon & Meteors, Sakura Branches & Petals, Sunbeams).
  - Added offline circular developer profile card with direct GitHub link.
  - Performed whole-repo dead code removal, type-safety refactoring, and code formatting adhering strictly to Dart lint standards.
- **2.1.0 (Build 18):**
  - Added continuous, seamlessly looping dynamic animated canvas backgrounds for Dark, OLED, Light, and AMOLED Sakura themes.
  - Added Easter Egg theme **AMOLED Sakura** (activated by tapping "Phantek" on header 10 times).
  - Added theme-adaptive glowing borders and iconography to header title (Electric Cyan Bolt, Amber Fire, Azure Sun, Sakura Blossom).
  - Cleaned up developer card interactions and removed external repository button.
- **v2.0.0 (Build 17):**
  - BREAKING CHANGE: Standardized application package ID and Android namespace to com.phantek.cygnus.albireo (requires clean install / resets OS-level application continuity).
  - Deprecated and removed VP9 codec and WebM container to resolve mobile encoding stability issues.
  - Standardized video pipelines to pure H.264 & H.265 (MP4, MKV, MOV) and audio to AAC, MP3, WAV.
  - Streamlined CPU encoding presets in Settings.
  - Thoroughly cleaned up unused code and expanded 64-bit modern SoC & GPU detection.
- **v1.3.0 (Build 16):**
  - Integrated real-time conversion telemetry dashboard (CPU %, RAM RSS Linux `/proc/self/status`, Storage I/O throughput).
  - Added 320 kbps audio quality and 4096 MB RAM buffer with hardware OOM protection.
- **v1.2.0 (Build 15):**
  - Added dedicated Audio Extractor feature (MP3, M4A, WAV).
  - Implemented orientation-aware resolution classification for portrait and landscape videos.
  - Integrated comprehensive hardware specifications display in Settings.
- **v1.1.0 (Build 14):**
  - Integrated Android Foreground Service and CPU Wakelock for background persistence and screen-off execution.

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. Please see the [LICENSE](LICENSE) file for full license terms.

---

<div align="center">
  <br/>
  <a href="https://github.com/zerabyte88">
    <img src="https://github.com/zerabyte88.png" width="48" height="48" style="border-radius: 50%;" alt="zerabyte88" />
  </a>
  <br/>
  <sub>Developed with ❤️ by <a href="https://github.com/zerabyte88">zerabyte88</a> (Creator & Maintainer)</sub>
</div>
