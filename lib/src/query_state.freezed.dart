// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'query_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$QueryState<TData, TError> {
  TData? get data => throw _privateConstructorUsedError;
  TError? get error => throw _privateConstructorUsedError;
  DateTime? get dataUpdatedAt => throw _privateConstructorUsedError;
  DateTime? get errorUpdatedAt => throw _privateConstructorUsedError;
  bool get isFetching => throw _privateConstructorUsedError;
  QueryStatus get status => throw _privateConstructorUsedError;
  bool get isInvalidated => throw _privateConstructorUsedError;
  FetchMeta? get fetchMeta => throw _privateConstructorUsedError;
  bool get isRefetchError => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $QueryStateCopyWith<TData, TError, QueryState<TData, TError>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QueryStateCopyWith<TData, TError, $Res> {
  factory $QueryStateCopyWith(QueryState<TData, TError> value,
          $Res Function(QueryState<TData, TError>) then) =
      _$QueryStateCopyWithImpl<TData, TError, $Res, QueryState<TData, TError>>;
  @useResult
  $Res call(
      {TData? data,
      TError? error,
      DateTime? dataUpdatedAt,
      DateTime? errorUpdatedAt,
      bool isFetching,
      QueryStatus status,
      bool isInvalidated,
      FetchMeta? fetchMeta,
      bool isRefetchError});
}

/// @nodoc
class _$QueryStateCopyWithImpl<TData, TError, $Res,
        $Val extends QueryState<TData, TError>>
    implements $QueryStateCopyWith<TData, TError, $Res> {
  _$QueryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = freezed,
    Object? error = freezed,
    Object? dataUpdatedAt = freezed,
    Object? errorUpdatedAt = freezed,
    Object? isFetching = null,
    Object? status = null,
    Object? isInvalidated = null,
    Object? fetchMeta = freezed,
    Object? isRefetchError = null,
  }) {
    return _then(_value.copyWith(
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as TData?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as TError?,
      dataUpdatedAt: freezed == dataUpdatedAt
          ? _value.dataUpdatedAt
          : dataUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      errorUpdatedAt: freezed == errorUpdatedAt
          ? _value.errorUpdatedAt
          : errorUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isFetching: null == isFetching
          ? _value.isFetching
          : isFetching // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as QueryStatus,
      isInvalidated: null == isInvalidated
          ? _value.isInvalidated
          : isInvalidated // ignore: cast_nullable_to_non_nullable
              as bool,
      fetchMeta: freezed == fetchMeta
          ? _value.fetchMeta
          : fetchMeta // ignore: cast_nullable_to_non_nullable
              as FetchMeta?,
      isRefetchError: null == isRefetchError
          ? _value.isRefetchError
          : isRefetchError // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QueryStateImplCopyWith<TData, TError, $Res>
    implements $QueryStateCopyWith<TData, TError, $Res> {
  factory _$$QueryStateImplCopyWith(_$QueryStateImpl<TData, TError> value,
          $Res Function(_$QueryStateImpl<TData, TError>) then) =
      __$$QueryStateImplCopyWithImpl<TData, TError, $Res>;
  @override
  @useResult
  $Res call(
      {TData? data,
      TError? error,
      DateTime? dataUpdatedAt,
      DateTime? errorUpdatedAt,
      bool isFetching,
      QueryStatus status,
      bool isInvalidated,
      FetchMeta? fetchMeta,
      bool isRefetchError});
}

/// @nodoc
class __$$QueryStateImplCopyWithImpl<TData, TError, $Res>
    extends _$QueryStateCopyWithImpl<TData, TError, $Res,
        _$QueryStateImpl<TData, TError>>
    implements _$$QueryStateImplCopyWith<TData, TError, $Res> {
  __$$QueryStateImplCopyWithImpl(_$QueryStateImpl<TData, TError> _value,
      $Res Function(_$QueryStateImpl<TData, TError>) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = freezed,
    Object? error = freezed,
    Object? dataUpdatedAt = freezed,
    Object? errorUpdatedAt = freezed,
    Object? isFetching = null,
    Object? status = null,
    Object? isInvalidated = null,
    Object? fetchMeta = freezed,
    Object? isRefetchError = null,
  }) {
    return _then(_$QueryStateImpl<TData, TError>(
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as TData?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as TError?,
      dataUpdatedAt: freezed == dataUpdatedAt
          ? _value.dataUpdatedAt
          : dataUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      errorUpdatedAt: freezed == errorUpdatedAt
          ? _value.errorUpdatedAt
          : errorUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isFetching: null == isFetching
          ? _value.isFetching
          : isFetching // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as QueryStatus,
      isInvalidated: null == isInvalidated
          ? _value.isInvalidated
          : isInvalidated // ignore: cast_nullable_to_non_nullable
              as bool,
      fetchMeta: freezed == fetchMeta
          ? _value.fetchMeta
          : fetchMeta // ignore: cast_nullable_to_non_nullable
              as FetchMeta?,
      isRefetchError: null == isRefetchError
          ? _value.isRefetchError
          : isRefetchError // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$QueryStateImpl<TData, TError> extends _QueryState<TData, TError>
    with DiagnosticableTreeMixin {
  const _$QueryStateImpl(
      {this.data,
      this.error,
      this.dataUpdatedAt,
      this.errorUpdatedAt,
      this.isFetching = false,
      this.status = QueryStatus.loading,
      this.isInvalidated = false,
      this.fetchMeta,
      this.isRefetchError = false})
      : super._();

  @override
  final TData? data;
  @override
  final TError? error;
  @override
  final DateTime? dataUpdatedAt;
  @override
  final DateTime? errorUpdatedAt;
  @override
  @JsonKey()
  final bool isFetching;
  @override
  @JsonKey()
  final QueryStatus status;
  @override
  @JsonKey()
  final bool isInvalidated;
  @override
  final FetchMeta? fetchMeta;
  @override
  @JsonKey()
  final bool isRefetchError;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'QueryState<$TData, $TError>(data: $data, error: $error, dataUpdatedAt: $dataUpdatedAt, errorUpdatedAt: $errorUpdatedAt, isFetching: $isFetching, status: $status, isInvalidated: $isInvalidated, fetchMeta: $fetchMeta, isRefetchError: $isRefetchError)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'QueryState<$TData, $TError>'))
      ..add(DiagnosticsProperty('data', data))
      ..add(DiagnosticsProperty('error', error))
      ..add(DiagnosticsProperty('dataUpdatedAt', dataUpdatedAt))
      ..add(DiagnosticsProperty('errorUpdatedAt', errorUpdatedAt))
      ..add(DiagnosticsProperty('isFetching', isFetching))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('isInvalidated', isInvalidated))
      ..add(DiagnosticsProperty('fetchMeta', fetchMeta))
      ..add(DiagnosticsProperty('isRefetchError', isRefetchError));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QueryStateImpl<TData, TError> &&
            const DeepCollectionEquality().equals(other.data, data) &&
            const DeepCollectionEquality().equals(other.error, error) &&
            (identical(other.dataUpdatedAt, dataUpdatedAt) ||
                other.dataUpdatedAt == dataUpdatedAt) &&
            (identical(other.errorUpdatedAt, errorUpdatedAt) ||
                other.errorUpdatedAt == errorUpdatedAt) &&
            (identical(other.isFetching, isFetching) ||
                other.isFetching == isFetching) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isInvalidated, isInvalidated) ||
                other.isInvalidated == isInvalidated) &&
            (identical(other.fetchMeta, fetchMeta) ||
                other.fetchMeta == fetchMeta) &&
            (identical(other.isRefetchError, isRefetchError) ||
                other.isRefetchError == isRefetchError));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(data),
      const DeepCollectionEquality().hash(error),
      dataUpdatedAt,
      errorUpdatedAt,
      isFetching,
      status,
      isInvalidated,
      fetchMeta,
      isRefetchError);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QueryStateImplCopyWith<TData, TError, _$QueryStateImpl<TData, TError>>
      get copyWith => __$$QueryStateImplCopyWithImpl<TData, TError,
          _$QueryStateImpl<TData, TError>>(this, _$identity);
}

abstract class _QueryState<TData, TError> extends QueryState<TData, TError> {
  const factory _QueryState(
      {final TData? data,
      final TError? error,
      final DateTime? dataUpdatedAt,
      final DateTime? errorUpdatedAt,
      final bool isFetching,
      final QueryStatus status,
      final bool isInvalidated,
      final FetchMeta? fetchMeta,
      final bool isRefetchError}) = _$QueryStateImpl<TData, TError>;
  const _QueryState._() : super._();

  @override
  TData? get data;
  @override
  TError? get error;
  @override
  DateTime? get dataUpdatedAt;
  @override
  DateTime? get errorUpdatedAt;
  @override
  bool get isFetching;
  @override
  QueryStatus get status;
  @override
  bool get isInvalidated;
  @override
  FetchMeta? get fetchMeta;
  @override
  bool get isRefetchError;
  @override
  @JsonKey(ignore: true)
  _$$QueryStateImplCopyWith<TData, TError, _$QueryStateImpl<TData, TError>>
      get copyWith => throw _privateConstructorUsedError;
}
