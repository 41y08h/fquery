// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:basic/pages/home.dart';
import 'package:basic/pages/infinity.dart';
import 'package:basic/pages/posts_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:fquery/fquery.dart';

import 'pages/todos_page.dart';

final queryClient = QueryClient(
  defaultQueryOptions: DefaultQueryOptions(),
);

void main() {
  runApp(
    QueryClientProvider(
      queryClient: queryClient,
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
    ),
  );
}
