// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cache_map.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CacheMap {
  Set<Observer> get observers;
  Timer? get gcTimer;
  Duration get cacheDuration;
  Query get query;

  /// Create a copy of CacheMap
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CacheMapCopyWith<CacheMap> get copyWith =>
      _$CacheMapCopyWithImpl<CacheMap>(this as CacheMap, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CacheMap &&
            const DeepCollectionEquality().equals(other.observers, observers) &&
            (identical(other.gcTimer, gcTimer) || other.gcTimer == gcTimer) &&
            (identical(other.cacheDuration, cacheDuration) ||
                other.cacheDuration == cacheDuration) &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(observers),
      gcTimer,
      cacheDuration,
      query);

  @override
  String toString() {
    return 'CacheMap(observers: $observers, gcTimer: $gcTimer, cacheDuration: $cacheDuration, query: $query)';
  }
}

/// @nodoc
abstract mixin class $CacheMapCopyWith<$Res> {
  factory $CacheMapCopyWith(CacheMap value, $Res Function(CacheMap) _then) =
      _$CacheMapCopyWithImpl;
  @useResult
  $Res call(
      {Set<Observer> observers,
      Timer? gcTimer,
      Duration cacheDuration,
      Query query});

  $QueryCopyWith<dynamic, Exception, $Res> get query;
}

/// @nodoc
class _$CacheMapCopyWithImpl<$Res> implements $CacheMapCopyWith<$Res> {
  _$CacheMapCopyWithImpl(this._self, this._then);

  final CacheMap _self;
  final $Res Function(CacheMap) _then;

  /// Create a copy of CacheMap
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? observers = null,
    Object? gcTimer = freezed,
    Object? cacheDuration = null,
    Object? query = null,
  }) {
    return _then(_self.copyWith(
      observers: null == observers
          ? _self.observers
          : observers // ignore: cast_nullable_to_non_nullable
              as Set<Observer>,
      gcTimer: freezed == gcTimer
          ? _self.gcTimer
          : gcTimer // ignore: cast_nullable_to_non_nullable
              as Timer?,
      cacheDuration: null == cacheDuration
          ? _self.cacheDuration
          : cacheDuration // ignore: cast_nullable_to_non_nullable
              as Duration,
      query: null == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as Query,
    ));
  }

  /// Create a copy of CacheMap
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $QueryCopyWith<dynamic, Exception, $Res> get query {
    return $QueryCopyWith<dynamic, Exception, $Res>(_self.query, (value) {
      return _then(_self.copyWith(query: value));
    });
  }
}

/// Adds pattern-matching-related methods to [CacheMap].
extension CacheMapPatterns on CacheMap {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_CacheMap value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CacheMap() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_CacheMap value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CacheMap():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_CacheMap value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CacheMap() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(Set<Observer> observers, Timer? gcTimer,
            Duration cacheDuration, Query query)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CacheMap() when $default != null:
        return $default(
            _that.observers, _that.gcTimer, _that.cacheDuration, _that.query);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(Set<Observer> observers, Timer? gcTimer,
            Duration cacheDuration, Query query)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CacheMap():
        return $default(
            _that.observers, _that.gcTimer, _that.cacheDuration, _that.query);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(Set<Observer> observers, Timer? gcTimer,
            Duration cacheDuration, Query query)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CacheMap() when $default != null:
        return $default(
            _that.observers, _that.gcTimer, _that.cacheDuration, _that.query);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CacheMap extends CacheMap {
  const _CacheMap(
      {final Set<Observer> observers = const {},
      this.gcTimer,
      required this.cacheDuration,
      required this.query})
      : _observers = observers,
        super._();

  final Set<Observer> _observers;
  @override
  @JsonKey()
  Set<Observer> get observers {
    if (_observers is EqualUnmodifiableSetView) return _observers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_observers);
  }

  @override
  final Timer? gcTimer;
  @override
  final Duration cacheDuration;
  @override
  final Query query;

  /// Create a copy of CacheMap
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CacheMapCopyWith<_CacheMap> get copyWith =>
      __$CacheMapCopyWithImpl<_CacheMap>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CacheMap &&
            const DeepCollectionEquality()
                .equals(other._observers, _observers) &&
            (identical(other.gcTimer, gcTimer) || other.gcTimer == gcTimer) &&
            (identical(other.cacheDuration, cacheDuration) ||
                other.cacheDuration == cacheDuration) &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_observers),
      gcTimer,
      cacheDuration,
      query);

  @override
  String toString() {
    return 'CacheMap(observers: $observers, gcTimer: $gcTimer, cacheDuration: $cacheDuration, query: $query)';
  }
}

/// @nodoc
abstract mixin class _$CacheMapCopyWith<$Res>
    implements $CacheMapCopyWith<$Res> {
  factory _$CacheMapCopyWith(_CacheMap value, $Res Function(_CacheMap) _then) =
      __$CacheMapCopyWithImpl;
  @override
  @useResult
  $Res call(
      {Set<Observer> observers,
      Timer? gcTimer,
      Duration cacheDuration,
      Query query});

  @override
  $QueryCopyWith<dynamic, Exception, $Res> get query;
}

/// @nodoc
class __$CacheMapCopyWithImpl<$Res> implements _$CacheMapCopyWith<$Res> {
  __$CacheMapCopyWithImpl(this._self, this._then);

  final _CacheMap _self;
  final $Res Function(_CacheMap) _then;

  /// Create a copy of CacheMap
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? observers = null,
    Object? gcTimer = freezed,
    Object? cacheDuration = null,
    Object? query = null,
  }) {
    return _then(_CacheMap(
      observers: null == observers
          ? _self._observers
          : observers // ignore: cast_nullable_to_non_nullable
              as Set<Observer>,
      gcTimer: freezed == gcTimer
          ? _self.gcTimer
          : gcTimer // ignore: cast_nullable_to_non_nullable
              as Timer?,
      cacheDuration: null == cacheDuration
          ? _self.cacheDuration
          : cacheDuration // ignore: cast_nullable_to_non_nullable
              as Duration,
      query: null == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as Query,
    ));
  }

  /// Create a copy of CacheMap
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $QueryCopyWith<dynamic, Exception, $Res> get query {
    return $QueryCopyWith<dynamic, Exception, $Res>(_self.query, (value) {
      return _then(_self.copyWith(query: value));
    });
  }
}

// dart format on
