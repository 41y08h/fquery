/// Core query, cache, observer, and mutation primitives for fquery.
///
/// This package contains the framework-agnostic state management layer used by
/// fquery integrations. It exposes query keys, query results, cache operations,
/// observers, mutation state, and mutation observers without depending on any UI
/// toolkit.
library;

export 'src/observer.dart';
export 'src/query.dart' hide BaseQueryOptions, DispatchAction;
export 'src/query_cache.dart';
export 'src/queries_observer.dart';
export 'src/mutation.dart';
export 'src/mutation_observer.dart';
