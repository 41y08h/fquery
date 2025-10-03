import 'package:fquery_core/models/mutation_result.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mutation.freezed.dart';

@freezed
abstract class Mutation<TData, TError> with _$Mutation<TData, TError> {
  const Mutation._();

  bool get isIdle => status == MutationStatus.idle;
  bool get isPending => status == MutationStatus.pending;
  bool get isSuccess => status == MutationStatus.success;
  bool get isError => status == MutationStatus.error;

  const factory Mutation({
    TData? data,
    TError? error,
    @Default(MutationStatus.idle) status,
    DateTime? submittedAt,
  }) = _Mutation<TData, TError>;
}
