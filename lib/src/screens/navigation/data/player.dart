import 'package:media_kit/media_kit.dart';
import 'package:mostaqem/src/screens/navigation/data/album.dart';

class AudioState {
  AudioState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.volume = 1.0,
    this.buffering = Duration.zero,
    this.loop = PlaylistMode.none,
    this.duration = Duration.zero,
    this.album,
    this.nextAlbum,
    this.queue = const [],
    this.queueIndex,
  });
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double volume;
  final PlaylistMode loop;
  final Duration buffering;
  final Album? album;
  final int? queueIndex;
  final List<Album> queue;
  final Album? nextAlbum;

  AudioState copyWith({
    bool? isPlaying,
    Duration? position,
    List<Album>? queue,
    PlaylistMode? loop,
    Album? nextAlbum,
    Duration? buffering,
    Duration? duration,
    Album? album,
    double? volume,
    int? queueIndex,
  }) {
    return AudioState(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      album: album ?? this.album,
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      nextAlbum: nextAlbum ?? this.nextAlbum,
      buffering: buffering ?? this.buffering,
      loop: loop ?? this.loop,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
