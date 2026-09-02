import 'package:flutter/services.dart';

class LocalFlacFile {
  const LocalFlacFile({
    required this.leaseId,
    required this.path,
    required this.name,
    required this.title,
    required this.artist,
    required this.duration,
    required this.sampleRate,
    required this.bitDepth,
  });

  final String leaseId;
  final String path;
  final String name;
  final String title;
  final String artist;
  final Duration duration;
  final int sampleRate;
  final int bitDepth;

  factory LocalFlacFile.fromMap(Map<Object?, Object?> data) => LocalFlacFile(
    leaseId: data['leaseId']! as String,
    path: data['path']! as String,
    name: data['name']! as String,
    title: data['title']! as String,
    artist: data['artist']! as String,
    duration: Duration(milliseconds: (data['durationMs']! as num).toInt()),
    sampleRate: (data['sampleRate']! as num).toInt(),
    bitDepth: (data['bitDepth']! as num).toInt(),
  );
}

abstract interface class LocalFlacPicker {
  Future<LocalFlacFile?> pick();
  Future<void> release(LocalFlacFile file);
}

/// Holds the Android SAF descriptor until the audio plugin releases its source.
class AndroidLocalFlacPicker implements LocalFlacPicker {
  static const channel = MethodChannel('org.holosmusic/local_flac');

  @override
  Future<LocalFlacFile?> pick() async {
    final data = await channel.invokeMapMethod<Object?, Object?>('pickFlac');
    return data == null ? null : LocalFlacFile.fromMap(data);
  }

  @override
  Future<void> release(LocalFlacFile file) =>
      channel.invokeMethod<void>('release', {'leaseId': file.leaseId});
}
