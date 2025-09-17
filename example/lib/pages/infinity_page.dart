import 'package:basic/models/infinity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'dart:math';

class InfinityPage extends HookWidget {
  const InfinityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final infinityAPI = Infinity.getInstance();
    final itemsQuery = useInfiniteQuery<PageResult, Exception, int>(
      [
        'infinity',
        {
          'type': 'scroll',
        },
      ],
      (page) {
        return infinityAPI.get(page);
      },
      initialPageParam: 1,
      getNextPageParam: ((lastPage, allPages, lastPageParam, allPageParam) {
        return lastPage.hasMore ? lastPage.page + 1 : null;
      }),
    );

    useEffect(() {
      scrollController.addListener(() {
        if (scrollController.position.pixels ==
            scrollController.position.maxScrollExtent) {
          itemsQuery.fetchNextPage();
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            // Subtract 1 pixels to stop fetching the next page automatically
            scrollController.position.maxScrollExtent - 1,
            duration: const Duration(seconds: 2),
            curve: Curves.fastOutSlowIn,
          );
        }
      });
      return null;
    }, []);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Infinity"),
        trailing: itemsQuery.isFetching
            ? CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: itemsQuery.refetch,
                child: const Icon(CupertinoIcons.refresh),
              ),
      ),
      child: SafeArea(
        child: InfiniteQueryBuilder<PageResult, Exception, int>(
          const [
            'infinity',
            {
              'type': 'scroll',
            },
          ],
          (page) {
            return infinityAPI.get(page);
          },
          initialPageParam: 1,
          getNextPageParam: ((lastPage, allPages, lastPageParam, allPageParam) {
            return lastPage.hasMore ? lastPage.page + 1 : null;
          }),
          builder: (context, items) {
            if (items.isLoading) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (items.isError) return Text(items.error.toString());
            final contents = items.data?.pages
                    .map((page) => page.content)
                    .expand((element) => element)
                    .toList() ??
                [];

            return Column(
              children: [
                if (items.isFetchingPreviousPage)
                  const SizedBox(
                    height: 100,
                    width: double.maxFinite,
                    child: CupertinoActivityIndicator(),
                  ),
                Expanded(
                  child: ListView.builder(
                      controller: scrollController,
                      itemCount: contents.length,
                      itemBuilder: ((context, index) {
                        return CupertinoListTile(title: Text(contents[index]));
                      })),
                ),
                if (items.isFetchingNextPage)
                  const SizedBox(
                    height: 100,
                    width: double.maxFinite,
                    child: CupertinoActivityIndicator(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
