import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holos_music/library/library_controller.dart';
import 'package:holos_music/library/local_library.dart';

import 'support/fakes.dart';

void main() {
  late FakeLibraryService service;
  late LibraryController controller;
  setUp(() {
    service = FakeLibraryService();
    controller = LibraryController(service);
  });
  tearDown(() async {
    controller.dispose();
    await service.progressEvents.close();
  });

  test(
    'selection starts a scan and saved tracks can be loaded again',
    () async {
      service.selection = const LibrarySnapshot(folders: [testFolder]);
      await controller.selectFolder();
      expect(service.scans, 1);
      expect(controller.snapshot.tracks.single.id, testLibraryTrack.id);
      expect(controller.message, contains('1 tracks'));
      expect(controller.busy, isFalse);
      final restored = LibraryController(service);
      await restored.load();
      expect(restored.snapshot.tracks.single.uri, testLibraryTrack.uri);
      restored.dispose();
    },
  );

  test(
    'cancelled folder picker keeps the collection and does not rescan',
    () async {
      service.stored = service.scanResult;
      await controller.load();
      await controller.selectFolder();
      expect(controller.snapshot.tracks.length, 1);
      expect(service.scans, 0);
    },
  );

  test(
    'cancelled scan keeps the prior snapshot and reports progress',
    () async {
      service.stored = service.scanResult;
      await controller.load();
      service.scanPending = Completer<LibrarySnapshot>();
      final pending = controller.rescan();
      service.progressEvents.add(const ScanProgress(checked: 8, found: 3));
      expect(controller.progress.checked, 8);
      await controller.cancelScan();
      expect(controller.cancelRequested, isTrue);
      expect(service.cancellations, 1);
      service.scanPending!.completeError(
        PlatformException(code: 'scan_cancelled'),
      );
      await pending;
      expect(controller.snapshot.tracks.single.id, testLibraryTrack.id);
      expect(controller.message, contains('previous library was kept'));
      expect(controller.busy, isFalse);
    },
  );

  test('scan failure keeps old library and permits retry', () async {
    service.stored = service.scanResult;
    await controller.load();
    service.failure = PlatformException(code: 'scan_failed');
    await controller.rescan();
    expect(controller.snapshot.tracks.length, 1);
    expect(controller.message, contains('Try again'));
    service.failure = null;
    await controller.rescan();
    expect(controller.message, contains('Scan complete'));
  });

  test(
    'unavailable folder disables its cached tracks and offers recovery',
    () async {
      service.stored = const LibrarySnapshot(
        folders: [
          LibraryFolder(
            uri: 'content://test/tree/music',
            name: 'Music',
            available: false,
          ),
        ],
        tracks: [testLibraryTrack],
      );
      await controller.load();
      expect(controller.snapshot.available(testLibraryTrack), isFalse);
      service.selection = const LibrarySnapshot(
        folders: [testFolder],
        tracks: [testLibraryTrack],
      );
      await controller.selectFolder();
      expect(controller.snapshot.available(testLibraryTrack), isTrue);
    },
  );

  test(
    'removing the final source removes only its cached collection',
    () async {
      service.stored = service.scanResult;
      await controller.load();
      await controller.forgetFolder(testFolder.uri);
      expect(controller.snapshot.folders, isEmpty);
      expect(controller.snapshot.tracks, isEmpty);
      expect(service.scans, 0);
    },
  );

  test('busy guard prevents overlapping scans or pickers', () async {
    service.stored = service.scanResult;
    await controller.load();
    service.scanPending = Completer<LibrarySnapshot>();
    final pending = controller.rescan();
    await controller.rescan();
    await controller.selectFolder();
    expect(service.scans, 1);
    service.scanPending!.complete(service.scanResult);
    await pending;
  });

  test('snapshot deduplicates by source identity, not title or filename', () {
    final raw = <String, dynamic>{
      'folders': [
        {'uri': testFolder.uri, 'name': 'Music', 'available': true},
      ],
      'tracks': [
        for (final id in ['a', 'a', 'b'])
          {
            'id': id,
            'uri': 'content://test/$id',
            'folderUri': testFolder.uri,
            'title': 'Same title',
            'artist': 'Artist',
            'durationMs': 1000,
          },
      ],
    };
    final snapshot = LibrarySnapshot.fromMap(raw);
    expect(snapshot.tracks.map((track) => track.id), ['a', 'b']);
  });
}
