# Third-Party Notices

Phantek - Video Toolkit is licensed under the GNU General Public License v3.0 or later
(see [LICENSE](LICENSE)). Copyright (C) 2026 zerabyte88.

This application bundles or links the third-party components listed below. Each component
remains under its own license, and nothing in this file changes those licenses.

## Media processing

| Component | Role | License | Upstream |
|:--|:--|:--|:--|
| FFmpeg | Video/audio transcoding, scaling, extraction | GNU GPL (GPL build with libx264 enabled), used here under GPL-3.0 | https://ffmpeg.org |
| FFmpegKit (`ffmpeg_kit_flutter_new`, full-GPL build) | FFmpeg/FFprobe bindings for Flutter and Android | Core under LGPL-3.0 (see [LICENSE.ffmpegkit](LICENSE.ffmpegkit)); the full-GPL build also contains GPL v3.0 components (see [LICENSE.ffmpegkit.GPLv3](LICENSE.ffmpegkit.GPLv3)), so the combined binary is distributed under GPL-3.0 | https://pub.dev/packages/ffmpeg_kit_flutter_new, original project https://github.com/arthenica/ffmpeg-kit |
| x264 (`libx264`) | H.264 video encoding | GPL-2.0-or-later | https://www.videolan.org/developers/x264.html |
| LAME (`libmp3lame`) | MP3 audio encoding | LGPL (see upstream for the exact version terms) | https://lame.sourceforge.io |

The full-GPL FFmpegKit build bundles additional native libraries (for example x265, xvidcore
and vid.stab, among others). Each is covered by its own license; see the package page above and
the license notices shipped with the package for the complete list.

FFmpeg is a trademark of Fabrice Bellard, originator of the FFmpeg project.

## Flutter, Dart and Material Icons

| Component | License |
|:--|:--|
| Flutter framework and engine, Dart SDK | BSD-3-Clause (The Flutter / Dart Authors) |
| Material Icons font | Apache-2.0 (Google) |

## Dart/Flutter packages (direct dependencies)

Exact versions are pinned in [pubspec.lock](pubspec.lock). Each package is under its own
open-source license; the full texts for all Dart packages are also shown in the app under
**Settings > About > License**.

- [device_info_plus](https://pub.dev/packages/device_info_plus)
- [file_picker](https://pub.dev/packages/file_picker)
- [flutter_foreground_task](https://pub.dev/packages/flutter_foreground_task)
- [open_file](https://pub.dev/packages/open_file)
- [package_info_plus](https://pub.dev/packages/package_info_plus)
- [path_provider](https://pub.dev/packages/path_provider)
- [share_plus](https://pub.dev/packages/share_plus)
- [shared_preferences](https://pub.dev/packages/shared_preferences)
- [url_launcher](https://pub.dev/packages/url_launcher)
- [wakelock_plus](https://pub.dev/packages/wakelock_plus)

## Source code availability

The complete corresponding source of this application is available at
https://github.com/zerabyte88/phantek-video-toolkit, at the tag matching each release.
Source for the bundled third-party libraries is available from the upstream projects linked above.
