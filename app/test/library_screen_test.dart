import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holos_music/holos_app.dart';
import 'package:holos_music/library/local_library.dart';
import 'package:holos_music/playback/player_controller.dart';

import 'support/fakes.dart';

void main() {
  testWidgets(
    'add folder scans library and selecting a row plays its document URI',
    (tester) async {
      final service = FakeLibraryService()
        ..selection = const LibrarySnapshot(folders: [testFolder]);
      final picker = FakePicker();
      final player = PlayerController(
        picker: picker,
        createEngine: FakeEngine.new,
      );
      addTearDown(player.dispose);
      await tester.pumpWidget(
        HolosMusicApp(controller: player, libraryService: service),
      );
      await tester.pump();
      expect(find.text('Choose your music folder'), findsOneWidget);
      await tester.tap(find.byKey(const Key('add-folder')));
      await tester.pump();
      expect(find.text('Test FLAC'), findsOneWidget);
      await tester.ensureVisible(find.byKey(ValueKey(testLibraryTrack.id)));
      await tester.tap(find.byKey(ValueKey(testLibraryTrack.id)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(picker.openedUri, testLibraryTrack.uri);
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('revoked folder access is shown and cached songs are disabled', (
    tester,
  ) async {
    final service = FakeLibraryService()
      ..stored = const LibrarySnapshot(
        folders: [
          LibraryFolder(
            uri: 'content://test/tree/music',
            name: 'Music',
            available: false,
          ),
        ],
        tracks: [testLibraryTrack],
      );
    final player = PlayerController(
      picker: FakePicker(),
      createEngine: FakeEngine.new,
    );
    addTearDown(player.dispose);
    await tester.pumpWidget(
      HolosMusicApp(controller: player, libraryService: service),
    );
    await tester.pump();
    expect(
      find.text('Access unavailable. Reselect this folder.'),
      findsOneWidget,
    );
    final trackRow = tester.widget<ListTile>(
      find.byKey(ValueKey(testLibraryTrack.id)),
    );
    expect(trackRow.enabled, isFalse);
    expect(trackRow.onTap, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
