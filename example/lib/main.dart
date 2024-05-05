// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:basic/home.dart';
import 'package:basic/posts_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:fquery/fquery.dart';

import 'todos_page.dart';

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
        },
      ),
    ),
  );
}
