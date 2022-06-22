import 'package:fquery/fquery/core/online_manager.dart';
import 'package:fquery/fquery/core/query.dart';

bool canFetch(QueryNetworkMode? networkMode) {
  bool isNetworkModeOnline =
      (networkMode ?? QueryNetworkMode.online) == QueryNetworkMode.online;

  return isNetworkModeOnline ? OnlineManager().isOnline : true;
}

class CancelOptions {
  bool? revert;
  bool? silent;

  CancelOptions({
    this.revert,
    this.silent,
  });
}

class CancelledError {
  bool? revert;
  bool? silent;

  CancelledError({
    CancelOptions? options,
  }) {
    revert = options?.revert ?? false;
    silent = options?.silent ?? false;
  }
}

class Retryer<TData> {
  Future<TData> Function() fn;
  void Function(CancelOptions? cancelOptions) cancel;
  void Function() continueFn;
  void Function() cancelRetry;
  void Function() continueRetry;

  Retryer({
    required this.fn,
    required this.cancel,
    required this.continueFn,
    required this.cancelRetry,
    required this.continueRetry,
  });
}
