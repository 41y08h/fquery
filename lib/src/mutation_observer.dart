import 'package:flutter/foundation.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/mutation.dart';

class MutationObserver<TVariables, TData, TError> extends ChangeNotifier {
  final QueryClient client;
  final UseMutationOptions<TVariables, TData, TError> options;
  late Mutation<TVariables, TData, TError> mutation;

  MutationObserver({
    required this.client,
    required this.options,
  }) {
    mutation = Mutation<TVariables, TData, TError>(
      client: client,
      observer: this,
    );
  }

  Future<void> mutate(TVariables variables) async {
    mutation.dispatch(MutationDispatchAction.mutate, null);
    TData? data;
    TError? error;
    try {
      data = await options.mutationFn(variables);
      mutation.dispatch(MutationDispatchAction.success, data);
      options.onSuccess?.call(data as dynamic, variables);
    } catch (err) {
      print(err);
      error = err as TError;
      mutation.dispatch(MutationDispatchAction.error, error);
      options.onError?.call(error as dynamic, variables);
    }
    options.onSettled?.call(data, error, variables);
  }

  void onMutationUpdated() {
    notifyListeners();
  }
}
