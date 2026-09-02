import 'dart:async';

import 'package:holos_music/playback/audio_engine.dart';
import 'package:holos_music/playback/local_flac_file.dart';

const testTrack = LocalFlacFile(
  leaseId: '1',
  path: '/proc/self/fd/1',
  name: 'test.flac',
  title: 'Test FLAC',
  artist: 'Test Artist',
  duration: Duration(minutes: 3),
  sampleRate: 96000,
  bitDepth: 24,
);

class FakePicker implements LocalFlacPicker {
  LocalFlacFile? selected = testTrack;
  Object? failure;
  Completer<LocalFlacFile?>? pending;
  final released = <String>[];

  @override
  Future<LocalFlacFile?> pick() async {
    if (failure != null) throw failure!;
    if (pending != null) return pending!.future;
    return selected;
  }

  @override
  Future<void> release(LocalFlacFile file) async => released.add(file.leaseId);
}

class FakeEngine implements AudioEngine {
  final stateEvents = StreamController<AudioEngineState>.broadcast(sync: true);
  final positionEvents = StreamController<Duration>.broadcast(sync: true);
  final durationEvents = StreamController<Duration>.broadcast(sync: true);
  Object? loadFailure;
  Completer<void>? loadGate;
  Completer<void>? resumeGate;
  int pauses = 0;
  int resumes = 0;
  int disposals = 0;
  Duration? lastSeek;
  String? source;

  @override
  Stream<AudioEngineState> get states => stateEvents.stream;
  @override
  Stream<Duration> get positions => positionEvents.stream;
  @override
  Stream<Duration> get durations => durationEvents.stream;
  @override
  Future<void> load(String path) async {
    source = path;
    if (loadFailure != null) throw loadFailure!;
    if (loadGate != null) await loadGate!.future;
  }

  @override
  Future<void> resume() async {
    resumes++;
    if (resumeGate != null) await resumeGate!.future;
    stateEvents.add(AudioEngineState.playing);
  }

  @override
  Future<void> pause() async {
    pauses++;
    stateEvents.add(AudioEngineState.paused);
  }

  @override
  Future<void> seek(Duration position) async => lastSeek = position;
  @override
  Future<void> dispose() async {
    disposals++;
    await stateEvents.close();
    await positionEvents.close();
    await durationEvents.close();
  }
}
