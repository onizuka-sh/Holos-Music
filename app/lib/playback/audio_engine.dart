// Local playback extracted from Mornye's music_playback_deck.dart.
// Copyright 2026 zarzet. SPDX-License-Identifier: LGPL-3.0-only
import 'package:audioplayers/audioplayers.dart';

enum AudioEngineState { playing, paused, stopped, completed }

abstract interface class AudioEngine {
  Stream<AudioEngineState> get states;
  Stream<Duration> get positions;
  Stream<Duration> get durations;
  Future<void> load(String path);
  Future<void> resume();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> dispose();
}

/// Mornye's ordinary Android output, without USB, effects, network or AutoMix.
class MornyeLocalAudioEngine implements AudioEngine {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<AudioEngineState> get states => _player.onPlayerStateChanged.map(
    (state) => switch (state) {
      PlayerState.playing => AudioEngineState.playing,
      PlayerState.paused => AudioEngineState.paused,
      PlayerState.completed => AudioEngineState.completed,
      _ => AudioEngineState.stopped,
    },
  );

  @override
  Stream<Duration> get positions => _player.onPositionChanged;
  @override
  Stream<Duration> get durations => _player.onDurationChanged;

  @override
  Future<void> load(String path) async {
    _player.positionUpdater = TimerPositionUpdater(
      interval: const Duration(milliseconds: 200),
      getPosition: _player.getCurrentPosition,
    );
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
          stayAwake: false,
        ),
      ),
    );
    // Mornye releases before loading because SAF may reuse descriptor numbers.
    await _player.release();
    await _player.setSource(DeviceFileSource(path));
  }

  @override
  Future<void> resume() => _player.resume();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> dispose() => _player.dispose();
}
