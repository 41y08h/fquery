import 'package:flutter/cupertino.dart';
import 'package:fquery/fquery/fquery.dart';

class QueryBuilder extends StatelessWidget {
  final QueryState query;
  final Widget Function() loading;
  final Widget Function(dynamic error) error;
  final Widget Function(dynamic data) data;

  const QueryBuilder({
    Key? key,
    required this.query,
    required this.loading,
    required this.error,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (query.isLoading) return loading();
        if (query.error != null) return error(query.error);
        return data(query.data);
      },
    );
  }
}
