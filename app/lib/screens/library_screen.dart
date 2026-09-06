import 'dart:async';

import 'package:flutter/material.dart';

import '../library/library_controller.dart';
import '../library/local_library.dart';
import '../playback/player_controller.dart';
import '../theme/app_tokens.dart';
import 'player_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.library, required this.player});
  final LibraryController library;
  final PlayerController player;

  void _openPlayer(BuildContext context) => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => PlayerScreen(controller: player)),
  );

  Future<void> _forget(BuildContext context, LibraryFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove folder from library?'),
        content: Text(
          '${folder.name} will be removed from the saved library. Your music files will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove folder'),
          ),
        ],
      ),
    );
    if (confirmed == true) await library.forgetFolder(folder.uri);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([library, player]),
    builder: (context, _) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final tokens = context.tokens;
      final snapshot = library.snapshot;
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/brand/holos_logo.png',
                width: 32,
                height: 32,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 10),
              const Flexible(child: Text('Holos Music')),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Now playing',
              icon: const Icon(Icons.graphic_eq),
              onPressed: () => _openPlayer(context),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(tokens.gapXl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your library',
                        style: theme.textTheme.headlineMedium,
                      ),
                      SizedBox(height: tokens.gapSm),
                      Text(
                        '${snapshot.tracks.length} tracks · Local FLAC',
                        style: theme.textTheme.bodyMedium,
                      ),
                      SizedBox(height: tokens.gapLg),
                      Wrap(
                        spacing: tokens.gapSm,
                        runSpacing: tokens.gapSm,
                        children: [
                          FilledButton.icon(
                            key: const Key('add-folder'),
                            onPressed: library.busy
                                ? null
                                : library.selectFolder,
                            icon: const Icon(Icons.create_new_folder_outlined),
                            label: const Text('Add folder'),
                          ),
                          OutlinedButton.icon(
                            key: const Key('rescan-library'),
                            onPressed: library.busy || snapshot.folders.isEmpty
                                ? null
                                : library.rescan,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Rescan'),
                          ),
                          TextButton.icon(
                            onPressed: () => _openPlayer(context),
                            icon: const Icon(Icons.audio_file_outlined),
                            label: const Text('Open one file'),
                          ),
                        ],
                      ),
                      if (library.loading || library.selecting) ...[
                        SizedBox(height: tokens.gapMd),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          library.selecting
                              ? 'Selecting folder…'
                              : 'Loading saved library…',
                        ),
                      ],
                      if (library.scanning) ...[
                        SizedBox(height: tokens.gapMd),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            library.cancelRequested
                                ? 'Cancelling after the current file…'
                                : '${library.progress.checked} files checked · ${library.progress.found} FLAC files read',
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: const Key('cancel-scan'),
                            onPressed: library.cancelRequested
                                ? null
                                : library.cancelScan,
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel scan'),
                          ),
                        ),
                      ],
                      if (library.message != null) ...[
                        SizedBox(height: tokens.gapMd),
                        Semantics(
                          liveRegion: true,
                          child: Text(library.message!),
                        ),
                        if (snapshot.folders.isEmpty && !library.busy)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: library.load,
                              child: const Text('Reload saved library'),
                            ),
                          ),
                      ],
                      if (snapshot.folders.isNotEmpty) ...[
                        SizedBox(height: tokens.gapXl),
                        Text(
                          'Music folders',
                          style: theme.textTheme.titleMedium,
                        ),
                        ...snapshot.folders.map(
                          (folder) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              folder.available
                                  ? Icons.folder_outlined
                                  : Icons.folder_off_outlined,
                              color: folder.available
                                  ? scheme.primary
                                  : scheme.error,
                            ),
                            title: Text(
                              folder.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: folder.available
                                ? null
                                : const Text(
                                    'Access unavailable. Reselect this folder.',
                                  ),
                            onTap: folder.available || library.busy
                                ? null
                                : library.selectFolder,
                            trailing: IconButton(
                              tooltip: 'Remove ${folder.name} from library',
                              onPressed: library.busy
                                  ? null
                                  : () => _forget(context, folder),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: tokens.gapLg),
                      Text('Songs', style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
              if (snapshot.tracks.isEmpty && !library.busy)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: tokens.gapXl),
                    child: Column(
                      children: [
                        Icon(
                          Icons.library_music_outlined,
                          size: 64,
                          color: scheme.primary,
                        ),
                        SizedBox(height: tokens.gapMd),
                        Text(
                          snapshot.folders.isEmpty
                              ? 'Choose your music folder'
                              : 'No FLAC files found',
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: tokens.gapSm),
                        Text(
                          snapshot.folders.isEmpty
                              ? 'Add a folder and allow access. Nested folders are scanned too.'
                              : 'Add a folder containing FLAC files, then rescan.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              SliverList.builder(
                itemCount: snapshot.tracks.length,
                itemBuilder: (context, index) {
                  final track = snapshot.tracks[index];
                  final available = snapshot.available(track);
                  return ListTile(
                    key: ValueKey(track.id),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: tokens.gapXl,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: scheme.surfaceContainerHigh,
                      child: Icon(
                        available ? Icons.music_note : Icons.lock_outline,
                        color: scheme.primary,
                      ),
                    ),
                    title: Text(
                      track.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      available
                          ? track.artist
                          : '${track.artist} · Folder access needed',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(formatPlaybackTime(track.duration)),
                    enabled: available && !player.busy,
                    onTap: available && !player.busy
                        ? () {
                            unawaited(player.playLibraryFile(track.uri));
                            _openPlayer(context);
                          }
                        : null,
                  );
                },
              ),
              SliverToBoxAdapter(child: SizedBox(height: tokens.gapXl)),
            ],
          ),
        ),
      );
    },
  );
}
