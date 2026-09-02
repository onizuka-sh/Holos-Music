import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'playback/audio_engine.dart';
import 'playback/local_flac_file.dart';
import 'playback/player_controller.dart';
import 'screens/player_screen.dart';
import 'theme/app_theme.dart';

class HolosMusicApp extends StatefulWidget {
  const HolosMusicApp({super.key, this.controller});
  final PlayerController? controller;

  @override
  State<HolosMusicApp> createState() => _HolosMusicAppState();
}

class _HolosMusicAppState extends State<HolosMusicApp> {
  static bool _licensesRegistered = false;
  late final PlayerController _controller;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
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
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Holos Music',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    home: PlayerScreen(controller: _controller),
  );
}
