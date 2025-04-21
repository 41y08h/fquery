// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';
import 'package:collection/collection.dart';

/// TODO: Add `public_member_api_docs` to `rules` in `linter` of analysis_options.yaml

typedef RawQueryKey = List<Object?>;

/// A serializable, deeply comparable query key.
///
/// Uses `DeepCollectionEquality` for equality and hashing,
/// and `jsonEncode` only for debugging/serialization purposes.
class QueryKey {
  /// The original, user-defined query key.
  final RawQueryKey raw;

  /// Creates a query key from a list of values.
  QueryKey(this.raw);

  static final _equality = DeepCollectionEquality();

  /// The stringified version of the key, for logging/debugging.
  late final String _serialized = jsonEncode(raw);

  /// Returns the serialized representation.
  String get serialized => _serialized;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryKey && _equality.equals(raw, other.raw);

  @override
  int get hashCode => _equality.hash(raw);

  @override
  String toString() => 'QueryKey($serialized)';
}
