import 'package:fquery_core/models/query.dart';

/// Default options for all queries.
class DefaultQueryOptions {
  /// The behavior of the query when the widget is first built and the data is already available.
  final RefetchOnMount refetchOnMount;

  /// The duration until the data becomes stale.
  final Duration staleDuration;

  /// The duration until the data is removed from the cache.
  final Duration cacheDuration;

  /// The interval at which the query will be refetched.
  final Duration? refetchInterval;

  /// The number of retry attempts if the query fails.
  final int retryCount;

  /// The delay between retry attempts if the query fails.
  final Duration retryDelay;

  /// Creates a new [DefaultQueryOptions] instance.
  DefaultQueryOptions({
    this.refetchOnMount = RefetchOnMount.stale,
    this.staleDuration = Duration.zero,
    this.cacheDuration = const Duration(seconds: 5),
    this.refetchInterval,
    this.retryCount = 3,
    this.retryDelay = const Duration(seconds: 1, milliseconds: 500),
  });
}
