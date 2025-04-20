// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

// TODO: Add `public_member_api_docs` to `rules` in `linter` of analysis_options.yaml:

typedef RawQueryKey = List<Object>;

/// A serializable, deeply comparable query key.
///
/// Internally uses `jsonEncode` for equality and hashCode,
/// making it perfect for use as a cache key or map key.
class QueryKey {
  /// The original, user-defined query key.
  final RawQueryKey raw;

  /// Creates a query key from a list of values.
  QueryKey(RawQueryKey key) : raw = key;

  /// The stringified version of the key, used for hashing and equality.
  late final String _serialized = jsonEncode(raw);

  /// Returns the serialized representation.
  String get serialized => _serialized;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryKey && _serialized == other._serialized;

  @override
  int get hashCode => _serialized.hashCode;

  @override
  String toString() => 'QueryKey($serialized)';
}
