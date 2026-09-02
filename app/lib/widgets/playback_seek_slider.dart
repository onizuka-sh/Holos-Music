// Adapted from Mornye; Copyright 2026 zarzet. LGPL-3.0-only.
import 'package:flutter/material.dart';
import 'package:holos_music/utils/playback_seek_preview.dart';
import 'package:holos_music/widgets/expressive_seek_track.dart';

/// Previews scrubbing locally and seeks once when the gesture ends.
class PlaybackSeekSlider extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Future<void> Function(Duration) onSeek;
  final PlaybackSeekPreview? preview;
  final bool playing;

  /// Mornye only: a hairline track with no side inset, for the desktop
  /// player capsule.
  final bool hairline;

  /// The track reaches both ends of the slider instead of leaving room for
  /// the thumb, to line up with the artwork above it.
  final bool edgeAligned;

  const PlaybackSeekSlider({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.preview,
    this.playing = false,
    this.hairline = false,
    this.edgeAligned = false,
  });

  @override
  State<PlaybackSeekSlider> createState() => _PlaybackSeekSliderState();
}

class _PlaybackSeekSliderState extends State<PlaybackSeekSlider> {
  double? _previewMs;
  int _gestureGeneration = 0;
  Object? _previewSession;

  void _start(double value) {
    _gestureGeneration++;
    _previewSession = widget.preview?.begin(
      Duration(milliseconds: value.round()),
    );
  }

  void _preview(double value) {
    setState(() => _previewMs = value);
    final session = _previewSession;
    if (session != null) {
      widget.preview?.update(session, Duration(milliseconds: value.round()));
    }
  }

  Future<void> _commit(double value) async {
    final generation = _gestureGeneration;
    final preview = widget.preview;
    final session = _previewSession;
    try {
      await widget.onSeek(Duration(milliseconds: value.round()));
    } finally {
      preview?.end(session);
      if (mounted && generation == _gestureGeneration) {
        setState(() => _previewMs = null);
      }
    }
  }

  @override
  void dispose() {
    final preview = widget.preview;
    final session = _previewSession;
    // Rotation or track replacement can remove this slider during layout.
    // Notify surviving lyrics/time labels after that frame has finished.
    WidgetsBinding.instance.addPostFrameCallback((_) => preview?.end(session));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final durationMs = widget.duration.inMilliseconds;
    final enabled = durationMs > 0;
    final maxMs = enabled ? durationMs.toDouble() : 1.0;
    return ExpressiveSeekTrack(
      playing:
          widget.playing &&
          enabled &&
          widget.position < widget.duration &&
          _previewMs == null,
      child: Slider(
        value: enabled
            ? (_previewMs ?? widget.position.inMilliseconds.toDouble()).clamp(
                0,
                maxMs,
              )
            : 0,
        max: maxMs,
        // Keeps the default 48dp height around the 20dp thumb.
        padding: widget.edgeAligned
            ? const EdgeInsets.symmetric(vertical: 14)
            : null,
        onChangeStart: enabled ? _start : null,
        onChanged: enabled ? _preview : null,
        onChangeEnd: enabled ? _commit : null,
      ),
    );
  }
}
