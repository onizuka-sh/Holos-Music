import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holos_music/holos_app.dart';
import 'package:holos_music/playback/player_controller.dart';
import 'support/fakes.dart';

void main() {
  testWidgets('empty player opens a FLAC file and play/pause controls work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = PlayerController(
      picker: FakePicker(),
      createEngine: FakeEngine.new,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(HolosMusicApp(controller: controller));
    expect(find.text('Holos Music'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byKey(const Key('play-pause'))).onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byKey(const Key('open-file')));
    await tester.tap(find.byKey(const Key('open-file')));
    await tester.pump();
    expect(find.text('Test FLAC'), findsOneWidget);
    expect(find.text('Test Artist'), findsOneWidget);
    expect(find.text('FLAC · 24-bit · 96.0 kHz'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('play-pause')));
    await tester.tap(find.byKey(const Key('play-pause')));
    await tester.pump();
    expect(find.text('Paused'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('small screen and large text stay scrollable without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = PlayerController(
      picker: FakePicker(),
      createEngine: FakeEngine.new,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: HolosMusicApp(controller: controller),
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('open-file')));
    await tester.tap(find.byKey(const Key('open-file')));
    await tester.pump();
    expect(controller.file, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
