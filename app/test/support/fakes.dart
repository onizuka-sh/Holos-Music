import 'dart:async';

import 'package:holos_music/playback/audio_engine.dart';
import 'package:holos_music/playback/local_flac_file.dart';
import 'package:holos_music/library/local_library.dart';

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

const testFolder = LibraryFolder(
  uri: 'content://test/tree/music',
  name: 'Music',
  available: true,
);
const testLibraryTrack = LibraryTrack(
  id: 'test:music/test.flac',
  uri: 'content://test/tree/music/document/test.flac',
  folderUri: 'content://test/tree/music',
  title: 'Test FLAC',
  artist: 'Test Artist',
  duration: Duration(minutes: 3),
);

class FakeLibraryService implements LocalLibraryService {
  LibrarySnapshot stored = const LibrarySnapshot();
  LibrarySnapshot? selection;
  LibrarySnapshot scanResult = const LibrarySnapshot(
    folders: [testFolder],
    tracks: [testLibraryTrack],
  );
  Object? failure;
  Completer<LibrarySnapshot>? scanPending;
  int scans = 0;
  int cancellations = 0;
  final progressEvents = StreamController<ScanProgress>.broadcast(sync: true);
  @override
  Stream<ScanProgress> get progress => progressEvents.stream;
  @override
  Future<LibrarySnapshot> load() async {
    if (failure != null) throw failure!;
    return stored;
  }

  @override
  Future<LibrarySnapshot?> selectFolder() async {
    if (failure != null) throw failure!;
    if (selection != null) stored = selection!;
    return selection;
  }

  @override
  Future<LibrarySnapshot> scan() async {
    scans++;
    if (failure != null) throw failure!;
    stored = scanPending == null ? scanResult : await scanPending!.future;
    return stored;
  }

  @override
  Future<void> cancel() async {
    cancellations++;
  }

  @override
  Future<LibrarySnapshot> forgetFolder(String uri) async {
    stored = LibrarySnapshot(
      folders: stored.folders.where((folder) => folder.uri != uri).toList(),
      tracks: stored.tracks.where((track) => track.folderUri != uri).toList(),
    );
    return stored;
  }
}

class FakePicker implements LocalFlacPicker {
  String? openedUri;
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

  @override
  Future<LocalFlacFile> openUri(String uri) async {
    openedUri = uri;
    if (failure != null) throw failure!;
    return selected ?? testTrack;
  }
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
