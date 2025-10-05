import 'package:basic/items_query_options.dart';
import 'package:basic/models/infinity.dart';
import 'package:flutter/cupertino.dart';
import 'package:fquery/instances/infinite_query_instance.dart';
import 'package:fquery/widgets/infinite_query_builder.dart';
import 'package:fquery_core/fquery_core.dart';

class InfinityPage extends StatefulWidget {
  const InfinityPage({super.key});

  @override
  State<InfinityPage> createState() => _InfinityPageState();
}

class _InfinityPageState extends State<InfinityPage> {
  final ScrollController scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    scrollController.removeListener(onScroll);
    scrollController.addListener(onScroll);

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
  }

  void onScroll() {
    final itemsQuery = InfiniteQueryInstance.of(
      context,
      itemsQueryOptions,
    );
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      itemsQuery.fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InfiniteQueryBuilder(
      InfiniteQueryOptions<PageResult, Exception, int>(
        queryKey: QueryKey([
          'infinity',
          {'type': 'scroll'}
        ]),
        queryFn: (page) {
          final infinityAPI = Infinity.getInstance();
          return infinityAPI.get(page);
        },
        initialPageParam: 1,
        getNextPageParam: (lastPage, allPages, lastPageParam, allPageParam) {
          return lastPage.hasMore ? lastPage.page + 1 : null;
        },
        refetchOnMount: RefetchOnMount.never,
      ),
      builder: (context, items) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text("Infinity"),
            trailing: items.isFetching
                ? const CupertinoActivityIndicator()
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: items.refetch,
                    child: const Icon(CupertinoIcons.refresh),
                  ),
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
                            return CupertinoListTile(
                                title: Text(contents[index]));
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
      },
    );
  }
}
