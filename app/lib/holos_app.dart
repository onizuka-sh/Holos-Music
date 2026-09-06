import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'playback/audio_engine.dart';
import 'library/library_controller.dart';
import 'library/local_library.dart';
import 'playback/local_flac_file.dart';
import 'playback/player_controller.dart';
import 'screens/library_screen.dart';
import 'theme/app_theme.dart';

class HolosMusicApp extends StatefulWidget {
  const HolosMusicApp({super.key, this.controller, this.libraryService});
  final PlayerController? controller;
  final LocalLibraryService? libraryService;

  @override
  State<HolosMusicApp> createState() => _HolosMusicAppState();
}

class _HolosMusicAppState extends State<HolosMusicApp> {
  static bool _licensesRegistered = false;
  late final PlayerController _controller;
  late final LibraryController _library;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _library = LibraryController(
      widget.libraryService ?? AndroidLocalLibraryService(),
    );
    unawaited(_library.load());
    _controller =
        widget.controller ??
        PlayerController(
          picker: AndroidLocalFlacPicker(),
          createEngine: MornyeLocalAudioEngine.new,
        );
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        // Background service/session ownership is introduced in version 0.4.0.
        if (state == AppLifecycleState.resumed) {
          unawaited(_controller.setForeground(true));
          unawaited(_library.load());
        } else if (state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden ||
            state == AppLifecycleState.detached) {
          unawaited(_controller.setForeground(false));
        }
      },
    );
    if (!_licensesRegistered) {
      _licensesRegistered = true;
      LicenseRegistry.addLicense(() async* {
        yield LicenseEntryWithLineBreaks(
          const ['Mornye — adapted theme and playback components'],
          '${await rootBundle.loadString('NOTICE')}\n\n'
          '${await rootBundle.loadString('LICENSE')}\n\n'
          '${await rootBundle.loadString('COPYING')}',
        );
        yield LicenseEntryWithLineBreaks(
          const ['Google Sans Flex'],
          await rootBundle.loadString(
            'assets/fonts/GoogleSansFlex-LICENSE.txt',
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _library.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Holos Music',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    home: LibraryScreen(library: _library, player: _controller),
  );
}
