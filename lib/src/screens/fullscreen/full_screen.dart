import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:mostaqem/src/screens/fullscreen/providers/lyrics_notifier.dart';
import 'package:mostaqem/src/screens/home/providers/home_providers.dart';
import 'package:mostaqem/src/screens/navigation/data/album.dart';
import 'package:mostaqem/src/screens/navigation/repository/lyrics_repository.dart';
import 'package:mostaqem/src/screens/navigation/widgets/providers/playing_provider.dart';
import 'package:mostaqem/src/screens/settings/appearance/providers/theme_notifier.dart';
import 'package:mostaqem/src/shared/internet_checker/network_checker.dart';
import 'package:mostaqem/src/shared/widgets/async_widget.dart';
import 'package:mostaqem/src/shared/widgets/tooltip_icon.dart';

class FullScreenWidget extends ConsumerStatefulWidget {
  const FullScreenWidget({required this.player, super.key});
  final Album player;

  @override
  ConsumerState<FullScreenWidget> createState() => _FullScreenWidgetState();
}

class _FullScreenWidgetState extends ConsumerState<FullScreenWidget> {
  late final ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(getConnectionProvider).value;
    final randomImage = ref.watch(fetchRandomImageProvider);
    final isLyricsVisible = ref.watch(lyricsNotifierProvider);
    final lyrics = ref.watch(currentLyricsNotifierProvider);
    final theme = ref.watch(themeProvider);
    return Stack(
      children: [
        if (connection == InternetConnectionStatus.connected)
          AsyncWidget(
            value: randomImage,
            data: (data) {
              return SizedBox.expand(
                child: Image.network(
                  data,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child; // Image loaded
                    } else {
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          )
        else
          SizedBox.expand(
            child: Image.asset(
              'assets/img/kaaba.jpg',
              fit: BoxFit.cover,
            ),
          ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.transparent,
                Colors.black,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.5, 0.3, 1],
            ),
          ),
        ),
        Visibility(
          visible: isLyricsVisible,
          child: Center(
            child: Container(
              height: MediaQuery.sizeOf(context).height,
              width: MediaQuery.sizeOf(context).width,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: AsyncWidget(
                  value: lyrics,
                  data: (data) {
                    if (data == null) {
                      return const Text(
                        'عفوا, لا يوجد كلمات , سوف نضيفها مع الوقت',
                      );
                    }

                    scrollController.animateTo(
                      (data.currentIndex ~/ 4) * 20,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );

                    return SizedBox(
                      width: 400,
                      height: MediaQuery.sizeOf(context).height - 180,
                      child: GridView.builder(
                        controller: scrollController,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 100,
                        ),
                        itemCount: data.lyricsList.length,
                        cacheExtent: 30,
                        itemBuilder: (context, index) {
                          final lyric = data.lyricsList[index];
                          final isCurrent = index == data.currentIndex;

                          return Text(
                            lyric.words,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.amiri(
                              fontWeight: isCurrent ? FontWeight.bold : null,
                              fontSize: 24,
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  : Colors.white.withOpacity(0.5),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                // StreamBuilder(
                //   stream: lyrics,
                //   builder: (context, snapshot) {
                //     if (snapshot.data == null) {
                //       return const Text(
                //         'عفوا, لا يوجد كلمات , سوف نضيفها مع الوقت',
                //       );
                //     }

                //     final lyricsList = snapshot.data!.item2;
                //     final currentIndex = snapshot.data!.item1;
                //     scrollController.animateTo(
                //       (currentIndex ~/ 4) * 20, // Adjusting for rows
                //       duration: const Duration(milliseconds: 300),
                //       curve: Curves.easeInOut,
                //     );

                //     return SizedBox(
                //       width: 400,
                //       height: MediaQuery.sizeOf(context).height - 180,
                //       child: GridView.builder(
                //         controller: scrollController,
                //         gridDelegate:
                //             const SliverGridDelegateWithMaxCrossAxisExtent(
                //           maxCrossAxisExtent: 100,
                //         ),
                //         itemCount: lyricsList.length,
                //         cacheExtent: 30,
                //         itemBuilder: (context, index) {
                //           final lyric = lyricsList[index];
                //           final isCurrent = index == currentIndex;

                //           return Text(
                //             lyric.words,
                //             textAlign: TextAlign.center,
                //             style: GoogleFonts.amiri(
                //               fontWeight: isCurrent ? FontWeight.bold : null,
                //               fontSize: 24,
                //               color: isCurrent
                //                   ? Theme.of(context).colorScheme.primary
                //                   : Colors.white.withOpacity(0.5),
                //             ),
                //           );
                //         },
                //       ),
                //     );
                //   },
                // ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 220, right: 50),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: CachedNetworkImageProvider(
                        widget.player.surah.image ??
                            'https://img.freepik.com/premium-photo/illustration-mosque-with-crescent-moon-stars-simple-shapes-minimalist-flat-design_217051-15556.jpg',
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.player.surah.arabicName,
                      style: const TextStyle(fontSize: 30, color: Colors.white),
                    ),
                    Text(
                      widget.player.reciter.arabicName,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    Visibility(
                      visible: ref.watch(isLocalProvider),
                      child: Text(
                        'تشغيل اوفلاين',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.surface,
              child: ToolTipIconButton(
                message: 'تغير الصورة',
                onPressed: () {
                  ref.invalidate(fetchRandomImageProvider);
                },
                icon: const Icon(Icons.arrow_forward_outlined),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
