# Holos Music 0.1.0 — source provenance

Selected components are copied/adapted from Mornye:
https://github.com/mornyeapp/Mornye
Revision: c90ec6478ad3e808ef22ba9464f8ad05054dde7b
Copyright 2026 zarzet. SPDX-License-Identifier: LGPL-3.0-only.

Original LICENSE, COPYING and NOTICE are retained verbatim. Copied source and
modifications in this project remain available under those terms. No Mornye
branding/logo or audio files are included.

| Holos Music source | Mornye source / modification |
| --- | --- |
| lib/theme/app_theme.dart, app_tokens.dart | Copied; package imports renamed |
| lib/models/theme_settings.dart, lib/utils/desktop_platform.dart | Copied theme dependencies; imports renamed |
| lib/widgets/expressive_seek_track.dart | Copied; imports renamed |
| lib/widgets/playback_seek_slider.dart | Copied; alternate Mornye theme branch removed; Material seeking behavior retained |
| lib/utils/playback_seek_preview.dart | Copied unchanged |
| lib/widgets/mornye_player_slider.dart | Retained source control; not used by default Material player |
| lib/playback/audio_engine.dart | Ordinary audioplayers source/release/output behavior extracted from music_playback_deck.dart; advanced routes/effects removed; foreground focus used |
| lib/playback/player_controller.dart | Lifecycle/state approach adapted from preview_player_provider.dart; local selection and explicit error/retry/completion handling added |
| lib/screens/player_screen.dart | Minimal single-file composition using Mornye theme, seek widget and transport sizes/colors from player_playback_controls.dart |
| third_party/audioplayers_android | Copied fork with upstream MIT license and Mornye patch notes; workspace resolution declaration removed for standalone use |
| assets/fonts/GoogleSansFlex.ttf | Copied font with accompanying license |
| .fvmrc, scripts/prepare_flutter_sdk.dart, patches/flutter/ | Copied SDK version pin and semantics preparation script/patch so fresh checkouts reproduce the tested SDK setup |

Holos Music branding is supplied by the user. The canonical source is
assets/brand/holos_logo_source.png; assets/brand/holos_logo.png is the generated
Flutter asset. Android icons/splash assets are generated from the same source.

The app shell and native single-file/STREAMINFO bridge are Holos Music integration
code. Downloader, network, provider, Rust backend, library and queue modules have
not been copied into this milestone.

Before distributing a binary, retain all component notices, make the corresponding
source and modifications available, and verify distribution obligations for the
actual packaged components. The in-app Licenses and credits page includes notices.
