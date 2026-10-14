# Phantek Video Toolkit

<p align="center">
  <img src="assets/icon/app_icon.jpg" alt="Phantek Icon" width="120" style="border-radius: 24px; box-shadow: 0 8px 24px rgba(0,0,0,0.25);" />
</p>

<div align="center">
  <img src="https://img.shields.io/static/v1?label=Platform&message=Android&color=059669&style=for-the-badge&logo=android&logoColor=white&labelColor=0f172a" alt="Platform" />
  <img src="https://img.shields.io/static/v1?label=Architecture&message=arm64-v8a&color=7c3aed&style=for-the-badge&logo=arm&logoColor=white&labelColor=0f172a" alt="Architecture" />
  <img src="https://img.shields.io/static/v1?label=Application%20ID&message=com.phantek.cygnus.albireo&color=6366f1&style=for-the-badge&logo=android&logoColor=white&labelColor=0f172a" alt="Application ID" />
  <a href="https://github.com/zerabyte88/phantek-video-toolkit/releases"><img src="https://img.shields.io/static/v1?label=Version&message=v3.5.0&color=2563eb&style=for-the-badge&logo=github&logoColor=white&labelColor=0f172a" alt="Version" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/static/v1?label=License&message=GPLv3&color=475569&style=for-the-badge&logo=gnu&logoColor=white&labelColor=0f172a" alt="License" /></a>
</div>

<br/>

**Phantek Video Toolkit** is an offline, on-device mobile video transcoding, resolution downscaling, file compression, and audio extraction toolkit built with Flutter and FFmpeg (`ffmpeg_kit_flutter_new`). It runs 100% locally on Android devices without requiring network connectivity, user accounts, cloud infrastructure, or tracking.

---

## Key Features

### 1. Dedicated Dual-Category Mode Architecture
The home screen provides clean segmented navigation divided into two primary categories:
- **Video Processing:**
  - **Convert:** Preserves the original video resolution while converting containers, tuning encoding presets, adjusting CRF or target bitrates, setting target frame rates, and configuring audio tracks.
  - **Downscale:** Dynamically inspects the source video resolution and lists only smaller valid targets (1080p, 720p, 480p, 360p), calculating exact proportional aspect ratios without image stretching or letterboxing.
- **Audio Extraction:**
  - **Audio Extractor:** Extracts the audio track directly from any video into standalone audio files (MP3, M4A, or WAV) with instant stream copy or customizable bitrates.

### 2. Video Processing (Convert & Downscale)
- **Single-Pass Rescaling Pipeline:** Pre-calculates exact even output dimensions (`width` and `height`) directly on the Dart layer, completely eliminating redundant rescale passes and padding filters in FFmpeg to minimize CPU cycles, memory copying, and thermal load.
- **Format & Container Support:** Generates standards-compliant **MP4** (with `-movflags +faststart` for instant streaming playback), **MKV**, and **MOV** containers.
- **Video Codec Standard:**
  - **H.264 / AVC (`libx264`):** Guaranteed universal hardware-accelerated playback across all Android devices, desktop media players (VLC, QuickTime, Windows Media Player), and web/social platforms.
- **3-Tier Mobile Encoding Ladder (`SpeedPreset`):**
  - **Fast (`area` + `veryfast` + CRF 24):** Anti-aliasing downsampling using 2×2 pixel area averaging (`sws_flags=area`) to eliminate moiré artifacts while minimizing mobile CPU overhead, temperature, and encoding time.
  - **Normal (`bicubic` + `faster` + CRF 22):** The calibrated mobile sweet spot offering balanced visual sharpness and efficient H.264 compression.
  - **Maximum (`lanczos` + `fast` + CRF 20):** High-precision Lanczos sinc interpolation paired with `accurate_rnd` and `full_chroma_int` flags (`sws_flags=lanczos+accurate_rnd+full_chroma_int`) for studio-grade line sharpness, accurate chroma reconstruction, and superior compression density.
- **Interactive CRF Slider & Rate Control:**
  - **Preset Synchronization:** Automatically jumps to the preset's recommended CRF (24 / 22 / 20) upon chip selection.
  - **Custom Fine-Tuning:** Adjusting the slider enables custom CRF tuning while preserving the chosen scaler algorithm and CPU preset, marked with a real-time "Custom" indicator badge.
  - **1-Tap Quick Reset:** Instantly restores the active preset's default recommended CRF.
  - **Safety Warning Banner:** Automatically highlights high-load warnings when CRF $\le 17$ to warn against exponential output file sizes and severe thermal strain.
  - **Target Bitrate Alternative:** Offers strict bitrate enforcement (e.g. 500 kbps up to 20,000 kbps) when specific file size budgets are required.
- **Dual-Trigger High-Load Protection Dialog:** Proactively prompts a confirmation dialog when attempting Maximum preset encoding on 4K sources or videos $\ge 30$ minutes in duration, offering a 1-tap "Use Normal" downgrade option to protect battery life and prevent thermal throttling.
- **Smart Audio Passthrough (4-Rule Passthrough):** Automatically uses zero-re-encoding direct stream copy (`-c:a copy`) when the source is AAC, container is MP4, stream channel count $\le 2$, and source bitrate is within $110\%$ of the target audio bitrate. Otherwise, safely falls back to clean AAC stereo re-encoding or mute mode (`-an`) if no audio stream exists.
- **Target Frame Rate (FPS):** Retain original source frame rate or transcode to standard targets (24, 30, or 60 FPS).

### 3. Dedicated Audio Extractor
- Extracts audio tracks directly from videos into popular audio formats:
  - **MP3 (`libmp3lame`):** Globally compatible with virtually every media player, vehicle system, and operating system.
  - **M4A / AAC (`aac`):** Pristine acoustic clarity with optimal compression efficiency for mobile storage (includes `+faststart`).
  - **WAV (`pcm_s16le`):** Uncompressed studio-grade lossless 16-bit PCM audio.
- **High-Speed Stream Copy:** Automatically bypasses re-encoding (`-c:a copy`) when extracting to matching formats (e.g. AAC to M4A, MP3 to MP3, PCM to WAV) for instant extraction.
- **Configurable Bitrate Options:** Selectable audio bitrates from 64 kbps up to 320 kbps (Studio Quality).

### 4. Real-Time Telemetry & Performance Monitoring
- **Live Telemetry Dashboard:** Displays real-time waveform monitoring cards during encoding:
  - **CPU Workload (%):** Live multi-threaded processor utilization during encoding.
  - **Memory Allocation (RAM RSS):** High-precision physical process resident memory (VmRSS) read directly from Linux `/proc/self/status`.
  - **Disk Write Throughput (MB/s):** Real-time measurement of encoder output write velocity to local storage.
- **Accurate Progress Estimator:** Real-time percentage indicator, encoding speed multiplier (e.g. 1.8×), elapsed time, calculated remaining time (ETA), and output file size tracking.
- **Live FFmpeg Console:** Collapsible real-time encoding log stream for deep inspection and diagnostic analysis.

### 5. Background Persistence & Screen-Off Execution
- **Android Foreground Service:** Operates under Android's official `mediaProcessing` foreground service type to prevent operating system process termination when the app is minimized or backgrounded.
- **Screen-Off Execution (CPU Wakelock):** Employs CPU wakelocks to keep transcoding jobs active when the device display turns off.
- **System Notification Updates:** Real-time conversion progress and completion status are displayed directly in the Android notification shade.

### 6. Modern Settings & Hardware Management
- **4-Container Surface Architecture:** Clean Material 3 surface grouping Appearance & Language, Performance & Hardware, Storage & Cache, and Device Specs & About.
- **2x2 Grid Theme Selector:** Visual cards with contextual color accents, category badges (`DARK`, `AMOLED`, `LIGHT`), and theme branding (`Snowfall`, `Midnight`, `Sakura`, `Daylight`).
- **Card Opacity & Translucent UI:** Adjustable card surface transparency from 100% solid down to 50% with an interactive live percentage slider (5% steps) and one-tap quick reset in Settings. Utilizes zero-cost GPU alpha tinting to guarantee rock-solid 60–120 FPS UI performance without `BackdropFilter` offscreen render-pass overhead.
- **Comprehensive Hardware Recognition:** Automatically inspects and displays Device Name, Model Code, Processor / SoC (Qualcomm Snapdragon, MediaTek Dimensity/Helio, Samsung Exynos, Google Tensor, Unisoc), Graphics Processor (GPU Adreno, Mali, Xclipse), Physical RAM, and Available Storage.
- **CPU Thread Allocation:** Customize encoding thread count or choose automatic multi-core allocation.
- **RAM Buffer Boundaries:** Configurable memory cache buffer limits (256 MB to 2048 MB) for optimized FFmpeg mobile memory caching.
- **Dedicated Video & Audio Output Directories:** Custom folder pickers with one-tap reset defaults.
- **Non-Destructive File Naming:** Automatically detects filename collisions and appends incremental identifiers (`-2`, `-3`) to avoid overwriting existing media.
- **Automated Cache Purge:** Cleans up temporary file picker caches with live size feedback to keep device storage clean.

### 7. Dynamic Visual Engine & 22-Language Localization
- **Continuous Looping Background Animations:** Battery-friendly, mathematically seamless animated canvas tailored to each active theme:
  - **Snowfall:** Winter village night landscape with snow-covered wooden cabins, warm golden window glow, chimney smoke puffs, snow-dusted pine trees, and drifting `#CFF0FF` crystalline snowflakes ❄️ (Badge: `DARK`).
  - **Midnight:** Glowing lunar crescent, twinkling starry sky, and shooting meteor trails 🌙 on true `#000000` pitch black for zero-watt AMOLED pixel efficiency (Badge: `AMOLED`).
  - **Daylight:** Warm morning sunbeams and fresh airy breeze ☀️ (Badge: `LIGHT`).
  - **Sakura:** Fluttering cherry blossom petals drifting over blooming sakura tree silhouettes and corner branches 🌸 (Badge: `AMOLED`).
- **Theme-Adaptive Header Title:** Animated glowing border and iconography dynamically matching the active theme mode (*Snowfall Crystal*, *Moonlight Starlight*, *Sunburst Gold*, or *Sakura Blossom*).
- **Easter Egg Theme (Sakura):** Unlocked by tapping the **"Phantek"** header title 10 times consecutively (revealing the Sakura theme option in Settings; subsequent 10 taps indicate that the easter egg is already active without re-triggering).
- **Dictionary Coverage across 22 Languages (Alphabetical Latin A–Z then Non-Latin):**
  - 🇮🇩 Indonesian (Bahasa Indonesia)
  - 🇲🇾 Malay (Bahasa Melayu)
  - 🇩🇰 Danish (Dansk)
  - 🇩🇪 German (Deutsch)
  - 🇺🇸 English
  - 🇪🇸 Spanish (Español)
  - 🇫🇷 French (Français)
  - 🇮🇹 Italian (Italiano)
  - 🇳🇱 Dutch (Nederlands)
  - 🇳🇴 Norwegian (Norsk)
  - 🇵🇹 Portuguese (Português)
  - 🇫🇮 Finnish (Suomi)
  - 🇸🇪 Swedish (Svenska)
  - 🇻🇳 Vietnamese (Tiếng Việt)
  - 🇷🇺 Russian (Русский)
  - 🇸🇦 Arabic (العربية)
  - 🇮🇳 Hindi (हिन्दी)
  - 🇹🇭 Thai (ไทย)
  - 🇯🇵 Japanese (日本語)
  - 🇨🇳 Simplified Chinese (简体中文)
  - 🇹🇼 Traditional Chinese (繁體中文)
  - 🇰🇷 Korean (한국어)

---

## Format & Codec Matrix

| Category | Format / Container | Codec | Technical Notes |
| :--- | :--- | :--- | :--- |
| **Video** | `.mp4` | H.264 (`libx264`) | Injects `-movflags +faststart` for instant streaming playback |
| **Video** | `.mkv` | H.264 (`libx264`) | Flexible modern container for video & audio packaging |
| **Video** | `.mov` | H.264 (`libx264`) | Universal format for mobile playback and video editing |
| **Audio** | `.mp3` | MP3 (`libmp3lame`) | Bitrates from 64 to 320 kbps or direct stream copy |
| **Audio** | `.m4a` | AAC (`aac`) | High acoustic fidelity optimized for mobile devices (`+faststart`) |
| **Audio** | `.wav` | PCM (`pcm_s16le`) | Uncompressed lossless studio acoustics |

---

## Build & Compilation

Phantek utilizes native C/C++ shared libraries bundled through `ffmpeg_kit_flutter_new`. The application is built specifically for modern **64-bit ARM (`arm64-v8a`)** architectures to deliver maximum processing performance and memory efficiency.

### Local APK Build Command

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64
```

The compiled release APK will be generated at:
`build/app/outputs/flutter-apk/Phantek-Video-Toolkit-arm64-v8a-v3.5.0.apk`

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
