// ignore_for_file: inference_failure_on_instance_creation

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mostaqem/src/core/SMTC/smtc_provider.dart';
import 'package:mostaqem/src/core/discord/discord_provider.dart';
import 'package:mostaqem/src/screens/home/providers/home_providers.dart';
import 'package:mostaqem/src/screens/navigation/data/album.dart';
import 'package:mostaqem/src/screens/navigation/data/player.dart';
import 'package:mostaqem/src/screens/navigation/repository/player_cache.dart';
import 'package:mostaqem/src/screens/offline/repository/offline_repository.dart';
import 'package:mostaqem/src/screens/reciters/providers/reciters_repository.dart';
import 'package:mostaqem/src/shared/internet_checker/network_checker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

part 'player_repository.g.dart';

@riverpod
class PlayerNotifier extends _$PlayerNotifier {
  final player = Player();

  @override
  AudioState build() {
    final audioState = AudioState();
    final networkState = ref.watch(getConnectionProvider).value;
    if (networkState == InternetConnectionStatus.disconnected ||
        networkState == null) {
      player.pause();
    } else {
      init();
      final cachedSurah = ref.read(playerCacheProvider());
      if (cachedSurah != null) {
        player.open(Media(cachedSurah.url), play: false);

        return audioState.copyWith(
          album: cachedSurah,
          duration: Duration(seconds: cachedSurah.duration),
        );
      }
    }
    return audioState;
  }

  void init() {
    player.stream.position.listen((position) {
      state = state.copyWith(position: position);
    });

    player.stream.duration.listen((duration) async {
      state = state.copyWith(duration: duration);
      if (state.album?.position != 0) {
        await player.seek(
          Duration(milliseconds: state.album?.position ?? 0),
        );
      }
    });

    player.stream.buffer.listen((buffering) {
      state = state.copyWith(buffering: buffering);
    });

    player.stream.completed.listen((completed) async {
      if (completed) {
        if (state.album!.surah.id < 114) {
          await playNext();
        } else {
          await play(surahID: 1);
        }
      }
    });
    player.stream.playing.listen((playing) async {
      state = state.copyWith(isPlaying: playing);
      if (Platform.isWindows) {
        windowThumbnailBar();
        ref.read(
          initSMTCProvider(
            duration: state.duration.inMilliseconds,
            position: state.position.inMilliseconds,
            image: state.album?.surah.image ??
                'https://img.freepik.com/premium-photo/illustration-mosque-with-crescent-moon-stars-simple-shapes-minimalist-flat-design_217051-15556.jpg',
            surah: state.album!.surah.arabicName,
            reciter: state.album!.reciter.arabicName,
          ),
        );
      }

      ref.read(
        updateRPCDiscordProvider(
          surahName: state.album?.surah.simpleName ?? '',
          reciter: state.album?.reciter.englishName ?? '',
          position: state.position.inMilliseconds,
          duration: state.duration.inMilliseconds,
        ),
      );
    });
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final hoursStr = hours > 0 ? '$hours:' : '';
    final minutesStr = twoDigits(minutes);
    final secondsStr = twoDigits(seconds);

    return '$hoursStr$minutesStr:$secondsStr';
  }

  bool isFirstChapter() {
    if (isLocalAudio()) {
      final currentURL = state.album?.url;
      final audios = ref.read(getLocalAudioProvider).value;
      if (audios == null) return false;

      final currentIndex = audios.indexWhere((e) => e.url == currentURL);

      return currentIndex > 0;
    }

    final currentSurah = state.album?.surah;
    if (currentSurah == null) {
      return false;
    }
    return currentSurah.id > 1;
  }

  bool isLastchapter() {
    if (isLocalAudio()) {
      final currentURL = state.album?.url;
      final audios = ref.read(getLocalAudioProvider).value;
      if (audios == null) return false;

      final currentIndex = audios.indexWhere((e) => e.url == currentURL);
      final lastIndex = audios.length - 1;
      debugPrint('CurrentIndex: $currentIndex, Lastindex:$lastIndex');
      return currentIndex < lastIndex;
    }
    final currentSurah = state.album?.surah;

    if (currentSurah == null) {
      return false;
    }
    return currentSurah.id < 114;
  }

  Future<void> handlePlayPause() async {
    if (state.isPlaying) {
      await player.pause();

      state = state.copyWith(isPlaying: false);
    } else {
      await player.play();

      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> localPlay({required Album album}) async {
    await player.open(Media(album.url));
    state = state.copyWith(album: album);
  }

  Future<void> localPlayNext() async {
    final currentURL = state.album?.url;
    final audios = await ref.read(getLocalAudioProvider.future);
    final currentIndex = audios.indexWhere((e) => e.url == currentURL);
    debugPrint('Next: ${audios[currentIndex + 1]}');
    state = state.copyWith(album: audios[currentIndex + 1]);
    await player.open(Media(audios[currentIndex + 1].url));
  }

  Future<void> playNext() async {
    if (isLocalAudio()) {
      await localPlayNext();
      return;
    }
    final currentSurah = state.album?.surah;

    final nextID = currentSurah!.id + 1;

    final recitationID = state.album?.recitationID;

    final chosenReciter = ref.read(userReciterProvider);
    debugPrint('Chosen Reciter: $chosenReciter');

    final mixID = 'audio_${chosenReciter.id + nextID}';

    final cachedAlbum = ref.read(playerCacheProvider(key: mixID));

    if (cachedAlbum == null || cachedAlbum.reciter != chosenReciter) {
      final nextAlbum = await fetchAlbum(
        surahID: nextID,
        reciterID: chosenReciter.id,
        recitationID: recitationID,
      );

      state = state.copyWith(album: nextAlbum);
      await player.open(Media(nextAlbum.url));

      await ref
          .read(playerCacheProvider(key: mixID).notifier)
          .setAlbum(nextAlbum, key: mixID);

      await DefaultCacheManager().downloadFile(nextAlbum.url);

      return;
    }
    final cachedFile =
        await DefaultCacheManager().getFileFromCache(cachedAlbum.url);

    if (cachedFile == null) {
      final nextAlbum = await fetchAlbum(
        surahID: nextID,
        reciterID: chosenReciter.id,
        recitationID: recitationID,
      );

      state = state.copyWith(album: nextAlbum);
      await player.open(Media(nextAlbum.url));

      await ref
          .read(playerCacheProvider(key: mixID).notifier)
          .setAlbum(nextAlbum, key: mixID);

      await DefaultCacheManager().downloadFile(nextAlbum.url);

      return;
    }

    final nextAlbum = Album(
      surah: cachedAlbum.surah,
      reciter: chosenReciter,
      recitationID: recitationID ?? 0,
      url: cachedFile.file.path,
    );

    state = state.copyWith(album: nextAlbum);

    await player.open(Media(nextAlbum.url));

    await ref
        .read(playerCacheProvider(key: mixID).notifier)
        .setAlbum(nextAlbum, key: mixID);
  }

  bool isLocalAudio() {
    return state.album?.isLocal ?? false;
  }

  Future<void> playPrevious() async {
    if (isLocalAudio()) {
      final currentUrl = state.album?.url;

      await player.previous();
      final audios = await ref.read(getLocalAudioProvider.future);
      final currentIndex = audios.indexWhere((e) => e.url == currentUrl);
      state = state.copyWith(album: audios[currentIndex - 1]);
      await player.open(Media(audios[currentIndex - 1].url));
      return;
    }
    final surahID = state.album!.surah.id;
    final recitationID = state.album?.recitationID;
    final previousID = surahID - 1;

    final mixID = 'audio_${recitationID ?? 0 + surahID}';
    final cachedAlbum = ref.read(playerCacheProvider(key: mixID));

    final chosenReciter = ref.read(userReciterProvider);

    if (cachedAlbum == null || cachedAlbum.reciter != chosenReciter) {
      final previousAlbum =
          await fetchAlbum(surahID: previousID, reciterID: chosenReciter.id);

      await player.open(Media(previousAlbum.url));
      state = state.copyWith(album: previousAlbum);
      await ref
          .read(playerCacheProvider(key: mixID).notifier)
          .setAlbum(previousAlbum, key: mixID);
      await DefaultCacheManager().downloadFile(previousAlbum.url);
      return;
    }
    final cachedFile =
        await DefaultCacheManager().getFileFromCache(cachedAlbum.url);
    if (cachedFile != null) {
      final previousAlbum = Album(
        surah: cachedAlbum.surah,
        reciter: cachedAlbum.reciter,
        url: cachedFile.file.path,
        recitationID: cachedAlbum.recitationID,
      );
      state = state.copyWith(album: previousAlbum);
      await player.open(Media(previousAlbum.url));
    }
    final previousAlbum =
        await fetchAlbum(surahID: previousID, reciterID: chosenReciter.id);

    state = state.copyWith(album: previousAlbum);
    await player.open(Media(previousAlbum.url));
    await DefaultCacheManager().downloadFile(previousAlbum.url);
  }

  Future<Album> fetchAlbum({
    required int surahID,
    required int reciterID,
    int? recitationID,
  }) async {
    final surah = await ref.read(fetchChapterByIdProvider(id: surahID).future);
    final reciter = await ref.read(fetchReciterProvider(id: reciterID).future);

    final audio = await ref.read(
      fetchAudioForChapterProvider(
        chapterNumber: surahID,
        reciterID: reciterID,
        recitationID: recitationID,
      ).future,
    );
    final album = Album(
      surah: surah,
      reciter: reciter,
      url: audio.url,
      recitationID: audio.recitationID,
    );
    final mixID = 'audio_${recitationID ?? 0 + surahID}';

    await ref
        .read(playerCacheProvider(key: mixID).notifier)
        .setAlbum(album, key: mixID);

    return album;
  }

  Future<void> play({
    required int surahID,
    int? recitationID,
  }) async {
    final cacheManager = DefaultCacheManager();
    final chosenReciterID = ref.read(userReciterProvider).id;

    final mixID = 'audio_${recitationID ?? 0 + surahID}';

    final cachedAlbum = ref.read(playerCacheProvider(key: mixID));

    debugPrint('surahID: $surahID');

    if (cachedAlbum == null || cachedAlbum.reciter.id != chosenReciterID) {
      final album = await fetchAlbum(
        surahID: surahID,
        reciterID: chosenReciterID,
        recitationID: recitationID,
      );
      state = state.copyWith(album: album);
      await player.open(
        Media(
          album.url,
        ),
      );
      await DefaultCacheManager().downloadFile(album.url);

      return;
    }

    final cachedFile = await cacheManager.getFileFromCache(cachedAlbum.url);
    if (cachedFile == null) {
      final album = await fetchAlbum(
        surahID: surahID,
        reciterID: chosenReciterID,
        recitationID: recitationID,
      );
      state = state.copyWith(album: album);
      await player.open(
        Media(
          album.url,
        ),
      );
      await DefaultCacheManager().downloadFile(album.url);

      return;
    }

    final album = Album(
      surah: cachedAlbum.surah,
      reciter: cachedAlbum.reciter,
      url: cachedAlbum.url,
      recitationID: cachedAlbum.recitationID,
    );
    await player.open(
      Media(
        album.url,
      ),
    );
    state = state.copyWith(album: album);

    await cacheManager.downloadFile(cachedAlbum.url);
  }

  void loop() {
    final mode = player.state.playlistMode;

    if (mode == PlaylistMode.none) {
      player.setPlaylistMode(PlaylistMode.single);
      state = state.copyWith(loop: PlaylistMode.single);

      return;
    }
    if (mode == PlaylistMode.single) {
      player.setPlaylistMode(PlaylistMode.loop);
      state = state.copyWith(loop: PlaylistMode.loop);

      return;
    }
    if (mode == PlaylistMode.loop) {
      player.setPlaylistMode(PlaylistMode.none);
      state = state.copyWith(loop: PlaylistMode.none);

      return;
    }
  }

  void changePosition(Duration position) {
    state = state.copyWith(position: position);
  }

  Future<void> handleSeek(Duration value) async {
    await player.seek(value);
    state = state.copyWith(position: value);
  }

  Future<void> handleVolume(double value) async {
    await player.setVolume(value * 100);

    state = state.copyWith(volume: value);
  }

  void windowThumbnailBar() {
    WindowsTaskbar.setFlashTaskbarAppIcon();

    WindowsTaskbar.setThumbnailToolbar([
      ThumbnailToolbarButton(
        ThumbnailToolbarAssetIcon('assets/img/skip_previous.ico'),
        'بعد',
        () async {
          await playNext();
        },
      ),
      if (state.isPlaying)
        ThumbnailToolbarButton(
          ThumbnailToolbarAssetIcon('assets/img/pause.ico'),
          'ايقاف ',
          () {
            player.pause();
            state = state.copyWith(isPlaying: false);
          },
        )
      else
        ThumbnailToolbarButton(
          ThumbnailToolbarAssetIcon('assets/img/play.ico'),
          'تشغيل',
          () {
            player.play();
            state = state.copyWith(isPlaying: true);
          },
        ),
      ThumbnailToolbarButton(
        ThumbnailToolbarAssetIcon('assets/img/skip_next.ico'),
        'قبل',
        () async {
          await playPrevious();
        },
      ),
    ]);
  }

  ({String currentTime, String durationTime}) playerTime() {
    final currentTime = formatDuration(state.position);
    final durationTime = formatDuration(state.duration);
    return (currentTime: currentTime, durationTime: durationTime);
  }
}
