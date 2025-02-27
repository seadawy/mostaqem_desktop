// ignore_for_file: strict_raw_type, inference_failure_on_instance_creation

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mostaqem/src/screens/navigation/repository/player_repository.dart';
import 'package:mostaqem/src/screens/navigation/widgets/providers/playing_provider.dart';
import 'package:mostaqem/src/screens/navigation/widgets/squiggly/squiggly_slider.dart';
import 'package:mostaqem/src/screens/settings/appearance/providers/squiggly_notifier.dart';
import 'package:mostaqem/src/shared/widgets/hover_builder.dart';
import 'package:rxdart/rxdart.dart';

class PlayControls extends ConsumerStatefulWidget {
  const PlayControls({
    required this.isFullScreen,
    required this.ref,
    super.key,
  });
  final bool isFullScreen;
  final WidgetRef ref;

  @override
  ConsumerState<PlayControls> createState() => _PlayControlsState();
}

class _PlayControlsState extends ConsumerState<PlayControls> {
  Icon loopIcon(PlaylistMode state, Color color) {
    if (state == PlaylistMode.none) {
      return Icon(
        Icons.repeat,
        size: 16,
        color: color,
      );
    }
    if (state == PlaylistMode.single) {
      return Icon(
        Icons.repeat,
        size: 16,
        color: color,
      );
    }
    return Icon(
      Icons.repeat_one_outlined,
      size: 16,
      color: color,
    );
  }

  StreamSubscription? periodicSubscription;
  final BehaviorSubject<double?> _dragPositionSubject =
      BehaviorSubject.seeded(null);
  @override
  void initState() {
    super.initState();

    periodicSubscription =
        Stream.periodic(const Duration(seconds: 1)).listen((_) {
      _dragPositionSubject.add(
        widget.ref.read(playerNotifierProvider).position.inSeconds.toDouble(),
      );
    });
  }

  @override
  void dispose() {
    periodicSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.ref.watch(playerNotifierProvider);
    final isSquiggly = widget.ref.watch(squigglyNotifierProvider);
    // TODO(mezoPeeta): Refactor playcontrols
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Transform.scale(
        scale: widget.isFullScreen ? 1.3 : 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                  visible: widget.ref
                      .watch(playerNotifierProvider.notifier)
                      .isFirstChapter(),
                  child: Tooltip(
                    message: 'قبل',
                    preferBelow: false,
                    child: IconButton(
                      onPressed: () async {
                        await widget.ref
                            .read(playerNotifierProvider.notifier)
                            .playPrevious();
                      },
                      icon: Icon(
                        Icons.skip_next_outlined,
                        color: widget.isFullScreen
                            ? Colors.white
                            : Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                      ),
                      iconSize: 25,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'تشغيل',
                  preferBelow: false,
                  child: IconButton(
                    onPressed: () async {
                      await widget.ref
                          .read(playerNotifierProvider.notifier)
                          .handlePlayPause();
                    },
                    icon: player.isPlaying
                        ? Icon(
                            Icons.pause_circle_filled_outlined,
                            color: widget.isFullScreen
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                          )
                        : Icon(
                            Icons.play_circle_fill_outlined,
                            color: widget.isFullScreen
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                          ),
                    iconSize: 25,
                  ),
                ),
                Visibility(
                  visible: widget.ref
                          .watch(playerNotifierProvider.notifier)
                          .isLastchapter() &&
                      widget.ref.watch(playerSurahProvider) != null,
                  child: Tooltip(
                    message: 'بعد',
                    preferBelow: false,
                    child: IconButton(
                      onPressed: () async {
                        await widget.ref
                            .read(playerNotifierProvider.notifier)
                            .playNext();
                      },
                      icon: Icon(
                        Icons.skip_previous_outlined,
                        color: widget.isFullScreen
                            ? Colors.white
                            : Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                      ),
                      iconSize: 25,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'اعادة',
                  preferBelow: false,
                  child: IconButton(
                    onPressed: () async {
                      widget.ref.read(playerNotifierProvider.notifier).loop();
                    },
                    icon: loopIcon(
                      player.loop,
                      player.loop == PlaylistMode.none
                          ? widget.isFullScreen
                              ? Colors.white
                              : Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer
                          : Theme.of(context).colorScheme.tertiary,
                    ),
                    iconSize: 16,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.ref
                      .watch(playerNotifierProvider.notifier)
                      .playerTime()
                      .$1,
                  style: TextStyle(
                    color: widget.isFullScreen ? Colors.white : null,
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: widget.isFullScreen
                        ? MediaQuery.sizeOf(context).width / 1.5
                        : MediaQuery.sizeOf(context).width / 2.5,
                    maxHeight: 10,
                  ),
                  child: StreamBuilder(
                    stream: _dragPositionSubject.stream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ??
                          widget.ref
                              .watch(playerNotifierProvider)
                              .position
                              .inSeconds
                              .toDouble();
                      final duration = widget.ref
                          .watch(playerNotifierProvider)
                          .duration
                          .inSeconds
                          .toDouble();

                      return Stack(
                        children: [
                          Visibility(
                            visible: false,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 4,
                                left: 25,
                                right: 25,
                              ),
                              child: LinearProgressIndicator(
                                value: widget.ref
                                    .watch(playerNotifierProvider)
                                    .buffering
                                    .inSeconds
                                    .toDouble(),
                                borderRadius: BorderRadius.circular(12),
                                valueColor: AlwaysStoppedAnimation(
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                ),
                              ),
                            ),
                          ),
                          HoverBuilder(
                            builder: (isHovered) {
                              return SliderTheme(
                                data: SliderThemeData(
                                  thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: isHovered ? 7 : 3,
                                    elevation: 0,
                                  ),
                                ),
                                child: isSquiggly
                                    ? SquigglyPlayerSlider(
                                        position: position,
                                        duration: duration,
                                        widget: widget,
                                        dragPositionSubject:
                                            _dragPositionSubject,
                                      )
                                    : NormalPlayerSlider(
                                        position: position,
                                        duration: duration,
                                        widget: widget,
                                        dragPositionSubject:
                                            _dragPositionSubject,
                                      ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Text(
                  widget.ref
                      .watch(playerNotifierProvider.notifier)
                      .playerTime()
                      .$2,
                  style: TextStyle(
                    color: widget.isFullScreen ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NormalPlayerSlider extends StatelessWidget {
  const NormalPlayerSlider({
    required this.position,
    required this.duration,
    required this.widget,
    required BehaviorSubject<double?> dragPositionSubject,
    super.key,
  }) : _dragPositionSubject = dragPositionSubject;

  final double position;
  final double duration;
  final PlayControls widget;
  final BehaviorSubject<double?> _dragPositionSubject;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: max(0, min(position, duration)),
      max: duration,
      onChangeStart: (_) async {
        final isPlaying = widget.ref.read(playerNotifierProvider).isPlaying;
        if (isPlaying) {
          await widget.ref.read(playerNotifierProvider.notifier).player.pause();
        }
      },
      onChangeEnd: (value) async {
        await widget.ref.read(playerNotifierProvider.notifier).handleSeek(
              Duration(seconds: value.toInt()),
            );
        await widget.ref.read(playerNotifierProvider.notifier).player.play();
      },
      onChanged: _dragPositionSubject.add,
    );
  }
}

class SquigglyPlayerSlider extends StatelessWidget {
  const SquigglyPlayerSlider({
    required this.position,
    required this.duration,
    required this.widget,
    required BehaviorSubject<double?> dragPositionSubject,
    super.key,
  }) : _dragPositionSubject = dragPositionSubject;

  final double position;
  final double duration;
  final PlayControls widget;
  final BehaviorSubject<double?> _dragPositionSubject;

  @override
  Widget build(BuildContext context) {
    return SquigglySlider(
      squiggleAmplitude: 3,
      squiggleWavelength: 5,
      squiggleSpeed: 0.2,
      value: max(0, min(position, duration)),
      max: duration,
      onChangeStart: (_) async {
        final isPlaying = widget.ref.read(playerNotifierProvider).isPlaying;
        if (isPlaying) {
          await widget.ref.read(playerNotifierProvider.notifier).player.pause();
        }
      },
      onChangeEnd: (value) async {
        await widget.ref.read(playerNotifierProvider.notifier).handleSeek(
              Duration(seconds: value.toInt()),
            );
        await widget.ref.read(playerNotifierProvider.notifier).player.play();
      },
      onChanged: _dragPositionSubject.add,
    );
  }
}
