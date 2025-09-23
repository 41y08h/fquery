import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';

/// A Builder widget which uses [useQueries] internally
class QueriesBuilder<TData, TError extends Exception> extends HookWidget {
  /// The builder function which recevies the [UseQueryResult] along with the [BuildContext]
  final Widget Function(BuildContext, List<UseQueryResult<TData, TError>>)
      builder;

  /// The list of options for each query.
  final List<UseQueriesOptions<TData, TError>> options;

  /// Creates a new [QueriesBuilder] instance.
  const QueriesBuilder(
    this.options, {
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final queries = useQueries<TData, TError>(
      options,
    );

    return Builder(builder: (context) {
      return builder(context, queries);
    });
  }
}
