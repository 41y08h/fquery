import 'package:flutter/foundation.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/mutation.dart';

class MutationObserver<TVariables, TData, TError, TContext>
    extends ChangeNotifier {
  final QueryClient client;
  final UseMutationOptions<TVariables, TData, TError, TContext> options;
  late Mutation<TVariables, TData, TError, TContext> mutation;
  TVariables? vars;

  MutationObserver({
    required this.client,
    required this.options,
  }) {
    mutation = Mutation<TVariables, TData, TError, TContext>(
      client: client,
      observer: this,
    );
  }

  /// This is "the" function responsible for the mutation.
  Future<void> mutate(TVariables variables) async {
    this.vars = variables;
    notifyListeners();

    mutation.dispatch(MutationDispatchAction.mutate, null);
    final ctx = await options.onMutate?.call(variables);

    late TData data;
    late TError error;
    try {
      data = await options.mutationFn(variables);
      mutation.dispatch(MutationDispatchAction.success, data);
      options.onSuccess?.call(data, variables, ctx);
    } catch (err) {
      error = err as TError;
      mutation.dispatch(MutationDispatchAction.error, error);
      options.onError?.call(error, variables, ctx);
    }
    options.onSettled?.call(data, error, variables, ctx);
  }

  /// Resets the mutation to its initial state.
  void reset() {
    mutation.dispatch(MutationDispatchAction.reset, null);
  }

  /// This is called from the [Mutation] class whenever the mutation state changes.
  /// It notifies the observer about the change and it also nofities the [useMutation] hook.
  void onMutationUpdated() {
    notifyListeners();
  }
}
