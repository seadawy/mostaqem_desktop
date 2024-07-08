import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import '../../../shared/discord/discord_provider.dart';
import '../../home/providers/home_providers.dart';
import '../../home/widgets/surah_widget.dart';
import '../data/player.dart';
import '../widgets/player_widget.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

final playerNotifierProvider =
    StateNotifierProvider.autoDispose<PlayerNotifier, AudioState>(
        PlayerNotifier.new);

class PlayerNotifier extends StateNotifier<AudioState> {
  final Ref ref;
  PlayerNotifier(this.ref) : super(AudioState()) {
    init();
  }
  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  final player = Player();

  void init() async {
    final surah = ref.read(playerSurahProvider);
    player.open(Media(surah.url));
    player.stream.position.listen((position) {
      if (!mounted) return;

      state = state.copyWith(position: position);
    });
    player.stream.duration.listen((duration) {
      if (!mounted) return;

      state = state.copyWith(duration: duration);
    });
    player.stream.completed.listen((completed) async {
      if (completed) {
        final surahID = ref.read(surahIDProvider) + 1;

        final reciter = ref.read(reciterProvider);
        if (surahID < 114) {
          await ref
              .read(seekIDProvider(surahID: surahID, reciter: reciter).future);
        } else {
          await ref.read(seekIDProvider(surahID: 1, reciter: reciter).future);
        }
      }
    });
    player.stream.playing.listen((playing) {
      if (!mounted) return;

      if (playing) {
        state = state.copyWith(isPlaying: true);
      } else {
        state = state.copyWith(isPlaying: false);
      }
      if (Platform.isWindows) {
        if (!mounted) return;

        windowThumbnailBar();
      }
      ref.watch(updateRPCDiscordProvider(
        surahName: surah.english,
      ));
    });

    ref.listen(playerSurahProvider, (_, n) {
      if (!mounted) return;
      player.playOrPause();
      player.open(Media(n.url));
    });
  }

  String formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    String hoursStr = hours > 0 ? '$hours:' : '';
    String minutesStr = twoDigits(minutes);
    String secondsStr = twoDigits(seconds);

    return '$hoursStr$minutesStr:$secondsStr';
  }

  bool isFirstChapter() => ref.watch(surahIDProvider) > 1;

  bool isLastchapter() => ref.watch(surahIDProvider) < 114;

  void handlePlayPause() {
    if (state.isPlaying) {
      player.pause();
      if (!mounted) return;

      state = state.copyWith(isPlaying: false);
    } else {
      player.play();
      if (!mounted) return;

      state = state.copyWith(isPlaying: true);
    }
  }

  void loop() {
    PlaylistMode mode = player.state.playlistMode;
    if (!mounted) return;
    if (mode == PlaylistMode.none) {
      player.setPlaylistMode(PlaylistMode.single);
      state = state.copyWith(loop: LoopMode.single);

      return;
    }
    if (mode == PlaylistMode.single) {
      player.setPlaylistMode(PlaylistMode.loop);
      state = state.copyWith(loop: LoopMode.repeat);

      return;
    }
    if (mode == PlaylistMode.loop) {
      player.setPlaylistMode(PlaylistMode.none);
      state = state.copyWith(loop: LoopMode.none);

      return;
    }
  }

  Future<void> handleSeek(double value) async {
    await player.seek(
      Duration(seconds: value.toInt()),
    );
  }

  Future<void> handleVolume(double value) async {
    await player.setVolume(value * 100);
    if (!mounted) return;

    state = state.copyWith(volume: value);
  }

  windowThumbnailBar() {
    if (!mounted) return;

    WindowsTaskbar.setFlashTaskbarAppIcon();

    WindowsTaskbar.setThumbnailToolbar([
      ThumbnailToolbarButton(
        ThumbnailToolbarAssetIcon('assets/img/skip_previous.ico'),
        "بعد",
        () async {
          final surahID = ref.read(surahIDProvider) + 1;
          final reciter = ref.read(reciterProvider);
          await ref
              .read(seekIDProvider(surahID: surahID, reciter: reciter).future);
        },
      ),
      state.isPlaying
          ? ThumbnailToolbarButton(
              ThumbnailToolbarAssetIcon('assets/img/pause.ico'),
              "ايقاف ",
              () {
                if (!mounted) return;
                player.pause();
                state = state.copyWith(isPlaying: false);
              },
            )
          : ThumbnailToolbarButton(
              ThumbnailToolbarAssetIcon('assets/img/play.ico'),
              "تشغيل",
              () {
                if (!mounted) return;

                player.play();
                state = state.copyWith(isPlaying: true);
              },
            ),
      ThumbnailToolbarButton(
        ThumbnailToolbarAssetIcon('assets/img/skip_next.ico'),
        "قبل",
        () async {
          final surahID = ref.read(surahIDProvider) - 1;
          final reciter = ref.read(reciterProvider);
          await ref
              .read(seekIDProvider(surahID: surahID, reciter: reciter).future);
        },
      ),
    ]);
  }

  (String, String) playerTime() {
    String currentTime = formatDuration(state.position);
    String durationTime = formatDuration(state.duration);
    return (currentTime, durationTime);
  }
}
