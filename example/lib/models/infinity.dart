// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:basic/models/todos.dart';

class PageResult {
  final List<String> content;
  final bool hasMore;
  final int page;
  PageResult({
    required this.content,
    required this.hasMore,
    required this.page,
  });
}

class Infinity {
  // Private static instance variable
  static Infinity? _instance;
  List<String> items = List.generate(200, (index) => "Item ${index + 1}");

  // Private constructor
  Infinity._();

  // Factory method to provide access to the singleton instance
  factory Infinity.getInstance() {
    // If an instance doesn't exist, create one; otherwise, return the existing instance
    _instance ??= Infinity._();
    return _instance!;
  }

  Future<PageResult> get(int page) async {
    print('get');
    const itemsPerPage = 20;
    await MockServer.delay();
    final content =
        items.sublist((page - 1) * itemsPerPage, page * itemsPerPage);
    return PageResult(content: content, hasMore: page < 10, page: page);
  }
}
