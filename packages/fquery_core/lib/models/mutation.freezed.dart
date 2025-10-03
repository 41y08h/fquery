// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mutation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Mutation<TData, TError> {
  TData? get data;
  TError? get error;
  dynamic get status;
  DateTime? get submittedAt;

  /// Create a copy of Mutation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MutationCopyWith<TData, TError, Mutation<TData, TError>> get copyWith =>
      _$MutationCopyWithImpl<TData, TError, Mutation<TData, TError>>(
          this as Mutation<TData, TError>, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Mutation<TData, TError> &&
            const DeepCollectionEquality().equals(other.data, data) &&
            const DeepCollectionEquality().equals(other.error, error) &&
            const DeepCollectionEquality().equals(other.status, status) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(data),
      const DeepCollectionEquality().hash(error),
      const DeepCollectionEquality().hash(status),
      submittedAt);

  @override
  String toString() {
    return 'Mutation<$TData, $TError>(data: $data, error: $error, status: $status, submittedAt: $submittedAt)';
  }
}

/// @nodoc
abstract mixin class $MutationCopyWith<TData, TError, $Res> {
  factory $MutationCopyWith(Mutation<TData, TError> value,
      $Res Function(Mutation<TData, TError>) _then) = _$MutationCopyWithImpl;
  @useResult
  $Res call(
      {TData? data, TError? error, dynamic status, DateTime? submittedAt});
}

/// @nodoc
class _$MutationCopyWithImpl<TData, TError, $Res>
    implements $MutationCopyWith<TData, TError, $Res> {
  _$MutationCopyWithImpl(this._self, this._then);

  final Mutation<TData, TError> _self;
  final $Res Function(Mutation<TData, TError>) _then;

  /// Create a copy of Mutation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = freezed,
    Object? error = freezed,
    Object? status = freezed,
    Object? submittedAt = freezed,
  }) {
    return _then(_self.copyWith(
      data: freezed == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as TData?,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as TError?,
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as dynamic,
      submittedAt: freezed == submittedAt
          ? _self.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Mutation].
extension MutationPatterns<TData, TError> on Mutation<TData, TError> {
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
    TResult Function(_Mutation<TData, TError> value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Mutation() when $default != null:
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
    TResult Function(_Mutation<TData, TError> value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Mutation():
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
    TResult? Function(_Mutation<TData, TError> value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Mutation() when $default != null:
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
    TResult Function(
            TData? data, TError? error, dynamic status, DateTime? submittedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Mutation() when $default != null:
        return $default(
            _that.data, _that.error, _that.status, _that.submittedAt);
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
    TResult Function(
            TData? data, TError? error, dynamic status, DateTime? submittedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Mutation():
        return $default(
            _that.data, _that.error, _that.status, _that.submittedAt);
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
    TResult? Function(
            TData? data, TError? error, dynamic status, DateTime? submittedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Mutation() when $default != null:
        return $default(
            _that.data, _that.error, _that.status, _that.submittedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Mutation<TData, TError> extends Mutation<TData, TError> {
  const _Mutation(
      {this.data,
      this.error,
      this.status = MutationStatus.idle,
      this.submittedAt})
      : super._();

  @override
  final TData? data;
  @override
  final TError? error;
  @override
  @JsonKey()
  final dynamic status;
  @override
  final DateTime? submittedAt;

  /// Create a copy of Mutation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MutationCopyWith<TData, TError, _Mutation<TData, TError>> get copyWith =>
      __$MutationCopyWithImpl<TData, TError, _Mutation<TData, TError>>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Mutation<TData, TError> &&
            const DeepCollectionEquality().equals(other.data, data) &&
            const DeepCollectionEquality().equals(other.error, error) &&
            const DeepCollectionEquality().equals(other.status, status) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(data),
      const DeepCollectionEquality().hash(error),
      const DeepCollectionEquality().hash(status),
      submittedAt);

  @override
  String toString() {
    return 'Mutation<$TData, $TError>(data: $data, error: $error, status: $status, submittedAt: $submittedAt)';
  }
}

/// @nodoc
abstract mixin class _$MutationCopyWith<TData, TError, $Res>
    implements $MutationCopyWith<TData, TError, $Res> {
  factory _$MutationCopyWith(_Mutation<TData, TError> value,
      $Res Function(_Mutation<TData, TError>) _then) = __$MutationCopyWithImpl;
  @override
  @useResult
  $Res call(
      {TData? data, TError? error, dynamic status, DateTime? submittedAt});
}

/// @nodoc
class __$MutationCopyWithImpl<TData, TError, $Res>
    implements _$MutationCopyWith<TData, TError, $Res> {
  __$MutationCopyWithImpl(this._self, this._then);

  final _Mutation<TData, TError> _self;
  final $Res Function(_Mutation<TData, TError>) _then;

  /// Create a copy of Mutation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? data = freezed,
    Object? error = freezed,
    Object? status = freezed,
    Object? submittedAt = freezed,
  }) {
    return _then(_Mutation<TData, TError>(
      data: freezed == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as TData?,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as TError?,
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as dynamic,
      submittedAt: freezed == submittedAt
          ? _self.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
