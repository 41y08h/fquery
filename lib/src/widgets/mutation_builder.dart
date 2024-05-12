// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/src/hooks/use_mutation.dart';

class MutationBuilder<TData, TError, TVariables, TContext> extends HookWidget {
  final Widget Function(
      BuildContext, UseMutationResult<TData, TError, TVariables>) builder;
  final Future<TData> Function(TVariables) mutationFn;
  final FutureOr<TContext>? Function(TVariables)? onMutate;
  final void Function(TData, TVariables, TContext?)? onSuccess;
  final void Function(TError, TVariables, TContext?)? onError;
  final void Function(TData?, TError?, TVariables, TContext?)? onSettled;

  MutationBuilder(
    this.mutationFn, {
    super.key,
    required this.builder,
    this.onMutate,
    this.onSuccess,
    this.onError,
    this.onSettled,
  });

  @override
  Widget build(BuildContext context) {
    final mutation = useMutation<TData, TError, TVariables, TContext>(
      mutationFn,
      onMutate: onMutate,
      onError: onError,
      onSuccess: onSuccess,
      onSettled: onSettled,
    );

    return Builder(builder: (context) {
      return builder(context, mutation);
    });
  }
}
