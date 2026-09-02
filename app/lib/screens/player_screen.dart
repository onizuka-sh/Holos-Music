// Player layout/transport styling follows Mornye's player_playback_controls.dart.
// Theme, tokens and seek track are adapted/copied from Mornye (LGPL-3.0-only).
import 'package:flutter/material.dart';

import '../playback/player_controller.dart';
import '../theme/app_tokens.dart';
import '../utils/playback_seek_preview.dart';
import '../widgets/playback_seek_slider.dart';

String formatPlaybackTime(Duration value) {
  final seconds = value.inSeconds;
  final minutes = (seconds ~/ 60).toString();
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remainder';
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.controller});
  final PlayerController controller;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _seekPreview = PlaybackSeekPreview();

  @override
  void dispose() {
    _seekPreview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final tokens = context.tokens;
      final file = controller.file;
      final playing = controller.status == PlayerStatus.playing;
      final loading = controller.status == PlayerStatus.loading;
      final description = switch (controller.status) {
        PlayerStatus.idle => 'Your music, on your device.',
        PlayerStatus.loading => 'Opening your FLAC file…',
        PlayerStatus.playing => 'Playing',
        PlayerStatus.paused => 'Paused',
        PlayerStatus.ended => 'Finished',
        PlayerStatus.error => 'Playback unavailable',
      };
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset('assets/brand/holos_logo.png', width: 32, height: 32,
                excludeFromSemantics: true),
              const SizedBox(width: 10),
              const Flexible(child: Text('Holos Music')),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Licenses and credits',
              icon: const Icon(Icons.info_outline),
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Holos Music',
                applicationVersion: '0.1.0',
                applicationIcon: Image.asset('assets/brand/holos_logo.png',
                  width: 64, height: 64, semanticLabel: 'Holos Music logo'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(tokens.gapXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'NOW PLAYING',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        letterSpacing: 1.6,
                      ),
                    ),
                    SizedBox(height: tokens.gapXl),
                    AspectRatio(
                      aspectRatio: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(
                            tokens.radiusCover,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.album_outlined,
                            size: 112,
                            color: scheme.primary,
                            semanticLabel: file == null
                                ? 'No track selected'
                                : 'FLAC audio',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: tokens.gapXl),
                    Text(
                      file?.title ?? 'Open a FLAC file',
                      key: const Key('track-title'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: tokens.gapSm),
                    Text(
                      file?.artist ?? 'Choose a file to start listening.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: tokens.gapMd),
                    Wrap(
                      spacing: tokens.gapSm,
                      runSpacing: tokens.gapSm,
                      children: [
                        Chip(
                          label: Text(
                            file == null
                                ? 'LOCAL FLAC'
                                : 'FLAC · ${file.bitDepth}-bit · ${file.sampleRate / 1000} kHz',
                          ),
                        ),
                        const Chip(label: Text('0.1.0')),
                      ],
                    ),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        description,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    SizedBox(height: tokens.gapMd),
                    IgnorePointer(
                      ignoring: !controller.canControl,
                      child: Semantics(
                        label: 'Playback position',
                        child: PlaybackSeekSlider(
                          key: ValueKey(file?.leaseId),
                          position: controller.position,
                          duration: controller.canControl
                              ? controller.duration
                              : Duration.zero,
                          onSeek: controller.seek,
                          preview: _seekPreview,
                          playing: playing,
                          edgeAligned: true,
                        ),
                      ),
                    ),
                    ValueListenableBuilder<Duration?>(
                      valueListenable: _seekPreview,
                      builder: (context, preview, _) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatPlaybackTime(preview ?? controller.position),
                          ),
                          Text(formatPlaybackTime(controller.duration)),
                        ],
                      ),
                    ),
                    SizedBox(height: tokens.gapLg),
                    Center(
                      child: IconButton.filled(
                        key: const Key('play-pause'),
                        style: IconButton.styleFrom(
                          minimumSize: const Size.square(68),
                        ),
                        iconSize: 44,
                        tooltip: controller.status == PlayerStatus.ended
                            ? 'Replay'
                            : playing
                            ? 'Pause'
                            : 'Play',
                        onPressed: controller.canControl
                            ? controller.togglePlayback
                            : null,
                        icon: loading
                            ? const SizedBox.square(
                                dimension: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(playing ? Icons.pause : Icons.play_arrow),
                      ),
                    ),
                    SizedBox(height: tokens.gapXl),
                    if (controller.error != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: EdgeInsets.all(tokens.gapLg),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(
                              tokens.radiusCard,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.error!,
                                style: TextStyle(
                                  color: scheme.onErrorContainer,
                                ),
                              ),
                              if (file != null &&
                                  controller.status == PlayerStatus.error)
                                TextButton(
                                  onPressed: controller.busy
                                      ? null
                                      : controller.retry,
                                  child: const Text('Try again'),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: tokens.gapLg),
                    ],
                    FilledButton.icon(
                      key: const Key('open-file'),
                      onPressed: controller.busy ? null : controller.openFile,
                      icon: controller.picking
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.audio_file_outlined),
                      label: Text(
                        controller.picking
                            ? 'Choosing file…'
                            : 'Open FLAC file',
                      ),
                    ),
                    SizedBox(height: tokens.gapMd),
                    Text(
                      'Playback pauses when you leave the app in this preview.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
