import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class LibraryFolder {
  const LibraryFolder({
    required this.uri,
    required this.name,
    required this.available,
  });
  final String uri;
  final String name;
  final bool available;
  factory LibraryFolder.fromMap(Map<String, dynamic> map) => LibraryFolder(
    uri: map['uri'] as String,
    name: map['name'] as String,
    available: map['available'] == true,
  );
}

class LibraryTrack {
  const LibraryTrack({
    required this.id,
    required this.uri,
    required this.folderUri,
    required this.title,
    required this.artist,
    required this.duration,
  });
  final String id;
  final String uri;
  final String folderUri;
  final String title;
  final String artist;
  final Duration duration;
  factory LibraryTrack.fromMap(Map<String, dynamic> map) => LibraryTrack(
    id: map['id'] as String,
    uri: map['uri'] as String,
    folderUri: map['folderUri'] as String,
    title: map['title'] as String,
    artist: map['artist'] as String,
    duration: Duration(milliseconds: (map['durationMs'] as num).toInt()),
  );
}

class LibrarySnapshot {
  const LibrarySnapshot({
    this.folders = const [],
    this.tracks = const [],
    this.skipped = 0,
  });
  final List<LibraryFolder> folders;
  final List<LibraryTrack> tracks;
  final int skipped;
  bool available(LibraryTrack track) => folders.any(
    (folder) => folder.uri == track.folderUri && folder.available,
  );
  factory LibrarySnapshot.fromMap(Map<String, dynamic> map) {
    final folders = (map['folders'] as List)
        .map(
          (value) =>
              LibraryFolder.fromMap(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
    final tracks = <String, LibraryTrack>{};
    for (final raw in map['tracks'] as List) {
      final track = LibraryTrack.fromMap(Map<String, dynamic>.from(raw as Map));
      tracks[track.id] = track;
    }
    return LibrarySnapshot(
      folders: List.unmodifiable(folders),
      tracks: List.unmodifiable(tracks.values),
      skipped: (map['skipped'] as num?)?.toInt() ?? 0,
    );
  }
}

LibrarySnapshot parseLibrary(String encoded) =>
    LibrarySnapshot.fromMap(jsonDecode(encoded) as Map<String, dynamic>);

class ScanProgress {
  const ScanProgress({this.checked = 0, this.found = 0, this.skipped = 0});
  final int checked;
  final int found;
  final int skipped;
}

abstract interface class LocalLibraryService {
  Stream<ScanProgress> get progress;
  Future<LibrarySnapshot> load();
  Future<LibrarySnapshot?> selectFolder();
  Future<LibrarySnapshot> scan();
  Future<void> cancel();
  Future<LibrarySnapshot> forgetFolder(String uri);
}

class AndroidLocalLibraryService implements LocalLibraryService {
  static const _channel = MethodChannel('org.holosmusic/library');
  static const _events = EventChannel('org.holosmusic/library_progress');
  @override
  Stream<ScanProgress> get progress =>
      _events.receiveBroadcastStream().map((event) {
        final data = event as Map;
        return ScanProgress(
          checked: (data['checked'] as num).toInt(),
          found: (data['found'] as num).toInt(),
          skipped: (data['skipped'] as num).toInt(),
        );
      });
  Future<LibrarySnapshot> _invoke(
    String method, [
    Map<String, Object>? arguments,
  ]) async {
    final encoded = await _channel.invokeMethod<String>(method, arguments);
    if (encoded == null) throw StateError('Missing library response');
    return compute(parseLibrary, encoded);
  }

  @override
  Future<LibrarySnapshot> load() => _invoke('load');
  @override
  Future<LibrarySnapshot?> selectFolder() async {
    final encoded = await _channel.invokeMethod<String>('pickFolder');
    return encoded == null ? null : compute(parseLibrary, encoded);
  }

  @override
  Future<LibrarySnapshot> scan() => _invoke('scan');
  @override
  Future<void> cancel() => _channel.invokeMethod<void>('cancel');
  @override
  Future<LibrarySnapshot> forgetFolder(String uri) =>
      _invoke('forgetFolder', {'uri': uri});
}
