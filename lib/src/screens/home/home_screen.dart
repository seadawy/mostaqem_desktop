import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:mostaqem/src/core/routes/routes.dart';
import 'package:mostaqem/src/screens/home/providers/home_providers.dart';
import 'package:mostaqem/src/screens/home/widgets/hijri_date_widget.dart';
import 'package:mostaqem/src/screens/home/widgets/surah_widget.dart';
import 'package:mostaqem/src/screens/navigation/widgets/player/player_widget.dart';
import 'package:mostaqem/src/screens/navigation/widgets/providers/playing_provider.dart';
import 'package:mostaqem/src/shared/widgets/async_widget.dart';
import 'package:mostaqem/src/shared/widgets/nework_required_widget.dart';
import 'package:mostaqem/src/shared/widgets/text_hover.dart';

final isTypingProvider = StateProvider<bool>((ref) => false);

final searchQueryProvider = StateProvider<String>((ref) => '');

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});
  final queryController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    HijriCalendar.setLocal('ar');
    final isTyping = ref.watch(isTypingProvider);
    final surahImage = ref.watch(playerSurahProvider)?.surah.image ?? '';

    return NeworkRequiredWidget(
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تاريخ اليوم'),
                  const HijriDateWidget(),
                  const SizedBox(
                    height: 10,
                  ),
                  Align(
                    child: SearchBar(
                      controller: queryController,
                      onChanged: (value) async {
                        ref.read(isTypingProvider.notifier).state =
                            value.isNotEmpty;
                        ref.read(searchQueryProvider.notifier).state = value;
                        ref.refresh(filterSurahByQueryProvider).value;
                      },
                      elevation: const WidgetStatePropertyAll<double>(0),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      trailing: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: isTyping
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    ref
                                        .read(searchQueryProvider.notifier)
                                        .state = '';
                                    queryController.clear();
                                  },
                                )
                              : const Icon(Icons.search),
                        ),
                      ],
                      hintText: 'ماذا تريد ان تسمع؟',
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  const SurahWidget(),
                ],
              ),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Visibility(
            visible: ref.watch(isCollapsedProvider) &&
                ref.watch(playerSurahProvider) != null,
            child: Expanded(
              child: Column(
                children: [
                  Container(
                    height: 450,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: CloseButton(
                              onPressed: () => ref
                                  .read(isCollapsedProvider.notifier)
                                  .update((state) => !state),
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Container(
                            width: double.infinity,
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: CachedNetworkImageProvider(
                                  surahImage,
                                  errorListener: (_) => const Icon(
                                    Icons.broken_image_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Text(
                            ref.watch(
                              playerSurahProvider.select(
                                (value) => value?.surah.arabicName ?? '',
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                          ),
                          TextHover(
                            text: ref.watch(
                              playerSurahProvider.select(
                                (value) => value?.reciter.arabicName ?? '',
                              ),
                            ),
                            onTap: () {
                              ref.read(goRouterProvider).go('/reciters');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const QueueWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QueueWidget extends ConsumerWidget {
  const QueueWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reciter = ref.watch(
      reciterProvider
          .select((value) => value?.arabicName ?? 'عبدالباسط عبدالصمد'),
    );
    final nextSurah = ref.watch(fetchNextSurahProvider);
    return Visibility(
      visible: nextSurah.hasValue,
      child: Expanded(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تسمع التالي',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AsyncWidget(
                        loading: () => const SizedBox.shrink(),
                        value: nextSurah,
                        data: (data) => Text(data?.arabicName ?? ''),
                      ),
                      TextHover(
                        text: reciter,
                        onTap: () {
                          ref.read(goRouterProvider).go('/reciters');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
