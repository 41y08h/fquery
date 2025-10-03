import 'dart:async';
import 'package:flutter/widgets.dart';
import 'cache_provider.dart';
import 'package:fquery_core/fquery_core.dart';

/// Builder widget for mutations
class MutationBuilder<TData, TError, TVariables, TContext>
    extends StatefulWidget {
  /// The builder function which receives the [BuildContext] along with the [MutationResult]
  final Widget Function(BuildContext, MutationResult<TData, TError, TVariables>)
      builder;

  /// The function that performs the mutation.
  final Future<TData> Function(TVariables) mutationFn;

  /// Called before the mutation function is executed.
  final FutureOr<TContext>? Function(TVariables)? onMutate;

  /// Called when the mutation is successful.
  final void Function(TData, TVariables, TContext?)? onSuccess;

  /// Called when the mutation results in an error.
  final void Function(TError, TVariables, TContext?)? onError;

  /// Called when the mutation is either successful or results in an error.
  final void Function(TData?, TError?, TVariables, TContext?)? onSettled;

  /// Creates a new [MutationBuilder] instance.
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
  State<MutationBuilder<TData, TError, TVariables, TContext>> createState() =>
      _MutationBuilderState<TData, TError, TVariables, TContext>();
}

class _MutationBuilderState<TData, TError, TVariables, TContext>
    extends State<MutationBuilder<TData, TError, TVariables, TContext>> {
  late final cache = CacheProvider.get(context);
  late MutationObserver<TData, TError, TVariables, TContext> observer;

  MutationObserver<TData, TError, TVariables, TContext> buildObserver() {
    return MutationObserver<TData, TError, TVariables, TContext>(
      options: MutationOptions(
        mutationFn: widget.mutationFn,
        onMutate: widget.onMutate,
        onSuccess: widget.onSuccess,
        onError: widget.onError,
        onSettled: widget.onSettled,
      ),
    );
  }

  // Initialization of the observer
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    setState(() {
      observer = buildObserver();
    });
    observer.subscribe(hashCode, () {
      setState(() {});
    });
  }

  @override
  void dispose() {
    observer.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(
      covariant MutationBuilder<TData, TError, TVariables, TContext>
          oldWidget) {
    super.didUpdateWidget(oldWidget);

    observer.updateOptions(
      MutationOptions(
        mutationFn: widget.mutationFn,
        onMutate: widget.onMutate,
        onSuccess: widget.onSuccess,
        onError: widget.onError,
        onSettled: widget.onSettled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      MutationResult(
        data: observer.mutation.state.data,
        error: observer.mutation.state.error,
        status: observer.mutation.state.status,
        mutate: observer.mutate,
        submittedAt: observer.mutation.state.submittedAt,
        reset: observer.reset,
        variables: observer.vars,
      ),
    );
  }
}
