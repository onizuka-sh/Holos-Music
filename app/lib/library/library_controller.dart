import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'local_library.dart';

class LibraryController extends ChangeNotifier {
  LibraryController(this.service) {
    _progressSubscription = service.progress.listen(
      (value) {
        if (_disposed || !scanning) return;
        progress = value;
        _publish();
      },
      onError: (Object _) {
        // Method results remain authoritative if progress streaming is unavailable.
      },
    );
  }

  final LocalLibraryService service;
  late final StreamSubscription<ScanProgress> _progressSubscription;
  LibrarySnapshot snapshot = const LibrarySnapshot();
  ScanProgress progress = const ScanProgress();
  bool loading = false;
  bool selecting = false;
  bool scanning = false;
  bool cancelRequested = false;
  bool _disposed = false;
  String? message;
  bool get busy => loading || selecting || scanning;

  void _publish() {
    if (!_disposed) notifyListeners();
  }

  void _failure(Object failure) {
    debugPrint('Holos library failure: ${failure.runtimeType}');
    message = switch (failure) {
      PlatformException(code: 'scan_cancelled') =>
        'Scan cancelled. Your previous library was kept.',
      PlatformException(code: 'access_denied') =>
        'Folder access is unavailable. Select the folder again.',
      PlatformException(code: 'picker_unavailable') =>
        'No folder picker is available on this device.',
      _ =>
        'Could not update the library. Your existing music files are unchanged. Try again.',
    };
  }

  Future<void> load() async {
    if (busy || _disposed) return;
    loading = true;
    message = null;
    _publish();
    try {
      final loaded = await service.load();
      if (!_disposed) snapshot = loaded;
    } catch (failure) {
      if (!_disposed) _failure(failure);
    } finally {
      loading = false;
      _publish();
    }
  }

  Future<void> selectFolder() async {
    if (busy || _disposed) return;
    selecting = true;
    message = null;
    _publish();
    bool shouldScan = false;
    try {
      final selected = await service.selectFolder();
      if (!_disposed && selected != null) {
        snapshot = selected;
        shouldScan = true;
      }
    } catch (failure) {
      if (!_disposed) _failure(failure);
    } finally {
      selecting = false;
      _publish();
    }
    if (shouldScan && !_disposed) await rescan();
  }

  Future<void> rescan() async {
    if (busy || _disposed || snapshot.folders.isEmpty) return;
    scanning = true;
    cancelRequested = false;
    message = null;
    progress = const ScanProgress();
    _publish();
    try {
      final scanned = await service.scan();
      if (!_disposed) {
        snapshot = scanned;
        final unavailable = scanned.folders
            .where((folder) => !folder.available)
            .length;
        message = unavailable > 0
            ? 'Some folders are unavailable. Their saved tracks were kept; reselect the folders to restore access.'
            : scanned.skipped > 0
            ? 'Scan complete. ${scanned.skipped} unreadable or invalid FLAC files were skipped.'
            : 'Scan complete. ${scanned.tracks.length} tracks in your library.';
      }
    } catch (failure) {
      if (!_disposed) _failure(failure);
    } finally {
      scanning = false;
      cancelRequested = false;
      _publish();
    }
  }

  Future<void> cancelScan() async {
    if (!scanning || cancelRequested || _disposed) return;
    cancelRequested = true;
    _publish();
    try {
      await service.cancel();
    } catch (failure) {
      if (!_disposed) {
        cancelRequested = false;
        _failure(failure);
        _publish();
      }
    }
  }

  Future<void> forgetFolder(String uri) async {
    if (busy || _disposed) return;
    selecting = true;
    message = null;
    _publish();
    bool shouldScan = false;
    try {
      final remaining = await service.forgetFolder(uri);
      if (!_disposed) {
        snapshot = remaining;
        shouldScan = remaining.folders.isNotEmpty;
      }
    } catch (failure) {
      if (!_disposed) _failure(failure);
    } finally {
      selecting = false;
      _publish();
    }
    if (shouldScan && !_disposed) await rescan();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_progressSubscription.cancel());
    if (scanning) unawaited(service.cancel().catchError((Object _) {}));
    super.dispose();
  }
}
