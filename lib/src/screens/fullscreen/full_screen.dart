import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:mostaqem/src/screens/home/providers/home_providers.dart';
import 'package:mostaqem/src/screens/navigation/data/album.dart';
import 'package:mostaqem/src/screens/navigation/repository/player_repository.dart';
import 'package:mostaqem/src/shared/internet_checker/network_checker.dart';
import 'package:mostaqem/src/shared/widgets/async_widget.dart';
import 'package:mostaqem/src/shared/widgets/tooltip_icon.dart';

class FullScreenWidget extends StatelessWidget {
  const FullScreenWidget({required this.player, required this.ref, super.key});
  final Album player;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(getConnectionProvider).value;
    final randomImage = ref.watch(fetchRandomImageProvider);
    final currentPlayer = ref.watch(playerNotifierProvider.notifier);
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
        // Center(
        //   child: StreamBuilder(
        //     stream: currentPlayer.syncLyrics(),
        //     builder: (context, snapshot) {
        //       if (snapshot.data == null) {
        //         return const SizedBox.shrink();
        //       }
        //       return Text(
        //         snapshot.data!,
        //         style: GoogleFonts.amiriQuran(fontSize: 25),
        //       );
        //     },
        //   ),
        // ),
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
                        player.surah.image ??
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
                      player.surah.arabicName,
                      style: const TextStyle(fontSize: 30, color: Colors.white),
                    ),
                    Text(
                      player.reciter.arabicName,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.5),
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
              backgroundColor: Theme.of(context).colorScheme.surface,
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
