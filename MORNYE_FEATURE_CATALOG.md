# Mornye feature discovery

Source revision: c90ec6478ad3e808ef22ba9464f8ad05054dde7b.
Platform scope: Android. Status: source-inspected candidates, not runtime verified.
Holos Music remains independent; only user-selected features will be evaluated for adaptation.

## Evidence map

| Feature group | Inspected source under references/Mornye |
| --- | --- |
| Folder scanning, browsing, collections, duplicate review and cleanup | lib/providers/local_library_provider*.dart; lib/providers/library_collections_provider.dart; lib/utils/settings_search_catalog.dart |
| Playback, queue, session restore, sleep timer, hardware controls, AutoMix and autoplay | lib/services/music_player_service.dart; lib/services/music_player_automix.dart; lib/services/music_player_autoplay.dart |
| Equalizer, normalization, USB/exclusive playback, haptics, motion artwork and Discord | lib/screens/settings/playback_settings_page.dart; lib/providers/equalizer_provider.dart; lib/models/settings.dart |
| Lyrics, providers and share cards | lib/screens/lyrics_share_screen.dart; lib/screens/settings/lyrics_settings_page.dart; lib/utils/settings_search_catalog.dart |
| Tag editing, provider autofill, embedding, conversion and CUE splitting | lib/screens/track_metadata*.dart; lib/controllers/metadata_editor_controller.dart |
| Search, link import, downloads and provider fallback | lib/providers/track_provider.dart; lib/screens/home_tab_import.dart; lib/providers/download_queue_provider.dart; lib/screens/settings/download_settings_page.dart |
| Playlist imports | lib/services/csv_import_service.dart (CSV, M3U and M3U8) |
| SMB, WebDAV, HTTP and Subsonic/OpenSubsonic sources; network destination | lib/services/network_storage_service.dart; lib/services/network_storage_upload.dart; lib/screens/network_storage_screen.dart |
| Extensions and provider priorities | lib/providers/extension_provider.dart; lib/screens/settings/extensions_page.dart; lib/utils/settings_search_catalog.dart |
| Listening statistics and Rewind | lib/services/listening_statistics.dart; lib/services/listening_rewind.dart |
| Appearance, fonts, language, cache and diagnostics | lib/screens/settings/; lib/utils/settings_search_catalog.dart |
| Backup and restore | lib/services/backup_service.dart; lib/screens/settings/backup_restore_page.dart |
| Widgets, concerts, discovery and previews | lib/services/player_widget_service.dart; lib/services/concert_calendar_service.dart; lib/providers/explore_provider.dart; lib/providers/weekly_releases_provider.dart; lib/providers/preview_player_provider.dart |

Google Drive integration and Telegram music storage were not found as built-in
implementations in the inspected Dart/Rust sources. Telegram community links are
not storage functionality. Do not present either as an existing Mornye feature.

Provider-backed features depend on installed extensions, service availability and
credentials where applicable. USB/DSD features depend on compatible hardware.
User selection and per-feature dependency/licensing review are pending.
