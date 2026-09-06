// Lifecycle/state handling adapted from Mornye's preview_player_provider.dart.
// Copyright 2026 zarzet. SPDX-License-Identifier: LGPL-3.0-only
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_engine.dart';
import 'local_flac_file.dart';

enum PlayerStatus { idle, loading, playing, paused, ended, error }

class PlayerController extends ChangeNotifier {
  PlayerController({
    required this.picker,
    required this.createEngine,
    this.loadTimeout = const Duration(seconds: 20),
  });

  final LocalFlacPicker picker;
  final AudioEngine Function() createEngine;
  final Duration loadTimeout;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  AudioEngine? _engine;
  LocalFlacFile? file;
  PlayerStatus status = PlayerStatus.idle;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  String? error;
  bool picking = false;
  bool commanding = false;
  bool _disposed = false;
  bool _foreground = true;

  bool get busy => picking || commanding || status == PlayerStatus.loading;
  bool get canControl => file != null && !busy && status != PlayerStatus.error;

  void _publish() {
    if (!_disposed) notifyListeners();
  }

  void _failure(Object failure) {
    if (_disposed) return;
    // Log event/category only: content URIs, titles and paths can be private.
    debugPrint('Holos playback failure: ${failure.runtimeType}');
    error = switch (failure) {
      PlatformException(code: 'not_flac') =>
        'This file is not a supported FLAC file. Choose another file.',
      PlatformException(code: 'access_denied') =>
        'File access was denied. Open the file again to grant access.',
      PlatformException(code: 'picker_unavailable') =>
        'No file picker is available on this device.',
      TimeoutException() =>
        'The file took too long to open. Try again or choose another file.',
      _ => 'Could not play this file. Try again or choose another FLAC file.',
    };
    status = PlayerStatus.error;
    unawaited(
      _engine?.pause().catchError((Object _) {}) ?? Future<void>.value(),
    );
    _publish();
  }

  Future<void> openFile() => _openSelection(picker.pick);

  Future<void> playLibraryFile(String uri) =>
      _openSelection(() => picker.openUri(uri));

  Future<void> _openSelection(Future<LocalFlacFile?> Function() select) async {
    if (busy || _disposed) return;
    picking = true;
    error = null;
    _publish();
    try {
      final selected = await select();
      if (_disposed) {
        if (selected != null) await picker.release(selected);
        return;
      }
      if (selected == null) return;
      final previous = file;
      await _disposeEngine();
      if (previous != null) await _release(previous);
      if (_disposed) {
        await _release(selected);
        return;
      }
      file = selected;
      picking = false;
      await _start();
    } catch (failure) {
      // A rejected/cancelled selection must not invalidate existing playback.
      if (file != null && status != PlayerStatus.error) {
        error = failure is PlatformException && failure.code == 'not_flac'
            ? 'Choose a valid FLAC file. Your current track is still available.'
            : 'Could not open the file. Your current track is still available.';
        debugPrint('Holos file selection failed: ${failure.runtimeType}');
      } else {
        _failure(failure);
      }
    } finally {
      picking = false;
      _publish();
    }
  }

  Future<void> _start() async {
    final selected = file;
    if (selected == null || _disposed) return;
    status = PlayerStatus.loading;
    error = null;
    position = Duration.zero;
    duration = selected.duration;
    _publish();
    final engine = createEngine();
    _engine = engine;
    bool current() => !_disposed && identical(_engine, engine);
    _subscriptions.addAll([
      engine.states.listen(
        (event) {
          if (!current() || status == PlayerStatus.error) return;
          // Preparation can emit stopped; it is not the end of a loaded track.
          if (event == AudioEngineState.stopped) return;
          status = switch (event) {
            AudioEngineState.playing => PlayerStatus.playing,
            AudioEngineState.paused => PlayerStatus.paused,
            AudioEngineState.completed => PlayerStatus.ended,
            AudioEngineState.stopped => status,
          };
          if (status == PlayerStatus.ended) position = duration;
          _publish();
        },
        onError: (Object failure) {
          if (current()) _failure(failure);
        },
      ),
      engine.positions.listen(
        (value) {
          if (!current() || status == PlayerStatus.error) return;
          position = _clamp(value);
          _publish();
        },
        onError: (Object failure) {
          if (current()) _failure(failure);
        },
      ),
      engine.durations.listen(
        (value) {
          if (!current() || value <= Duration.zero) return;
          duration = value;
          _publish();
        },
        onError: (Object failure) {
          if (current()) _failure(failure);
        },
      ),
    ]);
    try {
      await engine.load(selected.path).timeout(loadTimeout);
      if (!current() || status == PlayerStatus.error) return;
      if (_foreground) {
        await engine.resume().timeout(loadTimeout);
        if (current() && status != PlayerStatus.error) {
          if (!_foreground) await engine.pause();
          status = _foreground ? PlayerStatus.playing : PlayerStatus.paused;
        }
      } else {
        status = PlayerStatus.paused;
      }
    } catch (failure) {
      if (current()) {
        await _disposeEngine();
        _failure(failure);
      }
    }
    _publish();
  }

  Duration _clamp(Duration value) => Duration(
    milliseconds: value.inMilliseconds.clamp(0, duration.inMilliseconds),
  );

  Future<void> togglePlayback() async {
    if (!canControl || _engine == null) return;
    commanding = true;
    _publish();
    try {
      if (status == PlayerStatus.playing) {
        await _engine!.pause();
        status = PlayerStatus.paused;
      } else if (_foreground) {
        if (status == PlayerStatus.ended) {
          await _engine!.seek(Duration.zero);
          position = Duration.zero;
        }
        await _engine!.resume();
        if (!_foreground) await _engine!.pause();
        status = _foreground ? PlayerStatus.playing : PlayerStatus.paused;
      }
    } catch (failure) {
      _failure(failure);
    } finally {
      commanding = false;
      _publish();
    }
  }

  Future<void> seek(Duration value) async {
    if (!canControl || duration <= Duration.zero || _engine == null) return;
    commanding = true;
    try {
      final target = _clamp(value);
      await _engine!.seek(target);
      position = target;
      if (status == PlayerStatus.ended && target < duration) {
        status = PlayerStatus.paused;
      }
    } catch (failure) {
      _failure(failure);
    } finally {
      commanding = false;
      _publish();
    }
  }

  Future<void> retry() async {
    if (busy || file == null || _disposed) return;
    commanding = true;
    _publish();
    try {
      await _disposeEngine();
      await _start();
    } finally {
      commanding = false;
      _publish();
    }
  }

  Future<void> setForeground(bool foreground) async {
    _foreground = foreground;
    if (!foreground && status == PlayerStatus.playing && _engine != null) {
      try {
        await _engine!.pause();
        if (!_disposed && status != PlayerStatus.error) {
          status = PlayerStatus.paused;
        }
      } catch (failure) {
        _failure(failure);
      }
      _publish();
    }
  }

  Future<void> _release(LocalFlacFile selected) async {
    try {
      await picker.release(selected);
    } catch (_) {
      debugPrint('Holos file handle cleanup failed.');
    }
  }

  Future<void> _disposeEngine() async {
    final old = _engine;
    _engine = null;
    final subscriptions = List.of(_subscriptions);
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    try {
      await old?.dispose();
    } catch (_) {
      debugPrint('Holos audio cleanup failed.');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    final selected = file;
    unawaited(
      _disposeEngine().then((_) async {
        if (selected != null) await _release(selected);
      }),
    );
    super.dispose();
  }
}
