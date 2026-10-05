# Phantek - Video Toolkit

<p align="center">
  <img src="assets/icon/app_icon.jpg" alt="Phantek Icon" width="120" style="border-radius: 24px; box-shadow: 0 8px 24px rgba(0,0,0,0.25);" />
</p>

<div align="center">
  <img src="https://img.shields.io/static/v1?label=Platform&message=Android&color=059669&style=for-the-badge&logo=android&logoColor=white&labelColor=0f172a" alt="Platform" />
  <img src="https://img.shields.io/static/v1?label=Architecture&message=arm64-v8a&color=7c3aed&style=for-the-badge&logo=arm&logoColor=white&labelColor=0f172a" alt="Architecture" />
  <a href="https://github.com/zerabyte88/phantek-video-toolkit/releases"><img src="https://img.shields.io/static/v1?label=Version&message=v1.2.1&color=2563eb&style=for-the-badge&logo=github&logoColor=white&labelColor=0f172a" alt="Version" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/static/v1?label=License&message=GPLv3&color=475569&style=for-the-badge&logo=gnu&logoColor=white&labelColor=0f172a" alt="License" /></a>
</div>

<br/>

**Phantek (Phantek - Video Toolkit)** adalah aplikasi mobile *on-device* untuk konversi format video, *downscaling* resolusi, kompresi berkas, dan ekstraksi audio yang dibangun menggunakan Flutter dan FFmpeg (`ffmpeg_kit_flutter_new`). Bekerja 100% secara offline langsung di ponsel Android tanpa membutuhkan koneksi internet, akun pengguna, atau server eksternal.

---

## Fitur Utama

### 1. Pemrosesan Video (Convert & Downscale)
- **Downscale Resolusi:** Mengubah resolusi video tinggi (4K, 2K) ke resolusi standar (1080p, 720p, 480p, 360p) dengan mempertahankan rasio aspek asli (landscape maupun portrait) tanpa distorsi atau garis hitam.
- **Konversi Format & Codec:** Mendukung wadah kontainer **MP4** (dengan flag *faststart* untuk streaming cepat), **MKV**, dan **MOV**.
- **Pilihan Codec Video:**
  - **H.264 / AVC (`libx264`):** Kompatibilitas universal untuk semua perangkat, media sosial, dan pemutar video.
  - **H.265 / HEVC (`libx265`):** Efisiensi kompresi tinggi untuk menghemat ruang penyimpanan.
- **Mode Kontrol Kualitas (Rate Control):**
  - **CRF (Constant Rate Factor):** Menjaga kualitas visual yang konsisten dan natural.
  - **Target Bitrate:** Menetapkan bitrate khusus sesuai kebutuhan ukuran berkas target.
- **Target Frame Rate (FPS):** Opsi untuk mengubah atau mempertahankan FPS video asli.
- **Audio Video:** Opsi bitrate audio AAC atau mode hening (*mute* `-an`) untuk menghilangkan trek suara agar ukuran video lebih kecil.

### 2. Ekstraksi Audio Khusus (Audio Extractor)
- Ekstrak trek audio dari video ke format audio populer:
  - **MP3 (`libmp3lame`):** Kompatibel dengan semua perangkat dan pemutar musik.
  - **M4A / AAC (`aac`):** Kualitas suara tinggi dengan efisiensi ukuran optimal.
  - **WAV (`pcm_s16le`):** Audio studio uncompressed tanpa penurunan kualitas (lossless).
- **Stream Copy Cepat:** Salin langsung stream audio asli tanpa *re-encoding* jika format sumber cocok.
- **Pilihan Bitrate Fleksibel:** Pilihan bitrate audio dari 64 kbps hingga 320 kbps (Studio Quality).

### 3. Pemantauan Kinerja & Telemetri Real-Time
- **Dashboard Telemetri:** Menampilkan grafik garis langsung saat proses konversi berlangsung:
  - **Beban CPU (%):** Penggunaan processor proses encoding secara real-time.
  - **Alokasi RAM (MB):** Penggunaan memori fisik nyata (VmRSS) yang dibaca langsung dari kernel Linux `/proc/self/status`.
  - **Throughput Tulis Disk (MB/s):** Kecepatan penulisan data output ke media penyimpanan.
- **Estimasi Akurat:** Indikator persentase, kecepatan encoding (multiplier kecepatan), waktu berjalan, sisa waktu (ETA), dan ukuran berkas output sementara.

### 4. Background Persistence & Layar Mati
- **Android Foreground Service:** Berjalan di latar belakang dengan tipe `mediaProcessing` sehingga proses tidak ditutup paksa oleh sistem operasi saat aplikasi diminimalkan.
- **Dukungan Layar Mati (Wakelock):** Mencegah CPU masuk ke mode *deep sleep* saat layar HP dimatikan selama proses encoding masih berlangsung.
- **Pemberitahuan Status:** Progres konversi dapat dipantau langsung dari *notification tray* ponsel.

### 5. Manajemen Perangkat Keras & Pengaturan
- **Deteksi Spesifikasi Lengkap:** Mengenali nama perangkat, model, processor/SoC (Qualcomm Snapdragon, MediaTek Dimensity/Helio, Samsung Exynos, Google Tensor, Unisoc), chip grafis (GPU Adreno, Mali, Xclipse), RAM fisik, dan sisa kapasitas penyimpanan internal.
- **Alokasi Thread CPU:** Opsi menentukan jumlah core thread encoding atau mode otomatis (semua core).
- **Batas Buffer RAM:** Mengatur alokasi cache memori (256 MB hingga 4096 MB) dengan proteksi otomatis terhadap OOM pada perangkat dengan RAM $\le 4\text{ GB}$.
- **Folder Output Kustom:** Bebas memilih folder penyimpanan output untuk video (`/Movies` secara bawaan) dan audio (`/Music` secara bawaan).
- **Proteksi Penimpaan File:** Nama berkas otomatis diberi akhiran unik (`-2`, `-3`) jika sudah ada berkas dengan nama yang sama.
- **Pembersihan Cache Otomatis:** Menghapus berkas sementara dari pemilih file secara berkala agar penyimpanan perangkat tetap lega.

### 6. Desain Antarmuka & Multi-Bahasa
- **Pilihan Tema:** Mode Gelap (Slate Dark), Mode Gelap OLED (Pitch Black hemat baterai AMOLED), dan Mode Terang (Clean Light).
- **Dukungan 6 Bahasa:**
  - 🇮🇩 Bahasa Indonesia
  - 🇺🇸 English
  - 🇯🇵 日本語 (Japanese)
  - 🇨🇳 简体中文 (Simplified Chinese)
  - 🇹🇼 繁體中文 (Traditional Chinese)
  - 🇰🇷 한국어 (Korean)

---

## Matriks Format & Codec

| Kategori | Format / Kontainer | Codec | Catatan |
| :--- | :--- | :--- | :--- |
| **Video** | `.mp4` | H.264 (`libx264`), H.265 (`libx265`) | Mendukung flag `-movflags +faststart` & `-tag:v hvc1` |
| **Video** | `.mkv` | H.264 (`libx264`), H.265 (`libx265`) | Fleksibel untuk subtitle & multi-audio |
| **Video** | `.mov` | H.264 (`libx264`), H.265 (`libx265`) | Format standar ekosistem editing |
| **Audio** | `.mp3` | MP3 (`libmp3lame`) | Bitrate 64 - 320 kbps atau copy |
| **Audio** | `.m4a` | AAC (`aac`) | Kualitas tinggi efisien untuk ponsel |
| **Audio** | `.wav` | PCM (`pcm_s16le`) | Uncompressed lossless kualitas studio |

---

## Kompilasi & Build

Phantek menggunakan library native FFmpeg yang dikompilasi khusus untuk arsitektur modern **64-bit ARM (`arm64-v8a`)** demi performa optimal dan efisiensi memori.

### Build Rilis APK Lokal

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64
```

Hasil build berkas APK rilis berada di direktori:
`build/app/outputs/flutter-apk/Phantek-Video-Toolkit-arm64-v8a-v1.2.1.apk`

---

## Riwayat Versi

- **v1.2.1 (Build 17):**
  - Menghapus codec VP9 dan kontainer WebM untuk menjaga stabilitas encoding.
  - Standardisasi pipeline video ke H.264 & H.265 (MP4, MKV, MOV) dan audio ke AAC, MP3, WAV.
  - Pembersihan menyeluruh kode yang tidak terpakai (*unused code*) serta penyempurnaan deteksi SoC 64-bit modern.
- **v1.2.0 (Build 16):**
  - Standardisasi Application ID dan namespace Android `com.phantek.cygnus.albireo`.
  - Penyederhanaan pilihan preset kecepatan CPU di menu Pengaturan.
- **v1.1.5 (Build 15):**
  - Penambahan dashboard telemetri real-time (grafik CPU, RAM RSS Linux `/proc/self/status`, dan Storage I/O).
  - Penambahan opsi kualitas audio 320 kbps dan buffer RAM hingga 4096 MB dengan proteksi OOM.
- **v1.1.3 - v1.1.4:**
  - Penambahan fitur Audio Extractor (MP3, M4A, WAV).
  - Klasifikasi resolusi otomatis untuk video portrait dan landscape.
  - Deteksi spesifikasi hardware perangkat lengkap di Pengaturan.
- **v1.1.2:**
  - Integrasi Android Foreground Service dan CPU Wakelock untuk proses di latar belakang dan saat layar mati.

---

## Lisensi

Proyek ini dilisensikan di bawah **GNU General Public License v3.0 (GPLv3)**. Silakan baca berkas [LICENSE](LICENSE) untuk ketentuan lisensi lengkap.

---

<div align="center">
  <br/>
  <a href="https://github.com/zerabyte88">
    <img src="https://github.com/zerabyte88.png" width="48" height="48" style="border-radius: 50%;" alt="zerabyte88" />
  </a>
  <br/>
  <sub>Dikembangkan dengan ❤️ oleh <a href="https://github.com/zerabyte88">zerabyte88</a> (Creator & Maintainer)</sub>
</div>
