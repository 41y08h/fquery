import 'package:basic/models/infinity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';

class InfinityPage extends HookWidget {
  const InfinityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final infinityAPI = Infinity.getInstance();
    final items = useInfiniteQuery<PageResult, Error, int>(
      ['infinity'],
      (page) => infinityAPI.get(page),
      initialPageParam: 6,
      getNextPageParam: ((lastPage, allPages, lastPageParam, allPageParam) {
        return lastPage.hasMore ? lastPage.page + 1 : null;
      }),
      getPreviousPageParam:
          (firstPage, allPages, firstPageParam, allPageParam) {
        return firstPage.hasMore ? firstPage.page - 1 : null;
      },
      maxPages: 2,
    );

    useEffect(() {
      scrollController.addListener(() {
        if (scrollController.position.pixels ==
            scrollController.position.maxScrollExtent) {
          items.fetchNextPage();
        }

        if (scrollController.position.pixels ==
            scrollController.position.minScrollExtent) {
          items.fetchPreviousPage();
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            // Subtract 5 pixels to stop fetching the next page automatically
            scrollController.position.maxScrollExtent - 5,
            duration: const Duration(seconds: 2),
            curve: Curves.fastOutSlowIn,
          );
        }
      });
      return null;
    }, []);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Infinity"),
      ),
      child: SafeArea(
        child: Builder(
          builder: (context) {
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
