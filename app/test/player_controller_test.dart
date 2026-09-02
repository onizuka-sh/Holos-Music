import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holos_music/playback/audio_engine.dart';
import 'package:holos_music/playback/local_flac_file.dart';
import 'package:holos_music/playback/player_controller.dart';

import 'support/fakes.dart';

void main() {
  late FakePicker picker;
  late List<FakeEngine> engines;
  late PlayerController controller;

  setUp(() {
    picker = FakePicker();
    engines = [];
    controller = PlayerController(
      picker: picker,
      createEngine: () {
        final engine = FakeEngine();
        engines.add(engine);
        return engine;
      },
    );
  });
  tearDown(() async {
    controller.dispose();
    await Future<void>.delayed(Duration.zero);
  });

  test('opens metadata, plays, pauses, seeks, completes and replays', () async {
    await controller.openFile();
    final engine = engines.single;
    expect(controller.status, PlayerStatus.playing);
    expect(controller.file?.bitDepth, 24);
    expect(controller.duration, const Duration(minutes: 3));
    await controller.togglePlayback();
    expect(controller.status, PlayerStatus.paused);
    await controller.seek(const Duration(minutes: 5));
    expect(engine.lastSeek, const Duration(minutes: 3));
    await controller.seek(const Duration(seconds: -1));
    expect(engine.lastSeek, Duration.zero);
    engine.stateEvents.add(AudioEngineState.completed);
    expect(controller.status, PlayerStatus.ended);
    await controller.togglePlayback();
    expect(engine.lastSeek, Duration.zero);
    expect(controller.status, PlayerStatus.playing);
  });

  test(
    'cancelled selection preserves the existing session and handle',
    () async {
      await controller.openFile();
      engines.single.positionEvents.add(const Duration(seconds: 25));
      picker.selected = null;
      await controller.openFile();
      expect(engines.length, 1);
      expect(controller.status, PlayerStatus.playing);
      expect(controller.position, const Duration(seconds: 25));
      expect(picker.released, isEmpty);
    },
  );

  test('invalid new file leaves existing playback available', () async {
    await controller.openFile();
    picker.failure = PlatformException(code: 'not_flac');
    await controller.openFile();
    expect(controller.status, PlayerStatus.playing);
    expect(controller.error, contains('valid FLAC'));
    expect(controller.canControl, isTrue);
    expect(picker.released, isEmpty);
  });

  test(
    'denied initial selection reports recovery and can be retried',
    () async {
      picker.failure = PlatformException(code: 'access_denied');
      await controller.openFile();
      expect(controller.status, PlayerStatus.error);
      expect(controller.error, contains('grant access'));
      picker.failure = null;
      await controller.openFile();
      expect(controller.status, PlayerStatus.playing);
      expect(controller.error, isNull);
    },
  );

  test(
    'replacing a file disposes the engine before releasing the lease',
    () async {
      await controller.openFile();
      picker.selected = const LocalFlacFile(
        leaseId: '2',
        path: '/proc/self/fd/2',
        name: 'next.flac',
        title: 'Next',
        artist: 'Artist',
        duration: Duration(minutes: 2),
        sampleRate: 44100,
        bitDepth: 16,
      );
      await controller.openFile();
      expect(engines.first.disposals, 1);
      expect(picker.released, ['1']);
      expect(controller.file?.title, 'Next');
      expect(controller.position, Duration.zero);
    },
  );

  test(
    'runtime failure pauses audio, preserves error and permits engine retry',
    () async {
      await controller.openFile();
      engines.first.stateEvents.addError(StateError('decoder failure'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.status, PlayerStatus.error);
      expect(engines.first.pauses, 1);
      expect(controller.canControl, isFalse);
      await controller.retry();
      expect(engines.first.disposals, 1);
      expect(engines.length, 2);
      expect(controller.status, PlayerStatus.playing);
    },
  );

  test(
    'backgrounding while loading prevents autoplay on load completion',
    () async {
      final gate = Completer<void>();
      controller.dispose();
      controller = PlayerController(
        picker: picker,
        createEngine: () {
          final engine = FakeEngine()..loadGate = gate;
          engines.add(engine);
          return engine;
        },
      );
      final opening = controller.openFile();
      await Future<void>.delayed(Duration.zero);
      expect(controller.status, PlayerStatus.loading);
      await controller.setForeground(false);
      gate.complete();
      await opening;
      expect(controller.status, PlayerStatus.paused);
      expect(engines.single.resumes, 0);
      await controller.setForeground(true);
      expect(controller.status, PlayerStatus.paused);
    },
  );

  test(
    'backgrounding during resume pauses after asynchronous resume finishes',
    () async {
      await controller.openFile();
      await controller.togglePlayback();
      final gate = Completer<void>();
      engines.single.resumeGate = gate;
      final resuming = controller.togglePlayback();
      await controller.setForeground(false);
      gate.complete();
      await resuming;
      expect(controller.status, PlayerStatus.paused);
      expect(engines.single.pauses, 2);
    },
  );

  test('disposal while picker is open releases the late selection', () async {
    picker.pending = Completer<LocalFlacFile?>();
    final opening = controller.openFile();
    controller.dispose();
    picker.pending!.complete(testTrack);
    await opening;
    expect(picker.released, ['1']);
    expect(engines, isEmpty);
    // Replace the disposed instance for the shared teardown.
    controller = PlayerController(picker: picker, createEngine: FakeEngine.new);
  });

  test('load timeout disposes a stuck engine and reports retry', () async {
    controller.dispose();
    controller = PlayerController(
      picker: picker,
      loadTimeout: const Duration(milliseconds: 10),
      createEngine: () {
        final engine = FakeEngine()..loadGate = Completer<void>();
        engines.add(engine);
        return engine;
      },
    );
    await controller.openFile();
    expect(controller.status, PlayerStatus.error);
    expect(controller.error, contains('too long'));
    expect(engines.single.disposals, 1);
  });
}
