import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mostaqem/src/screens/fullscreen/widgets/full_screen_player_controls.dart';
import 'package:mostaqem/src/screens/navigation/data/album.dart';
import 'package:mostaqem/src/screens/navigation/repository/fullscreen_notifier.dart';
import 'package:mostaqem/src/screens/navigation/repository/player_cache.dart';
import 'package:mostaqem/src/screens/navigation/repository/player_repository.dart';
import 'package:mostaqem/src/screens/navigation/widgets/player/normal_player.dart';
import 'package:mostaqem/src/screens/navigation/widgets/providers/playing_provider.dart';
import 'package:window_manager/window_manager.dart';

final isCollapsedProvider = StateProvider<bool>((ref) => false);

class PlayerWidget extends ConsumerStatefulWidget {
  const PlayerWidget({
    super.key,
  });

  @override
  ConsumerState<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends ConsumerState<PlayerWidget>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);

    super.dispose();
  }

  @override
  void onWindowClose() {
    final player = ref.watch(playerSurahProvider);
    if (player == null) return;

    final position = ref.watch(playerNotifierProvider).position;
    ref.read(playerCacheProvider.notifier).setAlbum(
          Album(
            surah: player.surah,
            reciter: player.reciter,
            url: player.url,
            position: position.inMilliseconds,
            recitationID: player.recitationID,
          ),
        );
    super.onWindowClose();
  }

  @override
  Widget build(BuildContext context) {
    final isFullScreen = ref.watch(isFullScreenProvider);
    return Stack(
      children: [
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            color: isFullScreen
                ? Colors.transparent
                : Theme.of(context).colorScheme.secondaryContainer,
          ),
          child: isFullScreen
              ? FullScreenPlayControls(
                  ref: ref,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return constraints.minWidth < 1285
                        ? FittedBox(
                            child: NormalPlayer(
                              isFullScreen: isFullScreen,
                              ref: ref,
                            ),
                          )
                        : NormalPlayer(
                            isFullScreen: isFullScreen,
                            ref: ref,
                          );
                  },
                ),
        ),
        Visibility(
          visible: ref.watch(playerSurahProvider) == null,
          child: MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
