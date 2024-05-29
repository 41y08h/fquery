import 'package:basic/models/infinity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';

class InfinityPage extends HookWidget {
  const InfinityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final infinityAPI = Infinity.getInstance();
    final items = useInfiniteQuery<PageResult, Error, int>(
      ['infinity'],
      (page) => infinityAPI.get(page),
      initialPageParam: 1,
      getNextPageParam: ((lastPage) {
        return lastPage.page + 1;
      }),
    );

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Infinity"),
      ),
      child: SafeArea(
          child: Column(
        children: [
          Text(items.data?.pages.length.toString() ?? "loading"),
          CupertinoButton(
              child: Text("fetch more"),
              onPressed: () {
                items.fetchNextPage();
              }),
          items.isFetchingNextPage ? CupertinoActivityIndicator() : SizedBox()
        ],
      )),
    );
  }
}
