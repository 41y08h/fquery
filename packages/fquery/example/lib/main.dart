// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:basic/pages/home.dart';
import 'package:basic/pages/infinity_page.dart';
import 'package:basic/pages/posts_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery_core/models/default_query_options.dart';
import 'package:fquery_core/query_cache.dart';

import 'pages/todos_page.dart';

final queryCache = QueryCache(
    defaultQueryOptions: DefaultQueryOptions(
  refetchInterval: Duration(seconds: 2),
));

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CacheProvider(
      cache: queryCache,
      child: CupertinoApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        theme: const CupertinoThemeData(
          brightness: Brightness.light,
        ),
        routes: {
          '/': (context) => const Home(),
          '/todos': (context) => const TodosPage(),
          '/posts': (context) => const PostsPage(),
          '/infinity': (context) => const InfinityPage(),
        },
      ),
    );
  }
}
