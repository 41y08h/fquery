import 'package:basic/items_query_config.dart';
import 'package:basic/models/infinity.dart';
import 'package:flutter/cupertino.dart';
import 'package:fquery/fquery.dart';

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
    final itemsQuery = InfiniteQueryInstance<PageResult, Exception, int>(
      context,
      itemsQueryConfig,
    ).result;

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
  }

  @override
  Widget build(BuildContext context) {
    final itemsQuery = InfiniteQueryInstance<PageResult, Exception, int>(
      context,
      itemsQueryConfig,
    ).result;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Infinity"),
        trailing: itemsQuery.isFetching
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: itemsQuery.refetch,
                child: const Icon(CupertinoIcons.refresh),
              ),
      ),
      child: SafeArea(
        child: InfiniteQueryBuilder<PageResult, Exception, int>(
          itemsQueryConfig,
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
